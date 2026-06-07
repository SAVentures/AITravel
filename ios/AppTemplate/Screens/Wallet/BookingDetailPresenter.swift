/*
 Stateless derivation for the Wallet booking-detail screen. Resolves the booking by id on the store graph
 (`store.wallet?.booking(id:)`, 06-screens §5) and maps its domain leaves into the value-type fixtures the
 Wave-1 components render — it returns DATA, never Views (06-screens §3). Constructed in `body` from the
 store so per-field dependency tracking is preserved. Ports mockups/screens/wallet/booking-detail.html
 (the fidelity target).

 Resolution is present-vs-absent: if the id no longer resolves, every accessor returns nil/empty/false and
 the view degrades to an empty body rather than crashing (no force-unwrap).

 The hero (type / kind eyebrow / name / status / meta), the `confirmation`, and `hasAccessPass` come off the
 BOOKING itself (always present on a resolved row). The kind title, `infoCells`, `detailRows`, and
 `placedLabel` come off the optional `detail` payload — a booking without a fetched detail (every seeded row
 but the TP 201 flight) renders the hero + (when present) the confirmation row, and the view omits the
 detail-only sections. That is the `booking-castelo` no-pass preview state.
*/
import Foundation

struct BookingDetailPresenter {

    let store: AppStore
    let bookingID: BookingModel.ID

    init(store: AppStore, bookingID: BookingModel.ID) {
        self.store = store
        self.bookingID = bookingID
    }

    // MARK: - Resolution

    /// The live booking reference for this detail, looked up on the store graph (06-screens §5). `nil` when
    /// the id no longer resolves — the view degrades to an empty body, never a force-unwrap.
    private var booking: BookingModel? { store.wallet?.booking(id: bookingID) }

    /// The fetched detail payload, if this booking carries one. Drives the detail-only sections (kind
    /// title, info grid, detail list, placed chip). `nil` for a booking with no fetched detail.
    private var detail: BookingDetailInfo? { booking?.detail }

    /// Whether the booking still exists on the graph; the view guards its content on this.
    var hasBooking: Bool { booking != nil }

    // MARK: - Chrome

    /// The inline nav-bar title (mockup `.screen-topbar .ttl`, e.g. "Flight"). Taken from the detail's
    /// `kind`; falls back to the booking type's display label when no detail is fetched.
    var kindTitle: String { detail?.kind ?? booking?.type.displayLabel ?? "" }

    // MARK: - Hero block (mockup `.bd-hero`)

    /// The booking type — drives the icon-tile tint/mark (`bookingTint`/`bookingMark`) and the hero glyph.
    var type: BookingType { booking?.type ?? .other }

    /// The SF Symbol for the hero icon tile — read off the type (the model owns the glyph; the view never
    /// invents one). `nil` when the booking no longer resolves.
    var systemImage: String? { booking?.type.systemImage }

    /// The mono-caps eyebrow over the name (mockup `.bd-kind`, e.g. "TAP Air Portugal · TP 201"). Composed
    /// from the booking's `subtitleParts`; `nil` when there are none so the view omits the eyebrow.
    var kindEyebrow: String? {
        guard let parts = booking?.subtitleParts, !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    /// The big display name (mockup `.bd-name`, e.g. "Lisbon → New York").
    var name: String { booking?.title ?? "" }

    /// The booking's temporal status — drives the hero `StatusPill` (mockup `.bd-sub .pill`).
    var status: BookingStatus? { booking?.status }

    /// The hero meta line beside the status pill (mockup `.bd-sub .meta`, e.g. "Departs 13:40"). Uses the
    /// booking's `startTime`; `nil` when absent so the view omits it.
    var metaLine: String? {
        guard let line = booking?.startTime, !line.isEmpty else { return nil }
        return line
    }

    // MARK: - Info grid (mockup `.info-grid` — REUSES PlaceInfoGrid per OD-7)

    /// The three-cell info grid (Depart · Arrive · Seat), from the detail payload. Empty when no detail is
    /// fetched — the view then omits the grid (`PlaceFacts` is the shared cell type, OD-7).
    var infoCells: [PlaceFacts] { detail?.infoCells ?? [] }

    // MARK: - Confirmation row (mockup `.conf-row`)

    /// The confirmation code (mockup `.conf-row .v`). Read off the booking itself (present on most rows,
    /// not just those with a fetched detail); `nil` when the booking carries none — the view omits the row.
    var confirmation: String? {
        guard let code = booking?.confirmation, !code.isEmpty else { return nil }
        return code
    }

    // MARK: - Detail list (mockup `.det-list`)

    /// The quiet key/value detail rows, from the detail payload. Empty when no detail is fetched — the view
    /// then omits the list (reuses the `DetailRow` leaf the `DetailList` component renders).
    var detailRows: [DetailRow] { detail?.detailRows ?? [] }

    // MARK: - Placed chip (mockup `.placed`)

    /// The "Placed on Day N · date" confirmation copy (mockup `.placed`), from the detail payload. `nil`
    /// when the booking has no placement label — the view omits the chip.
    var placedLabel: String? {
        guard let label = detail?.placedLabel, !label.isEmpty else { return nil }
        return label
    }

    // MARK: - Action bar

    /// Whether this booking carries a day-of access pass — drives the bottom "Show boarding pass" CTA
    /// (shown only when `true`). The view presents `AccessCardView(pass:)` over the booking's pass.
    var hasAccessPass: Bool { booking?.accessPass != nil }

    /// The booking's access pass, for the CTA's `.fullScreenCover`. `nil` when the booking has none — the
    /// CTA is hidden in that case, so the view never force-unwraps this.
    var accessPass: AccessPass? { booking?.accessPass }

    /// The thumb-zone CTA label (mockup `.cta-bar .cta`).
    var showPassTitle: String { "Show boarding pass" }
}
