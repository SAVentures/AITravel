/*
 Layer 1 — Unit tests for the BookingDTO ↔ BookingModel / TripWalletDTO ↔ TripWalletModel
 round-trip (§4.2).

 Group 1: BookingDTO mapping round-trip
   - dto.toDomain().toDTO() == dto for each representative fixture row indexed by stable id.
   - Covers nil/non-nil optional fields: dayIndex, startTime, confirmation, detail, accessPass.
   - The richest fixture (booking-tap201) has a full BookingDetailInfo + AccessPass; verifying
     that proves nested value types are mapped completely.
   - Parameterized over a nonisolated BookingDTOFixtureTag enum; toDomain() runs @MainActor (§6.6).

 Group 2: BookingDTO JSON round-trip
   - encode(dto) → decode → dto2 with the plain symmetric coder — guards Codable symmetry.

 Group 3: TripWalletDTO container round-trip
   - Container dto.toDomain().toDTO() == dto preserves the id, tripCityName, dayCount, and all
     9 booking rows (8 placed + 1 orphan).
   - Uses SampleData.walletDTO() (populated, 9 bookings) and SampleData.emptyWalletDTO().

 Determinism rules (§3):
   - All fixtures from SampleData; stable id literals; no live clock.
   - Reference models (TripWalletModel, BookingModel) are identity types — assert on fields.

 Coder rule (§4.2):
   - Plain symmetric JSONEncoder/JSONDecoder with .iso8601 date strategy.
   - NEVER APIJSON — its snake-case conversion is asymmetric on acronym/ID keys.

 §6.6 compliance:
   - @Test(arguments:) table uses a nonisolated BookingDTOFixtureTag enum; toDomain() called
     INSIDE the @MainActor test body, never in the args position.
   - The TripWalletDTO parameterized tests pass single [(tag, expectation)] arrays to avoid
     the Cartesian-product footgun.
*/

import Testing
import Foundation
@testable import AppTemplate

// MARK: - BookingDTOFixtureTag

/// Nonisolated discriminator for parameterized BookingDTO round-trip tests (§6.6).
/// The DTOs are plain value types (nonisolated); toDomain() is @MainActor — build
/// the domain value inside the @MainActor test body.
enum BookingDTOFixtureTag: CaseIterable, CustomTestStringConvertible {
    /// Past lodging, Day 1, has confirmation, no detail/accessPass.
    case casaBairro
    /// Past dining, Day 1, nil startTime and confirmation.
    case timeoutMarket
    /// Activity-now, Day 2, has confirmation, no detail/accessPass.
    case castelo
    /// Transport-today, Day 2, nil confirmation.
    case ferry
    /// Upcoming activity, Day 3, has confirmation.
    case jeronimos
    /// Upcoming transport, Day 4, has confirmation + full BookingDetailInfo + AccessPass.
    case tap201
    /// Orphan (nil dayIndex), upcoming activity, has confirmation.
    case fadoOrphan

    var testDescription: String {
        switch self {
        case .casaBairro:   return "booking-casa-bairro (past lodging · Day 1 · confirmation)"
        case .timeoutMarket:return "booking-timeout (past dining · Day 1 · nil confirmation)"
        case .castelo:      return "booking-castelo (activity-now · Day 2 · confirmation)"
        case .ferry:        return "booking-ferry (transport-today · Day 2 · nil confirmation)"
        case .jeronimos:    return "booking-jeronimos (upcoming activity · Day 3 · confirmation)"
        case .tap201:       return "booking-tap201 (transport · Day 4 · detail + accessPass)"
        case .fadoOrphan:   return "booking-fado-orphan (orphan · nil dayIndex · confirmation)"
        }
    }

    var stableID: String {
        switch self {
        case .casaBairro:   return "booking-casa-bairro"
        case .timeoutMarket:return "booking-timeout"
        case .castelo:      return "booking-castelo"
        case .ferry:        return "booking-ferry"
        case .jeronimos:    return "booking-jeronimos"
        case .tap201:       return "booking-tap201"
        case .fadoOrphan:   return "booking-fado-orphan"
        }
    }

    /// Retrieves the DTO from the canonical wallet sample-data pool by stable id.
    /// nonisolated — SampleData.walletDTO() is a plain (non-@MainActor) function.
    func dto() -> BookingDTO {
        let all = SampleData.walletDTO().bookings
        guard let dto = all.first(where: { $0.id == stableID }) else {
            fatalError("BookingDTOFixtureTag: stable id '\(stableID)' not found in SampleData.walletDTO()")
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

// MARK: - BookingDTORoundTripTests

@Suite("BookingDTO + TripWalletDTO — round-trip tests (§4.2)")
struct BookingDTORoundTripTests {

    // MARK: - Group 1: BookingDTO mapping round-trip (dto.toDomain().toDTO() == dto)

    @Suite("BookingDTO mapping round-trip — dto.toDomain().toDTO() == dto")
    struct BookingDTOMappingRoundTripTests {

        /// Parameterized over all seven fixture tags. toDomain() is @MainActor — the whole
        /// test is @MainActor so toDomain() is called inside the body, never in the args (§6.6).
        @Test(
            "BookingDTO: dto.toDomain().toDTO() == dto (lossless mapping for all fixture rows)",
            arguments: BookingDTOFixtureTag.allCases
        )
        @MainActor
        func bookingDTOMappingRoundTrip(_ tag: BookingDTOFixtureTag) {
            let dto = tag.dto()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "dto.toDomain().toDTO() must equal the original DTO for \(tag.stableID)")
        }

        /// Field-level pinning for the richest fixture (booking-tap201: has detail + accessPass).
        @Test("BookingDTO: round-trip preserves every field for booking-tap201 (richest row)")
        @MainActor
        func bookingDTORoundTripFieldPinning() throws {
            let dto = BookingDTOFixtureTag.tap201.dto()
            let recovered = dto.toDomain().toDTO()

            #expect(recovered.id == "booking-tap201")
            #expect(recovered.title == "Lisbon → New York")
            #expect(recovered.type == .transport)
            #expect(recovered.status == .upcoming)
            #expect(recovered.dayIndex == 4)
            #expect(recovered.startTime == "Departs 13:40")
            #expect(recovered.subtitleParts == ["TAP Air · TP 201", "seat 14A"])
            #expect(recovered.confirmation == "7XQK2M")

            // detail is non-nil for tap201
            let detail = try #require(recovered.detail)
            #expect(detail.kind == "Flight")
            #expect(detail.infoCells.count == 3)
            #expect(detail.infoCells[0].key == "Depart")
            #expect(detail.infoCells[1].key == "Arrive")
            #expect(detail.infoCells[2].key == "Seat")
            #expect(detail.detailRows.count == 5)
            #expect(detail.placedLabel == "Placed on Day 4 · Sat, Aug 29")

            // accessPass is non-nil for tap201
            let pass = try #require(recovered.accessPass)
            #expect(pass.kindLabel == "Boarding pass")
            #expect(pass.title == "LIS → JFK · TP 201")
            #expect(pass.confirmation == "7XQK2M")
            #expect(pass.qrPayload == "7XQK2M")
            #expect(pass.metaCells.count == 3)
        }

        /// Verifies the nil-dayIndex (orphan) path (booking-fado-orphan).
        @Test("BookingDTO: round-trip preserves nil dayIndex (orphan booking-fado-orphan)")
        @MainActor
        func bookingDTORoundTripNilDayIndex() {
            let dto = BookingDTOFixtureTag.fadoOrphan.dto()
            #expect(dto.dayIndex == nil, "fixture precondition: booking-fado-orphan has nil dayIndex")
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.dayIndex == nil,
                    "nil dayIndex must survive the mapping round-trip")
        }

        /// Verifies nil optional fields (booking-ferry: nil confirmation, no detail, no accessPass).
        @Test("BookingDTO: round-trip preserves nil confirmation / nil detail / nil accessPass (booking-ferry)")
        @MainActor
        func bookingDTORoundTripNilOptionals() {
            let dto = BookingDTOFixtureTag.ferry.dto()
            #expect(dto.confirmation == nil, "fixture precondition: booking-ferry has nil confirmation")
            #expect(dto.detail == nil, "fixture precondition: booking-ferry has nil detail")
            #expect(dto.accessPass == nil, "fixture precondition: booking-ferry has nil accessPass")
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.confirmation == nil,
                    "nil confirmation must survive the mapping round-trip")
            #expect(recovered.detail == nil,
                    "nil detail must survive the mapping round-trip")
            #expect(recovered.accessPass == nil,
                    "nil accessPass must survive the mapping round-trip")
        }

        /// Verifies the .now status path (booking-castelo).
        @Test("BookingDTO: round-trip preserves .now status (booking-castelo)")
        @MainActor
        func bookingDTORoundTripNowStatus() {
            let dto = BookingDTOFixtureTag.castelo.dto()
            #expect(dto.status == .now, "fixture precondition: booking-castelo has .now status")
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.status == .now,
                    "status .now must survive the mapping round-trip")
        }

        /// Verifies the .past status path (booking-casa-bairro).
        @Test("BookingDTO: round-trip preserves .past status (booking-casa-bairro)")
        @MainActor
        func bookingDTORoundTripPastStatus() {
            let dto = BookingDTOFixtureTag.casaBairro.dto()
            #expect(dto.status == .past, "fixture precondition: booking-casa-bairro has .past status")
            let recovered = dto.toDomain().toDTO()
            #expect(recovered.status == .past,
                    "status .past must survive the mapping round-trip")
        }
    }

    // MARK: - Group 2: BookingDTO JSON round-trip (Codable symmetry)

    @Suite("BookingDTO JSON round-trip — encode → decode is lossless (Codable symmetry)")
    struct BookingDTOJSONRoundTripTests {

        /// JSON encode → decode for all seven fixture rows.
        @Test(
            "BookingDTO: JSON encode → decode is lossless for all fixture rows",
            arguments: BookingDTOFixtureTag.allCases
        )
        func bookingDTOJSONRoundTrip(_ tag: BookingDTOFixtureTag) throws {
            let dto = tag.dto()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "JSON encode → decode must be lossless for \(tag.stableID)")
        }

        /// Verify the BookingType rawValue encodes and round-trips correctly.
        @Test("BookingDTO: type raw value 'transport' survives JSON round-trip")
        func bookingDTOTypeRawValueRoundTrip() throws {
            let dto = BookingDTOFixtureTag.tap201.dto()
            #expect(dto.type == .transport)
            let data = try symmetricEncoder().encode(dto)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["type"] as? String == "transport",
                    "BookingType rawValue must encode as its String rawValue")
        }

        /// Verify BookingStatus rawValue 'now' encodes and round-trips correctly.
        @Test("BookingDTO: status raw value 'now' survives JSON round-trip")
        func bookingDTOStatusNowRawValueRoundTrip() throws {
            let dto = BookingDTOFixtureTag.castelo.dto()
            #expect(dto.status == .now)
            let data = try symmetricEncoder().encode(dto)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["status"] as? String == "now",
                    "BookingStatus .now must encode as 'now'")
        }

        /// Verify the nested AccessPass encodes under 'accessPass' key.
        @Test("BookingDTO: accessPass encodes under the key 'accessPass'")
        func bookingDTOAccessPassKeyInJSON() throws {
            let dto = BookingDTOFixtureTag.tap201.dto()
            #expect(dto.accessPass != nil, "fixture precondition: tap201 has an accessPass")
            let data = try symmetricEncoder().encode(dto)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let passDict = dict?["accessPass"] as? [String: Any]
            #expect(passDict != nil, "accessPass must be encoded under the key 'accessPass'")
            #expect(passDict?["confirmation"] as? String == "7XQK2M",
                    "the nested confirmation must encode correctly inside accessPass")
        }
    }

    // MARK: - Group 3: TripWalletDTO container round-trip

    @Suite("TripWalletDTO container round-trip — dto.toDomain().toDTO() == dto")
    struct TripWalletDTORoundTripTests {

        /// Populated 9-booking container (8 placed + 1 orphan): dto.toDomain().toDTO() == dto.
        @Test("TripWalletDTO (9 bookings): toDomain().toDTO() == dto (lossless container mapping)")
        @MainActor
        func tripWalletDTOPopulatedRoundTrip() {
            let dto = SampleData.walletDTO()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "TripWalletDTO.toDomain().toDTO() must equal the original for the populated seed")
        }

        /// Empty container round-trip — exercises the 0-bookings edge case.
        @Test("TripWalletDTO (empty): toDomain().toDTO() == dto (empty container mapping)")
        @MainActor
        func tripWalletDTOEmptyRoundTrip() {
            let dto = SampleData.emptyWalletDTO()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto,
                    "TripWalletDTO.toDomain().toDTO() must equal the original for the empty seed")
        }

        /// Field-level pin — id, tripCityName, dayCount, and all 9 booking ids survive.
        @Test("TripWalletDTO: round-trip preserves container fields and all 9 booking ids")
        @MainActor
        func tripWalletDTOFieldPinning() {
            let dto = SampleData.walletDTO()
            let recovered = dto.toDomain().toDTO()

            #expect(recovered.id == "wallet-lisbon",
                    "container id must survive the round-trip")
            #expect(recovered.tripCityName == "Lisbon",
                    "tripCityName must survive the round-trip")
            #expect(recovered.dayCount == 4,
                    "dayCount must survive the round-trip")
            #expect(recovered.bookings.count == 9,
                    "all 9 bookings must survive the round-trip")

            // Spot-check stable ids
            let ids = recovered.bookings.map { $0.id }
            #expect(ids.contains("booking-tap201"),
                    "booking-tap201 must be present after round-trip")
            #expect(ids.contains("booking-fado-orphan"),
                    "booking-fado-orphan (orphan) must be present after round-trip")
            #expect(ids.contains("booking-castelo"),
                    "booking-castelo must be present after round-trip")
        }

        /// JSON round-trip for the container DTO.
        @Test("TripWalletDTO (9 bookings): JSON encode → decode is lossless")
        func tripWalletDTOJSONRoundTrip() throws {
            let dto = SampleData.walletDTO()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "TripWalletDTO JSON encode → decode must be lossless for the populated seed")
        }

        /// JSON round-trip for the empty container.
        @Test("TripWalletDTO (empty): JSON encode → decode is lossless")
        func tripWalletDTOEmptyJSONRoundTrip() throws {
            let dto = SampleData.emptyWalletDTO()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto,
                    "TripWalletDTO JSON encode → decode must be lossless for the empty seed")
        }

        /// Verifies that toDomain() builds the correct child count and that
        /// TripWalletModel.booking(id:) resolves the stable ids correctly.
        @Test("TripWalletDTO.toDomain() builds a container with correct count and findable ids")
        @MainActor
        func tripWalletDTOToDomainBuildsCorrectGraph() {
            let dto = SampleData.walletDTO()
            let container = dto.toDomain()

            #expect(container.id == "wallet-lisbon")
            #expect(container.bookings.count == 9)

            // Spot-check lookup by stable id
            let tap201 = container.booking(id: "booking-tap201")
            #expect(tap201 != nil, "booking-tap201 must be findable in the domain graph")
            #expect(tap201?.title == "Lisbon → New York")
            #expect(tap201?.type == .transport)

            // The orphan must be present and have nil dayIndex
            let orphan = container.booking(id: "booking-fado-orphan")
            #expect(orphan != nil, "booking-fado-orphan must be findable in the domain graph")
            #expect(orphan?.dayIndex == nil, "orphan must have nil dayIndex in the domain graph")

            // Unknown id returns nil
            #expect(container.booking(id: "booking-does-not-exist") == nil)
        }
    }
}
