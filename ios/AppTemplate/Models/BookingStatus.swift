import Foundation

/*
 BookingStatus — mutually-exclusive display status for a booking.
 Leaf value type: raw-String enum synthesises Codable for free.
 Already wire-safe; no separate DTO. No SwiftUI dependency — fill/label
 color lives in the StatusPill component (design-system layer).

 Stored as seeded value data (OD-3: deterministic, no live-clock derivation).
 Computing from simulatedNow + per-booking dates is a later upgrade.
*/

// MARK: - BookingStatus

nonisolated enum BookingStatus: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case upcoming
    case today
    case now
    case past

    var displayLabel: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .today:    return "Today"
        case .now:      return "Now"
        case .past:     return "Past"
        }
    }
}
