/*
 Layer 1 — Presenter derivation tests for SavedListPresenter, PlaceDetailPresenter, AddPlacePresenter.

 Layer / scope:
   - L1: stateless value-over-(store, …ids) derivation. No network, no async.
   - Seeds a store via AppStore.preview(savedPlaces:) from SampleData.savedPlacesDTO() /
     emptySavedPlacesDTO(). Never SampleData.savedPlaces() in arguments position (it's
     @MainActor — §6.6 "expression is 'async' but not marked 'await'").

 Rules:
   - No Date() / Calendar.current / Locale.current.
   - Fixtures by stable id ("place-cevicheria"), never array position.
   - Reference model fields asserted individually; no == between two constructed instances.
   - @Test @MainActor throughout (presenters read @Observable @MainActor AppStore).
   - @Test(arguments:) uses a nonisolated tag enum; MainActor values are built inside the body.

 SavedListPresenter states covered:
   1. Empty (no places) → wayToSave × 3, isEmpty == true, emptyTitle/emptyBody non-empty
   2. Populated, byCategory → categoryGroups order (Eat → Drink → Stay → Do → Shop),
      counts match seed, place-cevicheria in Eat group
   3. Populated, bySource → sourceGroups; @saltinmycoffee "Lisbon in 48 hours" has 3 children
   4. Search-active (query non-empty) → searchGroups, fuzzy match count, isSearching == true

 PlaceDetailPresenter:
   - title/displayName/category/locationLine for a known id
   - provenance derived correctly (handle, meta with clip title + timestamp, quote)
   - facts count matches seed
   - address non-nil for a place with an address
   - hasPlace == false for an unknown id

 AddPlacePresenter:
   - methods returns 3 rows, first is prominent (reel), id ordering reel/screenshot/search
   - showsClipboard true with a detected URL, false with nil
   - clipboardURL returns the detected URL
   - writeErrorMessage is nil when store.writeError == nil
   - writeErrorMessage is non-nil when store.writeError == .addPlace
   - isLoading reflects the isAdding arg
*/

import Testing
@testable import AppTemplate

// MARK: - SavedListPresenter

@Suite("SavedListPresenter derivation")
struct SavedListPresenterTests {

    // MARK: B3 factory helpers

    /// Populated store (24 places), default mode=byCategory, no query.
    @MainActor
    private func makePopulatedStore() -> AppStore {
        AppStore.preview(savedPlaces: SampleData.savedPlacesDTO())
    }

    /// Empty store (0 places).
    @MainActor
    private func makeEmptyStore() -> AppStore {
        AppStore.preview(savedPlaces: SampleData.emptySavedPlacesDTO())
    }

    // MARK: - State 1: empty

    @Test("isEmpty is true when there are no places") @MainActor
    func isEmptyWhenNoPlaces() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        #expect(p.isEmpty == true)
    }

    @Test("isEmpty is false when places are loaded") @MainActor
    func isEmptyFalseWhenPopulated() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store)
        #expect(p.isEmpty == false)
    }

    @Test("wayToSave has exactly 3 rows") @MainActor
    func wayToSaveHasThreeRows() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        #expect(p.wayToSave.count == 3)
    }

    @Test("wayToSave: first row is reel (prominent), then screenshot, then search") @MainActor
    func wayToSaveOrder() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        let ids = p.wayToSave.map(\.id)
        #expect(ids == ["reel", "screenshot", "search"])
    }

    @Test("wayToSave: reel row is prominent") @MainActor
    func wayToSaveReelProminent() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        let reelRow = p.wayToSave.first(where: { $0.id == "reel" })
        #expect(reelRow?.prominent == true)
    }

    @Test("wayToSave: screenshot and search rows are not prominent") @MainActor
    func wayToSaveOthersNotProminent() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        let screenshot = p.wayToSave.first(where: { $0.id == "screenshot" })
        let search = p.wayToSave.first(where: { $0.id == "search" })
        #expect(screenshot?.prominent == false)
        #expect(search?.prominent == false)
    }

    @Test("emptyTitle is non-empty") @MainActor
    func emptyTitleNonEmpty() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        #expect(!p.emptyTitle.isEmpty)
    }

    @Test("emptyBody is non-empty") @MainActor
    func emptyBodyNonEmpty() {
        let store = makeEmptyStore()
        let p = SavedListPresenter(store: store)
        #expect(!p.emptyBody.isEmpty)
    }

    // MARK: - State 2: populated, byCategory

    @Test("categoryGroups has 5 groups for the populated seed (Eat/Drink/Stay/Do/Shop)") @MainActor
    func categoryGroupsCountPopulated() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        #expect(p.categoryGroups.count == 5)
    }

    @Test("categoryGroups ordered Eat → Drink → Stay → Do → Shop") @MainActor
    func categoryGroupsOrder() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let cats = p.categoryGroups.map(\.category)
        #expect(cats == [.eat, .drink, .stay, .do, .shop])
    }

    @Test("categoryGroups Eat has 7 rows (seed: Eat×7)") @MainActor
    func categoryGroupsEatCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let eatGroup = p.categoryGroups.first(where: { $0.category == .eat })
        #expect(eatGroup != nil)
        if let eatGroup {
            #expect(eatGroup.count == 7)
            #expect(eatGroup.rows.count == 7)
        }
    }

    @Test("categoryGroups Drink has 4 rows (seed: Drink×4)") @MainActor
    func categoryGroupsDrinkCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let drinkGroup = p.categoryGroups.first(where: { $0.category == .drink })
        #expect(drinkGroup != nil)
        if let drinkGroup {
            #expect(drinkGroup.count == 4)
        }
    }

    @Test("categoryGroups Stay has 5 rows (seed: Stay×5)") @MainActor
    func categoryGroupsStayCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let stayGroup = p.categoryGroups.first(where: { $0.category == .stay })
        #expect(stayGroup != nil)
        if let stayGroup {
            #expect(stayGroup.count == 5)
        }
    }

    @Test("categoryGroups Do has 6 rows (seed: Do×6)") @MainActor
    func categoryGroupsDoCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let doGroup = p.categoryGroups.first(where: { $0.category == .do })
        #expect(doGroup != nil)
        if let doGroup {
            #expect(doGroup.count == 6)
        }
    }

    @Test("categoryGroups Shop has 2 rows (seed: Shop×2)") @MainActor
    func categoryGroupsShopCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let shopGroup = p.categoryGroups.first(where: { $0.category == .shop })
        #expect(shopGroup != nil)
        if let shopGroup {
            #expect(shopGroup.count == 2)
        }
    }

    @Test("categoryGroups Eat contains place-cevicheria row") @MainActor
    func categoryGroupsEatContainsCevicheria() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let eatGroup = p.categoryGroups.first(where: { $0.category == .eat })
        #expect(eatGroup != nil)
        if let eatGroup {
            let cevicheriaRow = eatGroup.rows.first(where: { $0.id == "place-cevicheria" })
            #expect(cevicheriaRow != nil, "place-cevicheria must appear in the Eat category group")
            if let row = cevicheriaRow {
                #expect(row.name == "A Cevicheria")
                // Trailing is .chevron in the by-category list
                #expect(row.trailing == .chevron)
            }
        }
    }

    @Test("categoryGroups Eat label is 'Eat'") @MainActor
    func categoryGroupsEatLabel() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let eatGroup = p.categoryGroups.first(where: { $0.category == .eat })
        #expect(eatGroup?.label == "Eat")
    }

    // Frozen-literal oracle: 7 eat-places → "7 places"
    @Test("categoryGroups Eat countLabel is frozen literal '7 places'") @MainActor
    func categoryGroupsEatCountLabel() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        let eatGroup = p.categoryGroups.first(where: { $0.category == .eat })
        #expect(eatGroup?.countLabel == "7 places")
    }

    @Test("categoryFilter narrows to a single category group") @MainActor
    func categoryFilterNarrowsToSingleGroup() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory, categoryFilter: .drink)
        #expect(p.categoryGroups.count == 1)
        #expect(p.categoryGroups.first?.category == .drink)
    }

    // MARK: - Hero copy

    @Test("eyebrow is 'Wishlist'") @MainActor
    func eyebrowIsWishlist() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store)
        #expect(p.eyebrow == "Wishlist")
    }

    @Test("title is 'Places you've saved' in byCategory mode") @MainActor
    func titleByCategoryMode() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        #expect(p.title == "Places you've saved")
    }

    @Test("title is 'Saved by source' in bySource mode") @MainActor
    func titleBySourceMode() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        #expect(p.title == "Saved by source")
    }

    // Frozen-literal oracle: 24 places · 3 cities (Lisbon, Tokyo, Porto) · from 9 sources
    @Test("headerCounts frozen literal '24 places · 3 cities · from 9 sources' — byCategory") @MainActor
    func headerCountsByCategoryFrozenLiteral() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .byCategory)
        #expect(p.headerCounts == "24 places · 3 cities · from 9 sources")
    }

    // MARK: - Filters: distinctCityNames / cityOptions

    @Test("distinctCityNames has 3 entries (Lisbon, Tokyo, Porto)") @MainActor
    func distinctCityNamesCount() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store)
        #expect(p.distinctCityNames.count == 3)
    }

    @Test("distinctCityNames includes Lisbon, Tokyo, Porto") @MainActor
    func distinctCityNamesContents() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store)
        #expect(p.distinctCityNames.contains("Lisbon"))
        #expect(p.distinctCityNames.contains("Tokyo"))
        #expect(p.distinctCityNames.contains("Porto"))
    }

    @Test("cityOptions includes All sentinel (id='all') as first option") @MainActor
    func cityOptionsAllSentinel() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store)
        let first = p.cityOptions.first
        #expect(first?.id == "all")
        #expect(first?.cityName == nil)
    }

    // MARK: - State 3: populated, bySource

    @Test("sourceGroups is non-empty for the populated seed") @MainActor
    func sourceGroupsNonEmpty() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        #expect(!p.sourceGroups.isEmpty)
    }

    // The @saltinmycoffee "Lisbon in 48 hours" reel holds 3 places in the seed:
    // A Cevicheria (0:42), Park Bar (1:15), Time Out Market (2:03).
    @Test("sourceGroups: @saltinmycoffee 'Lisbon in 48 hours' card has 3 child rows") @MainActor
    func sourceGroupsLisbonReelHasThreeChildren() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        // The source key for reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours")
        let lisbonCard = p.sourceGroups.first(where: { $0.id == "reel:saltinmycoffee:Lisbon in 48 hours" })
        #expect(lisbonCard != nil, "reel:saltinmycoffee:Lisbon in 48 hours card must exist in sourceGroups")
        if let card = lisbonCard {
            #expect(card.places.count == 3,
                    "saltinmycoffee Lisbon reel must have 3 child rows; got \(card.places.count)")
            let childIDs = card.places.map(\.id)
            #expect(childIDs.contains("place-cevicheria"))
            #expect(childIDs.contains("place-park-bar"))
            #expect(childIDs.contains("place-timeout-market"))
        }
    }

    // The @tokyo.eats reel "Tokyo eats you can't miss" holds 4 places in the seed.
    @Test("sourceGroups: @tokyo.eats card has 4 child rows") @MainActor
    func sourceGroupsTokyoReelHasFourChildren() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        let tokyoCard = p.sourceGroups.first(where: { $0.id == "reel:tokyo.eats:Tokyo eats you can't miss" })
        #expect(tokyoCard != nil, "reel:tokyo.eats card must exist in sourceGroups")
        if let card = tokyoCard {
            #expect(card.places.count == 4,
                    "tokyo.eats reel must have 4 child rows; got \(card.places.count)")
        }
    }

    @Test("sourceGroups: reel card has non-nil footHint when it has > 1 child") @MainActor
    func sourceGroupsReelFootHintPresent() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        let lisbonCard = p.sourceGroups.first(where: { $0.id == "reel:saltinmycoffee:Lisbon in 48 hours" })
        #expect(lisbonCard?.footHint != nil, "multi-place reel card must have a footHint")
    }

    @Test("sourceGroups: search card exists (place-bar-trench, place-cantinho-avillez, place-bairro-alto-hotel)") @MainActor
    func sourceGroupsSearchCardExists() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, mode: .bySource)
        let searchCard = p.sourceGroups.first(where: { $0.id == "search" })
        #expect(searchCard != nil, "search source card must exist in sourceGroups")
        if let card = searchCard {
            let childIDs = card.places.map(\.id)
            #expect(childIDs.contains("place-bar-trench"))
            #expect(childIDs.contains("place-cantinho-avillez"))
            #expect(childIDs.contains("place-bairro-alto-hotel"))
        }
    }

    // MARK: - State 4: search-active

    @Test("isSearching is false for empty query") @MainActor
    func isSearchingFalseEmptyQuery() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "")
        #expect(p.isSearching == false)
    }

    @Test("isSearching is false for whitespace-only query") @MainActor
    func isSearchingFalseWhitespace() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "   ")
        #expect(p.isSearching == false)
    }

    @Test("isSearching is true for non-empty query") @MainActor
    func isSearchingTrueWithQuery() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "ramen")
        #expect(p.isSearching == true)
    }

    @Test("searchGroups: query 'ramen' matches Afuri Ramen (direct, name match)") @MainActor
    func searchGroupsRamenDirectMatch() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "ramen")
        let matchesGroup = p.searchGroups.first(where: { $0.id == "matches" })
        #expect(matchesGroup != nil, "should have a 'matches' group for 'ramen'")
        if let group = matchesGroup {
            let ids = group.rows.map(\.id)
            #expect(ids.contains("place-afuri-ramen"))
        }
    }

    @Test("searchGroups: query 'ramen' rows have trailing .category") @MainActor
    func searchGroupsRamenTrailingCategory() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "ramen")
        let matchesGroup = p.searchGroups.first(where: { $0.id == "matches" })
        if let group = matchesGroup {
            let afuriRow = group.rows.first(where: { $0.id == "place-afuri-ramen" })
            #expect(afuriRow?.trailing == .category, "search rows must use .category trailing")
        }
    }

    @Test("searchGroups: query 'ceviche' matches A Cevicheria (name match)") @MainActor
    func searchGroupsCevicheMatch() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "ceviche")
        let matchesGroup = p.searchGroups.first(where: { $0.id == "matches" })
        #expect(matchesGroup != nil)
        if let group = matchesGroup {
            let ids = group.rows.map(\.id)
            #expect(ids.contains("place-cevicheria"))
        }
    }

    @Test("searchGroups: query that matches nothing gives no groups") @MainActor
    func searchGroupsNoMatch() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "zzznoplacezzzxxx")
        #expect(p.searchGroups.isEmpty)
        #expect(p.searchHasResults == false)
    }

    @Test("searchGroups: matches group subtitle mentions cities count") @MainActor
    func searchGroupsMatchesSubtitleMentionsCities() {
        // "cevicheria" matches exactly 1 place (A Cevicheria in Lisbon) → "across 1 city"
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "cevicheria")
        let matchesGroup = p.searchGroups.first(where: { $0.id == "matches" })
        #expect(matchesGroup?.subtitle == "across 1 city")
    }

    @Test("searchGroups: searchVoice eyebrow is 'Matching by vibe'") @MainActor
    func searchVoiceEyebrow() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "rooftop")
        #expect(p.searchVoice.eyebrow == "Matching by vibe")
    }

    @Test("searchGroups: searchVoice line contains the query term") @MainActor
    func searchVoiceLineContainsQuery() {
        let store = makePopulatedStore()
        let p = SavedListPresenter(store: store, query: "rooftop")
        #expect(p.searchVoice.line.contains("rooftop"))
    }
}

// MARK: - PlaceDetailPresenter

@Suite("PlaceDetailPresenter derivation")
struct PlaceDetailPresenterTests {

    // MARK: B3 factory helper

    /// Build a PlaceDetailPresenter for a given place id over the populated seed.
    @MainActor
    private func makePresenter(id: String) -> PlaceDetailPresenter {
        let store = AppStore.preview(savedPlaces: SampleData.savedPlacesDTO())
        return PlaceDetailPresenter(store: store, placeID: id)
    }

    // MARK: Resolution

    @Test("hasPlace is true for known id 'place-cevicheria'") @MainActor
    func hasPlaceTrueForKnownID() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.hasPlace == true)
    }

    @Test("hasPlace is false for unknown id") @MainActor
    func hasPlaceFalseForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.hasPlace == false)
    }

    // MARK: Title block

    @Test("title is place name for 'place-cevicheria'") @MainActor
    func titleForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.title == "A Cevicheria")
    }

    @Test("title is empty string for unknown id") @MainActor
    func titleEmptyForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.title == "")
    }

    @Test("displayName equals title for 'place-cevicheria'") @MainActor
    func displayNameEqualsTitleForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.displayName == p.title)
    }

    @Test("category is .eat for 'place-cevicheria'") @MainActor
    func categoryForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.category == .eat)
    }

    @Test("category is nil for unknown id") @MainActor
    func categoryNilForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.category == nil)
    }

    @Test("locationLine contains neighborhood and city for 'place-cevicheria'") @MainActor
    func locationLineForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        // Seed: neighborhood="Príncipe Real", cityName="Lisbon" → "Príncipe Real · Lisbon"
        #expect(p.locationLine.contains("Príncipe Real"))
        #expect(p.locationLine.contains("Lisbon"))
    }

    @Test("locationLine is empty for unknown id") @MainActor
    func locationLineEmptyForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.locationLine == "")
    }

    // MARK: Provenance card

    @Test("provenance is non-nil for 'place-cevicheria' (has provenance in seed)") @MainActor
    func provenanceNonNilForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.provenance != nil)
    }

    @Test("provenance.sourceHandle is '@saltinmycoffee' for 'place-cevicheria'") @MainActor
    func provenanceHandleForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        // Seed: sourceHandle="saltinmycoffee" (no @); handle() normalises → "@saltinmycoffee"
        #expect(p.provenance?.sourceHandle == "@saltinmycoffee")
    }

    @Test("provenance.meta contains 'Reel' for 'place-cevicheria' (reel source)") @MainActor
    func provenanceMetaContainsReelForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        let meta = p.provenance?.meta
        #expect(meta != nil)
        if let meta {
            #expect(meta.contains("Reel"))
        }
    }

    @Test("provenance.meta contains clip title 'Lisbon in 48 hours' for 'place-cevicheria'") @MainActor
    func provenanceMetaContainsClipTitle() {
        let p = makePresenter(id: "place-cevicheria")
        let meta = p.provenance?.meta
        #expect(meta?.contains("Lisbon in 48 hours") == true)
    }

    @Test("provenance.meta contains timestamp '0:42' for 'place-cevicheria'") @MainActor
    func provenanceMetaContainsTimestamp() {
        let p = makePresenter(id: "place-cevicheria")
        let meta = p.provenance?.meta
        #expect(meta?.contains("0:42") == true)
    }

    @Test("provenance.quote is non-nil and non-empty for 'place-cevicheria'") @MainActor
    func provenanceQuoteForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.provenance?.quote != nil)
        if let quote = p.provenance?.quote {
            #expect(!quote.isEmpty)
        }
    }

    @Test("provenance is nil for 'place-cantinho-avillez' (search source, no provenance)") @MainActor
    func provenanceNilForSearchPlace() {
        let p = makePresenter(id: "place-cantinho-avillez")
        // Seed: search source, no provenance field set
        #expect(p.provenance == nil)
    }

    // MARK: Facts grid

    @Test("facts has 3 entries for 'place-cevicheria' (Hours, Price, Cuisine)") @MainActor
    func factsCountForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.facts.count == 3)
    }

    @Test("facts first entry key is 'Hours' for 'place-cevicheria'") @MainActor
    func factsFirstKeyForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.facts.first?.key == "Hours")
    }

    @Test("facts is empty for unknown id") @MainActor
    func factsEmptyForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.facts.isEmpty)
    }

    // MARK: Map snippet

    @Test("address is non-nil for 'place-cevicheria' (has addressLine in seed)") @MainActor
    func addressNonNilForCevicheria() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.address != nil)
        if let address = p.address {
            #expect(address.contains("Príncipe Real"))
        }
    }

    @Test("address is nil for unknown id") @MainActor
    func addressNilForUnknownID() {
        let p = makePresenter(id: "place-does-not-exist")
        #expect(p.address == nil)
    }

    // MARK: Action bar

    @Test("addToTripTitle is 'Add to a trip'") @MainActor
    func addToTripTitle() {
        let p = makePresenter(id: "place-cevicheria")
        #expect(p.addToTripTitle == "Add to a trip")
    }
}

// MARK: - AddPlacePresenter

@Suite("AddPlacePresenter derivation")
struct AddPlacePresenterTests {

    // MARK: B3 factory helper

    @MainActor
    private func makePresenter(
        detectedURL: String? = nil,
        isAdding: Bool = false,
        writeError: WriteError? = nil
    ) -> AddPlacePresenter {
        let store = AppStore.preview(savedPlaces: SampleData.savedPlacesDTO())
        store.writeError = writeError
        return AddPlacePresenter(store: store, detectedURL: detectedURL, isAdding: isAdding)
    }

    // MARK: Header copy

    @Test("title is 'Save a place'") @MainActor
    func titleIsSaveAPlace() {
        let p = makePresenter()
        #expect(p.title == "Save a place")
    }

    @Test("subtitle is non-empty") @MainActor
    func subtitleNonEmpty() {
        let p = makePresenter()
        #expect(!p.subtitle.isEmpty)
    }

    // MARK: Method rows

    @Test("methods has exactly 3 rows") @MainActor
    func methodsHasThreeRows() {
        let p = makePresenter()
        #expect(p.methods.count == 3)
    }

    @Test("methods order: reel, screenshot, search") @MainActor
    func methodsOrder() {
        let p = makePresenter()
        let ids = p.methods.map(\.id)
        #expect(ids == ["reel", "screenshot", "search"])
    }

    @Test("methods: reel row is prominent") @MainActor
    func methodsReelIsProminent() {
        let p = makePresenter()
        let reelRow = p.methods.first(where: { $0.id == "reel" })
        #expect(reelRow?.prominent == true)
    }

    @Test("methods: screenshot and search rows are not prominent") @MainActor
    func methodsOthersNotProminent() {
        let p = makePresenter()
        let screenshot = p.methods.first(where: { $0.id == "screenshot" })
        let search = p.methods.first(where: { $0.id == "search" })
        #expect(screenshot?.prominent == false)
        #expect(search?.prominent == false)
    }

    // MARK: Clipboard affordance

    @Test("showsClipboard is false when detectedURL is nil") @MainActor
    func showsClipboardFalseWhenNil() {
        let p = makePresenter(detectedURL: nil)
        #expect(p.showsClipboard == false)
    }

    @Test("showsClipboard is true when detectedURL is non-empty") @MainActor
    func showsClipboardTrueWithURL() {
        let p = makePresenter(detectedURL: SampleData.stubbedClipboardURL)
        #expect(p.showsClipboard == true)
    }

    @Test("clipboardURL returns the detected URL when set") @MainActor
    func clipboardURLReturnsDetectedURL() {
        let url = SampleData.stubbedClipboardURL
        let p = makePresenter(detectedURL: url)
        #expect(p.clipboardURL == url)
    }

    @Test("clipboardURL returns empty string when detectedURL is nil") @MainActor
    func clipboardURLEmptyWhenNil() {
        let p = makePresenter(detectedURL: nil)
        #expect(p.clipboardURL == "")
    }

    @Test("clipboardKey is 'On your clipboard'") @MainActor
    func clipboardKeyLabel() {
        let p = makePresenter()
        #expect(p.clipboardKey == "On your clipboard")
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

    @Test("writeErrorMessage is non-nil when store.writeError is .addPlace") @MainActor
    func writeErrorMessageNonNilOnAddPlaceError() {
        let p = makePresenter(writeError: .addPlace)
        #expect(p.writeErrorMessage != nil)
        if let msg = p.writeErrorMessage {
            #expect(!msg.isEmpty)
        }
    }
}
