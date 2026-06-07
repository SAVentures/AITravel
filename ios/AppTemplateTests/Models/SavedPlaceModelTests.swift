/*
 Layer 1 — Unit tests for the Saved-tab model layer.

 Group 1: SavedPlacesModel mutations (§4.1)
   - insertPending(_:) prepends a new row at index 0; existing rows shift down.
   - reconcile(pendingID:with:) swaps the pending row in place, preserving the index.
   - rollback(pendingID:) removes the pending row by id.
   - place(id:) returns the live reference for a known id, nil for an unknown one.

 Group 2: SavedPlaceModel.restore(from:) (§4.1 — rollback seam)
   - Applies every mutable field from the DTO snapshot; id is immutable and must not change.

 Group 3: PlaceSource Codable round-trips (§4.2)
   - Each case (reel/screenshot/search) round-trips through a plain symmetric coder.
   - nil-optional paths: .reel with nil clipTitle and .screenshot with nil savedNote.

 Group 4: PlaceSource derived helpers
   - kind, displayLabel, systemImage are pure functions of the case — pin them for the UI contract.

 Group 5: PlaceCategory
   - displayLabel matches the expected string for each case.

 Determinism rules (§3):
   - No Date(), Calendar.current, or Locale.current.
   - Fixtures from SampleData.savedPlacesDTO(); stable id literals only ("place-cevicheria", etc.).
   - SavedPlaceModel is a reference type — assert on fields, never == between two instances.

 Coder rule (§4.2):
   - Plain symmetric JSONEncoder/JSONDecoder with .iso8601 date strategy for all round-trip tests.
   - APIJSON is not used here — its snake-case key conversion is asymmetric on acronym/ID keys.

 §6.6 notes:
   - @Test(arguments:) for PlaceSource cases parameterizes over a nonisolated PlaceSourceCaseTag enum;
     the actual PlaceSource value is built INSIDE the @MainActor (or plain) test body.
   - The PlaceCategory parameterized test uses a [(PlaceCategory, String)] tuple array (not two
     separate collections) to avoid the N×M Cartesian-product footgun.
*/

import Testing
import Foundation
@testable import AppTemplate

// MARK: - PlaceSourceCaseTag

/// Nonisolated discriminator for the @Test(arguments:) PlaceSource parameterized test.
/// Builds the concrete PlaceSource value INSIDE the test body (§6.6 nonisolated-tag pattern).
enum PlaceSourceCaseTag: CaseIterable, CustomTestStringConvertible {
    case reelWithClipTitle
    case reelWithNilClipTitle
    case screenshotWithNote
    case screenshotWithNilNote
    case search

    var testDescription: String {
        switch self {
        case .reelWithClipTitle:    return "reel(handle:clipTitle: non-nil)"
        case .reelWithNilClipTitle: return "reel(handle:clipTitle: nil)"
        case .screenshotWithNote:   return "screenshot(savedNote: non-nil)"
        case .screenshotWithNilNote:return "screenshot(savedNote: nil)"
        case .search:               return "search"
        }
    }

    /// Builds the PlaceSource value to test.
    /// Plain (not @MainActor) because PlaceSource is nonisolated.
    func source() -> PlaceSource {
        switch self {
        case .reelWithClipTitle:    return .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours")
        case .reelWithNilClipTitle: return .reel(handle: "saltinmycoffee", clipTitle: nil)
        case .screenshotWithNote:   return .screenshot(savedNote: "Maps list · screenshot")
        case .screenshotWithNilNote:return .screenshot(savedNote: nil)
        case .search:               return .search
        }
    }
}

// MARK: - Symmetric coder helpers

/// Plain symmetric encoder/decoder pair for round-trip tests (§4.2).
/// Uses .iso8601 for Date fields; no key strategy — symmetric encoding only.
private func symmetricEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    return enc
}

private func symmetricDecoder() -> JSONDecoder {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return dec
}

/// Encode then decode a Codable value using the plain symmetric coder pair.
private func codableRoundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try symmetricEncoder().encode(value)
    return try symmetricDecoder().decode(T.self, from: data)
}

// MARK: - SavedPlaceModelTests

@Suite("Saved model — SavedPlacesModel mutations, restore(from:), PlaceSource Codable, PlaceCategory")
struct SavedPlaceModelTests {

    // MARK: - Group 1: SavedPlacesModel mutations

    @Suite("SavedPlacesModel mutations — insertPending / reconcile / rollback / place(id:)")
    struct SavedPlacesModelMutationTests {

        // MARK: insertPending(_:)

        /// insertPending(_:) prepends the new row at index 0, pushing all existing rows down.
        /// Seeded from SampleData.savedPlacesDTO() — all 24 places present before the insert.
        @Test("insertPending(_:) inserts the new place at index 0, count grows by 1")
        @MainActor
        func insertPendingPrependsAtIndexZero() {
            let model = SampleData.savedPlaces()
            let countBefore = model.places.count
            // Build a minimal pending row — id distinct from any seed id.
            let pending = SavedPlaceModel(
                id: "place-pending-test",
                name: "Pending Test Place",
                category: .eat,
                location: PlaceLocation(neighborhood: "Test Quarter", cityName: "Lisbon"),
                source: .search
            )
            model.insertPending(pending)
            #expect(model.places.count == countBefore + 1,
                    "count must grow by exactly 1 after insertPending")
            #expect(model.places[0].id == "place-pending-test",
                    "the new row must land at index 0")
            // Spot-check: the previously-first place is now at index 1.
            // "place-cevicheria" is the first row in the 24-place seed.
            #expect(model.places[1].id == "place-cevicheria",
                    "the previous first row must shift to index 1")
        }

        /// insertPending(_:) on an empty container puts the row at index 0.
        @Test("insertPending(_:) on an empty container results in a single-element list")
        @MainActor
        func insertPendingIntoEmptyContainer() {
            let empty = SampleData.emptySavedPlaces()
            #expect(empty.places.isEmpty, "precondition: empty seed has 0 places")
            let pending = SavedPlaceModel(
                id: "place-pending-first",
                name: "First Pending",
                category: .drink,
                location: PlaceLocation(neighborhood: "Alfama", cityName: "Lisbon"),
                source: .search
            )
            empty.insertPending(pending)
            #expect(empty.places.count == 1)
            #expect(empty.places[0].id == "place-pending-first")
        }

        // MARK: reconcile(pendingID:with:)

        /// reconcile(pendingID:with:) replaces the pending row at the correct index, preserving position.
        @Test("reconcile(pendingID:with:) swaps the pending row in place, count unchanged")
        @MainActor
        func reconcileReplacesAtCorrectIndex() {
            let model = SampleData.savedPlaces()
            let countBefore = model.places.count
            // Insert a pending row first.
            let pending = SavedPlaceModel(
                id: "place-pending-resolve",
                name: "Pending Resolve",
                category: .stay,
                location: PlaceLocation(neighborhood: "Príncipe Real", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours")
            )
            model.insertPending(pending)
            #expect(model.places[0].id == "place-pending-resolve",
                    "precondition: pending row is at index 0")

            // Build the resolved row (same domain data but could differ on reconciled fields).
            let resolved = SavedPlaceModel(
                id: "place-resolved-server",
                name: "Resolved Server Name",
                category: .stay,
                location: PlaceLocation(neighborhood: "Príncipe Real", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours")
            )
            model.reconcile(pendingID: "place-pending-resolve", with: resolved)

            // Count must not change.
            #expect(model.places.count == countBefore + 1,
                    "reconcile must not change the count")
            // The resolved row must be at index 0 — same position as the pending row.
            #expect(model.places[0].id == "place-resolved-server",
                    "the resolved row must occupy the same position as the pending row")
        }

        /// reconcile with an unknown id is a no-op — places array unchanged.
        @Test("reconcile(pendingID:with:) with an unknown id is a no-op")
        @MainActor
        func reconcileUnknownIDIsNoOp() {
            let model = SampleData.savedPlaces()
            let countBefore = model.places.count
            let firstIDBefore = model.places[0].id
            let resolved = SavedPlaceModel(
                id: "place-ghost",
                name: "Ghost",
                category: .do,
                location: PlaceLocation(neighborhood: "Nowhere", cityName: "Tokyo"),
                source: .search
            )
            model.reconcile(pendingID: "place-does-not-exist", with: resolved)
            #expect(model.places.count == countBefore, "no-op: count must not change")
            #expect(model.places[0].id == firstIDBefore, "no-op: first element must not change")
        }

        // MARK: rollback(pendingID:)

        /// rollback(pendingID:) removes the pending row; the remaining rows are unaffected.
        @Test("rollback(pendingID:) removes the row with the matching id, count shrinks by 1")
        @MainActor
        func rollbackRemovesPendingRow() {
            let model = SampleData.savedPlaces()
            let countBefore = model.places.count
            // Insert then rollback.
            let pending = SavedPlaceModel(
                id: "place-pending-rollback",
                name: "Rollback Target",
                category: .shop,
                location: PlaceLocation(neighborhood: "Ginza", cityName: "Tokyo"),
                source: .screenshot(savedNote: nil)
            )
            model.insertPending(pending)
            #expect(model.places.count == countBefore + 1, "precondition: row inserted")
            model.rollback(pendingID: "place-pending-rollback")
            #expect(model.places.count == countBefore, "count must return to original after rollback")
            #expect(model.place(id: "place-pending-rollback") == nil,
                    "rolled-back row must not be findable by id")
        }

        /// rollback with an unknown id is a no-op.
        @Test("rollback(pendingID:) with an unknown id is a no-op")
        @MainActor
        func rollbackUnknownIDIsNoOp() {
            let model = SampleData.savedPlaces()
            let countBefore = model.places.count
            model.rollback(pendingID: "place-does-not-exist")
            #expect(model.places.count == countBefore, "no-op: count must not change")
        }

        // MARK: place(id:)

        /// place(id:) returns the live reference for a known id.
        /// Uses stable id "place-cevicheria" from the seed.
        @Test("place(id:) returns the live reference for a known stable id")
        @MainActor
        func placeByKnownIDReturnsReference() throws {
            let model = SampleData.savedPlaces()
            let result = model.place(id: "place-cevicheria")
            let ref = try #require(result)
            // Assert on fields, not identity equality.
            #expect(ref.id == "place-cevicheria")
            #expect(ref.name == "A Cevicheria")
            #expect(ref.category == .eat)
        }

        /// place(id:) returns nil for an id not present in the container.
        @Test("place(id:) returns nil for an unknown id")
        @MainActor
        func placeByUnknownIDReturnsNil() {
            let model = SampleData.savedPlaces()
            let result = model.place(id: "place-does-not-exist")
            #expect(result == nil)
        }

        /// place(id:) returns nil on an empty container.
        @Test("place(id:) returns nil when the container is empty")
        @MainActor
        func placeByIDOnEmptyContainerReturnsNil() {
            let empty = SampleData.emptySavedPlaces()
            let result = empty.place(id: "place-cevicheria")
            #expect(result == nil)
        }
    }

    // MARK: - Group 2: SavedPlaceModel.restore(from:)

    @Suite("SavedPlaceModel.restore(from:) — rollback seam reverts all mutable fields")
    struct SavedPlaceModelRestoreTests {

        /// restore(from:) applies every mutable field from the DTO snapshot.
        /// Verifies id is NOT mutated (it is a let).
        @Test("restore(from:) reverts all mutable fields to the DTO snapshot; id is unchanged")
        @MainActor
        func restoreRevertsAllMutableFields() {
            // Seed a live place from the DTO so the initial state is deterministic.
            let dto = SampleData.savedPlacesDTO().places.first(where: { $0.id == "place-cevicheria" })!
            let place = dto.toDomain()

            // Capture snapshot state.
            let snapshotName = place.name
            let snapshotCategory = place.category
            let snapshotLocation = place.location
            let snapshotSource = place.source
            let snapshotProvenance = place.provenance
            let snapshotFacts = place.facts
            let snapshotAddressLine = place.addressLine
            let snapshotLatitude = place.latitude
            let snapshotLongitude = place.longitude
            let snapshotSavedAtNote = place.savedAtNote

            // Mutate every mutable field.
            place.name = "Mutated Name"
            place.category = .shop
            place.location = PlaceLocation(neighborhood: "Nowhere", cityName: "Atlantis")
            place.source = .search
            place.provenance = nil
            place.facts = []
            place.addressLine = nil
            place.latitude = 0.0
            place.longitude = 0.0
            place.savedAtNote = "mutated note"

            // restore(from:) must revert every mutable field.
            place.restore(from: dto)

            // id is immutable — must equal the original.
            #expect(place.id == "place-cevicheria")
            // All mutable fields must match the snapshot.
            #expect(place.name == snapshotName)
            #expect(place.category == snapshotCategory)
            #expect(place.location == snapshotLocation)
            #expect(place.source == snapshotSource)
            #expect(place.provenance == snapshotProvenance)
            #expect(place.facts == snapshotFacts)
            #expect(place.addressLine == snapshotAddressLine)
            #expect(place.latitude == snapshotLatitude)
            #expect(place.longitude == snapshotLongitude)
            #expect(place.savedAtNote == snapshotSavedAtNote)
        }

        /// restore(from:) handles the nil-optional fields correctly (provenance nil, facts empty).
        /// Uses the "place-cantinho-avillez" seed row (provenance: nil, savedAtNote: nil).
        @Test("restore(from:) handles nil optionals — provenance nil stays nil, savedAtNote nil stays nil")
        @MainActor
        func restoreHandlesNilOptionals() {
            let dto = SampleData.savedPlacesDTO().places.first(where: { $0.id == "place-cantinho-avillez" })!
            // Confirm the fixture has nil provenance and nil savedAtNote.
            #expect(dto.provenance == nil, "fixture precondition: cantinho-avillez has nil provenance")
            #expect(dto.savedAtNote == nil, "fixture precondition: cantinho-avillez has nil savedAtNote")

            let place = dto.toDomain()
            // Mutate to non-nil values.
            place.provenance = PlaceProvenance(sourceHandle: "mutated", clipTitle: nil, timestamp: nil, quote: nil)
            place.savedAtNote = "mutated note"

            place.restore(from: dto)

            #expect(place.provenance == nil, "restore must revert provenance back to nil")
            #expect(place.savedAtNote == nil, "restore must revert savedAtNote back to nil")
        }
    }

    // MARK: - Group 3: PlaceSource Codable round-trips

    @Suite("PlaceSource — manual tag-keyed Codable round-trips each case")
    struct PlaceSourceCodableTests {

        /// All five PlaceSource cases in one parameterized test (§6.6 nonisolated-tag pattern).
        /// PlaceSource is nonisolated, so the args evaluation is safe. The tag builds the value
        /// inside the body via tag.source().
        @Test(
            "PlaceSource: encode → decode is lossless for all cases and nil-optional paths",
            arguments: PlaceSourceCaseTag.allCases
        )
        func placeSourceRoundTrips(_ tag: PlaceSourceCaseTag) throws {
            let source = tag.source()
            let recovered = try codableRoundTrip(source)
            #expect(recovered == source)
        }

        /// Verify the tag key is "tag" in the encoded output (contract guard for the hand-written Codable).
        @Test("PlaceSource: encoded JSON contains a 'tag' key")
        func placeSourceEncodedHasTagKey() throws {
            let source = PlaceSource.search
            let data = try symmetricEncoder().encode(source)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["tag"] as? String == "search",
                    "the tag key must be 'tag' and the search case must encode as 'search'")
        }

        /// Verify reel with clipTitle nil does NOT include a "clipTitle" key (encodeIfPresent).
        @Test("PlaceSource.reel with nil clipTitle does not encode the clipTitle key")
        func reelWithNilClipTitleOmitsKey() throws {
            let source = PlaceSource.reel(handle: "saltinmycoffee", clipTitle: nil)
            let data = try symmetricEncoder().encode(source)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["clipTitle"] == nil,
                    "clipTitle must be absent when nil (encodeIfPresent)")
        }

        /// Verify screenshot with savedNote nil does NOT include a "savedNote" key.
        @Test("PlaceSource.screenshot with nil savedNote does not encode the savedNote key")
        func screenshotWithNilNoteOmitsKey() throws {
            let source = PlaceSource.screenshot(savedNote: nil)
            let data = try symmetricEncoder().encode(source)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["savedNote"] == nil,
                    "savedNote must be absent when nil (encodeIfPresent)")
        }
    }

    // MARK: - Group 4: PlaceSource derived helpers

    @Suite("PlaceSource derived helpers — kind, displayLabel, systemImage")
    struct PlaceSourceDerivedTests {

        // MARK: kind

        @Test("PlaceSource.reel.kind == .reel")
        func reelKind() {
            let source = PlaceSource.reel(handle: "saltinmycoffee", clipTitle: nil)
            #expect(source.kind == .reel)
        }

        @Test("PlaceSource.screenshot.kind == .screenshot")
        func screenshotKind() {
            let source = PlaceSource.screenshot(savedNote: nil)
            #expect(source.kind == .screenshot)
        }

        @Test("PlaceSource.search.kind == .search")
        func searchKind() {
            #expect(PlaceSource.search.kind == .search)
        }

        // MARK: displayLabel

        @Test("PlaceSource.reel.displayLabel includes the handle prefixed with @")
        func reelDisplayLabel() {
            let source = PlaceSource.reel(handle: "saltinmycoffee", clipTitle: nil)
            #expect(source.displayLabel == "Reel · @saltinmycoffee")
        }

        @Test("PlaceSource.screenshot.displayLabel returns the note when non-nil")
        func screenshotDisplayLabelWithNote() {
            let source = PlaceSource.screenshot(savedNote: "Maps list · screenshot")
            #expect(source.displayLabel == "Maps list · screenshot")
        }

        @Test("PlaceSource.screenshot.displayLabel returns 'Screenshot' when note is nil")
        func screenshotDisplayLabelNilNote() {
            let source = PlaceSource.screenshot(savedNote: nil)
            #expect(source.displayLabel == "Screenshot")
        }

        @Test("PlaceSource.search.displayLabel == 'Search'")
        func searchDisplayLabel() {
            #expect(PlaceSource.search.displayLabel == "Search")
        }

        // MARK: systemImage

        @Test("PlaceSource.reel.systemImage == 'play.rectangle'")
        func reelSystemImage() {
            let source = PlaceSource.reel(handle: "h", clipTitle: nil)
            #expect(source.systemImage == "play.rectangle")
        }

        @Test("PlaceSource.screenshot.systemImage == 'photo'")
        func screenshotSystemImage() {
            let source = PlaceSource.screenshot(savedNote: nil)
            #expect(source.systemImage == "photo")
        }

        @Test("PlaceSource.search.systemImage == 'magnifyingglass'")
        func searchSystemImage() {
            #expect(PlaceSource.search.systemImage == "magnifyingglass")
        }
    }

    // MARK: - Group 5: PlaceCategory.displayLabel

    @Suite("PlaceCategory.displayLabel — all five cases")
    struct PlaceCategoryDisplayLabelTests {

        /// Single parameterized test pairing each case with its expected label.
        /// Uses a [(PlaceCategory, String)] tuple array to avoid the N×M Cartesian-product footgun (§6.6).
        @Test(
            "PlaceCategory.displayLabel returns the correct string for each case",
            arguments: [
                (PlaceCategory.eat,   "Eat"),
                (PlaceCategory.drink, "Drink"),
                (PlaceCategory.stay,  "Stay"),
                (PlaceCategory.do,    "Do"),
                (PlaceCategory.shop,  "Shop"),
            ] as [(PlaceCategory, String)]
        )
        func categoryDisplayLabel(_ category: PlaceCategory, _ expected: String) {
            #expect(category.displayLabel == expected)
        }
    }
}
