// OnboardingRobot.swift — Shared UITest robot for all Onboarding XCUITest suites.
//
// Centralizes the three helpers that are copy-pasted byte-identically across the six onboarding
// UITest suites (OnboardingTripShapeUITests, OnboardingWhenUITests, OnboardingBaseLocationUITests,
// OnboardingGettingAroundUITests, OnboardingDestinationUITests, OnboardingGeneratingUITests):
//
//   1. launch(scenario:startStep:now:failureRate:staticMap:) — owns all launchEnvironment /
//      launchArguments setup (UITEST_SCENARIO, UITEST_START_STEP, UITEST_NOW,
//      UITEST_FAILURE_RATE, UITEST_STATIC_MAP, -UIAnimationDragCoefficient 10). Reproduced
//      from OnboardingTripShapeUITests.makeLaunchedApp (lines 63-74) and cross-checked against
//      OnboardingWhenUITests / OnboardingGettingAroundUITests / OnboardingBaseLocationUITests
//      (the four files that set UITEST_FAILURE_RATE). `staticMap: true` sets
//      UITEST_STATIC_MAP=1 (BaseLocation); default false = key absent = no change for others.
//
//   2. scrollToElement(_:maxSwipes:) — reproduced byte-identically from OnboardingTripShapeUITests
//      (lines 79-82) and OnboardingGettingAroundUITests (lines 81-84), which are identical.
//
//   3. performOnboardingAudit(extraSuppressions:) — centralizes the BROAD
//      performAccessibilityAudit { issueHandler } with the documented suppression list that is
//      common to all six suites:
//        • [.dynamicType, .contrast, .textClipped] — systemic FPs on this custom design
//        • onboarding.progress .hitRegion — informational element, not an interaction target
//      The optional `extraSuppressions` trailing closure (default { _ in false }, a no-op) is
//      evaluated AFTER the common checks, letting per-suite callers add screen-specific
//      exemptions without touching the common set.
//      Reproduced verbatim from OnboardingTripShapeUITests.testAccessibilityAudit (lines 372-378),
//      OnboardingWhenUITests (lines 328-334), OnboardingGettingAroundUITests (lines 396-402),
//      OnboardingDestinationUITests (lines 353-358). Track B will refine this suppression set here.
//
// DIVERGENCES across suites (noted for the coordinator):
//
//   • OnboardingGeneratingUITests.testAccessibilityAudit adds a screen-specific suppression:
//       `if issue.element?.identifier == "generation.handoff" && issue.auditType == .hitRegion { return true }`
//     Suites can migrate this via:
//       try robot.performOnboardingAudit {
//           $0.element?.identifier == "generation.handoff" && $0.auditType == .hitRegion
//       }
//     The common suppression set is unchanged. The default { _ in false } is a no-op.
//
//   • OnboardingBaseLocationUITests.testAccessibilityAudit adds a screen-specific suppression:
//       `if issue.auditType == .elementDetection && id.isEmpty && (issue.element?.label ?? "").isEmpty { return true }`
//     (for a decorative element on the static map placeholder). Suites can migrate this via:
//       try robot.performOnboardingAudit {
//           $0.auditType == .elementDetection && ($0.element?.identifier ?? "").isEmpty && ($0.element?.label ?? "").isEmpty
//       }
//     The BaseLocation suite also runs a second audit pass in manual mode; that call likewise
//     accepts the same extraSuppressions closure.
//
//   • UITEST_FAILURE_RATE: OnboardingDestinationUITests and OnboardingGeneratingUITests do NOT set
//     UITEST_FAILURE_RATE in their local makeLaunchedApp (the key is absent). The robot's
//     launch(failureRate:) forwards UITEST_FAILURE_RATE ONLY when non-nil, preserving today's
//     behavior for those suites when they call launch without failureRate.
//
// pbxproj membership: AppTemplateUITests uses PBXFileSystemSynchronizedRootGroup (objectVersion 77,
// isa = PBXFileSystemSynchronizedRootGroup). The new Support/ subdirectory auto-joins the
// AppTemplateUITests target — no manual pbxproj entry is needed. Confirmed from project.pbxproj:
// target 000000000000000000000022 has fileSystemSynchronizedGroups = [000000000000000000000032].
//
// UITEST_FAILURE_RATE seam: nothing in the app currently reads this key (AppTemplateApp.swift reads
// only UITEST_SCENARIO). The optional param is kept as deliberate scaffolding for the onboarding
// write command (coming later). See docs/decisions.md for the dated entry (Task C5 / A-DEC).
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// Shared robot for all Onboarding UITest suites.
///
/// Wraps `XCUIApplication` and owns:
/// - Launch-environment/argument setup (`launch(scenario:startStep:now:failureRate:staticMap:)`)
/// - Scroll helper (`scrollToElement(_:maxSwipes:)`)
/// - Common accessibility audit (`performOnboardingAudit(extraSuppressions:)`)
/// - Minimal a11y-id query conveniences (`cta(_:)`, `backButton`)
///
/// Screen-specific suppressions (BaseLocation `.elementDetection`, Generating `generation.handoff`)
/// are passed in via the `extraSuppressions` trailing closure — they are NOT widened into the
/// common suppression set. The default `{ _ in false }` is a no-op for suites that need no extras.
@MainActor struct OnboardingRobot {

    // MARK: - Properties

    /// The underlying application under test.
    let app: XCUIApplication

    // MARK: - Init

    init() {
        app = XCUIApplication()
    }

    // MARK: - Launch

    /// Launch the app wired to a given onboarding scenario and optional start step.
    ///
    /// - Parameters:
    ///   - scenario: The `UITEST_SCENARIO` value (e.g. `"onboardingA"`, `"onboardingB"`,
    ///     `"onboardingC"`). Defaults to `"onboardingA"`.
    ///   - startStep: The `UITEST_START_STEP` value to skip directly to a step (e.g. `"tripShape"`,
    ///     `"when"`, `"baseLocation"`, `"gettingAround"`, `"generating"`). Pass `nil` to start from
    ///     the first step (no UITEST_START_STEP key set — used by the end-to-end flow walk, C6).
    ///   - now: The `UITEST_NOW` ISO-8601 string, pinning the clock so time-conditional state is
    ///     deterministic (07-testing §3). Defaults to `"2026-06-03T12:00:00Z"`.
    ///   - failureRate: When non-nil, forwards `UITEST_FAILURE_RATE` into `launchEnvironment` as
    ///     a string. When `nil` (the default), the key is NOT set — preserving today's launch
    ///     behavior for suites that do not drive the failure path. This is a future hook for the
    ///     onboarding write command (roadmap); nothing in AppTemplateApp.swift reads it today.
    ///     See docs/decisions.md (Task C5) — do NOT delete this param.
    ///   - staticMap: When `true`, sets `UITEST_STATIC_MAP = "1"` in `launchEnvironment`.
    ///     Required by `OnboardingBaseLocationUITests` to exercise the static-map placeholder path.
    ///     Default `false` = key absent = no change in behavior for all other suites.
    /// - Returns: The launched `XCUIApplication`.
    @discardableResult
    func launch(
        scenario: String = "onboardingA",
        startStep: String? = nil,
        now: String = "2026-06-03T12:00:00Z",
        failureRate: Double? = nil,
        staticMap: Bool = false
    ) -> XCUIApplication {
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        if let step = startStep {
            app.launchEnvironment["UITEST_START_STEP"] = step
        }
        // Pin the clock — no live Date() in the UI layer (07-testing §3).
        app.launchEnvironment["UITEST_NOW"] = now
        // Forward UITEST_FAILURE_RATE ONLY when a rate is explicitly requested.
        // When nil, the key is absent — matching the prior behavior of suites that omit it.
        // Future hook: the onboarding write command will read this to drive error-path/rollback tests.
        // See docs/decisions.md (Task C5). Do NOT treat nil-forwarding as dead code.
        if let rate = failureRate {
            app.launchEnvironment["UITEST_FAILURE_RATE"] = String(rate)
        }
        // Forward UITEST_STATIC_MAP ONLY when the caller opts in (BaseLocation static-map path).
        // Default false = key absent = today's behavior for all other suites.
        if staticMap {
            app.launchEnvironment["UITEST_STATIC_MAP"] = "1"
        }
        // Slow animations so waitForExistence beats spring transitions; not zero (system buttons).
        // Reproduced verbatim from OnboardingTripShapeUITests.makeLaunchedApp (line 71).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Scroll helper

    /// Swipes up until `element` is realized into the accessibility tree, or `maxSwipes` is exhausted.
    ///
    /// Required for elements below the initial viewport — lazy/below-fold elements report
    /// `.exists == false` until scrolled into the realized tree (07-testing §7.3).
    ///
    /// Reproduced byte-identically from `OnboardingTripShapeUITests.scrollToElement(_:in:maxSwipes:)`
    /// (lines 79-82) and `OnboardingGettingAroundUITests.scrollToElement(_:in:maxSwipes:)` (lines 81-84).
    func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes { app.swipeUp(); swipes += 1 }
    }

    // MARK: - Common accessibility audit

    /// Runs the BROAD `performAccessibilityAudit` with the common documented suppression set.
    ///
    /// The audit is BROAD — no `for:` narrowing — so new audit types are never silently dropped.
    /// Suppressions are per-type or per-element, never blanket (returning `true` unconditionally
    /// would be a bug per 07-testing §7.4).
    ///
    /// **Common suppression set (verbatim from all six suites):**
    /// - `.dynamicType` — the audit reads `adjustsFontForContentSizeCategory`, which SwiftUI's
    ///   `Font.custom(relativeTo:)` / `Font.system(.style)` don't surface; text DOES scale
    ///   (Typography.swift binds every role to a Dynamic Type style, zero fixedSize). Durable lock
    ///   is an AX5 render snapshot (Track B). Re-confirm on any new fixed-size font.
    /// - `.contrast` — pixel-sampler mis-reads OKLCH inks over glass/scroll. Receded-ink contrast
    ///   is a design-doc decision, not an XCUITest assertion.
    /// - `.textClipped` — FilterChip, SegmentedSelector, DayStepper, and Menu labels grow from
    ///   minHeight/minWidth (no fixed frame); known FP on custom layout-driven elements.
    /// - `.hitRegion` on `onboarding.progress` — the progress bar is informational, not an
    ///   interaction target. The identifier `"onboarding.progress"` is confirmed in
    ///   `OnboardingProgressBar.swift` (line 27).
    ///
    /// **Screen-specific suppressions** are passed in via `extraSuppressions`, NOT baked into the
    /// common set here.
    ///
    /// - Parameter extraSuppressions: A closure evaluated AFTER all common checks. Return `true`
    ///   to suppress the issue, `false` to let it fall through to the hard-fail. The default
    ///   `{ _ in false }` is a no-op — byte-identical behavior for suites that pass nothing.
    ///
    ///   Example — Generating suite:
    ///   ```swift
    ///   try robot.performOnboardingAudit {
    ///       $0.element?.identifier == "generation.handoff" && $0.auditType == .hitRegion
    ///   }
    ///   ```
    ///   Example — BaseLocation suite:
    ///   ```swift
    ///   try robot.performOnboardingAudit {
    ///       $0.auditType == .elementDetection
    ///           && ($0.element?.identifier ?? "").isEmpty
    ///           && ($0.element?.label ?? "").isEmpty
    ///   }
    ///   ```
    ///
    /// Track B will refine the suppression set in this one centralized place.
    func performOnboardingAudit(
        extraSuppressions: @escaping (XCUIAccessibilityAuditIssue) -> Bool = { _ in false }
    ) throws {
        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            if suppressedTypes.contains(issue.auditType) { return true }
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if issue.element?.identifier == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            // Screen-specific suppression hook — caller supplies; default { _ in false } is a no-op.
            // Preserves per-suite exemptions (generation.handoff, BaseLocation decorative elements)
            // without widening the common suppression set.
            if extraSuppressions(issue) { return true }
            // All other issues hard-fail — a blanket return true here would be a defect (§7.4).
            return false
        }
    }

    // MARK: - Convenience element accessors

    /// Returns a button element queried by a dot-namespaced accessibility identifier.
    ///
    /// Usage: `robot.cta("tripshape.cta")`, `robot.cta("when.cta")`, etc.
    /// Never query by displayed text — identifiers are stable contracts (07-testing §7.3).
    func cta(_ id: String) -> XCUIElement {
        app.buttons[id]
    }

    /// Returns the floating back-navigation button (`onboarding.back`).
    ///
    /// Confirmed in every step view (e.g. GettingAroundStepView.swift line 56,
    /// TripShapeStepView.swift line 46, WhenStepView.swift, BaseLocationStepView.swift line 79).
    var backButton: XCUIElement {
        app.buttons["onboarding.back"]
    }
}
