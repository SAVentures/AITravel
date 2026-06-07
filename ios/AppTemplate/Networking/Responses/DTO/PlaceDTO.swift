/*
 Value-type wire mirror of `SavedPlaceModel`. Reuses the leaf value types directly — they are
 already nonisolated and Codable (no per-leaf DTO, per 02-models §1.2 and §4). Both DTOs in
 this file are `nonisolated` so they decode off the main actor without isolation-mismatch errors
 (02-models §1.2).

 Mapping contract (02-models §4):
   - `PlaceDTO.toDomain()`     — builds a `SavedPlaceModel` reference on the main actor.
   - `SavedPlaceModel.toDTO()` — snapshots the live reference back to a value DTO.
   - Round-trip invariant: `dto.toDomain().toDTO() == dto` (tested in Wave 4, Task 4.1).
   - The mapping is TOTAL: every field in `SavedPlaceModel` has a corresponding field here;
     a field added to the model but omitted from this DTO will be a compile error.

 `SavedPlaceModel.restore(from: PlaceDTO)` (defined in SavedPlaceModel.swift, Task 1.1) is the
 rollback seam that calls into this type. This file satisfies that forward reference.
*/
import Foundation

// MARK: - PlaceDTO

nonisolated struct PlaceDTO: Codable, Equatable, Sendable {

    var id: String
    var name: String
    var category: PlaceCategory
    var location: PlaceLocation
    var source: PlaceSource
    var provenance: PlaceProvenance?
    var facts: [PlaceFacts]
    var addressLine: String?
    var latitude: Double?
    var longitude: Double?
    var savedAtNote: String?

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
}

// MARK: - PlaceDTO → SavedPlaceModel

extension PlaceDTO {

    /// Builds a `SavedPlaceModel` reference graph on the main actor.
    /// Called by `SavedPlacesDTO.toDomain()` for each child place.
    @MainActor
    func toDomain() -> SavedPlaceModel {
        SavedPlaceModel(
            id: id,
            name: name,
            category: category,
            location: location,
            source: source,
            provenance: provenance,
            facts: facts,
            addressLine: addressLine,
            latitude: latitude,
            longitude: longitude,
            savedAtNote: savedAtNote
        )
    }
}

// MARK: - SavedPlaceModel → PlaceDTO

extension SavedPlaceModel {

    /// Snapshots the live reference back to a value DTO.
    /// Used for rollback snapshots and any request body that sends a place.
    func toDTO() -> PlaceDTO {
        PlaceDTO(
            id: id,
            name: name,
            category: category,
            location: location,
            source: source,
            provenance: provenance,
            facts: facts,
            addressLine: addressLine,
            latitude: latitude,
            longitude: longitude,
            savedAtNote: savedAtNote
        )
    }
}
