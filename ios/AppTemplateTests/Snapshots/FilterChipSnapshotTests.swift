// FilterChipSnapshotTests.swift — Layer 3 render-snapshot lock for FilterChip.
//
// Freezes the three key states of FilterChip so any later change that silently
// moves a pixel — fill color, check-glyph visibility, label ink, disabled muting,
// capsule shape — fails the build.
//
// Governing doc: ios/docs/engineering/07-testing.md §6.
// Component source: ios/AppTemplate/DesignSystem/Components/FilterChip.swift.
//
// States covered (one snapshot each, §6.2):
//   default  — unselected, enabled. Neutral `fillSecondary` pill, no check glyph.
//   selected — selected, enabled. Solid ink (`textPrimary`) pill + leading check glyph.
//   disabled — unselected, disabled via `.disabled(true)`. Muted `fillTertiary` pill,
//              `textTertiary` label — disabled is NEVER a hand-dimmed color; it reads
//              from the environment (`@Environment(\.isEnabled)` in FilterChipButtonStyle
//              line 90).
//
// Determinism (§6.4):
//   - No live clock — FilterChip is a pure display component with no time-conditional state.
//   - No `withAnimation` — snapshots at rest.
//   - `designSystemEnvironment()` (inside the helper) injects `.disablesOneShotMotion = true`
//     and registers embedded fonts — no per-file setup needed.
//   - `SampleData` is not required; FilterChip takes value-type arguments only.
//
// Baselines land at:
//   __Snapshots__/FilterChipSnapshotTests/default.png
//   __Snapshots__/FilterChipSnapshotTests/selected.png
//   __Snapshots__/FilterChipSnapshotTests/disabled.png
//
// First run records (fails with "recorded") — commit the PNGs. Do NOT leave
// `record: .all` in this file; that silently re-records and hides regressions (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("FilterChip snapshots")
struct FilterChipSnapshotTests {

    // MARK: - default

    /// Unselected, enabled — the chip's resting state.
    /// Renders a `fillSecondary` capsule with the label in `textPrimary` ink.
    /// The check-glyph icon slot is collapsed (hidden, not removed) so the label
    /// baseline is stable across the toggle (FilterChip.swift line 55–57).
    @Test("default — unselected, enabled, fillSecondary capsule, no check glyph")
    @MainActor func default_() {
        assertDesignSnapshot(
            chipCanvas {
                FilterChip(label: "By day", isSelected: false, action: {})
            },
            named: "default"
        )
    }

    // MARK: - selected

    /// Selected, enabled — the ink pill register.
    /// Renders a solid `textPrimary` capsule with a leading checkmark glyph.
    /// Confirms the non-color selection signal (check glyph) co-occurs with the fill
    /// change — no unit test can verify that co-occurrence (§6 L3).
    @Test("selected — selected, enabled, solid ink capsule with leading check glyph")
    @MainActor func selected() {
        assertDesignSnapshot(
            chipCanvas {
                FilterChip(label: "By day", isSelected: true, action: {})
            },
            named: "selected"
        )
    }

    // MARK: - disabled

    /// Unselected, disabled via `.disabled(true)` — the muted register.
    /// Disabled is read from the environment (`@Environment(\.isEnabled)` in
    /// FilterChipButtonStyle line 90) — never a hand-dimmed literal. Renders
    /// `fillTertiary` background and `textTertiary` label ink.
    @Test("disabled — unselected, disabled via environment, fillTertiary + textTertiary")
    @MainActor func disabled() {
        assertDesignSnapshot(
            chipCanvas {
                FilterChip(label: "By day", isSelected: false, action: {})
                    .disabled(true)
            },
            named: "disabled"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a chip in a representative page-surface canvas so the PNG shows the chip
/// in context rather than on a transparent background. Mirrors the `#Preview` setup
/// in FilterChip.swift (padding + `surfacePage` fill). Not a full-bleed screen; the
/// chip is a component, not a screen (§6.2 "isolated component" path).
@MainActor
private func chipCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.cardInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
