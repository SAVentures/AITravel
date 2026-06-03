// Tag.swift — the read-only status tag (05-components §5; J-2.4 / J-10.2; 08-slop A-1/C-1).
//
// A small, capsule-shaped, READ-ONLY label for status/category — "Ramen", "Open now",
// "Reserved · 8 PM" (the mockup `.tag`, components.html §05). It is content, not chrome: NEVER glass
// (J-0.1), and it does NOT handle taps — the interactive register is `FilterChip` (C5).
//
// Anatomy ported from the mockup `.tag`:
//   • capsule shape at the `Radius.tag` rung — the smallest content radius (J-10.1/J-10.2).
//   • a short label in the MONO family (`Typography.caption`), uppercased, with caps tracking applied
//     at the call site (the role doesn't bake it in — T-5.2). Mono is reserved here for measurement /
//     short status caps, never sentence text (J-3.5, 08-slop B-10).
//   • a neutral `fillTertiary` ground (the mockup's `--fill-tertiary`); the label ink is the
//     secondary text role (the mockup draws it in the `--ink-600` / textSecondary tone).
//
// §5.1 — a tag carries state via ONE accent mark OR a neutral fill — never a side-border, never a
// gradient fill (J-2.4, 08-slop A-1/A-2/C-1). The optional `state` variant adds a single leading
// `stateNow` dot; the COLOR is always paired with the label text so the status survives
// color-blindness (02-color §6, never color alone). There is no bordered/gradient path to misuse.
//
// @ScaledMetric (T-6.4): the dot is a non-text metric, so it scales with the label via
// `@ScaledMetric(relativeTo:)` rather than a fixed CGFloat (J-0.3). Sizing is content-hugging — no
// fixed frame.
//
// Value-type args only (no AppStore, no domain object — 05 §8); the local `TagModel` fixture below
// drives the previews and the Wave E snapshots.
import SwiftUI

struct Tag: View {

    /// What a tag carries beyond its label: a neutral status (fill only) or a now/live state that adds
    /// the single `stateNow` accent mark. The accent is the budgeted state colour (J-0.4 / J-2.4) — a
    /// tag never invents a fill colour of its own.
    enum Mark {
        /// Neutral — the fill-only capsule (the default; e.g. "Ramen", "Michelin").
        case neutral
        /// A live/now status — one leading `stateNow` dot paired with the label (e.g. "Open now").
        case now
    }

    private let label: String
    private let mark: Mark

    init(_ label: String, mark: Mark = .neutral) {
        self.label = label
        self.mark = mark
    }

    /// The leading dot for the `.now` mark, scaled with the caption text style so it tracks Dynamic Type.
    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = 6

    var body: some View {
        HStack(spacing: Spacing.paired) {
            if mark == .now {
                Circle()
                    .fill(ColorRole.stateNow)
                    .frame(width: dotSize, height: dotSize)
            }
            Text(label.uppercased())
                .font(Typography.caption)
                .tracking(Typography.trackCapsCaption)
                .foregroundStyle(ColorRole.textSecondary)
        }
        // Content-hugging capsule: hairline (4) vertical / paired (8) horizontal inset — the mockup
        // `.tag` `padding: 4px 8px`. No fixed frame (J-0.3); content drives the size.
        .padding(.vertical, Spacing.hairline)
        .padding(.horizontal, Spacing.paired)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.tag))
        // Colour is paired with the label, so the status is announced as text — never colour alone.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

/// A tiny local value-type fixture for `#Preview` + the Wave E snapshot — no `SampleData`/domain model
/// exists in Phase 0 (05 §8, plan Wave C note).
private struct TagFixture: Identifiable {
    let id = UUID()
    let label: String
    let mark: Tag.Mark
}

#Preview("Tag — default + state-mark") {
    let fixtures: [TagFixture] = [
        .init(label: "Ramen", mark: .neutral),
        .init(label: "Michelin", mark: .neutral),
        .init(label: "Open now", mark: .now),
    ]
    HStack(spacing: Spacing.paired) {
        ForEach(fixtures) { fixture in
            Tag(fixture.label, mark: fixture.mark)
        }
    }
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}
