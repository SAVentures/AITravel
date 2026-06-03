// OnboardingWhenUITests.swift — XCUITest flow for the When step (onboarding step 02/03).
//
// Drives the real app to the "When are you going?" step via UITEST_START_STEP=when and exercises:
//   • Initial state: month menu present, both precision segments present, CTA present and enabled,
//     exact-date pickers absent (default precision is justMonth).
//   • Precision toggle: tapping exactDates reveals when.start + when.end; tapping justMonth hides them.
//   • CTA advances: when.cta is hittable; after tapping, the When screen is no longer on screen.
//   • Accessibility audit with narrow, documented suppressions (same policy as OnboardingDestinationUITests).
//
// Scenarios covered (table-driven — the When step is structurally identical across A and C):
//   • onboardingA — returning, Lisbon (savedHere=23), tripDays=4 (fixedDays floor from TripShape)
//   • onboardingC — first trip, Lisbon (savedAnywhere=0), tripDays seeded from tasteDefaults (4 days)
//
// The When step's CTA title is always "Continue" (WhenStepPresenter.ctaTitle — not scenario-specific),
// so the table covers scenarios by asserting the structural ids, not copy variation.
//
// Identifiers confirmed against live View source (WhenStepView.swift):
//   when.cta                  — OnboardingActionFloor primary button (line 23, primaryAccessibilityID:)
//   when.month                — month Menu label (line 116, .accessibilityIdentifier("when.month"))
//   when.precision.justMonth  — SegmentedSelector segment: prefix "when.precision" + rawValue "justMonth"
//                               (SegmentedSelector.swift line 45, DatePrecision.id = rawValue,
//                               WhenStepView.swift line 159 extension DatePrecision: Identifiable)
//   when.precision.exactDates — same selector, rawValue "exactDates"
//   when.start                — DatePicker start date (line 124); only rendered when precision == .exactDates
//   when.end                  — DatePicker end date (line 135); only rendered when precision == .exactDates
//   onboarding.back           — floating GlassCircleButton chevron.left (line 45)
//   onboarding.progress       — OnboardingProgressBar (present on every onboarding step)
//
// DatePrecision rawValues confirmed in TripWhen.swift (line 11–12):
//   case justMonth  → "justMonth"
//   case exactDates → "exactDates"
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest flow for `WhenStepView` — onboarding step "when" (step index 2).
///
/// Verifies: month-menu presence; both precision segments present with justMonth as default (exact-date
/// pickers absent); tapping exactDates reveals the pickers; tapping justMonth hides them again; the CTA
/// is hittable and advances the flow. Runs across onboardingA and onboardingC and includes the
/// accessibility audit with the standard documented suppressions.
@MainActor
final class OnboardingWhenUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the When screen fails to load.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Launch the app pinned to the `when` step in the given scenario. Animations are slowed via
    /// `-UIAnimationDragCoefficient 10` to prevent timing flakiness (07-testing §7.6). `UITEST_NOW` is
    /// pinned to a fixed date so the month-menu derivation (12 months forward from "now") is deterministic
    /// (07-testing §3). `UITEST_FAILURE_RATE` is wired so the write-error path is driveable; the default
    /// "0" exercises the success path.
    @discardableResult
    private func makeLaunchedApp(
        scenario: String = "onboardingA",
        failureRate: String = "0",
        now: String = "2026-06-03T12:00:00Z"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_START_STEP"] = "when"
        // Pin the clock — WhenStepPresenter derives monthOptions from AppDate.simulatedNow (§3).
        app.launchEnvironment["UITEST_NOW"] = now
        app.launchEnvironment["UITEST_FAILURE_RATE"] = failureRate
        // Slow animations so waitForExistence beats them; not zero (system buttons use spring).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Shared: wait for the When screen

    /// Returns the CTA element once it exists, or fails the test. The CTA (`when.cta`) is the most
    /// reliable sentinel for the When screen being live and ready — it is always present (unlike the
    /// destination screen which hides the CTA during search mode).
    private func waitForWhenScreen(in app: XCUIApplication, scenario: String = "") -> XCUIElement {
        let cta = app.buttons["when.cta"]
        let tag = scenario.isEmpty ? "" : "[\(scenario)] "
        XCTAssertTrue(
            cta.waitForExistence(timeout: 8),
            "\(tag)when.cta must exist — UITEST_START_STEP=when must land on the When step"
        )
        return cta
    }

    // MARK: - testInitialStateAcrossScenarios
    //
    // Table-driven: for each scenario (A and C), assert the When screen is live with the expected
    // structural ids: month menu present, both precision segments present, CTA present and enabled,
    // and the exact-date pickers absent (default precision is justMonth).
    //
    // onboardingA and onboardingC are covered because the When step is structurally identical for
    // both — the ctaTitle is always "Continue", the same month menu and precision selector render,
    // and fixedDays defaults to 4 in both seeds.

    func testInitialStateAcrossScenarios() throws {
        let scenarios = ["onboardingA", "onboardingC"]

        for scenario in scenarios {
            let app = makeLaunchedApp(scenario: scenario)
            defer { app.terminate() }

            // ── Sentinel: CTA must be present ──
            let cta = waitForWhenScreen(in: app, scenario: scenario)
            XCTAssertTrue(
                cta.isEnabled,
                "[\(scenario)] when.cta must be enabled — the When step always allows advancing"
            )

            // ── Month menu must be present ──
            let monthMenu = app.buttons["when.month"]
            XCTAssertTrue(
                monthMenu.waitForExistence(timeout: 4),
                "[\(scenario)] when.month must exist — the month Menu is always rendered on the When step"
            )

            // ── Both precision segments must be present ──
            let justMonthSegment = app.buttons["when.precision.justMonth"]
            XCTAssertTrue(
                justMonthSegment.waitForExistence(timeout: 4),
                "[\(scenario)] when.precision.justMonth must exist — justMonth segment renders for all scenarios"
            )

            let exactDatesSegment = app.buttons["when.precision.exactDates"]
            XCTAssertTrue(
                exactDatesSegment.waitForExistence(timeout: 4),
                "[\(scenario)] when.precision.exactDates must exist — exactDates segment renders for all scenarios"
            )

            // ── Default precision is justMonth → exact-date pickers must NOT exist ──
            // TripWhen.seedDefault has precision = .justMonth (TripWhen.swift line 50).
            // DatePicker elements are only rendered inside the `if p.datePrecision == .exactDates` branch
            // (WhenStepView.swift line 84) so they must be absent in the default state.
            let startPicker = app.datePickers["when.start"]
            XCTAssertFalse(
                startPicker.exists,
                "[\(scenario)] when.start must NOT exist when precision is justMonth (default)"
            )
            let endPicker = app.datePickers["when.end"]
            XCTAssertFalse(
                endPicker.exists,
                "[\(scenario)] when.end must NOT exist when precision is justMonth (default)"
            )

            // ── Progress bar and back button sanity checks ──
            let progress = app.otherElements["onboarding.progress"]
            XCTAssertTrue(
                progress.waitForExistence(timeout: 3),
                "[\(scenario)] onboarding.progress must exist on the When step"
            )
            let backButton = app.buttons["onboarding.back"]
            XCTAssertTrue(
                backButton.waitForExistence(timeout: 3),
                "[\(scenario)] onboarding.back must exist on the When step"
            )

            // Attach screenshot of initial state — triage aid for CI, never pixel-diffed (§7.5).
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "when-initial-justMonth-\(scenario)"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }

    // MARK: - testPrecisionToggleRevealsAndHidesDatePickers
    //
    // Verifies the full precision-toggle lifecycle:
    //   1. Default state: precision is justMonth → when.start and when.end do not exist.
    //   2. Tap when.precision.exactDates → the exactDates branch renders → when.start and when.end appear.
    //   3. Tap when.precision.justMonth → the branch collapses → when.start and when.end disappear.
    //
    // This drives onboardingA only — the toggle mechanics are identical across A and C (both seed
    // precision = .justMonth from TripWhen.seedDefault). The table in testInitialStateAcrossScenarios
    // already confirms the initial absent-picker state for both scenarios.

    func testPrecisionToggleRevealsAndHidesDatePickers() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForWhenScreen(in: app)

        // ── 1. Confirm justMonth is the default — pickers absent ──
        let startPicker = app.datePickers["when.start"]
        let endPicker = app.datePickers["when.end"]
        XCTAssertFalse(
            startPicker.exists,
            "when.start must not exist before toggling to exactDates"
        )
        XCTAssertFalse(
            endPicker.exists,
            "when.end must not exist before toggling to exactDates"
        )

        let preToggleShot = XCTAttachment(screenshot: app.screenshot())
        preToggleShot.name = "when-pre-toggle-justMonth"
        preToggleShot.lifetime = .keepAlways
        add(preToggleShot)

        // ── 2. Tap exactDates segment → pickers must appear ──
        // SegmentedSelector renders each option as a Button with id `when.precision.<rawValue>`.
        // Tapping calls onSelect → store.onboarding?.setDatePrecision(.exactDates) →
        // p.datePrecision becomes .exactDates → exactDates(_:) branch renders the two DatePickers.
        let exactDatesSegment = app.buttons["when.precision.exactDates"]
        XCTAssertTrue(
            exactDatesSegment.waitForExistence(timeout: 4),
            "when.precision.exactDates must exist and be tappable"
        )
        XCTAssertTrue(exactDatesSegment.isHittable, "when.precision.exactDates must be hittable")
        exactDatesSegment.tap()

        // DatePickers are rendered inside `if p.datePrecision == .exactDates` (WhenStepView.swift line 84).
        // After the tap, the branch should render synchronously via SwiftUI's state update.
        XCTAssertTrue(
            startPicker.waitForExistence(timeout: 5),
            "when.start must appear after tapping when.precision.exactDates"
        )
        XCTAssertTrue(
            endPicker.waitForExistence(timeout: 5),
            "when.end must appear after tapping when.precision.exactDates"
        )

        let exactDatesShot = XCTAttachment(screenshot: app.screenshot())
        exactDatesShot.name = "when-exactDates-pickers-visible"
        exactDatesShot.lifetime = .keepAlways
        add(exactDatesShot)

        // ── 3. Tap justMonth segment → pickers must disappear ──
        // The tap calls setDatePrecision(.justMonth) → branch collapses → DatePickers removed from tree.
        let justMonthSegment = app.buttons["when.precision.justMonth"]
        XCTAssertTrue(justMonthSegment.isHittable, "when.precision.justMonth must be hittable after exactDates was selected")
        justMonthSegment.tap()

        XCTAssertTrue(
            startPicker.waitForNonExistence(timeout: 5),
            "when.start must disappear after tapping when.precision.justMonth"
        )
        XCTAssertTrue(
            endPicker.waitForNonExistence(timeout: 5),
            "when.end must disappear after tapping when.precision.justMonth"
        )

        // CTA must still be present and enabled after both toggle directions.
        XCTAssertTrue(cta.exists, "when.cta must remain present after precision toggle round-trip")
        XCTAssertTrue(cta.isEnabled, "when.cta must remain enabled after precision toggle round-trip")

        let postToggleShot = XCTAttachment(screenshot: app.screenshot())
        postToggleShot.name = "when-post-toggle-justMonth-restored"
        postToggleShot.lifetime = .keepAlways
        add(postToggleShot)
    }

    // MARK: - testCTAIsHittableAndAdvancesStep
    //
    // Verifies that when.cta is hittable and tapping it advances the onboarding flow off the When step.
    // After advancing, the next step (BaseLocation) renders and when.month is no longer on screen.
    // This is a soft check — if the next step's scaffold takes longer than the timeout, we accept
    // the absence of when.month as the signal (the When step always advances; the next screen's exact
    // id is outside this test's scope). Runs for onboardingA only (the flow advance mechanic is
    // scenario-independent).

    func testCTAIsHittableAndAdvancesStep() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")
        let cta = waitForWhenScreen(in: app)

        // ── CTA is hittable ──
        XCTAssertTrue(cta.isHittable, "when.cta must be hittable — it must be in the viewport and interactive")

        let preCtaShot = XCTAttachment(screenshot: app.screenshot())
        preCtaShot.name = "when-cta-hittable"
        preCtaShot.lifetime = .keepAlways
        add(preCtaShot)

        // ── Tap the CTA — store.advanceOnboardingStep() fires ──
        // WhenStepView.swift line 25: primaryAction: { store.advanceOnboardingStep() }
        // After advancing, the When step is replaced by the next step and when.month leaves the tree.
        cta.tap()

        // Soft advancement check: when.month must no longer exist after the step advances.
        // We use waitForNonExistence rather than asserting the next step's id (that's BaseLocation's test).
        let monthMenu = app.buttons["when.month"]
        XCTAssertTrue(
            monthMenu.waitForNonExistence(timeout: 8),
            "when.month must disappear after tapping when.cta — the When step must have been left"
        )

        let postCtaShot = XCTAttachment(screenshot: app.screenshot())
        postCtaShot.name = "when-after-cta-tap-step-advanced"
        postCtaShot.lifetime = .keepAlways
        add(postCtaShot)
    }

    // MARK: - testAccessibilityAudit
    //
    // Runs the BROAD audit (Apple's mechanism — `performAccessibilityAudit` with an `issueHandler`, not a
    // narrowed `for:` set, so new audit types are never silently dropped) and suppresses only documented
    // issues. Policy mirrors OnboardingDestinationUITests.testAccessibilityAudit:
    //
    //   • .dynamicType — the audit reads UIKit's adjustsFontForContentSizeCategory, which SwiftUI's
    //     Font.custom(relativeTo:) / Font.system(.style) don't surface; the text DOES scale (Typography.swift
    //     binds every role to a Dynamic Type style, zero fixedSize). The durable lock is an AX5 render
    //     snapshot (task §10), not this audit.
    //   • .contrast  — the audit pixel-samples and mis-reads backgrounds over glass / scroll / the OKLCH
    //     ramp (it flags the system .glassProminent CTA and custom ink-on-surface, which pass). The
    //     receded-ink contrast call is a design-doc decision, not an XCUITest assertion.
    //   • .textClipped — the month Menu label grows dynamically (no fixed frame); known FP on layout-driven
    //     elements where the audit can mis-read transient clipping.
    //   • .hitRegion on onboarding.progress — the progress bar is informational, not an interaction target.
    //
    // Every other type/element hard-fails (return false). A blanket-suppressed or bare audit is a bug (§7.9).
    // See docs/decisions.md (this date).

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "onboardingA")

        let cta = app.buttons["when.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "when.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "when-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass / dynamic Menu).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]
        try app.performAccessibilityAudit { issue in
            // Suppress the documented unreliable types for this design system.
            if suppressedTypes.contains(issue.auditType) { return true }
            // Informational progress bar isn't an interaction target → its .hitRegion flag is expected.
            if issue.element?.identifier == "onboarding.progress" && issue.auditType == .hitRegion { return true }
            // All other issues hard-fail.
            return false
        }
    }
}
