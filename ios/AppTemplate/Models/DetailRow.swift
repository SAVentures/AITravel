import Foundation

/*
 DetailRow — one key/value row in the booking-detail quiet list (.det-list/.det-row).
 Leaf value type — wire-safe, no DTO. Used by BookingDetailInfo.detailRows
 and rendered by the DetailList component (Wave 1).
*/

// MARK: - DetailRow

nonisolated struct DetailRow: Codable, Equatable, Hashable, Sendable {
    var key: String
    var value: String
}
