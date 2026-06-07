import Foundation

/*
 BookingType — mutually-exclusive booking category.
 Leaf value type: raw-String enum synthesises Codable for free.
 Already wire-safe; no separate DTO. No SwiftUI dependency — color/tint
 lives in ColorRole.bookingTint/bookingMark (design-system layer).
 `systemImage` keeps SF Symbol choice out of views and models; presenters
 pass this through to components that accept a systemImage argument.
*/

// MARK: - BookingType

nonisolated enum BookingType: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case lodging
    case transport
    case activity
    case dining
    case other

    var displayLabel: String {
        switch self {
        case .lodging:   return "Lodging"
        case .transport: return "Transport"
        case .activity:  return "Activity"
        case .dining:    return "Dining"
        case .other:     return "Other"
        }
    }

    /// SF Symbol per booking type.
    /// Keeping glyph choice here (the model layer) rather than in views
    /// means every presenter and component reads the same symbol.
    var systemImage: String {
        switch self {
        case .lodging:   return "bed.double"
        case .transport: return "airplane"
        case .activity:  return "ticket"
        case .dining:    return "fork.knife"
        case .other:     return "mappin"
        }
    }
}
