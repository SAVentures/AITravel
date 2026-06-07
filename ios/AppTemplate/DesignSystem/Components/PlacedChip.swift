// PlacedChip.swift — a screen-agnostic component: the read-only "placed on the itinerary" status chip
// (wallet slice). A small, quiet capsule that confirms a booking has been placed onto a day — e.g.
// "Placed on Day 2 · Thu Aug 27". It is read-only confirmation, not an action and not a tap target.
//
// PORTS FROM: `mockups/screens/wallet/wallet-shell.css` `.placed`
//   ground   `background: var(--fill-tertiary)`     → `ColorRole.fillTertiary`
//   shape    `border-radius: var(--r-pill)`         → `Radius.pill` (a chip is chrome-shaped — J-10.2)
//   gap      `gap: 7px` (glyph ↔ label)             → `Spacing.sm`
//   label    `font-size: 12.5px; weight 600;`
//            `color: var(--ink-700)`                → `Typography.subhead` · `ColorRole.textPrimary`
//   glyph    `.placed svg { color: var(--ink-500) }`→ `ColorRole.textSecondary` (recessive, paired w/ text)
//
// Token discipline: SEMANTIC tokens only — zero literals, zero `Primitive.*` (J-0.2). This is CONTENT, so
// it is NEVER glass (J-0.1 / J-8) — glass lives only on floating chrome. A read-only display chip: no
// `Button`, no tap (distinct from `FilterChip`/`PillButton`). The check glyph is paired with the text so
// meaning never rides on color or icon alone (02-color §6). Dynamic Type: the SF Symbol + text style scale
// for free — no fixed point size, no fixed frame (J-0.3). Mirrors `TimeHint`.
import SwiftUI

/// A read-only status chip confirming a booking is placed on a day — a small leading check glyph + a short
/// confirmation label on a recessive `fillTertiary` capsule. Screen-agnostic: takes its display string as a
/// value-type arg, no `AppStore`, no domain object (05-design-system.md §8).
struct PlacedChip: View {

    /// The full confirmation line, e.g. "Placed on Day 2 · Thu Aug 27". The caller composes the day/date —
    /// the chip is a dumb display surface.
    private let text: String

    /// The SF Symbol for the small leading glyph. Defaults to a check, matching the mockup's placed mark.
    private let systemImage: String

    init(_ text: String, systemImage: String = "checkmark") {
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // The small leading check — recessive glyph, paired with the label so the "placed" meaning
            // never rides on the icon alone (02-color §6). An SF Symbol scales with Dynamic Type for free.
            Image(systemName: systemImage)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .accessibilityHidden(true)

            // The confirmation label — the UI face, primary ink (the mockup's `--ink-700`).
            Text(text)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textPrimary)
        }
        // Chrome-thin chip padding from the named ladder (J-1) — vertical `paired`, horizontal `cardInset`,
        // mirroring `TimeHint` (mockup `padding: 9px 14px`).
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.lg)
        // The recessive ground + the pill shape (a chip is chrome-shaped — J-10.2). Solid fill, NOT glass:
        // this is content, and glass is reserved for floating chrome (J-0.1 / J-8).
        .background(ColorRole.fillTertiary, in: .capsule)
        // One VoiceOver stop reading the confirmation text — the glyph is decorative (hidden above).
        .accessibilityElement(children: .combine)
    }
}

#Preview("Default") {
    PlacedChip("Placed on Day 2 · Thu Aug 27")
        .padding(Spacing.screenInset)
}
