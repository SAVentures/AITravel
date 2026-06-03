// BaseLocationStepPresenter.swift — the stateless presenter for onboarding step 03 (base location).
//
// Ports the NAMED mockups `state-a-screen-03-base-location.html` (Alfama),
// `state-b-screen-03-base-location.html` (Gion), and `state-c-screen-03-base-location.html` (Baixa).
//
// A stateless value type over `(store)` (06-screens.md §3): it reads the active `TripDraft` off the store
// and returns only data / view-models — never a `View`, never `AppStore` mutation. All screen-specific
// derivation lives here so the view stays layout + wiring (06-screens.md §2 / §8). Rebuilt cheaply each
// `body` pass.
//
// ── The coordinate → region mapping lives HERE (the task's explicit seam, 02-models §3.2) ──────────────
// `BaseLocation` stores flat `Double` lat/long (no MapKit in the model). `BaseMapCard` takes a value-type
// `BaseMapModel` carrying an `MKCoordinateRegion` + `CLLocationCoordinate2D`s, so this presenter is the
// one place flat lat/long is lifted into MapKit types. `import MapKit` is here, not in the model.
//
// ── `whyVoice` is editorial copy, derived per state ────────────────────────────────────────────────────
// The mockups' `.ai .why` line ("Alfama, basically — eighteen of your twenty-three places…" /
// "Gion, by the east temples…" / "Baixa, dead-central…") and its eyebrow ("What we noticed" /
// "Where the plan clusters" / "Where to base you") vary by `OnboardingState` (A/B/C). There is no model
// field carrying the line — it is the screen's one AI editorial moment (J-3.6 / J-6.2) — so it is derived
// here from the branch + the recommended base, not invented in the view.
import Foundation
import MapKit

/// Derives every value the base-location step renders — the map model, the AI "why" voice, the reach
/// rows, the alternative-neighborhoods rail, and the CTA title — from the active draft on the store.
///
/// Stateless: holds only the store, returns data/view-models, rebuilt each `body` pass (06-screens §3).
struct BaseLocationStepPresenter {

    let store: AppStore

    /// The active onboarding draft. All derivation reads through it; when there is no draft the screen is
    /// not on-stage, so the optional reads collapse to safe defaults.
    private var draft: TripDraft? { store.onboarding }

    // MARK: - Base mode (segmented selection)

    /// The current base-selection mode — `.smart` (the AI rec path) or `.manual` (the stubbed picker).
    /// Drives the `SegmentedSelector` selection and which body the view shows.
    var baseMode: BaseSelectionMode { draft?.baseMode ?? .smart }

    // MARK: - The recommended base + neighborhood

    /// The recommended base for the chosen city (pins + coordinates + zone label). Read from the immutable
    /// catalog seed, not from `baseSelection` — `baseSelection` is `nil` until the user confirms the CTA;
    /// the smart-recommendation card always shows the recommended base the model proposes.
    private var recommendedBase: BaseLocation? { draft?.context.recommendedBase }

    /// The recommended neighborhood — the one flagged `isRecommended` in the catalog. Carries the reach
    /// rows + the blurb the smart card surfaces.
    private var recommendedNeighborhood: Neighborhood? {
        draft?.context.neighborhoods.first { $0.isRecommended }
    }

    /// The recommended neighborhood's display name (the map zone label + the CTA noun).
    private var neighborhoodName: String {
        recommendedBase?.neighborhoodName ?? recommendedNeighborhood?.name ?? ""
    }

    // MARK: - Map model (the coord → region mapping — the task's explicit seam)

    /// The value model `BaseMapCard` renders: the framing region, the home marker, the place pins (each
    /// with their `MapPin` register), and the floating zone label. This is the one place flat `Double`
    /// lat/long is lifted into MapKit types (02-models §3.2) — the component never sees `BaseLocation`.
    var mapModel: BaseMapModel {
        guard let base = recommendedBase else {
            // No active draft / no recommended base — an empty, centered region so the card never crashes
            // off-stage. The screen only composes the card on the `.smart` path with a live draft.
            return BaseMapModel(
                zoneName: "",
                region: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    span: MKCoordinateSpan(latitudeDelta: baseRegionSpan, longitudeDelta: baseRegionSpan)
                ),
                homeCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                places: []
            )
        }

        let center = CLLocationCoordinate2D(latitude: base.latitude, longitude: base.longitude)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: baseRegionSpan, longitudeDelta: baseRegionSpan)
        )
        let home = CLLocationCoordinate2D(latitude: base.homeLatitude, longitude: base.homeLongitude)
        let places = base.pins.map { pin in
            BaseMapPin(
                id: pin.id,
                coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude),
                register: register(for: pin.kind)
            )
        }

        // The map chip reads the bare neighborhood name (mockup `.zlab` — "Alfama"), not the longer
        // `zoneLabel` summary string ("Alfama · 18 / 23 …"); the summary lives in the AI "why" line.
        return BaseMapModel(
            zoneName: neighborhoodName,
            region: region,
            homeCoordinate: home,
            places: places
        )
    }

    /// The recommended `BaseLocation` to commit when the CTA fires — what `select(base:)` is handed.
    var selectedBase: BaseLocation? { recommendedBase }

    /// Map the domain `PinKind` to the component's `MapPin.PinRegister`. The in-neighborhood pins read as
    /// `.definitive` (no rank index — these are reach pins, not a ranked itinerary), the out-of-zone ones
    /// as `.fuzzy` (mockup `.pin` vs `.pin.out`).
    private func register(for kind: PinKind) -> MapPin.PinRegister {
        switch kind {
        case .definitive: .definitive(nil)
        case .fuzzy: .fuzzy
        }
    }

    // MARK: - The AI "why" voice (one editorial moment per state — J-3.6 / J-6.2)

    /// The mono-caps eyebrow for the AI "why" line, by branch (mockup `.ai .why .lab`).
    var whyEyebrow: String {
        switch draft?.onboardingState {
        case .returningWithLocalSaves: "What we noticed"
        case .savesElsewhere: "Where the plan clusters"
        case .firstTrip: "Where to base you"
        case nil: "What we noticed"
        }
    }

    /// The italic display "why" line — the screen's one editorial moment (mockup `.ai .why .line`),
    /// derived per branch. Specific, one sentence with a point (J-11.1).
    var whyVoice: String {
        switch draft?.onboardingState {
        case .returningWithLocalSaves:
            "Alfama, basically — eighteen of your twenty-three places are a 25-minute walk from here."
        case .savesElsewhere:
            "Gion, by the east temples — most of what's worth your mornings sits within a 20-minute walk."
        case .firstTrip:
            "Baixa, dead-central — close to most of what fits a food-and-history first trip, and an easy hop to everywhere else."
        case nil:
            ""
        }
    }

    // MARK: - Reach rows (rendered via `TimeHint`)

    /// One reach row, as a `TimeHint.Model` paired with a stable id so the view's `ForEach` is identified
    /// without forcing `Identifiable` onto the component's value fixture. Mirrors the mockup `.reach .r`:
    /// a leading glyph, a label, and a mono measurement carried by `TimeHint`.
    struct ReachRowModel: Identifiable {
        let id: String
        let hint: TimeHint.Model
    }

    /// The recommended neighborhood's reach rows, mapped to `TimeHint.Model` (the `[glyph] [label] [mono
    /// measurement]` the mockup `.reach .r` renders). The measurement carries the mono numeral
    /// (≤ 25 min / 12 min / 25 min).
    var reachRows: [ReachRowModel] {
        (recommendedNeighborhood?.reachRows ?? []).map { row in
            ReachRowModel(
                id: row.id,
                hint: TimeHint.Model(
                    text: row.label,
                    systemImage: row.systemImage,
                    measurement: row.measurement
                )
            )
        }
    }

    // MARK: - Alternative neighborhoods (the HScrollSection rail)

    /// One card in the "Other neighborhoods we weighed" rail (mockup `.alts .alt`): a display name + a mono
    /// meta line ("14 places · 30 min walk" / "central · flat"). A tiny view-model so the view stays free
    /// of domain shaping.
    struct AltModel: Identifiable {
        let id: String
        /// The neighborhood display name (mockup `.alt .nm`).
        let name: String
        /// The mono meta line under the name (mockup `.alt .m`). May lead with a bold place count or be a
        /// bare descriptor (state C carries descriptors, no counts).
        let meta: String
    }

    /// The non-recommended neighborhoods, as rail cards (mockup `.alts`). The recommended one is the map
    /// card above, so it is excluded here.
    var altNeighborhoods: [AltModel] {
        (draft?.context.neighborhoods ?? [])
            .filter { !$0.isRecommended }
            .map { neighborhood in
                AltModel(
                    id: neighborhood.id,
                    name: neighborhood.name,
                    meta: altMeta(for: neighborhood)
                )
            }
    }

    /// The mono meta line for an alt card. When the neighborhood has a place count it leads with it
    /// ("14 places · 30 min walk"); when it has none (state C descriptors) it shows the blurb alone
    /// ("central · flat").
    private func altMeta(for neighborhood: Neighborhood) -> String {
        if neighborhood.placeCount > 0 {
            "\(neighborhood.placeCount) places · \(neighborhood.blurb)"
        } else {
            neighborhood.blurb
        }
    }

    // MARK: - CTA

    /// The primary CTA title (mockup `.ob-cta` — "Use Alfama as base"). Reads the recommended
    /// neighborhood, so the verb-led label always names the base the screen proposes (J-11.3).
    var ctaTitle: String { "Use \(neighborhoodName) as base" }

    // MARK: - Constants

    /// The framing span (degrees) for the map region — a neighborhood-scale window (≈ the mockup's
    /// `.map` zoom). Kept here so the coord → region mapping is fully owned by the presenter.
    private let baseRegionSpan: CLLocationDegrees = 0.018
}
