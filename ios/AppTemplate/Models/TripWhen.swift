/*
 Onboarding "when" — the month-led travel-dates value type held on TripDraftModel. Captured on the Trip
 Shape step alongside trip length. A month is always chosen; `precision` says how specific the user got:
 just the month, flexible around it, or an exact start→end range. Coordinates/dates are flat `Date`,
 built only via AppDate (never the live clock), so seeds + tests stay deterministic.
*/
import Foundation

// MARK: - DatePrecision

nonisolated enum DatePrecision: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case justMonth   // a rough month, no specific days
    case exactDates  // a concrete start→end range

    var label: String {
        switch self {
        case .justMonth:  "Just the month"
        case .exactDates: "Exact dates"
        }
    }
}

// MARK: - TripWhen

nonisolated struct TripWhen: Codable, Equatable, Hashable, Sendable {

    var precision: DatePrecision
    var year: Int
    var month: Int            // 1...12
    var startDate: Date?      // set when precision == .exactDates
    var endDate: Date?

    init(
        precision: DatePrecision = .justMonth,
        year: Int,
        month: Int,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.precision = precision
        self.year = year
        self.month = month
        self.startDate = startDate
        self.endDate = endDate
    }

    /// The seed default: a rough month framing on the app's fixed "now" (`AppDate.simulatedNow` = Jun 2026).
    /// Kept as plain literals so this stays usable from the `nonisolated` DTO/value layer (AppDate is
    /// MainActor-isolated). The MainActor presenter/model do the live `AppDate` month math.
    static let seedDefault = TripWhen(precision: .justMonth, year: 2026, month: 6)
}
