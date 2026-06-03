// BaseMapCard.swift — the recommended-base mini-map. Ports screen-03 `.rec .map`: a MapKit map with a soft
// zone, MapPin markers (.definitive in / .fuzzy out), a home marker, and a floating mono zone-label chip.
// Content, never glass (J-0.1) — map + chip are solid surfaces.
// snapshotMode (J-12.4): MapKit tiles are non-deterministic and would flake an L3 snapshot, so the same
// footprint renders zone+pins+home+label over a neutral placeholder (no tiles); the live Map is L4-only.
import SwiftUI
import MapKit

// MARK: - The value model

// The register reuses MapPin's signature idea rather than re-encoding in/out as a boolean.
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

// A screen maps its domain `BaseLocation` to this; the component never sees AppStore or a domain object.
struct BaseMapModel: Sendable {
    let zoneName: String
    let region: MKCoordinateRegion
    let homeCoordinate: CLLocationCoordinate2D
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

struct BaseMapCard: View {
    let model: BaseMapModel
    var snapshotMode: Bool = false

    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = Sizing.Component.baseMapHeight

    var body: some View {
        ZStack {
            mapLayer
            overlay
        }
        .frame(height: mapHeight)
        .clipShape(ConcentricRectangle()) // inherits the rec card's corner from the parent `.containerShape`
        // The map is decorative context — collapse it to ONE labeled element so its internal pin / place /
        // zone-label text (and the live MapKit labels) aren't surfaced as loose, unlabeled a11y text.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of \(model.zoneName) and nearby places")
        .accessibilityIdentifier("onboarding.basemap")
    }

    // MARK: Map layer

    @ViewBuilder private var mapLayer: some View {
        if snapshotMode {
            ColorRole.fillTertiary
        } else {
            Map(initialPosition: .region(model.region), interactionModes: []) {
                MapCircle(center: model.region.center, radius: zoneRadiusMeters)
                    .foregroundStyle(ColorRole.fillQuaternary)
                    .stroke(ColorRole.separator, lineWidth: zoneStroke)

                ForEach(model.places) { place in
                    Annotation("", coordinate: place.coordinate) {
                        MapPin(place.register)
                    }
                }

                Annotation("", coordinate: model.homeCoordinate) {
                    homeMarker
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        }
    }

    // MARK: Overlay

    // Live path: only the floating label sits on top (pins/zone/home are inside the Map). snapshotMode:
    // everything is composed in screen space over the placeholder, since the geo annotations can't render.
    @ViewBuilder private var overlay: some View {
        if snapshotMode {
            placeholderContent
        } else {
            VStack {
                zoneLabel
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
        }
    }

    private var placeholderContent: some View {
        ZStack {
            Capsule()
                .fill(ColorRole.fillQuaternary)
                .strokeBorder(ColorRole.separator, lineWidth: zoneStroke)
                .frame(width: zonePlaceholderWidth, height: zonePlaceholderHeight)

            // A representative scatter — exact geo positions are L4's concern, not the lock's (J-12.4).
            HStack(spacing: Spacing.md) {
                ForEach(model.places.prefix(placeholderPinCount)) { place in
                    MapPin(place.register)
                }
            }

            homeMarker

            VStack {
                zoneLabel
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
        }
    }

    // MARK: Home marker

    // The .now register's vocabulary but with a home glyph rather than a dot. Ring is static — no pulse (J-9.3).
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

    // MARK: Zone label

    private var zoneLabel: some View {
        Text(model.zoneName)
            .font(Typography.caption)
            .tracking(Typography.trackCapsCaption)
            .textCase(.uppercase)
            .foregroundStyle(ColorRole.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            // Solid surface chip, NOT glass (J-0.1).
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.pill))
            .shadowRest()
            .accessibilityIdentifier("onboarding.basemap.zonelabel")
    }

    // MARK: Derived metrics

    private var zoneRadiusMeters: CLLocationDistance {
        let metersPerDegreeLat = 111_000.0
        return model.region.span.latitudeDelta * metersPerDegreeLat * zoneSpanFraction
    }

    // Non-text metrics scale with Dynamic Type (T-6.4) — never a bare fixed CGFloat (J-0.3).
    @ScaledMetric(relativeTo: .body) private var homeSize: CGFloat = Sizing.Component.baseMapHome
    @ScaledMetric(relativeTo: .body) private var homeRingWidth: CGFloat = Sizing.Component.baseMapHomeRing
    @ScaledMetric(relativeTo: .body) private var zoneStroke: CGFloat = Stroke.separator
    @ScaledMetric(relativeTo: .body) private var zonePlaceholderWidth: CGFloat = Sizing.Component.baseMapZoneWidth
    @ScaledMetric(relativeTo: .body) private var zonePlaceholderHeight: CGFloat = Sizing.Component.baseMapZoneHeight

    private let homeRingOpacity: Double = 0.10
    private let zoneSpanFraction: Double = 0.33
    private let placeholderPinCount = 5
}

// MARK: - Previews

private extension BaseMapModel {
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

// The L3 lock uses THIS variant only — deterministic, no live tiles.
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
