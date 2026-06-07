/*
 The two reference models for the Wallet feature:

 - `TripWalletModel`  — the container / list owner. A mutable list row at the wallet level;
   holds the ordered collection of bookings and exposes a lookup helper plus the orphan-
   placement write seams.

 - `BookingModel`     — the row. One booking entry. Holds the leaf value types directly
   (BookingType, BookingStatus, BookingDetailInfo?, AccessPass?) so only the mutated row
   is re-observed by SwiftUI.

 Both are `@MainActor @Observable final class` because both participate in list rendering and
 mutate in place (02-models §1.1). Neither is Codable — serialisation is the DTO layer's job
 (Task 2.2). Equality is identity-based; no value Equatable/Hashable.

 `restore(from: BookingDTO)` on BookingModel is the rollback seam: AppStore calls it after a
 failed optimistic write to revert the live reference in place (03-store §3). BookingDTO is
 defined in Task 2.2; this file forward-references it — the compiler will flag it until 2.2
 lands.

 Status is stored as seeded value data (OD-3 decision: deterministic, no live-clock derivation).
 Computing from simulatedNow + per-booking dates is a later upgrade.
*/
import Foundation

// MARK: - TripWalletModel

@MainActor
@Observable
final class TripWalletModel: Identifiable {

    // MARK: Identity

    let id: String

    // MARK: Mutable fields

    var tripCityName: String
    var dayCount: Int
    var bookings: [BookingModel]

    // MARK: Designated init

    init(id: String, tripCityName: String, dayCount: Int, bookings: [BookingModel]) {
        self.id = id
        self.tripCityName = tripCityName
        self.dayCount = dayCount
        self.bookings = bookings
    }

    // MARK: Lookup

    /// Returns the live `BookingModel` reference for the given id, or `nil` if absent.
    func booking(id: BookingModel.ID) -> BookingModel? {
        bookings.first { $0.id == id }
    }

    // MARK: Mutations (pure, in-place — 03-store §3 Tier 1)

    /*
     These are the optimistic-write seam for `AppStore.placeOrphan` (03-store §3). The store
     command orchestrates (capture previous state → network → reconcile/rollback); each per-entity
     mutation lives here as a method on the reference model. Both mutate the matched booking
     in place — because `BookingModel` is `@Observable`, only the affected row invalidates.
    */

    /// Assigns `dayIndex` on the matched booking (and marks it `.upcoming` if it was previously
    /// orphaned/nil). The store calls this as the optimistic step before firing `PlaceOrphanRequest`.
    func place(bookingID: BookingModel.ID, onDay dayIndex: Int) {
        guard let booking = booking(id: bookingID) else { return }
        booking.dayIndex = dayIndex
        if booking.status == .upcoming || booking.dayIndex == nil {
            // Ensure the booking has a placed status; the seeded status is the source of truth
            // but an orphan being placed should not remain visually un-placed.
            booking.status = .upcoming
        }
    }

    /// Reverts `dayIndex` on the matched booking to `previousDayIndex` — the rollback seam.
    /// `AppStore.placeOrphan` calls this when `PlaceOrphanRequest` fails, passing the captured
    /// previous value (nil = orphan, Int = already placed).
    func restoreDay(bookingID: BookingModel.ID, to previousDayIndex: Int?) {
        guard let booking = booking(id: bookingID) else { return }
        booking.dayIndex = previousDayIndex
    }
}

// MARK: - BookingModel

@MainActor
@Observable
final class BookingModel: Identifiable {

    // MARK: Identity

    let id: String

    // MARK: Mutable fields

    var title: String
    var type: BookingType
    var status: BookingStatus
    /// `nil` means the booking is an orphan — not yet assigned to a day.
    var dayIndex: Int?
    /// Display string for the start time, e.g. "10:00" or "Departs 13:40". No live clock.
    var startTime: String?
    /// Ordered parts of the subtitle meta line, e.g. ["timed entry", "2 adults"].
    /// The presenter joins these for display; keeping them separate allows truncation control.
    var subtitleParts: [String]
    var confirmation: String?
    /// Full booking-detail payload; present when the user navigates to the detail screen.
    var detail: BookingDetailInfo?
    /// Day-of access pass; present only for bookings that have a boarding pass / timed entry.
    var accessPass: AccessPass?

    // MARK: Designated init

    init(
        id: String,
        title: String,
        type: BookingType,
        status: BookingStatus,
        dayIndex: Int? = nil,
        startTime: String? = nil,
        subtitleParts: [String] = [],
        confirmation: String? = nil,
        detail: BookingDetailInfo? = nil,
        accessPass: AccessPass? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.status = status
        self.dayIndex = dayIndex
        self.startTime = startTime
        self.subtitleParts = subtitleParts
        self.confirmation = confirmation
        self.detail = detail
        self.accessPass = accessPass
    }
}

// MARK: - restore(from:)

extension BookingModel {

    /*
     The rollback seam. `id` is immutable; only the mutable fields are reapplied from the
     DTO snapshot. Called by AppStore after a failed optimistic write (03-store §3).
     BookingDTO is defined in Task 2.2 — forward reference; the compiler flags it until that
     task lands.
    */
    func restore(from dto: BookingDTO) {
        title = dto.title
        type = dto.type
        status = dto.status
        dayIndex = dto.dayIndex
        startTime = dto.startTime
        subtitleParts = dto.subtitleParts
        confirmation = dto.confirmation
        detail = dto.detail
        accessPass = dto.accessPass
    }
}
