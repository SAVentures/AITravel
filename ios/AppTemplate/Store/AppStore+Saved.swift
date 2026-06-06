/*
 The Saved feature's store commands. Read path (hydration) + the one networked write (add a place),
 thin async wrappers over the network and the SavedPlaces graph. Mirrors AppStore+Onboarding.swift's
 load path and the `borrow` optimistic-write + rollback shape in 03-store.md §3.

 Logic lives here, not in views (non-negotiable #5): the screen calls `addPlace` / `loadSavedPlaces`
 and reads `savedPlaces` / `savedLoadState` / `writeError`; it never reassigns the graph itself.
*/
import Foundation

extension AppStore {

    // MARK: - Read path (hydration)

    /// Hydrate the saved-places graph from the network. On success maps the DTO to the domain graph
    /// on the main actor and marks `.loaded`; on failure marks `.failed(...)` and leaves the graph
    /// nil (no partial graph). Mirrors `loadOnboarding`.
    func loadSavedPlaces() async {
        savedLoadState = .loading
        do {
            let dto = try await api.send(GetSavedPlacesRequest())
            setSavedPlaces(dto.toDomain())
            savedLoadState = .loaded
        } catch {
            setSavedPlaces(nil)
            savedLoadState = .failed(String(describing: error))
        }
    }

    // MARK: - Write command (optimistic + rollback)

    /*
     Add a place from a pasted reel/clipboard URL — the one real networked write for the Saved slice
     (D-4). Optimistic-then-reconcile, with rollback on failure (03-store §3):

       1. build a pending optimistic `SavedPlaceModel` and insert it into `savedPlaces.places` in place
          (only the list invalidates — the row is observable);
       2. fire `AddPlaceRequest`; on success replace the optimistic row in place with the resolved
          server row (`dto.toDomain()`) so the graph carries the server id, and clear `writeError`;
       3. on failure remove the optimistically-inserted row (snapshot = its id) and set
          `writeError = .addPlace` so the screen surfaces the banner.

     Guard: with no graph there is nothing to insert into, so this is a no-op (the add flow is only
     reachable from the hydrated Saved list).
    */
    func addPlace(_ body: AddPlaceBody) async {
        guard let savedPlaces else { return }

        // 1. Optimistic insert. Remember the id so rollback / reconcile can find this exact row.
        let optimisticID = "place-pending-\(UUID().uuidString)"
        let optimistic = SavedPlaceModel(
            id: optimisticID,
            name: "Resolving…",
            category: .eat,
            location: PlaceLocation(neighborhood: "", cityName: ""),
            source: .reel(handle: "", clipTitle: nil),
            savedAtNote: "Resolving from reel"
        )
        savedPlaces.places.insert(optimistic, at: 0)

        do {
            // 2. Fire the write, reconcile from the resolved DTO.
            let dto = try await api.send(AddPlaceRequest(body_: body))
            if let index = savedPlaces.places.firstIndex(where: { $0.id == optimisticID }) {
                // Replace in place — the resolved row carries the server id (immutable on the model).
                savedPlaces.places[index] = dto.toDomain()
            }
            writeError = nil
        } catch {
            // 3. Rollback: drop the optimistic row and surface the failure.
            savedPlaces.places.removeAll { $0.id == optimisticID }
            writeError = .addPlace
        }
    }
}
