import Foundation

/*
 BookingDetailInfo — the booking-detail payload stored on a BookingModel.
 Leaf value type — wire-safe, no DTO.

 PlaceFacts reuse decision (OD-7 prerequisite):
 PlaceFacts { var key: String; var value: String; var sub: String? } is an exact
 structural match for the info-cell shape (key label / primary value / optional
 secondary line). Reusing PlaceFacts for `infoCells` lets the BookingInfoGrid
 component reuse PlaceInfoGrid's anatomy (per OD-7), and avoids a duplicate type.
 No InfoCell type is defined — PlaceFacts serves both roles.

 `kind`       — display string for the booking category header (e.g. "Flight").
 `infoCells`  — 3-cell hairline info grid (BookingInfoGrid component, Wave 1).
 `detailRows` — quiet key/value list (DetailList component, Wave 1).
 `placedLabel`— optional "Placed on Day N · date" copy (PlacedChip component).
*/

// MARK: - BookingDetailInfo

nonisolated struct BookingDetailInfo: Codable, Equatable, Hashable, Sendable {
    var kind: String
    var infoCells: [PlaceFacts]
    var detailRows: [DetailRow]
    var placedLabel: String?
}
