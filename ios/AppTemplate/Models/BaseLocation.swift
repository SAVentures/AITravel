// BaseLocation.swift — the recommended-base value type for the onboarding step-03 base-location model.
//
// All coordinate storage is flat `Double` lat/long fields (02-models §3.2 — never force
// `CLLocationCoordinate2D` through a coder; the view maps these to `CLLocationCoordinate2D`).
// No MapKit / CoreLocation import here; no SwiftUI import.
//
// `PinKind` and `BaseSelectionMode` are mutually-exclusive-state enums with no associated values
// → raw `String` enums, synthesized `Codable` for free (02-models §3.1).
//
// All three types are leaf value types (02-models §1.2): they are not mutable rows in a list; they
// are held as values on the `TripDraft` reference model and are already wire-safe, so no DTO is needed.
import Foundation

// MARK: - PinKind

/// Whether a `BasePin` represents a definitive (in-neighborhood) or fuzzy (out-of-neighborhood)
/// place marker on the base map. Mirrors `MapPin.PinRegister` for the domain model;
/// the view maps `PinKind → MapPin.PinRegister` when building a `BaseMapModel`.
nonisolated enum PinKind: String, Codable, Equatable, Hashable, Sendable {
    /// An in-neighborhood place — solid, certain.
    case definitive
    /// An out-of-neighborhood place — approximate, recessive.
    case fuzzy
}

// MARK: - BasePin

/// One map pin attached to a `BaseLocation`: a lat/long coordinate + which kind of place it is.
/// Collection-stored in `BaseLocation.pins`, so `Identifiable` with a stable literal id.
nonisolated struct BasePin: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    /// Latitude of this pin's position (WGS-84 decimal degrees).
    let latitude: Double
    /// Longitude of this pin's position (WGS-84 decimal degrees).
    let longitude: Double
    /// Whether this place is definitively inside the recommended neighborhood or fuzzy / peripheral.
    let kind: PinKind

    init(id: String, latitude: Double, longitude: Double, kind: PinKind) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.kind = kind
    }
}

// MARK: - BaseLocation

/// The recommended base neighborhood for a trip: lat/long of the neighborhood centroid, the hotel /
/// anchor home point, all place pins (each with their `PinKind`), and a display zone label.
///
/// Coordinates are stored as flat `Double` lat/long fields; the view that drives `BaseMapCard`
/// maps them to `CLLocationCoordinate2D` (02-models §3.2). No import of MapKit or CoreLocation here.
///
/// This is a leaf value type (02-models §1.2): it is held as `TripDraft.baseSelection: BaseLocation?`
/// and is not itself a mutable row in a list, so it is a `struct`, not a reference model.
nonisolated struct BaseLocation: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    /// Display name of the recommended neighborhood (e.g. "Alfama", "Gion", "Baixa").
    let neighborhoodName: String
    /// Latitude of the neighborhood centroid — the map region center (WGS-84 decimal degrees).
    let latitude: Double
    /// Longitude of the neighborhood centroid — the map region center (WGS-84 decimal degrees).
    let longitude: Double
    /// Latitude of the recommended home / hotel anchor point (WGS-84 decimal degrees).
    let homeLatitude: Double
    /// Longitude of the recommended home / hotel anchor point (WGS-84 decimal degrees).
    let homeLongitude: Double
    /// All place pins to render on the base map; each carries a `PinKind` register.
    let pins: [BasePin]
    /// The floating zone-label text shown on the map chip (e.g. "Alfama · 18 / 23 within 25 min walk").
    let zoneLabel: String

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

/// How the user chooses their base in onboarding step 03: AI-recommended from saved places,
/// or a manual pick. Mutually exclusive → raw `String` enum (02-models §3.1).
///
/// The `.manual` path is stubbed for this milestone (renders `EmptyStateView`) — state is
/// captured and testable, but the manual picker is not yet built.
nonisolated enum BaseSelectionMode: String, Codable, Equatable, Hashable, Sendable {
    /// Smart recommendation derived from the user's saved places in the neighborhood.
    case smart
    /// User-driven selection (stubbed — manual base picker coming soon).
    case manual
}
