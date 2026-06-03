/*
 The wire/domain DTO carrying the seed catalog a MockProvider serves for one onboarding scenario.
 Reuses the leaf value types directly — they are already wire-safe, so there is no per-leaf DTO.
 Only the DTOs and leaf value types are Codable; TripDraftModel is not — toDomain() builds its
 reference graph on the main actor.
*/
import Foundation

// MARK: - OnboardingContextDTO

nonisolated struct OnboardingContextDTO: Codable, Equatable, Sendable {

    var destination: City
    var cityOptions: [City]
    var neighborhoods: [Neighborhood]
    var recommendedBase: BaseLocation
    var shapeOptions: [TripShapeOption]  // empty in state C (taste-form path)
    var tasteDefaults: TasteProfile?     // nil for states A/B
    var transportRec: TransportRec
    var generationPlan: GenerationPlan
    var savedHere: Int                   // saved places in the chosen destination — drives the A branch
    var savedAnywhere: Int               // saved places anywhere — distinguishes B from C

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

// MARK: - toDomain

extension OnboardingContextDTO {

    private static let defaultTripDays = 4

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
