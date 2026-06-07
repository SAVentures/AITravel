/*
 Wallet sample data — faithful to mockups/screens/wallet/wallet-populated.html,
 booking-detail.html, and access-card.html.

 Architecture:
 - `walletDTO()` / `emptyWalletDTO()` are the primary builders (Task 2.4, after DTOs exist).
   They are plain (not @MainActor) so they can be called from SampleData.seed(for:) without
   actor isolation.
 - `walletSimulatedNow` pins the clock to "today = Thu Aug 27" matching the mockup's
   now/today/upcoming statuses — so BookingStatus seeded values are deterministic.

 All ids are stable literals so previews/tests hard-link without UUID().

 COORDINATOR NOTE (Task 2.4):
 - `SampleData.seed(for:)` in SampleData.swift needs `.walletStandard`, `.walletEmpty`,
   and `.walletError` cases wired to the builders below.
 - `MockSeed.swift` needs `var wallet: TripWalletDTO?` (defaulted nil).
 - `MockScenario.swift` needs `.walletStandard`, `.walletEmpty`, `.walletError` cases.
 These are serial shared-file edits; do not add them here (02-models §5 seeding convention).
*/
import Foundation

extension SampleData {

    // MARK: - simulatedNow

    /// Fixed clock for all time-conditional state in the Wallet seed.
    /// Pinned to Thu 2025-08-28 12:00 UTC — "today = Thu Aug 27" in the mockup
    /// (using 28 so Aug 27 is yesterday = past, Day 2 is today, matching now/today statuses).
    /// If OD-3 upgrades BookingStatus to computed-from-simulatedNow, this is the seam.
    static var walletSimulatedNow: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 8
        components.day = 28
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - Leaf value type fixtures (used by the DTO builders in Task 2.4)

    // TAP Air TP 201 access pass (faithful to access-card.html / booking-detail.html)
    static func tap201AccessPass() -> AccessPass {
        AccessPass(
            kindLabel: "Boarding pass",
            title: "LIS → JFK · TP 201",
            subtitle: "Zé Maria · Sat, Aug 29 · boards 13:05",
            qrPayload: "7XQK2M",
            confirmation: "7XQK2M",
            metaCells: [
                PlaceFacts(key: "Gate", value: "24"),
                PlaceFacts(key: "Seat", value: "14A"),
                PlaceFacts(key: "Zone", value: "2")
            ]
        )
    }

    // Booking detail for the TP 201 flight (faithful to booking-detail.html)
    static func tap201DetailInfo() -> BookingDetailInfo {
        BookingDetailInfo(
            kind: "Flight",
            infoCells: [
                PlaceFacts(key: "Depart", value: "13:40", sub: "LIS T2"),
                PlaceFacts(key: "Arrive", value: "16:05", sub: "JFK T4"),
                PlaceFacts(key: "Seat", value: "14A", sub: "Economy")
            ],
            detailRows: [
                DetailRow(key: "Airline", value: "TAP Air Portugal"),
                DetailRow(key: "Flight", value: "TP 201"),
                DetailRow(key: "Aircraft", value: "Airbus A330-200"),
                DetailRow(key: "Duration", value: "7h 25m"),
                DetailRow(key: "Baggage", value: "1× 23 kg checked")
            ],
            placedLabel: "Placed on Day 4 · Sat, Aug 29"
        )
    }
}
