/*
 Layer 1 — Presenter derivation tests for WalletPresenter, BookingDetailPresenter,
 and AddToWalletPresenter.

 Layer / scope:
   - L1: stateless value-over-(store, …ids) derivation. No network, no async.
   - Seeds a store via AppStore.preview(wallet:) from SampleData.walletDTO() /
     SampleData.emptyWalletDTO(). Never SampleData.wallet() in arguments position (it's
     @MainActor — §6.6 "expression is 'async' but not marked 'await'").

 Rules:
   - No Date() / Calendar.current / Locale.current.
   - Fixtures by stable id ("booking-tap201"), never array position.
   - Reference model fields asserted individually; no == between two constructed instances.
   - @Test @MainActor throughout (presenters read @Observable @MainActor AppStore).
   - @Test(arguments:) uses a nonisolated tag enum; MainActor values built inside the body.

 WalletPresenter states covered:
   1. Empty (no bookings) → isEmpty == true, emptyTitle/emptyBody non-empty, wayToSave × 3
   2. Populated, default filter (.byDay) → heroContext "Lisbon · 4 days · 8 bookings";
      dayGroups count == 4; order day 1→4; isToday flag on day 2; past-day rows flagged isPast;
      orphan present (booking-fado-orphan)
   3. Filter .byType → dayGroups keyed by type; lodging group present; filter chips count
   4. Filter .orphans → dayGroups is empty
   5. filterChips: 3 chips, orphans chip has count == 1
   6. orphanBookingID == "booking-fado-orphan"; suggestedDay == 2 (first today/now day)

 BookingDetailPresenter:
   - hasBooking true/false for known/unknown id
   - kindTitle from detail.kind ("Flight"), falls back to type.displayLabel
   - systemImage non-nil for known id
   - kindEyebrow from subtitleParts ("TAP Air · TP 201 · seat 14A") for tap201
   - name == booking.title
   - status == booking.status
   - metaLine == booking.startTime
   - infoCells count from detail (3 for tap201)
   - confirmation for tap201
   - detailRows count from detail (5 for tap201)
   - placedLabel from detail ("Placed on Day 4 · Sat, Aug 29")
   - hasAccessPass true for tap201, false for castelo
   - showPassTitle == "Show boarding pass"
   - no-detail path: infoCells empty, detailRows empty, placedLabel nil (booking-castelo)

 AddToWalletPresenter:
   - methods count == 3, order forward/scan/photo
   - forward row is prominent; scan and photo are not
   - methodTitle / methodSubtitle / reviewTitle non-empty
   - forwardEmail == "wallet@aitravel.app"
   - verifyTag / confirmTitle / editTitle pinned literals
   - reviewFields count == 5, order type/name/when/where/confirmation
   - reviewFields.when.lowConfidence == true; confirmation.isMono == true
   - orphanBookingID == "booking-fado-orphan"; suggestedDay == 2
   - isLoading reflects isAdding arg
   - writeErrorMessage nil when writeError nil, non-nil when .placeOrphan
*/

import Testing
@testable import AppTemplate

// MARK: - WalletPresenter

@Suite("WalletPresenter derivation")
struct WalletPresenterTests {

    // MARK: Factory helpers

    /// Populated store (8 placed + 1 orphan).
    @MainActor
    private func makePopulatedStore() -> AppStore {
        AppStore.preview(wallet: SampleData.walletDTO())
    }

    /// Empty store (0 bookings).
    @MainActor
    private func makeEmptyStore() -> AppStore {
        AppStore.preview(wallet: SampleData.emptyWalletDTO())
    }

    // MARK: - State 1: empty

    @Test("isEmpty is true when there are no bookings") @MainActor
    func isEmptyWhenNoBookings() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        #expect(p.isEmpty == true)
    }

    @Test("isEmpty is false when bookings are loaded") @MainActor
    func isEmptyFalseWhenPopulated() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.isEmpty == false)
    }

    @Test("emptyTitle is non-empty") @MainActor
    func emptyTitleNonEmpty() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        #expect(!p.emptyTitle.isEmpty)
    }

    @Test("emptyBody is non-empty") @MainActor
    func emptyBodyNonEmpty() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        #expect(!p.emptyBody.isEmpty)
    }

    @Test("wayToSave has exactly 3 rows") @MainActor
    func wayToSaveHasThreeRows() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        #expect(p.wayToSave.count == 3)
    }

    @Test("wayToSave: order is forward, scan, photo") @MainActor
    func wayToSaveOrder() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        let ids = p.wayToSave.map(\.id)
        #expect(ids == ["forward", "scan", "photo"])
    }

    @Test("wayToSave: no rows are prominent (empty state uses no accent)") @MainActor
    func wayToSaveNoneProminent() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        let prominentRows = p.wayToSave.filter { $0.prominent }
        #expect(prominentRows.isEmpty,
                "the wallet empty state must have no prominent WayToSaveRow (the badge is the one accent)")
    }

    // MARK: - State 2: populated, .byDay (default)

    /// Frozen-literal oracle: 8 placed bookings (orphan is not counted), city Lisbon, 4 days.
    @Test("heroContext frozen literal 'Lisbon · 4 days · 8 bookings' (placed count, not total)") @MainActor
    func heroContextFrozenLiteral() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.heroContext == "Lisbon · 4 days · 8 bookings",
                "heroContext must be 'Lisbon · 4 days · 8 bookings' — the orphan is NOT counted")
    }

    @Test("dayGroups has 4 groups for the populated seed (Days 1-4) with .byDay filter") @MainActor
    func dayGroupsCountPopulated() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        #expect(p.dayGroups.count == 4)
    }

    @Test("dayGroups are in ascending day order: Day 1, Day 2, Day 3, Day 4") @MainActor
    func dayGroupsAscendingOrder() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let dayLabels = p.dayGroups.map(\.dayLabel)
        #expect(dayLabels == ["Day 1", "Day 2", "Day 3", "Day 4"])
    }

    /// Day 2 is today because it contains a .now (castelo) or .today (ferry) booking.
    @Test("dayGroups: Day 2 has isToday == true (contains .now/.today bookings)") @MainActor
    func dayGroupsDay2IsToday() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day2 = p.dayGroups.first(where: { $0.dayLabel == "Day 2" })
        #expect(day2 != nil)
        if let group = day2 {
            #expect(group.isToday == true,
                    "Day 2 must be flagged as today because it has .now/.today bookings")
        }
    }

    @Test("dayGroups: Day 1, Day 3, Day 4 have isToday == false") @MainActor
    func dayGroupsNonTodayDaysNotFlagged() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let nonTodayLabels = ["Day 1", "Day 3", "Day 4"]
        for label in nonTodayLabels {
            let group = p.dayGroups.first(where: { $0.dayLabel == label })
            if let group {
                #expect(group.isToday == false,
                        "\(label) must have isToday == false")
            }
        }
    }

    /// Day 1 has 2 past bookings (casa-bairro + timeout). Their rows must have isPast == true.
    @Test("dayGroups: Day 1 rows are flagged isPast == true (past status bookings)") @MainActor
    func dayGroupsDay1RowsArePast() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day1 = p.dayGroups.first(where: { $0.dayLabel == "Day 1" })
        #expect(day1 != nil)
        if let group = day1 {
            for row in group.rows {
                #expect(row.isPast == true,
                        "all rows in Day 1 must have isPast == true (Day 1 bookings are .past)")
            }
        }
    }

    @Test("dayGroups: Day 1 has 2 rows (casa-bairro + timeout)") @MainActor
    func dayGroupsDay1Count() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day1 = p.dayGroups.first(where: { $0.dayLabel == "Day 1" })
        #expect(day1?.rows.count == 2)
    }

    @Test("dayGroups: Day 2 has 2 rows (castelo + ferry)") @MainActor
    func dayGroupsDay2Count() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day2 = p.dayGroups.first(where: { $0.dayLabel == "Day 2" })
        #expect(day2?.rows.count == 2)
    }

    @Test("dayGroups: booking-tap201 appears in Day 4") @MainActor
    func dayGroupsTap201InDay4() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day4 = p.dayGroups.first(where: { $0.dayLabel == "Day 4" })
        #expect(day4 != nil)
        if let group = day4 {
            let tap201Row = group.rows.first(where: { $0.id == "booking-tap201" })
            #expect(tap201Row != nil, "booking-tap201 must appear in Day 4")
            if let row = tap201Row {
                #expect(row.title == "Lisbon → New York")
                #expect(row.type == .transport)
                #expect(row.isPast == false)
            }
        }
    }

    @Test("dayGroups: Day 2 dateLabel contains 'today'") @MainActor
    func dayGroupsDay2DateLabelContainsToday() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day2 = p.dayGroups.first(where: { $0.dayLabel == "Day 2" })
        #expect(day2?.dateLabel.contains("today") == true,
                "the Day 2 dateLabel must contain 'today'")
    }

    @Test("dayGroups: Day 1 dateLabel does NOT contain 'today'") @MainActor
    func dayGroupsDay1DateLabelNotToday() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byDay)
        let day1 = p.dayGroups.first(where: { $0.dayLabel == "Day 1" })
        #expect(day1?.dateLabel.contains("today") == false,
                "Day 1 dateLabel must not contain 'today'")
    }

    // MARK: - Orphan prompt

    @Test("orphan is non-nil when there is an unplaced booking") @MainActor
    func orphanNonNilWhenPresent() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan != nil, "orphan must be non-nil when booking-fado-orphan is present")
    }

    @Test("orphan is nil when there are no unplaced bookings (empty wallet)") @MainActor
    func orphanNilWhenEmpty() {
        let store = makeEmptyStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan == nil)
    }

    @Test("orphan.bookingName matches the orphan booking title ('Fado at Tasca do Chico')") @MainActor
    func orphanBookingName() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan?.bookingName == "Fado at Tasca do Chico")
    }

    @Test("orphan.type matches the orphan booking type (.activity)") @MainActor
    func orphanType() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan?.type == .activity)
    }

    @Test("orphan.pinTitle contains 'Pin to Day' (at least)") @MainActor
    func orphanPinTitleContainsPinToDay() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan?.pinTitle.contains("Pin to Day") == true)
    }

    @Test("orphan.dismissTitle == 'Not now'") @MainActor
    func orphanDismissTitle() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan?.dismissTitle == "Not now")
    }

    @Test("orphan.labelCaps contains 'BOOKING NOT YET PLACED'") @MainActor
    func orphanLabelCapsContainsCopy() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphan?.labelCaps.contains("BOOKING NOT YET PLACED") == true)
    }

    @Test("orphanBookingID == 'booking-fado-orphan'") @MainActor
    func orphanBookingID() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.orphanBookingID == "booking-fado-orphan")
    }

    /// suggestedDay == 2: the first today/now day in the seed (Day 2 has .now + .today bookings).
    @Test("suggestedDay == 2 (first today/now day from the seeded statuses)") @MainActor
    func suggestedDay() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.suggestedDay == 2,
                "suggestedDay must be 2 — the day containing .now/.today bookings")
    }

    // MARK: - State 3: filter .byType

    @Test("dayGroups is non-empty for .byType filter on the populated seed") @MainActor
    func dayGroupsByTypeNonEmpty() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byType)
        #expect(!p.dayGroups.isEmpty)
    }

    @Test("dayGroups .byType: lodging group has id 'type-lodging'") @MainActor
    func dayGroupsByTypeLodgingGroupExists() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byType)
        let lodgingGroup = p.dayGroups.first(where: { $0.id == "type-lodging" })
        #expect(lodgingGroup != nil, "a 'type-lodging' group must be present in .byType")
    }

    @Test("dayGroups .byType: lodging group has dayLabel == 'Lodging'") @MainActor
    func dayGroupsByTypeLodgingLabel() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byType)
        let lodgingGroup = p.dayGroups.first(where: { $0.id == "type-lodging" })
        #expect(lodgingGroup?.dayLabel == "Lodging")
    }

    @Test("dayGroups .byType: groups have empty dateLabel and isToday == false") @MainActor
    func dayGroupsByTypeDateLabelEmpty() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byType)
        for group in p.dayGroups {
            #expect(group.dateLabel == "",
                    "by-type groups must have an empty dateLabel (no day/date context)")
            #expect(group.isToday == false,
                    "by-type groups must have isToday == false")
        }
    }

    @Test("dayGroups .byType: booking-tap201 appears in the 'type-transport' group") @MainActor
    func dayGroupsByTypeTransportContainsTap201() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .byType)
        let transportGroup = p.dayGroups.first(where: { $0.id == "type-transport" })
        #expect(transportGroup != nil)
        if let group = transportGroup {
            let tap201 = group.rows.first(where: { $0.id == "booking-tap201" })
            #expect(tap201 != nil, "booking-tap201 must appear in the type-transport group")
        }
    }

    // MARK: - State 4: filter .orphans

    @Test("dayGroups is empty for .orphans filter") @MainActor
    func dayGroupsEmptyForOrphansFilter() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store, filter: .orphans)
        #expect(p.dayGroups.isEmpty,
                "dayGroups must be empty for the .orphans filter — the view shows only the orphan prompt")
    }

    // MARK: - Filter chips

    @Test("filterChips has exactly 3 chips") @MainActor
    func filterChipsHasThreeChips() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        #expect(p.filterChips.count == 3)
    }

    @Test("filterChips order: byDay, byType, orphans") @MainActor
    func filterChipsOrder() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        let filters = p.filterChips.map(\.filter)
        #expect(filters == [.byDay, .byType, .orphans])
    }

    @Test("filterChips orphans chip has count == 1 (one orphan in the seed)") @MainActor
    func filterChipsOrphansCount() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        let orphansChip = p.filterChips.first(where: { $0.filter == .orphans })
        #expect(orphansChip != nil)
        #expect(orphansChip?.count == 1,
                "the orphans chip must have count == 1 (booking-fado-orphan is the one orphan)")
    }

    @Test("filterChips byDay and byType chips have nil count (no badge)") @MainActor
    func filterChipsByDayByTypeNilCount() {
        let store = makePopulatedStore()
        let p = WalletPresenter(store: store)
        let byDayChip = p.filterChips.first(where: { $0.filter == .byDay })
        let byTypeChip = p.filterChips.first(where: { $0.filter == .byType })
        #expect(byDayChip?.count == nil, "byDay chip must have nil count")
        #expect(byTypeChip?.count == nil, "byType chip must have nil count")
    }
}

// MARK: - BookingDetailPresenter

@Suite("BookingDetailPresenter derivation")
struct BookingDetailPresenterTests {

    // MARK: Factory helper

    /// Build a BookingDetailPresenter for a given booking id over the populated seed.
    @MainActor
    private func makePresenter(bookingID: String) -> BookingDetailPresenter {
        let store = AppStore.preview(wallet: SampleData.walletDTO())
        return BookingDetailPresenter(store: store, bookingID: bookingID)
    }

    // MARK: Resolution

    @Test("hasBooking is true for known id 'booking-tap201'") @MainActor
    func hasBookingTrueForKnownID() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.hasBooking == true)
    }

    @Test("hasBooking is false for unknown id") @MainActor
    func hasBookingFalseForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.hasBooking == false)
    }

    // MARK: Chrome

    /// kindTitle comes from detail.kind ("Flight") for booking-tap201.
    @Test("kindTitle is 'Flight' for 'booking-tap201' (from detail.kind)") @MainActor
    func kindTitleFromDetailForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.kindTitle == "Flight")
    }

    /// kindTitle falls back to booking type's displayLabel when no detail is fetched.
    /// booking-castelo has no detail; type == .activity → displayLabel == "Activity".
    @Test("kindTitle falls back to type.displayLabel when no detail (booking-castelo → 'Activity')") @MainActor
    func kindTitleFallbackForCastelo() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.kindTitle == "Activity",
                "kindTitle must fall back to type.displayLabel when booking has no detail")
    }

    @Test("kindTitle is empty for unknown id") @MainActor
    func kindTitleEmptyForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.kindTitle == "")
    }

    // MARK: Hero block

    @Test("type is .transport for 'booking-tap201'") @MainActor
    func typeForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.type == .transport)
    }

    @Test("type is .other for unknown id (fallback)") @MainActor
    func typeOtherForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.type == .other)
    }

    @Test("systemImage is non-nil for known id 'booking-tap201'") @MainActor
    func systemImageNonNilForKnownID() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.systemImage != nil)
    }

    @Test("systemImage == 'airplane' for 'booking-tap201' (.transport type)") @MainActor
    func systemImageForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.systemImage == "airplane")
    }

    @Test("systemImage is nil for unknown id") @MainActor
    func systemImageNilForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.systemImage == nil)
    }

    /// kindEyebrow is the subtitleParts joined by " · ".
    /// booking-tap201 subtitleParts: ["TAP Air · TP 201", "seat 14A"] → "TAP Air · TP 201 · seat 14A"
    @Test("kindEyebrow for 'booking-tap201' is composed from subtitleParts") @MainActor
    func kindEyebrowForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        let eyebrow = p.kindEyebrow
        #expect(eyebrow != nil)
        if let eyebrow {
            #expect(eyebrow.contains("TAP Air"),
                    "kindEyebrow must include the first subtitle part")
        }
    }

    /// booking-ferry has empty subtitleParts — kindEyebrow should be nil.
    /// Actually ferry has subtitleParts ["Cais do Sodré", "10 min"] so let's use a booking with empty subtitleParts.
    /// booking-casa-bairro has subtitleParts ["Alfama", "2 nights"] — non-nil eyebrow.
    /// Use booking-timeout which also has subtitleParts ["Cais do Sodré", "lunch"].
    /// The test we want: kindEyebrow is nil when subtitleParts is empty.
    /// We build a custom DTO for this case:
    @Test("kindEyebrow is nil when subtitleParts is empty") @MainActor
    func kindEyebrowNilWhenEmptySubtitleParts() {
        // Build a one-booking wallet with empty subtitleParts
        let dto = BookingDTO(
            id: "booking-no-parts",
            title: "No Parts Booking",
            type: .activity,
            status: .upcoming,
            dayIndex: 1,
            startTime: "10:00",
            subtitleParts: [],  // empty — kindEyebrow must be nil
            confirmation: nil
        )
        let walletDTO = TripWalletDTO(id: "wallet-test", tripCityName: "Test", dayCount: 1, bookings: [dto])
        let store = AppStore.preview(wallet: walletDTO)
        let p = BookingDetailPresenter(store: store, bookingID: "booking-no-parts")
        #expect(p.kindEyebrow == nil,
                "kindEyebrow must be nil when subtitleParts is empty")
    }

    @Test("name == 'Lisbon → New York' for 'booking-tap201'") @MainActor
    func nameForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.name == "Lisbon → New York")
    }

    @Test("name is empty for unknown id") @MainActor
    func nameEmptyForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.name == "")
    }

    @Test("status is .upcoming for 'booking-tap201'") @MainActor
    func statusForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.status == .upcoming)
    }

    @Test("status is nil for unknown id") @MainActor
    func statusNilForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.status == nil)
    }

    @Test("metaLine is 'Departs 13:40' for 'booking-tap201'") @MainActor
    func metaLineForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.metaLine == "Departs 13:40")
    }

    @Test("metaLine is nil for unknown id") @MainActor
    func metaLineNilForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.metaLine == nil)
    }

    // MARK: Info grid (from detail payload)

    @Test("infoCells has 3 cells for 'booking-tap201' (has detail)") @MainActor
    func infoCellsCountForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.infoCells.count == 3)
    }

    @Test("infoCells[0].key == 'Depart' for 'booking-tap201'") @MainActor
    func infoCellsFirstKeyForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.infoCells.first?.key == "Depart")
    }

    @Test("infoCells is empty for 'booking-castelo' (no detail fetched)") @MainActor
    func infoCellsEmptyForNonDetailBooking() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.infoCells.isEmpty,
                "infoCells must be empty for a booking with no detail payload")
    }

    // MARK: Confirmation row

    @Test("confirmation is '7XQK2M' for 'booking-tap201'") @MainActor
    func confirmationForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.confirmation == "7XQK2M")
    }

    @Test("confirmation is nil for 'booking-ferry' (no confirmation in seed)") @MainActor
    func confirmationNilForFerry() {
        let p = makePresenter(bookingID: "booking-ferry")
        #expect(p.confirmation == nil)
    }

    @Test("confirmation is nil for unknown id") @MainActor
    func confirmationNilForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.confirmation == nil)
    }

    // MARK: Detail list

    @Test("detailRows has 5 rows for 'booking-tap201' (from detail)") @MainActor
    func detailRowsCountForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.detailRows.count == 5)
    }

    @Test("detailRows is empty for 'booking-castelo' (no detail)") @MainActor
    func detailRowsEmptyForNonDetailBooking() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.detailRows.isEmpty)
    }

    // MARK: Placed chip

    @Test("placedLabel is 'Placed on Day 4 · Sat, Aug 29' for 'booking-tap201'") @MainActor
    func placedLabelForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.placedLabel == "Placed on Day 4 · Sat, Aug 29")
    }

    @Test("placedLabel is nil for 'booking-castelo' (no detail)") @MainActor
    func placedLabelNilForNonDetailBooking() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.placedLabel == nil)
    }

    // MARK: Action bar (access pass drives CTA)

    @Test("hasAccessPass is true for 'booking-tap201' (has accessPass in seed)") @MainActor
    func hasAccessPassTrueForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.hasAccessPass == true)
    }

    @Test("hasAccessPass is false for 'booking-castelo' (no accessPass)") @MainActor
    func hasAccessPassFalseForCastelo() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.hasAccessPass == false)
    }

    @Test("hasAccessPass is false for unknown id") @MainActor
    func hasAccessPassFalseForUnknownID() {
        let p = makePresenter(bookingID: "booking-does-not-exist")
        #expect(p.hasAccessPass == false)
    }

    @Test("accessPass is non-nil for 'booking-tap201'") @MainActor
    func accessPassNonNilForTap201() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.accessPass != nil)
        if let pass = p.accessPass {
            #expect(pass.kindLabel == "Boarding pass")
            #expect(pass.confirmation == "7XQK2M")
        }
    }

    @Test("accessPass is nil for 'booking-castelo'") @MainActor
    func accessPassNilForCastelo() {
        let p = makePresenter(bookingID: "booking-castelo")
        #expect(p.accessPass == nil)
    }

    @Test("showPassTitle == 'Show boarding pass'") @MainActor
    func showPassTitle() {
        let p = makePresenter(bookingID: "booking-tap201")
        #expect(p.showPassTitle == "Show boarding pass")
    }
}

// MARK: - AddToWalletPresenter

@Suite("AddToWalletPresenter derivation")
struct AddToWalletPresenterTests {

    // MARK: Factory helper

    @MainActor
    private func makePresenter(
        isAdding: Bool = false,
        writeError: WriteError? = nil
    ) -> AddToWalletPresenter {
        let store = AppStore.preview(wallet: SampleData.walletDTO())
        store.writeError = writeError
        return AddToWalletPresenter(store: store, isAdding: isAdding)
    }

    // MARK: Method rows (Phase A)

    @Test("methodTitle is 'Add to wallet'") @MainActor
    func methodTitleIsCopy() {
        let p = makePresenter()
        #expect(p.methodTitle == "Add to wallet")
    }

    @Test("methodSubtitle is non-empty") @MainActor
    func methodSubtitleNonEmpty() {
        let p = makePresenter()
        #expect(!p.methodSubtitle.isEmpty)
    }

    @Test("methods has exactly 3 rows") @MainActor
    func methodsHasThreeRows() {
        let p = makePresenter()
        #expect(p.methods.count == 3)
    }

    @Test("methods order: forward, scan, photo") @MainActor
    func methodsOrder() {
        let p = makePresenter()
        let ids = p.methods.map(\.id)
        #expect(ids == ["forward", "scan", "photo"])
    }

    @Test("methods: forward row is prominent") @MainActor
    func methodsForwardIsProminent() {
        let p = makePresenter()
        let forwardRow = p.methods.first(where: { $0.id == "forward" })
        #expect(forwardRow?.prominent == true)
    }

    @Test("methods: scan and photo rows are not prominent") @MainActor
    func methodsOthersNotProminent() {
        let p = makePresenter()
        let scan = p.methods.first(where: { $0.id == "scan" })
        let photo = p.methods.first(where: { $0.id == "photo" })
        #expect(scan?.prominent == false)
        #expect(photo?.prominent == false)
    }

    // MARK: Forward-to-email

    @Test("forwardKey is 'Or forward email to'") @MainActor
    func forwardKeyLabel() {
        let p = makePresenter()
        #expect(p.forwardKey == "Or forward email to")
    }

    @Test("forwardEmail is 'wallet@aitravel.app'") @MainActor
    func forwardEmail() {
        let p = makePresenter()
        #expect(p.forwardEmail == "wallet@aitravel.app")
    }

    // MARK: Phase B copy

    @Test("reviewTitle is 'Check the details'") @MainActor
    func reviewTitleIsCopy() {
        let p = makePresenter()
        #expect(p.reviewTitle == "Check the details")
    }

    @Test("reviewVoiceLine is 'Read from your screenshot'") @MainActor
    func reviewVoiceLine() {
        let p = makePresenter()
        #expect(p.reviewVoiceLine == "Read from your screenshot")
    }

    @Test("verifyTag is 'verify'") @MainActor
    func verifyTagIsCopy() {
        let p = makePresenter()
        #expect(p.verifyTag == "verify")
    }

    @Test("confirmTitle is 'Add to wallet'") @MainActor
    func confirmTitleIsCopy() {
        let p = makePresenter()
        #expect(p.confirmTitle == "Add to wallet")
    }

    @Test("editTitle is 'Edit details'") @MainActor
    func editTitleIsCopy() {
        let p = makePresenter()
        #expect(p.editTitle == "Edit details")
    }

    // MARK: Review fields

    @Test("reviewFields has exactly 5 fields") @MainActor
    func reviewFieldsCount() {
        let p = makePresenter()
        #expect(p.reviewFields.count == 5)
    }

    @Test("reviewFields order: type, name, when, where, confirmation") @MainActor
    func reviewFieldsOrder() {
        let p = makePresenter()
        let keys = p.reviewFields.map(\.key)
        #expect(keys == ["type", "name", "when", "where", "confirmation"])
    }

    @Test("reviewFields 'when' has lowConfidence == true") @MainActor
    func reviewFieldsWhenLowConfidence() {
        let p = makePresenter()
        let whenField = p.reviewFields.first(where: { $0.key == "when" })
        #expect(whenField != nil)
        #expect(whenField?.lowConfidence == true,
                "the 'when' field must be low-confidence (verify tag)")
    }

    @Test("reviewFields 'confirmation' has isMono == true") @MainActor
    func reviewFieldsConfirmationIsMono() {
        let p = makePresenter()
        let confField = p.reviewFields.first(where: { $0.key == "confirmation" })
        #expect(confField != nil)
        #expect(confField?.isMono == true,
                "the confirmation field must be rendered mono")
    }

    @Test("reviewFields 'type' has bookingType == .activity (the orphan's type)") @MainActor
    func reviewFieldsTypeBookingType() {
        let p = makePresenter()
        let typeField = p.reviewFields.first(where: { $0.key == "type" })
        #expect(typeField?.bookingType == .activity)
    }

    @Test("reviewFields 'name' value is 'Fado at Tasca do Chico'") @MainActor
    func reviewFieldsNameValue() {
        let p = makePresenter()
        let nameField = p.reviewFields.first(where: { $0.key == "name" })
        #expect(nameField?.value == "Fado at Tasca do Chico")
    }

    @Test("reviewFields 'confirmation' value is 'TDC-8841'") @MainActor
    func reviewFieldsConfirmationValue() {
        let p = makePresenter()
        let confField = p.reviewFields.first(where: { $0.key == "confirmation" })
        #expect(confField?.value == "TDC-8841")
    }

    // MARK: Write target derivation

    /// orphanBookingID == "booking-fado-orphan" — the first unplaced booking in the seed.
    @Test("orphanBookingID == 'booking-fado-orphan'") @MainActor
    func orphanBookingID() {
        let p = makePresenter()
        #expect(p.orphanBookingID == "booking-fado-orphan")
    }

    /// suggestedDay == 2 — the first today/now day (Day 2 has .now/.today bookings).
    @Test("suggestedDay == 2 (first today/now day from the seeded statuses)") @MainActor
    func suggestedDay() {
        let p = makePresenter()
        #expect(p.suggestedDay == 2)
    }

    // MARK: Loading state

    @Test("isLoading is false when isAdding is false") @MainActor
    func isLoadingFalseWhenNotAdding() {
        let p = makePresenter(isAdding: false)
        #expect(p.isLoading == false)
    }

    @Test("isLoading is true when isAdding is true") @MainActor
    func isLoadingTrueWhenAdding() {
        let p = makePresenter(isAdding: true)
        #expect(p.isLoading == true)
    }

    // MARK: Write error

    @Test("writeErrorMessage is nil when store.writeError is nil") @MainActor
    func writeErrorMessageNilWhenNoError() {
        let p = makePresenter(writeError: nil)
        #expect(p.writeErrorMessage == nil)
    }

    @Test("writeErrorMessage is non-nil when store.writeError is .placeOrphan") @MainActor
    func writeErrorMessageNonNilOnPlaceOrphanError() {
        let p = makePresenter(writeError: .placeOrphan)
        #expect(p.writeErrorMessage != nil)
        if let msg = p.writeErrorMessage {
            #expect(!msg.isEmpty)
        }
    }

    @Test("writeErrorMessage is non-nil when store.writeError is .addPlace (any error shows a banner)") @MainActor
    func writeErrorMessageNonNilOnAddPlaceError() {
        let p = makePresenter(writeError: .addPlace)
        // addPlace uses bannerMessage which is always non-nil for any WriteError case
        #expect(p.writeErrorMessage != nil)
    }
}
