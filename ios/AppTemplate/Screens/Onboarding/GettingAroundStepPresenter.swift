/*
 Stateless derivation for onboarding Step 04 (Getting Around) — a presenter value over the store,
 built in `body`, returning data / view-models (never Views). Owns this step's screen-specific
 derivation; store-shared derivation lives on `AppStore+Onboarding`.

 Ports screen-04-getting-around.html (shared A / C — Lisbon €) and its state-b variant (Kyoto ¥).
 Imports SwiftUI only for the returned view-side value types (TimeHint.Model / FilterChipModel).
*/
import SwiftUI

struct GettingAroundStepPresenter {

    let store: AppStore

    // MARK: - Convenience accessors

    /// `nil` only when no flow is in progress — keeps the presenter total.
    private var draft: TripDraftModel? { store.onboarding }

    private var rec: TransportRec? { draft?.context.transportRec }

    // MARK: - Hero copy

    var heroEyebrow: String { "Getting around" }

    var heroQuestion: String { "How will you get around?" }

    var heroSub: String { "Pick one mode we optimize around, plus a few we can mix in." }

    // MARK: - The AI rec voice

    /* PLAIN mono label, deliberately WITHOUT an accent dot: the accent budget (J-2.4, ≤ 2) is spent
       on the CTA + the one suggested `stateNow` dot below, so this eyebrow stays neutral. */
    var recEyebrow: String { "Reading your trip" }

    var recLineLead: String { "We'd suggest " }

    /* The screen's ONE editorial italic moment (J-3.6) — rendered in the display face italic, and
       nothing else on the screen is italic. */
    var recLineEmphasis: String {
        let mode = rec?.suggestedMode ?? .transit
        return "\(mode.label.lowercased())."
    }

    var cityContext: String { rec?.cityContext ?? "" }

    // MARK: - Reason rows

    var reasonRows: [TimeHint.Model] {
        (rec?.reasons ?? []).map { reason in
            TimeHint.Model(
                text: reason.text,
                systemImage: reason.systemImage,
                measurement: reason.measurement
            )
        }
    }

    // MARK: - The conditional context note

    /* The rain / blossom-crowd caveat. Quiet by design — rendered through `ContextNote`, which carries
       NO alarm color (J-11.5). */
    var contextNote: (eyebrow: String, text: String)? {
        guard let note = rec?.contextNote else { return nil }
        return (eyebrow: note.eyebrow, text: note.text)
    }

    // MARK: - Tier 1 · "Mostly"

    var mostlyOptions: [TransportMode] { [.walk, .transit, .drive, .cycle] }

    var primaryMode: TransportMode {
        draft?.transport.primary ?? suggestedMode
    }

    /// Drives the suggested-hint + its one `stateNow` dot (the one accent mark in the body, J-2.4).
    var suggestedMode: TransportMode {
        draft?.transport.suggested ?? rec?.suggestedMode ?? .transit
    }

    /// Names the suggested mode so the dot is paired with a label, never color alone (02-color §6).
    var suggestedHint: String {
        "\(suggestedMode.label) is what we suggested"
    }

    // MARK: - Tier 2 · "Also OK"

    var alsoOKModes: [TransportMode] { [.walk, .rideshare, .cycle, .bus, .drive] }

    var selectedAlsoOK: Set<TransportMode> {
        draft?.transport.alsoOK ?? []
    }

    var alsoOKChips: [FilterChipModel] {
        alsoOKModes.map { mode in
            FilterChipModel(label: mode.label, isSelected: selectedAlsoOK.contains(mode))
        }
    }

    // MARK: - CTA

    var ctaTitle: String {
        "Continue · Mostly \(primaryMode.label.lowercased())"
    }
}
