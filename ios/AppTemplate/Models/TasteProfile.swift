import Foundation

// MARK: - Interest

/// A single travel interest the user selects during onboarding (Step 02, state C).
///
/// Mutually-exclusive values are collected into a `Set<Interest>` on ``TasteProfile``.
/// Raw `String` backing synthesises `Codable` for free (`02-models.md §3.1`).
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

    /// Display label shown on the interest chip in the taste form.
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
}

// MARK: - Pace

/// The preferred trip pace the user selects during onboarding (Step 02, state C).
///
/// Raw `String` backing synthesises `Codable` for free (`02-models.md §3.1`).
nonisolated enum Pace: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case easy
    case balanced
    case packed

    /// Display label shown on the pace segmented selector in the taste form.
    var label: String {
        switch self {
        case .easy:     return "Easy"
        case .balanced: return "Balanced"
        case .packed:   return "Packed"
        }
    }
}

// MARK: - TasteProfile

/// A snapshot of the user's taste preferences collected in the onboarding taste form
/// (Step 02, state C). Held as `TripDraft.tasteProfile: TasteProfile?`.
///
/// Leaf value type — already wire-safe; no separate DTO (`02-models.md §1.2`).
nonisolated struct TasteProfile: Codable, Equatable, Hashable, Sendable {
    /// Trip duration in days (driven by ``DayStepper``).
    var days: Int
    /// The set of interests the user toggled on.
    var interests: Set<Interest>
    /// The preferred pace for the trip.
    var pace: Pace
}
