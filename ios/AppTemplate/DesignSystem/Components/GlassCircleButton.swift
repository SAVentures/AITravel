// GlassCircleButton.swift — the bar glyph button (05-components.md §1.1; J-0.1/J-8.3/J-2.4).
//
// One SF Symbol on the system Liquid Glass material, circular, 44×44pt hit target. Ports `.gbtn`
// (mockups/components/Components.html §01). The ONE component that touches glass, because it IS floating
// chrome — via `.buttonStyle(.glass)`, never hand-rolled. Inside an already-glass bar the host demotes it
// to a plain glyph (no glass-on-glass, J-8.3). Tint conveys meaning ONLY (J-2.4): the accent rides the
// selected glyph, paired with the `.isSelected` trait so it is never color alone (02-color §6).
import SwiftUI

/// A circular Liquid Glass glyph button for floating bars / overlay chips (05-components §1.1).
///
/// One SF Symbol on the system glass material, a 44×44pt hit target, `.tint` only to convey selection.
/// Data in as value-type args only — no `AppStore`, no domain object (05-design-system §8).
///
/// - Note: standalone, this carries its own glass. Inside an already-glass bar it must be demoted to a
///   plain glyph button by the host so two glass layers never stack (J-8.3).
struct GlassCircleButton: View {

    /// The SF Symbol name for the glyph (e.g. `"chevron.left"`, `"star"`). Value-type arg.
    let systemImage: String

    /// A short verb/role label for assistive tech (the glyph carries no text — 05-components §1.1).
    let accessibilityLabel: String

    /// Selected/active conveys meaning: the glyph takes the accent tint AND the `.isSelected` trait, so
    /// the state is never color alone (J-2.4, 02-color §6).
    let isSelected: Bool

    /// The tap action.
    let action: () -> Void

    /// The HIG minimum hit target — scaled with Dynamic Type so the touch area grows with the user's text
    /// size rather than staying a fixed point value (05-components intro, T-6.4).
    @ScaledMetric(relativeTo: .body) private var hitTarget: CGFloat = Sizing.minTapTarget

    init(
        systemImage: String,
        accessibilityLabel: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                // The glyph is symbol-sized; the 44pt target comes from the frame below, not a fixed
                // point size on the symbol (it scales with the control + Dynamic Type).
                .imageScale(.large)
                // Center the glyph inside the full 44pt circle so the whole capsule is the tap target.
                .frame(width: hitTarget, height: hitTarget)
                .contentShape(.circle)
        }
        // System Liquid Glass — the ONE place a component touches glass (it's a bar glyph). `.interactive`
        // adds the system touch-point illumination on press (05-components §1.1). Never hand-rolled.
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        // Tint conveys meaning ONLY: the accent rides the selected glyph; an unselected glyph is neutral
        // ink (J-2.4). Paired below with the `.isSelected` trait so it is never color alone.
        .tint(isSelected ? ColorRole.actionPrimary : ColorRole.textPrimary)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

/// A faux frosted/striped stage (ports the mockup `.glass-stage`) so the glass translucency reads — the
/// system material samples what's behind it, so a snapshot/preview over flat paper would show no glass.
/// The future snapshot (Wave E) renders both states over a representative stage like this one.
private struct GlassStage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            // A representative striped paper ground (the system glass samples this so the material reads).
            // Built from semantic surface roles only — no literal colors (J-0.2).
            ColorRole.surfacePage
            VStack(spacing: Spacing.sm) {
                ColorRole.surfaceGrouped
                ColorRole.fillTertiary
                ColorRole.surfaceGrouped
                ColorRole.fillSecondary
            }
            content
                .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("GlassCircleButton") {
    GlassStage {
        HStack(spacing: Spacing.md) {
            // default — neutral ink glyph
            GlassCircleButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Back",
                action: {}
            )
            // selected — the accent tint conveys the active state (paired with the .isSelected trait)
            GlassCircleButton(
                systemImage: "star.fill",
                accessibilityLabel: "Saved",
                isSelected: true,
                action: {}
            )
            GlassCircleButton(
                systemImage: "ellipsis",
                accessibilityLabel: "More",
                action: {}
            )
        }
    }
}
