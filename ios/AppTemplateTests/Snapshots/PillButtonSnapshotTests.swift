// PillButtonSnapshotTests.swift — Layer 3 render-snapshot lock for PillButton.
//
// Freezes the accepted render for each key state of `PillButton` so any later change that
// silently moves a pixel — fill, label color, opacity, padding, capsule shape — fails the
// build. One assertion per state; thin by design (07-testing §6, §6.2).
//
// States covered (§6.2 — "PillButton: .primary · .ghost"):
//   primary            — accent fill, textOnAccent label, systemImage leading, at rest
//   primary-pressed    — resting target at the committed press scale (0.985); ButtonStyle's
//                        `isPressed` is not externally constructible, so we apply the same
//                        `.scaleEffect(0.985)` the #Preview "Primary — pressed" uses (#188–193
//                        of PillButton.swift) — the closest representable variant.
//   primary-disabled   — `.disabled(true)` → 0.4 opacity via `isEnabled` env read in PillButtonStyle
//   primary-loading    — `isLoading: true` → spinner overlay, label hidden, input disabled
//   secondary          — fillTertiary well, textPrimary label
//   ghost              — transparent fill, textSecondary label, narrower horizontal padding
//   destructive        — destructive wash + destructive label color, system-role `.destructive`
//
// Determinism (07-testing §6.4):
//   - No `Date()` / live clock — component is store-free and clock-free.
//   - No `withAnimation` — all views rendered at rest.
//   - `designSystemEnvironment()` in the helper registers fonts and injects
//     `\.disablesOneShotMotion = true` (settles any entrance motion before capture).
//   - Fixed viewport via `canonicalConfig` (iPhone 17 Pro, 393×852, @3x, .light).
//
// Baselines land in __Snapshots__/PillButtonSnapshotTests/ alongside this file and are committed.
// First run records (fails with "recorded") — commit the PNGs; subsequent runs diff.

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("PillButton render snapshots")
@MainActor
struct PillButtonSnapshotTests {

    // A fixed width that lets the capsule size naturally around the label — wide enough that
    // the pill never clips at any of the four tiers' padding widths, but not full-screen so the
    // component renders in isolation rather than stretching edge-to-edge.
    private let buttonWidth: CGFloat = 280

    // MARK: - Primary tier

    @Test("primary — accent fill at rest")
    func primary() {
        let view = PillButton(
            title: "Save place",
            tier: .primary,
            systemImage: "bookmark",
            action: {}
        )
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "primary")
    }

    @Test("primary-pressed — resting target at committed press scale")
    func primaryPressed() {
        // `configuration.isPressed` inside PillButtonStyle is not externally constructible.
        // The project's own #Preview "Primary — pressed" (PillButton.swift:188–193) mirrors
        // the committed press scale via `.scaleEffect(0.985)` on the resting button — we do
        // the same so the snapshot locks the visual target the press commits from.
        let view = PillButton(
            title: "Save place",
            tier: .primary,
            systemImage: "bookmark",
            action: {}
        )
        .scaleEffect(0.985)
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "primary-pressed")
    }

    @Test("primary-disabled — 0.4 opacity via isEnabled environment")
    func primaryDisabled() {
        let view = PillButton(
            title: "Save place",
            tier: .primary,
            systemImage: "bookmark",
            action: {}
        )
        .disabled(true)
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "primary-disabled")
    }

    @Test("primary-loading — spinner overlay, label hidden, input disabled")
    func primaryLoading() {
        let view = PillButton(
            title: "Save place",
            tier: .primary,
            systemImage: "bookmark",
            isLoading: true,
            action: {}
        )
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "primary-loading")
    }

    // MARK: - Secondary tier

    @Test("secondary — fillTertiary well, textPrimary label")
    func secondary() {
        let view = PillButton(
            title: "Preview route",
            tier: .secondary,
            action: {}
        )
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "secondary")
    }

    // MARK: - Ghost tier

    @Test("ghost — transparent fill, textSecondary label")
    func ghost() {
        let view = PillButton(
            title: "See all",
            tier: .ghost,
            action: {}
        )
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "ghost")
    }

    // MARK: - Destructive tier

    @Test("destructive — wash fill, destructive label color, system role")
    func destructive() {
        let view = PillButton(
            title: "Remove from trip",
            tier: .destructive,
            systemImage: "trash",
            action: {}
        )
        .frame(width: buttonWidth)
        .padding()

        assertDesignSnapshot(view, named: "destructive")
    }
}
