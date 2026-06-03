import Foundation

/*
 The single home for date formatting and construction in the model layer. Every
 formatter is pinned to UTC + en_US_POSIX and every date is built from these helpers,
 never the live clock — so time/locale-conditional state renders identically on every
 machine and test, regardless of host region.

 Never call Date() / Calendar.current / Locale.current in app or model code. Time-
 conditional logic takes a now: Date sourced from the store's simulatedNow (below).
*/
enum AppDate {

    // MARK: Pinned primitives

    static let timeZone = TimeZone(identifier: "UTC")!

    static let locale = Locale(identifier: "en_US_POSIX")

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        return calendar
    }()

    // MARK: Formatters

    static let dueDate: DateFormatter = make(format: "MMM d")          // e.g. "Jun 1"

    static let full: DateFormatter = make(format: "EEEE, MMM d")       // e.g. "Sunday, Jun 1"

    static let monthYear: DateFormatter = make(format: "LLLL yyyy")    // e.g. "June 2026"

    // MARK: Deterministic construction

    /// The only sanctioned way to construct a `Date` in seeds and tests — never reaches
    /// the live clock, so the result is identical on every run.
    static func make(y: Int, m: Int, d: Int, h: Int = 0, min: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: y, month: m, day: d, hour: h, minute: min
        )
        // Pinned components in a pinned calendar always resolve; the force-unwrap
        // documents that a malformed literal is a programmer error, not a runtime path.
        return calendar.date(from: components)!
    }

    /// The app's fixed "now" — a stable literal instant, not `Date()`. The store exposes
    /// this as its `simulatedNow`; the model layer reads it rather than the live clock.
    static let simulatedNow: Date = make(y: 2026, m: 6, d: 1, h: 12, min: 0)

    // MARK: -

    private static func make(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.calendar = calendar
        formatter.dateFormat = format
        return formatter
    }
}
