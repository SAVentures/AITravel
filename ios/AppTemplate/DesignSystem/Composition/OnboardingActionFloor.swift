/*
 Floating Liquid Glass CTA for the immersive onboarding flow — the onboarding sibling of `ActionBar`,
 with a primary-over-ghost vocabulary. Ports the mockup `.ob-cta` / `.ob-ghost`; composed by each step
 via `ScreenScaffold(actions:)`.

 The earlier solid-floor exception (`docs/decisions.md` W1-09) is SUPERSEDED: no opaque floor, no
 hairline — the action floats over content and the glass comes from the SYSTEM button styles, never a
 hand-rolled translucency or `glassChrome()`. Primary + optional ghost share ONE GlassEffectContainer
 because glass can't sample glass (J-8.3). Accessibility ids are caller-supplied; the floor bakes none.
*/
import SwiftUI

struct OnboardingActionFloor: View {

    private let primaryTitle: String
    private let primaryEnabled: Bool
    private let primaryAccessibilityID: String?
    private let primaryAction: () -> Void
    private let ghostTitle: String?
    private let ghostAccessibilityID: String?
    private let ghostAction: (() -> Void)?

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
        GlassEffectContainer {
            VStack(spacing: Spacing.sm) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(.glassProminent)
                    .tint(ColorRole.actionPrimary)        // accent via tint only, never a fill (J-2.4)
                    .frame(maxWidth: .infinity)
                    .disabled(!primaryEnabled)
                    .accessibilityIdentifier(ifPresent: primaryAccessibilityID)

                if let ghostTitle, let ghostAction {
                    Button(ghostTitle, action: ghostAction)
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier(ifPresent: ghostAccessibilityID)
                }
            }
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(.horizontal, Spacing.screenInset)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

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

// Previews only: stacks placeholder content under the floor so the glass reads against real material.
private func placeholderStage<Floor: View>(@ViewBuilder floor: () -> Floor) -> some View {
    ZStack(alignment: .bottom) {
        ColorRole.surfacePage.ignoresSafeArea()
        VStack(alignment: .leading, spacing: Spacing.md) {
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
