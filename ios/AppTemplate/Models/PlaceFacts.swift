import Foundation

// MARK: - PlaceFacts

/*
 One cell in the place-detail info grid (hours, price tier, cuisine, etc.).
 `key` is the label (e.g. "Hours"), `value` is the primary content (e.g. "9 am – 11 pm"),
 `sub` is an optional secondary line (e.g. "Closed Mondays"). Leaf value type — wire-safe, no DTO.
*/
nonisolated struct PlaceFacts: Codable, Equatable, Hashable, Sendable {
    var key: String
    var value: String
    var sub: String?
}
