// DestinationStepPresenter.swift — the stateless derivation for onboarding step 01 (plan W4-01).
//
// Named mockups (the fidelity target this screen ports):
//   mockups/screens/onboarding/state-a-screen-01-destination.html  (A — returning, local saves)
//   mockups/screens/onboarding/state-b-screen-01-destination.html  (B — saves elsewhere)
//   mockups/screens/onboarding/state-c-screen-01-destination.html  (C — first trip)
//
// Per `06-screens.md §3`: a stateless `<Screen>Presenter` value type over the store, constructed in
// `body`, returning data / view-models (NEVER `View`s). ALL of step 01's screen-specific derivation
// lives here — the per-state hero copy (eyebrow / question / sub), the search value, the AI-voice
// eyebrow+line, and the recent-rail + grid `CityTileModel`s (mapping each `City` → its
// `PlaceCardModel` register, selection, and meta `Tag`). The view stays layout + wiring only.
//
// The *store-shared* branch derivation (`onboardingState`) lives on the store (`AppStore+Onboarding`);
// this presenter reads it to pick the per-state copy. Kept cheap — rebuilt every `body` pass.
import Foundation

// MARK: - CityTileModel — the view-model for one destination tile (rail chip + grid card)

/// One destination option, already derived for the view: the underlying `City`, its certainty
/// register (selected → `.definitive`, others → `.fuzzy`, per J-8), whether it is the chosen
/// destination, and its meta `Tag` label (e.g. "plan started", "23 saved", "Roma Norte").
///
/// A value type the view renders without any further logic — the `City` → `PlaceCardModel` map and
/// the selection/register decision are made HERE, not in the view (`06-screens.md §1`).
struct CityTileModel: Identifiable, Sendable {

    /// The underlying city (carries `id`, `name`, `country`, `meta`).
    let city: City

    /// The card register the tile renders in — `.definitive` for the chosen city (lifted, ink ring +
    /// check), `.fuzzy` for the rest (received, no accent). Certainty via elevation, never a fill (J-8).
    let certainty: PlaceCertainty

    /// Whether this is the chosen destination — drives the ink check mark (J-2.4, not an accent fill).
    let isSelected: Bool

    /// The per-tile meta label shown beneath the name (`City.meta.displayLabel`), e.g.
    /// "Portugal · 23 saved" composed by the view, or the floating `Tag` "plan started".
    let metaLabel: String

    /// Whether the meta reads as a floating "plan started" badge (mockup `.saved` tag) rather than the
    /// inline country · detail subtitle. True only for the `.planStarted` meta on an UNselected tile.
    let showsPlanStartedBadge: Bool

    var id: String { city.id }
}

// MARK: - DestinationStepPresenter

/// Stateless derivation for `DestinationStepView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved (`06-screens.md §3`).
struct DestinationStepPresenter {

    /// The single source of truth the screen reads. Held, never mutated here.
    let store: AppStore

    /// The live search query from the well (ephemeral UI state the view owns). Empty → no filtering,
    /// the full catalog shows (the static-mockup default). Non-empty → the rail + grid keep only cities
    /// whose name matches (case/diacritic-insensitive). The filter lives HERE, not the view (J-5).
    let searchText: String

    init(store: AppStore, searchText: String = "") {
        self.store = store
        self.searchText = searchText
    }

    // MARK: - Catalog access (the immutable seed the provider served)

    /// The active draft, or `nil` when onboarding is dismissed / pre-hydration. The presenter stays
    /// total when absent (the container renders nothing in that case).
    private var draft: TripDraft? { store.onboarding }

    /// The seed catalog carried on the draft.
    private var context: OnboardingContextDTO? { draft?.context }

    /// The A/B/C branch — read off the store derivation (NOT recomputed in the view). Defaults to the
    /// first-trip copy when absent so every accessor stays total.
    private var state: OnboardingState { store.onboardingState ?? .firstTrip }

    // MARK: - Hero copy (per the named mockup, per state)

    /// The mono caps eyebrow above the hero question (mockup `.hero .eyebrow`). Constant across states.
    var eyebrow: String { "Destination" }

    /// The display hero question (mockup `.hero .q`). C asks it as a *first* trip; A/B as a return.
    var question: String {
        switch state {
        case .returningWithLocalSaves, .savesElsewhere:
            "Where are you headed?"
        case .firstTrip:
            "Where to first?"
        }
    }

    /// The hero sub-line (mockup `.hero .sub`).
    var sub: String {
        switch state {
        case .returningWithLocalSaves, .savesElsewhere:
            "Pick a city — we'll bring your saved places along."
        case .firstTrip:
            "Your first trip — pick a city and we'll build the rest from its best."
        }
    }

    // MARK: - Search well

    /// The read-only value shown in the `SearchWell` — the chosen destination's name (mockup `.search`
    /// `.val`). Empty when no city is chosen yet (the well shows its placeholder).
    var searchValue: String {
        draft?.destination?.name ?? ""
    }

    // MARK: - AI voice (the one editorial italic line, per state)

    /// The `AIVoice` eyebrow + line for this state (mockup `.ai .lab` + `.ai .line`). A reads the local
    /// saves; B reads taste from elsewhere; C is the empty "nothing saved yet" copy.
    var aiVoice: (eyebrow: String, line: String) {
        let cityName = draft?.destination?.name ?? "this city"
        switch state {
        case .returningWithLocalSaves:
            let count = store.savedHere
            return (
                eyebrow: "Reading your saved places",
                line: "You've saved \(count) places in \(cityName) — clustered in your favorite "
                    + "neighborhoods, with a few further out."
            )
        case .savesElsewhere:
            return (
                eyebrow: "Nothing saved here — reading your taste",
                line: "No places saved in \(cityName) yet. From your saves elsewhere we know the shape "
                    + "of it — food-led, quiet mornings, light on museums."
            )
        case .firstTrip:
            return (
                eyebrow: "Your first trip",
                line: "Nothing saved yet — that's fine. We'll start from \(cityName)'s best and learn "
                    + "your taste as you go."
            )
        }
    }

    // MARK: - Recent rail + grid (City → CityTileModel)

    /// The "More cities" 2×2 grid (mockup `.pop`): every `cityOptions` city, the chosen one in the
    /// `.definitive` register (selected), the rest `.fuzzy`. The `City` → tile map lives here, per task.
    /// When the search well carries a query, the grid keeps only the matching cities (the filter is the
    /// presenter's, not the view's — J-5).
    var gridCities: [CityTileModel] {
        matchingCities.map { tile(for: $0) }
    }

    /// The horizontal "Recent" rail (mockup `.rail`): the same catalog surfaced as mini chips. The seed
    /// carries one city catalog, so the rail reads from it too (data-driven, never invented). Filtered by
    /// the same query as the grid, so searching narrows BOTH surfaces in lockstep.
    var recentCities: [CityTileModel] {
        matchingCities.map { tile(for: $0) }
    }

    /// The catalog narrowed by the live search query: when empty, the full catalog (the static-mockup
    /// default); otherwise the cities whose `name` contains the query, case- and diacritic-insensitive.
    ///
    /// Exposed so the view's SEARCH-RESULTS mode (keyboard up / query typed) can render these as a
    /// vertical result list, while the non-searching layout keeps using `recentCities` / `gridCities`.
    /// The filter is the presenter's, never the view's (J-5).
    var matchingCities: [City] {
        let cities = context?.cityOptions ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return cities }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - CTA

    /// The action-floor CTA verb (mockup `.ob-cta` — "Continue with Lisbon"). Reads the chosen city so
    /// the primary always names the destination (J-11.3, verb-led).
    var ctaTitle: String {
        if let name = draft?.destination?.name {
            return "Continue with \(name)"
        }
        return "Continue"
    }

    /// Whether the CTA can fire — there must be a chosen destination (every seed pre-selects one, so
    /// this is `true` in practice; it keeps the floor honest if a future flow clears the selection).
    var canContinue: Bool {
        draft?.destination != nil
    }

    // MARK: - Mapping

    /// Map one catalog `City` to its tile view-model: selected → definitive, others → fuzzy; the meta
    /// `Tag` from `City.meta`; the floating "plan started" badge only on an unselected planStarted tile.
    private func tile(for city: City) -> CityTileModel {
        let isSelected = draft?.destination?.id == city.id
        let isPlanStarted = city.meta == .planStarted
        return CityTileModel(
            city: city,
            certainty: isSelected ? .definitive : .fuzzy,
            isSelected: isSelected,
            metaLabel: metaLabel(for: city),
            showsPlanStartedBadge: isPlanStarted && !isSelected
        )
    }

    /// The inline subtitle beneath a tile name (mockup `.pcard .mt` — "Portugal · 23 saved"): the
    /// country joined to the meta's display label, unless the meta is the floating "plan started" badge.
    private func metaLabel(for city: City) -> String {
        if city.meta == .planStarted {
            return city.meta.displayLabel
        }
        return "\(city.country) · \(city.meta.displayLabel)"
    }
}
