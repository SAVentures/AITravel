// GlassCircleButtonSnapshotTests.swift — Layer 3 render-snapshot lock for GlassCircleButton.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// States covered (§6.2 — one snapshot per key state):
//   default  — isSelected: false  → neutral ink glyph, no accent tint
//   selected — isSelected: true   → accent-tinted glyph + .isSelected trait
//
// Ground: the system Liquid Glass material samples whatever is behind the button. A blank white
// host would show no glass character. We render each button over a frosted-stripe stage built from
// the same semantic surface roles the component's own GlassStage preview uses (surfacePage /
// surfaceGrouped / fillTertiary / fillSecondary striped under the button). GlassStage is private
// to the component file so we replicate the equivalent ground inline here; no app-source changes.
//
// Determinism (§6.4):
//   - No Date() / live clock (these components carry no time state).
//   - No withAnimation (at rest).
//   - .environment(\.disablesOneShotMotion, true) injected via designSystemEnvironment().
//   - action closure is a no-op — tap never fires in a snapshot.
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("GlassCircleButton snapshots")
struct GlassCircleButtonSnapshotTests {

    // MARK: - default

    @Test
    @MainActor
    func default_() {
        assertDesignSnapshot(
            frostedStage {
                GlassCircleButton(
                    systemImage: "chevron.left",
                    accessibilityLabel: "Back",
                    isSelected: false,
                    action: {}
                )
            },
            named: "default"
        )
    }

    // MARK: - selected

    @Test
    @MainActor
    func selected() {
        assertDesignSnapshot(
            frostedStage {
                GlassCircleButton(
                    systemImage: "star.fill",
                    accessibilityLabel: "Saved",
                    isSelected: true,
                    action: {}
                )
            },
            named: "selected"
        )
    }
}

// MARK: - Frosted stage (local — GlassStage is private to GlassCircleButton.swift)

/// A representative frosted/striped ground so the Liquid Glass material samples real content and
/// reads correctly in the snapshot. Mirrors the semantic-token construction of the private
/// `GlassStage` in `GlassCircleButton.swift` (same ColorRole/Spacing tokens, same layering).
///
/// The system glass material is translucent and tone-maps what's behind it; rendering over a flat
/// white surface would show no glass character and produce a misleading baseline.
@MainActor
@ViewBuilder
private func frostedStage<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    ZStack {
        // Page ground
        ColorRole.surfacePage
        // Horizontal stripes — grouped and fill bands mirror the component's GlassStage
        VStack(spacing: Spacing.paired) {
            ColorRole.surfaceGrouped
            ColorRole.fillTertiary
            ColorRole.surfaceGrouped
            ColorRole.fillSecondary
        }
        // The button, centred, with standard card inset
        content()
            .padding(Spacing.cardInset)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
