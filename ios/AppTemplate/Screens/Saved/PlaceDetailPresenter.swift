/*
 Stateless derivation for the Saved place-detail screen. Resolves the place by id on the store graph and
 maps its domain leaves into the value-type fixtures the Wave-0.A components render — it returns DATA, never
 Views (06-screens §3). Constructed in `body` from the store so per-field dependency tracking is preserved.
 Ports mockups/screens/saved/place-detail.html (the fidelity target).

 The A/B/C-style state here is simply present-vs-absent: if the id no longer resolves (e.g. an optimistic
 row rolled back), every accessor returns nil/empty and the view shows nothing rather than crashing.
*/
import Foundation

struct PlaceDetailPresenter {

    let store: AppStore
    let placeID: SavedPlaceModel.ID

    init(store: AppStore, placeID: SavedPlaceModel.ID) {
        self.store = store
        self.placeID = placeID
    }

    // MARK: - Resolution

    /// The live reference for this detail, looked up on the store graph (06-screens §5). `nil` when the
    /// id no longer resolves — the view degrades to an empty body, never a force-unwrap.
    private var place: SavedPlaceModel? { store.savedPlaces?.place(id: placeID) }

    /// Whether the place still exists on the graph; the view guards its content on this.
    var hasPlace: Bool { place != nil }

    // MARK: - Title block (mockup `.pd-titleblock`)

    /// The inline nav-bar title. The display name doubles as the scaffold's `.detail(title:)`.
    var title: String { place?.name ?? "" }

    /// The category for the kicker chip (mockup `.pd-kicker .pl-cat`).
    var category: PlaceCategory? { place?.category }

    /// The "neighborhood · city" kicker line (mockup `.pd-kicker .where`).
    var locationLine: String { place?.locationLine ?? "" }

    /// The big display name (mockup `.pd-name`).
    var displayName: String { place?.name ?? "" }

    // MARK: - Provenance card (mockup `.prov`)

    /// The "Saved from" card fixture, derived from the place's `provenance` leaf. `nil` when the place was
    /// saved without provenance (e.g. a bare search result) — the view omits the card.
    var provenance: ProvenanceCard.Model? {
        guard let provenance = place?.provenance else { return nil }
        return ProvenanceCard.Model(
            sourceHandle: handle(provenance.sourceHandle),
            meta: provenanceMeta(provenance),
            quote: provenance.quote
        )
    }

    /// The meta line under the handle — e.g. "Reel · "Lisbon in 48 hours" · 0:42" (mockup `.prov-who .mt`).
    /// Joins the source kind, the optional clip title (quoted), and the optional timestamp.
    private func provenanceMeta(_ provenance: PlaceProvenance) -> String? {
        var parts: [String] = [sourceKindLabel]
        if let clipTitle = provenance.clipTitle, !clipTitle.isEmpty {
            parts.append("“\(clipTitle)”")
        }
        if let timestamp = provenance.timestamp, !timestamp.isEmpty {
            parts.append(timestamp)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The leading word of the meta line, keyed off the place's source kind (Reel / Screenshot / Saved).
    private var sourceKindLabel: String {
        switch place?.source.kind {
        case .reel:       return "Reel"
        case .screenshot: return "Screenshot"
        case .search:     return "Saved"
        case .none:       return "Saved"
        }
    }

    /// Normalises a stored handle to the displayed `@handle` form (the seed stores it without the `@`).
    private func handle(_ raw: String) -> String {
        raw.hasPrefix("@") ? raw : "@\(raw)"
    }

    // MARK: - Info grid (mockup `.info-grid`)

    /// The facts grid cells (Hours · Price · Cuisine). Empty when the place carries no facts — the view
    /// then omits the grid.
    var facts: [PlaceFacts] { place?.facts ?? [] }

    // MARK: - Map snippet (mockup `.map-snip`)

    /// The address line the map snippet shows; `nil` when the place has no address (the view omits the
    /// snippet rather than render an empty well — J-12.4).
    var address: String? {
        guard let line = place?.addressLine, !line.isEmpty else { return nil }
        return line
    }

    // MARK: - Action bar

    /// The thumb-zone CTA label (mockup `.cta-bar .cta`). D-5: the Trip feature does not exist this
    /// milestone, so the view wires this to an info banner, not a Trip screen.
    var addToTripTitle: String { "Add to a trip" }
}
