// ContextNote.swift — a screen-agnostic component: the quiet, neutral context note row
// (05-design-system §8; J-11.5 / J-4.2 / J-7.1).
//
// A low-key info row that surfaces a conditional, ambient caveat beside a recommendation — "For your
// dates · Rain 2 of 4 days", "Lots of saves here · Strong first draft". It is *not* a status tag, not an
// action, and DELIBERATELY carries NO alarm color: no `destructive`, no accent, no "!" (J-11.5). A
// considered caveat earns trust by being calm; an alarmist one erodes it. It reads as a leading glyph + a
// mono caps eyebrow + a quiet body line whose key spans are emphasized by WEIGHT, never color (J-2).
//
// PORTS FROM: `mockups/screens/onboarding/screen-04-getting-around.html` `.note`
//   ground    `background: var(--paper-100)`              → `ColorRole.surfacePage`
//   shape     `border-radius: var(--r-row)`               → `Radius.row` (a content well — J-10.1/J-10.2)
//   gap       `gap: 11px` (glyph ↔ text)                  → `Spacing.itemGap` (sibling rung — J-1)
//   glyph     `.note .ic { color: var(--ink-500) }`       → `ColorRole.textTertiary` (recessive, quiet)
//   eyebrow   `.note .b .l` mono caps `var(--ink-500)`    → `Typography.caption` mono caps · `textTertiary`
//   body      `.note .b { color: var(--text-secondary) }` → `Typography.subhead` · `ColorRole.textSecondary`
//   span      `.note .b b { color: var(--ink-900) }`      → bold WEIGHT + `textPrimary` (J-2, never color-only)
//
// Token discipline: SEMANTIC tokens only — zero literals, zero `Primitive.*` (J-0.2). This is CONTENT, so
// it is NEVER glass (J-0.1 / J-8) — glass lives only on floating chrome. The eyebrow caps tracking is
// applied at the call site from the named token (`trackEyebrowCaption`, T-5.2). Bold emphasis spans are
// pulled into an `AttributedString` (weight, not color) so the line stays binary-ink quiet (J-2.2).
//
// Value-type args only; no `AppStore`, no domain model (05 §8). A tiny local fixture drives `#Preview`.
import SwiftUI

/// A quiet, neutral context-note row: a recessive glyph + a mono caps eyebrow over a body line whose key
/// spans are emphasized by weight (never an alarm color — J-11.5). Screen-agnostic — takes a value-type
/// fixture, no `AppStore`, no domain object (05-design-system.md §8). Content, never chrome (J-0.1).
struct ContextNote: View {

    /// The short mono-caps label (e.g. "For your dates"). Kept brief — caps tracking is for short eyebrows.
    let eyebrow: String
    /// The body line, e.g. "Rain 2 of 4 days". Quiet secondary ink (J-2.2).
    let text: String
    /// Substrings of `text` to emphasize by WEIGHT (e.g. "Rain 2 of 4 days"). Bolded + lifted to primary
    /// ink — never an accent or alarm color (J-2 / J-11.5). Empty = a flat quiet line.
    let emphasis: [String]
    /// An optional SF Symbol for the leading glyph, e.g. "cloud.rain". `nil` renders text-only.
    let systemImage: String?

    init(eyebrow: String, text: String, emphasis: [String] = [], systemImage: String? = nil) {
        self.eyebrow = eyebrow
        self.text = text
        self.emphasis = emphasis
        self.systemImage = systemImage
    }

    var body: some View {
        // Glyph ↔ text at the sibling rung; the glyph aligns to the top of the (possibly multi-line) text.
        HStack(alignment: .top, spacing: Spacing.itemGap) {
            if let systemImage {
                // Recessive leading glyph — quiet tertiary ink, paired with the body so meaning never
                // rides on color alone (02-color §6). Scales with Dynamic Type for free (no fixed size).
                Image(systemName: systemImage)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                // Mono caps eyebrow — recessive, the loosest caps tracking applied from the named token
                // (T-5.2). Tertiary ink so the body line below carries the read.
                Text(eyebrow)
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)

                // The quiet body line — secondary ink, UI face; key spans lifted by WEIGHT to primary ink
                // (never an alarm color — J-11.5 / J-2). Left-aligned, comfortable multi-line (J-7.1).
                Text(emphasizedText)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Content-well padding from the named ladder (J-1) — the row rung's inset.
        .padding(Spacing.cardInset)
        // The quiet page ground + the row shape (a content well, NOT glass — J-0.1 / J-8). No alarm fill.
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        .accessibilityIdentifier("contextnote")
        // One VoiceOver stop reading the eyebrow + body, not fragments (05-components §4.2).
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow): \(text)")
    }

    /// Build the body as an `AttributedString`, bolding each emphasized span and lifting it to primary ink —
    /// emphasis by WEIGHT (+ one ink step), never an accent or alarm color (J-2 / J-11.5). Whole-substring
    /// matching keeps the API value-type and Equatable-friendly (no fragile string indices at the call site).
    private var emphasizedText: AttributedString {
        var attributed = AttributedString(text)
        for span in emphasis where !span.isEmpty {
            var search = attributed.startIndex
            while let range = attributed[search...].range(of: span) {
                attributed[range].font = Typography.subhead.weight(.semibold)
                attributed[range].foregroundColor = ColorRole.textPrimary
                search = range.upperBound
            }
        }
        return attributed
    }
}

#Preview("With emphasis") {
    // Local value-type fixture — no SampleData / domain model exists in Phase 0.
    ContextNote(
        eyebrow: "For your dates",
        text: "Rain 2 of 4 days — transit keeps the plan dry without changing the shape.",
        emphasis: ["Rain 2 of 4 days"],
        systemImage: "cloud.rain"
    )
    .padding(Spacing.screenInset)
}

#Preview("Text only") {
    ContextNote(
        eyebrow: "Lots of saves here",
        text: "We can lean on the 23 places you've already saved."
    )
    .padding(Spacing.screenInset)
}
