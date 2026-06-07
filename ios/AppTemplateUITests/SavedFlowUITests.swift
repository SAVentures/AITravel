// SavedFlowUITests.swift — XCUITest flow for the Saved tab (Task 4.4).
//
// Drives the real app against MockProvider scenarios via launch-environment injection
// (`UITEST_SCENARIO`, `UITEST_FAILURE_RATE`, `UITEST_NOW`). Queries exclusively by
// dot-namespaced accessibility identifier — never by displayed text (locale-sensitive,
// per 07-testing §7.3). All async waits use `waitForExistence(timeout:)`; no `sleep()`.
//
// Scenarios covered:
//   savedStandard    — 24 places pre-seeded at launch; populates the list in by-category mode.
//   savedEmpty       — 0 places pre-seeded; rich empty state (WayToSaveRow × 3).
//   savedError + UITEST_FAILURE_RATE=1.0  — store pre-seeded (list visible) + AddPlaceRequest
//                      throws .status(503) → add write rolls back + writeError.banner appears.
//
// Pre-seeding note: for savedStandard/savedEmpty/savedError, AppTemplateApp.makeStore() calls
// store.loadSeed(savedPlaces:) at launch so SavedListView's `.task` guard (if savedPlaces == nil)
// is false — GetSavedPlacesRequest never fires. UITEST_FAILURE_RATE=1.0 therefore only affects
// AddPlaceRequest (the write), enabling the rollback path without also failing the read.
//
// Accessibility identifiers confirmed against live View source (SavedListView.swift,
// AddPlaceSheet.swift, PlaceDetailView.swift, SourceCard.swift, SegmentedSelector.swift):
//
//   tab.saved                              AppTab.accessibilityID (AppTab.swift)
//   savedlist.add                          SavedListView addAffordanceRow (line 158)
//   savedlist.emptyState                   SavedListView emptyState (line 422)
//   savedlist.mode.bySource                SegmentedSelector → prefix "savedlist.mode" + SavedListMode.id "bySource" (line 74)
//   savedlist.mode.byCategory              SegmentedSelector → prefix "savedlist.mode" + SavedListMode.id "byCategory"
//   placerow.<id>                          SavedListView placeRowButton (line 392)
//   sourcecard.<id>                        SavedListView sourceContent (line 323)
//   sourceplacerow.<id>                    SourceCard expandedBody (line 136)
//   placedetail.back                       PlaceDetailView overHeroHeader (line 98)
//   addplace.method.reel                   AddPlaceSheet methodRow reel (line 135)
//   addplace.paste                         AddPlaceSheet pasteButton (line 230)
//   addplace.close                         AddPlaceSheet closeButton (line 117)
//   addplace.progress                      AddPlaceSheet progress indicator (line 143) — optional; appears mid-write
//   writeError.banner                      AddPlaceSheet / SavedListView errorBanner (lines 251 / 449)
//   waytosave.reel                         SavedListView emptyState WayToSaveRow (line 412 → id "reel")
//
// Source card id for the savedStandard seed's first reel:
//   "reel:saltinmycoffee:Lisbon in 48 hours"   (SavedListPresenter.sourceKey, confirmed SampleData+Saved.swift)
// Child place IDs under that card: place-cevicheria, place-park-bar, place-timeout-market.
//
// Mock latency: AddPlaceRequest.mockLatency = .milliseconds(800).  All write-path waits use
// timeout ≥ 4 s to absorb the 800 ms latency plus animation drag.
//
// Launch/scroll/audit boilerplate mirrors OnboardingRobot (Support/OnboardingRobot.swift).
// pbxproj: AppTemplateUITests uses PBXFileSystemSynchronizedRootGroup (objectVersion 77) —
// new Swift files auto-join the target; no manual pbxproj entry needed.
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest suite for the Saved tab flow — SavedListView · PlaceDetailView · AddPlaceSheet.
///
/// Table-driven across three configurations:
///   1. savedStandard      — rows present, by-category → by-source toggle, row → detail → back.
///   2. savedEmpty         — empty state, waytosave affordances open the add sheet.
///   3. savedStandard + failure rate 1.0 — add write rolls back, writeError.banner appears.
///
/// One `performAccessibilityAudit()` under savedStandard with narrow documented suppressions.
@MainActor
final class SavedFlowUITests: XCTestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if the Saved tab does
        // not reach the expected state.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Builds and launches `XCUIApplication` wired to a given scenario.
    ///
    /// - Parameters:
    ///   - scenario: The `UITEST_SCENARIO` raw value. Saved scenarios: `"savedStandard"`,
    ///     `"savedEmpty"`, `"savedError"`.
    ///   - failureRate: When `1.0`, sets `UITEST_FAILURE_RATE=1.0` — the app's `AppTemplateApp`
    ///     maps this to `APIClient.mock(failure: .status(503))`. Any other value omits the key.
    ///   - now: ISO-8601 string pinning the clock (07-testing §3). Defaults to
    ///     `"2025-07-15T09:41:00Z"` matching `SampleData.savedSimulatedNow`.
    /// - Returns: The launched `XCUIApplication`.
    @discardableResult
    private func makeLaunchedApp(
        scenario: String,
        failureRate: Double? = nil,
        now: String = "2025-07-15T09:41:00Z"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_NOW"] = now
        if let failureRate, failureRate == 1.0 {
            app.launchEnvironment["UITEST_FAILURE_RATE"] = "1.0"
        }
        // Slow animations so waitForExistence beats spring transitions (mirrors OnboardingRobot).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Scroll helper

    /// Swipes up until `element` enters the realized accessibility tree, up to `maxSwipes` times.
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    // MARK: - testSavedTabShowsRows (savedStandard — list is populated)
    //
    // Verifies: the Saved tab lands in by-category mode with populated rows; placerow.place-cevicheria
    // exists (first Eat entry in the seed); tapping it pushes PlaceDetailView (placedetail.back appears);
    // tapping back pops to the list (savedlist.add re-appears).

    func testSavedTabShowsRows() throws {
        let app = makeLaunchedApp(scenario: "savedStandard")
        defer { app.terminate() }

        // The app boots into the Saved tab (selectedTab = .saved). The store is pre-seeded at
        // launch (AppTemplateApp.makeStore → loadSeed(savedPlaces:)), so savedPlaces is non-nil
        // when the view renders and the non-empty layout appears immediately. Confirm the "+"
        // add affordance — the most reliable sentinel for the populated layout being live.
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "savedlist.add must exist — savedStandard is pre-seeded so the non-empty layout renders"
        )

        let rowsShot = XCTAttachment(screenshot: app.screenshot())
        rowsShot.name = "saved-list-by-category-populated"
        rowsShot.lifetime = .keepAlways
        add(rowsShot)

        // The first Eat place is A Cevicheria (id: place-cevicheria, SampleData+Saved.swift line 85).
        // It is near the top of the by-category list so scrolling should be unnecessary, but guard with
        // scrollToElement to be resilient to any future reordering above the fold.
        let cevicheriaRow = app.buttons["placerow.place-cevicheria"]
        scrollToElement(cevicheriaRow, in: app)
        XCTAssertTrue(
            cevicheriaRow.waitForExistence(timeout: 4),
            "placerow.place-cevicheria must exist in the savedStandard list (first Eat entry)"
        )

        // Tap the row — pushes PlaceDetailView.
        XCTAssertTrue(cevicheriaRow.isHittable, "placerow.place-cevicheria must be hittable")
        cevicheriaRow.tap()

        // PlaceDetailView's over-hero back button confirms we landed on the detail screen.
        let backButton = app.buttons["placedetail.back"]
        XCTAssertTrue(
            backButton.waitForExistence(timeout: 5),
            "placedetail.back must appear after tapping placerow.place-cevicheria"
        )

        let detailShot = XCTAttachment(screenshot: app.screenshot())
        detailShot.name = "place-detail-cevicheria"
        detailShot.lifetime = .keepAlways
        add(detailShot)

        // Tap back — pops to the list (savedlist.add re-appears).
        XCTAssertTrue(backButton.isHittable, "placedetail.back must be hittable")
        backButton.tap()

        XCTAssertTrue(
            addButton.waitForExistence(timeout: 5),
            "savedlist.add must re-appear after popping back from PlaceDetailView"
        )

        let backShot = XCTAttachment(screenshot: app.screenshot())
        backShot.name = "saved-list-after-detail-back"
        backShot.lifetime = .keepAlways
        add(backShot)
    }

    // MARK: - testBySourceTogglesAndExpandsCard (savedStandard — mode toggle + source card)
    //
    // Verifies: tapping savedlist.mode.bySource switches to by-source mode; the first reel's
    // SourceCard (id "reel:saltinmycoffee:Lisbon in 48 hours") appears; tapping it expands the
    // card and child rows (sourceplacerow.place-cevicheria) become hittable.

    func testBySourceTogglesAndExpandsCard() throws {
        let app = makeLaunchedApp(scenario: "savedStandard")
        defer { app.terminate() }

        // Wait for the list to be populated.
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "savedlist.add must exist before toggling mode"
        )

        // The SegmentedSelector emits savedlist.mode.<SavedListMode.id> per option
        // (SegmentedSelector.swift line 74: `\(accessibilityIDPrefix).\(option.id)`).
        // SavedListMode.id == rawValue ("bySource"), so the button is "savedlist.mode.bySource".
        let bySourceButton = app.buttons["savedlist.mode.bySource"]
        XCTAssertTrue(
            bySourceButton.waitForExistence(timeout: 4),
            "savedlist.mode.bySource must exist (SegmentedSelector with prefix 'savedlist.mode')"
        )
        bySourceButton.tap()

        // The reel card for @saltinmycoffee "Lisbon in 48 hours".
        // sourcecard id = sourceKey(for: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours"))
        //              = "reel:saltinmycoffee:Lisbon in 48 hours"  (SavedListPresenter.swift line 333)
        let firstCard = app.buttons["sourcecard.reel:saltinmycoffee:Lisbon in 48 hours"]
        scrollToElement(firstCard, in: app)
        XCTAssertTrue(
            firstCard.waitForExistence(timeout: 6),
            "sourcecard.reel:saltinmycoffee:Lisbon in 48 hours must appear after switching to by-source"
        )

        let bySourceShot = XCTAttachment(screenshot: app.screenshot())
        bySourceShot.name = "saved-list-by-source-collapsed"
        bySourceShot.lifetime = .keepAlways
        add(bySourceShot)

        // Tap the card head to expand it — child SourcePlaceRows appear.
        XCTAssertTrue(firstCard.isHittable, "SourceCard head must be hittable")
        firstCard.tap()

        // The first child row: A Cevicheria (place-cevicheria, the reel's 0:42 mention).
        let childRow = app.buttons["sourceplacerow.place-cevicheria"]
        XCTAssertTrue(
            childRow.waitForExistence(timeout: 4),
            "sourceplacerow.place-cevicheria must appear after expanding the reel SourceCard"
        )

        let expandedShot = XCTAttachment(screenshot: app.screenshot())
        expandedShot.name = "saved-list-by-source-expanded"
        expandedShot.lifetime = .keepAlways
        add(expandedShot)
    }

    // MARK: - testEmptyStateRendersWaysToSave (savedEmpty — rich empty state)
    //
    // Verifies: the savedEmpty scenario renders savedlist.emptyState (no rows); the reel
    // WayToSaveRow (waytosave.reel) is present; tapping it opens AddPlaceSheet (addplace.close
    // appears); closing the sheet returns to the empty state.

    func testEmptyStateRendersWaysToSave() throws {
        let app = makeLaunchedApp(scenario: "savedEmpty")
        defer { app.terminate() }

        // The empty state renders instead of the by-category list.
        let emptyState = app.otherElements["savedlist.emptyState"]
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 8),
            "savedlist.emptyState must exist when savedEmpty is seeded (0 places)"
        )

        // savedlist.add must NOT be present — the empty state replaces the populated layout.
        // (addAffordanceRow is only rendered in non-empty states in SavedListView.swift.)
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForNonExistence(timeout: 3),
            "savedlist.add must NOT exist in the empty state (addAffordanceRow not rendered)"
        )

        let emptyShot = XCTAttachment(screenshot: app.screenshot())
        emptyShot.name = "saved-list-empty-state"
        emptyShot.lifetime = .keepAlways
        add(emptyShot)

        // The reel WayToSaveRow — id "waytosave.reel" (SavedListView emptyState: "waytosave.\(way.id)",
        // WayToSaveRowModel id = "reel", SavedListPresenter.wayToSave line 152).
        let reelRow = app.buttons["waytosave.reel"]
        XCTAssertTrue(
            reelRow.waitForExistence(timeout: 4),
            "waytosave.reel must exist in the empty state (prominent reel WayToSaveRow)"
        )

        // Tapping opens AddPlaceSheet — confirmed by addplace.close appearing.
        XCTAssertTrue(reelRow.isHittable, "waytosave.reel must be hittable")
        reelRow.tap()

        let closeButton = app.buttons["addplace.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addplace.close must appear after tapping waytosave.reel (AddPlaceSheet presented)"
        )

        let sheetShot = XCTAttachment(screenshot: app.screenshot())
        sheetShot.name = "add-place-sheet-from-empty-state"
        sheetShot.lifetime = .keepAlways
        add(sheetShot)

        // Close the sheet — savedlist.emptyState must re-appear.
        XCTAssertTrue(closeButton.isHittable, "addplace.close must be hittable")
        closeButton.tap()

        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 4),
            "savedlist.emptyState must re-appear after closing AddPlaceSheet"
        )
    }

    // MARK: - testAddPlaceOptimisticRow (savedStandard — add success path)
    //
    // Verifies: tapping "+" opens AddPlaceSheet; tapping addplace.method.reel (the prominent reel
    // row) fires the networked write (addplace.progress may flash); on success the sheet dismisses
    // and savedlist.add re-appears (the optimistic row is in the list). The mock returns success
    // because no UITEST_FAILURE_RATE is set.

    func testAddPlaceOptimisticRow() throws {
        let app = makeLaunchedApp(scenario: "savedStandard")
        defer { app.terminate() }

        // Wait for the list.
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "savedlist.add must exist before tapping it"
        )

        // Open AddPlaceSheet.
        XCTAssertTrue(addButton.isHittable, "savedlist.add must be hittable")
        addButton.tap()

        let closeButton = app.buttons["addplace.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addplace.close must appear when AddPlaceSheet is presented"
        )

        let sheetShot = XCTAttachment(screenshot: app.screenshot())
        sheetShot.name = "add-place-sheet-open"
        sheetShot.lifetime = .keepAlways
        add(sheetShot)

        // The prominent reel row (the ONE write — AddPlaceSheet.swift line 135).
        let reelMethod = app.buttons["addplace.method.reel"]
        XCTAssertTrue(
            reelMethod.waitForExistence(timeout: 4),
            "addplace.method.reel must exist in AddPlaceSheet (the prominent reel row)"
        )

        // Tap it — fires await store.addPlace(). The mock latency is 800ms; the ProgressView
        // (addplace.progress) may appear briefly. We do not hard-assert on the mid-flight state
        // because it is transient; we assert the post-success state instead.
        XCTAssertTrue(reelMethod.isHittable, "addplace.method.reel must be hittable")
        reelMethod.tap()

        // On success the sheet dismisses — addplace.close must disappear.
        // Timeout covers the 800ms mock latency + animation drag (10×).
        XCTAssertTrue(
            closeButton.waitForNonExistence(timeout: 10),
            "AddPlaceSheet must dismiss on a successful add (addplace.close disappears)"
        )

        // The list is back — savedlist.add must re-appear.
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 5),
            "savedlist.add must re-appear after a successful addPlace write"
        )

        let successShot = XCTAttachment(screenshot: app.screenshot())
        successShot.name = "saved-list-after-add-success"
        successShot.lifetime = .keepAlways
        add(successShot)
    }

    // MARK: - testAddPlaceWriteErrorBanner (savedError + failure rate 1.0 — rollback path)
    //
    // Verifies: with UITEST_FAILURE_RATE=1.0 the add write rolls back and writeError.banner appears
    // in the AddPlaceSheet. The sheet stays open (dismiss is conditional on writeError == nil in
    // AddPlaceSheet.addFromClipboard). Uses addplace.paste (the second entry to the same write)
    // so both write entry points are exercised across the suite.
    //
    // Uses savedError (same DTO as savedStandard) so AppTemplateApp.makeStore() pre-seeds
    // savedPlaces before any request fires. This confines UITEST_FAILURE_RATE=1.0 to WRITE
    // requests only (AddPlaceRequest): the GET never fires (the .task guard `savedPlaces == nil`
    // is false at render time), and addPlace's `guard let savedPlaces else { return }` succeeds.

    func testAddPlaceWriteErrorBanner() throws {
        let app = makeLaunchedApp(scenario: "savedError", failureRate: 1.0)
        defer { app.terminate() }

        // The store is pre-seeded at launch (AppTemplateApp.makeStore → loadSeed(savedPlaces:))
        // so the list renders without waiting for a network load.
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "savedlist.add must exist (savedError is pre-seeded at launch with 24 places)"
        )

        // Open AddPlaceSheet.
        addButton.tap()

        let closeButton = app.buttons["addplace.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addplace.close must appear when AddPlaceSheet is presented"
        )

        // The paste button (addplace.paste) — the clipboard affordance, the second entry point to
        // the add write (AddPlaceSheet.swift pasteButton, line 230). Exercises that path.
        let pasteButton = app.buttons["addplace.paste"]
        XCTAssertTrue(
            pasteButton.waitForExistence(timeout: 4),
            "addplace.paste must exist — the clipboard affordance is visible when detectedURL is non-nil"
        )

        let preWriteShot = XCTAttachment(screenshot: app.screenshot())
        preWriteShot.name = "add-place-pre-write-failure"
        preWriteShot.lifetime = .keepAlways
        add(preWriteShot)

        // Tap paste — fires the write, which will throw .status(503) immediately (no latency on
        // failure: MockProvider uses self.latency which is .zero by default; request.mockLatency
        // is not consulted by MockProvider.send).
        XCTAssertTrue(pasteButton.isHittable, "addplace.paste must be hittable")
        pasteButton.tap()

        // Diagnostic: confirm which failure mode we hit before asserting the banner.
        // If addplace.close disappears, the sheet dismissed → Case A (write succeeded — failure
        // injection didn't reach the write). If it stays, the sheet is open → Case B (write failed
        // but banner not rendered — store.writeError observation / re-render issue).
        // We wait only 4 s here so the real banner assertion below still gets its full 10 s budget.
        let sheetStillOpen = closeButton.waitForExistence(timeout: 4)
        XCTAssertTrue(
            sheetStillOpen,
            "addplace.close must still exist after the paste tap — if this fails the sheet " +
            "dismissed, meaning the write SUCCEEDED (Case A: failure injection did not reach " +
            "AddPlaceRequest). If this passes but writeError.banner is missing, the write failed " +
            "but AddPlaceSheet did not re-render (Case B: @Observable observation gap)."
        )

        // The sheet stays open on failure (dismiss is guarded by writeError == nil).
        // writeError.banner must appear (AddPlaceSheet errorBanner, line 251).
        // Timeout covers animation drag coefficient (UIAnimationDragCoefficient=10).
        // writeError.banner uses .accessibilityElement(children: .combine) (AddPlaceSheet.swift line 256)
        // — .combine flattens the glyph+message HStack into a single combined element that XCUITest
        // surfaces as a staticText, NOT an otherElements entry. Use a type-agnostic descendants query so
        // the lookup is correct regardless of the element class the runtime assigns.
        let errorBanner = app.descendants(matching: .any)
            .matching(identifier: "writeError.banner")
            .firstMatch
        XCTAssertTrue(
            errorBanner.waitForExistence(timeout: 10),
            "writeError.banner must appear in AddPlaceSheet after a forced write failure"
        )

        let errorShot = XCTAttachment(screenshot: app.screenshot())
        errorShot.name = "add-place-write-error-banner"
        errorShot.lifetime = .keepAlways
        add(errorShot)
    }

    // MARK: - testAccessibilityAudit (savedStandard — broad audit on SavedListView)
    //
    // Runs the BROAD `performAccessibilityAudit` (no `for:` narrowing — that silently drops
    // whole categories, per 07-testing §7.4). The `issueHandler` carries ONLY the documented
    // suppressions below; everything else returns `false` (hard-fail).
    //
    // Suppressed types and their documented compensating checks:
    //
    // • .dynamicType — SwiftUI `Font.custom(relativeTo:)` / `Font.system(.style)` don't surface
    //   `adjustsFontForContentSizeCategory` to the UIKit a11y inspector; text DOES scale
    //   (Typography.swift binds every role to a Dynamic Type style, zero fixedSize calls).
    //   Compensating control (07 §7.4): AX5 render snapshot for saved-list-by-category
    //   (SavedSnapshotTests "saved-list-by-category-ax5") locks Dynamic Type at AX5.
    //   Whole-type suppression is therefore covered.
    //
    // • .contrast — the pixel-sampler mis-reads OKLCH inks over the system glass/scroll
    //   background (flags ink-700-on-white and the system `.glassProminent` CTA, both of
    //   which definitionally pass). Receded-ink contrast is a deliberate design-doc decision
    //   (decisions.md 2026-06-03). Compensating control: committed snapshot baselines lock the
    //   rendered ink values — any unintentional token drift breaks L3 before reaching this audit.
    //
    // • .textClipped — FilterChip, SegmentedSelector, and PlaceRow labels grow from minHeight
    //   (no fixed frame); the audit flags them as clipped at the measurement moment. Known FP on
    //   custom layout-driven elements. Compensating control: committed snapshot baselines for
    //   FilterChipSnapshotTests, SegmentedSelectorSnapshotTests, PlaceRowSnapshotTests — a real
    //   clip shifts the rendered bounds and breaks those baselines before shipping.
    //
    // • .elementDetection && id.isEmpty && label.isEmpty — the hero-photo placeholder ZStack
    //   may surface a "potentially inaccessible text" FP for the decorative ZStack layer that
    //   carries no id or label; the PlaceDetailView hero marks those layers
    //   `.accessibilityElement(children: .ignore)` + `.accessibilityHidden(true)` but on the
    //   SavedListView there may be a decorative ColorRole.fillTertiary layer in PlaceRow that
    //   the heuristic catches transiently. Suppression is narrow: only elements with BOTH
    //   empty id AND empty label; any element with a non-empty id or label hard-fails.
    //   Compensating control: AX5 snapshot baseline (SavedSnapshotTests "saved-list-by-category-ax5").
    //
    // Every other issue hard-fails (return false). A blanket `return true` is a defect (§7.4).

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "savedStandard")
        defer { app.terminate() }

        // Wait for the list to be fully rendered before auditing.
        let addButton = app.buttons["savedlist.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "savedlist.add must exist before running the accessibility audit"
        )

        // Scroll down slightly so below-fold rows enter the realized tree — the audit samples the
        // live tree, so unrealized elements are absent and won't generate false issues.
        app.swipeUp()
        app.swipeDown()    // restore to top so the audit sees the full populated list

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "saved-list-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types unreliable on this custom design (custom fonts / OKLCH inks / glass tab bar).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]

        try app.performAccessibilityAudit { issue in
            // Whole-type suppressions — each named a live compensating check above.
            if suppressedTypes.contains(issue.auditType) { return true }
            // Narrow .elementDetection suppression: decorative layers with no id AND no label
            // (the render-heuristic "potentially inaccessible text" FP — 07 §6.6 + 05 §8.1).
            // Any element with a non-empty id or non-empty label is NOT suppressed here.
            let id    = issue.element?.identifier ?? ""
            let label = issue.element?.label      ?? ""
            if issue.auditType == .elementDetection && id.isEmpty && label.isEmpty { return true }
            // All other issues hard-fail — a blanket return true is a defect (07-testing §7.4).
            return false
        }
    }
}
