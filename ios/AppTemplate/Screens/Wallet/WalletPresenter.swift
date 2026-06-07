/*
 Stateless derivation for the Travel-wallet keystone screen (WalletView). Given the store + the screen's
 ephemeral UI state (the `filter` selection), it derives the DATA the two states render — never a View
 (06-screens §3). Rebuilt each `body` pass; constructed in `body` so the store's per-field dependency
 tracking is preserved.

 Ports the two state mockups (mockups/screens/wallet/):
 - wallet-populated  → `heroContext`, `filterChips`, `orphan` (the AI placement prompt), and the grouped
                       `dayGroups` (DayGroupHeader + BookingRows). The "By type" / "Orphans" chips re-derive
                       the grouping so every chip is a real sink.
 - wallet-empty      → `emptyTitle`/`emptyBody` + `wayToSave` (three WayToSaveRowModels) when the wallet
                       holds no bookings at all.

 Reads `store.wallet`. The reference-model rows (`BookingModel`) are read here only to map them into the
 design-system components' value-type fixtures (`BookingRowModel` / `OrphanPromptModel` / `WayToSaveRowModel`)
 — the components never see `AppStore` or a domain object (01-arch §3, 05 §8). The presenter supplies each
 row's `systemImage` (from `BookingType.systemImage`), composes the meta string (from `startTime` +
 `subtitleParts`), and picks the leading `timeEmphasis` slice (the `startTime`).
*/
import Foundation

// MARK: - Filter (ephemeral UI state shared by the view + presenter)

/// The wallet's grouping/filter — the `FilterChip` selection (mockup `.chips`). Ephemeral UI state
/// (06 §3), not domain state.
enum WalletFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case byDay
    case byType
    case orphans

    var id: String { rawValue }
    var label: String {
        switch self {
        case .byDay:   return "By day"
        case .byType:  return "By type"
        case .orphans: return "Orphans"
        }
    }
}

// MARK: - Derived view-models (DATA, not Views)

/// One grouped block — the mockup `.daygrp` header over its `BookingRow`s. In `.byDay` it is a trip day
/// (Day N + date eyebrow + the today flag); in `.byType` the `dayLabel` carries the booking-type label and
/// the date eyebrow is empty. `rows` are the already-mapped row fixtures.
struct WalletDayGroup: Identifiable, Sendable {
    /// Stable identity — the day index for `.byDay`, the type raw value for `.byType`.
    let id: String
    /// The header lead — "Day 2" (by day) or "Activity" (by type) (mockup `.daygrp .n`).
    let dayLabel: String
    /// The date eyebrow — "Thu · Aug 27" / "Thu · Aug 27 · today" (mockup `.daygrp .d`); empty by type.
    let dateLabel: String
    /// Whether this is the trip's current day (drives the header "today" register).
    let isToday: Bool
    let rows: [BookingRowModel]
}

// MARK: - One filter-chip view-model (mockup `.chips .chip`)

struct WalletFilterChip: Identifiable, Sendable {
    let filter: WalletFilter
    let label: String
    /// The orphan count badge (only the `.orphans` chip carries one; `nil` shows no count/dot).
    let count: Int?

    var id: String { filter.id }
}

// MARK: - WalletPresenter

struct WalletPresenter {

    let store: AppStore
    /// The active grouping/filter (ephemeral `@State` the presenter re-derives on).
    let filter: WalletFilter

    init(store: AppStore, filter: WalletFilter = .byDay) {
        self.store = store
        self.filter = filter
    }

    // MARK: - Graph access

    private var wallet: TripWalletModel? { store.wallet }
    private var allBookings: [BookingModel] { wallet?.bookings ?? [] }
    /// Bookings already filed onto a day (the `dayGroups` source).
    private var placedBookings: [BookingModel] { allBookings.filter { $0.dayIndex != nil } }
    /// Bookings not yet placed (`dayIndex == nil`) — the orphan source.
    private var orphanBookings: [BookingModel] { allBookings.filter { $0.dayIndex == nil } }

    // MARK: - Top-level state

    /// No bookings at all → the rich empty state (wallet-empty), regardless of filter.
    var isEmpty: Bool { allBookings.isEmpty }

    // MARK: - Hero context (mockup `.wal-sub .ctx`: "Lisbon · 4 days · 8 bookings")

    /// "Lisbon · 4 days · 8 bookings" — the placed-booking count (the orphan is surfaced separately by the
    /// prompt + the Orphans chip, mirroring the mockup's "8 bookings" with one orphan called out above).
    var heroContext: String {
        let city = wallet?.tripCityName ?? ""
        let days = wallet?.dayCount ?? 0
        let count = placedBookings.count
        return "\(city) · \(days) \(days == 1 ? "day" : "days") · "
            + "\(count) \(count == 1 ? "booking" : "bookings")"
    }

    // MARK: - Filter chips (mockup `.wal-sub .chips`)

    /// By day [default] · By type · Orphans (with the unplaced count). The view marks the active chip;
    /// the orphan count drives the chip's badge + dot.
    var filterChips: [WalletFilterChip] {
        let orphanCount = orphanBookings.count
        return [
            WalletFilterChip(filter: .byDay, label: WalletFilter.byDay.label, count: nil),
            WalletFilterChip(filter: .byType, label: WalletFilter.byType.label, count: nil),
            WalletFilterChip(filter: .orphans, label: WalletFilter.orphans.label, count: orphanCount),
        ]
    }

    // MARK: - Orphan prompt (mockup `.orphan`)

    /// The first unplaced booking, as the AI placement prompt's value type — `nil` when nothing is orphaned.
    /// The component renders it; the screen wires Pin → `placeOrphan`, the row → the booking detail.
    var orphan: OrphanPromptModel? {
        guard let booking = orphanBookings.first else { return nil }
        return OrphanPromptModel(
            labelCaps: "\(orphanBookings.count) "
                + (orphanBookings.count == 1 ? "BOOKING NOT YET PLACED" : "BOOKINGS NOT YET PLACED"),
            bookingName: booking.title,
            bookingMeta: orphanMeta(for: booking),
            type: booking.type,
            systemImage: booking.type.systemImage,
            suggestionLine: suggestionLine(for: booking),
            pinTitle: "Pin to Day \(suggestedDay)",
            dismissTitle: "Not now"
        )
    }

    /// The id of the orphan the prompt points at (the screen needs it to fire the write / push the detail).
    var orphanBookingID: BookingModel.ID? { orphanBookings.first?.id }

    /// The day the orphan prompt suggests (mockup: "Pin to Day 2"). Deterministic — the first today/now day,
    /// else the first placed day, else day 1.
    var suggestedDay: Int {
        if let today = placedBookings.first(where: { $0.status == .now || $0.status == .today })?.dayIndex {
            return today
        }
        return placedBookings.compactMap(\.dayIndex).min() ?? 1
    }

    private func orphanMeta(for booking: BookingModel) -> String {
        var parts = booking.subtitleParts.filter { !$0.isEmpty }
        if let confirmation = booking.confirmation {
            parts.append("confirmation \(confirmation)")
        }
        return parts.joined(separator: " · ")
    }

    /// The AI italic suggestion line (mockup `.orphan .line`), with **bold** spans for the key facts.
    private func suggestionLine(for booking: BookingModel) -> String {
        let time = booking.startTime.map { "**\($0) show**" } ?? "an evening show"
        return "This reads like a \(time) — it fits your **Day \(suggestedDay)** evening, after dinner."
    }

    // MARK: - Grouped content (mockup `.daygrp` + `.bk-list`)

    /// The grouped booking rows, re-derived per `filter`:
    /// - `.byDay`   → one group per trip day, ascending, with the date eyebrow + today flag.
    /// - `.byType`  → one group per booking type (no date eyebrow).
    /// - `.orphans` → no day groups (only the orphan prompt shows).
    var dayGroups: [WalletDayGroup] {
        switch filter {
        case .byDay:   return dayGroupsByDay
        case .byType:  return dayGroupsByType
        case .orphans: return []
        }
    }

    /// Group placed bookings by `dayIndex` ascending; past days' rows carry `isPast`.
    private var dayGroupsByDay: [WalletDayGroup] {
        let days = Set(placedBookings.compactMap(\.dayIndex)).sorted()
        return days.map { day in
            let rows = placedBookings
                .filter { $0.dayIndex == day }
                .map { bookingRow(for: $0) }
            let today = isToday(day: day)
            return WalletDayGroup(
                id: "day-\(day)",
                dayLabel: "Day \(day)",
                dateLabel: dateLabel(forDay: day, isToday: today),
                isToday: today,
                rows: rows
            )
        }
    }

    /// Group placed bookings by `BookingType`, in the canonical type order.
    private var dayGroupsByType: [WalletDayGroup] {
        BookingType.allCases.compactMap { type in
            let bookings = placedBookings.filter { $0.type == type }
            guard !bookings.isEmpty else { return nil }
            return WalletDayGroup(
                id: "type-\(type.rawValue)",
                dayLabel: type.displayLabel,
                dateLabel: "",
                isToday: false,
                rows: bookings.map { bookingRow(for: $0) }
            )
        }
    }

    /// A day is "today" when it holds a live (`now`) or `today` booking — deterministic from the seeded
    /// statuses (OD-3: no live clock).
    private func isToday(day: Int) -> Bool {
        placedBookings.contains { $0.dayIndex == day && ($0.status == .now || $0.status == .today) }
    }

    // MARK: - Row mapping (domain → component value type)

    /// Maps a domain `BookingModel` to the `BookingRow` value type: the meta string is `startTime` +
    /// `subtitleParts` joined; the leading `timeEmphasis` slice is the `startTime`; the icon glyph is the
    /// type's SF Symbol (06-screens §3 — the presenter supplies it, the component never invents one).
    private func bookingRow(for booking: BookingModel) -> BookingRowModel {
        BookingRowModel(
            id: booking.id,
            title: booking.title,
            meta: metaLine(for: booking),
            timeEmphasis: booking.startTime,
            type: booking.type,
            systemImage: booking.type.systemImage,
            status: booking.status,
            confirmation: booking.confirmation,
            isPast: booking.status == .past
        )
    }

    /// "10:00 · timed entry · 2 adults" — the `startTime` leads (the emphasized `.time` slice), then the
    /// subtitle parts. When `startTime` is absent the parts stand alone.
    private func metaLine(for booking: BookingModel) -> String {
        var parts: [String] = []
        if let startTime = booking.startTime { parts.append(startTime) }
        parts.append(contentsOf: booking.subtitleParts.filter { !$0.isEmpty })
        return parts.joined(separator: " · ")
    }

    // MARK: - Day date labels (mockup `.daygrp .d`)

    /// "Thu · Aug 27" / "Thu · Aug 27 · today". Derived deterministically from the pinned trip start
    /// (Day 1 = Wed, Aug 26 2025, matching wallet-populated.html), so the labels never read the live clock
    /// (OD-3) and stay snapshot-stable.
    private func dateLabel(forDay day: Int, isToday: Bool) -> String {
        guard let date = Self.calendar.date(byAdding: .day, value: day - 1, to: Self.tripStart) else {
            return "Day \(day)"
        }
        let base = Self.dayDateFormatter.string(from: date)
        return isToday ? "\(base) · today" : base
    }

    /// Trip Day 1 anchor — Wed, Aug 26 2025 (UTC), the mockup's first day.
    private static let tripStart: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 8
        components.day = 26
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }()

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    /// Fixed `en_US_POSIX` + UTC so the "EEE · MMM d" label is identical on every device + in snapshots.
    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "EEE · MMM d"
        return formatter
    }()

    // MARK: - Empty state (mockup wallet-empty `.empty`)

    var emptyTitle: String { "Nothing in your wallet yet" }

    var emptyBody: String {
        "Hand me a confirmation any way you have it — I'll read it and file it under the right day "
            + (wallet?.tripCityName.isEmpty == false ? "in \(wallet!.tripCityName)." : "in your trip.")
    }

    /// The three capture methods (mockup `.ways`) — all uniform `paper-100` rows, no prominent/accent
    /// `.way.primary` on the empty state (the `WalletEmptyGlyph` badge is the screen's one accent).
    var wayToSave: [WayToSaveRowModel] {
        [
            WayToSaveRowModel(
                id: "forward",
                title: "Forward a confirmation",
                subtitle: "Paste text, a link, or an email",
                systemImage: "envelope",
                prominent: false
            ),
            WayToSaveRowModel(
                id: "scan",
                title: "Scan a pass or ticket",
                subtitle: "QR code or barcode",
                systemImage: "qrcode.viewfinder"
            ),
            WayToSaveRowModel(
                id: "photo",
                title: "From a photo",
                subtitle: "Snap or upload a screenshot",
                systemImage: "camera"
            ),
        ]
    }
}
