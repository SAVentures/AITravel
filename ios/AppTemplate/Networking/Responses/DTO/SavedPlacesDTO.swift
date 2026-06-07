/*
 Value-type wire mirror of `SavedPlacesModel` (the container reference model). Holds an id and
 a flat array of `PlaceDTO` — no nested container DTO because the leaf value types are already
 wire-safe and `PlaceDTO` handles the per-row mapping (02-models §4).

 Mapping contract (02-models §4):
   - `SavedPlacesDTO.toDomain()` — builds the `SavedPlacesModel` reference graph on the main
     actor (calls `PlaceDTO.toDomain()` for each child).
   - `SavedPlacesModel.toDTO()` — snapshots the container and all child rows back to a value DTO.
   - Round-trip invariant: `dto.toDomain().toDTO() == dto` (tested in Wave 4, Task 4.1).
*/
import Foundation

// MARK: - SavedPlacesDTO

nonisolated struct SavedPlacesDTO: Codable, Equatable, Sendable {

    var id: String
    var places: [PlaceDTO]

    init(id: String, places: [PlaceDTO]) {
        self.id = id
        self.places = places
    }
}

// MARK: - SavedPlacesDTO → SavedPlacesModel

extension SavedPlacesDTO {

    /// Builds the `SavedPlacesModel` reference graph (container + all child rows) on the main actor.
    @MainActor
    func toDomain() -> SavedPlacesModel {
        SavedPlacesModel(
            id: id,
            places: places.map { $0.toDomain() }
        )
    }
}

// MARK: - SavedPlacesModel → SavedPlacesDTO

extension SavedPlacesModel {

    /// Snapshots the container and every child `SavedPlaceModel` back to a value DTO.
    func toDTO() -> SavedPlacesDTO {
        SavedPlacesDTO(
            id: id,
            places: places.map { $0.toDTO() }
        )
    }
}
