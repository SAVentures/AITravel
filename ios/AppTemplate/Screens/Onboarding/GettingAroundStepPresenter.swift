// GettingAroundStepPresenter.swift — the stateless derivation for onboarding Step 04 (plan W4-04).
//
// Per `06-screens.md §3`: a stateless `<Screen>Presenter` value type over the store, constructed in
// `body`, returning data / view-models (never `View`s). It owns this step's screen-specific derivation
// — the AI rec voice (the eyebrow + the ONE italic editorial line), the city/days context, the reason
// rows, the conditional context note, the two-tier mode control (the 4-way "Mostly" segmented options
// + the multi-select "Also OK" chips), and the verb-led CTA title. The *store-shared* derivation
// (`onboardingState`, saved counts) lives on the store (`AppStore+Onboarding`); this presenter only
// reads the draft's transport rec + the live selection.
//
// Named mockups (the fidelity targets):
//   `mockups/screens/onboarding/screen-04-getting-around.html`        (shared A / C — Lisbon €)
//   `mockups/screens/onboarding/state-b-screen-04-getting-around.html` (B — Kyoto ¥)
//
// Imports SwiftUI because it returns `TimeHint.Model` / `FilterChipModel` (view-side value types); no
// `View` is built here. Kept cheap — it is rebuilt every `body` pass.
import SwiftUI

/// Stateless derivation for `GettingAroundStepView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved (`06-screens.md §3`). All derived data reads the live
/// `TripDraftModel` (the chosen transport + the seed `TransportRec` catalog); no `View` is built.
struct GettingAroundStepPresenter {

    /// The single source of truth this step reads. Held, never mutated here.
    let store: AppStore

    // MARK: - Convenience accessors (the live draft + its seed transport rec)

    /// The active onboarding draft. `nil` only when there is no flow in progress (the view renders
    /// nothing in that case, but the presenter stays total).
    private var draft: TripDraftModel? { store.onboarding }

    /// The AI transport recommendation served in the seed catalog (the € / ¥ reasons, the context note,
    /// the suggested mode). The single source for this step's recommendation copy.
    private var rec: TransportRec? { draft?.context.transportRec }

    // MARK: - Hero copy (the shared `.hero` block — identical across A / B / C)

    /// The mono-caps eyebrow above the hero question.
    var heroEyebrow: String { "Getting around" }

    /// The display hero question.
    var heroQuestion: String { "How will you get around?" }

    /// The sub copy under the hero question.
    var heroSub: String { "Pick one mode we optimize around, plus a few we can mix in." }

    // MARK: - The AI rec voice (the ONE italic editorial moment — J-3.6 / J-6.2 / OPEN-DECISION-7)

    /// The rec card's mono-caps eyebrow — a PLAIN mono label (mockup `.ai .lab`), deliberately WITHOUT
    /// an accent dot: the screen's accent budget (J-2.4, ≤ 2) is spent on the CTA + the one suggested
    /// `stateNow` dot below, so this eyebrow stays neutral (OPEN-DECISION-7).
    var recEyebrow: String { "Reading your trip" }

    /// The roman lead-in of the editorial rec line (mockup `.rec .top .v` — "We'd suggest ").
    var recLineLead: String { "We'd suggest " }

    /// The italic-emphasized tail of the rec line — the suggested mode word + period (mockup `.v em` —
    /// "transit."). This is the screen's ONE editorial italic moment (J-3.6); the view renders it in the
    /// display face italic and nothing else on the screen is italic.
    var recLineEmphasis: String {
        let mode = rec?.suggestedMode ?? .transit
        return "\(mode.label.lowercased())."
    }

    /// The mono city/days context shown trailing the rec line (mockup `.rec .top .ctx` — "Lisbon / 4
    /// days", "Kyoto · Gion / 4 days"). Carries the seed's two-line `cityContext` verbatim.
    var cityContext: String { rec?.cityContext ?? "" }

    // MARK: - Reason rows (the `.rec .reasons` strip — `TimeHint` rows with € / ¥ measurements)

    /// The supporting reason rows, mapped to `TimeHint.Model`s — a leading glyph, the reason body, and
    /// the mono € / ¥ / time measurement that carries the fact (T-1.2). One per `ReasonRow` in the seed.
    var reasonRows: [TimeHint.Model] {
        (rec?.reasons ?? []).map { reason in
            TimeHint.Model(
                text: reason.text,
                systemImage: reason.systemImage,
                measurement: reason.measurement
            )
        }
    }

    // MARK: - The conditional context note (the `.note` row — quiet, NO alarm color — J-11.5)

    /// The conditional context note (the rain / blossom-crowd caveat). Quiet by design — the view
    /// renders it through `ContextNote`, which carries NO alarm color (J-11.5). `nil` when there is no
    /// rec (the view omits the row).
    var contextNote: (eyebrow: String, text: String)? {
        guard let note = rec?.contextNote else { return nil }
        return (eyebrow: note.eyebrow, text: note.text)
    }

    // MARK: - Tier 1 · "Mostly" (the 4-way single-select segmented control → `setPrimaryMode`)

    /// The four primary-mode options the "Mostly" segmented selector shows, left to right (mockup
    /// `.mostly` — Walk · Transit · Drive · Cycle). A fixed, ordered list; the segment label + glyph come
    /// from each `TransportMode`.
    var mostlyOptions: [TransportMode] { [.walk, .transit, .drive, .cycle] }

    /// The currently-selected primary mode — drives the ink pill + the `.isSelected` trait. Defaults to
    /// the suggested mode when there is no draft.
    var primaryMode: TransportMode {
        draft?.transport.primary ?? suggestedMode
    }

    /// The mode the AI suggested — drives the "Transit is what we suggested" hint + its one `stateNow`
    /// dot (the one accent mark in the body, J-2.4).
    var suggestedMode: TransportMode {
        draft?.transport.suggested ?? rec?.suggestedMode ?? .transit
    }

    /// The mono hint under the "Mostly" selector (mockup `.suggest` — "Transit is what we suggested").
    /// Names the suggested mode so the one `stateNow` dot is paired with a label, never color alone
    /// (02-color §6).
    var suggestedHint: String {
        "\(suggestedMode.label) is what we suggested"
    }

    // MARK: - Tier 2 · "Also OK" (the multi-select chip row → `toggleAlsoOK`)

    /// The modes the "Also OK" chip row offers, left to right (mockup `.alsook` — Walk · Rideshare ·
    /// Cycle · Bus · Drive). A fixed, ordered list; the screen toggles each into the alsoOK set.
    var alsoOKModes: [TransportMode] { [.walk, .rideshare, .cycle, .bus, .drive] }

    /// The currently-selected also-OK set — drives each chip's solid-ink + check register.
    var selectedAlsoOK: Set<TransportMode> {
        draft?.transport.alsoOK ?? []
    }

    /// The "Also OK" chips as `FilterChipModel`s (multi-select — any number may be on). Each chip's
    /// `isSelected` reflects membership in the alsoOK set; the view wires the toggle to `toggleAlsoOK`.
    var alsoOKChips: [FilterChipModel] {
        alsoOKModes.map { mode in
            FilterChipModel(label: mode.label, isSelected: selectedAlsoOK.contains(mode))
        }
    }

    // MARK: - CTA

    /// The verb-led floor CTA title (mockup `.ob-cta` — "Continue · Mostly transit"). Names the chosen
    /// primary mode so the action reads concretely (J-11.3).
    var ctaTitle: String {
        "Continue · Mostly \(primaryMode.label.lowercased())"
    }
}
