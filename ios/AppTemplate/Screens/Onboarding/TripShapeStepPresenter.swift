/*
 Stateless derivation for onboarding Step 02 — the "one view, two bodies" screen (OPEN DECISION 2):
 states A/B render three selectable TripShapeCards; state C renders a taste form. This presenter owns
 the branch decision (step02Mode) and all model → component value-type mapping, so the view stays
 layout + wiring only.

 Hero copy is screen-specific (not in the DTO — each named mockup hardcodes its own eyebrow/question/
 sub), so it is derived here per A/B/C branch. Rebuilt every body pass; kept cheap.
*/
import SwiftUI

// MARK: - step02Mode

/// The two structurally-different bodies Step 02 can show under one step + chrome + CTA.
enum TripShapeStepMode: Equatable {
    case shapeCards
    case tasteForm
}

// MARK: - TripShapeCardModel

/// A fully-resolved view-model for one `TripShapeCard`: the model's `TripShapeOption` + `DiagramSpec`
/// mapped to the component's own value types so the view only places the component. The `id` suffix
/// (`a`/`b`/`c`) drives both the a11y id (`tripshape.<id>` / `tripshape.<id>.locked`) and the selected key.
struct TripShapeCardModel: Identifiable {
    let id: String
    let strategy: TripShapeStrategy
    let eyebrow: String
    let title: String
    let metricStrip: [MetricToken]  // empty when locked
    let diagram: TripShapeDiagram
    let register: TripShapeRegister
    let isSelected: Bool
    let embedsStepper: Bool  // only the fixed-days card A
}

// MARK: - TripShapeStepPresenter

/// Stateless derivation for `TripShapeStepView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved.
struct TripShapeStepPresenter {

    let store: AppStore

    private var draft: TripDraftModel? { store.onboarding }

    // MARK: Branch

    /// A/B → the shape cards; C (`firstTrip`) → the taste form.
    var step02Mode: TripShapeStepMode {
        store.onboardingState == .firstTrip ? .tasteForm : .shapeCards
    }

    // MARK: Hero copy (screen-specific — not in the DTO; mirrors the named mockups per branch)

    var heroEyebrow: String { "Trip shape" }

    var heroQuestion: String {
        switch step02Mode {
        case .shapeCards: "How should this trip fit?"
        case .tasteForm:  "What kind of trip is this?"
        }
    }

    var heroSub: String {
        switch store.onboardingState {
        case .returningWithLocalSaves:
            return "You've saved \(store.savedHere) places. Plan around your days, your whole list, or just the highlights — each makes a different trip."
        case .savesElsewhere:
            return "You haven't saved places here yet — so we'll plan from the city's best, shaped by the taste we read in your other trips."
        case .firstTrip, .none:
            return "No saved places yet — so tell us the shape, and we'll fill it with the city's best."
        }
    }

    // MARK: Shape cards (A/B)

    /// The three shape cards, each option + diagram mapped to the component's value types. Empty in state
    /// C (the DTO's `shapeOptions` is empty there).
    var shapeCards: [TripShapeCardModel] {
        guard let draft else { return [] }
        return draft.context.shapeOptions.enumerated().map { index, option in
            let locked = isLocked(option)
            return TripShapeCardModel(
                id: cardID(for: index),
                strategy: option.strategy,
                eyebrow: option.eyebrow,
                title: option.title,
                metricStrip: locked ? [] : metricTokens(from: option.metricStrip),
                diagram: diagram(from: option.diagram),
                register: register(for: option, locked: locked),
                isSelected: !locked && draft.shapeStrategy == option.strategy,
                embedsStepper: option.strategy == .fixedDays
            )
        }
    }

    var selectedStrategy: TripShapeStrategy? { draft?.shapeStrategy }

    // MARK: Taste form (C)

    var tasteDays: Int { draft?.tripDays ?? OnboardingDefaults.tripDays }

    var interestChips: [FilterChipModel] {
        Interest.allCases.map { interest in
            FilterChipModel(label: interest.label, isSelected: selectedInterests.contains(interest))
        }
    }

    var selectedInterests: Set<Interest> { draft?.tasteProfile?.interests ?? [] }

    /// The view zips these with `interestChips` so the toggle callback knows which `Interest` each maps to.
    var interests: [Interest] { Interest.allCases }

    var paceOptions: [Pace] { Pace.allCases }

    var pace: Pace { draft?.tasteProfile?.pace ?? .balanced }

    // MARK: CTA

    /// State-driven so the CTA tracks the selection: a prompt while nothing is picked (paired with the
    /// disabled floor), then the chosen shape once a card is selected. C's taste form is day-led.
    var ctaTitle: String {
        switch step02Mode {
        case .tasteForm:
            return "Continue · \(tasteDays) days"
        case .shapeCards:
            guard let selected = shapeCards.first(where: { $0.isSelected }) else {
                return "Choose a trip shape"
            }
            // The fixed-days card embeds the stepper, so its CTA is day-led; the others name the shape.
            if selected.strategy == .fixedDays {
                return "Continue · \(tasteDays) days"
            }
            return "Continue · \(shortLabel(selected.eyebrow))"
        }
    }

    /// A/B require an explicit shape pick before advancing (no card is preselected); C's taste form is
    /// valid from its defaults, so it's always continuable.
    var canContinue: Bool {
        switch step02Mode {
        case .shapeCards: selectedStrategy != nil
        case .tasteForm:  true
        }
    }

    /// The card eyebrow is "A · Fixed days" / "B · Cover the bucket" — drop the "X · " index prefix so the
    /// CTA reads the shape's name, not its slot letter.
    private func shortLabel(_ eyebrow: String) -> String {
        eyebrow.components(separatedBy: " · ").last ?? eyebrow
    }

    // MARK: - Private mapping helpers

    /// Locked when the option opts in (`lockable`), carries a reason, and the destination has no local
    /// saves — B's cover-bucket before any local saves.
    private func isLocked(_ option: TripShapeOption) -> Bool {
        option.lockable && option.lockReason != nil && store.savedHere == 0
    }

    private func register(for option: TripShapeOption, locked: Bool) -> TripShapeRegister {
        if locked, let reason = option.lockReason {
            return .locked(reason: reason)
        }
        return .selectable
    }

    /// Drop the model's pure separator fragments (" · ") — the component draws the middot between tokens
    /// itself, so a separator fragment would double it up.
    private func metricTokens(from fragments: [MetricFragment]) -> [MetricToken] {
        fragments
            .filter { !isSeparator($0) }
            .map { MetricToken($0.text, emphasis: $0.emphasis, struck: $0.struck) }
    }

    private func isSeparator(_ fragment: MetricFragment) -> Bool {
        let trimmed = fragment.text.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || trimmed == "·"
    }

    private func diagram(from spec: DiagramSpec) -> TripShapeDiagram {
        switch spec {
        case let .fixedDays(filled, dim):
            return .fixedDays(filled: filled, dim: dim)
        case let .coverBucket(dayCounts):
            return .coverBucket(dayCounts: dayCounts)
        case let .rankedBars(values, pickIndex, dimIndex):
            return .rankedBars(values: values, dim: dimIndex, pick: pickIndex)
        }
    }

    private func cardID(for index: Int) -> String {
        switch index {
        case 0: "a"
        case 1: "b"
        default: "c"
        }
    }
}

// MARK: - Defaults

/// Mirrors `OnboardingContextDTO.defaultTripDays`.
private enum OnboardingDefaults {
    static let tripDays = 4
}
