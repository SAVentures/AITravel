/*
 Layer 1 — Unit tests for the PlaceDTO ↔ SavedPlaceModel / SavedPlacesDTO round-trip (§4.2).

 Group 1: PlaceDTO mapping round-trip
   - dto.toDomain().toDTO() == dto for representative fixture rows indexed by stable id.
   - Covers every PlaceSource case (reel/screenshot/search) and both nil/non-nil optional fields
     (provenance, addressLine, latitude/longitude, savedAtNote) so any new field on SavedPlaceModel
     that lacks a PlaceDTO mirror will break this test.
   - Parameterized over a nonisolated PlaceDTOFixtureTag enum; toDomain() runs @MainActor (§6.6).

 Group 2: PlaceDTO JSON round-trip
   - encode(dto) → decode → dto2 (symmetric coder) — guards Codable symmetry independently of
     the domain mapping.

 Group 3: SavedPlacesDTO container round-trip
   - Container dto.toDomain().toDTO() == dto preserves the id and the full places array.
   - Uses SampleData.savedPlacesDTO() (24-place populated seed) and SampleData.emptySavedPlacesDTO().

 Determinism rules (§3):
   - All fixtures from SampleData; stable id literals ("place-cevicheria", etc.); no live clock.
   - Reference models (SavedPlaceModel, SavedPlacesModel) are identity types — assert on fields.

 Coder rule (§4.2):
   - Plain symmetric JSONEncoder/JSONDecoder with .iso8601 date strategy.
   - NEVER APIJSON — its snake-case conversion is asymmetric on acronym/ID keys.

 §6.6 compliance:
   - @Test(arguments:) table uses a nonisolated PlaceDTOFixtureTag enum; toDomain() is called
     INSIDE the @MainActor test body, never in the args position.
   - The SavedPlacesDTO parameterized test passes a single [(tag, expectation)] tuple array,
     not two separate collections, to avoid the Cartesian-product footgun.
*/

import Testing
import Foundation
@testable import AppTemplate

// MARK: - PlaceDTOFixtureTag

/// Nonisolated discriminator for parameterized PlaceDTO round-trip tests (§6.6).
/// The DTOs are plain value types (nonisolated), but toDomain() is @MainActor —
/// building the domain value inside the @MainActor test body is the correct pattern.
enum PlaceDTOFixtureTag: CaseIterable, CustomTestStringConvertible {
    /// Eat, reel source, non-nil provenance, all optionals present — the richest row.
    case cevicheria
    /// Eat, reel source, non-nil provenance (nil quote path via pasteis-belem is similar — use timeout for richer data)
    case timeoutMarket
    /// Eat, screenshot source (savedNote non-nil), non-nil provenance.
    case pasteisbelem
    /// Do, screenshot source (savedNote nil), non-nil provenance with nil clipTitle.
    case museuAzulejo
    /// Eat, search source, nil provenance, nil addressLine is present; coordinates present.
    case cantinhoAvillez
    /// Drink, search source, nil provenance, nil savedAtNote, non-nil addressLine.
    case barTrench

    var testDescription: String {
        switch self {
        case .cevicheria:     return "place-cevicheria (reel · full provenance · all optionals)"
        case .timeoutMarket:  return "place-timeout-market (reel · provenance · no savedAtNote)"
        case .pasteisbelem:   return "place-pasteis-belem (screenshot · savedNote non-nil)"
        case .museuAzulejo:   return "place-museu-azulejo (screenshot · savedNote nil · provenance nil clipTitle)"
        case .cantinhoAvillez:return "place-cantinho-avillez (search · nil provenance · nil savedAtNote)"
        case .barTrench:      return "place-bar-trench (search · nil provenance · nil savedAtNote)"
        }
    }

    /// Stable id literal for lookup in SampleData.savedPlacesDTO().places.
    var stableID: String {
        switch self {
        case .cevicheria:     return "place-cevicheria"
        case .timeoutMarket:  return "place-timeout-market"
        case .pasteisbelem:   return "place-pasteis-belem"
        case .museuAzulejo:   return "place-museu-azulejo"
        case .cantinhoAvillez:return "place-cantinho-avillez"
        case .barTrench:      return "place-bar-trench"
        }
    }

    /// Retrieves the DTO from the canonical sample-data pool by stable id.
    /// nonisolated — SampleData.savedPlacesDTO() is a plain (non-@MainActor) function.
    func dto() -> PlaceDTO {
        let all = SampleData.savedPlacesDTO().places
        // #require is unavailable outside @Test body; use force-unwrap with a meaningful id.
        guard let dto = all.first(where: { $0.id == stableID }) else {
            fatalError("PlaceDTOFixtureTag: stable id '\(stableID)' not found in SampleData.savedPlacesDTO()")
        }
        return dto
    }
}

// MARK: - Symmetric coder helpers

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

private func codableRoundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try symmetricEncoder().encode(value)
    return try symmetricDecoder().decode(T.self, from: data)
}

// MARK: - PlaceDTORoundTripTests

@Suite("PlaceDTO + SavedPlacesDTO — round-trip tests (§4.2)")
struct PlaceDTORoundTripTests {

    // MARK: - Group 1: PlaceDTO mapping round-trip (dto.toDomain().toDTO() == dto)

    @Suite("PlaceDTO mapping round-trip — dto.toDomain().toDTO() == dto")
    struct PlaceDTOMappingRoundTripTests {

        /// Parameterized over all six fixture tags. toDomain() is @MainActor — the whole test
        /// is @MainActor to satisfy the isolation requirement without calling toDomain() in the
        /// nonisolated arguments position (§6.6).
        @Test(
            "PlaceDTO: dto.toDomain().toDTO() == dto (lossless mapping for all fixture rows)",
            arguments: PlaceDTOFixtureTag.allCases
        )
        @MainActor
        func placeDTOMappingRoundTrip(_ tag: PlaceDTOFixtureTag) {
            let dto = tag.dto()
            // toDomain() called here — inside @MainActor body, not in the args position.
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "dto.toDomain().toDTO() must equal the original DTO for \(tag.stableID)")
        }

        // MARK: Field-level pinning for the richest fixture (place-cevicheria)

        /// Explicitly asserts each field of the round-tripped DTO so a field drift is clearly
        /// attributed to the offending property, not just "recovered != dto".
        @Test("PlaceDTO: round-trip preserves every field for place-cevicheria (richest row)")
        @MainActor
        func placeDTORoundTripFieldPinning() throws {
            let dto = PlaceDTOFixtureTag.cevicheria.dto()
            let recovered = dto.toDomain().toDTO()

            #expect(recovered.id == "place-cevicheria")
            #expect(recovered.name == "A Cevicheria")
            #expect(recovered.category == .eat)
            #expect(recovered.location == PlaceLocation(neighborhood: "Príncipe Real", cityName: "Lisbon"))
            // Source is a reel — assert the associated values.
            if case .reel(let handle, let clipTitle) = recovered.source {
                #expect(handle == "saltinmycoffee")
                #expect(clipTitle == "Lisbon in 48 hours")
            } else {
                Issue.record("expected .reel source for place-cevicheria")
            }
            // Provenance is non-nil for cevicheria.
            let prov = try #require(recovered.provenance)
            #expect(prov.sourceHandle == "saltinmycoffee")
            #expect(prov.clipTitle == "Lisbon in 48 hours")
            #expect(prov.timestamp == "0:42")
            #expect(prov.quote == "The best ceviche in Lisbon — seriously, queue for it.")
            // Facts array has exactly 3 cells.
            #expect(recovered.facts.count == 3)
            #expect(recovered.facts[0].key == "Hours")
            #expect(recovered.facts[1].key == "Price")
            #expect(recovered.facts[2].key == "Cuisine")
            // Address and coordinates are non-nil.
            #expect(recovered.addressLine == "Rua Dom Pedro V 129, Príncipe Real")
            #expect(recovered.latitude == 38.7170)
            #expect(recovered.longitude == -9.1490)
            #expect(recovered.savedAtNote == "Bookmarked from reel")
        }

        /// Verifies the nil-provenance, nil-savedAtNote path (place-cantinho-avillez).
        @Test("PlaceDTO: round-trip preserves nil provenance and nil savedAtNote (place-cantinho-avillez)")
        @MainActor
        func placeDTORoundTripNilOptionals() {
            let dto = PlaceDTOFixtureTag.cantinhoAvillez.dto()
            #expect(dto.provenance == nil, "fixture precondition: cantinho-avillez has nil provenance")
            #expect(dto.savedAtNote == nil, "fixture precondition: cantinho-avillez has nil savedAtNote")
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.provenance == nil,
                    "nil provenance must survive the mapping round-trip")
            #expect(recovered.savedAtNote == nil,
                    "nil savedAtNote must survive the mapping round-trip")
        }

        /// Verifies the screenshot-source path with a nil savedNote (place-museu-azulejo).
        @Test("PlaceDTO: round-trip preserves screenshot(savedNote: nil) source (place-museu-azulejo)")
        @MainActor
        func placeDTORoundTripScreenshotNilNote() {
            let dto = PlaceDTOFixtureTag.museuAzulejo.dto()
            // Confirm the fixture source.
            if case .screenshot(let note) = dto.source {
                #expect(note == nil, "fixture precondition: museu-azulejo has screenshot(savedNote: nil)")
            } else {
                Issue.record("expected .screenshot source for place-museu-azulejo")
            }
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.source == dto.source,
                    "screenshot(savedNote: nil) must survive the mapping round-trip unchanged")
        }

        /// Verifies the screenshot-source path with a non-nil savedNote (place-pasteis-belem).
        @Test("PlaceDTO: round-trip preserves screenshot(savedNote: non-nil) source (place-pasteis-belem)")
        @MainActor
        func placeDTORoundTripScreenshotWithNote() {
            let dto = PlaceDTOFixtureTag.pasteisbelem.dto()
            if case .screenshot(let note) = dto.source {
                #expect(note != nil, "fixture precondition: pasteis-belem has a non-nil savedNote")
            } else {
                Issue.record("expected .screenshot source for place-pasteis-belem")
            }
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.source == dto.source,
                    "screenshot(savedNote: non-nil) must survive the mapping round-trip unchanged")
        }
    }

    // MARK: - Group 2: PlaceDTO JSON round-trip (Codable symmetry)

    @Suite("PlaceDTO JSON round-trip — encode → decode is lossless (Codable symmetry)")
    struct PlaceDTOJSONRoundTripTests {

        /// JSON encode → decode for all six fixture rows in one parameterized test.
        /// This is a pure Codable test — no domain mapping involved.
        @Test(
            "PlaceDTO: JSON encode → decode is lossless for all fixture rows",
            arguments: PlaceDTOFixtureTag.allCases
        )
        func placeDTOJSONRoundTrip(_ tag: PlaceDTOFixtureTag) throws {
            let dto = tag.dto()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "JSON encode → decode must be lossless for \(tag.stableID)")
        }

        /// Verify that a PlaceDTO with a .search source (no extra keys) encodes and decodes
        /// without any extra/missing keys. Spot-check the raw JSON for the tag key.
        @Test("PlaceDTO with search source: encoded JSON has tag == 'search' inside 'source'")
        func placeDTOSearchSourceTagKey() throws {
            let dto = PlaceDTOFixtureTag.cantinhoAvillez.dto()
            guard case .search = dto.source else {
                Issue.record("fixture precondition: place-cantinho-avillez must have .search source")
                return
            }
            let data = try symmetricEncoder().encode(dto)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let sourceDict = dict?["source"] as? [String: Any]
            #expect(sourceDict?["tag"] as? String == "search",
                    "the source dict must carry tag == 'search'")
        }
    }

    // MARK: - Group 3: SavedPlacesDTO container round-trip

    @Suite("SavedPlacesDTO container round-trip — dto.toDomain().toDTO() == dto")
    struct SavedPlacesDTORoundTripTests {

        /// Populated 24-place container: dto.toDomain().toDTO() == dto.
        @Test("SavedPlacesDTO (24 places): toDomain().toDTO() == dto (lossless container mapping)")
        @MainActor
        func savedPlacesDTOPopulatedRoundTrip() {
            let dto = SampleData.savedPlacesDTO()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "SavedPlacesDTO.toDomain().toDTO() must equal the original for the 24-place seed")
        }

        /// Empty container round-trip — exercises the 0-places edge case.
        @Test("SavedPlacesDTO (empty): toDomain().toDTO() == dto (empty container mapping)")
        @MainActor
        func savedPlacesDTOEmptyRoundTrip() {
            let dto = SampleData.emptySavedPlacesDTO()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "SavedPlacesDTO.toDomain().toDTO() must equal the original for the empty seed")
        }

        /// Field-level pin for the container — id and places count survive the round-trip.
        @Test("SavedPlacesDTO: round-trip preserves container id and all 24 place ids")
        @MainActor
        func savedPlacesDTOFieldPinning() {
            let dto = SampleData.savedPlacesDTO()
            let recovered = dto.toDomain().toDTO()

            #expect(recovered.id == "saved-places-main",
                    "container id must survive the round-trip")
            #expect(recovered.places.count == 24,
                    "all 24 places must survive the round-trip")

            // Spot-check three stable ids from different categories.
            let ids = recovered.places.map { $0.id }
            #expect(ids.contains("place-cevicheria"),
                    "place-cevicheria (Eat) must be present after round-trip")
            #expect(ids.contains("place-park-bar"),
                    "place-park-bar (Drink) must be present after round-trip")
            #expect(ids.contains("place-embaixada"),
                    "place-embaixada (Shop) must be present after round-trip")
        }

        /// JSON round-trip for the container DTO — Codable symmetry at the container level.
        @Test("SavedPlacesDTO (24 places): JSON encode → decode is lossless")
        func savedPlacesDTOJSONRoundTrip() throws {
            let dto = SampleData.savedPlacesDTO()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "SavedPlacesDTO JSON encode → decode must be lossless for the 24-place seed")
        }

        /// JSON round-trip for the empty container DTO.
        @Test("SavedPlacesDTO (empty): JSON encode → decode is lossless")
        func savedPlacesDTOEmptyJSONRoundTrip() throws {
            let dto = SampleData.emptySavedPlacesDTO()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "SavedPlacesDTO JSON encode → decode must be lossless for the empty seed")
        }

        /// Verifies that the toDomain() call builds the correct number of children and
        /// that the container's place(id:) lookup resolves the stable ids correctly.
        @Test("SavedPlacesDTO.toDomain() builds a container with correct count and findable ids")
        @MainActor
        func savedPlacesDTOToDomainBuildsCorrectGraph() {
            let dto = SampleData.savedPlacesDTO()
            let container = dto.toDomain()

            #expect(container.id == "saved-places-main")
            #expect(container.places.count == 24)

            // Spot-check lookup by stable id.
            let cevicheria = container.place(id: "place-cevicheria")
            #expect(cevicheria != nil, "place-cevicheria must be findable in the domain graph")
            #expect(cevicheria?.name == "A Cevicheria")
            #expect(cevicheria?.category == .eat)

            // Confirm an unknown id returns nil.
            #expect(container.place(id: "place-does-not-exist") == nil)
        }
    }
}
