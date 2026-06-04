import Foundation

/*
 Taste preferences collected in the onboarding taste form (Step 02, state C):
 Interest · Pace · TasteProfile. Leaf value types — already wire-safe, no separate DTO.
 Raw-String backing on the enums synthesises Codable for free.
*/

// MARK: - Interest

nonisolated enum Interest: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case food
    case history
    case coffee
    case architecture
    case views
    case nightlife
    case markets
    case nature
    case art

    var label: String {
        switch self {
        case .food:         return "Food"
        case .history:      return "History"
        case .coffee:       return "Coffee"
        case .architecture: return "Architecture"
        case .views:        return "Views"
        case .nightlife:    return "Nightlife"
        case .markets:      return "Markets"
        case .nature:       return "Nature"
        case .art:          return "Art"
        }
    }

    var systemImage: String {
        switch self {
        case .food:         return "fork.knife"
        case .history:      return "building.columns"
        case .coffee:       return "cup.and.saucer"
        case .architecture: return "building.2"
        case .views:        return "binoculars"
        case .nightlife:    return "moon.stars"
        case .markets:      return "bag"
        case .nature:       return "leaf"
        case .art:          return "paintpalette"
        }
    }
}

// MARK: - Pace

nonisolated enum Pace: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case easy
    case balanced
    case packed

    var label: String {
        switch self {
        case .easy:     return "Easy"
        case .balanced: return "Balanced"
        case .packed:   return "Packed"
        }
    }
}

// MARK: - TasteProfile

// Held as TripDraftModel.tasteProfile: TasteProfile?.
nonisolated struct TasteProfile: Codable, Equatable, Hashable, Sendable {
    var days: Int
    var interests: Set<Interest>
    var pace: Pace
}
