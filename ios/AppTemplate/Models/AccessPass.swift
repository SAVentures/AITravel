import Foundation

/*
 AccessPass — the day-of boarding-pass / access-card payload stored on a BookingModel.
 Leaf value type — wire-safe, no DTO. Present only on bookings that have a pass
 (e.g. the TAP Air TP 201 flight). Rendered by AccessPassCard (Wave 1).

 `kindLabel`    — "Boarding pass", "Timed entry", etc. (.acc-band label)
 `title`        — primary pass line, e.g. "LIS → JFK · TP 201"
 `subtitle`     — secondary pass line, e.g. "Zé Maria · Sat, Aug 29 · boards 13:05"
 `qrPayload`    — string encoded into the QR code (CoreImage CIQRCodeGenerator)
 `confirmation` — mono confirmation code shown below the QR (.cap)
 `metaCells`    — 3-cell hairline grid (Gate/Seat/Zone); reuses PlaceFacts
                  (same structural fit as BookingDetailInfo.infoCells — see that
                  file's OD-7 note).
*/

// MARK: - AccessPass

nonisolated struct AccessPass: Codable, Equatable, Hashable, Sendable {
    var kindLabel: String
    var title: String
    var subtitle: String
    var qrPayload: String
    var confirmation: String
    var metaCells: [PlaceFacts]
}
