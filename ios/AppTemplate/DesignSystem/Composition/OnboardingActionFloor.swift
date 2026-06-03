// OnboardingActionFloor.swift — a COMPOSITION primitive: the SOLID immersive-flow CTA floor
// (05-components §2; J-0.1 EXCEPTION / J-6.1). The solid sibling of the glass `ActionBar`.
//
// The onboarding config floor pinned in the bottom thumb zone: a full-width primary CTA and an optional
// full-width ghost below it. Ports the mockup `.ob-action` floor + `.ob-cta` + `.ob-ghost`
// (screen-shell.css §"Solid action floor — config CTA"). This is the floor every immersive onboarding
// step composes via `ScreenScaffold(actions:)`.
//
// ── SOLID, not glass — the deliberate carve-out from "glass on floating chrome only" (J-0.1) ──────────
// The default for floating chrome is the system Liquid Glass material (`ActionBar`). This floor is the
// considered EXCEPTION: the immersive onboarding config floor is SOLID by design (the mockup floor is an
// opaque paper floor, not a frosted bar) — a takeover flow wants a calm, opaque base under the CTA, not a
// translucency sampling the content scrolling behind it. So this primitive paints an OPAQUE
// `ColorRole.surfacePage` floor with a top hairline `separator`, and never touches `glassEffect` /
// `.buttonStyle(.glass)` / `GlassEffectContainer`. This exception is logged in `docs/decisions.md`; the
// glass `ActionBar` remains the default for every non-immersive screen. (No gradient fill — gradients as
// fills are slop, J-2.4 / 08-slop; the mockup's transparent→solid fade is rendered as a solid floor.)
//
// ── One primary per region (J-6.1) ───────────────────────────────────────────────────────────────────
// Exactly one accent CTA — a `PillButton(.primary)` (the budgeted `ColorRole.actionPrimary` fill, via the
// button, never a fill we paint here). The optional second action is a `PillButton(.ghost)` — transparent,
// low-stakes ("Pick a specific hotel or address") — never a second primary (J-6.1).
//
// ── Reuse, don't rebuild ──────────────────────────────────────────────────────────────────────────────
// The buttons are `PillButton` (the tier-driven content button) — so the pill shape, the ≥44pt
// Dynamic-Type-scaled tap target, and the ≤100ms press all come from there. This floor owns only the
// SOLID ground, the hairline, the chrome-thin padding, and the primary-over-ghost stack.
//
// ── Accessibility identifiers are the CALLER's job ───────────────────────────────────────────────────
// The floor takes labels/actions/ids as args and bakes NO fixed id; a screen passes
// `primaryAccessibilityID` (e.g. "onboarding.cta") / `ghostAccessibilityID` so its own contract owns the
// id namespace.
//
// Semantic tokens only — no literal spacing/colors, no `Primitive.*` (J-0.2).
import SwiftUI

/// The SOLID bottom action floor for the immersive onboarding flow: a full-width `PillButton(.primary)`
/// CTA over an optional full-width `PillButton(.ghost)`, on an opaque `surfacePage` floor with a top
/// hairline.
///
/// Value-arg form — the screen supplies the verb-led titles (`J-11.3`: "Continue with Lisbon", "Pick a
/// specific hotel or address"), the actions, the optional `primaryEnabled` gate, and the
/// accessibility-identifier passthroughs. The floor owns the look (solid, chrome-thin density,
/// one-primary restraint); the screen owns the data and the ids.
///
/// SOLID by design (J-0.1 exception — see file header + `docs/decisions.md`): unlike the glass
/// `ActionBar`, the immersive config floor is opaque. Used only by the onboarding takeover flow.
struct OnboardingActionFloor: View {

    private let primaryTitle: String
    private let primaryEnabled: Bool
    private let primaryAccessibilityID: String?
    private let primaryAction: () -> Void
    private let ghostTitle: String?
    private let ghostAccessibilityID: String?
    private let ghostAction: (() -> Void)?

    /// - Parameters:
    ///   - primaryTitle: the CTA's verb-led label (`J-11.3`). The accent rides the `PillButton(.primary)`
    ///     role only (`ColorRole.actionPrimary`), never a fill we paint (J-2.4).
    ///   - primaryEnabled: gates the CTA when the step isn't satisfiable yet; the floor stays present.
    ///   - primaryAccessibilityID: caller-supplied id (e.g. `"onboarding.cta"`); the floor bakes none.
    ///   - ghostTitle: an optional low-stakes ghost action below the CTA. Pass `nil` for primary-only.
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
        // Primary over an optional ghost — the `.ob-cta` / `.ob-ghost` stack. The hairline-tight gap
        // between them keeps the ghost reading as a lesser appendage to the CTA, not a sibling (J-6.1).
        VStack(spacing: Spacing.hairline) {
            PillButton(title: primaryTitle, tier: .primary, action: primaryAction)
                .frame(maxWidth: .infinity)            // full-width CTA (the `.ob-cta` width: 100%)
                .disabled(!primaryEnabled)
                .accessibilityIdentifier(primaryAccessibilityID ?? "")

            if let ghostTitle, let ghostAction {
                PillButton(title: ghostTitle, tier: .ghost, action: ghostAction)
                    .frame(maxWidth: .infinity)        // full-width ghost (`.ob-ghost` width: 100%)
                    .accessibilityIdentifier(ghostAccessibilityID ?? "")
            }
        }
        // Chrome-thin: the floor hosts the action and recedes — top/horizontal inset from `cardInset`,
        // tight inter-button gap from `hairline`. Content + Dynamic Type size the buttons (J-0.3).
        .padding(.horizontal, Spacing.cardInset)
        .padding(.top, Spacing.cardInset)
        .padding(.bottom, Spacing.paired)
        .frame(maxWidth: .infinity)
        // SOLID floor (the J-0.1 exception): an opaque `surfacePage` ground with a top hairline — NOT
        // glass, NOT a gradient fill. The hairline separates the floor from the content scrolling above.
        .background(alignment: .top) {
            ColorRole.surfacePage
                .overlay(alignment: .top) {
                    ColorRole.separator
                        .frame(height: separatorThickness)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// The top hairline thickness — a 1pt-on-the-grid separator scaled with text so the seam holds at
    /// large Dynamic Type; never a fixed visual frame for the floor itself (J-0.3, J-4.3).
    @ScaledMetric(relativeTo: .body) private var separatorThickness: CGFloat = 1
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

/// Previews only: stacks placeholder content under the floor so the solid floor reads against scrolling
/// content (the floor pins to the bottom of an immersive step, content scrolling above its hairline).
private func placeholderStage<Floor: View>(@ViewBuilder floor: () -> Floor) -> some View {
    ZStack(alignment: .bottom) {
        ColorRole.surfacePage.ignoresSafeArea()
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            ForEach(0..<8, id: \.self) { _ in
                Text("Content scrolls above the solid onboarding action floor.")
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
