/*
 The two reference models for the Saved tab:

 - `SavedPlacesModel`  — the container / list owner. A mutable list row at the tab level;
   holds the ordered collection of saved places and exposes a lookup helper.

 - `SavedPlaceModel`   — the row. One saved place entry. Holds the leaf value types directly
   (PlaceCategory, PlaceLocation, PlaceSource, PlaceProvenance?, PlaceFacts, flat lat/long
   doubles) so only the mutated row is re-observed by SwiftUI.

 Both are `@MainActor @Observable final class` because both participate in list rendering and
 mutate in place (02-models §1.1). Neither is Codable — serialisation is PlaceDTO's job
 (Task 1.2). Equality is identity-based; no value Equatable/Hashable.

 `restore(from: PlaceDTO)` is the rollback seam: AppStore calls it after a failed optimistic
 write to revert the live reference in place (03-store §3). PlaceDTO is defined in Task 1.2;
 this file forward-references it — the compiler will flag it until 1.2 lands.
*/
import Foundation

// MARK: - SavedPlacesModel

@MainActor
@Observable
final class SavedPlacesModel: Identifiable {

    // MARK: Identity

    let id: String

    // MARK: Mutable fields

    var places: [SavedPlaceModel]

    // MARK: Designated init

    init(id: String, places: [SavedPlaceModel]) {
        self.id = id
        self.places = places
    }

    // MARK: Lookup

    /// Returns the live `SavedPlaceModel` reference for the given id, or `nil` if absent.
    func place(id: SavedPlaceModel.ID) -> SavedPlaceModel? {
        places.first { $0.id == id }
    }

    // MARK: Mutations (pure, in-place — 03-store §3 Tier 1)

    /*
     These are the optimistic-write seam for `AppStore.addPlace` (03-store §3). The store command
     orchestrates (build optimistic model → network → reconcile/rollback); each per-entity mutation
     lives here as a method on the reference model. All mutate `self.places` in place — because
     `SavedPlacesModel` is `@Observable`, only the list invalidates and re-renders.
    */

    /// Inserts the optimistic pending row at the top of the list (index 0).
    func insertPending(_ place: SavedPlaceModel) {
        places.insert(place, at: 0)
    }

    /// Replaces the pending row (matched by id) with the resolved server row, preserving its position.
    /// `SavedPlaceModel.id` is a `let`, so the element is swapped rather than mutated in place.
    func reconcile(pendingID: SavedPlaceModel.ID, with resolved: SavedPlaceModel) {
        guard let index = places.firstIndex(where: { $0.id == pendingID }) else { return }
        places[index] = resolved
    }

    /// Removes the pending row by id — the rollback for a failed optimistic insert.
    func rollback(pendingID: SavedPlaceModel.ID) {
        places.removeAll { $0.id == pendingID }
    }
}

// MARK: - SavedPlaceModel

@MainActor
@Observable
final class SavedPlaceModel: Identifiable {

    // MARK: Identity

    let id: String

    // MARK: Mutable fields

    var name: String
    var category: PlaceCategory
    var location: PlaceLocation
    var source: PlaceSource
    var provenance: PlaceProvenance?
    var facts: [PlaceFacts]
    var addressLine: String?
    /// WGS-84 decimal degrees. Flat Double — never CLLocationCoordinate2D (mirror BaseLocation).
    var latitude: Double?
    /// WGS-84 decimal degrees.
    var longitude: Double?
    var savedAtNote: String?

    // MARK: Designated init

    init(
        id: String,
        name: String,
        category: PlaceCategory,
        location: PlaceLocation,
        source: PlaceSource,
        provenance: PlaceProvenance? = nil,
        facts: [PlaceFacts] = [],
        addressLine: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        savedAtNote: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.source = source
        self.provenance = provenance
        self.facts = facts
        self.addressLine = addressLine
        self.latitude = latitude
        self.longitude = longitude
        self.savedAtNote = savedAtNote
    }

    // MARK: Display helpers (pure, data only — no SwiftUI import)

    /// One-line location string, e.g. "Príncipe Real · Lisbon".
    var locationLine: String { location.displayLine }

    /// Whether coordinates are present and can be used for a map pin.
    var hasCoordinates: Bool { latitude != nil && longitude != nil }
}

// MARK: - restore(from:)

extension SavedPlaceModel {

    /*
     The rollback seam. `id` is immutable; only the mutable fields are reapplied from the
     DTO snapshot. Called by AppStore after a failed optimistic write (03-store §3).
     PlaceDTO is defined in Task 1.2 — forward reference; the compiler flags it until that
     task lands.
    */
    func restore(from dto: PlaceDTO) {
        name = dto.name
        category = dto.category
        location = dto.location
        source = dto.source
        provenance = dto.provenance
        facts = dto.facts
        addressLine = dto.addressLine
        latitude = dto.latitude
        longitude = dto.longitude
        savedAtNote = dto.savedAtNote
    }
}
