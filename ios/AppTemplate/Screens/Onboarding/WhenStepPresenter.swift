/*
 Stateless derivation for onboarding step 03 — "when are you going?". Month-led: a month is always
 chosen; the precision segment (just the month / exact dates) says how specific. Exact dates are floored
 to the trip length chosen on the Trip Shape step (an exact range can't be shorter than the days asked
 for). The MainActor `AppDate` month math lives here (TripWhen stays a nonisolated value type).
*/
import Foundation

struct WhenStepPresenter {

    let store: AppStore

    private var draft: TripDraftModel? { store.onboarding }

    struct MonthOption: Identifiable, Hashable {
        let year: Int
        let month: Int
        let label: String
        var id: String { "\(year)-\(month)" }
    }

    // MARK: - When state

    var tripWhen: TripWhen { draft?.tripWhen ?? .seedDefault }

    var datePrecision: DatePrecision { tripWhen.precision }

    /// The trip length chosen on Trip Shape — the floor an exact range can't go below.
    var fixedDays: Int { draft?.tripDays ?? 4 }

    private var monthStart: Date { AppDate.make(y: tripWhen.year, m: tripWhen.month, d: 1) }

    var selectedMonthLabel: String { AppDate.monthYear.string(from: monthStart) }

    /// Twelve months forward from the app's fixed "now" — the month-menu options.
    var monthOptions: [MonthOption] {
        let calendar = AppDate.calendar
        let anchor = AppDate.make(
            y: calendar.component(.year, from: AppDate.simulatedNow),
            m: calendar.component(.month, from: AppDate.simulatedNow),
            d: 1
        )
        return (0..<12).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: anchor) else { return nil }
            return MonthOption(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date),
                label: AppDate.monthYear.string(from: date)
            )
        }
    }

    // MARK: - Exact-date pickers

    var exactStartDefault: Date { tripWhen.startDate ?? monthStart }

    /// The earliest allowed end — at least `fixedDays` (inclusive) from the start.
    var minEndDate: Date {
        AppDate.calendar.date(byAdding: .day, value: max(fixedDays - 1, 0), to: exactStartDefault)
            ?? exactStartDefault
    }

    var exactEndDefault: Date { tripWhen.endDate ?? minEndDate }

    var exactRangeFloorHint: String { "At least \(fixedDays) days" }

    // MARK: - Hero + CTA

    var eyebrow: String { "When" }

    var question: String { "When are you going?" }

    var sub: String {
        "We'll plan around your \(fixedDays) days. Pick a month — add exact dates if you have them."
    }

    var ctaTitle: String { "Continue" }
}
