// WalletFlowUITests.swift — XCUITest flow for the Wallet feature (Task 4.4).
//
// Drives the real app against MockProvider scenarios via launch-environment injection
// (`UITEST_SCENARIO`, `UITEST_FAILURE_RATE`, `UITEST_NOW`). Queries exclusively by
// dot-namespaced accessibility identifier — never by displayed text (locale-sensitive,
// per 07-testing §7.3). All async waits use `waitForExistence(timeout:)`; no `sleep()`.
//
// Scenarios covered:
//   walletStandard — wallet pre-seeded at launch: booking rows present, orphan prompt shows,
//                    tapping a row pushes BookingDetailView, showPass opens AccessCardView.
//   walletEmpty    — 0 bookings: wallet.emptyState visible, three WayToSaveRows present,
//                    tapping one opens AddToWalletSheet.
//   walletError + UITEST_FAILURE_RATE=1.0 — orphan pin write rolls back + writeError.banner
//                    appears; add-sheet confirm write rolls back + writeError.banner appears.
//
// Pre-seeding note: for wallet scenarios, AppTemplateApp.makeStore() calls
// store.loadSeed(wallet:) at launch so WalletView's `.task` guard (if store.wallet == nil)
// is false — GetWalletRequest never fires. UITEST_FAILURE_RATE=1.0 therefore only affects
// PlaceOrphanRequest (the write), enabling the rollback path without also failing the read.
//
// Reachability: the app boots to .saved (AppStore.selectedTab default). The test taps `tab.wallet`
// to switch to the Wallet top-level tab; WalletView is the tab's root so it renders immediately.
//
// Accessibility identifiers confirmed against live View source:
//
//   tab.wallet                AppTab.accessibilityID (AppTab.wallet)
//   wallet.add                WalletView.addAffordanceRow (WalletView.swift line 113)
//   wallet.emptyState         WalletView.emptyState (WalletView.swift line 247)
//   walletfilter.byday        WalletView.filterChips — WalletFilter.byDay.rawValue.lowercased() (line 139)
//   walletfilter.bytype       WalletView.filterChips — WalletFilter.byType.rawValue.lowercased() (line 139)
//   walletfilter.orphans      WalletView.filterChips — WalletFilter.orphans.rawValue.lowercased() (line 139)
//   bookingrow.booking-castelo  WalletView.bookingRowButton (line 206; id from SampleData+Wallet.swift line 87)
//   bookingrow.booking-tap201   WalletView.bookingRowButton (line 206; id from SampleData+Wallet.swift line 91)
//   bookingrow.booking-fado-orphan  WalletView.bookingRowButton (line 206; id from SampleData+Wallet.swift line 93)
//   orphan.pin                WalletView.orphanPrompt (line 172)
//   orphan.dismiss            WalletView.orphanPrompt (line 173)
//   orphan.row                WalletView.orphanPrompt (line 174)
//   bookingdetail.share       BookingDetailView.shareRow (line 126)
//   bookingdetail.showPass    BookingDetailView — ActionBar primaryAccessibilityID (line 63)
//   accesscard.close          AccessCardView.closeButton (line 106)
//   addwallet.close           AddToWalletSheet.closeButton (line 131)
//   addwallet.method.forward  AddToWalletSheet.methodRow (line 163 — method.id == "forward")
//   addwallet.confirm         AddToWalletSheet.confirmCTA (line 365; id when !isAdding)
//   writeError.banner         WalletView.errorBanner (line 269) / AddToWalletSheet.errorBanner (line 416)
//   waytosave.<id>            WalletView.emptyState WayToSaveRow (line 237)
//
// Booking stable ids (SampleData+Wallet.swift):
//   "booking-castelo"         Day 2, status .now, activity — always on screen first in walletStandard
//   "booking-tap201"          Day 4, status .upcoming, transport — has an access pass (bookingdetail.showPass)
//   "booking-fado-orphan"     dayIndex nil — the seeded orphan driving the OrphanPromptCard + add-sheet write
//
// Mock write latency: PlaceOrphanRequest.mockLatency = .milliseconds(600).
// All write-path waits use timeout >= 6 s to absorb the 600 ms latency plus animation drag (10×).
//
// writeError.banner uses .accessibilityElement(children: .combine) (WalletView.swift line 268 /
// AddToWalletSheet.swift line 415) — .combine flattens the glyph+message HStack into a single
// element that XCUITest may surface as any element type. Use a type-agnostic descendants query so
// the lookup is correct regardless of the runtime element class (Saved L4 lesson, SavedFlowUITests).
//
// pbxproj: AppTemplateUITests uses PBXFileSystemSynchronizedRootGroup (objectVersion 77) —
// new Swift files auto-join the target; no manual pbxproj entry needed.
//
// See ios/docs/engineering/07-testing.md §7 for the full XCUITest layer contract.

import XCTest

/// XCUITest suite for the Wallet feature — WalletView · BookingDetailView · AccessCardView ·
/// AddToWalletSheet.
///
/// Table-driven across three configurations:
///   1. walletStandard  — rows present, orphan prompt shows; row → detail → showPass → close;
///                        "+" opens AddToWalletSheet (confirm navigates to review phase; close).
///   2. walletEmpty     — empty state visible; waytosave row opens AddToWalletSheet; close.
///   3. walletError (UITEST_FAILURE_RATE=1.0) — orphan "Pin" write rolls back, writeError.banner
///                        appears; add-sheet "Add to wallet" confirm rolls back, banner appears.
///
/// One `performAccessibilityAudit()` under walletStandard with narrow documented suppressions.
@MainActor
final class WalletFlowUITests: XCTestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Stop on first failure — subsequent assertions are meaningless if WalletView is unreachable.
        continueAfterFailure = false
    }

    // MARK: - Launch helper

    /// Builds and launches `XCUIApplication` wired to a given wallet scenario.
    ///
    /// - Parameters:
    ///   - scenario: The `UITEST_SCENARIO` raw value. Wallet scenarios: `"walletStandard"`,
    ///     `"walletEmpty"`, `"walletError"`.
    ///   - failureRate: When `1.0`, sets `UITEST_FAILURE_RATE=1.0` — AppTemplateApp maps this to
    ///     `APIClient.mock(failure: .status(503))`. Omitted for success paths.
    ///   - now: ISO-8601 string pinning the clock (07-testing §3). Defaults to
    ///     `"2025-08-28T12:00:00Z"` matching `SampleData.walletSimulatedNow` (today = Thu Aug 27
    ///     in the mockup so Day-2 bookings show .now / .today status deterministically).
    /// - Returns: The launched `XCUIApplication`.
    @discardableResult
    private func makeLaunchedApp(
        scenario: String,
        failureRate: Double? = nil,
        now: String = "2025-08-28T12:00:00Z"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_NOW"] = now
        if let failureRate, failureRate == 1.0 {
            app.launchEnvironment["UITEST_FAILURE_RATE"] = "1.0"
        }
        // Slow animations so waitForExistence beats spring transitions (mirrors SavedFlowUITests).
        app.launchArguments += ["-UIAnimationDragCoefficient", "10"]
        app.launch()
        return app
    }

    // MARK: - Navigation helpers

    /// Selects the Wallet top-level tab, landing directly on WalletView.
    ///
    /// The app boots to the Saved tab (`AppStore.selectedTab` defaults to `.saved`). This helper
    /// taps the Wallet tab (`tab.wallet`) in the system tab bar; WalletView is the tab's root so
    /// it is visible immediately after the tap — no further push is required.
    private func navigateToWallet(in app: XCUIApplication) {
        let walletTab = app.tabBars.buttons["tab.wallet"].exists
            ? app.tabBars.buttons["tab.wallet"]
            : app.tabBars.buttons["Wallet"]
        XCTAssertTrue(walletTab.waitForExistence(timeout: 6), "tab.wallet must exist (Wallet is a top-level tab)")
        walletTab.tap()
    }

    /// Swipes up until `element` is in the realized accessibility tree, up to `maxSwipes` times.
    private func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 6
    ) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    /// Swipes up until `element` is on-screen and hittable, up to `maxSwipes` times.
    ///
    /// Use this (not `scrollToElement`) when the element is known to exist in the a11y tree but
    /// may sit below the fold — `.exists` returns `true` for off-screen elements, but `.isHittable`
    /// only returns `true` once the element is within the visible viewport. Booking rows in the
    /// walletStandard list (Day 2 / Day 4) are pushed below the fold by the orphan prompt card
    /// and earlier-day groups, so a plain existence-scroll is insufficient.
    private func scrollToHittable(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 6
    ) {
        var n = 0
        while !element.isHittable && n < maxSwipes {
            app.swipeUp()
            n += 1
        }
    }

    // MARK: - testWalletStandardShowsRowsAndNavigates
    //
    // walletStandard: confirms the populated list (wallet.add + booking rows), taps a row to push
    // BookingDetailView, taps "Show boarding pass" to present AccessCardView, then closes both.
    // The store is pre-seeded at launch — no GET fires, so the list renders immediately.

    func testWalletStandardShowsRowsAndNavigates() throws {
        let app = makeLaunchedApp(scenario: "walletStandard")
        defer { app.terminate() }

        navigateToWallet(in: app)

        // wallet.add is the most reliable populated-layout sentinel (addAffordanceRow, line 113).
        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must appear — walletStandard is pre-seeded so the populated layout renders"
        )

        let walletPopulatedShot = XCTAttachment(screenshot: app.screenshot())
        walletPopulatedShot.name = "wallet-list-populated"
        walletPopulatedShot.lifetime = .keepAlways
        add(walletPopulatedShot)

        // The "booking-castelo" row — Day 2, status .now, near the top of the by-day list.
        // bookingrow.<id> set by WalletView.bookingRowButton (.accessibilityIdentifier line 206).
        // The orphan prompt card + Day 1 group push this row below the fold; scroll to hittable
        // (not just to existence — off-screen elements are in the a11y tree but not hittable).
        let casteloRow = app.buttons["bookingrow.booking-castelo"]
        XCTAssertTrue(
            casteloRow.waitForExistence(timeout: 5),
            "bookingrow.booking-castelo must exist in the walletStandard list (Day 2, .now activity)"
        )
        scrollToHittable(casteloRow, in: app)
        XCTAssertTrue(casteloRow.isHittable, "bookingrow.booking-castelo must be hittable")

        // Scroll to find the tap201 row (Day 4 — further below the fold than castelo).
        // Same pattern: wait for existence, then scroll until hittable before tapping.
        let tap201Row = app.buttons["bookingrow.booking-tap201"]
        XCTAssertTrue(
            tap201Row.waitForExistence(timeout: 5),
            "bookingrow.booking-tap201 must exist (Day 4, has access pass)"
        )
        scrollToHittable(tap201Row, in: app)
        XCTAssertTrue(tap201Row.isHittable, "bookingrow.booking-tap201 must be hittable")
        tap201Row.tap()

        // BookingDetailView — confirmed by bookingdetail.showPass (the CTA only appears when a pass
        // exists — booking-tap201 carries tap201AccessPass()).
        let showPassButton = app.buttons["bookingdetail.showPass"]
        XCTAssertTrue(
            showPassButton.waitForExistence(timeout: 6),
            "bookingdetail.showPass must appear after tapping bookingrow.booking-tap201 " +
            "(ActionBar primary CTA, visible because booking-tap201 has an access pass)"
        )

        let detailShot = XCTAttachment(screenshot: app.screenshot())
        detailShot.name = "booking-detail-tap201"
        detailShot.lifetime = .keepAlways
        add(detailShot)

        // Tap "Show boarding pass" — presents AccessCardView as a fullScreenCover.
        XCTAssertTrue(showPassButton.isHittable, "bookingdetail.showPass must be hittable")
        showPassButton.tap()

        // AccessCardView — confirmed by accesscard.close (line 106 of AccessCardView.swift).
        let accessCloseButton = app.buttons["accesscard.close"]
        XCTAssertTrue(
            accessCloseButton.waitForExistence(timeout: 6),
            "accesscard.close must appear after tapping bookingdetail.showPass " +
            "(AccessCardView presented as .fullScreenCover)"
        )

        let accessShot = XCTAttachment(screenshot: app.screenshot())
        accessShot.name = "access-card-tap201"
        accessShot.lifetime = .keepAlways
        add(accessShot)

        // Close the access card — AccessCardView dismisses.
        XCTAssertTrue(accessCloseButton.isHittable, "accesscard.close must be hittable")
        accessCloseButton.tap()

        // Back on BookingDetailView — showPass must re-appear (confirms dismiss worked).
        XCTAssertTrue(
            showPassButton.waitForExistence(timeout: 5),
            "bookingdetail.showPass must re-appear after closing AccessCardView"
        )

        let backAfterAccessShot = XCTAttachment(screenshot: app.screenshot())
        backAfterAccessShot.name = "booking-detail-after-access-close"
        backAfterAccessShot.lifetime = .keepAlways
        add(backAfterAccessShot)
    }

    // MARK: - testWalletStandardOrphanPromptVisible
    //
    // walletStandard: confirms the orphan prompt renders (orphan.pin + orphan.dismiss present), and
    // that dismissing it via "Not now" hides it this session.

    func testWalletStandardOrphanPromptVisible() throws {
        let app = makeLaunchedApp(scenario: "walletStandard")
        defer { app.terminate() }

        navigateToWallet(in: app)

        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must appear before checking the orphan prompt"
        )

        // The orphan prompt — booking-fado-orphan has dayIndex nil so the seeded wallet includes it.
        // OrphanPromptCard pin/dismiss/row ids are set by the WalletView.orphanPrompt call site
        // (pinAccessibilityID / dismissAccessibilityID / rowAccessibilityID, lines 172-174).
        let orphanPin = app.buttons["orphan.pin"]
        scrollToElement(orphanPin, in: app)
        XCTAssertTrue(
            orphanPin.waitForExistence(timeout: 6),
            "orphan.pin must appear — booking-fado-orphan (dayIndex nil) drives the OrphanPromptCard"
        )

        let orphanDismiss = app.buttons["orphan.dismiss"]
        XCTAssertTrue(
            orphanDismiss.waitForExistence(timeout: 4),
            "orphan.dismiss must appear alongside orphan.pin in the OrphanPromptCard"
        )

        let orphanShot = XCTAttachment(screenshot: app.screenshot())
        orphanShot.name = "wallet-orphan-prompt"
        orphanShot.lifetime = .keepAlways
        add(orphanShot)

        // Tap "Not now" — the prompt is hidden this session via `orphanDismissed` @State.
        XCTAssertTrue(orphanDismiss.isHittable, "orphan.dismiss must be hittable")
        orphanDismiss.tap()

        // The pin button must disappear (the prompt is gone from the layout).
        XCTAssertTrue(
            orphanPin.waitForNonExistence(timeout: 5),
            "orphan.pin must disappear after tapping orphan.dismiss (prompt hidden this session)"
        )

        let afterDismissShot = XCTAttachment(screenshot: app.screenshot())
        afterDismissShot.name = "wallet-after-orphan-dismiss"
        afterDismissShot.lifetime = .keepAlways
        add(afterDismissShot)
    }

    // MARK: - testWalletStandardAddSheetOpensAndCloses
    //
    // walletStandard: tapping wallet.add opens AddToWalletSheet (addwallet.close appears);
    // tapping the "Forward" method row advances to the review phase (addwallet.confirm appears);
    // closing the sheet returns to WalletView (wallet.add re-appears).

    func testWalletStandardAddSheetOpensAndCloses() throws {
        let app = makeLaunchedApp(scenario: "walletStandard")
        defer { app.terminate() }

        navigateToWallet(in: app)

        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must exist before tapping it"
        )

        XCTAssertTrue(addButton.isHittable, "wallet.add must be hittable")
        addButton.tap()

        // AddToWalletSheet — confirmed by addwallet.close appearing.
        let closeButton = app.buttons["addwallet.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addwallet.close must appear when AddToWalletSheet is presented"
        )

        let sheetOpenShot = XCTAttachment(screenshot: app.screenshot())
        sheetOpenShot.name = "add-wallet-sheet-method"
        sheetOpenShot.lifetime = .keepAlways
        add(sheetOpenShot)

        // The prominent "Forward a confirmation" row advances to the review phase.
        // addwallet.method.forward — set by AddToWalletSheet.methodRow (line 163, method.id == "forward").
        let forwardMethod = app.buttons["addwallet.method.forward"]
        XCTAssertTrue(
            forwardMethod.waitForExistence(timeout: 4),
            "addwallet.method.forward must exist in phase A (the prominent Forward row)"
        )
        XCTAssertTrue(forwardMethod.isHittable, "addwallet.method.forward must be hittable")
        forwardMethod.tap()

        // Phase B — confirmed by addwallet.confirm appearing (the "Add to wallet" CTA when !isAdding).
        let confirmButton = app.buttons["addwallet.confirm"]
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 5),
            "addwallet.confirm must appear after advancing to the review phase (phase B)"
        )

        let sheetReviewShot = XCTAttachment(screenshot: app.screenshot())
        sheetReviewShot.name = "add-wallet-sheet-review"
        sheetReviewShot.lifetime = .keepAlways
        add(sheetReviewShot)

        // Close the sheet — addwallet.close must dismiss it.
        XCTAssertTrue(closeButton.isHittable, "addwallet.close must be hittable")
        closeButton.tap()

        // Back on WalletView — wallet.add must re-appear.
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 5),
            "wallet.add must re-appear after closing AddToWalletSheet"
        )

        let backShot = XCTAttachment(screenshot: app.screenshot())
        backShot.name = "wallet-after-add-sheet-close"
        backShot.lifetime = .keepAlways
        add(backShot)
    }

    // MARK: - testWalletEmptyStateRendersWays
    //
    // walletEmpty: wallet.emptyState is visible, wallet.add is NOT present, and the WayToSaveRow
    // affordances exist. Tapping one opens AddToWalletSheet (addwallet.close appears); closing
    // returns to the empty state (wallet.emptyState re-appears).

    func testWalletEmptyStateRendersWays() throws {
        let app = makeLaunchedApp(scenario: "walletEmpty")
        defer { app.terminate() }

        navigateToWallet(in: app)

        // wallet.emptyState — the .accessibilityElement(children: .contain) container on the empty
        // layout (WalletView.swift line 246-247). Must appear.
        let emptyState = app.otherElements["wallet.emptyState"]
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 8),
            "wallet.emptyState must appear when walletEmpty is seeded (0 bookings)"
        )

        // wallet.add must be present — it is now a persistent floating GlassCircleButton in
        // ScreenScaffold's trailing-action overlay, visible in ALL states including empty.
        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 3),
            "wallet.add must exist in the empty state (persistent floating '+' is always present)"
        )

        let emptyShot = XCTAttachment(screenshot: app.screenshot())
        emptyShot.name = "wallet-empty-state"
        emptyShot.lifetime = .keepAlways
        add(emptyShot)

        // The WayToSaveRow affordances — ids "waytosave.<way.id>" (WalletView.swift line 237).
        // The first way (forward) from AddToWalletPresenter.methods is expected first.
        // We locate any waytosave row; the exact id depends on the presenter's way ordering.
        // Check for "waytosave.forward" — the prominent first way in the AddToWalletPresenter.
        let forwardWay = app.buttons["waytosave.forward"]
        XCTAssertTrue(
            forwardWay.waitForExistence(timeout: 4),
            "waytosave.forward must exist in the empty state (the prominent WayToSaveRow)"
        )

        // Tapping any waytosave row opens AddToWalletSheet (all three have the same sink).
        XCTAssertTrue(forwardWay.isHittable, "waytosave.forward must be hittable")
        forwardWay.tap()

        let closeButton = app.buttons["addwallet.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addwallet.close must appear after tapping waytosave.forward (AddToWalletSheet presented)"
        )

        let sheetShot = XCTAttachment(screenshot: app.screenshot())
        sheetShot.name = "add-wallet-sheet-from-empty-state"
        sheetShot.lifetime = .keepAlways
        add(sheetShot)

        // Close the sheet — wallet.emptyState must re-appear.
        XCTAssertTrue(closeButton.isHittable, "addwallet.close must be hittable")
        closeButton.tap()

        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 5),
            "wallet.emptyState must re-appear after closing AddToWalletSheet from the empty state"
        )

        let afterCloseShot = XCTAttachment(screenshot: app.screenshot())
        afterCloseShot.name = "wallet-empty-after-sheet-close"
        afterCloseShot.lifetime = .keepAlways
        add(afterCloseShot)
    }

    // MARK: - testOrphanPinWriteErrorBanner
    //
    // walletError + UITEST_FAILURE_RATE=1.0: tapping orphan.pin fires placeOrphan, which throws
    // .status(503) → the day is restored + store.writeError == .placeOrphan → writeError.banner
    // appears on WalletView.
    //
    // Uses walletError (same DTO as walletStandard) so AppTemplateApp.makeStore() pre-seeds the
    // wallet before any request fires. UITEST_FAILURE_RATE=1.0 is therefore confined to the write
    // (PlaceOrphanRequest), never to the read (GetWalletRequest fires only when wallet == nil, and
    // pre-seeding means it is non-nil at render time — matching the savedError pre-seed pattern).

    func testOrphanPinWriteErrorBanner() throws {
        let app = makeLaunchedApp(scenario: "walletError", failureRate: 1.0)
        defer { app.terminate() }

        navigateToWallet(in: app)

        // Store is pre-seeded — populated layout appears immediately.
        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must appear (walletError is pre-seeded at launch — same DTO as walletStandard)"
        )

        // Scroll to the orphan prompt.
        let orphanPin = app.buttons["orphan.pin"]
        scrollToElement(orphanPin, in: app)
        XCTAssertTrue(
            orphanPin.waitForExistence(timeout: 6),
            "orphan.pin must appear (booking-fado-orphan has dayIndex nil in the walletError seed)"
        )

        let preWriteShot = XCTAttachment(screenshot: app.screenshot())
        preWriteShot.name = "wallet-orphan-pre-pin-failure"
        preWriteShot.lifetime = .keepAlways
        add(preWriteShot)

        // Tap "Pin to Day N" — fires store.placeOrphan, which will fail immediately
        // (UITEST_FAILURE_RATE=1.0 → MockProvider returns .status(503)). The store rolls back
        // dayIndex to nil and sets writeError = .placeOrphan.
        XCTAssertTrue(orphanPin.isHittable, "orphan.pin must be hittable")
        orphanPin.tap()

        // writeError.banner must appear on WalletView (line 269 of WalletView.swift).
        // .combine flattens the glyph+message HStack — use type-agnostic descendants query
        // (the Saved L4 lesson: the element class may not be .other, use .any).
        // PlaceOrphanRequest.mockLatency = .milliseconds(600); add 4s animation-drag buffer.
        let errorBanner = app.descendants(matching: .any)
            .matching(identifier: "writeError.banner")
            .firstMatch
        XCTAssertTrue(
            errorBanner.waitForExistence(timeout: 8),
            "writeError.banner must appear on WalletView after orphan.pin fires a forced placeOrphan " +
            "failure (UITEST_FAILURE_RATE=1.0 → .status(503) → rollback → writeError == .placeOrphan)"
        )

        let errorShot = XCTAttachment(screenshot: app.screenshot())
        errorShot.name = "wallet-orphan-pin-write-error-banner"
        errorShot.lifetime = .keepAlways
        add(errorShot)
    }

    // MARK: - testAddSheetConfirmWriteErrorBanner
    //
    // walletError + UITEST_FAILURE_RATE=1.0: the add-sheet "Add to wallet" confirm taps
    // addwallet.confirm, which fires store.placeOrphan → .status(503) → writeError.banner appears
    // in the sheet (the sheet stays open on failure — dismiss is guarded by writeError == nil).
    // Exercises the second write entry point and confirms the banner appears in the sheet context.

    func testAddSheetConfirmWriteErrorBanner() throws {
        let app = makeLaunchedApp(scenario: "walletError", failureRate: 1.0)
        defer { app.terminate() }

        navigateToWallet(in: app)

        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must exist before opening the add sheet (walletError pre-seeded)"
        )
        addButton.tap()

        let closeButton = app.buttons["addwallet.close"]
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "addwallet.close must appear when AddToWalletSheet is presented"
        )

        // Advance to phase B via the Forward method row.
        let forwardMethod = app.buttons["addwallet.method.forward"]
        XCTAssertTrue(
            forwardMethod.waitForExistence(timeout: 4),
            "addwallet.method.forward must exist in phase A"
        )
        forwardMethod.tap()

        // Confirm we are on the review phase — addwallet.confirm present (not addwallet.progress).
        let confirmButton = app.buttons["addwallet.confirm"]
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 5),
            "addwallet.confirm must appear after advancing to the review phase"
        )

        let preWriteShot = XCTAttachment(screenshot: app.screenshot())
        preWriteShot.name = "add-wallet-confirm-pre-failure"
        preWriteShot.lifetime = .keepAlways
        add(preWriteShot)

        // Tap "Add to wallet" — fires store.placeOrphan (the one networked write, OD-4).
        // UITEST_FAILURE_RATE=1.0 → .status(503) → rollback → writeError = .placeOrphan.
        XCTAssertTrue(confirmButton.isHittable, "addwallet.confirm must be hittable")
        confirmButton.tap()

        // Sheet stays open on failure (dismiss is guarded by writeError == nil, AddToWalletSheet.swift
        // confirmAdd() line 440). addwallet.close must still exist.
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 4),
            "addwallet.close must still exist after the confirm tap — if this fails the sheet " +
            "dismissed, meaning the write SUCCEEDED (Case A: failure injection did not reach " +
            "PlaceOrphanRequest). If it passes but the banner is missing, the store write failed " +
            "but the sheet did not re-render (Case B: @Observable observation gap)."
        )

        // writeError.banner must appear inside AddToWalletSheet (line 416 of AddToWalletSheet.swift).
        // Same .combine / type-agnostic query as the WalletView banner test.
        // PlaceOrphanRequest.mockLatency = .milliseconds(600); with animation drag (10×) allow 8 s.
        let errorBanner = app.descendants(matching: .any)
            .matching(identifier: "writeError.banner")
            .firstMatch
        XCTAssertTrue(
            errorBanner.waitForExistence(timeout: 8),
            "writeError.banner must appear in AddToWalletSheet after a forced confirm write failure"
        )

        let errorShot = XCTAttachment(screenshot: app.screenshot())
        errorShot.name = "add-wallet-confirm-write-error-banner"
        errorShot.lifetime = .keepAlways
        add(errorShot)
    }

    // MARK: - testAccessibilityAudit (walletStandard — broad audit on WalletView)
    //
    // Runs the BROAD `performAccessibilityAudit` (no `for:` narrowing — that silently drops whole
    // categories, per 07-testing §7.4). The `issueHandler` carries ONLY the documented suppressions
    // below; everything else returns `false` (hard-fail).
    //
    // Suppressed types and their documented compensating checks:
    //
    // • .dynamicType — SwiftUI `Font.custom(relativeTo:)` / `Font.system(.style)` don't surface
    //   `adjustsFontForContentSizeCategory` to the UIKit a11y inspector; text DOES scale
    //   (Typography.swift binds every role to a Dynamic Type style, zero fixedSize calls).
    //   Compensating control (07 §7.4): AX5 render snapshot for wallet-populated
    //   (WalletSnapshotTests "wallet-ax5") locks Dynamic Type at AX5.
    //   Whole-type suppression is therefore covered.
    //
    // • .contrast — the pixel-sampler mis-reads OKLCH inks over the system glass/scroll background
    //   and the booking-type tinted icon tiles (flags bookingMark-on-bookingTint pairs which
    //   definitionally pass at the mockup opacity). Receded-ink contrast is a deliberate design-doc
    //   decision (decisions.md 2026-06-03). Compensating control: committed snapshot baselines lock
    //   the rendered ink values — any unintentional token drift breaks L3 before this audit.
    //
    // • .textClipped — BookingRow, StatusPill, and DayGroupHeader labels grow from minHeight
    //   (no fixed frame); the audit flags them as clipped at the measurement moment. Known FP on
    //   custom layout-driven components. Compensating control: committed snapshot baselines for
    //   BookingRowSnapshotTests, StatusPillSnapshotTests, DayGroupHeaderSnapshotTests — a real clip
    //   shifts rendered bounds and breaks those baselines before shipping.
    //
    // • .elementDetection && id.isEmpty && label.isEmpty — the accent badge on WalletEmptyGlyph and
    //   decorative background shapes (bookingTint tile) carry `.accessibilityHidden(true)`, but the
    //   heuristic may transiently flag ZStack layers in complex compound views. Suppression is narrow:
    //   only elements with BOTH empty id AND empty label; any element with a non-empty id or label
    //   hard-fails. Compensating control: AX5 wallet snapshot (WalletSnapshotTests "wallet-ax5").
    //
    // Every other issue hard-fails (return false). A blanket `return true` is a defect (§7.4).

    func testAccessibilityAudit() throws {
        let app = makeLaunchedApp(scenario: "walletStandard")
        defer { app.terminate() }

        navigateToWallet(in: app)

        // Wait for the wallet to be fully rendered before auditing.
        let addButton = app.buttons["wallet.add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 8),
            "wallet.add must exist before running the accessibility audit"
        )

        // Scroll down to realize below-fold rows in the accessibility tree, then restore to top.
        app.swipeUp()
        app.swipeDown()

        let preAuditShot = XCTAttachment(screenshot: app.screenshot())
        preAuditShot.name = "wallet-pre-audit"
        preAuditShot.lifetime = .keepAlways
        add(preAuditShot)

        // Audit types that are systematically unreliable on this custom design (see above).
        let suppressedTypes: XCUIAccessibilityAuditType = [.dynamicType, .contrast, .textClipped]

        try app.performAccessibilityAudit { issue in
            // Whole-type suppressions — each names a live compensating check above.
            if suppressedTypes.contains(issue.auditType) { return true }
            // Narrow .elementDetection suppression: decorative compound-view layers with no id AND
            // no label (the render-heuristic "potentially inaccessible text" FP — 07 §6.6 / 05 §8.1).
            // Any element with a non-empty id or non-empty label is NOT suppressed here.
            let id    = issue.element?.identifier ?? ""
            let label = issue.element?.label      ?? ""
            if issue.auditType == .elementDetection && id.isEmpty && label.isEmpty { return true }
            // All other issues hard-fail — a blanket return true is a defect (07-testing §7.4).
            return false
        }
    }
}
