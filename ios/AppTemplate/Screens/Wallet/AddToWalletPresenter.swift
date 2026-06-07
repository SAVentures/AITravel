// AddToWalletPresenter.swift — stateless derivation for the two-phase "Add to wallet" sheet (06-screens
// §3). Ports mockups/screens/wallet/add-method.html (phase A) + add-review.html (phase B).
//
// Derives, from the store + ephemeral sheet state: the three "way to save" method rows (phase A), the
// forward-to-email clipboard string, and the AI-review field rows (phase B), plus the loading / write-error
// display read off the store. Returns DATA (value types / strings), never `View`s (06 §3.1) — the sheet
// assembles them. Stateless, rebuilt each `body` pass (06 §3.3). Mirrors `AddPlacePresenter`: a value type
// over `(store, …)`, cheap, pure in → out (06 §3.4).
import Foundation

struct AddToWalletPresenter {

    /// The single source of truth — read for the write-error / loading display (the method rows + the
    /// review fields are static copy this milestone; the store carries the live write state).
    let store: AppStore

    /// Whether the add write is in flight — the sheet's ephemeral `@State` (`isAdding`), set around `await
    /// store.placeOrphan(...)`. Surfaces the `PlaceOrphanRequest` latency as a progress affordance (04 §7).
    let isAdding: Bool

    // MARK: - Phase A — method copy (mockup `.sheet-title` / `.sheet-sub`, add-method.html)

    /// The method-phase title (mockup `.sheet-title`).
    var methodTitle: String { "Add to wallet" }

    /// The method-phase sub copy (mockup `.sheet-sub`) — present-tense, calm, the AI voice (J-11.2/J-11.5).
    var methodSubtitle: String {
        "Hand it over any way you have it — I'll read out the details and file it under the right day."
    }

    // MARK: - Method rows (mockup `.method` / `.method.primary`, add-method.html)

    /// The three capture methods, in mockup order: the prominent "Forward a confirmation" (the path that
    /// advances to the review phase + the one demonstrated write), then "Scan a pass or ticket", then "From
    /// a photo". The screen maps each to a sink — the prominent row advances the phase; the others hit a
    /// `pendingMethod` stub (deeper capture flows are separate stories — OD-8 / 06 §4.1).
    var methods: [WayToSaveRowModel] {
        [
            WayToSaveRowModel(
                id: "forward",
                title: "Forward a confirmation",
                subtitle: "Paste text, a link, or an email",
                systemImage: "envelope",
                prominent: true
            ),
            WayToSaveRowModel(
                id: "scan",
                title: "Scan a pass or ticket",
                subtitle: "QR code or barcode",
                systemImage: "qrcode.viewfinder"
            ),
            WayToSaveRowModel(
                id: "photo",
                title: "From a photo",
                subtitle: "Snap or upload a screenshot",
                systemImage: "camera"
            ),
        ]
    }

    // MARK: - Forward-to-email row (mockup `.fwd-addr`, add-method.html)

    /// The fixed key label above the forwarding address.
    var forwardKey: String { "Or forward email to" }

    /// The forwarding address — a mono "measurement" string (T-1.2), the copy-button payload.
    var forwardEmail: String { "wallet@aitravel.app" }

    // MARK: - Phase B — review copy (mockup `.sheet-title` / `.rev-ai`, add-review.html)

    /// The review-phase title (mockup `.sheet-title`).
    var reviewTitle: String { "Check the details" }

    /// The `AIVoice` eyebrow on the review card (mockup `.rev-ai .mk` dot is the eyebrow mark).
    var reviewEyebrow: String { "AI" }

    /// The `AIVoice` line — what the assistant did (mockup `.rev-ai` copy).
    var reviewVoiceLine: String { "Read from your screenshot" }

    // MARK: - Review fields (mockup `.rev-card .rev-field`, add-review.html)

    /// A single review-card field: a key label + a value, with optional kinds the view renders specially
    /// (the Type chip's booking icon; a low-confidence italic "verify" value; a mono confirmation).
    struct ReviewField: Identifiable {
        /// Stable identity — also the a11y-id suffix the view composes into `addwallet.field.<key>`.
        let key: String
        /// The field's key label (mockup `.rev-field .k`).
        let label: String
        /// The field's value text (mockup `.rev-field .v`).
        let value: String
        /// For the "Type" field: the booking type whose icon-chip the view renders before the value.
        var bookingType: BookingType?
        /// True for a low-confidence field (the "When") — rendered italic + a "verify" tag (mockup `.v.low`).
        var lowConfidence: Bool = false
        /// True for a confirmation code — rendered in the mono face (mockup `.v.mono`, T-1.2).
        var isMono: Bool = false

        var id: String { key }
    }

    /// The AI-extracted review fields, in mockup order (Type / Name / When / Where / Confirmation). Static
    /// copy this milestone — the extraction is the deeper "read a brand-new booking" flow (OD-4); these
    /// mirror the seeded orphan ("Fado at Tasca do Chico", booking-fado-orphan) the demonstrated write places.
    var reviewFields: [ReviewField] {
        [
            ReviewField(key: "type", label: "Type", value: BookingType.activity.displayLabel, bookingType: .activity),
            ReviewField(key: "name", label: "Name", value: "Fado at Tasca do Chico"),
            ReviewField(key: "when", label: "When", value: "Probably Aug 27, 21:00", lowConfidence: true),
            ReviewField(key: "where", label: "Where", value: "Rua do Diário de Notícias 39, Bairro Alto"),
            ReviewField(key: "confirmation", label: "Confirmation", value: "TDC-8841", isMono: true),
        ]
    }

    /// The low-confidence "verify" tag copy (mockup `.verify`).
    var verifyTag: String { "verify" }

    /// The review-phase primary CTA label (mockup `.sheet-cta`).
    var confirmTitle: String { "Add to wallet" }

    /// The review-phase ghost label (mockup `.sheet-ghost`).
    var editTitle: String { "Edit details" }

    // MARK: - Write state (read off the store — banner, never toast/alert, 06 §6)

    /// True while the add write is in flight — drives the CTA's progress affordance + disables re-taps.
    var isLoading: Bool { isAdding }

    /// The write-error banner copy, present only when the optimistic `placeOrphan` rolled back
    /// (`store.writeError == .placeOrphan`). `nil` ⇒ no banner. The view pairs it with a glyph (never colour
    /// alone — 02-color §6) and stamps `writeError.banner`.
    var writeErrorMessage: String? { store.writeError?.bannerMessage }
}
