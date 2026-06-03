/*
 Value-type wire/parity mirror of the `@MainActor`, non-Codable `TripDraftModel`. Mirrors every field
 (incl. the immutable `context` catalog) so the mapping is total: `dto.toDomain().toDTO() == dto`.
 `toDomain()` is `@MainActor` (it builds the reference model); `toDTO()` snapshots the live reference back.
*/
import Foundation

// MARK: - TripDraftDTO

nonisolated struct TripDraftDTO: Codable, Equatable, Sendable {

    var context: OnboardingContextDTO
    var id: String
    var destination: City?
    var shapeStrategy: TripShapeStrategy?
    var tripDays: Int
    var tripWhen: TripWhen
    var tasteProfile: TasteProfile?
    var baseSelection: BaseLocation?
    var selectedNeighborhoodID: String?
    var baseMode: BaseSelectionMode
    var transport: TransportSelection
    var currentStep: OnboardingStep
    var generationPlan: GenerationPlan?
    var onboardingState: OnboardingState

    init(
        context: OnboardingContextDTO,
        id: String,
        destination: City?,
        shapeStrategy: TripShapeStrategy?,
        tripDays: Int,
        tripWhen: TripWhen = .seedDefault,
        tasteProfile: TasteProfile?,
        baseSelection: BaseLocation?,
        selectedNeighborhoodID: String? = nil,
        baseMode: BaseSelectionMode,
        transport: TransportSelection,
        currentStep: OnboardingStep,
        generationPlan: GenerationPlan?,
        onboardingState: OnboardingState
    ) {
        self.context = context
        self.id = id
        self.destination = destination
        self.shapeStrategy = shapeStrategy
        self.tripDays = tripDays
        self.tripWhen = tripWhen
        self.tasteProfile = tasteProfile
        self.baseSelection = baseSelection
        self.selectedNeighborhoodID = selectedNeighborhoodID
        self.baseMode = baseMode
        self.transport = transport
        self.currentStep = currentStep
        self.generationPlan = generationPlan
        self.onboardingState = onboardingState
    }
}

// MARK: - TripDraftModel → TripDraftDTO

extension TripDraftModel {

    func toDTO() -> TripDraftDTO {
        TripDraftDTO(
            context: context,
            id: id,
            destination: destination,
            shapeStrategy: shapeStrategy,
            tripDays: tripDays,
            tripWhen: tripWhen,
            tasteProfile: tasteProfile,
            baseSelection: baseSelection,
            selectedNeighborhoodID: selectedNeighborhoodID,
            baseMode: baseMode,
            transport: transport,
            currentStep: currentStep,
            generationPlan: generationPlan,
            onboardingState: onboardingState
        )
    }
}

// MARK: - TripDraftDTO → TripDraftModel

extension TripDraftDTO {

    @MainActor
    func toDomain() -> TripDraftModel {
        TripDraftModel(
            context: context,
            id: id,
            destination: destination,
            shapeStrategy: shapeStrategy,
            tripDays: tripDays,
            tripWhen: tripWhen,
            tasteProfile: tasteProfile,
            baseSelection: baseSelection,
            selectedNeighborhoodID: selectedNeighborhoodID,
            baseMode: baseMode,
            transport: transport,
            currentStep: currentStep,
            generationPlan: generationPlan,
            onboardingState: onboardingState
        )
    }
}
