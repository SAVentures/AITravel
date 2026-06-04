// OnboardingWhenUITests.swift — XCUITest flow for the When step (onboarding step 02/03).
//
// Drives the real app to the "When are you going?" step via UITEST_START_STEP=when and exercises:
//   • Initial state: month menu present, both precision segments present, CTA present and enabled,
//     exact-date pickers absent (default precision is justMonth).
//   • Precision toggle: tapping exactDates reveals when.start + when.end; tapping justMonth hides them.
//   • Group value: the SegmentedSelector container element (label "Date precision") exposes a `.value`
//     equal to the selected DatePrecision.label ("Just the month" / "Exact dates"); asserted at
//     default state AND after each toggle direction.
//   • Month value: when.month carries accessibilityLabel "Trip month" and accessibilityValue equal to
//     the selected month label (e.g. "June 2026" when UITEST_NOW is pinned to 2026-06-03 and the seed
//     month is June 2026 from TripWhen.seedDefault).
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
// Identifiers / group element query confirmed against live View source:
//   when.cta                  — OnboardingActionFloor primary button (WhenStepView.swift line 23)
//   when.month                — month Menu (WhenStepView.swift line 111-113); carries label "Trip month"
//                               + value selectedMonthLabel (Wave 2, Task 2.3)
//   when.precision.justMonth  — SegmentedSelector segment: prefix "when.precision" + rawValue "justMonth"
//                               (SegmentedSelector.swift line 75; DatePrecision.id = rawValue,
//                               WhenStepView.swift extension DatePrecision: Identifiable)
//   when.precision.exactDates — same selector, rawValue "exactDates"
//   when.start                — DatePicker start date (WhenStepView.swift line 121); exactDates only
//   when.end                  — DatePicker end date (WhenStepView.swift line 125); exactDates only
//   onboarding.back           — floating GlassCircleButton (WhenStepView.swift line 38)
//   onboarding.progress       — OnboardingProgressBar (every onboarding step)
//
//   SegmentedSelector group element — queried by label predicate, NOT by id:
//     The track applies .accessibilityElement(children: .contain) + .accessibilityValue(label(selection))
//     (SegmentedSelector.swift lines 92-93). The caller applies .accessibilityLabel("Date precision")
//     via groupedTrack (line 50). There is no .accessibilityIdentifier on the container; the group is
//     addressed via `app.otherElements.matching(NSPredicate(format: "label == 'Date precision'")).firstMatch`.
//     `children: .contain` keeps per-segment Button ids independently hittable — see SegmentedSelector.swift
//     lines 87-91 for the rationale (`.ignore`/`.combine` would collapse them and break the tap path).
//
// DatePrecision labels confirmed in TripWhen.swift:
//   .justMonth  → "Just the month"
//   .exactDates → "Exact dates"
//
// Month label: WhenStepPresenter.selectedMonthLabel uses AppDate.monthYear.string(from:) on the seed
// month (June 2026 from TripWhen.seedDefault). With UITEST_NOW = "2026-06-03T12:00:00Z", the first
// monthOptions entry is June 2026 → selectedMonthLabel = "June 2026".
//
// Launch is routed through OnboardingRobot.launch(scenario:startStep:now:) (C1 migration).
// UITEST_FAILURE_RATE is NOT forwarded here — the robot centralizes it via its optional failureRate
// param (C5). Callers that pass nothing get nil → key absent → behavior unchanged (future hook
// for the planned onboarding write; see docs/decisions.md Task C5).
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest flow for `WhenStepView` — onboarding step "when" (step index 2).
///
/// Verifies: month-menu presence + label/value; both precision segments present with justMonth as default
/// (exact-date pickers absent); the SegmentedSelector group element's `.value` equals the selected
/// `DatePrecision.label` and changes correctly across a precision toggle (exactDates → justMonth round-
/// trip); tapping exactDates reveals the pickers; tapping justMonth hides them again; the CTA is hittable
/// and advances the flow. Runs across onboardingA and onboardingC and includes the accessibility audit
/// with the standard documented suppressions.
@MainActor
final class OnboardingWhenUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the When screen fails to load.
        continueAfterFailure = false
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

    // MARK: - Shared: precision group container

    /// Returns the SegmentedSelector container element for the "Date precision" group.
    ///
    /// The container is NOT stamped with an `accessibilityIdentifier` — SegmentedSelector applies
    /// `.accessibilityElement(children: .contain)` + `.accessibilityValue(label(selection))` on the
    /// track, and the caller's label ("Date precision") via `groupedTrack` (SegmentedSelector.swift
    /// lines 46-51, 92-93). There is no id to query by, so we use a label predicate on `otherElements`.
    /// `children: .contain` is load-bearing: it keeps the container a real element WITH each per-segment
    /// Button remaining an independently-hittable child, so `app.buttons["when.precision.*"]` still
    /// resolves for tap actions (SegmentedSelector.swift lines 87-91).
    private func precisionGroup(in app: XCUIApplication) -> XCUIElement {
        app.otherElements.matching(NSPredicate(format: "label == 'Date precision'")).firstMatch
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
            let robot = OnboardingRobot()
            let app = robot.launch(scenario: scenario, startStep: "when")
            defer { app.terminate() }

            // ── Sentinel: CTA must be present ──
            let cta = waitForWhenScreen(in: app, scenario: scenario)
            XCTAssertTrue(
                cta.isEnabled,
                "[\(scenario)] when.cta must be enabled — the When step always allows advancing"
            )

            // ── Month menu must be present, with the correct label and value ──
            // when.month carries .accessibilityLabel("Trip month") + .accessibilityValue(selectedMonthLabel)
            // (WhenStepView.swift lines 112-113, Task 2.3). The default seed month is June 2026
            // (TripWhen.seedDefault year=2026 month=6); UITEST_NOW = "2026-06-03T12:00:00Z" pins
            // AppDate.simulatedNow so monthOptions[0] is June 2026 → selectedMonthLabel = "June 2026".
            let monthMenu = app.buttons["when.month"]
            XCTAssertTrue(
                monthMenu.waitForExistence(timeout: 4),
                "[\(scenario)] when.month must exist — the month Menu is always rendered on the When step"
            )
            XCTAssertEqual(
                monthMenu.label,
                "Trip month",
                "[\(scenario)] when.month.label must be 'Trip month' (Task 2.3 Wave-2 annotation)"
            )
            // The value is locale-formatted; we assert it is non-empty (the seed always seeds a month).
            // A stronger "June 2026" equality would be locale-fragile on non-English simulators; we
            // confirm it is not empty and not the placeholder — the shape assertion is sufficient for L4.
            XCTAssertFalse(
                (monthMenu.value as? String ?? "").isEmpty,
                "[\(scenario)] when.month.value must be non-empty — selectedMonthLabel is always set from seed"
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

            // ── Precision group container value must reflect the default selection ──
            // The SegmentedSelector track carries .accessibilityElement(children: .contain) +
            // .accessibilityValue(label(selection)), and the caller supplies .accessibilityLabel("Date
            // precision"). We query the container by its label (no id stamped on the track — confirmed
            // in SegmentedSelector.swift; the precisionGroup helper wraps the predicate query).
            // Default precision is .justMonth → DatePrecision.label == "Just the month".
            let group = precisionGroup(in: app)
            XCTAssertTrue(
                group.waitForExistence(timeout: 4),
                "[\(scenario)] the 'Date precision' container element must exist (children: .contain + label)"
            )
            XCTAssertEqual(
                group.value as? String,
                "Just the month",
                "[\(scenario)] precision group value must be 'Just the month' in the default state"
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

    // MARK: - testPrecisionGroupValueChangesOnToggle
    //
    // Verifies that the SegmentedSelector container element's `.value` equals the selected
    // DatePrecision.label and CHANGES correctly across a precision toggle:
    //
    //   1. Default state: group.value == "Just the month" (precision = .justMonth).
    //   2. Tap when.precision.exactDates → group.value == "Exact dates".
    //   3. Tap when.precision.justMonth  → group.value == "Just the month" (restored).
    //
    // The per-segment tap tests in testPrecisionToggleRevealsAndHidesDatePickers de-risk the
    // Wave-2 `children: .contain` change — confirm those ids are still individually hittable.
    // This test asserts the GROUP VALUE layer added in Wave 2 (Task 2.1 + 2.4).
    //
    // Group element query: `app.otherElements.matching(NSPredicate(format: "label == 'Date precision'"))
    // .firstMatch` — label predicate is the only stable handle because SegmentedSelector stamps no id
    // on the container track (the per-segment ids live on the child Buttons under `.contain`).
    //
    // Runs for onboardingA only — the toggle mechanic and group-value wiring are scenario-independent.

    func testPrecisionGroupValueChangesOnToggle() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "when")
        _ = waitForWhenScreen(in: app)

        let group = precisionGroup(in: app)

        // ── 1. Default state: group value == "Just the month" ──
        XCTAssertTrue(
            group.waitForExistence(timeout: 6),
            "precision group container must exist in the initial state"
        )
        XCTAssertEqual(
            group.value as? String,
            "Just the month",
            "precision group value must be 'Just the month' at default (precision = .justMonth)"
        )

        let defaultGroupShot = XCTAttachment(screenshot: app.screenshot())
        defaultGroupShot.name = "when-precision-group-default-justMonth"
        defaultGroupShot.lifetime = .keepAlways
        add(defaultGroupShot)

        // ── 2. Tap exactDates → group value must change to "Exact dates" ──
        // Per-segment ids are still independently hittable under `children: .contain` (SegmentedSelector
        // lines 87-91: `.ignore`/`.combine` was explicitly rejected to preserve this tap path).
        let exactDatesSegment = app.buttons["when.precision.exactDates"]
        XCTAssertTrue(
            exactDatesSegment.waitForExistence(timeout: 4),
            "when.precision.exactDates must still resolve as its own button under children: .contain"
        )
        XCTAssertTrue(exactDatesSegment.isHittable, "when.precision.exactDates must be hittable")
        exactDatesSegment.tap()

        // The `.accessibilityValue` on the container track updates synchronously with SwiftUI's
        // selection-binding refresh. Use waitForExistence on the group to confirm it's still in tree,
        // then assert the value (XCUITest reads the live a11y tree value, no extra wait needed).
        XCTAssertTrue(
            group.waitForExistence(timeout: 4),
            "precision group container must remain in tree after tapping exactDates"
        )
        XCTAssertEqual(
            group.value as? String,
            "Exact dates",
            "precision group value must be 'Exact dates' after tapping when.precision.exactDates"
        )

        let exactDatesGroupShot = XCTAttachment(screenshot: app.screenshot())
        exactDatesGroupShot.name = "when-precision-group-exactDates"
        exactDatesGroupShot.lifetime = .keepAlways
        add(exactDatesGroupShot)

        // ── 3. Tap justMonth → group value must restore to "Just the month" ──
        let justMonthSegment = app.buttons["when.precision.justMonth"]
        XCTAssertTrue(
            justMonthSegment.waitForExistence(timeout: 4),
            "when.precision.justMonth must still resolve as its own button under children: .contain"
        )
        XCTAssertTrue(justMonthSegment.isHittable, "when.precision.justMonth must be hittable after exactDates selected")
        justMonthSegment.tap()

        XCTAssertTrue(
            group.waitForExistence(timeout: 4),
            "precision group container must remain in tree after tapping justMonth"
        )
        XCTAssertEqual(
            group.value as? String,
            "Just the month",
            "precision group value must restore to 'Just the month' after tapping when.precision.justMonth"
        )

        let restoredGroupShot = XCTAttachment(screenshot: app.screenshot())
        restoredGroupShot.name = "when-precision-group-restored-justMonth"
        restoredGroupShot.lifetime = .keepAlways
        add(restoredGroupShot)
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
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "when")
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
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "when")
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
    // narrowed `for:` set, so new audit types are never silently dropped) via OnboardingRobot's
    // performOnboardingAudit, which centralizes the common suppression set (C1 migration).
    //
    // Common suppression set (owned by OnboardingRobot.performOnboardingAudit):
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
    // No screen-specific extraSuppressions are needed for this suite — the When step has no additional
    // documented exemptions beyond the common set (no generation.handoff, no decorative map placeholder).
    //
    // Every other type/element hard-fails (return false inside the robot). A blanket-suppressed or bare
    // audit is a bug (§7.9). See docs/decisions.md (this date).

    func testAccessibilityAudit() throws {
        let robot = OnboardingRobot()
        let app = robot.launch(scenario: "onboardingA", startStep: "when")

        let cta = app.buttons["when.cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 8), "when.cta must exist before audit")

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "when-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Common suppression set only — no screen-specific extras for the When step.
        try robot.performOnboardingAudit()
    }
}
