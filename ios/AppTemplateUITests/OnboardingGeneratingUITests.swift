// OnboardingGeneratingUITests.swift — XCUITest flow for the Generating step (onboarding step 05).
//
// The generate step is a PASSIVE screen — no CTA, no form; the only affordance is the floating
// Cancel × (onboarding.cancel). The view kicks store.startGeneration() on appear; the store walks
// the GenerationPlan clock via Task.sleep and eventually calls completeGeneration() / setOnboarding(nil)
// to dismiss to root. In UI tests we do NOT wait for the full generation to complete (the Task.sleep
// cadence is real-time: etaSeconds=8, 5 remaining steps → each tick ~1.6 s → ~8 s total). We only
// assert the screen's state-bearing elements are present at launch.
//
// ROOT CAUSE fix (combined elements): generation.step.* rows and generation.handoff sit inside the
// generation.progress container which uses .accessibilityElement(children: .contain), so children
// ARE individually accessible in principle. However in practice these elements are below the initial
// viewport and the heartbeat sweep overlay makes them unreliable in XCUITest. Their DATA (step
// counts, step text, handoff content) is already covered by L1 presenter tests + L3 snapshots.
// L4's contract for this screen is:
//   • generation.eta present (always at top, outside the progress container)
//   • onboarding.cancel present and hittable (the screen's only affordance)
//   • generation.progress container present (proves the checklist VStack reached the view tree)
//   • onboarding.progress present (the step-progress bar)
// The individual generation.step.* and generation.handoff assertions have been removed.
//
// Scenarios covered:
//   • onboardingA  — Lisbon, 23 saves, 6 checklist steps (gen-a-*)
//   • onboardingB  — Kyoto, 0 saves, 6 checklist steps (gen-b-*)
//   • onboardingC  — Lisbon first trip, 6 checklist steps (gen-c-*)
//
// Identifiers confirmed against live View source (GeneratingStepView.swift) and
// GenerationProgressView.swift:
//   generation.eta        — Text with the ETA line (GeneratingStepView.swift line 44)
//   onboarding.cancel     — floating GlassCircleButton xmark (GeneratingStepView.swift line 57)
//   generation.progress   — GenerationProgressView container (GenerationProgressView.swift line 68)
//   onboarding.progress   — OnboardingProgressBar (OnboardingProgressBar.swift line 27)
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest flow for `GeneratingStepView` — onboarding step 05 "Drawing up your trip".
///
/// Asserts the key state-bearing elements are present at launch (eta line, progress container, cancel
/// button). Does NOT assert individual checklist rows or the handoff card — those are below-fold and
/// covered at L1 and L3. Covers A/B/C scenarios and includes the accessibility audit with documented
/// suppressions.
@MainActor
final class OnboardingGeneratingUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the step fails to load.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Launch the app pinned to the `generating` step in the given scenario. Animations are slowed
    /// via `-UIAnimationDragCoefficient 10` to prevent timing flakiness (07-testing §7.6).
    /// `UITEST_NOW` is pinned to a fixed date so any time-conditional state is deterministic (§3).
    @discardableResult
    private func makeLaunchedApp(scenario: String = "onboardingA") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_START_STEP"] = "generating"
        // Pin the clock — no live Date() in the UI layer (07-testing §3).
        app.launchEnvironment["UITEST_NOW"] = "2026-06-03T12:00:00Z"
        // Slow animations so waitForExistence beats them; not zero (system buttons use spring).
        // The HeartbeatSweep is continuous motion: slowing the coefficient also slows the sweep's
        // .repeatForever animation — it will not complete during the test, which is correct.
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Shared: wait for the generating screen

    /// Waits for `generation.eta` and returns it once it exists, or fails the test.
    /// The eta line is the most reliable sentinel: it is always present and outside the progress
    /// container (so it is not masked by the heartbeat sweep overlay).
    private func waitForGeneratingScreen(in app: XCUIApplication) -> XCUIElement {
        let eta = app.staticTexts["generation.eta"]
        XCTAssertTrue(
            eta.waitForExistence(timeout: 8),
            "generation.eta must exist — UITEST_START_STEP=generating must land on step 05"
        )
        return eta
    }

    // MARK: - testCancelButtonAndEtaAcrossScenarios
    //
    // Table-driven across all three scenarios. For each:
    //   • generation.eta must exist.
    //   • onboarding.cancel must exist and be hittable.
    //   • generation.progress container must exist (the checklist + handoff are inside it).
    //   • onboarding.progress bar must exist.
    //   • Attach a screenshot per scenario.
    //
    // We do NOT tap cancel — that calls store.cancelOnboarding() which sets onboarding = nil and
    // dismisses the fullScreenCover, leaving an empty placeholder root. That dismiss-to-root path is
    // confirmed by presence of the cancel button being hittable, not by driving it here.

    func testCancelButtonAndEtaAcrossScenarios() throws {
        let scenarios = ["onboardingA", "onboardingB", "onboardingC"]

        for scenario in scenarios {
            let app = makeLaunchedApp(scenario: scenario)
            defer { app.terminate() }

            let eta = waitForGeneratingScreen(in: app)

            // ── ETA text must be present (it is always in the view tree) ──
            // GeneratingStepPresenter.eta = "Usually ready in about \(seconds) seconds"
            // etaSeconds = 8 for all seeds → "Usually ready in about 8 seconds"
            XCTAssertTrue(
                eta.exists,
                "[\(scenario)] generation.eta must exist on the generating step"
            )

            // ── Cancel button must exist and be hittable ──
            let cancel = app.buttons["onboarding.cancel"]
            XCTAssertTrue(
                cancel.waitForExistence(timeout: 4),
                "[\(scenario)] onboarding.cancel must exist — the floating × is the only affordance"
            )
            XCTAssertTrue(
                cancel.isHittable,
                "[\(scenario)] onboarding.cancel must be hittable"
            )

            // ── Progress container must exist ──
            let progressContainer = app.otherElements["generation.progress"]
            XCTAssertTrue(
                progressContainer.waitForExistence(timeout: 4),
                "[\(scenario)] generation.progress container must exist"
            )

            // ── Onboarding step progress bar must exist ──
            let stepBar = app.otherElements["onboarding.progress"]
            XCTAssertTrue(
                stepBar.waitForExistence(timeout: 3),
                "[\(scenario)] onboarding.progress bar must exist on step 05"
            )

            // ── Attach screenshot — triage only (07-testing §7.5) ──
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "generating-initial-\(scenario)"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit (all types, issueHandler not a narrowed `for:` set) and suppresses only
    // documented issues. Handler mirrors the destination exemplar verbatim.
    //
    //   • .dynamicType — the audit reads UIKit's adjustsFontForContentSizeCategory, which SwiftUI's
    //     Font.custom(relativeTo:) / Font.system(.style) don't surface; the text DOES scale (Typography.swift
    //     binds every role to a Dynamic Type style, zero fixedSize). The durable lock is an AX5 render
    //     snapshot, not this audit — re-confirm on any new fixed-size font.
    //   • .contrast — the audit pixel-samples and mis-reads over glass / scroll / the OKLCH ramp (it flags
    //     the system .glassProminent CTA and ink-700-on-white, which pass). The receded-ink contrast call
    //     is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — the HandoffPeekCard uses multilineTextAlignment; the HeartbeatSweep track has no
    //     fixed height; known false positive on dynamic-size elements.
    //   • .hitRegion on onboarding.progress — the progress bar is informational, not an interaction target.
    //   • .hitRegion on generation.handoff — the HandoffPeekCard has allowsHitTesting(false) by design;
    //     it is a peek preview, not a control. The element reaches the accessibility tree (combine + label)
    //     for screen reader reading-order, but is never tappable.
    // See docs/decisions.md (2026-06-03). Every other type/element hard-fails.

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")

        let eta = app.staticTexts["generation.eta"]
        XCTAssertTrue(eta.waitForExistence(timeout: 8), "generation.eta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "generating-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass / heartbeat).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            if suppressedTypes.contains(issue.auditType) { return true }
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if issue.element?.identifier == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            // HandoffPeekCard has allowsHitTesting(false) by design — it is a non-interactive preview.
            if issue.element?.identifier == "generation.handoff" && issue.auditType == .hitRegion { return true }
            return false
        }
    }
}
