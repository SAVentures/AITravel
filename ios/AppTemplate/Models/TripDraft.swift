// TripDraft.swift — the ONE reference model for the onboarding flow (plan W2-01).
//
// `TripDraft` is the single mutable graph the onboarding flow accumulates across its five steps
// and the UI observes per-field. It is owned by `AppStore` and mutated in place, so it is modeled
// as a `@MainActor @Observable final class` — step edits invalidate only their readers
// (02-models.md §1.1).
//
// Consequences of being a reference `@Observable` type (02-models.md §1.1):
//   - It is `@MainActor`-isolated; its isolation *is* its `Sendable` conformance, so it never
//     crosses the API boundary — the wire uses `TripDraftDTO` (TripDraftDTO.swift).
//   - It is NOT `Codable`; serialization is the DTO layer's job.
//   - Equality is identity-based; we do not declare value `Equatable`/`Hashable`. Tests assert on
//     fields, never `==`.
//   - It owns its mutations as pure, synchronous, in-place methods (02-models.md §2). No `Date()`,
//     no network, no SwiftUI import.
//
// The immutable seed catalog the provider served is carried as `let context: OnboardingContextDTO`
// so the live draft can read the saved-place counts and the seed options without re-fetching.
import Foundation

// MARK: - TripDraft

/// The single mutable onboarding draft — a `@MainActor @Observable` reference model the flow
/// accumulates across steps. Owned by `AppStore`, mutated in place via the model methods below.
///
/// Not `Codable`; identity equality (02-models.md §1.1). The value snapshot used for the wire /
/// seed parity round-trip is `TripDraftDTO` (`toDTO()` / `restore(from:)`).
@MainActor
@Observable
final class TripDraft: Identifiable {

    // MARK: Immutable catalog

    /// The seed catalog the provider served — the city options, neighborhoods, shape options,
    /// transport rec, generation plan, and saved-place counts. Read-only on the live draft;
    /// `savedHere` / `savedAnywhere` derive from it.
    let context: OnboardingContextDTO

    // MARK: Identity

    /// Stable seed id, e.g. `"draft-onboardingA"`.
    let id: String

    // MARK: Mutable selection fields

    /// The chosen destination city (value type).
    var destination: City?
    /// The selected trip-shape strategy — A/B/C selection (value enum).
    var shapeStrategy: TripShapeStrategy?
    /// The stepper value; defaults to 4.
    var tripDays: Int
    /// The taste profile populated in state C (value type).
    var tasteProfile: TasteProfile?
    /// The chosen base location (value type).
    var baseSelection: BaseLocation?
    /// How the base was chosen — smart vs manual.
    var baseMode: BaseSelectionMode
    /// The transport selection — primary + alsoOK set + suggested (value type).
    var transport: TransportSelection
    /// The step-nav cursor (value enum).
    var currentStep: OnboardingStep
    /// The six-step generation plan (value type).
    var generationPlan: GenerationPlan?
    /// The derived A/B/C branch (set from the catalog's saved-place counts).
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

    /// Saved places the user has in the chosen destination — drives the A branch.
    var savedHere: Int { context.savedHere }
    /// Saved places the user has anywhere — distinguishes B (`> 0`) from C (`== 0`).
    var savedAnywhere: Int { context.savedAnywhere }
}

// MARK: - Model methods (pure, in-place state transitions — 02-models.md §2)

extension TripDraft {

    /// Step 01 — pick the destination city.
    func select(city: City) {
        destination = city
    }

    /// Step 02 (A/B) — pick the trip-shape strategy.
    func select(strategy: TripShapeStrategy) {
        shapeStrategy = strategy
    }

    /// Step 02 — set the trip-day count.
    func setDays(_ days: Int) {
        tripDays = days
    }

    /// Step 02 (C) — toggle one interest in the taste profile. No-op contract: if no taste
    /// profile exists yet, seed an empty balanced one before toggling.
    func toggleInterest(_ interest: Interest) {
        var profile = tasteProfile ?? TasteProfile(days: tripDays, interests: [], pace: .balanced)
        if profile.interests.contains(interest) {
            profile.interests.remove(interest)
        } else {
            profile.interests.insert(interest)
        }
        tasteProfile = profile
    }

    /// Step 02 (C) — set the trip pace in the taste profile.
    func setPace(_ pace: Pace) {
        var profile = tasteProfile ?? TasteProfile(days: tripDays, interests: [], pace: pace)
        profile.pace = pace
        tasteProfile = profile
    }

    /// Step 03 — choose the base location.
    func select(base: BaseLocation) {
        baseSelection = base
    }

    /// Step 03 — set the base-selection mode (smart / manual).
    func setBaseMode(_ mode: BaseSelectionMode) {
        baseMode = mode
    }

    /// Step 04 — set the primary transport mode.
    func setPrimaryMode(_ mode: TransportMode) {
        transport.primary = mode
    }

    /// Step 04 — toggle one mode in the also-OK set.
    func toggleAlsoOK(_ mode: TransportMode) {
        if transport.alsoOK.contains(mode) {
            transport.alsoOK.remove(mode)
        } else {
            transport.alsoOK.insert(mode)
        }
    }

    /// Advance the step cursor by one, clamped to the `OnboardingStep` range.
    func advanceStep() {
        let next = currentStep.index + 1
        if let step = OnboardingStep(rawValue: next) {
            currentStep = step
        }
    }

    /// Retreat the step cursor by one, clamped to the `OnboardingStep` range.
    func retreatStep() {
        let previous = currentStep.index - 1
        if let step = OnboardingStep(rawValue: previous) {
            currentStep = step
        }
    }
}

// MARK: - restore(from:) — apply a value snapshot back onto the live reference

extension TripDraft {

    /// Apply a `TripDraftDTO` value snapshot back onto this live reference, in place
    /// (02-models.md §4 — the rollback / parity seam). `context` and `id` are immutable, so the
    /// snapshot must carry the same catalog; only the mutable selection fields are reapplied.
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
