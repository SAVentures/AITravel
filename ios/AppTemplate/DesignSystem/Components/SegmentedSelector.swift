// SegmentedSelector.swift — a single-select segmented control on a quiet pill track (05-components §5).
// Ports the onboarding `.seg` (2-way base-mode), `.pace` (3-way pace), and `.mostly` (4-way getting-around)
// controls — all three share ONE pattern: an ink-pill on the selected segment over a `fill-tertiary` track.
//
// THE LOAD-BEARING DECISION (mirrors `FilterChip`, Components.html §05 caption): the selected segment is a
// **solid ink pill, NOT the accent**. Mockups render `background: var(--ink-900); color: var(--paper-0)` on
// `.on` — choosing among one's own options is *navigation through a control*, not a now-state, so it must
// not claim the accent (J-0.4 / J-2.4). The accent (blue `actionPrimary` / `stateNow`) stays reserved for
// the CTA and the one AI/now mark on each onboarding screen. Selected fill = `ColorRole.textPrimary` (ink),
// label = `ColorRole.textOnAccent` (the light label legible on ink) — matching `--ink-900` / `--paper-0`.
//
// Selection is conveyed by **fill + weight, never color alone** (02-color §6): the selected segment gains the
// ink pill AND `.accessibilityAddTraits(.isSelected)`, so the state survives grayscale / color-blindness and
// is announced to assistive tech. One selected segment per group is the model's invariant — `selection`
// names it; this view renders the state it is handed.
//
// Tokens only (J-0.2): semantic `ColorRole` / `Typography` / `Spacing` / `Radius` / `Motion` — zero literals,
// zero `Primitive.*`. The track and each segment use `Radius.pill` (chrome shape; J-10.2). NEVER glass — a
// segmented control is content the user taps, not floating chrome (J-0.1; only the bar/floor layer is glass).
// 44pt tap dimension per segment via `@ScaledMetric` (J-0.3 — a bare `44` would not scale at large text).
import SwiftUI

/// A single-select segmented control, generic over an `Identifiable & Hashable` option.
///
/// Renders the 2-/3-/4-way onboarding selectors from one component: pass `options` and the current
/// `selection`; `label` / `systemImage` map each option to its caps-free UI label and optional leading SF
/// Symbol (return `nil` for text-only segments, as in `.pace`). `onSelect` hands the tapped option back to
/// the caller, which flips its own selection model (single-selection lives in the model, not here).
///
/// Value-type args only — no `AppStore`, no domain object (05-design-system §8). The caller supplies an
/// `accessibilityIDPrefix` namespace so each segment gets a stable `\(prefix).\(optionID)` identifier
/// (`basemode.smart`, `pace.balanced`, `transport.mostly.transit`).
struct SegmentedSelector<Option: Identifiable & Hashable>: View {
    /// The segments, left to right.
    let options: [Option]
    /// The currently selected option — drives the ink pill + the `.isSelected` trait.
    let selection: Option
    /// Each option's short UI label (a noun, never caps body — J-3.5).
    let label: (Option) -> String
    /// Each option's optional leading SF Symbol; `nil` renders a text-only segment (the `.pace` register).
    let systemImage: (Option) -> String?
    /// The a11y-id namespace; each segment becomes `\(accessibilityIDPrefix).\(option.id)`.
    let accessibilityIDPrefix: String
    /// Selection callback — the caller updates its own model and re-passes `selection`.
    let onSelect: (Option) -> Void

    var body: some View {
        // The quiet pill TRACK: a `fillTertiary` well that holds the segments (mockup `.seg`/`.pace`/`.mostly`
        // `background: var(--fill-tertiary)`). Inner padding insets the segments so the selected pill never
        // touches the track edge — `Spacing.hairline` matches the mockup's 2–3px track padding.
        HStack(spacing: Spacing.hairline) {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    SegmentLabel(
                        title: label(option),
                        systemImage: systemImage(option)
                    )
                }
                .buttonStyle(SegmentButtonStyle(isSelected: option == selection))
                .accessibilityIdentifier("\(accessibilityIDPrefix).\(option.id)")
                .accessibilityAddTraits(option == selection ? [.isSelected] : [])
            }
        }
        .padding(Spacing.hairline)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.pill))
    }
}

// MARK: - Segment label (optional leading glyph ↔ label)

/// Lays an optional leading SF Symbol at `Spacing.paired` (the icon↔label rung, J-1) before the label. The
/// glyph uses the mono `footnote` role so it scales with Dynamic Type (no fixed pt; J-0.3). Text-only
/// segments simply omit the icon — the layout hugs the label (the `.pace` register).
private struct SegmentLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.paired) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(Typography.footnote)
                    .accessibilityHidden(true)
            }
            Text(title)
        }
    }
}

// MARK: - Segment style (fill · shape · press · 44pt target)

/// A single segment's pill treatment, driven by `configuration.isPressed` so the press commits in ≤100ms
/// before the release animation (J-9.1). Selected → a solid ink pill (`textPrimary`) + light label
/// (`textOnAccent`); unselected → transparent over the track with a quiet `textSecondary` label (mockup
/// `.on` vs the resting `--ink-600` segment). Reads `.isEnabled` from the environment for the disabled
/// register; never a hand-dimmed color (05-components intro). All values are semantic tokens.
private struct SegmentButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// The HIG minimum tap target — a floor; content + Dynamic Type still grow the segment. `@ScaledMetric`
    /// scales it with the label so it holds at large text (J-0.3); a bare `44` literal would not.
    @ScaledMetric(relativeTo: .subheadline) private var minTapTarget: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.subhead) // UI family, content density — not chrome-thin (J-5)
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity) // equal-width segments — the 2/3/4-up grid (mockup `1fr` columns)
            .padding(.vertical, Spacing.paired)
            .padding(.horizontal, Spacing.itemGap)
            .frame(minHeight: minTapTarget)
            .background(fill, in: .rect(cornerRadius: Radius.pill)) // pill segment (J-10.2)
            .contentShape(.rect(cornerRadius: Radius.pill))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }

    /// Selected → the light label on the ink pill (`textOnAccent`). Disabled → the muted past/placeholder
    /// ink. Unselected → the quiet `textSecondary` resting label (mockup `--ink-600`).
    private var labelColor: Color {
        if !isEnabled { return ColorRole.textTertiary }
        return isSelected ? ColorRole.textOnAccent : ColorRole.textSecondary
    }

    /// Selected is a SOLID INK pill (`textPrimary`), never the accent (the load-bearing call, mirrors
    /// `FilterChip`). Unselected segments are transparent so the `fillTertiary` track shows through.
    private var fill: Color {
        isSelected ? ColorRole.textPrimary : .clear
    }
}

// MARK: - Previews — one per width register (05-design-system §8; snapshot matrix in Wave 1)

/// A tiny value-type fixture — no domain object, no `AppStore` (05-design-system §8). Each preview group is a
/// local selection model the `#Preview` renders against.
private struct SegmentOption: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String?
}

#Preview("SegmentedSelector — 2-way (base mode)") {
    let options = [
        SegmentOption(id: "smart", title: "Smart from saved", systemImage: nil),
        SegmentOption(id: "manual", title: "Pick manually", systemImage: nil),
    ]
    return SegmentedSelector(
        options: options,
        selection: options[0],
        label: \.title,
        systemImage: \.systemImage,
        accessibilityIDPrefix: "basemode",
        onSelect: { _ in }
    )
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}

#Preview("SegmentedSelector — 3-way (pace, text-only)") {
    let options = [
        SegmentOption(id: "easy", title: "Easy", systemImage: nil),
        SegmentOption(id: "balanced", title: "Balanced", systemImage: nil),
        SegmentOption(id: "packed", title: "Packed", systemImage: nil),
    ]
    return SegmentedSelector(
        options: options,
        selection: options[1],
        label: \.title,
        systemImage: \.systemImage,
        accessibilityIDPrefix: "pace",
        onSelect: { _ in }
    )
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}

#Preview("SegmentedSelector — 4-way with icons (transport)") {
    let options = [
        SegmentOption(id: "walk", title: "Walk", systemImage: "figure.walk"),
        SegmentOption(id: "transit", title: "Transit", systemImage: "tram.fill"),
        SegmentOption(id: "drive", title: "Drive", systemImage: "car.fill"),
        SegmentOption(id: "cycle", title: "Cycle", systemImage: "bicycle"),
    ]
    return SegmentedSelector(
        options: options,
        selection: options[1],
        label: \.title,
        systemImage: \.systemImage,
        accessibilityIDPrefix: "transport.mostly",
        onSelect: { _ in }
    )
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}
