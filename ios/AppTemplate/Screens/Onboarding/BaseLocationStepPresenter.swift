/*
 Stateless presenter for onboarding step 03 (base location). Ports state-{a,b,c}-screen-03-base-location.html
 (Alfama / Gion / Baixa). Reads the active TripDraftModel off the store and returns only data/view-models so
 the view stays layout + wiring.

 Two seams owned here:
 - The coordinate → region mapping: BaseLocation stores flat Double lat/long (no MapKit in the model), so this
   is the one place it's lifted into MKCoordinateRegion / CLLocationCoordinate2D. import MapKit lives here.
 - whyVoice/whyEyebrow are editorial copy with no model field — the screen's one AI editorial moment, derived
   per OnboardingState (A/B/C), not invented in the view.
*/
import Foundation
import MapKit

struct BaseLocationStepPresenter {

    let store: AppStore

    private var draft: TripDraftModel? { store.onboarding }

    // MARK: - Base mode (segmented selection)

    var baseMode: BaseSelectionMode { draft?.baseMode ?? .smart }

    // MARK: - The recommended base + neighborhood

    /* Read from the immutable catalog seed, not baseSelection — baseSelection is nil until the user
       confirms the CTA, but the smart card always shows the recommended base. */
    private var recommendedBase: BaseLocation? { draft?.context.recommendedBase }

    private var recommendedNeighborhood: Neighborhood? {
        draft?.context.neighborhoods.first { $0.isRecommended }
    }

    private var neighborhoodName: String {
        recommendedBase?.neighborhoodName ?? recommendedNeighborhood?.name ?? ""
    }

    // MARK: - Map model

    var mapModel: BaseMapModel {
        guard let base = recommendedBase else {
            // No active draft / recommended base — empty centered region so the card never crashes off-stage.
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

        // Map chip reads the bare neighborhood name, not the longer zoneLabel summary (that lives in whyVoice).
        return BaseMapModel(
            zoneName: neighborhoodName,
            region: region,
            homeCoordinate: home,
            places: places
        )
    }

    var selectedBase: BaseLocation? { recommendedBase }

    // In-neighborhood pins read as .definitive with no rank index (reach pins, not a ranked itinerary).
    private func register(for kind: PinKind) -> MapPin.PinRegister {
        switch kind {
        case .definitive: .definitive(nil)
        case .fuzzy: .fuzzy
        }
    }

    // MARK: - The AI "why" voice

    var whyEyebrow: String {
        switch draft?.onboardingState {
        case .returningWithLocalSaves: "What we noticed"
        case .savesElsewhere: "Where the plan clusters"
        case .firstTrip: "Where to base you"
        case nil: "What we noticed"
        }
    }

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

    // MARK: - Reach rows

    // A stable id paired with the hint so ForEach identifies without forcing Identifiable onto the fixture.
    struct ReachRowModel: Identifiable {
        let id: String
        let hint: TimeHint.Model
    }

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

    // MARK: - Alternative neighborhoods

    struct AltModel: Identifiable {
        let id: String
        let name: String
        let meta: String
    }

    // The recommended neighborhood is the map card above, so it is excluded here.
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

    // With a place count, lead with it ("14 places · 30 min walk"); without (state C), the blurb alone.
    private func altMeta(for neighborhood: Neighborhood) -> String {
        if neighborhood.placeCount > 0 {
            "\(neighborhood.placeCount) places · \(neighborhood.blurb)"
        } else {
            neighborhood.blurb
        }
    }

    // MARK: - Manual picker (baseMode == .manual)

    // Every neighborhood (recommended + weighed) as a selectable row — manual mode lets the user override
    // the smart pick with any one of them.
    var manualOptions: [AltModel] {
        (draft?.context.neighborhoods ?? []).map { neighborhood in
            AltModel(
                id: neighborhood.id,
                name: neighborhood.name,
                meta: altMeta(for: neighborhood)
            )
        }
    }

    var selectedNeighborhoodID: String? { draft?.selectedNeighborhoodID }

    private var manualSelectedName: String? {
        guard let id = selectedNeighborhoodID else { return nil }
        return draft?.context.neighborhoods.first { $0.id == id }?.name
    }

    // A specific hotel/address pinned via the map sheet (mutually exclusive with a neighborhood pick).
    var pinnedBaseName: String? { draft?.baseSelection?.neighborhoodName }

    // The region the address-picker sheet opens on — the destination framing from the recommended base.
    var pickerRegion: MKCoordinateRegion { mapModel.region }

    // MARK: - CTA

    var ctaTitle: String {
        // A pinned specific address overrides whichever segment is showing.
        if let name = pinnedBaseName { return "Use \(name) as base" }
        switch baseMode {
        case .smart:
            return "Use \(neighborhoodName) as base"
        case .manual:
            if let name = manualSelectedName { return "Use \(name) as base" }
            return "Pick a neighborhood"
        }
    }

    // A pinned address always continues; otherwise smart has the recommendation, manual needs a pick.
    var canContinue: Bool {
        if pinnedBaseName != nil { return true }
        switch baseMode {
        case .smart:  return true
        case .manual: return selectedNeighborhoodID != nil
        }
    }

    // MARK: - Constants

    // The map region span (degrees) — a neighborhood-scale framing window.
    private let baseRegionSpan: CLLocationDegrees = 0.018
}
