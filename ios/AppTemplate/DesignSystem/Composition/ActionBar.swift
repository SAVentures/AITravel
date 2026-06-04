// ActionBar.swift — a COMPOSITION primitive: the thumb-zone CTA bar (05-design-system §9;
// 05-components §2; J-0.1 / J-5.1 / J-6.1).
//
// The screen's primary action, pinned in the bottom thumb zone — the reachable place for a CTA on a
// large phone. A glass bar holding a prominent blue CTA and an optional outline secondary; content
// scrolls *under* it (the `ScreenScaffold` supplies the iOS 26 scroll-edge effect, 06-screens §2.1).
// The bar is chrome-thin: it hosts an action and recedes (mockup components.html §02 "Action bar").
//
// ── Glass on floating chrome ONLY (J-0.1, the non-negotiable) ────────────────────────────────────────
// This is the ONE content-area place glass appears — and it is *floating chrome*, not content. The
// glass comes from the system button styles (`.buttonStyle(.glassProminent)` / `.buttonStyle(.glass)`),
// the iOS 26 Liquid Glass material — never a hand-rolled translucency, never `.cardSurface()`.
//
// ── Grouped in ONE GlassEffectContainer (05-components §2; 05-design-system §6) ──────────────────────
// Glass can't sample glass, so the primary + secondary buttons that must blend/morph as one piece of
// chrome share a SINGLE `GlassEffectContainer`. We do NOT additionally wrap the bar in `glassChrome()`
// — stacking the bar's own glass under the buttons' glass would be glass-on-glass (J-8.3). The
// container is the grouping seam; the button styles are the material.
//
// ── One primary per region (J-6.1) ──────────────────────────────────────────────────────────────────
// Exactly one `.glassProminent` CTA. The optional second action is the lesser `.glass` (outline)
// secondary — two prominent buttons would be two competing asks (J-6.1 / AP-12). The accent rides the
// prominent button's role/tint only (`ColorRole.actionPrimary`), never a fill we paint (J-2.4).
//
// ── Chrome-thin density (J-5.1) ─────────────────────────────────────────────────────────────────────
// Tight vertical padding from `Spacing.sm`; the bar hosts a target and disappears. No content
// padding, no fixed frames (J-0.3) — the buttons size to content + Dynamic Type.
//
// ── Accessibility identifiers are the CALLER's job ──────────────────────────────────────────────────
// The bar takes labels/actions as args and bakes NO fixed id; a screen passes `primaryAccessibilityID`
// (e.g. "actionbar.primary") / `secondaryAccessibilityID` so its own contract owns the id namespace.
//
// Semantic tokens only — no literal spacing/colors, no `Primitive.*` (J-0.2).
import SwiftUI

/// The bottom thumb-zone CTA bar: a glass `.glassProminent` primary action and an optional `.glass`
/// secondary, grouped in one `GlassEffectContainer` so they blend as a single piece of floating chrome.
///
/// Value-arg form — the screen supplies the verb-led labels (`J-11.3`: "Borrow", "Add to day"), the
/// actions, optional `disabled` states, and the accessibility-identifier passthroughs. The bar owns the
/// look (glass, chrome-thin density, one-prominent restraint); the screen owns the data and the ids.
///
/// Floating chrome only (J-0.1): this is the single content-area place glass appears, and the
/// `ScreenScaffold` lets content scroll *under* it. Never used as content.
struct ActionBar: View {

    /// The lesser, optional action shown beside the primary CTA — rendered with `.buttonStyle(.glass)`
    /// (the outline secondary), never a second prominent button (J-6.1).
    struct SecondaryAction {
        let title: String
        let action: () -> Void
        var isDisabled: Bool = false
        var accessibilityID: String?

        init(
            _ title: String,
            isDisabled: Bool = false,
            accessibilityID: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.action = action
            self.isDisabled = isDisabled
            self.accessibilityID = accessibilityID
        }
    }

    private let primaryTitle: String
    private let primaryAction: () -> Void
    private let primaryIsDisabled: Bool
    private let primaryAccessibilityID: String?
    private let secondary: SecondaryAction?

    /// - Parameters:
    ///   - primaryTitle: the prominent CTA's verb-led label (`J-11.3`). The accent rides the
    ///     `.glassProminent` role only (`ColorRole.actionPrimary`), never a fill (J-2.4).
    ///   - primaryIsDisabled: disables the CTA when the action isn't available (e.g. already done);
    ///     the bar stays present (05-components §2 state table).
    ///   - primaryAccessibilityID: caller-supplied id (e.g. `"actionbar.primary"`); the bar bakes none.
    ///   - secondary: an optional lesser `.glass` action beside the CTA. Pass `nil` for primary-only.
    ///   - primaryAction: the prominent CTA's tap handler.
    init(
        primaryTitle: String,
        primaryIsDisabled: Bool = false,
        primaryAccessibilityID: String? = nil,
        secondary: SecondaryAction? = nil,
        primaryAction: @escaping () -> Void
    ) {
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.primaryIsDisabled = primaryIsDisabled
        self.primaryAccessibilityID = primaryAccessibilityID
        self.secondary = secondary
    }

    var body: some View {
        // One container so the (optional) secondary + the primary blend as a single piece of chrome —
        // glass can't sample glass, so grouping is required, not N independent glass surfaces (J-8.3).
        GlassEffectContainer {
            HStack(spacing: Spacing.sm) {
                if let secondary {
                    Button(secondary.title, action: secondary.action)
                        .buttonStyle(.glass)              // lesser, outline secondary (J-6.1)
                        .disabled(secondary.isDisabled)
                        .accessibilityIdentifier(ifPresent: secondary.accessibilityID)
                }

                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(.glassProminent)         // the ONE prominent CTA (J-6.1)
                    .tint(ColorRole.actionPrimary)        // accent via tint only, never a fill (J-2.4)
                    .frame(maxWidth: .infinity)           // the CTA owns the width; secondary hugs
                    .disabled(primaryIsDisabled)
                    .accessibilityIdentifier(ifPresent: primaryAccessibilityID)
            }
            .buttonBorderShape(.capsule)                  // content buttons are pills (J-10.2)
            .controlSize(.large)
        }
        // Chrome-thin: tight vertical padding, the standard horizontal inset — the bar recedes (J-5.1).
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.screenInset)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Optional-id passthrough

private extension View {
    /// Attaches `.accessibilityIdentifier` ONLY when `id` is non-nil. A nil id leaves the element
    /// unstamped (no empty `""` id), so the `.elementDetection` audit never sees a decorative blank-id
    /// node (Track B Task 1.3). The bar owns the mechanism; the screen owns the id value.
    @ViewBuilder
    func accessibilityIdentifier(ifPresent id: String?) -> some View {
        if let id {
            accessibilityIdentifier(id)
        } else {
            self
        }
    }
}

#Preview("Primary only") {
    placeholderStage {
        ActionBar(
            primaryTitle: "Open today's map",
            primaryAccessibilityID: "actionbar.primary"
        ) {}
    }
}

#Preview("Primary + secondary") {
    placeholderStage {
        ActionBar(
            primaryTitle: "Open today's map",
            primaryAccessibilityID: "actionbar.primary",
            secondary: .init("Add to day", accessibilityID: "actionbar.secondary") {}
        ) {}
    }
}

/// Previews only: stacks placeholder content under the bar so the glass reads against real material and
/// the thumb-zone placement is visible (the bar floats over scrolling content in a real screen).
private func placeholderStage<Bar: View>(@ViewBuilder bar: () -> Bar) -> some View {
    ZStack(alignment: .bottom) {
        ColorRole.surfacePage.ignoresSafeArea()
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                Text("Content scrolls under the floating action bar.")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.screenInset)
        .frame(maxHeight: .infinity, alignment: .top)

        bar()
    }
}
