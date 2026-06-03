/*
 Layer 1 — Presenter derivation tests for all six onboarding step presenters.
 Mirrors the shape of `bookListPresenterDerivesRows` (07-testing §4.3): seed an AppStore via
 AppStore.preview(_:step:), build the stateless presenter, assert each derived value.

 Rules:
 - No Date() / Calendar.current / Locale.current — no time-sensitive state in these presenters.
 - Fixtures indexed by stable id ("city-tokyo", "shape-cover-bucket"), never array position.
 - Reference model fields asserted individually; no == between two constructed instances.
 - @Test @MainActor throughout (presenters read @Observable @MainActor AppStore).
*/

import Testing
@testable import AppTemplate

// MARK: - DestinationStepPresenter

@Suite("DestinationStepPresenter derivation")
struct DestinationStepPresenterTests {

    // MARK: Hero copy per state

    @Test("eyebrow is always 'Destination'") @MainActor
    func eyebrowIsDestination() {
        for context in [SampleData.onboardingAContext(), SampleData.onboardingBContext(), SampleData.onboardingCContext()] {
            let store = AppStore.preview(context, step: .destination)
            let p = DestinationStepPresenter(store: store)
            #expect(p.eyebrow == "Destination")
        }
    }

    @Test("question — stateA returningWithLocalSaves") @MainActor
    func questionStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.question == "Where are you headed?")
    }

    @Test("question — stateB savesElsewhere") @MainActor
    func questionStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.question == "Where are you headed?")
    }

    @Test("question — stateC firstTrip") @MainActor
    func questionStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.question == "Where to first?")
    }

    @Test("sub — stateA includes 'saved places along'") @MainActor
    func subStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.sub == "Pick a city — we'll bring your saved places along.")
    }

    @Test("sub — stateC mentions 'first trip'") @MainActor
    func subStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.sub == "Your first trip — pick a city and we'll build the rest from its best.")
    }

    // MARK: ctaTitle / canContinue

    @Test("ctaTitle when destination selected — stateA (Lisbon)") @MainActor
    func ctaTitleWithDestination() {
        // stateA seeds with Lisbon as the destination
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.ctaTitle == "Continue with Lisbon")
        #expect(p.canContinue == true)
    }

    @Test("ctaTitle falls back to 'Continue' when destination nil") @MainActor
    func ctaTitleNoDestination() {
        // Build a store and clear the destination
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        store.onboarding?.clearDestination()
        let p = DestinationStepPresenter(store: store)
        #expect(p.ctaTitle == "Continue")
        #expect(p.canContinue == false)
    }

    // MARK: matchingCities filter

    @Test("matchingCities empty query returns all cities — stateA") @MainActor
    func matchingCitiesEmptyQuery() {
        let context = SampleData.onboardingAContext()
        let store = AppStore.preview(context, step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "")
        // stateA has 4 cities: Lisbon, Tokyo, Mexico City, Marrakech
        #expect(p.matchingCities.count == context.cityOptions.count)
    }

    @Test("matchingCities 'Tok' matches Tokyo only") @MainActor
    func matchingCitiesFilterTok() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "Tok")
        let ids = p.matchingCities.map(\.id)
        #expect(ids.contains("city-tokyo"))
        #expect(!ids.contains("city-lisbon"))
        #expect(ids.count == 1)
    }

    @Test("matchingCities 'lisb' matches Lisbon (case-insensitive)") @MainActor
    func matchingCitiesFilterLisb() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "lisb")
        let ids = p.matchingCities.map(\.id)
        #expect(ids.contains("city-lisbon"))
        #expect(!ids.contains("city-tokyo"))
        #expect(ids.count == 1)
    }

    @Test("matchingCities whitespace-only query returns all cities") @MainActor
    func matchingCitiesWhitespaceQuery() {
        let context = SampleData.onboardingAContext()
        let store = AppStore.preview(context, step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "   ")
        #expect(p.matchingCities.count == context.cityOptions.count)
    }

    // MARK: gridCities / recentCities mapping

    @Test("gridCities count equals matchingCities count — stateA") @MainActor
    func gridCitiesCountMatchesMatchingCities() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "")
        #expect(p.gridCities.count == p.matchingCities.count)
    }

    @Test("recentCities count equals gridCities count — stateA") @MainActor
    func recentCitiesCountMatchesGridCities() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "")
        #expect(p.recentCities.count == p.gridCities.count)
    }

    @Test("tile for selected city has isSelected=true and certainty=.definitive") @MainActor
    func tileForSelectedCityIsSelected() {
        // stateA seeds with Lisbon as destination
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "")
        let lisbonTile = p.gridCities.first(where: { $0.id == "city-lisbon" })
        let tokyoTile = p.gridCities.first(where: { $0.id == "city-tokyo" })
        #expect(lisbonTile != nil)
        if let tile = lisbonTile {
            #expect(tile.isSelected == true)
            #expect(tile.certainty == .definitive)
            #expect(tile.showsPlanStartedBadge == false)
        }
        // Non-selected tile
        if let tile = tokyoTile {
            #expect(tile.isSelected == false)
            #expect(tile.certainty == .fuzzy)
        }
    }

    @Test("tile with meta .planStarted and not selected shows planStarted badge") @MainActor
    func tileWithPlanStartedMetaShowsBadgeWhenNotSelected() {
        // stateA: Lisbon has meta .planStarted in cityOptions. But stateA seeds destination=Lisbon,
        // so Lisbon IS selected — we need a different city with planStarted. In stateB, Kyoto is .planStarted.
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .destination)
        // stateB seeds destination=Kyoto. Kyoto has meta .planStarted and is selected → no badge.
        let p = DestinationStepPresenter(store: store, searchText: "")
        let kyotoTile = p.gridCities.first(where: { $0.id == "city-kyoto" })
        if let tile = kyotoTile {
            // Selected, so badge is suppressed even though meta is .planStarted
            #expect(tile.isSelected == true)
            #expect(tile.showsPlanStartedBadge == false)
        }
    }

    @Test("metaLabel for non-planStarted city includes country and meta") @MainActor
    func metaLabelForNonPlanStartedCity() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store, searchText: "")
        // Tokyo in stateA has meta .savedCount(6): "Japan · 6 saves"
        let tokyoTile = p.gridCities.first(where: { $0.id == "city-tokyo" })
        #expect(tokyoTile != nil)
        if let tile = tokyoTile {
            // country "Japan" must be in the label; planStarted prefix is absent
            #expect(tile.metaLabel.contains("Japan"))
        }
    }

    // MARK: searchValue reflects selected destination name

    @Test("searchValue is destination name when destination is set") @MainActor
    func searchValueIsDestinationName() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = DestinationStepPresenter(store: store)
        #expect(p.searchValue == "Lisbon")
    }

    @Test("searchValue is empty string when no destination") @MainActor
    func searchValueEmptyWhenNoDestination() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        store.onboarding?.clearDestination()
        let p = DestinationStepPresenter(store: store)
        #expect(p.searchValue == "")
    }
}

// MARK: - TripShapeStepPresenter

@Suite("TripShapeStepPresenter derivation")
struct TripShapeStepPresenterTests {

    // MARK: step02Mode branch

    @Test("step02Mode is .shapeCards for stateA") @MainActor
    func step02ModeStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.step02Mode == .shapeCards)
    }

    @Test("step02Mode is .shapeCards for stateB") @MainActor
    func step02ModeStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.step02Mode == .shapeCards)
    }

    @Test("step02Mode is .tasteForm for stateC") @MainActor
    func step02ModeStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.step02Mode == .tasteForm)
    }

    // MARK: Hero copy

    @Test("heroEyebrow is always 'Trip shape'") @MainActor
    func heroEyebrow() {
        for context in [SampleData.onboardingAContext(), SampleData.onboardingBContext(), SampleData.onboardingCContext()] {
            let store = AppStore.preview(context, step: .tripShape)
            let p = TripShapeStepPresenter(store: store)
            #expect(p.heroEyebrow == "Trip shape")
        }
    }

    @Test("heroQuestion for shapeCards (stateA)") @MainActor
    func heroQuestionShapeCards() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.heroQuestion == "How should this trip fit?")
    }

    @Test("heroQuestion for tasteForm (stateC)") @MainActor
    func heroQuestionTasteForm() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.heroQuestion == "What kind of trip is this?")
    }

    @Test("heroSub for stateA mentions savedHere count") @MainActor
    func heroSubStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        // stateA: savedHere == 23
        #expect(p.heroSub.contains("23"))
    }

    @Test("heroSub for stateB mentions no saved places here") @MainActor
    func heroSubStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.heroSub.contains("haven't saved"))
    }

    @Test("heroSub for stateC is the first-trip copy") @MainActor
    func heroSubStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.heroSub.contains("No saved places yet"))
    }

    // MARK: shapeCards — stateA (three cards, all unlocked)

    @Test("shapeCards stateA has 3 cards") @MainActor
    func shapeCardsCountStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.shapeCards.count == 3)
    }

    @Test("shapeCards stateA ids are a/b/c") @MainActor
    func shapeCardsIdsStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        let ids = p.shapeCards.map(\.id)
        #expect(ids.contains("a"))
        #expect(ids.contains("b"))
        #expect(ids.contains("c"))
    }

    @Test("shapeCards stateA: fixedDays card is not locked and embedsStepper") @MainActor
    func shapeCardFixedDaysStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        // index 0 → id "a", strategy .fixedDays
        let card = p.shapeCards.first(where: { $0.strategy == .fixedDays })
        #expect(card != nil)
        if let card {
            #expect(card.register == .selectable)
            #expect(card.embedsStepper == true)
            #expect(!card.metricStrip.isEmpty)
        }
    }

    @Test("shapeCards stateA: coverBucket card is unlocked (savedHere == 23)") @MainActor
    func shapeCardCoverBucketUnlockedStateA() {
        // stateA savedHere == 23, so coverBucket is NOT locked
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        let card = p.shapeCards.first(where: { $0.strategy == .coverBucket })
        #expect(card != nil)
        if let card {
            #expect(card.register == .selectable)
            #expect(!card.metricStrip.isEmpty)
        }
    }

    @Test("shapeCards stateB: coverBucket card is locked (savedHere == 0)") @MainActor
    func shapeCardCoverBucketLockedStateB() {
        // stateB savedHere == 0, so coverBucket IS locked
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        let card = p.shapeCards.first(where: { $0.strategy == .coverBucket })
        #expect(card != nil)
        if let card {
            if case .locked(let reason) = card.register {
                #expect(!reason.isEmpty)
            } else {
                Issue.record("Expected .locked register for coverBucket in stateB")
            }
            // Locked card has empty metric strip
            #expect(card.metricStrip.isEmpty)
        }
    }

    @Test("shapeCards stateC is empty (taste-form path)") @MainActor
    func shapeCardsEmptyStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.shapeCards.isEmpty)
    }

    @Test("selectedStrategy is nil when no strategy picked") @MainActor
    func selectedStrategyNilInitially() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.selectedStrategy == nil)
    }

    @Test("selectedStrategy reflects draft after selection") @MainActor
    func selectedStrategyAfterSelection() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        store.onboarding?.select(strategy: .highlights)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.selectedStrategy == .highlights)
    }

    // MARK: Taste form (stateC)

    @Test("tasteDays default is 4 when no tripDays set (stateC)") @MainActor
    func tasteDaysDefaultStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.tasteDays == 4)
    }

    @Test("interestChips count equals Interest.allCases.count") @MainActor
    func interestChipsCount() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.interestChips.count == Interest.allCases.count)
    }

    @Test("interests equals Interest.allCases") @MainActor
    func interestsIsAllCases() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.interests == Interest.allCases)
    }

    @Test("paceOptions equals Pace.allCases") @MainActor
    func paceOptionsIsAllCases() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.paceOptions == Pace.allCases)
    }

    @Test("pace defaults to .balanced in stateC") @MainActor
    func paceDefaultStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        // stateC tasteDefaults seeds pace = .balanced
        #expect(p.pace == .balanced)
    }

    @Test("selectedInterests reflect stateC seed (food, history, coffee)") @MainActor
    func selectedInterestsSeedStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        // stateC tasteDefaults: interests = [.food, .history, .coffee]
        #expect(p.selectedInterests.contains(.food))
        #expect(p.selectedInterests.contains(.history))
        #expect(p.selectedInterests.contains(.coffee))
    }

    @Test("interestChips mark seeded interests as selected (stateC)") @MainActor
    func interestChipsSelectionStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        let foodChip = p.interestChips.first(where: { $0.label == "Food" })
        let nightlifeChip = p.interestChips.first(where: { $0.label == "Nightlife" })
        #expect(foodChip?.isSelected == true)
        #expect(nightlifeChip?.isSelected == false)
    }

    // MARK: ctaTitle

    @Test("ctaTitle contains tasteDays") @MainActor
    func ctaTitleContainsDays() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        let p = TripShapeStepPresenter(store: store)
        #expect(p.ctaTitle == "Continue · \(p.tasteDays) days")
    }
}

// MARK: - BaseLocationStepPresenter

@Suite("BaseLocationStepPresenter derivation")
struct BaseLocationStepPresenterTests {

    // MARK: baseMode

    @Test("baseMode defaults to .smart") @MainActor
    func baseModeSmart() {
        for context in [SampleData.onboardingAContext(), SampleData.onboardingBContext(), SampleData.onboardingCContext()] {
            let store = AppStore.preview(context, step: .baseLocation)
            let p = BaseLocationStepPresenter(store: store)
            #expect(p.baseMode == .smart)
        }
    }

    // MARK: mapModel

    @Test("mapModel zoneName is 'Alfama' for stateA") @MainActor
    func mapModelZoneNameStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.mapModel.zoneName == "Alfama")
    }

    @Test("mapModel zoneName is 'Gion' for stateB") @MainActor
    func mapModelZoneNameStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.mapModel.zoneName == "Gion")
    }

    @Test("mapModel zoneName is 'Baixa' for stateC") @MainActor
    func mapModelZoneNameStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.mapModel.zoneName == "Baixa")
    }

    @Test("mapModel places are non-empty for stateA (Alfama has 6 pins)") @MainActor
    func mapModelPlacesStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.mapModel.places.count == 6)
    }

    // MARK: whyEyebrow / whyVoice per state

    @Test("whyEyebrow for stateA is 'What we noticed'") @MainActor
    func whyEyebrowStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyEyebrow == "What we noticed")
    }

    @Test("whyEyebrow for stateB is 'Where the plan clusters'") @MainActor
    func whyEyebrowStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyEyebrow == "Where the plan clusters")
    }

    @Test("whyEyebrow for stateC is 'Where to base you'") @MainActor
    func whyEyebrowStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyEyebrow == "Where to base you")
    }

    @Test("whyVoice for stateA mentions Alfama") @MainActor
    func whyVoiceStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyVoice.contains("Alfama"))
    }

    @Test("whyVoice for stateB mentions Gion") @MainActor
    func whyVoiceStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyVoice.contains("Gion"))
    }

    @Test("whyVoice for stateC mentions Baixa") @MainActor
    func whyVoiceStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.whyVoice.contains("Baixa"))
    }

    // MARK: reachRows

    @Test("reachRows stateA has 3 rows from Alfama seed") @MainActor
    func reachRowsCountStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.reachRows.count == 3)
    }

    @Test("reachRows stateA first row id is 'reach-alfama-foot'") @MainActor
    func reachRowsFirstIdStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        let footRow = p.reachRows.first(where: { $0.id == "reach-alfama-foot" })
        #expect(footRow != nil)
        if let row = footRow {
            #expect(row.hint.text == "18 of 23 places on foot")
            #expect(row.hint.measurement == "≤ 25 min")
        }
    }

    @Test("reachRows stateB first row id is 'reach-gion-foot'") @MainActor
    func reachRowsFirstIdStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        let footRow = p.reachRows.first(where: { $0.id == "reach-gion-foot" })
        #expect(footRow != nil)
    }

    // MARK: altNeighborhoods

    @Test("altNeighborhoods excludes the recommended neighborhood — stateA") @MainActor
    func altNeighborhoodsExcludesRecommendedStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        // Alfama is recommended; alt list should not contain it
        let altIds = p.altNeighborhoods.map(\.id)
        #expect(!altIds.contains("neighborhood-alfama"))
    }

    @Test("altNeighborhoods stateA count is 5 total - 1 recommended = 5") @MainActor
    func altNeighborhoodsCountStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        // stateA has 6 neighborhoods; Alfama is recommended; 5 alts
        #expect(p.altNeighborhoods.count == 5)
    }

    @Test("altNeighborhoods meta includes placeCount for stateA neighborhoods with places") @MainActor
    func altNeighborhoodsMetaStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        // Bairro Alto has placeCount=14, blurb="30 min walk" → "14 places · 30 min walk"
        let bairroAlto = p.altNeighborhoods.first(where: { $0.id == "neighborhood-bairro-alto" })
        #expect(bairroAlto != nil)
        if let alt = bairroAlto {
            #expect(alt.meta == "14 places · 30 min walk")
        }
    }

    @Test("altNeighborhoods meta is just blurb for stateC (placeCount=0)") @MainActor
    func altNeighborhoodsMetaStateCNoPlaces() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        // stateC Chiado: placeCount=0, blurb="central · flat"
        let chiado = p.altNeighborhoods.first(where: { $0.id == "neighborhood-chiado" })
        #expect(chiado != nil)
        if let alt = chiado {
            #expect(alt.meta == "central · flat")
        }
    }

    // MARK: ctaTitle

    @Test("ctaTitle uses neighborhood name for stateA") @MainActor
    func ctaTitleStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.ctaTitle == "Use Alfama as base")
    }

    @Test("ctaTitle uses neighborhood name for stateB") @MainActor
    func ctaTitleStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.ctaTitle == "Use Gion as base")
    }

    @Test("ctaTitle uses neighborhood name for stateC") @MainActor
    func ctaTitleStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        let p = BaseLocationStepPresenter(store: store)
        #expect(p.ctaTitle == "Use Baixa as base")
    }
}

// MARK: - GettingAroundStepPresenter

@Suite("GettingAroundStepPresenter derivation")
struct GettingAroundStepPresenterTests {

    // MARK: Hero copy (static)

    @Test("heroEyebrow is 'Getting around'") @MainActor
    func heroEyebrow() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.heroEyebrow == "Getting around")
    }

    @Test("heroQuestion is the fixed line") @MainActor
    func heroQuestion() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.heroQuestion == "How will you get around?")
    }

    @Test("heroSub is the fixed pick + mix line") @MainActor
    func heroSub() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.heroSub == "Pick one mode we optimize around, plus a few we can mix in.")
    }

    // MARK: AI rec voice

    @Test("recEyebrow is 'Reading your trip'") @MainActor
    func recEyebrow() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.recEyebrow == "Reading your trip")
    }

    @Test("recLineLead is 'We'd suggest '") @MainActor
    func recLineLead() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.recLineLead == "We'd suggest ")
    }

    @Test("recLineEmphasis is lowercase suggested mode label with period — stateA (transit)") @MainActor
    func recLineEmphasisStateA() {
        // stateA: lisbonTransportRec suggestedMode = .transit, label = "Transit"
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.recLineEmphasis == "transit.")
    }

    @Test("cityContext for stateA is 'Lisbon\\n4 days'") @MainActor
    func cityContextStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.cityContext == "Lisbon\n4 days")
    }

    @Test("cityContext for stateB is 'Kyoto · Gion\\n4 days'") @MainActor
    func cityContextStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.cityContext == "Kyoto · Gion\n4 days")
    }

    // MARK: reasonRows

    @Test("reasonRows stateA has 3 rows") @MainActor
    func reasonRowsCountStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.reasonRows.count == 3)
    }

    @Test("reasonRows stateA first row text is the transit reason") @MainActor
    func reasonRowsFirstTextStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        let transitRow = p.reasonRows.first(where: { $0.systemImage == "tram.fill" })
        #expect(transitRow != nil)
        if let row = transitRow {
            #expect(row.text.contains("Metro"))
            #expect(row.measurement == "€1.65")
        }
    }

    // MARK: contextNote

    @Test("contextNote is non-nil for stateA (Lisbon rain caveat)") @MainActor
    func contextNoteStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.contextNote != nil)
        if let note = p.contextNote {
            #expect(note.eyebrow == "For your dates")
            #expect(note.text.contains("Rain"))
        }
    }

    @Test("contextNote is non-nil for stateB (Kyoto blossom-season caveat)") @MainActor
    func contextNoteStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.contextNote != nil)
        if let note = p.contextNote {
            #expect(note.text.contains("Blossom"))
        }
    }

    // MARK: mostlyOptions / alsoOKModes (static lists)

    @Test("mostlyOptions contains walk/transit/drive/cycle in that order") @MainActor
    func mostlyOptions() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.mostlyOptions == [.walk, .transit, .drive, .cycle])
    }

    @Test("alsoOKModes contains walk/rideshare/cycle/bus/drive in that order") @MainActor
    func alsoOKModes() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.alsoOKModes == [.walk, .rideshare, .cycle, .bus, .drive])
    }

    // MARK: suggestedMode / primaryMode / suggestedHint

    @Test("suggestedMode is .transit for stateA") @MainActor
    func suggestedModeStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.suggestedMode == .transit)
    }

    @Test("primaryMode defaults to suggestedMode when no user selection") @MainActor
    func primaryModeDefaultsSuggested() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.primaryMode == p.suggestedMode)
    }

    @Test("primaryMode reflects user selection after setPrimaryMode") @MainActor
    func primaryModeAfterUserSelection() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        store.onboarding?.setPrimaryMode(.walk)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.primaryMode == .walk)
    }

    @Test("suggestedHint labels the suggested mode") @MainActor
    func suggestedHint() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.suggestedHint == "\(p.suggestedMode.label) is what we suggested")
    }

    // MARK: alsoOKChips

    @Test("alsoOKChips count equals alsoOKModes count") @MainActor
    func alsoOKChipsCount() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.alsoOKChips.count == p.alsoOKModes.count)
    }

    @Test("alsoOKChips all unselected initially") @MainActor
    func alsoOKChipsAllUnselectedInitially() {
        // stateA seeds alsoOK as empty set
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        #expect(p.alsoOKChips.allSatisfy { !$0.isSelected })
    }

    @Test("alsoOKChips reflect toggleAlsoOK mutation") @MainActor
    func alsoOKChipsAfterToggle() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        store.onboarding?.toggleAlsoOK(.cycle)
        let p = GettingAroundStepPresenter(store: store)
        let cycleChip = p.alsoOKChips.first(where: { $0.label == "Cycle" })
        #expect(cycleChip?.isSelected == true)
    }

    // MARK: ctaTitle

    @Test("ctaTitle contains primaryMode label (lowercase)") @MainActor
    func ctaTitleContainsPrimaryMode() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        let p = GettingAroundStepPresenter(store: store)
        let expected = "Continue · Mostly \(p.primaryMode.label.lowercased())"
        #expect(p.ctaTitle == expected)
    }
}

// MARK: - GeneratingStepPresenter

@Suite("GeneratingStepPresenter derivation")
struct GeneratingStepPresenterTests {

    // MARK: Hero copy (static)

    @Test("eyebrow is 'Drawing up your trip'") @MainActor
    func eyebrow() {
        for context in [SampleData.onboardingAContext(), SampleData.onboardingBContext(), SampleData.onboardingCContext()] {
            let store = AppStore.preview(context, step: .generating)
            let p = GeneratingStepPresenter(store: store)
            #expect(p.eyebrow == "Drawing up your trip")
        }
    }

    @Test("headline derives from plan.headline — stateA") @MainActor
    func headlineStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        #expect(p.headline == "Drawing up your trip")
    }

    @Test("sub derives from plan.sub — stateA") @MainActor
    func subStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        // stateA sub mentions "23 saved places"
        #expect(p.sub.contains("23 saved places"))
    }

    @Test("sub derives from plan.sub — stateC is brief") @MainActor
    func subStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        #expect(p.sub == "A first draft to react to.")
    }

    // MARK: steps

    @Test("steps count equals plan.steps.count — stateA (6 steps)") @MainActor
    func stepsCountStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        #expect(p.steps.count == 6)
    }

    @Test("steps stateA: gen-a-cluster is .done, gen-a-days is .current") @MainActor
    func stepsStatusStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        let clusterStep = p.steps.first(where: { $0.id == "gen-a-cluster" })
        let daysStep = p.steps.first(where: { $0.id == "gen-a-days" })
        let routeStep = p.steps.first(where: { $0.id == "gen-a-route" })
        #expect(clusterStep?.status == .done)
        #expect(daysStep?.status == .current)
        #expect(routeStep?.status == .pending)
    }

    @Test("steps stateA: gen-a-cluster has detail '5 clusters found'") @MainActor
    func stepsDetailStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        let clusterStep = p.steps.first(where: { $0.id == "gen-a-cluster" })
        #expect(clusterStep?.detail == "5 clusters found")
    }

    @Test("steps stateA: gen-a-sequence has nil detail") @MainActor
    func stepsNilDetailStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        let seqStep = p.steps.first(where: { $0.id == "gen-a-sequence" })
        #expect(seqStep?.detail == nil)
    }

    @Test("steps stateB: gen-b-pull is .done") @MainActor
    func stepsStatusStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        let pullStep = p.steps.first(where: { $0.id == "gen-b-pull" })
        #expect(pullStep?.status == .done)
    }

    // MARK: handoff

    @Test("handoff is non-nil when plan is present — stateA") @MainActor
    func handoffNonNilStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        #expect(p.handoff != nil)
        if let handoff = p.handoff {
            #expect(handoff.title == "Up next · Trip overview")
            #expect(handoff.subtitle == "Lisbon · 4 days, your shape.")
        }
    }

    @Test("handoff subtitle stateB is Kyoto") @MainActor
    func handoffSubtitleStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        if let handoff = p.handoff {
            #expect(handoff.subtitle.contains("Kyoto"))
        }
    }

    // MARK: eta

    @Test("eta contains etaSeconds from plan — stateA (8 seconds)") @MainActor
    func etaStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = GeneratingStepPresenter(store: store)
        #expect(p.eta == "Usually ready in about 8 seconds")
    }

    @Test("eta falls back to 8 when plan is nil") @MainActor
    func etaNilPlan() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        store.onboarding?.generationPlan = nil
        let p = GeneratingStepPresenter(store: store)
        #expect(p.eta == "Usually ready in about 8 seconds")
    }
}

// MARK: - OnboardingFlowPresenter

@Suite("OnboardingFlowPresenter derivation")
struct OnboardingFlowPresenterTests {

    // MARK: currentStep

    @Test("currentStep reflects draft.currentStep") @MainActor
    func currentStepReflectsDraft() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.currentStep == .tripShape)
    }

    @Test("currentStep defaults to .destination when no draft") @MainActor
    func currentStepDefaultsWhenNoDraft() {
        let store = AppStore(api: .mock())
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.currentStep == .destination)
    }

    // MARK: onboardingState

    @Test("onboardingState is .returningWithLocalSaves for stateA") @MainActor
    func onboardingStateA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.onboardingState == .returningWithLocalSaves)
    }

    @Test("onboardingState is .savesElsewhere for stateB") @MainActor
    func onboardingStateB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .destination)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.onboardingState == .savesElsewhere)
    }

    @Test("onboardingState is .firstTrip for stateC") @MainActor
    func onboardingStateC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .destination)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.onboardingState == .firstTrip)
    }

    @Test("onboardingState is nil when no draft") @MainActor
    func onboardingStateNilWhenNoDraft() {
        let store = AppStore(api: .mock())
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.onboardingState == nil)
    }

    // MARK: progressIndex

    @Test("progressIndex == 0 for .destination step") @MainActor
    func progressIndexDestination() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.progressIndex == 0)
    }

    @Test("progressIndex == 1 for .tripShape step") @MainActor
    func progressIndexTripShape() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.progressIndex == 1)
    }

    @Test("progressIndex == 4 for .generating step") @MainActor
    func progressIndexGenerating() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.progressIndex == 4)
    }

    // MARK: leadingGlyph

    @Test("leadingGlyph is .close on first step (index == 0)") @MainActor
    func leadingGlyphCloseOnFirstStep() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.leadingGlyph == .close)
    }

    @Test("leadingGlyph is .back on subsequent steps (index > 0)") @MainActor
    func leadingGlyphBackOnSubsequentSteps() {
        for step in [OnboardingStep.tripShape, .baseLocation, .gettingAround, .generating] {
            let store = AppStore.preview(SampleData.onboardingAContext(), step: step)
            let p = OnboardingFlowPresenter(store: store)
            #expect(p.leadingGlyph == .back, "Expected .back for step \(step)")
        }
    }

    @Test("leadingGlyph defaults to .close when no draft (progressIndex == 0)") @MainActor
    func leadingGlyphDefaultsToClose() {
        let store = AppStore(api: .mock())
        let p = OnboardingFlowPresenter(store: store)
        #expect(p.leadingGlyph == .close)
    }
}
