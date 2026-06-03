// DesignSnapshot.swift — the single render-snapshot seam for all Layer 3 tests.
//
// Every snapshot in AppTemplateTests goes through `assertDesignSnapshot(_:named:)` so
// all visual tests render at an identical, pinned viewport regardless of file. The
// config is committed and reviewed once; per-file overrides are forbidden.
//
// Governing doc: ios/docs/engineering/07-testing.md §6.1 (pinned helper) + §6.4 (determinism).
//
// ── Phase 0 scope note ─────────────────────────────────────────────────────────────────────────
// 07-testing §6.1 describes a `designSystemEnvironment()` that ALSO seeds an `AppStore` from
// `SampleData.library()` at a fixed `simulatedNow`. That injection is **deferred to Phase 2**:
// `AppStore` and `SampleData` do not exist in the Phase 0 foundation. All Wave C components
// take value-type fixtures as arguments and require no store. The store-seed line will be added
// to `designSystemEnvironment()` when Phase 2 scaffolds the domain layer (see plan §OD-5).
// ──────────────────────────────────────────────────────────────────────────────────────────────

import Foundation
import SnapshotTesting
import SwiftUI
import UIKit
@testable import AppTemplate

// MARK: - Pinned viewport

/// The single viewport for every render snapshot. iPhone 17 Pro logical frame.
///
/// Spec (07-testing §6.1):
///   - logical size  393 × 852 pt
///   - safe-area     top 59 pt / bottom 34 pt / leading 0 / trailing 0
///   - interface style  .light
///   - display scale    3× (@3x)
///
/// **Re-record all baselines if this config changes.** Do so in a dedicated commit
/// named `chore: re-record snapshots for simulator pin change` and review every diff
/// (07-testing §8).
let canonicalConfig = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 393, height: 852),
    traits: UITraitCollection(traitsFrom: [
        .init(userInterfaceStyle: .light),
        .init(displayScale: 3),
    ])
)

// MARK: - Canonical snapshot assertion

/// Renders `view` at the pinned iPhone 17 Pro viewport and diffs against the committed
/// baseline PNG at `__Snapshots__/<TestClassName>/<testName>.<named>.png`.
///
/// Usage (one call per component state):
/// ```swift
/// assertDesignSnapshot(PillButton(.primary, label: "Book"), named: "primary")
/// assertDesignSnapshot(PillButton(.ghost,   label: "Book"), named: "ghost")
/// ```
///
/// Rules (07-testing §6.3–6.4):
/// - First run **records** the baseline and fails with "recorded" — commit the PNG.
/// - Subsequent runs **diff**; a pixel change fails the build.
/// - Never snapshot mid-animation (`withAnimation` is banned in snapshot bodies).
/// - Never leave `record: .all` in committed code — it silently re-records and hides regressions.
///
/// - Parameters:
///   - view: The SwiftUI view to render. Pass it unwrapped; this function wraps it in
///     `designSystemEnvironment()` and a `UIHostingController`.
///   - named: The state name, which becomes the PNG filename component. e.g. `"primary"`,
///     `"borrowed"`, `"loading"`. Keep it lowercase-kebab.
///   - file: Injected by the compiler — identifies the calling test file for baseline path resolution.
///   - testName: Injected by the compiler — drives the `__Snapshots__/<class>/` subdirectory name.
///   - line: Injected by the compiler — reported in Xcode on a diff failure.
@MainActor
func assertDesignSnapshot<V: View>(
    _ view: V,
    named name: String,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    let host = UIHostingController(rootView: view.designSystemEnvironment())
    host.overrideUserInterfaceStyle = .light
    // swift-snapshot-testing derives __Snapshots__/ from `file` (an absolute #filePath),
    // so baselines land next to the test source in the worktree.
    assertSnapshot(
        of: host,
        as: .image(on: canonicalConfig),
        named: name,
        file: file,
        testName: testName,
        line: line
    )
}

// MARK: - Design-system environment modifier

extension View {
    /// Applies the standard design-system environment for render snapshots (07-testing §6.1 / §6.4).
    ///
    /// What this does **now** (Phase 0):
    ///   1. Registers embedded Schibsted Grotesk + Hanken Grotesk fonts via
    ///      `FontRegistry.registerEmbeddedFonts()` so `Typography.*` roles resolve to the real
    ///      custom faces rather than falling back to the system face (07-testing §6.4 — Font fallback).
    ///   2. Injects `\.disablesOneShotMotion = true` so any entrance animation or continuous shimmer
    ///      (e.g. `LoadingSkeleton`'s sweep) settles to its resting frame before capture — preventing
    ///      mid-flight flakes (07-testing §6.4 — One-shot entrance motion).
    ///
    /// What this does NOT do yet (Phase 2 deferral):
    ///   • Seed an `AppStore` from `SampleData.library()` at `simulatedNow`. That injection is
    ///     described in 07-testing §6.1 but requires `AppStore` and `SampleData`, which do not exist
    ///     in Phase 0. It will be added here when Phase 2 scaffolds the domain layer (plan §OD-5).
    ///     Screen-level snapshots in Phase 2 depend on this; component snapshots in Phase 0 do not
    ///     (all Wave C components accept value-type fixtures and are store-free).
    ///
    /// - Returns: The receiver wrapped in the deterministic snapshot environment.
    @MainActor
    func designSystemEnvironment() -> some View {
        // Step 1 — register fonts (idempotent; safe to call per-snapshot).
        FontRegistry.registerEmbeddedFonts()

        // Step 2 — settle any entrance / continuous motion to rest before capture, and force the
        // deterministic MapKit placeholder (no network tiles) for any screen with a map (07-testing §6.4).
        return self
            .environment(\.disablesOneShotMotion, true)
            .environment(\.mapSnapshotMode, true)
    }
}
