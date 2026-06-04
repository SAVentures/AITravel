// SegmentedSelectorSnapshotTests.swift — Layer 3 render-snapshot lock for SegmentedSelector.
//
// These tests are the lock on SegmentedSelector at authoring time. They do not
// verify the design (that is the fidelity-reviewer's job); they freeze the accepted
// render so any later change that silently moves a pixel — ink pill on selected segment,
// fillTertiary track, label typography, icon + text layout — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   two-way-selected    — 2-way text-only (base mode), first option selected
//   two-way-no-sel      — 2-way text-only with the second option selected (covers unselected left)
//   three-way-selected  — 3-way text-only (pace), middle option (Balanced) selected
//   four-way-with-icons — 4-way with SF Symbols (transport), second item (Transit) selected
//   scrollable          — 5-way icon+label (transport extended), scrollable:true, third item selected;
//                         confirms the ScrollView wrapper, content-width segments (not equal-width),
//                         and the ink pill on a scrollable track.
//
// The control is embedded in a surfacePage canvas matching the #Preview padding so the
// PNG shows it in the context a real onboarding screen provides.
//
// Determinism (07-testing §6.4):
//   · No Date() — SegmentedSelector is a pure display component with no clock dependency.
//   · No withAnimation — snapshots at rest; scaleEffect animation is a tap response, never fired.
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · Fixtures are inline value literals mirroring the #Preview fixtures in SegmentedSelector.swift.
//
// Baselines land in __Snapshots__/SegmentedSelectorSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

// MARK: - Stable test-local option type
//
// SegmentedSelector is generic over `Identifiable & Hashable`. We define a private fixture
// option type here rather than relying on the file-private `SegmentOption` in the component
// source (which is @testable-inaccessible as a private type).

private struct TestSegmentOption: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String?
    init(id: String, title: String, systemImage: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

@Suite("SegmentedSelector snapshots")
struct SegmentedSelectorSnapshotTests {

    // MARK: - Fixtures (mirror the #Preview values in SegmentedSelector.swift)

    private let baseModeOptions: [TestSegmentOption] = [
        TestSegmentOption(id: "smart",  title: "Smart from saved"),
        TestSegmentOption(id: "manual", title: "Pick manually"),
    ]

    private let paceOptions: [TestSegmentOption] = [
        TestSegmentOption(id: "easy",     title: "Easy"),
        TestSegmentOption(id: "balanced", title: "Balanced"),
        TestSegmentOption(id: "packed",   title: "Packed"),
    ]

    private let transportOptions: [TestSegmentOption] = [
        TestSegmentOption(id: "walk",    title: "Walk",    systemImage: "figure.walk"),
        TestSegmentOption(id: "transit", title: "Transit", systemImage: "tram.fill"),
        TestSegmentOption(id: "drive",   title: "Drive",   systemImage: "car.fill"),
        TestSegmentOption(id: "cycle",   title: "Cycle",   systemImage: "bicycle"),
    ]

    // 5-way transport-extended fixture — one more option than `transportOptions` so the row
    // overflows a 393pt canvas and exercises the ScrollView path (SegmentedSelector.swift line 25–27).
    private let scrollableTransportOptions: [TestSegmentOption] = [
        TestSegmentOption(id: "walk",    title: "Walk",    systemImage: "figure.walk"),
        TestSegmentOption(id: "transit", title: "Transit", systemImage: "tram.fill"),
        TestSegmentOption(id: "drive",   title: "Drive",   systemImage: "car.fill"),
        TestSegmentOption(id: "cycle",   title: "Cycle",   systemImage: "bicycle"),
        TestSegmentOption(id: "ferry",   title: "Ferry",   systemImage: "ferry.fill"),
    ]

    // MARK: - two-way-selected

    /// 2-way text-only (base mode), first option selected.
    /// The left segment shows the solid textPrimary ink pill; the right segment is clear (track shows through).
    /// Confirms the selected/unselected fill co-occurs with the correct label ink colors.
    @Test("two-way-selected — 2-way text-only, first option selected (ink pill left)")
    @MainActor func twoWaySelected() {
        let options = baseModeOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[0],
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "basemode",
                    onSelect: { _ in }
                )
            },
            named: "two-way-selected"
        )
    }

    // MARK: - two-way-no-sel

    /// 2-way text-only (base mode), second option selected.
    /// Confirms the ink pill moves to the right segment; the left is clear. Covers the
    /// unselected state of the first option alongside the selected state of the second.
    @Test("two-way-no-sel — 2-way text-only, second option selected (ink pill right)")
    @MainActor func twoWayNoSel() {
        let options = baseModeOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[1],
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "basemode",
                    onSelect: { _ in }
                )
            },
            named: "two-way-no-sel"
        )
    }

    // MARK: - three-way-selected

    /// 3-way text-only (pace), centre option selected.
    /// Confirms equal-width segments, the middle ink pill, and flanking clear segments.
    @Test("three-way-selected — 3-way text-only (pace), Balanced selected (ink pill centre)")
    @MainActor func threeWaySelected() {
        let options = paceOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[1],   // "Balanced"
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "pace",
                    onSelect: { _ in }
                )
            },
            named: "three-way-selected"
        )
    }

    // MARK: - four-way-with-icons

    /// 4-way with SF Symbols (transport), Transit selected.
    /// Confirms icon + text layout in each segment and the ink pill on the second item.
    @Test("four-way-with-icons — 4-way with SF Symbols (transport), Transit selected")
    @MainActor func fourWayWithIcons() {
        let options = transportOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[1],   // "Transit"
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "transport.mostly",
                    onSelect: { _ in }
                )
            },
            named: "four-way-with-icons"
        )
    }

    // MARK: - scrollable

    /// 5-way icon+label (transport extended), `scrollable: true`, "Drive" (index 2) selected.
    /// Mirrors the 4-way transport fixture but with `scrollable: true` and a fifth option so the
    /// track overflows the 393pt canvas. Confirms:
    ///   · The ScrollView wrapper is engaged (SegmentedSelector.swift line 25–27).
    ///   · Segments are content-width (not equal-width) — `equalWidth: false` in SegmentButtonStyle.
    ///   · The ink pill lands on the correct (Drive) segment amid content-width peers.
    ///   · `lineLimit(1)` keeps each label one line inside a scrollable track (line 86).
    @Test("scrollable — 5-way icon+label, scrollable:true, Drive selected, overflowing track")
    @MainActor func scrollable() {
        let options = scrollableTransportOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[2],   // "Drive"
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "transport.scrollable",
                    scrollable: true,
                    onSelect: { _ in }
                )
            },
            named: "scrollable"
        )
    }

    // MARK: - four-way-with-icons-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as `fourWayWithIcons` (4-way transport,
    /// Transit selected) but rendered at accessibilityExtraExtraExtraLarge (AX5) to lock
    /// Dynamic Type scaling of the icon+label segment layout, the ink pill, and the fillTertiary
    /// track at maximum text size. This is the most type-dense non-scrollable state — it exercises
    /// both the icon glyph and the text label in every segment simultaneously. Freezes any
    /// regression where a fixed segment height or font-size token change clips labels at AX5.
    /// Glass-free component — renders fully at AX5.
    /// (Task 3.4 — restores the AX5 compensating control lost per decisions.md 2026-06-03.)
    @Test("four-way-with-icons-ax5 — AX5 Dynamic Type: 4-way icon+label, Transit selected at accessibilityXXXL")
    @MainActor func fourWayWithIconsAX5() {
        let options = transportOptions
        assertDesignSnapshot(
            canvas {
                SegmentedSelector(
                    options: options,
                    selection: options[1],   // "Transit"
                    label: \.title,
                    systemImage: \.systemImage,
                    accessibilityIDPrefix: "transport.mostly",
                    onSelect: { _ in }
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "four-way-with-icons-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the selector in a surfacePage canvas with the same padding as the #Preview
/// in SegmentedSelector.swift. Not a full-bleed screen; the control is a component (§6.2).
@MainActor
private func canvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
