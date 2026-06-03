import Foundation

/// The single home for date *formatting* and *construction* in the model layer.
///
/// Every formatter is **pinned** — a fixed time zone (UTC) and the `en_US_POSIX`
/// locale — and every date the app reasons about is built from these helpers, never
/// from the live clock. That pinning is what makes time- and locale-conditional state
/// (an *overdue* badge, a due-date label) render identically on every machine, in
/// every test, regardless of the host's region or zone (`02-models.md §6`,
/// `07-testing.md §3` — determinism).
///
/// **Never call `Date()` / `Calendar.current` / `Locale.current`** in app or model
/// code. Time-conditional logic takes a `now: Date` argument supplied from the store's
/// `simulatedNow`, which is sourced from ``AppDate/simulatedNow`` here.
enum AppDate {

    // MARK: Pinned primitives

    /// The fixed time zone all formatting and construction use. UTC so a date built
    /// from y/m/d components lands on the same instant everywhere.
    static let timeZone = TimeZone(identifier: "UTC")!

    /// The fixed, region-independent locale. `en_US_POSIX` is the canonical choice for
    /// stable, machine-readable formatting that never shifts with the host's settings.
    static let locale = Locale(identifier: "en_US_POSIX")

    /// The calendar all component-based construction goes through — Gregorian, pinned
    /// to the fixed zone and locale above.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        return calendar
    }()

    // MARK: Formatters (lazy statics — created once, reused)

    /// Borrow due dates, e.g. `"Jun 1"`.
    static let dueDate: DateFormatter = make(format: "MMM d")

    /// Detail headers, e.g. `"Sunday, Jun 1"`.
    static let full: DateFormatter = make(format: "EEEE, MMM d")

    // MARK: Deterministic construction

    /// Builds a date from explicit components in the pinned calendar — the only
    /// sanctioned way to construct a `Date` in seeds and tests. Never reaches the live
    /// clock, so the result is identical on every run.
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

    /// The app's fixed "now". A stable literal instant — **not** `Date()` — so every
    /// time-conditional surface (overdue badges, relative labels) is deterministic in
    /// previews, tests, and the running mock app. The store exposes this as its
    /// `simulatedNow`; the model layer reads it rather than the live clock.
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
