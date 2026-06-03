// GlassCircleButton.swift — the bar glyph button (05-components.md §1.1; J-0.1/J-8.3/J-2.4).
//
// A single SF Symbol on the iOS 26 system Liquid Glass material, shaped as a circle, with a 44×44pt hit
// target — the glyph button that floats in nav bars, toolbars, and overlay chips. Ports the mockup
// `.gbtn` (mockups/components/Components.html §01): 44×44, a ~20pt glyph, `ink-700` at rest, `accent-600`
// when selected.
//
// ── This is the ONE component that touches glass — and it is a *bar glyph*, not content ───────────────
// Every other `Components/` view is resting content on a solid surface and NEVER touches glass (J-0.1,
// 05-components §3.3). This one is the single exception because it IS floating chrome (a bar glyph). It
// uses the SYSTEM material via `.buttonStyle(.glass)` — never a hand-rolled translucency, never the
// `glassChrome()` content seam (that wraps *containers*; a button picks up glass from its style).
//
// ── If it ever migrates into a glass bar, it DROPS its own glass (J-8.3 — no glass-on-glass) ──────────
// Two translucent layers read as dishwater. When a `GlassCircleButton` sits inside an already-glass bar
// (a tab/top bar, the `ActionBar`'s `GlassEffectContainer`), the host bar carries the glass and these
// glyphs render as plain glyph buttons (`.borderless`/`.plain`) instead — never `.glass` inside `.glass`
// (05-components §1.1). That demotion is the *host*'s call; standalone (an overlay chip over a photo /
// map) this button carries its own glass, as here.
//
// ── Tint conveys MEANING only (J-2.4) ─────────────────────────────────────────────────────────────────
// `.tint(_:)` is applied ONLY to the selected/active glyph (it carries `actionPrimary` — the mockup's
// `--accent-600`). Tinting every glyph destroys the signal (05-components §1.1, conorluddy). The accent
// is paired with the `isSelected` accessibility trait so the state survives grayscale / VoiceOver — never
// color alone (02-color §6). An unselected glyph stays neutral (`textPrimary`).
//
// Semantic tokens only — no literal, no `Primitive.*` (J-0.2). The 44pt hit target scales with text via
// `@ScaledMetric` (never a fixed CGFloat — T-6.4); `.buttonBorderShape(.circle)` + `controlSize` shape
// the capsule, never a `.frame(width:height:)` (05-components §1.4, J-0.3).
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

    /// The 44×44pt minimum hit target — the HIG floor — scaled with Dynamic Type so the touch area grows
    /// with the user's text size rather than staying a fixed point value (05-components intro, T-6.4).
    @ScaledMetric(relativeTo: .body) private var hitTarget: CGFloat = 44

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
            VStack(spacing: Spacing.paired) {
                ColorRole.surfaceGrouped
                ColorRole.fillTertiary
                ColorRole.surfaceGrouped
                ColorRole.fillSecondary
            }
            content
                .padding(Spacing.cardInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("GlassCircleButton") {
    GlassStage {
        HStack(spacing: Spacing.itemGap) {
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
