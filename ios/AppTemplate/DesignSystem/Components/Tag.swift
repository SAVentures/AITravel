// Tag.swift — the read-only status tag: a small capsule label for status/category (05-components §5).
// Ports the mockup `.tag` (components.html §05): a `Radius.tag` capsule, a short MONO caps label
// (`Typography.caption`, caps tracking at the call site — T-5.2), on a neutral `fillTertiary` ground.
// State is carried by ONE accent mark OR a neutral fill — never a side-border or gradient (§5.1, J-2.4,
// 08-slop A-1/C-1); the `.now` dot is always paired with the label (never color alone — 02-color §6).
// Content, never glass (J-0.1); content-hugging (J-0.3). Value-type args only (05 §8).
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
    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = Sizing.dot

    var body: some View {
        HStack(spacing: Spacing.sm) {
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
        // Content-hugging capsule — the mockup `.tag` `padding: 4px 8px` (J-0.3; content drives size).
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
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
    HStack(spacing: Spacing.sm) {
        ForEach(fixtures) { fixture in
            Tag(fixture.label, mark: fixture.mark)
        }
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
