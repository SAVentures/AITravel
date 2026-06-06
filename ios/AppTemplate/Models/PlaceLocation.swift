import Foundation

// MARK: - PlaceLocation

/*
 Free-text neighborhood + city name for a saved place. Distinct from the onboarding
 `Neighborhood` type (which carries reach/scoring data). Leaf value type — wire-safe, no DTO.
*/
nonisolated struct PlaceLocation: Codable, Equatable, Hashable, Sendable {
    var neighborhood: String
    var cityName: String

    /// One-line display string, e.g. "Príncipe Real · Lisbon".
    var displayLine: String { "\(neighborhood) · \(cityName)" }
}
