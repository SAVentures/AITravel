/*
 The single mutable onboarding draft — a reference @Observable graph AppStore owns and mutates in
 place across the five steps, observed per-field. Never crosses the API boundary (it's MainActor-
 isolated); the wire uses TripDraftDTO. Identity equality, not Codable.

 `context` carries the immutable seed catalog so the live draft reads saved-place counts and seed
 options without re-fetching.
*/
import Foundation

// MARK: - TripDraftModel

@MainActor
@Observable
final class TripDraftModel: Identifiable {

    // MARK: Immutable catalog

    let context: OnboardingContextDTO

    // MARK: Identity

    let id: String

    // MARK: Mutable selection fields

    var destination: City?
    var shapeStrategy: TripShapeStrategy?
    var tripDays: Int
    var tasteProfile: TasteProfile?
    var baseSelection: BaseLocation?
    var baseMode: BaseSelectionMode
    var transport: TransportSelection
    var currentStep: OnboardingStep
    var generationPlan: GenerationPlan?
    var onboardingState: OnboardingState

    // MARK: Designated init

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

    // MARK: Derived (read the immutable catalog)

    var savedHere: Int { context.savedHere }       // drives the A branch
    var savedAnywhere: Int { context.savedAnywhere } // distinguishes B (> 0) from C (== 0)
}

// MARK: - Model methods

extension TripDraftModel {

    func select(city: City) {
        destination = city
    }

    func clearDestination() {
        destination = nil
    }

    func select(strategy: TripShapeStrategy) {
        shapeStrategy = strategy
    }

    func setDays(_ days: Int) {
        tripDays = days
    }

    // Seeds an empty balanced profile first if none exists yet.
    func toggleInterest(_ interest: Interest) {
        var profile = tasteProfile ?? TasteProfile(days: tripDays, interests: [], pace: .balanced)
        if profile.interests.contains(interest) {
            profile.interests.remove(interest)
        } else {
            profile.interests.insert(interest)
        }
        tasteProfile = profile
    }

    func setPace(_ pace: Pace) {
        var profile = tasteProfile ?? TasteProfile(days: tripDays, interests: [], pace: pace)
        profile.pace = pace
        tasteProfile = profile
    }

    func select(base: BaseLocation) {
        baseSelection = base
    }

    func setBaseMode(_ mode: BaseSelectionMode) {
        baseMode = mode
    }

    func setPrimaryMode(_ mode: TransportMode) {
        transport.primary = mode
    }

    func toggleAlsoOK(_ mode: TransportMode) {
        if transport.alsoOK.contains(mode) {
            transport.alsoOK.remove(mode)
        } else {
            transport.alsoOK.insert(mode)
        }
    }

    // Clamped to the OnboardingStep range.
    func advanceStep() {
        let next = currentStep.index + 1
        if let step = OnboardingStep(rawValue: next) {
            currentStep = step
        }
    }

    // Clamped to the OnboardingStep range.
    func retreatStep() {
        let previous = currentStep.index - 1
        if let step = OnboardingStep(rawValue: previous) {
            currentStep = step
        }
    }
}

// MARK: - restore(from:)

extension TripDraftModel {

    /* The rollback / parity seam. `context` and `id` are immutable, so the snapshot must carry the
       same catalog; only the mutable selection fields are reapplied. */
    func restore(from dto: TripDraftDTO) {
        destination = dto.destination
        shapeStrategy = dto.shapeStrategy
        tripDays = dto.tripDays
        tasteProfile = dto.tasteProfile
        baseSelection = dto.baseSelection
        baseMode = dto.baseMode
        transport = dto.transport
        currentStep = dto.currentStep
        generationPlan = dto.generationPlan
        onboardingState = dto.onboardingState
    }
}
