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
    var tripWhen: TripWhen
    var tasteProfile: TasteProfile?
    var baseSelection: BaseLocation?
    // The manually-picked neighborhood (baseMode == .manual). Neighborhoods carry no coordinates, so the
    // pick is captured by id, not as a BaseLocation.
    var selectedNeighborhoodID: String?
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

    // MARK: - When (month-led travel dates)

    func setTripMonth(year: Int, month: Int) {
        tripWhen.year = year
        tripWhen.month = month
    }

    func setDatePrecision(_ precision: DatePrecision) {
        tripWhen.precision = precision
        switch precision {
        case .exactDates:
            // Seed a concrete range from the chosen month, spanning at least the chosen trip length.
            if tripWhen.startDate == nil {
                let start = AppDate.make(y: tripWhen.year, m: tripWhen.month, d: 1)
                tripWhen.startDate = start
                tripWhen.endDate = minimumExactEnd(from: start)
            }
        case .justMonth:
            tripWhen.startDate = nil
            tripWhen.endDate = nil
        }
    }

    func setExactStart(_ date: Date) {
        tripWhen.startDate = date
        // Keep the range at least `tripDays` long when the start moves.
        let minEnd = minimumExactEnd(from: date)
        if let end = tripWhen.endDate, end >= minEnd { return }
        tripWhen.endDate = minEnd
    }

    func setExactEnd(_ date: Date) {
        guard let start = tripWhen.startDate else { tripWhen.endDate = date; return }
        // The range can't be shorter than the trip length chosen on the Trip Shape step.
        tripWhen.endDate = max(date, minimumExactEnd(from: start))
    }

    /// The earliest end date that still spans `tripDays` (inclusive) from `start`.
    private func minimumExactEnd(from start: Date) -> Date {
        AppDate.calendar.date(byAdding: .day, value: max(tripDays - 1, 0), to: start) ?? start
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

    // Manual mode: a neighborhood pick and a specific-address pin are mutually exclusive — choosing one
    // clears the other so the CTA reads a single base.
    func selectNeighborhood(_ id: String) {
        selectedNeighborhoodID = id
        baseSelection = nil
    }

    func selectSpecificBase(_ base: BaseLocation) {
        baseSelection = base
        selectedNeighborhoodID = nil
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
        tripWhen = dto.tripWhen
        tasteProfile = dto.tasteProfile
        baseSelection = dto.baseSelection
        selectedNeighborhoodID = dto.selectedNeighborhoodID
        baseMode = dto.baseMode
        transport = dto.transport
        currentStep = dto.currentStep
        generationPlan = dto.generationPlan
        onboardingState = dto.onboardingState
    }
}
