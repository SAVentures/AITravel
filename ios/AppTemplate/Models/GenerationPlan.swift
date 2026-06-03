/*
 Leaf value types for the onboarding generate step (W2-08): the step checklist, the plan
 holding it, and the two onboarding-flow enums. All value types — none are mutable list rows.
 `Identifiable` only on GenerationStep, since it is collection-stored.
*/
import Foundation

// MARK: - StepState

nonisolated enum StepState: String, Codable, Equatable, Hashable, Sendable {
    case done
    case current
    case pending
}

// MARK: - GenerationStep

nonisolated struct GenerationStep: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let label: String
    let detail: String?  // nil = no mono sub-line
    let state: StepState

    init(id: String, label: String, detail: String? = nil, state: StepState) {
        self.id = id
        self.label = label
        self.detail = detail
        self.state = state
    }
}

// MARK: - GenerationPlan

nonisolated struct GenerationPlan: Codable, Equatable, Hashable, Sendable {
    var steps: [GenerationStep]
    var etaSeconds: Int
    var handoffEyebrow: String
    var handoffLine: String
    var headline: String
    var sub: String
    var currentStepIndex: Int  // index of the step in .current state

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

/// Which data-driven branch the onboarding flow takes, derived from savedHere / savedAnywhere counts.
nonisolated enum OnboardingState: String, Codable, Equatable, Hashable, Sendable {
    case returningWithLocalSaves  // savedHere > 0
    case savesElsewhere           // savedHere == 0 && savedAnywhere > 0
    case firstTrip                // savedAnywhere == 0
}

// MARK: - OnboardingStep

nonisolated enum OnboardingStep: Int, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case destination    = 0
    case tripShape      = 1
    case baseLocation   = 2
    case gettingAround  = 3
    case generating     = 4

    var index: Int { rawValue }
    static var totalSteps: Int { allCases.count }

    var progressCount: String { "\(index + 1) / \(OnboardingStep.totalSteps)" }  // "1 / 5"
}
