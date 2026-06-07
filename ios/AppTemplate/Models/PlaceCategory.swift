import Foundation

/*
 PlaceCategory — mutually-exclusive category for a saved place.
 Leaf value type: raw-String enum synthesises Codable for free.
 Already wire-safe; no separate DTO. No SwiftUI dependency — color/tint
 lives in ColorRole.categoryTint (design-system layer).
*/

// MARK: - PlaceCategory

nonisolated enum PlaceCategory: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case eat
    case drink
    case stay
    case `do`
    case shop

    var displayLabel: String {
        switch self {
        case .eat:   return "Eat"
        case .drink: return "Drink"
        case .stay:  return "Stay"
        case .do:    return "Do"
        case .shop:  return "Shop"
        }
    }
}
