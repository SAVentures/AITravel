// TripShapeStepPresenter.swift — the stateless derivation for onboarding Step 02 (plan W4-02).
//
// Step 02 is the "one view, two bodies" screen (OPEN DECISION 2): states A/B render three selectable
// `TripShapeCard`s; state C renders a taste form (day stepper + interest chips + pace). Both bodies live
// under one step, one chrome, one CTA. THIS presenter owns the branch decision (`step02Mode`) and ALL
// model → component mapping, so the view stays layout + wiring only (`06-screens.md §1/§3`):
//
//   • `TripShapeOption` + `DiagramSpec` (model)  →  `TripShapeCardModel` carrying the component's own
//     `MetricToken` / `TripShapeDiagram` / `TripShapeRegister` value types (mapped HERE, not in `body`).
//   • `Interest` (model)  →  `FilterChipModel` + the selected set.
//   • the hero copy, which is screen-specific (it is NOT in the DTO — each named mockup hardcodes its
//     own eyebrow / question / sub), so it is derived here per A/B/C branch.
//
// Returns data / view-models, never `View`s (`06-screens.md §3.1`): the locked register, the diagram
// spec, and the metric fragments are all value types the view assembles into components. Kept cheap — it
// is rebuilt every `body` pass. Imports SwiftUI only because it returns the component value types.
import SwiftUI

// MARK: - step02Mode — which of the two bodies this step renders

/// The two structurally-different bodies Step 02 can show under one step + chrome + CTA. Derived from the
/// store's A/B/C branch: A/B show the three shape cards, C shows the taste form (`OPEN DECISION 2`).
enum TripShapeStepMode: Equatable {
    /// States A / B — a column of three selectable `TripShapeCard`s (one may be `.locked` in B).
    case shapeCards
    /// State C — the taste form (day stepper + interest chips + pace selector).
    case tasteForm
}

// MARK: - TripShapeCardModel — one card, fully mapped to the component's value types

/// A fully-resolved view-model for one `TripShapeCard`: the model's `TripShapeOption` + `DiagramSpec`
/// mapped to the COMPONENT's own value types (`MetricToken`, `TripShapeDiagram`, `TripShapeRegister`) so
/// the view only places the component (`06-screens.md §3.1`). The `id` suffix (`a`/`b`/`c`) drives both
/// the a11y id (`tripshape.<id>` / `tripshape.<id>.locked`) and the card's selected key.
struct TripShapeCardModel: Identifiable {
    /// The caller id suffix — `a` (fixed days) / `b` (cover bucket) / `c` (highlights).
    let id: String
    /// The trip-shape strategy this card selects when tapped.
    let strategy: TripShapeStrategy
    /// The mono caps eyebrow ("A · Fixed days").
    let eyebrow: String
    /// The display title ("Pack four great days.").
    let title: String
    /// The mono metric strip fragments, mapped to the component's `MetricToken`. Empty when locked.
    let metricStrip: [MetricToken]
    /// The embedded shape diagram, mapped to the component's `TripShapeDiagram`.
    let diagram: TripShapeDiagram
    /// The register — `.selectable` or `.locked(reason:)` (B's cover-bucket before local saves).
    let register: TripShapeRegister
    /// Whether this card is the chosen one (ink ring + check). Always `false` for a locked card.
    let isSelected: Bool
    /// Whether this card embeds the inline `DayStepper` under its title (only the fixed-days card A).
    let embedsStepper: Bool
}

// MARK: - TripShapeStepPresenter

/// Stateless derivation for `TripShapeStepView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved (`06-screens.md §3`).
struct TripShapeStepPresenter {

    /// The single source of truth the step reads. Held, never mutated here.
    let store: AppStore

    /// The active draft, or `nil` pre-hydration. The view renders nothing without it.
    private var draft: TripDraftModel? { store.onboarding }

    // MARK: Branch

    /// Which body this step renders. A/B → the shape cards; C (`firstTrip`) → the taste form. Defaults to
    /// the card body when there is no active draft (the view guards on the draft anyway).
    var step02Mode: TripShapeStepMode {
        store.onboardingState == .firstTrip ? .tasteForm : .shapeCards
    }

    // MARK: Hero copy (screen-specific — not in the DTO; mirrors the named mockups per branch)

    /// The mono caps eyebrow above the hero question — "Trip shape" on every branch (the named mockups'
    /// `.eyebrow`).
    var heroEyebrow: String { "Trip shape" }

    /// The hero question (`.q`). A/B ask how the trip should *fit* (the shape cards); C asks what *kind*
    /// of trip it is (the taste form) — straight from the named mockups.
    var heroQuestion: String {
        switch step02Mode {
        case .shapeCards: "How should this trip fit?"
        case .tasteForm:  "What kind of trip is this?"
        }
    }

    /// The hero sub copy (`.sub`), per branch. A names the saved count; B explains the city's-best pivot;
    /// C explains the taste-first path (the named mockups' `.sub`).
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

    // MARK: Shape cards (A/B) — model → component value types, mapped here

    /// The three shape cards, with each `TripShapeOption` + `DiagramSpec` mapped to the component's value
    /// types. A card is `.locked` when its option is `lockable`, has a lock reason, and the destination
    /// has no local saves (B's cover-bucket); otherwise `.selectable`. The fixed-days card carries the
    /// inline `DayStepper` flag. Empty in state C (the DTO's `shapeOptions` is empty there).
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

    /// The currently-selected strategy (drives each card's `isSelected`), or `nil` before a pick.
    var selectedStrategy: TripShapeStrategy? { draft?.shapeStrategy }

    // MARK: Taste form (C)

    /// The current trip-day count for the standalone `DayStepper`. Defaults to the draft's `tripDays`.
    var tasteDays: Int { draft?.tripDays ?? OnboardingDefaults.tripDays }

    /// The interest chips, one per `Interest` case, mapped to `FilterChipModel` with the selected set
    /// reflected. The selected set is the taste profile's interests (empty if none yet).
    var interestChips: [FilterChipModel] {
        Interest.allCases.map { interest in
            FilterChipModel(label: interest.label, isSelected: selectedInterests.contains(interest))
        }
    }

    /// The set of interests the user has toggled on (drives each chip's selected state + the a11y trait).
    var selectedInterests: Set<Interest> { draft?.tasteProfile?.interests ?? [] }

    /// All interest cases in display order — the view zips these with `interestChips` so the toggle
    /// callback knows which `Interest` each chip maps to.
    var interests: [Interest] { Interest.allCases }

    /// The 3-way pace options for the segmented selector, in order (Easy / Balanced / Packed).
    var paceOptions: [Pace] { Pace.allCases }

    /// The currently-selected pace (drives the segmented selector). Defaults to balanced.
    var pace: Pace { draft?.tasteProfile?.pace ?? .balanced }

    // MARK: CTA

    /// The floor CTA title — "Continue · N days", the day count read off the draft (J-11.2/J-11.4 —
    /// specific digits). Same on both bodies (the named mockups all read "Continue · 4 days").
    var ctaTitle: String { "Continue · \(tasteDays) days" }

    // MARK: - Private mapping helpers (model → component value types)

    /// Lock decision: the option opts in (`lockable`), carries a reason, and the destination has no local
    /// saves (`savedHere == 0`). This is B's cover-bucket before any local saves.
    private func isLocked(_ option: TripShapeOption) -> Bool {
        option.lockable && option.lockReason != nil && store.savedHere == 0
    }

    /// The component register for an option: `.locked(reason:)` when locked, else `.selectable`.
    private func register(for option: TripShapeOption, locked: Bool) -> TripShapeRegister {
        if locked, let reason = option.lockReason {
            return .locked(reason: reason)
        }
        return .selectable
    }

    /// Map the model's metric fragments to the component's `MetricToken`s, dropping the model's pure
    /// separator fragments (" · ") — the component draws the middot between tokens itself, so a separator
    /// fragment would double it up. A fragment is a separator when its trimmed text is empty or a middot.
    private func metricTokens(from fragments: [MetricFragment]) -> [MetricToken] {
        fragments
            .filter { !isSeparator($0) }
            .map { MetricToken($0.text, emphasis: $0.emphasis, struck: $0.struck) }
    }

    /// A model fragment that only carries the inter-token separator (" · " / whitespace), which the
    /// component renders itself between tokens.
    private func isSeparator(_ fragment: MetricFragment) -> Bool {
        let trimmed = fragment.text.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || trimmed == "·"
    }

    /// Map the model `DiagramSpec` to the component's `TripShapeDiagram` (same shape, different layer).
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

    /// The a11y / selection id suffix for a card at an index — `a` / `b` / `c` (the named mockups label
    /// the three cards A / B / C).
    private func cardID(for index: Int) -> String {
        switch index {
        case 0: "a"
        case 1: "b"
        default: "c"
        }
    }
}

// MARK: - Defaults

/// Screen-local defaults the presenter falls back to when there is no draft (kept off the magic-number
/// path; mirrors `OnboardingContextDTO.defaultTripDays`).
private enum OnboardingDefaults {
    static let tripDays = 4
}
