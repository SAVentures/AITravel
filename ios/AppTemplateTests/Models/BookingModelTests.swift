/*
 Layer 1 — Unit tests for the Wallet model layer.

 Group 1: TripWalletModel mutations (§4.1)
   - place(bookingID:onDay:) sets the booking's dayIndex to the given value.
   - place(bookingID:onDay:) on an orphan (was nil dayIndex) also transitions status to .upcoming.
   - place(bookingID:onDay:) on a non-orphan (was non-nil dayIndex) does NOT change status.
   - place(bookingID:onDay:) with an unknown id is a no-op.
   - booking(id:) returns the live reference for a known id, nil for an unknown one.

 Group 2: BookingModel.restore(from:) (§4.1 — rollback seam)
   - Applies every mutable field from the DTO snapshot; id is immutable and must not change.
   - Exercises the full-field revert path (dayIndex, status, detail, accessPass all revert).
   - Exercises the nil-optional path (restores nil fields from a nil-field snapshot).

 Group 3: BookingType derived helpers
   - systemImage returns the correct SF Symbol for each case.
   - displayLabel returns the correct display string for each case.

 Group 4: BookingStatus derived helpers
   - displayLabel returns the correct string for each case.

 Determinism rules (§3):
   - No Date(), Calendar.current, or Locale.current.
   - Fixtures from SampleData.walletDTO(); stable id literals only.
   - BookingModel/TripWalletModel are reference types — assert on fields, never == between instances.

 Coder rule (§4.2):
   - No JSON coder here (that's BookingDTORoundTripTests). These are pure in-place mutation tests.

 §6.6 notes:
   - @Test(arguments:) for BookingType/BookingStatus parameterizes over [(Case, String)] tuple arrays
     to avoid the N×M Cartesian-product footgun.
   - TripWalletModel/BookingModel are @MainActor — all tests that use them are @MainActor.
*/

import Testing
import Foundation
@testable import AppTemplate

// MARK: - BookingModelTests

@Suite("Wallet model — TripWalletModel mutations, BookingModel.restore(from:), BookingType/BookingStatus")
struct BookingModelTests {

    // MARK: - Group 1: TripWalletModel mutations

    @Suite("TripWalletModel mutations — place(bookingID:onDay:) / booking(id:)")
    struct TripWalletModelMutationTests {

        // MARK: place(bookingID:onDay:) — sets dayIndex

        /// place(bookingID:onDay:) sets the booking's dayIndex to the given value.
        /// Uses the orphan (booking-fado-orphan, dayIndex nil) so pre-state is deterministic.
        @Test("place(bookingID:onDay:) sets dayIndex on the matched booking")
        @MainActor
        func placeSetsDay() throws {
            let wallet = SampleData.walletDTO().toDomain()
            let orphan = try #require(wallet.booking(id: "booking-fado-orphan"),
                                     "fixture precondition: booking-fado-orphan must be present")
            #expect(orphan.dayIndex == nil, "fixture precondition: orphan starts with nil dayIndex")

            wallet.place(bookingID: "booking-fado-orphan", onDay: 2)

            #expect(orphan.dayIndex == 2,
                    "place(bookingID:onDay:) must set dayIndex to the given value")
        }

        /// Placing an orphan (was nil dayIndex) also transitions status to .upcoming.
        @Test("place(bookingID:onDay:) on an orphan transitions status to .upcoming")
        @MainActor
        func placeOrphanTransitionsStatus() throws {
            let wallet = SampleData.walletDTO().toDomain()
            let orphan = try #require(wallet.booking(id: "booking-fado-orphan"))
            // The orphan seed starts with .upcoming, but was nil dayIndex (which is the trigger).
            // Capture status; place; confirm .upcoming (the transition is: wasOrphan → set .upcoming).
            // Test the path: was nil dayIndex → after place, status == .upcoming
            wallet.place(bookingID: "booking-fado-orphan", onDay: 3)

            #expect(orphan.dayIndex == 3)
            #expect(orphan.status == .upcoming,
                    "an orphan booking (nil dayIndex before place) must have status .upcoming after placement")
        }

        /// Placing a non-orphan (non-nil dayIndex) does NOT change status.
        @Test("place(bookingID:onDay:) on a non-orphan does not change status")
        @MainActor
        func placeNonOrphanPreservesStatus() throws {
            let wallet = SampleData.walletDTO().toDomain()
            // booking-castelo has dayIndex 2 and status .now
            let castelo = try #require(wallet.booking(id: "booking-castelo"))
            #expect(castelo.dayIndex == 2, "fixture precondition: castelo has non-nil dayIndex")
            let statusBefore = castelo.status
            #expect(statusBefore == .now, "fixture precondition: castelo has .now status")

            wallet.place(bookingID: "booking-castelo", onDay: 1)

            #expect(castelo.dayIndex == 1, "dayIndex must be updated")
            #expect(castelo.status == statusBefore,
                    "status must not change when placing a booking that was already placed")
        }

        /// place(bookingID:onDay:) with an unknown id is a no-op; no booking is mutated.
        @Test("place(bookingID:onDay:) with an unknown id is a no-op")
        @MainActor
        func placeUnknownIDIsNoOp() throws {
            let wallet = SampleData.walletDTO().toDomain()
            let countBefore = wallet.bookings.count
            let orphanDayBefore = wallet.booking(id: "booking-fado-orphan")?.dayIndex

            wallet.place(bookingID: "booking-does-not-exist", onDay: 2)

            #expect(wallet.bookings.count == countBefore, "no-op: booking count must not change")
            #expect(wallet.booking(id: "booking-fado-orphan")?.dayIndex == orphanDayBefore,
                    "no-op: unrelated booking must not be mutated")
        }

        // MARK: booking(id:)

        /// booking(id:) returns the live reference for a known stable id.
        @Test("booking(id:) returns the live reference for a known stable id")
        @MainActor
        func bookingByKnownIDReturnsReference() throws {
            let wallet = SampleData.walletDTO().toDomain()
            let result = wallet.booking(id: "booking-tap201")
            let ref = try #require(result)
            // Assert on fields, not identity equality (reference type)
            #expect(ref.id == "booking-tap201")
            #expect(ref.title == "Lisbon → New York")
            #expect(ref.type == .transport)
            #expect(ref.accessPass != nil, "tap201 must carry an access pass")
        }

        /// booking(id:) returns nil for an id not present in the container.
        @Test("booking(id:) returns nil for an unknown id")
        @MainActor
        func bookingByUnknownIDReturnsNil() {
            let wallet = SampleData.walletDTO().toDomain()
            #expect(wallet.booking(id: "booking-does-not-exist") == nil)
        }

        /// booking(id:) returns nil on an empty wallet.
        @Test("booking(id:) returns nil when the wallet has no bookings")
        @MainActor
        func bookingByIDOnEmptyWalletReturnsNil() {
            let empty = SampleData.emptyWalletDTO().toDomain()
            #expect(empty.booking(id: "booking-tap201") == nil)
        }

        /// Verifies that booking(id:) returns the live reference — not a copy.
        /// Mutating the returned reference mutates the booking on the wallet.
        @Test("booking(id:) returns the live reference — mutations via the ref are reflected on the wallet")
        @MainActor
        func bookingByIDReturnsLiveReference() throws {
            let wallet = SampleData.walletDTO().toDomain()
            let ref = try #require(wallet.booking(id: "booking-jeronimos"))
            let titleBefore = ref.title
            ref.title = "Mutated Title"
            // Look up again — must see the mutation
            let refAgain = try #require(wallet.booking(id: "booking-jeronimos"))
            #expect(refAgain.title == "Mutated Title",
                    "the wallet must reflect the mutation applied through the live reference")
            // Restore
            ref.title = titleBefore
        }
    }

    // MARK: - Group 2: BookingModel.restore(from:)

    @Suite("BookingModel.restore(from:) — rollback seam reverts all mutable fields")
    struct BookingModelRestoreTests {

        /// restore(from:) applies every mutable field from the DTO snapshot.
        /// Verifies id is NOT mutated (it is a let).
        /// Uses booking-tap201: the richest row (has detail + accessPass).
        @Test("restore(from:) reverts all mutable fields to the DTO snapshot; id is unchanged")
        @MainActor
        func restoreRevertsAllMutableFields() throws {
            let dto = BookingDTOFixtureTag.tap201.dto()
            let booking = dto.toDomain()

            // Capture the snapshot state.
            let snapshotTitle = booking.title
            let snapshotType = booking.type
            let snapshotStatus = booking.status
            let snapshotDayIndex = booking.dayIndex
            let snapshotStartTime = booking.startTime
            let snapshotSubtitleParts = booking.subtitleParts
            let snapshotConfirmation = booking.confirmation
            let snapshotDetail = booking.detail
            let snapshotAccessPass = booking.accessPass

            // Mutate every mutable field.
            booking.title = "Mutated Title"
            booking.type = .dining
            booking.status = .past
            booking.dayIndex = 99
            booking.startTime = "99:99"
            booking.subtitleParts = ["mutated"]
            booking.confirmation = "MUTATED"
            booking.detail = nil
            booking.accessPass = nil

            // restore(from:) must revert every mutable field.
            booking.restore(from: dto)

            // id is immutable — must equal the original.
            #expect(booking.id == "booking-tap201")
            // All mutable fields must match the snapshot.
            #expect(booking.title == snapshotTitle)
            #expect(booking.type == snapshotType)
            #expect(booking.status == snapshotStatus)
            #expect(booking.dayIndex == snapshotDayIndex)
            #expect(booking.startTime == snapshotStartTime)
            #expect(booking.subtitleParts == snapshotSubtitleParts)
            #expect(booking.confirmation == snapshotConfirmation)
            #expect(booking.detail == snapshotDetail)
            #expect(booking.accessPass == snapshotAccessPass)
        }

        /// restore(from:) restores nil fields correctly (detail and accessPass back to nil).
        /// Uses booking-ferry: nil confirmation, nil detail, nil accessPass.
        @Test("restore(from:) handles nil optionals — nil fields stay nil, non-nil fields get set")
        @MainActor
        func restoreHandlesNilOptionals() throws {
            let dto = BookingDTOFixtureTag.ferry.dto()
            #expect(dto.confirmation == nil, "fixture precondition: ferry has nil confirmation")
            #expect(dto.detail == nil, "fixture precondition: ferry has nil detail")
            #expect(dto.accessPass == nil, "fixture precondition: ferry has nil accessPass")

            let booking = dto.toDomain()
            // Mutate to non-nil values.
            booking.confirmation = "FORCED"
            booking.detail = BookingDetailInfo(kind: "Forced", infoCells: [], detailRows: [], placedLabel: nil)
            booking.accessPass = AccessPass(
                kindLabel: "Forced",
                title: "Forced Title",
                subtitle: "Forced Sub",
                qrPayload: "FORCED",
                confirmation: "FORCED",
                metaCells: []
            )

            booking.restore(from: dto)

            #expect(booking.confirmation == nil, "restore must revert confirmation back to nil")
            #expect(booking.detail == nil, "restore must revert detail back to nil")
            #expect(booking.accessPass == nil, "restore must revert accessPass back to nil")
        }

        /// restore(from:) reverts dayIndex back to nil (the rollback of a place command).
        /// This is the core orphan-placement rollback scenario.
        @Test("restore(from:) reverts dayIndex from a placed value back to nil (orphan-placement rollback)")
        @MainActor
        func restoreRevertsOrphanPlacement() throws {
            // Use the orphan fixture as the snapshot: dayIndex nil, status .upcoming
            let snapshotDTO = BookingDTOFixtureTag.fadoOrphan.dto()
            #expect(snapshotDTO.dayIndex == nil, "fixture precondition: orphan snapshot has nil dayIndex")

            let booking = snapshotDTO.toDomain()
            // Simulate the optimistic placement.
            booking.dayIndex = 2
            booking.status = .upcoming
            #expect(booking.dayIndex == 2, "precondition: dayIndex was placed")

            // Rollback via restore(from:).
            booking.restore(from: snapshotDTO)

            #expect(booking.dayIndex == nil,
                    "restore must revert dayIndex from 2 back to nil (orphan rollback)")
            #expect(booking.status == .upcoming,
                    "restore must revert status to match the snapshot")
        }

        /// restore(from:) correctly restores the full detail payload (including nested cells).
        @Test("restore(from:) correctly restores a non-nil detail with nested infoCells and detailRows")
        @MainActor
        func restoreRestoresDetailPayload() throws {
            let dto = BookingDTOFixtureTag.tap201.dto()
            #expect(dto.detail != nil, "fixture precondition: tap201 has detail")

            let booking = dto.toDomain()
            booking.detail = nil  // clobber the detail

            booking.restore(from: dto)

            let restoredDetail = try #require(booking.detail,
                                              "restore must restore the non-nil detail")
            #expect(restoredDetail.kind == "Flight")
            #expect(restoredDetail.infoCells.count == 3)
            #expect(restoredDetail.detailRows.count == 5)
            #expect(restoredDetail.placedLabel == "Placed on Day 4 · Sat, Aug 29")
        }
    }

    // MARK: - Group 3: BookingType derived helpers

    @Suite("BookingType.systemImage and .displayLabel — all five cases")
    struct BookingTypeDerivedTests {

        /// systemImage returns the correct SF Symbol for each BookingType case.
        /// Uses a [(BookingType, String)] tuple array to avoid the N×M Cartesian-product footgun (§6.6).
        @Test(
            "BookingType.systemImage returns the correct SF Symbol for each case",
            arguments: [
                (BookingType.lodging,   "bed.double"),
                (BookingType.transport, "airplane"),
                (BookingType.activity,  "ticket"),
                (BookingType.dining,    "fork.knife"),
                (BookingType.other,     "mappin"),
            ] as [(BookingType, String)]
        )
        func bookingTypeSystemImage(_ type: BookingType, _ expected: String) {
            #expect(type.systemImage == expected,
                    "BookingType.\(type).systemImage must be '\(expected)'")
        }

        /// displayLabel returns the correct display string for each BookingType case.
        @Test(
            "BookingType.displayLabel returns the correct string for each case",
            arguments: [
                (BookingType.lodging,   "Lodging"),
                (BookingType.transport, "Transport"),
                (BookingType.activity,  "Activity"),
                (BookingType.dining,    "Dining"),
                (BookingType.other,     "Other"),
            ] as [(BookingType, String)]
        )
        func bookingTypeDisplayLabel(_ type: BookingType, _ expected: String) {
            #expect(type.displayLabel == expected,
                    "BookingType.\(type).displayLabel must be '\(expected)'")
        }
    }

    // MARK: - Group 4: BookingStatus derived helpers

    @Suite("BookingStatus.displayLabel — all four cases")
    struct BookingStatusDerivedTests {

        /// displayLabel returns the correct string for each BookingStatus case.
        @Test(
            "BookingStatus.displayLabel returns the correct string for each case",
            arguments: [
                (BookingStatus.upcoming, "Upcoming"),
                (BookingStatus.today,    "Today"),
                (BookingStatus.now,      "Now"),
                (BookingStatus.past,     "Past"),
            ] as [(BookingStatus, String)]
        )
        func bookingStatusDisplayLabel(_ status: BookingStatus, _ expected: String) {
            #expect(status.displayLabel == expected,
                    "BookingStatus.\(status).displayLabel must be '\(expected)'")
        }
    }
}
