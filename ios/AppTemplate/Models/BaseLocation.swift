/*
 Onboarding step-03 base-location model — leaf value types held on TripDraftModel.

 Coordinates are flat `Double` lat/long, never `CLLocationCoordinate2D` (don't force it through a
 coder); the view does the mapping. No MapKit / CoreLocation / SwiftUI import here.
*/
import Foundation

// MARK: - PinKind

// Domain mirror of `MapPin.PinRegister`; the view maps `PinKind → MapPin.PinRegister`.
nonisolated enum PinKind: String, Codable, Equatable, Hashable, Sendable {
    case definitive  // in-neighborhood, certain
    case fuzzy       // out-of-neighborhood, approximate
}

// MARK: - BasePin

nonisolated struct BasePin: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let latitude: Double   // WGS-84 decimal degrees
    let longitude: Double  // WGS-84 decimal degrees
    let kind: PinKind

    init(id: String, latitude: Double, longitude: Double, kind: PinKind) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.kind = kind
    }
}

// MARK: - BaseLocation

nonisolated struct BaseLocation: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let neighborhoodName: String
    let latitude: Double       // neighborhood centroid / map region center (WGS-84)
    let longitude: Double
    let homeLatitude: Double    // recommended home / hotel anchor point (WGS-84)
    let homeLongitude: Double
    let pins: [BasePin]
    let zoneLabel: String  // floating map-chip text, e.g. "Alfama · 18 / 23 within 25 min walk"

    init(
        id: String,
        neighborhoodName: String,
        latitude: Double,
        longitude: Double,
        homeLatitude: Double,
        homeLongitude: Double,
        pins: [BasePin],
        zoneLabel: String
    ) {
        self.id = id
        self.neighborhoodName = neighborhoodName
        self.latitude = latitude
        self.longitude = longitude
        self.homeLatitude = homeLatitude
        self.homeLongitude = homeLongitude
        self.pins = pins
        self.zoneLabel = zoneLabel
    }
}

// MARK: - BaseSelectionMode

nonisolated enum BaseSelectionMode: String, Codable, Equatable, Hashable, Sendable {
    case smart
    case manual  // stubbed this milestone — renders EmptyStateView; state is captured + testable
}
