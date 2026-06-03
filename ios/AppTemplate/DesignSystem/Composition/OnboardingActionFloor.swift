// OnboardingActionFloor.swift — a COMPOSITION primitive: the FLOATING Liquid Glass CTA for the immersive
// onboarding flow (05-design-system §9; 05-components §2; J-0.1 / J-6.1). The onboarding sibling of
// `ActionBar` — the same floating-glass-chrome pattern, just with a primary-over-ghost vocabulary.
//
// The onboarding step's primary action, floating in the bottom thumb zone over the scrolling content.
// Ports the mockup `.ob-cta` / `.ob-ghost` actions, now rendered with the SYSTEM Liquid Glass material
// instead of the old solid floor. This is the floor every immersive onboarding step composes via
// `ScreenScaffold(actions:)`.
//
// ── Floating Liquid Glass — glass on floating chrome ONLY (J-0.1), now applies normally ────────────────
// The earlier solid-floor exception (`docs/decisions.md` 2026-06-02 W1-09) is SUPERSEDED per user
// direction: there is NO solid `surfacePage` floor, NO top hairline, NO opaque background — the action
// floats over content. The glass comes from the SYSTEM button styles (`.buttonStyle(.glassProminent)` /
// `.buttonStyle(.glass)`), the iOS 26 Liquid Glass material — never a hand-rolled translucency, never
// `glassChrome()` on content. The new supersede entry is logged in `docs/decisions.md`.
//
// ── Grouped in ONE GlassEffectContainer (05-components §2; 05-design-system §6) ───────────────────────
// Glass can't sample glass, so the primary + (optional) ghost that must blend/morph as one piece of
// chrome share a SINGLE `GlassEffectContainer` (J-8.3). The container is the grouping seam; the button
// styles are the material — we do NOT additionally wrap the floor in `glassChrome()`.
//
// ── One primary per region (J-6.1) ───────────────────────────────────────────────────────────────────
// Exactly one `.glassProminent` CTA — the accent rides the prominent button's tint only
// (`ColorRole.actionPrimary`), never a fill we paint (J-2.4). The optional second action is the lesser
// `.glass` ghost ("Pick a specific hotel or address") — never a second prominent button (J-6.1).
//
// ── Accessibility identifiers are the CALLER's job ───────────────────────────────────────────────────
// The floor takes labels/actions/ids as args and bakes NO fixed id; a screen passes
// `primaryAccessibilityID` (e.g. "onboarding.cta") / `ghostAccessibilityID` so its own contract owns the
// id namespace.
//
// Semantic tokens only — no literal spacing/colors, no `Primitive.*` (J-0.2). No fixed frames (J-0.3) —
// the buttons size to content + Dynamic Type.
import SwiftUI

/// The FLOATING Liquid Glass bottom action floor for the immersive onboarding flow: a full-width
/// `.glassProminent` primary CTA over an optional full-width `.glass` ghost, grouped in one
/// `GlassEffectContainer` so they blend as a single piece of floating chrome.
///
/// Value-arg form — the screen supplies the verb-led titles (`J-11.3`: "Continue with Lisbon", "Pick a
/// specific hotel or address"), the actions, the optional `primaryEnabled` gate, and the
/// accessibility-identifier passthroughs. The floor owns the look (floating glass, one-primary restraint);
/// the screen owns the data and the ids.
///
/// Floating chrome only (J-0.1): the action floats over scrolling content. Glass-on-floating-chrome now
/// applies normally — the prior solid-floor exception (`docs/decisions.md` W1-09) is superseded.
struct OnboardingActionFloor: View {

    private let primaryTitle: String
    private let primaryEnabled: Bool
    private let primaryAccessibilityID: String?
    private let primaryAction: () -> Void
    private let ghostTitle: String?
    private let ghostAccessibilityID: String?
    private let ghostAction: (() -> Void)?

    /// - Parameters:
    ///   - primaryTitle: the CTA's verb-led label (`J-11.3`). The accent rides the `.glassProminent` tint
    ///     only (`ColorRole.actionPrimary`), never a fill we paint (J-2.4).
    ///   - primaryEnabled: gates the CTA when the step isn't satisfiable yet; the floor stays present.
    ///   - primaryAccessibilityID: caller-supplied id (e.g. `"onboarding.cta"`); the floor bakes none.
    ///   - ghostTitle: an optional low-stakes `.glass` ghost action below the CTA. `nil` for primary-only.
    ///   - ghostAccessibilityID: caller-supplied id for the ghost (e.g. `"onboarding.ghost"`).
    ///   - ghostAction: the ghost's tap handler (paired with `ghostTitle`).
    ///   - primaryAction: the CTA's tap handler.
    init(
        primaryTitle: String,
        primaryEnabled: Bool = true,
        primaryAccessibilityID: String? = nil,
        ghostTitle: String? = nil,
        ghostAccessibilityID: String? = nil,
        ghostAction: (() -> Void)? = nil,
        primaryAction: @escaping () -> Void
    ) {
        self.primaryTitle = primaryTitle
        self.primaryEnabled = primaryEnabled
        self.primaryAccessibilityID = primaryAccessibilityID
        self.ghostTitle = ghostTitle
        self.ghostAccessibilityID = ghostAccessibilityID
        self.ghostAction = ghostAction
        self.primaryAction = primaryAction
    }

    var body: some View {
        // One container so the (optional) ghost + the primary blend as a single piece of chrome — glass
        // can't sample glass, so grouping is required, not N independent glass surfaces (J-8.3).
        GlassEffectContainer {
            VStack(spacing: Spacing.paired) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(.glassProminent)         // the ONE prominent CTA (J-6.1)
                    .tint(ColorRole.actionPrimary)        // accent via tint only, never a fill (J-2.4)
                    .frame(maxWidth: .infinity)           // full-width CTA (the `.ob-cta` width: 100%)
                    .disabled(!primaryEnabled)
                    .accessibilityIdentifier(primaryAccessibilityID ?? "")

                if let ghostTitle, let ghostAction {
                    Button(ghostTitle, action: ghostAction)
                        .buttonStyle(.glass)              // lesser, low-stakes ghost (J-6.1)
                        .frame(maxWidth: .infinity)       // full-width ghost (`.ob-ghost` width: 100%)
                        .accessibilityIdentifier(ghostAccessibilityID ?? "")
                }
            }
            .buttonBorderShape(.capsule)                  // content buttons are pills (J-10.2)
            .controlSize(.large)
        }
        // Chrome-thin: the standard horizontal inset + a thumb-zone bottom breath — the floor floats and
        // recedes (J-5.1). Content + Dynamic Type size the buttons (J-0.3); no opaque floor, no hairline.
        .padding(.horizontal, Spacing.screenInset)
        .padding(.top, Spacing.paired)
        .padding(.bottom, Spacing.paired)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews (one per meaningful state · Wave-1 rule)

#Preview("Primary only") {
    placeholderStage {
        OnboardingActionFloor(
            primaryTitle: "Continue with Lisbon",
            primaryAccessibilityID: "onboarding.cta"
        ) {}
    }
}

#Preview("Primary + ghost") {
    placeholderStage {
        OnboardingActionFloor(
            primaryTitle: "Use Alfama as base",
            primaryAccessibilityID: "onboarding.cta",
            ghostTitle: "Pick a specific hotel or address",
            ghostAccessibilityID: "onboarding.ghost",
            ghostAction: {}
        ) {}
    }
}

#Preview("Primary disabled") {
    placeholderStage {
        OnboardingActionFloor(
            primaryTitle: "Continue with Lisbon",
            primaryEnabled: false,
            primaryAccessibilityID: "onboarding.cta"
        ) {}
    }
}

/// Previews only: stacks placeholder content under the floor so the glass reads against real material and
/// the thumb-zone placement is visible (the floor floats over scrolling content in a real screen).
private func placeholderStage<Floor: View>(@ViewBuilder floor: () -> Floor) -> some View {
    ZStack(alignment: .bottom) {
        ColorRole.surfacePage.ignoresSafeArea()
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            ForEach(0..<8, id: \.self) { _ in
                Text("Content scrolls under the floating onboarding action floor.")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.screenInset)
        .frame(maxHeight: .infinity, alignment: .top)

        floor()
    }
}
