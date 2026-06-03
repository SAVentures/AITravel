// OnboardingActionFloorSnapshotTests.swift — Layer 3 render-snapshot lock for OnboardingActionFloor.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// States covered (§6.2 — one snapshot per key state):
//   primary-only     — one glassProminent CTA, no ghost; primary enabled.
//   primary-disabled — glassProminent CTA disabled (.disabled modifier applied); no ghost.
//   primary-ghost    — glassProminent CTA + ghost (plain glass) secondary action; both enabled.
//
// These three states mirror the three named #Preview fixtures in OnboardingActionFloor.swift.
// Each locks a distinct visual configuration of the GlassEffectContainer: the number of buttons,
// the tint/enabled treatment of the primary, and whether the ghost row is present — no unit test
// can confirm that these co-occur correctly.
//
// Ground: The glass material samples whatever is behind it. A flat-white host would show no glass
// character. Each view is composed as a ZStack with surfacePage + a column of body text behind the
// floor — the same `placeholderStage` pattern the previews use. This is a local inline variant
// (placeholderStage is private to OnboardingActionFloor.swift).
//
// Determinism (§6.4):
//   - No Date() — OnboardingActionFloor carries no time state.
//   - No withAnimation — rendered at rest.
//   - designSystemEnvironment() injects \.disablesOneShotMotion = true.
//   - action closures are no-ops (tap never fires in a snapshot).
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("OnboardingActionFloor snapshots")
@MainActor
struct OnboardingActionFloorSnapshotTests {

    // MARK: - Snapshots

    @Test("primary-only — glassProminent CTA; no ghost; primary enabled")
    func primaryOnly() {
        assertDesignSnapshot(
            placeholderStage {
                OnboardingActionFloor(
                    primaryTitle: "Continue with Lisbon",
                    primaryAccessibilityID: "onboarding.cta",
                    primaryAction: {}
                )
            },
            named: "primary-only"
        )
    }

    @Test("primary-disabled — glassProminent CTA disabled; no ghost")
    func primaryDisabled() {
        assertDesignSnapshot(
            placeholderStage {
                OnboardingActionFloor(
                    primaryTitle: "Continue with Lisbon",
                    primaryEnabled: false,
                    primaryAccessibilityID: "onboarding.cta",
                    primaryAction: {}
                )
            },
            named: "primary-disabled"
        )
    }

    @Test("primary-ghost — glassProminent CTA + plain glass ghost; both enabled")
    func primaryGhost() {
        assertDesignSnapshot(
            placeholderStage {
                OnboardingActionFloor(
                    primaryTitle: "Use Alfama as base",
                    primaryAccessibilityID: "onboarding.cta",
                    ghostTitle: "Pick a specific hotel or address",
                    ghostAccessibilityID: "onboarding.ghost",
                    ghostAction: {},
                    primaryAction: {}
                )
            },
            named: "primary-ghost"
        )
    }
}

// MARK: - Placeholder stage (local)
//
// Stacks placeholder body text under the floor so the system Liquid Glass material samples
// real content — a flat white host would show no glass character. Mirrors the semantic-token
// construction of the private `placeholderStage` in OnboardingActionFloor.swift; replicated
// here because that function is private to the component file.

@MainActor
@ViewBuilder
private func placeholderStage<Floor: View>(
    @ViewBuilder floor: () -> Floor
) -> some View {
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
