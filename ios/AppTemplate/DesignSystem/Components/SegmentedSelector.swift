/*
 A single-select segmented control on a quiet pill track. Ports the onboarding `.seg`/`.pace`/`.mostly`
 controls (2/3/4-way): an ink pill on the selected segment over a `fillTertiary` track.
 Load-bearing call (mirrors FilterChip): the selected segment is a SOLID INK pill, NOT the accent (J-0.4 /
 J-2.4) — conveyed by fill + the `.isSelected` trait, never color alone, so it survives grayscale.
*/
import SwiftUI

/// A single-select segmented control, generic over an `Identifiable & Hashable` option. Single-selection
/// lives in the caller's model; `onSelect` hands back the tapped option and the caller re-passes `selection`.
struct SegmentedSelector<Option: Identifiable & Hashable>: View {
    let options: [Option]
    let selection: Option
    let label: (Option) -> String
    /// `nil` renders a text-only segment (the `.pace` register).
    let systemImage: (Option) -> String?
    /// Each segment becomes `\(accessibilityIDPrefix).\(option.id)`.
    let accessibilityIDPrefix: String
    /// The caller-supplied GROUP label (e.g. "Date precision"). Owns the *value* of the a11y group;
    /// the component owns the *mechanism* (it exposes the group element + reads `label(selection)` as
    /// its value). Empty (the default) attaches no label modifier — never an empty-string foot-gun —
    /// so the snapshot/preview fixtures that don't supply one stay byte-identical. Real callers pass a
    /// non-empty label (Task 2.4: "Date precision" / "Base location mode" / "Primary transport").
    var accessibilityLabel: String = ""
    /// When `true`, segments size to their content and the track scrolls horizontally — for option sets
    /// that won't fit the width without wrapping the labels (the transport `.mostly` row).
    var scrollable: Bool = false
    let onSelect: (Option) -> Void

    /// Shared-geometry namespace for the single ink "moving-train" pill (see `pill(for:)`).
    @Namespace private var selectionPill

    var body: some View {
        // ONE consistent a11y structure: the group element (`children: .contain`) + value/label live on
        // the `track` for BOTH paths (see `track`). `.contain` is what makes the track a real, addressable
        // group element while keeping each segment Button an independent, resolvable child — that covering
        // container is what satisfies the `.elementDetection` audit (no "potentially inaccessible text"
        // left uncontained on GettingAround). Moving the container off the track to the ScrollView left
        // rendered text uncontained and reintroduced that failure, so the container stays on the track.
        if scrollable {
            // The track sets `.fixedSize(horizontal: true)` (see `track`), so even with `.contain` it keeps
            // its intrinsic content width instead of shrinking to the viewport — "Cycle" renders full and
            // the ScrollView scrolls (no D-7 truncation). The ScrollView only provides the clipping
            // viewport; it carries no a11y group of its own (that's on the track).
            ScrollView(.horizontal, showsIndicators: false) { track }
        } else {
            // Fixed-width path: segments are `maxWidth: .infinity` at the track's own width, so `.contain`
            // imposes no width the track didn't already have. No `.fixedSize` needed.
            track
        }
    }

    // The quiet pill track: a hairline inset keeps the selected pill off the track edge.
    private var track: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    onSelect(option)
                } label: {
                    SegmentLabel(
                        title: label(option),
                        systemImage: systemImage(option)
                    )
                }
                .buttonStyle(SegmentButtonStyle(isSelected: isSelected, equalWidth: !scrollable))
                // The selection pill is a SINGLE shared element: only the selected segment hosts it,
                // tagged with the namespace, so on a selection change SwiftUI interpolates its frame
                // from the old segment to the new one — the ink pill SLIDES ("moving train"), it does
                // not fade in place. Unselected segments host no pill (the `fillTertiary` track shows
                // through). Backgrounding here (not in the ButtonStyle) is required: a ButtonStyle can't
                // see the namespace.
                .background(pill(for: isSelected))
                .accessibilityIdentifier("\(accessibilityIDPrefix).\(option.id)")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(Spacing.xs)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.pill))
        // Slide the matched-geometry pill on selection change. House curve = critically-damped ease-out
        // (no overshoot — a timing curve can't bounce, satisfying E-1 / §1). Automatic/time-based move
        // → the curve, not a spring (§3). Only the indicator's matched frame animates; no layout prop
        // (§8 / E-2). The tap-commit press scale stays in the ButtonStyle at the `tap` rung.
        .animation(Motion.standard(Motion.standard), value: selection)
        // SCROLLABLE only: pin the track to its intrinsic content width BEFORE the group container applies.
        // `.contain` (below) otherwise proposes the ScrollView's viewport width to the track, shrinking it
        // and truncating the trailing segment ("Cycle" → "Cyc…", slop D-7). `.fixedSize(horizontal: true)`
        // makes the track hug its content — identical intrinsic-width layout to a plain HStack, so the
        // committed scrollable snapshot stays byte-identical — and the ScrollView scrolls the overflow.
        // The fixed path needs none of this: its segments are `maxWidth: .infinity` at the track's own
        // width, so `.contain` adds no constraint the track didn't already have.
        .modifier(ScrollableTrackWidth(active: scrollable))
        // ONE consistent a11y structure for BOTH paths: promote the track to the addressable group element
        // carrying the selection value/label. `children: .contain` is the covering container the
        // `.elementDetection` audit requires (rendered segment text is never left uncontained) while
        // keeping each segment Button an independent, resolvable child (per-segment ids still resolve).
        .accessibilityGroup(value: label(selection), label: accessibilityLabel)
    }

    /// The single ink pill, rendered only on the selected segment and tagged with the shared namespace
    /// so it travels between segments. Resting appearance is unchanged: solid `textPrimary` ink (never
    /// the accent — J-0.4 / J-2.4), `Radius.pill`.
    @ViewBuilder
    private func pill(for isSelected: Bool) -> some View {
        if isSelected {
            ColorRole.textPrimary
                .clipShape(.rect(cornerRadius: Radius.pill))
                .matchedGeometryEffect(id: "selectionPill", in: selectionPill)
        }
    }
}

// MARK: - A11y group

private extension View {
    /// Promotes the track to a single addressable group element carrying `value`, with `label` applied
    /// only when non-empty. Applied on the `track` for BOTH paths (the scrollable path first pins the
    /// track's width with `ScrollableTrackWidth` so `.contain` can't shrink it — see `track`).
    /// `children: .contain` makes the track a real element (the covering container the `.elementDetection`
    /// audit needs) WHILE leaving the segment Buttons inside it independent, individually-resolvable,
    /// hittable children — so the per-segment ids keep resolving (`app.buttons["when.precision.exactDates"]`
    /// etc.) and VoiceOver announces e.g. "Date precision, Exact dates". `.ignore`/`.combine` would
    /// collapse the segments and HIDE those ids — never use them here. The conditional label (vs
    /// `.accessibilityLabel(Text(""))`) avoids stamping a real-but-blank label on the snapshot/preview
    /// fixtures that pass no label — the empty-id foot-gun.
    @ViewBuilder
    func accessibilityGroup(value: String, label: String) -> some View {
        if label.isEmpty {
            self
                .accessibilityElement(children: .contain)
                .accessibilityValue(value)
        } else {
            self
                .accessibilityElement(children: .contain)
                .accessibilityValue(value)
                .accessibilityLabel(label)
        }
    }
}

// MARK: - Scrollable track width

/// Pins the track to its intrinsic content width on the scrollable path only, so the a11y group
/// container (`children: .contain`) can't shrink it to the ScrollView viewport and truncate the trailing
/// segment (slop D-7). `vertical: false` leaves height free to scale with Dynamic Type (J-0.3). When
/// inactive (the fixed-width path) it is a no-op, leaving that path's layout untouched.
private struct ScrollableTrackWidth: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.fixedSize(horizontal: true, vertical: false)
        } else {
            content
        }
    }
}

// MARK: - Segment label

private struct SegmentLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(Typography.footnote)
                    .accessibilityHidden(true)
            }
            Text(title)
        }
    }
}

// MARK: - Segment style

private struct SegmentButtonStyle: ButtonStyle {
    let isSelected: Bool
    /// Equal-width fills the track (fixed segmented control); content-width lets a scrollable row hug labels.
    var equalWidth: Bool = true
    @Environment(\.isEnabled) private var isEnabled

    // @ScaledMetric so the tap floor holds at large text — a bare literal would not (J-0.3).
    @ScaledMetric(relativeTo: .subheadline) private var minTapTarget: CGFloat = Sizing.minTapTarget

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.subhead)
            .lineLimit(equalWidth ? nil : 1) // scrollable segments stay one line (they scroll, not wrap)
            .foregroundStyle(labelColor)
            .frame(maxWidth: equalWidth ? .infinity : nil)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: minTapTarget)
            .contentShape(.rect(cornerRadius: Radius.pill))
            // Tap feedback only: commit the press scale at the `tap` rung (≤100ms, §6). The SELECTION
            // pill is NOT drawn here — it's a single matched-geometry element in the parent that slides
            // (a ButtonStyle can't see the namespace). Label color flips with the selection in the
            // parent's slide animation.
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }

    private var labelColor: Color {
        if !isEnabled { return ColorRole.textTertiary }
        return isSelected ? ColorRole.textOnAccent : ColorRole.textSecondary
    }
}

// MARK: - Previews

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
    .padding(Spacing.lg)
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
    .padding(Spacing.lg)
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
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
