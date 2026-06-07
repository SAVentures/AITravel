// DayGroupHeader.swift — the wallet day-group header: a day number + date + a filling hairline rule.
// Ports the mockup `.daygrp` (mockups/screens/wallet/wallet-shell.css): a display `.n` ("Day 2") + a
// mono-caps `.d` ("Thu · Aug 27 · today") + a `.rule` hairline (`flex: 1`) that fills the remaining
// width. Grouping by space + ONE rule, not a box (J-4) — same idiom as the Saved `categoryHeader`, which
// is a dot + label + count + filling rule; here the dot/count become a date eyebrow, the rule still
// fills. Content, never glass (J-0.1). Semantic tokens only (J-0.2); Dynamic Type throughout (J-0.3).
//
// A11y: the whole header is ONE combined element ("Day 2, Thursday August 27, today") — the caller
// passes the spoken date; the rule is decorative and hidden.
import SwiftUI

struct DayGroupHeader: View {

    /// The day number label — e.g. "Day 2" (`.daygrp .n`, display).
    private let dayLabel: String
    /// The date eyebrow — e.g. "Thu · Aug 27" or "Thu · Aug 27 · today" (`.daygrp .d`, mono caps). The
    /// caller composes the human string (incl. the "today" suffix); the component renders it caps.
    private let dateLabel: String
    /// Whether this group is the trip's current day. The "today" emphasis lives in the caller-composed
    /// `dateLabel`; this flag stays in the type for the a11y label and future per-day affordances.
    private let isToday: Bool

    init(dayLabel: String, dateLabel: String, isToday: Bool) {
        self.dayLabel = dayLabel
        self.dateLabel = dateLabel
        self.isToday = isToday
    }

    var body: some View {
        // `.firstTextBaseline` aligns the display number with the mono eyebrow on their shared baseline
        // (mockup `align-items: baseline`), exactly as the Saved `categoryHeader` aligns its label + count.
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(dayLabel)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize()                          // mockup `.n` never wraps (`white-space: nowrap`)

            Text(dateLabel.uppercased())
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textTertiary)
                .fixedSize()                          // mockup `.d` never wraps (`white-space: nowrap`)

            // The `.rule` — a 1pt hairline that fills the remaining width (`flex: 1`). Vertically centered
            // in the baseline-aligned row (mockup `align-self: center`). Decorative → hidden from a11y.
            Rectangle()
                .fill(ColorRole.separator)
                .frame(height: Stroke.separator)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // One combined element: "Day 2, Thursday August 27, today". The caller-composed `dateLabel` is the
        // spoken date; VoiceOver reads the number then the date (not the abbreviated/caps display string).
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("DayGroupHeader — today / not-today") {
    VStack(alignment: .leading, spacing: Spacing.xl) {
        DayGroupHeader(dayLabel: "Day 2", dateLabel: "Thu · Aug 27 · today", isToday: true)
        DayGroupHeader(dayLabel: "Day 3", dateLabel: "Fri · Aug 28", isToday: false)
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
