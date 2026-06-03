// BaseMapCard.swift — the recommended-base mini-map (05-components; J-0.1, J-12.4; plan W1-06 / OD-4).
//
// Ports the screen-03 `.rec .map` (state-a/-screen-03-base-location): a real MapKit map capped at the
// card's corner, carrying a recommended neighborhood **zone** (a soft, dashed-edge region), `MapPin`
// place markers (`.definitive` in-neighborhood, `.fuzzy` out), a **home** marker (the recommended base,
// the `.now`-register ink home glyph with a soft ring), and a floating mono **zone label** chip.
//
// ── Content, never glass (J-0.1) ──────────────────────────────────────────────────────────────────────
// The map is CONTENT — the card it sits in is white (`cardSurface`) at the screen level, with NO colored
// edge (mockup `.rec`). Nothing here is glass; the only frosted layer in onboarding is the floating
// progress header / floor at the composition tier. The zone label chip is a SOLID `surfaceGrouped` pill
// with the rest shadow (mockup `.zlab`), not a glass chip.
//
// ── Concentric corner ─────────────────────────────────────────────────────────────────────────────────
// The map fills the top of the rec card and inherits the card's corner via `.containerShape` +
// `ConcentricRectangle()` — never a hand-picked inner radius (03-layout-spacing §5, J-7.4). The card sets
// its own `cardSurface()`/`Radius.card` corner at the screen; here the map is clipped to a concentric
// rounded rect so it reads as part of one card, not a nested box.
//
// ── snapshotMode (OPEN DECISION 4 / J-12.4) ───────────────────────────────────────────────────────────
// MapKit tiles are network-dependent and non-deterministic, so a render snapshot of the live `Map` would
// flake. When `snapshotMode == true` the SAME footprint renders the zone + pins + home + label over a
// neutral `fillTertiary` placeholder (NO live tiles, NO network) — a stable, footprint-identical stand-in
// for the L3 lock, never a broken-image / blank-tile box (J-12.4, 08-slop A-7). The live `Map` is
// exercised only by the L4 XCUITest (home marker present by a11y id), never pixel-diffed.
//
// Value-type args only — a `BaseMapModel` carrying flat data + the `MapPin.PinRegister` register per
// place; no `AppStore`, no domain object (05 §8). Semantic tokens only; zero literals / `Primitive.*`
// (J-0.2). `@ScaledMetric` for the non-text marker/label metrics (J-0.3 — no fixed content frames).
import SwiftUI
import MapKit

// MARK: - The value model (data in as a value type — no AppStore, no domain object; 05 §8)

/// One place marker on the base map: where it sits + which `MapPin` register it reads as (`.definitive`
/// in-neighborhood, `.fuzzy` out). The register is the product's one signature idea, reused from `MapPin`
/// (plan Wave-1 "reuse, don't rebuild") rather than re-encoded as a boolean.
struct BaseMapPin: Identifiable, Sendable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let register: MapPin.PinRegister

    init(id: String, coordinate: CLLocationCoordinate2D, register: MapPin.PinRegister) {
        self.id = id
        self.coordinate = coordinate
        self.register = register
    }
}

/// The base-map card's data, as a tiny value type for the component + its previews/snapshots. A screen
/// maps its domain `BaseLocation` to this (the view turns flat lat/long into `CLLocationCoordinate2D`,
/// 02-models §3.2); the component never sees `AppStore` or a domain object (01-arch §3, 05 §8).
struct BaseMapModel: Sendable {
    /// The recommended neighborhood name — the floating mono zone-label chip (mockup `.zlab`, "Alfama").
    let zoneName: String
    /// The map's framing region — center + span. The recommended zone overlay is drawn around the center.
    let region: MKCoordinateRegion
    /// The recommended base ("home") marker coordinate — the ink home glyph (mockup `.home`).
    let homeCoordinate: CLLocationCoordinate2D
    /// The place markers — `.definitive` for in-neighborhood places, `.fuzzy` for out (mockup `.pin` /
    /// `.pin.out`).
    let places: [BaseMapPin]

    init(
        zoneName: String,
        region: MKCoordinateRegion,
        homeCoordinate: CLLocationCoordinate2D,
        places: [BaseMapPin]
    ) {
        self.zoneName = zoneName
        self.region = region
        self.homeCoordinate = homeCoordinate
        self.places = places
    }
}

// MARK: - BaseMapCard

/// The recommended-base mini-map: a real MapKit `Map` (or, in `snapshotMode`, a deterministic placeholder)
/// carrying the zone, place pins, the home marker, and the mono zone-label chip. Content — never glass
/// (J-0.1). The enclosing `.rec` card (`cardSurface`) is applied by the screen; this fills its top.
struct BaseMapCard: View {
    let model: BaseMapModel
    /// When true, render the overlays over a neutral `fillTertiary` placeholder instead of live tiles, so
    /// the L3 render snapshot is deterministic (OPEN DECISION 4 / J-12.4). The live `Map` is L4-only.
    var snapshotMode: Bool = false

    /// The map panel height — a non-text metric, so it scales with Dynamic Type via `@ScaledMetric`
    /// rather than a fixed CGFloat (T-6.4, J-0.3). Seeded from the mockup's 184pt `.map` panel.
    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = 184

    var body: some View {
        ZStack {
            mapLayer
            overlay
        }
        .frame(height: mapHeight)
        .clipShape(ConcentricRectangle()) // inherits the rec card's corner from the parent `.containerShape`
        .accessibilityIdentifier("onboarding.basemap")
    }

    // MARK: Map layer — live tiles, or the deterministic neutral placeholder (snapshotMode)

    @ViewBuilder private var mapLayer: some View {
        if snapshotMode {
            // A neutral solid ground in place of live tiles — footprint-identical, deterministic, never a
            // blank-tile / broken-image box (J-12.4, 08-slop A-7).
            ColorRole.fillTertiary
        } else {
            Map(initialPosition: .region(model.region), interactionModes: []) {
                // The recommended zone — a soft neutral region with a faint stroke (mockup `.zone`:
                // `fill-quaternary` ground, a dashed `ink-300` edge). MapKit owns the geo-anchored shape;
                // the screen reads `region.span` for the radius so the zone tracks the framing.
                MapCircle(center: model.region.center, radius: zoneRadiusMeters)
                    .foregroundStyle(ColorRole.fillQuaternary)
                    .stroke(ColorRole.separator, lineWidth: zoneStroke)

                // Place markers — the product's definitive/fuzzy register, reused from `MapPin`.
                ForEach(model.places) { place in
                    Annotation("", coordinate: place.coordinate) {
                        MapPin(place.register)
                    }
                }

                // The recommended-base home marker (mockup `.home` — ink ground, home glyph, soft ring).
                Annotation("", coordinate: model.homeCoordinate) {
                    homeMarker
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        }
    }

    // MARK: Overlay — in snapshotMode the geo content can't render, so draw it over the placeholder

    /// In `snapshotMode` the live `Map` (and its geo-anchored annotations) is absent, so the zone, pins,
    /// home, and label are composed in screen space over the neutral ground — the same footprint and the
    /// same visual vocabulary, deterministic. In the live path only the floating mono label sits on top
    /// (the pins/zone/home are inside the `Map`).
    @ViewBuilder private var overlay: some View {
        if snapshotMode {
            placeholderContent
        } else {
            VStack {
                zoneLabel
                Spacer(minLength: 0)
            }
            .padding(Spacing.itemGap)
        }
    }

    /// The deterministic placeholder composition: the soft zone, the in/out pins, the home marker, and the
    /// mono label — laid out in screen space (no geo) so the snapshot is stable and footprint-identical.
    private var placeholderContent: some View {
        ZStack {
            // The recommended zone — a soft neutral capsule with a faint edge (mockup `.zone`).
            Capsule()
                .fill(ColorRole.fillQuaternary)
                .strokeBorder(ColorRole.separator, lineWidth: zoneStroke)
                .frame(width: zonePlaceholderWidth, height: zonePlaceholderHeight)

            // A representative scatter of the registers so the placeholder reads as the same map (the
            // exact geo positions are L4's concern, not the lock's — J-12.4).
            HStack(spacing: Spacing.itemGap) {
                ForEach(model.places.prefix(placeholderPinCount)) { place in
                    MapPin(place.register)
                }
            }

            homeMarker

            VStack {
                zoneLabel
                Spacer(minLength: 0)
            }
            .padding(Spacing.itemGap)
        }
    }

    // MARK: Home marker — the recommended base (mockup `.home`): ink ground, home glyph, soft ring

    /// The recommended-base marker. The `.now` register's vocabulary (the user's "here") but carrying a
    /// home glyph rather than a dot, per the mockup `.home`: a solid ink disc, a paper home glyph, and a
    /// soft low-opacity ring. Content, never glass (J-0.1); the ring is static — no continuous pulse (J-9.3).
    private var homeMarker: some View {
        Image(systemName: "house.fill")
            .font(Typography.caption)
            .foregroundStyle(ColorRole.textOnAccent)
            .frame(width: homeSize, height: homeSize)
            .background(ColorRole.textPrimary, in: .circle)
            .background {
                Circle()
                    .fill(ColorRole.textPrimary.opacity(homeRingOpacity))
                    .frame(width: homeSize + homeRingWidth * 2, height: homeSize + homeRingWidth * 2)
            }
            .accessibilityIdentifier("onboarding.basemap.home")
            .accessibilityLabel("Recommended base: \(model.zoneName)")
    }

    // MARK: Zone label — the floating mono chip (mockup `.zlab`): solid surface pill + rest shadow

    private var zoneLabel: some View {
        Text(model.zoneName)
            .font(Typography.caption) // mono caption — the mockup's mono caps chip
            .tracking(Typography.trackCapsCaption)
            .textCase(.uppercase)
            .foregroundStyle(ColorRole.textSecondary)
            .padding(.horizontal, Spacing.paired)
            .padding(.vertical, Spacing.hairline)
            // Solid surface chip (mockup `.zlab` = `paper-0` + `shadow-rest`), NOT glass (J-0.1).
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.pill))
            .shadowRest()
            .accessibilityIdentifier("onboarding.basemap.zonelabel")
    }

    // MARK: Derived metrics

    /// The recommended-zone radius, in meters, derived from the framing span so the overlay tracks the
    /// region (a fraction of the latitudinal span — the mockup zone covers ~the central third).
    private var zoneRadiusMeters: CLLocationDistance {
        let metersPerDegreeLat = 111_000.0
        return model.region.span.latitudeDelta * metersPerDegreeLat * zoneSpanFraction
    }

    // Non-text metrics scale with Dynamic Type (T-6.4) — never a bare fixed CGFloat (J-0.3).

    /// The home disc diameter (mockup `.home` 30px).
    @ScaledMetric(relativeTo: .body) private var homeSize: CGFloat = 30
    /// The home ring width (mockup `.home` 5px halo).
    @ScaledMetric(relativeTo: .body) private var homeRingWidth: CGFloat = 5
    /// The zone-overlay stroke width (mockup `.zone` 1px dashed edge).
    @ScaledMetric(relativeTo: .body) private var zoneStroke: CGFloat = 1
    /// The placeholder zone capsule footprint (mockup `.zone` 168×124).
    @ScaledMetric(relativeTo: .body) private var zonePlaceholderWidth: CGFloat = 168
    @ScaledMetric(relativeTo: .body) private var zonePlaceholderHeight: CGFloat = 124

    /// The home ring opacity (mockup `.home` 10% halo).
    private let homeRingOpacity: Double = 0.10
    /// The zone radius as a fraction of the framing latitudinal span (mockup zone ≈ central third).
    private let zoneSpanFraction: Double = 0.33
    /// How many of the place registers to scatter in the deterministic placeholder.
    private let placeholderPinCount = 5
}

// MARK: - Previews — the deterministic snapshot variant + a live one (05 §8, §10)

private extension BaseMapModel {
    /// A local value-type fixture (Lisbon · Alfama) — no SampleData / domain model in Phase 0 (05 §8).
    static let alfama = BaseMapModel(
        zoneName: "Alfama",
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7139, longitude: -9.1283),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ),
        homeCoordinate: CLLocationCoordinate2D(latitude: 38.7139, longitude: -9.1283),
        places: [
            BaseMapPin(id: "p1", coordinate: .init(latitude: 38.7146, longitude: -9.1297), register: .definitive(1)),
            BaseMapPin(id: "p2", coordinate: .init(latitude: 38.7131, longitude: -9.1271), register: .definitive(2)),
            BaseMapPin(id: "p3", coordinate: .init(latitude: 38.7152, longitude: -9.1268), register: .definitive(3)),
            BaseMapPin(id: "p4", coordinate: .init(latitude: 38.7125, longitude: -9.1290), register: .definitive(nil)),
            BaseMapPin(id: "o1", coordinate: .init(latitude: 38.7180, longitude: -9.1340), register: .fuzzy),
            BaseMapPin(id: "o2", coordinate: .init(latitude: 38.7100, longitude: -9.1230), register: .fuzzy)
        ]
    )
}

// The L3 lock uses THIS variant only — deterministic, no live tiles (OPEN DECISION 4 / J-12.4).
#Preview("BaseMapCard — snapshotMode (deterministic)") {
    BaseMapCard(model: .alfama, snapshotMode: true)
        .cardSurface()
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

// Exercised by the L4 XCUITest (home marker present), never pixel-diffed.
#Preview("BaseMapCard — live Map") {
    BaseMapCard(model: .alfama)
        .cardSurface()
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
