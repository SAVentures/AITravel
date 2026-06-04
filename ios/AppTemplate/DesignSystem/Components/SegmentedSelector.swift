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
    /// When `true`, segments size to their content and the track scrolls horizontally — for option sets
    /// that won't fit the width without wrapping the labels (the transport `.mostly` row).
    var scrollable: Bool = false
    let onSelect: (Option) -> Void

    var body: some View {
        if scrollable {
            ScrollView(.horizontal, showsIndicators: false) { track }
        } else {
            track
        }
    }

    // The quiet pill track: a hairline inset keeps the selected pill off the track edge.
    private var track: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    SegmentLabel(
                        title: label(option),
                        systemImage: systemImage(option)
                    )
                }
                .buttonStyle(SegmentButtonStyle(isSelected: option == selection, equalWidth: !scrollable))
                .accessibilityIdentifier("\(accessibilityIDPrefix).\(option.id)")
                .accessibilityAddTraits(option == selection ? [.isSelected] : [])
            }
        }
        .padding(Spacing.xs)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.pill))
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
            .background(fill, in: .rect(cornerRadius: Radius.pill))
            .contentShape(.rect(cornerRadius: Radius.pill))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
            // Cross-fade (NOT a slide): the ink fill + label color fade out of the old segment and into
            // the new one on selection change. Per-segment color change → opacity cross-fade, no shared
            // geometry. Standard ease-out at the base rung — a discrete state change, not continuous (§2/§3).
            .animation(Motion.standard(Motion.standard), value: isSelected)
    }

    private var labelColor: Color {
        if !isEnabled { return ColorRole.textTertiary }
        return isSelected ? ColorRole.textOnAccent : ColorRole.textSecondary
    }

    // Selected = solid ink (`textPrimary`), never the accent. Unselected is clear so the track shows through.
    private var fill: Color {
        isSelected ? ColorRole.textPrimary : .clear
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
