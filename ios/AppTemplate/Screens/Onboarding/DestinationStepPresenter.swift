/*
 Stateless derivation for onboarding step 01 (the destination picker). Derives per-state hero copy,
 search value, AI-voice line, and the rail + grid CityTileModels (City → register/selection/meta).
 Ports state-{a,b,c}-screen-01-destination.html.

 The A/B/C branch (onboardingState) is derived on the store, not here — this presenter only reads it
 to pick per-state copy.
*/
import Foundation

// MARK: - CityTileModel

/* One destination tile, fully derived for the view. Certainty via elevation, never a fill (J-8):
   selected → .definitive (ink ring + check), rest → .fuzzy. */
struct CityTileModel: Identifiable, Sendable {

    let city: City

    let certainty: PlaceCertainty

    let isSelected: Bool

    let metaLabel: String

    // The floating "plan started" badge (mockup .saved tag), not the inline subtitle — only on an
    // unselected .planStarted tile.
    let showsPlanStartedBadge: Bool

    var id: String { city.id }
}

// MARK: - DestinationStepPresenter

// Constructed in `body` from the store so per-field dependency tracking is preserved (06-screens §3).
struct DestinationStepPresenter {

    let store: AppStore

    let searchText: String

    init(store: AppStore, searchText: String = "") {
        self.store = store
        self.searchText = searchText
    }

    // MARK: - Catalog access

    private var draft: TripDraftModel? { store.onboarding }

    private var context: OnboardingContextDTO? { draft?.context }

    // Defaults to .firstTrip when absent so every accessor stays total.
    private var state: OnboardingState { store.onboardingState ?? .firstTrip }

    // MARK: - Hero copy

    var eyebrow: String { "Destination" }

    var question: String {
        switch state {
        case .returningWithLocalSaves, .savesElsewhere:
            "Where are you headed?"
        case .firstTrip:
            "Where to first?"
        }
    }

    var sub: String {
        switch state {
        case .returningWithLocalSaves, .savesElsewhere:
            "Pick a city — we'll bring your saved places along."
        case .firstTrip:
            "Your first trip — pick a city and we'll build the rest from its best."
        }
    }

    // MARK: - Search well

    var searchValue: String {
        draft?.destination?.name ?? ""
    }

    // MARK: - AI voice

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

    // MARK: - Recent rail + grid

    var gridCities: [CityTileModel] {
        matchingCities.map { tile(for: $0) }
    }

    // Same catalog as the grid, surfaced as the "Recent" rail — filtered by the same query so both
    // narrow in lockstep.
    var recentCities: [CityTileModel] {
        matchingCities.map { tile(for: $0) }
    }

    // Exposed so the view's search-results mode can render these as a vertical list while the default
    // layout uses recentCities / gridCities.
    var matchingCities: [City] {
        let cities = context?.cityOptions ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return cities }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - CTA

    var ctaTitle: String {
        if let name = draft?.destination?.name {
            return "Continue with \(name)"
        }
        return "Continue"
    }

    var canContinue: Bool {
        draft?.destination != nil
    }

    // MARK: - Mapping

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

    private func metaLabel(for city: City) -> String {
        if city.meta == .planStarted {
            return city.meta.displayLabel
        }
        return "\(city.country) · \(city.meta.displayLabel)"
    }
}
