// GenerationPlan.swift — leaf value types for the generate step (W2-08).
//
// All five types are leaf value types (02-models.md §1): none are mutable rows in a list.
// `Codable, Equatable, Hashable, Sendable` throughout; `Identifiable` only where
// collection-stored (`GenerationStep` is an element of `[GenerationStep]`).
// No SwiftUI import — model layer never imports SwiftUI (02 §2).
import Foundation

// MARK: - StepState

/// The firming-up state of one generation step: done → current → pending.
/// Raw-`String` enum synthesises `Codable` for free (02 §3.1).
nonisolated enum StepState: String, Codable, Equatable, Hashable, Sendable {
    case done
    case current
    case pending
}

// MARK: - GenerationStep

/// One labelled step in the generation checklist.
/// `Identifiable` because it is stored in an ordered collection (`GenerationPlan.steps`).
nonisolated struct GenerationStep: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable literal id (e.g. `"step-cluster"`).
    let id: String
    /// The step body line (e.g. "Grouping your 23 places by neighborhood").
    let label: String
    /// An optional mono sub-line (e.g. "5 clusters found"). `nil` = no sub-line.
    let detail: String?
    /// Whether this step is done, currently running, or waiting.
    let state: StepState

    init(id: String, label: String, detail: String? = nil, state: StepState) {
        self.id = id
        self.label = label
        self.detail = detail
        self.state = state
    }
}

// MARK: - GenerationPlan

/// The full generate-step plan: an ordered checklist of 6 steps plus display copy and
/// timing metadata. Not `Identifiable` — it is a value held directly on `TripDraft`,
/// never stored in an independent keyed collection.
nonisolated struct GenerationPlan: Codable, Equatable, Hashable, Sendable {
    /// The six planning steps, ordered leading → trailing.
    var steps: [GenerationStep]
    /// Estimated wall-clock duration in seconds (default 8).
    var etaSeconds: Int
    /// Mono caps eyebrow on the handoff peek (e.g. "Up next · Trip overview").
    var handoffEyebrow: String
    /// Italic display line on the handoff peek (e.g. "Lisbon · 4 days, your shape.").
    var handoffLine: String
    /// Primary headline shown above the checklist.
    var headline: String
    /// Sub-copy shown below the headline.
    var sub: String
    /// The index of the step currently in the `.current` state (0–5).
    var currentStepIndex: Int

    init(
        steps: [GenerationStep],
        etaSeconds: Int = 8,
        handoffEyebrow: String,
        handoffLine: String,
        headline: String,
        sub: String,
        currentStepIndex: Int
    ) {
        self.steps = steps
        self.etaSeconds = etaSeconds
        self.handoffEyebrow = handoffEyebrow
        self.handoffLine = handoffLine
        self.headline = headline
        self.sub = sub
        self.currentStepIndex = currentStepIndex
    }
}

// MARK: - OnboardingState

/// Which of the three data-driven branches (A / B / C) the onboarding flow takes, derived
/// from `savedHere` / `savedAnywhere` counts (03-store.md AppStore+Onboarding derivation).
/// Raw-`String` enum synthesises `Codable` for free (02 §3.1).
nonisolated enum OnboardingState: String, Codable, Equatable, Hashable, Sendable {
    /// A — returning user with saved places in this city (`savedHere > 0`).
    case returningWithLocalSaves
    /// B — saves elsewhere but not in this city (`savedHere == 0 && savedAnywhere > 0`).
    case savesElsewhere
    /// C — first trip, no saves anywhere (`savedAnywhere == 0`).
    case firstTrip
}

// MARK: - OnboardingStep

/// The five-step cursor for the onboarding flow.
/// `Int` raw values (0–4) allow array-index arithmetic and `progressCount` helpers.
/// `CaseIterable` lets the store and tests enumerate all steps without hard-coding bounds.
nonisolated enum OnboardingStep: Int, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case destination    = 0
    case tripShape      = 1
    case baseLocation   = 2
    case gettingAround  = 3
    case generating     = 4

    /// Zero-based index of this step (equals `rawValue`).
    var index: Int { rawValue }

    /// The total number of steps in the flow.
    static var totalSteps: Int { allCases.count }   // 5

    /// A human-readable progress label: "1 / 5", "2 / 5", …
    var progressCount: String { "\(index + 1) / \(OnboardingStep.totalSteps)" }
}
