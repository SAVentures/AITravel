// OnboardingContextDTO.swift — the seed catalog the provider serves (plan W2-09).
//
// `OnboardingContextDTO` is the wire/domain DTO that carries the seed for one onboarding scenario:
// the destination, the city catalog, the neighborhood alternatives, the recommended base, the
// trip-shape options, the transport rec, the generation plan, and the saved-place counts. It reuses
// the leaf value types directly — they are already wire-safe, so there is no per-leaf DTO
// (02-models.md §1.2 / §4).
//
// `toDomain()` builds the seed `TripDraftModel` reference graph on the main actor (02-models.md §4).
// Only the DTOs and the leaf value types are `Codable`; `TripDraftModel` is not.
import Foundation

// MARK: - OnboardingContextDTO

/// The seed catalog a `MockProvider` serves for one onboarding scenario.
///
/// `Codable, Equatable, Sendable` — the wire shape (02-models.md §4). All fields are leaf value
/// types reused directly; there is no `CityDTO` / `NeighborhoodDTO` / etc.
nonisolated struct OnboardingContextDTO: Codable, Equatable, Sendable {

    /// The chosen city for this scenario.
    var destination: City
    /// The full city catalog — the recent rail plus the "more cities" grid.
    var cityOptions: [City]
    /// Base-location alternatives, including the recommended one.
    var neighborhoods: [Neighborhood]
    /// The recommended base — pins + coordinates + zone label.
    var recommendedBase: BaseLocation
    /// The step-02 trip-shape cards for states A/B. **Empty** in state C (taste-form path).
    var shapeOptions: [TripShapeOption]
    /// The pre-selected taste profile for state C; `nil` for states A/B.
    var tasteDefaults: TasteProfile?
    /// The AI transport recommendation.
    var transportRec: TransportRec
    /// The six-step generation plan.
    var generationPlan: GenerationPlan
    /// Saved places the user has in the chosen destination (drives the A branch).
    var savedHere: Int
    /// Saved places the user has anywhere (distinguishes B from C).
    var savedAnywhere: Int

    init(
        destination: City,
        cityOptions: [City],
        neighborhoods: [Neighborhood],
        recommendedBase: BaseLocation,
        shapeOptions: [TripShapeOption],
        tasteDefaults: TasteProfile?,
        transportRec: TransportRec,
        generationPlan: GenerationPlan,
        savedHere: Int,
        savedAnywhere: Int
    ) {
        self.destination = destination
        self.cityOptions = cityOptions
        self.neighborhoods = neighborhoods
        self.recommendedBase = recommendedBase
        self.shapeOptions = shapeOptions
        self.tasteDefaults = tasteDefaults
        self.transportRec = transportRec
        self.generationPlan = generationPlan
        self.savedHere = savedHere
        self.savedAnywhere = savedAnywhere
    }
}

// MARK: - Derived branch

extension OnboardingContextDTO {

    /// The A/B/C branch derived from the saved-place counts (02-models §3 / plan W2-09):
    /// - A (`returningWithLocalSaves`): `savedHere > 0`
    /// - B (`savesElsewhere`): `savedHere == 0 && savedAnywhere > 0`
    /// - C (`firstTrip`): `savedAnywhere == 0`
    var onboardingState: OnboardingState {
        if savedHere > 0 {
            return .returningWithLocalSaves
        } else if savedAnywhere > 0 {
            return .savesElsewhere
        } else {
            return .firstTrip
        }
    }
}

// MARK: - toDomain — build the seed TripDraftModel (02-models.md §4)

extension OnboardingContextDTO {

    /// The default trip length, in days, a fresh draft starts at (plan W2-09).
    private static let defaultTripDays = 4

    /// Build the seed `TripDraftModel` from the catalog, on the main actor.
    ///
    /// Seeds `destination`, a default `tripDays`, `currentStep = .destination`, the `transport`
    /// from `transportRec.suggestedMode`, the `generationPlan`, `tasteProfile = tasteDefaults`, the
    /// derived `onboardingState`, and carries the catalog as `context`. The draft id is
    /// `"draft-<onboardingState>"`.
    @MainActor
    func toDomain() -> TripDraftModel {
        let suggested = transportRec.suggestedMode
        let seedTransport = TransportSelection(
            primary: suggested,
            alsoOK: [],
            suggested: suggested
        )
        return TripDraftModel(
            context: self,
            id: "draft-\(onboardingState.rawValue)",
            destination: destination,
            shapeStrategy: nil,
            tripDays: Self.defaultTripDays,
            tasteProfile: tasteDefaults,
            baseSelection: nil,
            baseMode: .smart,
            transport: seedTransport,
            currentStep: .destination,
            generationPlan: generationPlan,
            onboardingState: onboardingState
        )
    }
}
