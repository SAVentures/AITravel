// SampleData+Onboarding.swift — the three onboarding seed contexts (plan W2-11).
//
// `SampleData` is the one mock source (02-models.md §5). Each `MockScenario.onboardingA/B/C`
// resolves to a `MockSeed` whose `onboardingContext` is built here. All ids are stable literals;
// the content is faithful to the named mockups under `mockups/screens/onboarding/`
// (state-a/b/c-*.html) — city names, saved counts, neighborhood place counts, reach rows,
// trip-shape copy + metric strips + diagram numbers, transport reasons (€ / ¥) + context notes,
// and the six generation steps + cluster names + handoff lines.
//
// The three contexts drive A/B/C branch selection via `savedHere` / `savedAnywhere`
// (`OnboardingContextDTO.onboardingState`):
//   - A: `savedHere > 0`                          → returningWithLocalSaves
//   - B: `savedHere == 0 && savedAnywhere > 0`     → savesElsewhere
//   - C: `savedAnywhere == 0`                      → firstTrip
import Foundation

extension SampleData {

    // MARK: - A — returning, local saves (Lisbon, 23 saved)

    /// State A: Lisbon chosen with 23 saved places here (plus 6 in Tokyo). Full cover-the-bucket
    /// option available; Alfama base (18 / 23 within a 25-min walk); transit rec in € with a rain
    /// note; the six Lisbon generation steps.
    /// Mockups: `state-a-screen-01..05`.
    static func onboardingAContext() -> OnboardingContextDTO {
        OnboardingContextDTO(
            destination: lisbonCity(savedHere: 23, meta: .savedCount(23)),
            cityOptions: cityOptionsStateA(),
            neighborhoods: lisbonNeighborhoodsStateA(),
            recommendedBase: alfamaBase(),
            shapeOptions: shapeOptionsStateA(),
            tasteDefaults: nil,
            transportRec: lisbonTransportRec(),
            generationPlan: lisbonGenerationPlanStateA(),
            savedHere: 23,
            savedAnywhere: 23 + 6   // Lisbon (23) + Tokyo (6)
        )
    }

    // MARK: - B — saves elsewhere, none here (Kyoto, 0 here)

    /// State B: Kyoto chosen with no local saves but saves elsewhere (Tokyo + Lisbon). The
    /// cover-the-bucket option is locked ("Save places in Kyoto to unlock"); copy pivots to taste +
    /// the city's best; Gion base; transit rec in ¥ with a blossom-crowd note; the Kyoto generation
    /// steps ("12 picks shortlisted").
    /// Mockups: `state-b-screen-01..05`.
    static func onboardingBContext() -> OnboardingContextDTO {
        OnboardingContextDTO(
            destination: kyotoCity(savedHere: 0, meta: .neighborhood("plan from scratch")),
            cityOptions: cityOptionsStateB(),
            neighborhoods: kyotoNeighborhoodsStateB(),
            recommendedBase: gionBase(),
            shapeOptions: shapeOptionsStateB(),
            tasteDefaults: nil,
            transportRec: kyotoTransportRec(),
            generationPlan: kyotoGenerationPlanStateB(),
            savedHere: 0,
            savedAnywhere: 6 + 23   // Tokyo (6) + Lisbon (23), none in Kyoto
        )
    }

    // MARK: - C — first trip, nothing saved anywhere (Lisbon)

    /// State C: Lisbon chosen as a first trip with nothing saved anywhere. Step 02 is the taste form
    /// (no shape cards), so `shapeOptions` is empty and `tasteDefaults` carries the seed taste
    /// (4 days, food / history / coffee, balanced). Baixa base (descriptors, no place counts); the
    /// shared Lisbon transport rec; the Lisbon "best for food and history" generation plan.
    /// Mockups: `state-c-screen-01..05`.
    static func onboardingCContext() -> OnboardingContextDTO {
        OnboardingContextDTO(
            destination: lisbonCity(savedHere: 0, meta: .neighborhood("we'll plan it")),
            cityOptions: cityOptionsStateC(),
            neighborhoods: lisbonNeighborhoodsStateC(),
            recommendedBase: baixaBase(),
            shapeOptions: [],   // step 02 is the taste form in state C
            tasteDefaults: TasteProfile(days: 4, interests: [.food, .history, .coffee], pace: .balanced),
            transportRec: lisbonTransportRec(),
            generationPlan: lisbonGenerationPlanStateC(),
            savedHere: 0,
            savedAnywhere: 0
        )
    }
}

// MARK: - Shared city builders

extension SampleData {

    fileprivate static func lisbonCity(savedHere: Int, meta: CityMeta) -> City {
        City(id: "city-lisbon", name: "Lisbon", country: "Portugal", savedHere: savedHere, meta: meta)
    }

    fileprivate static func tokyoCity(meta: CityMeta = .savedCount(6)) -> City {
        City(id: "city-tokyo", name: "Tokyo", country: "Japan", savedHere: 6, meta: meta)
    }

    fileprivate static func kyotoCity(savedHere: Int, meta: CityMeta) -> City {
        City(id: "city-kyoto", name: "Kyoto", country: "Japan", savedHere: savedHere, meta: meta)
    }

    fileprivate static func mexicoCityCity() -> City {
        City(id: "city-mexico-city", name: "Mexico City", country: "Mexico", savedHere: 0, meta: .neighborhood("Roma Norte"))
    }

    fileprivate static func marrakechCity() -> City {
        City(id: "city-marrakech", name: "Marrakech", country: "Morocco", savedHere: 0, meta: .medina)
    }

    fileprivate static func osakaCity() -> City {
        City(id: "city-osaka", name: "Osaka", country: "Japan", savedHere: 0, meta: .savedCount(0))
    }

    fileprivate static func seoulCity() -> City {
        City(id: "city-seoul", name: "Seoul", country: "Korea", savedHere: 0, meta: .savedCount(0))
    }

    // MARK: City catalogs per state (the recent rail + the "more cities" grid)

    /// State A grid: Lisbon (23 saved, plan started) · Tokyo (6 saved) · Mexico City · Marrakech.
    fileprivate static func cityOptionsStateA() -> [City] {
        [
            lisbonCity(savedHere: 23, meta: .planStarted),
            tokyoCity(),
            mexicoCityCity(),
            marrakechCity(),
        ]
    }

    /// State B grid: Kyoto (plan started) · Tokyo (6 saved) · Osaka (0) · Seoul (0).
    fileprivate static func cityOptionsStateB() -> [City] {
        [
            kyotoCity(savedHere: 0, meta: .planStarted),
            tokyoCity(),
            osakaCity(),
            seoulCity(),
        ]
    }

    /// State C grid: Lisbon (we'll plan it) · Tokyo (trending) · Mexico City · Marrakech.
    fileprivate static func cityOptionsStateC() -> [City] {
        [
            lisbonCity(savedHere: 0, meta: .neighborhood("we'll plan it")),
            City(id: "city-tokyo", name: "Tokyo", country: "Japan", savedHere: 0, meta: .neighborhood("trending")),
            mexicoCityCity(),
            marrakechCity(),
        ]
    }
}

// MARK: - Neighborhoods

extension SampleData {

    /// Lisbon neighborhoods (state A): Alfama (recommended) + Bairro Alto / Chiado /
    /// Príncipe Real / Belém / Baixa — place counts + blurbs per `state-a-screen-03`.
    fileprivate static func lisbonNeighborhoodsStateA() -> [Neighborhood] {
        [
            Neighborhood(
                id: "neighborhood-alfama",
                name: "Alfama",
                placeCount: 18,
                blurb: "central",
                reachRows: alfamaReachRows(),
                isRecommended: true
            ),
            Neighborhood(id: "neighborhood-bairro-alto", name: "Bairro Alto", placeCount: 14, blurb: "30 min walk", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-chiado", name: "Chiado", placeCount: 12, blurb: "central", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-principe-real", name: "Príncipe Real", placeCount: 9, blurb: "quieter", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-belem", name: "Belém", placeCount: 4, blurb: "west", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-baixa", name: "Baixa", placeCount: 0, blurb: "central", reachRows: [], isRecommended: false),
        ]
    }

    /// Kyoto neighborhoods (state B): Gion (recommended) + Downtown / S. Higashiyama /
    /// Pontochō / Arashiyama — pick counts + blurbs per `state-b-screen-03`.
    fileprivate static func kyotoNeighborhoodsStateB() -> [Neighborhood] {
        [
            Neighborhood(
                id: "neighborhood-gion",
                name: "Gion",
                placeCount: 0,
                blurb: "east temples",
                reachRows: gionReachRows(),
                isRecommended: true
            ),
            Neighborhood(id: "neighborhood-downtown", name: "Downtown", placeCount: 10, blurb: "central", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-s-higashiyama", name: "S. Higashiyama", placeCount: 8, blurb: "temples", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-pontocho", name: "Pontochō", placeCount: 6, blurb: "nightlife", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-arashiyama", name: "Arashiyama", placeCount: 3, blurb: "west", reachRows: [], isRecommended: false),
        ]
    }

    /// Lisbon neighborhoods (state C): Baixa (recommended) + Chiado / Alfama / Bairro Alto /
    /// Príncipe Real — descriptors, no place counts per `state-c-screen-03`.
    fileprivate static func lisbonNeighborhoodsStateC() -> [Neighborhood] {
        [
            Neighborhood(
                id: "neighborhood-baixa",
                name: "Baixa",
                placeCount: 0,
                blurb: "dead-central",
                reachRows: baixaReachRows(),
                isRecommended: true
            ),
            Neighborhood(id: "neighborhood-chiado", name: "Chiado", placeCount: 0, blurb: "central · flat", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-alfama", name: "Alfama", placeCount: 0, blurb: "atmospheric · hilly", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-bairro-alto", name: "Bairro Alto", placeCount: 0, blurb: "nightlife", reachRows: [], isRecommended: false),
            Neighborhood(id: "neighborhood-principe-real", name: "Príncipe Real", placeCount: 0, blurb: "quieter", reachRows: [], isRecommended: false),
        ]
    }

    fileprivate static func alfamaReachRows() -> [ReachRow] {
        [
            ReachRow(id: "reach-alfama-foot", systemImage: "figure.walk", label: "18 of 23 places on foot", measurement: "≤ 25 min"),
            ReachRow(id: "reach-alfama-centro", systemImage: "tram.fill", label: "Centro via metro", measurement: "12 min"),
            ReachRow(id: "reach-alfama-belem", systemImage: "tram.fill", label: "Belém on tram 15E", measurement: "25 min"),
        ]
    }

    fileprivate static func gionReachRows() -> [ReachRow] {
        [
            ReachRow(id: "reach-gion-foot", systemImage: "figure.walk", label: "Most of the picks on foot", measurement: "≤ 20 min"),
            ReachRow(id: "reach-gion-downtown", systemImage: "tram.fill", label: "Downtown via subway", measurement: "10 min"),
            ReachRow(id: "reach-gion-arashiyama", systemImage: "tram.fill", label: "Arashiyama by train", measurement: "22 min"),
        ]
    }

    fileprivate static func baixaReachRows() -> [ReachRow] {
        [
            ReachRow(id: "reach-baixa-foot", systemImage: "figure.walk", label: "Most of the plan on foot", measurement: "≤ 20 min"),
            ReachRow(id: "reach-baixa-metro", systemImage: "tram.fill", label: "Everywhere else via metro", measurement: "≤ 15 min"),
            ReachRow(id: "reach-baixa-belem", systemImage: "tram.fill", label: "Belém by tram 15E", measurement: "22 min"),
        ]
    }
}

// MARK: - Recommended bases (real-ish coordinates + pins)

extension SampleData {

    /// Alfama base — 18 / 23 within a 25-min walk. Home anchor near the Alfama centroid; pins are
    /// `.definitive` in-neighborhood, `.fuzzy` for the out-of-zone (Belém) saves.
    fileprivate static func alfamaBase() -> BaseLocation {
        BaseLocation(
            id: "base-alfama",
            neighborhoodName: "Alfama",
            latitude: 38.7118,
            longitude: -9.1300,
            homeLatitude: 38.7118,
            homeLongitude: -9.1300,
            pins: [
                BasePin(id: "pin-alfama-1", latitude: 38.7124, longitude: -9.1295, kind: .definitive),
                BasePin(id: "pin-alfama-2", latitude: 38.7110, longitude: -9.1278, kind: .definitive),
                BasePin(id: "pin-alfama-3", latitude: 38.7135, longitude: -9.1312, kind: .definitive),
                BasePin(id: "pin-alfama-4", latitude: 38.7102, longitude: -9.1325, kind: .definitive),
                BasePin(id: "pin-alfama-belem-1", latitude: 38.6979, longitude: -9.2061, kind: .fuzzy),
                BasePin(id: "pin-alfama-belem-2", latitude: 38.6968, longitude: -9.2030, kind: .fuzzy),
            ],
            zoneLabel: "Alfama · 18 / 23 within 25 min walk"
        )
    }

    /// Gion base — most picks within a 20-min walk of the east temples.
    fileprivate static func gionBase() -> BaseLocation {
        BaseLocation(
            id: "base-gion",
            neighborhoodName: "Gion",
            latitude: 35.0037,
            longitude: 135.7752,
            homeLatitude: 35.0037,
            homeLongitude: 135.7752,
            pins: [
                BasePin(id: "pin-gion-1", latitude: 35.0030, longitude: 135.7780, kind: .definitive),
                BasePin(id: "pin-gion-2", latitude: 35.0045, longitude: 135.7800, kind: .definitive),
                BasePin(id: "pin-gion-3", latitude: 35.0021, longitude: 135.7765, kind: .definitive),
                BasePin(id: "pin-gion-arashiyama", latitude: 35.0094, longitude: 135.6670, kind: .fuzzy),
            ],
            zoneLabel: "Gion · most picks within 20 min walk"
        )
    }

    /// Baixa base — dead-central, close to most of a food-and-history first trip. No place counts
    /// (state C has nothing saved), so the zone label is descriptive.
    fileprivate static func baixaBase() -> BaseLocation {
        BaseLocation(
            id: "base-baixa",
            neighborhoodName: "Baixa",
            latitude: 38.7110,
            longitude: -9.1390,
            homeLatitude: 38.7110,
            homeLongitude: -9.1390,
            pins: [
                BasePin(id: "pin-baixa-1", latitude: 38.7117, longitude: -9.1385, kind: .definitive),
                BasePin(id: "pin-baixa-2", latitude: 38.7102, longitude: -9.1398, kind: .definitive),
                BasePin(id: "pin-baixa-3", latitude: 38.7095, longitude: -9.1375, kind: .definitive),
                BasePin(id: "pin-baixa-belem", latitude: 38.6979, longitude: -9.2061, kind: .fuzzy),
            ],
            zoneLabel: "Baixa · dead-central"
        )
    }
}

// MARK: - Trip-shape options

extension SampleData {

    /// State A shape cards: Fixed days (selectable) · Cover the bucket (unlocked — 23 saved) ·
    /// Just the highlights. Metric strips + diagram numbers per `state-a-screen-02`.
    fileprivate static func shapeOptionsStateA() -> [TripShapeOption] {
        [
            TripShapeOption(
                id: "shape-fixed-days",
                strategy: .fixedDays,
                eyebrow: "A · Fixed days",
                title: "Pack four great days.",
                tagline: nil,
                metricStrip: [
                    MetricFragment(text: "hits 14 of 23", emphasis: true),
                    MetricFragment(text: " · "),
                    MetricFragment(text: "skips 9", struck: true),
                ],
                diagram: .fixedDays(filled: [0, 1, 2, 3], dim: []),
                lockable: false,
                lockReason: nil
            ),
            TripShapeOption(
                id: "shape-cover-bucket",
                strategy: .coverBucket,
                eyebrow: "B · Cover the bucket",
                title: "Hit everything you saved.",
                tagline: "We calculate the days needed to fit all 23, routed by neighborhood.",
                metricStrip: [
                    MetricFragment(text: "~6 days", emphasis: true),
                    MetricFragment(text: " · "),
                    MetricFragment(text: "hits 23 of 23"),
                ],
                diagram: .coverBucket(dayCounts: [4, 4, 4, 4, 4, 3]),
                lockable: true,    // unlocked here — savedHere == 23 > 0
                lockReason: nil
            ),
            TripShapeOption(
                id: "shape-highlights",
                strategy: .highlights,
                eyebrow: "C · Just the highlights",
                title: "The best of yours, plus the unmissable.",
                tagline: "Your top-rated saves, plus a few picks the city is known for.",
                metricStrip: [
                    MetricFragment(text: "top 14 of yours", emphasis: true),
                    MetricFragment(text: " · "),
                    MetricFragment(text: "+ 3 picks"),
                ],
                diagram: .rankedBars(values: [1.0, 0.82, 0.68, 0.55, 0.4], pickIndex: 0, dimIndex: nil),
                lockable: false,
                lockReason: nil
            ),
        ]
    }

    /// State B shape cards: Fixed days · Cover the bucket (**locked** — nothing saved in Kyoto) ·
    /// Just the highlights (Kyoto's best, tuned to taste). Per `state-b-screen-02`.
    fileprivate static func shapeOptionsStateB() -> [TripShapeOption] {
        [
            TripShapeOption(
                id: "shape-fixed-days",
                strategy: .fixedDays,
                eyebrow: "A · Fixed days",
                title: "Pack four great days.",
                tagline: nil,
                metricStrip: [
                    MetricFragment(text: "we pick 14", emphasis: true),
                    MetricFragment(text: " · "),
                    MetricFragment(text: "paced for 4 days"),
                ],
                diagram: .fixedDays(filled: [0, 1, 2, 3], dim: []),
                lockable: false,
                lockReason: nil
            ),
            TripShapeOption(
                id: "shape-cover-bucket",
                strategy: .coverBucket,
                eyebrow: "B · Cover the bucket",
                title: "Hit everything you saved.",
                tagline: "Routes a trip around your whole saved list — once you've saved some here.",
                metricStrip: [
                    MetricFragment(text: "0 saved"),
                ],
                diagram: .coverBucket(dayCounts: [0, 0, 0, 0, 0]),
                lockable: true,
                lockReason: "Save places in Kyoto to unlock"
            ),
            TripShapeOption(
                id: "shape-highlights",
                strategy: .highlights,
                eyebrow: "C · Just the highlights",
                title: "Kyoto's best, tuned to your taste.",
                tagline: "The places the city's known for, filtered by the taste we read in your saves.",
                metricStrip: [
                    MetricFragment(text: "12 picks", emphasis: true),
                    MetricFragment(text: " · "),
                    MetricFragment(text: "your taste"),
                ],
                diagram: .rankedBars(values: [1.0, 0.85, 0.7, 0.58, 0.45], pickIndex: 0, dimIndex: nil),
                lockable: false,
                lockReason: nil
            ),
        ]
    }
}

// MARK: - Transport recommendations

extension SampleData {

    /// Lisbon transport rec — transit, € reasons, rain note. Shared by states A and C
    /// (the common `screen-04-getting-around`).
    fileprivate static func lisbonTransportRec() -> TransportRec {
        TransportRec(
            suggestedMode: .transit,
            cityContext: "Lisbon\n4 days",
            reasons: [
                ReasonRow(id: "reason-lisbon-transit", systemImage: "tram.fill", text: "Metro reaches most of the city within a 5-min walk of a station.", measurement: "€1.65"),
                ReasonRow(id: "reason-lisbon-walk", systemImage: "figure.walk", text: "Walking is great inside Alfama and Bairro Alto — short blocks.", measurement: "≤ 25 min"),
                ReasonRow(id: "reason-lisbon-drive", systemImage: "car.fill", text: "Driving means parking and tight medieval streets.", measurement: "€18+/day"),
            ],
            contextNote: ContextNoteModel(
                eyebrow: "For your dates",
                text: "Rain forecast 2 of your 4 days. Transit and walking will beat cycling those days."
            )
        )
    }

    /// Kyoto transport rec — transit, ¥ reasons, blossom-crowd note. Per `state-b-screen-04`.
    fileprivate static func kyotoTransportRec() -> TransportRec {
        TransportRec(
            suggestedMode: .transit,
            cityContext: "Kyoto · Gion\n4 days",
            reasons: [
                ReasonRow(id: "reason-kyoto-transit", systemImage: "tram.fill", text: "Subway and buses reach most of the picks within a short walk.", measurement: "¥230"),
                ReasonRow(id: "reason-kyoto-walk", systemImage: "figure.walk", text: "Walking is best inside Higashiyama — temple lanes, short blocks.", measurement: "≤ 20 min"),
                ReasonRow(id: "reason-kyoto-drive", systemImage: "car.fill", text: "Driving means paid lots and slow downtown grids.", measurement: "¥2000+/day"),
            ],
            contextNote: ContextNoteModel(
                eyebrow: "For your dates",
                text: "Blossom-season crowds peak midday. Early starts and transit beat the queues."
            )
        )
    }
}

// MARK: - Generation plans

extension SampleData {

    /// Lisbon generation plan (state A): the six steps + clusters (Alfama · Belém · Bairro Alto ·
    /// Parque), eta 8s, handoff "Lisbon · 4 days, your shape." Per `state-a-screen-05`.
    fileprivate static func lisbonGenerationPlanStateA() -> GenerationPlan {
        GenerationPlan(
            steps: [
                GenerationStep(id: "gen-a-cluster", label: "Grouping your 23 places by neighborhood", detail: "5 clusters found", state: .done),
                GenerationStep(id: "gen-a-days", label: "Clustering into 4 days", detail: "Alfama · Belém · Bairro Alto · Parque", state: .current),
                GenerationStep(id: "gen-a-route", label: "Routing each day to minimize backtracking", detail: "2 loops · 1 line · 1 hub", state: .pending),
                GenerationStep(id: "gen-a-sequence", label: "Sequencing the days so they flow geographically", detail: nil, state: .pending),
                GenerationStep(id: "gen-a-meals", label: "Spacing meals and rest", detail: nil, state: .pending),
                GenerationStep(id: "gen-a-tips", label: "Adding context-aware tips", detail: nil, state: .pending),
            ],
            etaSeconds: 8,
            handoffEyebrow: "Up next · Trip overview",
            handoffLine: "Lisbon · 4 days, your shape.",
            headline: "Drawing up your trip",
            sub: "Reading your 23 saved places, your Alfama base, and your transit preference. We'll hand you something you can shape.",
            currentStepIndex: 1
        )
    }

    /// Kyoto generation plan (state B): Kyoto's best ("12 picks shortlisted") + clusters
    /// (Higashiyama · Arashiyama · Downtown · Fushimi), handoff "Kyoto · 4 days, a strong first
    /// draft." Per `state-b-screen-05`.
    fileprivate static func kyotoGenerationPlanStateB() -> GenerationPlan {
        GenerationPlan(
            steps: [
                GenerationStep(id: "gen-b-pull", label: "Pulling Kyoto's best, tuned to your taste", detail: "12 picks shortlisted", state: .done),
                GenerationStep(id: "gen-b-days", label: "Clustering into 4 days", detail: "Higashiyama · Arashiyama · Downtown · Fushimi", state: .current),
                GenerationStep(id: "gen-b-route", label: "Routing each day to minimize backtracking", detail: "2 loops · 1 line · 1 hub", state: .pending),
                GenerationStep(id: "gen-b-sequence", label: "Sequencing the days so they flow geographically", detail: nil, state: .pending),
                GenerationStep(id: "gen-b-meals", label: "Spacing meals and rest", detail: nil, state: .pending),
                GenerationStep(id: "gen-b-tips", label: "Adding context-aware tips, and leaving room for what you'll save as you go", detail: nil, state: .pending),
            ],
            etaSeconds: 8,
            handoffEyebrow: "Up next · Trip overview",
            handoffLine: "Kyoto · 4 days, a strong first draft.",
            headline: "Drawing up your trip",
            sub: "Working from Kyoto's best and the taste we read in your saves — plus your Gion base and transit preference. You'll shape it from here.",
            currentStepIndex: 1
        )
    }

    /// Lisbon generation plan (state C): "best for food and history" + clusters (Baixa · Alfama ·
    /// Belém · Bairro Alto), handoff "Lisbon · 4 days, your shape." (sub "A first draft to react
    /// to."). Per `state-c-screen-05`.
    fileprivate static func lisbonGenerationPlanStateC() -> GenerationPlan {
        GenerationPlan(
            steps: [
                GenerationStep(id: "gen-c-choose", label: "Choosing Lisbon's best for food, history & coffee", detail: "14 picks shortlisted", state: .done),
                GenerationStep(id: "gen-c-days", label: "Clustering into 4 days", detail: "Baixa · Alfama · Belém · Bairro Alto", state: .current),
                GenerationStep(id: "gen-c-route", label: "Routing each day to minimize backtracking", detail: "2 loops · 1 line · 1 hub", state: .pending),
                GenerationStep(id: "gen-c-sequence", label: "Sequencing the days so they flow geographically", detail: nil, state: .pending),
                GenerationStep(id: "gen-c-meals", label: "Spacing meals and rest", detail: nil, state: .pending),
                GenerationStep(id: "gen-c-tips", label: "Adding tips, and leaving room to save as you explore", detail: nil, state: .pending),
            ],
            etaSeconds: 8,
            handoffEyebrow: "Up next · Trip overview",
            handoffLine: "Lisbon · 4 days, your shape.",
            headline: "Drawing up your trip",
            sub: "A first draft to react to.",
            currentStepIndex: 1
        )
    }
}
