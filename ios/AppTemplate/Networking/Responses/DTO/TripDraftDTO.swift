// TripDraftDTO.swift — the value-type wire mirror of the `TripDraftModel` reference model (plan W2-01/W2-09).
//
// `TripDraftModel` is `@MainActor` and not `Codable`, so the wire / seed-parity boundary uses this value
// DTO (02-models.md §4). `TripDraftDTO` mirrors every field of `TripDraftModel` — including the immutable
// `context: OnboardingContextDTO` catalog — so the mapping is **total**:
//
//     dto.toDomain().toDTO() == dto        (round-trip invariant — unit-tested, 07-testing.md §4.2)
//
// `toDomain()` is `@MainActor` (it constructs a `@MainActor` reference model); `toDTO()` snapshots
// the live reference back to a value. Only the DTOs and leaf value types are `Codable`.
import Foundation

// MARK: - TripDraftDTO

/// The value-type mirror of `TripDraftModel`. `Codable, Equatable, Sendable` — the wire / parity shape.
///
/// Mirrors every `TripDraftModel` field field-for-field, including the immutable `context` catalog, so
/// the `toDomain()` / `toDTO()` round-trip is total (02-models.md §4).
nonisolated struct TripDraftDTO: Codable, Equatable, Sendable {

    /// The seed catalog this draft was built from.
    var context: OnboardingContextDTO
    /// Stable seed id.
    var id: String
    /// The chosen destination city.
    var destination: City?
    /// The selected trip-shape strategy.
    var shapeStrategy: TripShapeStrategy?
    /// The stepper value.
    var tripDays: Int
    /// The state-C taste profile.
    var tasteProfile: TasteProfile?
    /// The chosen base location.
    var baseSelection: BaseLocation?
    /// How the base was chosen.
    var baseMode: BaseSelectionMode
    /// The transport selection.
    var transport: TransportSelection
    /// The step-nav cursor.
    var currentStep: OnboardingStep
    /// The six-step generation plan.
    var generationPlan: GenerationPlan?
    /// The derived A/B/C branch.
    var onboardingState: OnboardingState

    init(
        context: OnboardingContextDTO,
        id: String,
        destination: City?,
        shapeStrategy: TripShapeStrategy?,
        tripDays: Int,
        tasteProfile: TasteProfile?,
        baseSelection: BaseLocation?,
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
        self.tasteProfile = tasteProfile
        self.baseSelection = baseSelection
        self.baseMode = baseMode
        self.transport = transport
        self.currentStep = currentStep
        self.generationPlan = generationPlan
        self.onboardingState = onboardingState
    }
}

// MARK: - TripDraftModel → TripDraftDTO (snapshot the live reference back)

extension TripDraftModel {

    /// Snapshot this live reference graph back into a value DTO (02-models.md §4). Captures every
    /// field so the round-trip is total.
    func toDTO() -> TripDraftDTO {
        TripDraftDTO(
            context: context,
            id: id,
            destination: destination,
            shapeStrategy: shapeStrategy,
            tripDays: tripDays,
            tasteProfile: tasteProfile,
            baseSelection: baseSelection,
            baseMode: baseMode,
            transport: transport,
            currentStep: currentStep,
            generationPlan: generationPlan,
            onboardingState: onboardingState
        )
    }
}

// MARK: - TripDraftDTO → TripDraftModel (build the reference graph on the main actor)

extension TripDraftDTO {

    /// Build the `TripDraftModel` reference graph from this snapshot, on the main actor. Every field is
    /// carried through verbatim so `dto.toDomain().toDTO() == dto` holds (02-models.md §4).
    @MainActor
    func toDomain() -> TripDraftModel {
        TripDraftModel(
            context: context,
            id: id,
            destination: destination,
            shapeStrategy: shapeStrategy,
            tripDays: tripDays,
            tasteProfile: tasteProfile,
            baseSelection: baseSelection,
            baseMode: baseMode,
            transport: transport,
            currentStep: currentStep,
            generationPlan: generationPlan,
            onboardingState: onboardingState
        )
    }
}
