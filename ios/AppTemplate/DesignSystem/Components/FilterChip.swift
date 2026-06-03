// FilterChip.swift — the interactive, selectable filter chip (05-components §5; ports `.chip` / `.chip.sel`
// from mockups/components/Components.html §05).
//
// A capsule the user taps to toggle a filter. Two registers — read-only *tags* (the `Tag` component) and
// these interactive *filter chips* — share the capsule shape but NOT the selected treatment.
//
// THE LOAD-BEARING DECISION (Components.html §05 caption): a selected filter is a **solid ink pill, NOT the
// accent**. The blue (`actionPrimary` / `stateNow`) stays reserved for the action and the now-state — a
// selected chip is *navigation through one's own filters*, not a now-state, so it must not claim the accent
// (J-0.4 / J-2.4). The ink fill is `ColorRole.textPrimary` with a legible `textOnAccent`-style label,
// mirroring the mockup's `--ink-900` ground / `--paper-0` label.
//
// Color is NEVER the only signal: selection pairs the color change WITH a leading check glyph so it survives
// grayscale / color-blindness (02-color §6; "color-coded status is always paired with the label" — §05 cap).
//
// One selected chip per group is the CALLER's responsibility (J-6.3 — "one selected marker per group"):
// this view renders the state it is handed; the screen owning the group enforces single-selection in its
// model and passes `isSelected` accordingly.
//
// Tokens only (J-0.2): semantic `ColorRole` / `Typography` / `Spacing` / `Radius` / `Motion` — zero literals,
// zero `Primitive.*`. Capsule via `Radius.pill` (chrome shape; J-10.2). NEVER glass — a chip is content the
// user taps, not floating chrome (J-0.1; only the bar/ActionBar layer is glass). 44pt tap target via padding.
import SwiftUI

/// A tiny value-type fixture for previews and the Wave E snapshot — no domain object, no `AppStore`
/// (05-design-system §8). A screen passes its own label + selection + action; this is only the local model
/// the `#Preview` renders against.
struct FilterChipModel: Identifiable {
    let id = UUID()
    var label: String
    var isSelected: Bool
}

/// An interactive filter chip. Selected reads as a solid ink pill + a check glyph (never the accent, never
/// color alone). Default / selected / pressed / disabled are covered; the press commits in ≤100ms via the
/// `ButtonStyle` before any animation (J-9.1). Disabled is read from the environment (`.disabled()`), never a
/// hand-dimmed color.
struct FilterChip: View {
    /// The chip's label — a short noun phrase ("By day", "By type"). UI family, never caps body (J-3.5).
    let label: String
    /// Whether this chip is the selected one in its group. The caller enforces one-selected-per-group.
    let isSelected: Bool
    /// Toggle action — the caller flips its own selection model.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(label)
            } icon: {
                // The non-color half of the selection signal: a check appears only when selected, so the
                // state survives grayscale (02-color §6). Hidden (not removed) when unselected keeps the
                // label baseline steady across the toggle.
                Image(systemName: "checkmark")
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .labelStyle(FilterChipLabelStyle(showsIcon: isSelected))
        }
        .buttonStyle(FilterChipButtonStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Label layout (icon ↔ label pairing)

/// Lays the optional check glyph at `Spacing.paired` (8pt) from the label — the icon↔label rung (J-1). When
/// unselected the icon slot is collapsed so the chip hugs its label, matching the mockup's two widths.
private struct FilterChipLabelStyle: LabelStyle {
    let showsIcon: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.paired) {
            if showsIcon {
                configuration.icon
                    .font(Typography.footnote) // glyph scales with Dynamic Type (no fixed pt; J-0.3)
            }
            configuration.title
        }
    }
}

// MARK: - Capsule style (fill · shape · press · 44pt target)

/// The chip's capsule treatment, driven by `configuration.isPressed` so the press commits in ≤100ms before
/// the release animation (J-9.1). Reads `.isEnabled` from the environment for the disabled register; never a
/// hand-dimmed color (05-components intro). All values are semantic tokens.
private struct FilterChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// The HIG minimum tap target — a floor, content/Dynamic Type still grow the chip. `@ScaledMetric`
    /// scales it with the label so it holds at large text (T-6.4); a bare `44` literal would not (J-0.3).
    @ScaledMetric(relativeTo: .subheadline) private var minTapTarget: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.subhead) // UI family, content density — not chrome-thin (J-5)
            .foregroundStyle(labelColor)
            // Vertical/horizontal inset pads the visual capsule and guarantees the 44pt tap dimension
            // (HIG; 05-components §5) without a fixed frame (J-0.3).
            .padding(.vertical, Spacing.paired)
            .padding(.horizontal, Spacing.cardInset)
            .frame(minHeight: minTapTarget)
            .background(fill, in: .capsule) // pill shape — chrome radius for a chip (J-10.2)
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }

    /// Selected → the ink pill's legible light label (`textOnAccent`-style, on a solid dark fill).
    /// Disabled → the muted past/placeholder ink. Default → primary ink on the neutral well.
    private var labelColor: Color {
        if !isEnabled { return ColorRole.textTertiary }
        return isSelected ? ColorRole.textOnAccent : ColorRole.textPrimary
    }

    /// Selected is a SOLID INK pill (`textPrimary`), never the accent (the load-bearing call; §05 cap).
    /// Unselected is a quiet neutral well (`fillSecondary`). Disabled mutes the unselected fill further.
    private var fill: Color {
        if isSelected { return ColorRole.textPrimary }
        return isEnabled ? ColorRole.fillSecondary : ColorRole.fillTertiary
    }
}

// MARK: - Previews — one per meaningful state (05-design-system §8; snapshot matrix in Wave E)

#Preview("FilterChip — states") {
    // A local fixture group: one selected, the rest not — the single-selected-per-group invariant the
    // caller owns, shown here statically.
    let group = [
        FilterChipModel(label: "By day", isSelected: true),
        FilterChipModel(label: "By type", isSelected: false),
        FilterChipModel(label: "Orphans", isSelected: false),
    ]

    return VStack(alignment: .leading, spacing: Spacing.sectionGap) {
        // default + selected, side by side (the group register from the mockup)
        HStack(spacing: Spacing.paired) {
            ForEach(group) { chip in
                FilterChip(label: chip.label, isSelected: chip.isSelected, action: {})
            }
        }

        // disabled register
        FilterChip(label: "By type", isSelected: false, action: {})
            .disabled(true)
    }
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}
