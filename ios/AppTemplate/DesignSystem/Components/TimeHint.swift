// TimeHint.swift — a screen-agnostic component: the time-conditional hint chip (05-components §5 "hint";
// J-2 / J-3.4 / J-10.2).
//
// A small, quiet capsule that surfaces a *time-conditional* cue beside a place or moment — "Best light
// 7:30–8:30", "Closes 21:00". It is read-only ambient guidance, not an action and not a status tag: it sits
// on a recessive `fillQuaternary` ground, carries a short UI label and a small leading glyph, and lets a
// MONO numeral range carry the measurement (the time) so the digits align and read as a fact (T-1.2).
//
// PORTS FROM: `mockups/components/Components.html` §05 `.hint`
//   ground   `background: var(--fill-quaternary)`   → `ColorRole.fillQuaternary`
//   shape    `border-radius: var(--r-pill)`         → `Radius.pill` (a chip is chrome-shaped — J-10.2)
//   gap      `gap: 8px` (glyph ↔ label)             → `Spacing.paired`
//   label    UI text, recessive                     → `Typography.subhead` · `ColorRole.textSecondary`
//   glyph    `.hint svg { color: var(--ink-500) }`  → `ColorRole.textSecondary` (recessive, like the label)
//   mono     `.hint .mono { color: var(--ink-700) }`→ `Typography.caption` (system mono) · `textPrimary`
//
// Token discipline: SEMANTIC tokens only — zero literals, zero `Primitive.*` (J-0.2). This is CONTENT, so
// it is NEVER glass (J-0.1 / J-8) — glass lives only on floating chrome. The measurement is `.monospacedDigit()`
// so the numerals tabular-align even though the mono role is already monospaced (belt-and-braces per the
// plan's inline-numeral note). Color-coded meaning is never carried by color alone — the glyph + label pair
// it (02-color §6).
import SwiftUI

/// A read-only, time-conditional hint chip: a small glyph + a short UI label + an optional mono time range,
/// on a recessive `fillQuaternary` capsule. Screen-agnostic — takes a value-type fixture, no `AppStore`,
/// no domain object (05-design-system.md §8).
struct TimeHint: View {

    /// The local value-type fixture this component renders from (no `SampleData` / domain model exists in
    /// the foundation phase). `measurement` is the optional mono time range the numerals carry.
    struct Model {
        /// The short UI label, e.g. "Best light", "Closes". Leads, recessive.
        var text: String
        /// An SF Symbol name for the small leading glyph, e.g. "clock".
        var systemImage: String
        /// The optional time/measurement range rendered in the mono role, e.g. "7:30–8:30". `nil` for a
        /// label-only hint.
        var measurement: String?

        init(text: String, systemImage: String, measurement: String? = nil) {
            self.text = text
            self.systemImage = systemImage
            self.measurement = measurement
        }
    }

    private let model: Model

    init(_ model: Model) {
        self.model = model
    }

    var body: some View {
        HStack(spacing: Spacing.paired) {
            // The small leading glyph — recessive, paired with the label so meaning never rides on color
            // alone (02-color §6). An SF Symbol scales with Dynamic Type for free (no fixed point size).
            Image(systemName: model.systemImage)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .accessibilityHidden(true)

            // The short UI label — recessive secondary ink, the UI face.
            Text(model.text)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)

            // The mono measurement — the time range carries the load as a FACT: system mono role, primary
            // ink, tabular digits so the numerals align (T-1.2). Omitted when the hint is label-only.
            if let measurement = model.measurement {
                Text(measurement)
                    .font(Typography.caption)
                    .monospacedDigit()
                    .foregroundStyle(ColorRole.textPrimary)
            }
        }
        // Chrome-thin chip padding from the named ladder (J-1) — vertical `paired`, horizontal `cardInset`.
        .padding(.vertical, Spacing.paired)
        .padding(.horizontal, Spacing.cardInset)
        // The recessive ground + the pill shape (a chip is chrome-shaped — J-10.2). Solid fill, NOT glass:
        // this is content, and glass is reserved for floating chrome (J-0.1 / J-8).
        .background(ColorRole.fillQuaternary, in: .capsule)
        // One VoiceOver stop that reads the label + the time, not three fragments (05-components §4.2).
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Combine the label + measurement into a single spoken phrase for VoiceOver.
    private var accessibilityLabel: String {
        if let measurement = model.measurement {
            "\(model.text), \(measurement)"
        } else {
            model.text
        }
    }
}

#Preview("Default") {
    TimeHint(
        TimeHint.Model(text: "Best light", systemImage: "clock", measurement: "7:30–8:30")
    )
    .padding(Spacing.screenInset)
}
