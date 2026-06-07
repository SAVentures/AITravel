/*
 The Wallet feature's store commands. Read path (hydration) + the one networked write (place an
 orphan booking onto a day), thin async wrappers over the network and the TripWallet graph. Mirrors
 AppStore+Saved.swift's load path and the `addPlace` optimistic-write + rollback shape in 03-store.md §3.

 Logic lives here, not in views (non-negotiable #5): the screen calls `placeOrphan` / `loadWallet`
 and reads `wallet` / `walletLoadState` / `writeError`; it never reassigns the graph itself.
*/
import Foundation

extension AppStore {

    // MARK: - Read path (hydration)

    /// Hydrate the trip-wallet graph from the network. On success maps the DTO to the domain graph
    /// on the main actor and marks `.loaded`; on failure marks `.failed(...)` and leaves the graph
    /// nil (no partial graph). Mirrors `loadSavedPlaces`.
    func loadWallet() async {
        walletLoadState = .loading
        do {
            let dto = try await api.send(GetWalletRequest())
            setWallet(dto.toDomain())
            walletLoadState = .loaded
        } catch {
            setWallet(nil)
            walletLoadState = .failed(String(describing: error))
        }
    }

    // MARK: - Write command (optimistic + rollback)

    /*
     Place an orphan booking (one with no `dayIndex`) onto a specific day — the one real networked write
     for the Wallet slice (OD-4). Optimistic-then-reconcile, with rollback on failure (03-store §3). The
     command ORCHESTRATES; each per-entity mutation is a method on `TripWalletModel` / `BookingModel`
     (Tier 1) — this holds no raw `dayIndex`/index-replace assignment, mirroring `addPlace` calling
     `insertPending`/`reconcile`/`rollback`:

       1. capture the booking's current `dayIndex` (the previous value) so rollback can revert exactly;
       2. `place(bookingID:onDay:)` optimistically (only that row invalidates — the booking is observable);
       3. fire `PlaceOrphanRequest`; on success `restore(...)` the booking from the resolved server row
          (`dto`) so the graph carries the reconciled state, and clear `writeError`;
       4. on failure `restoreDay(...)` the booking's day back to the captured previous value and set
          `writeError = .placeOrphan` so the screen surfaces the banner.
    */
    func placeOrphan(bookingID: BookingModel.ID, onDay dayIndex: Int) async {
        // 1. Remember the prior day so rollback can revert this exact booking (nil = was an orphan).
        let previousDayIndex = wallet?.booking(id: bookingID)?.dayIndex

        // 2. Optimistic placement (the model method; only the affected row re-renders).
        wallet?.place(bookingID: bookingID, onDay: dayIndex)

        do {
            // 3. Fire the write, reconcile the live reference from the resolved DTO.
            let dto = try await api.send(PlaceOrphanRequest(id: bookingID, dayIndex: dayIndex))
            wallet?.booking(id: bookingID)?.restore(from: dto)
            writeError = nil
        } catch {
            // 4. Rollback: revert the day and surface the failure.
            wallet?.restoreDay(bookingID: bookingID, to: previousDayIndex)
            writeError = .placeOrphan
        }
    }
}
