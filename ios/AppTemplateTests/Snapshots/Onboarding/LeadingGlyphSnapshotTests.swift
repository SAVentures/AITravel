// LeadingGlyphSnapshotTests.swift — Layer 3 render-snapshot lock for LeadingGlyph.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// LeadingGlyph is an enum — not a View itself. It is the presenter-level vocabulary that a screen
// maps onto its own GlassCircleButton (per the component doc: "a screen maps it onto its own
// floating GlassCircleButton(systemImage:accessibilityLabel:)"). The snapshot therefore locks the
// actual rendered artefact: a GlassCircleButton constructed from each case's .systemImage and
// .accessibilityLabel. This is the real production path; snapshotting a bare enum case would test
// nothing visual.
//
// States covered (§6.2 — one snapshot per key state):
//   close — LeadingGlyph.close → "xmark" glyph; used on the first onboarding step to dismiss.
//   back  — LeadingGlyph.back  → "chevron.left" glyph; used on subsequent steps.
//
// Both buttons render at default (not selected) — the LeadingGlyph is always a navigation control,
// never in a "selected/active" state that would change the glyph tint.
//
// Ground: frosted-stripe stage so the Liquid Glass material samples real content and reads correctly
// (the same strategy as GlassCircleButtonSnapshotTests). GlassStage is private to GlassCircleButton.swift
// so the equivalent is replicated inline here with the same semantic-token construction.
//
// Determinism (§6.4):
//   - No Date() — LeadingGlyph carries no time state.
//   - No withAnimation — rendered at rest.
//   - designSystemEnvironment() injects \.disablesOneShotMotion = true.
//   - action closures are no-ops (tap never fires in a snapshot).
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("LeadingGlyph snapshots")
@MainActor
struct LeadingGlyphSnapshotTests {

    // MARK: - Snapshots

    @Test("close — xmark glyph; onboarding dismiss control")
    func close() {
        let glyph = LeadingGlyph.close
        assertDesignSnapshot(
            frostedStage {
                GlassCircleButton(
                    systemImage: glyph.systemImage,
                    accessibilityLabel: glyph.accessibilityLabel,
                    action: {}
                )
            },
            named: "close"
        )
    }

    @Test("back — chevron.left glyph; onboarding back control")
    func back() {
        let glyph = LeadingGlyph.back
        assertDesignSnapshot(
            frostedStage {
                GlassCircleButton(
                    systemImage: glyph.systemImage,
                    accessibilityLabel: glyph.accessibilityLabel,
                    action: {}
                )
            },
            named: "back"
        )
    }
}

// MARK: - Frosted stage (local)
//
// A representative frosted/striped ground so the Liquid Glass material samples real content and
// reads correctly in the snapshot. Mirrors the semantic-token construction of the private
// `GlassStage` in `GlassCircleButton.swift`. GlassStage is private to that file, so the
// equivalent is replicated here; no app-source changes required.

@MainActor
@ViewBuilder
private func frostedStage<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    ZStack {
        ColorRole.surfacePage
        VStack(spacing: Spacing.paired) {
            ColorRole.surfaceGrouped
            ColorRole.fillTertiary
            ColorRole.surfaceGrouped
            ColorRole.fillSecondary
        }
        content()
            .padding(Spacing.cardInset)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
