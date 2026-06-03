// BaseMapCardSnapshotTests.swift — Layer 3 render-snapshot lock for BaseMapCard.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// States covered (§6.2 — one snapshot per key state):
//   snapshot-mode — deterministic placeholder render (snapshotMode: true); MapKit live tiles
//                   are non-deterministic and network-dependent, so this is the ONLY L3 path.
//                   The live Map variant is L4 XCUITest-only (documented in BaseMapCard.swift
//                   "The L3 lock uses THIS variant only"). The alfama fixture mirrors the
//                   private preview fixture defined in BaseMapCard.swift.
//
// IMPORTANT: snapshotMode: true is REQUIRED here. Without it the component calls MapKit for
// live tiles, which are non-deterministic and would produce a flaky or blank baseline. The
// placeholder path (snapshotMode: true) renders zone capsule + pins + home marker + zone label
// in screen space over a fillTertiary ground — fully deterministic (J-12.4 / OPEN DECISION 4).
//
// Ground: surfacePage + cardSurface inset (matching the preview context in BaseMapCard.swift).
//
// Determinism (§6.4):
//   - No Date() — BaseMapCard carries no time state.
//   - No withAnimation — rendered at rest.
//   - snapshotMode: true — no live tiles, no network.
//   - disablesOneShotMotion injected via designSystemEnvironment().
//   - Fixture is a local replica of BaseMapModel.alfama (private to BaseMapCard.swift).
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
import MapKit
@testable import AppTemplate

@Suite("BaseMapCard snapshots")
@MainActor
struct BaseMapCardSnapshotTests {

    // MARK: - Fixture
    //
    // Mirrors the private `BaseMapModel.alfama` preview fixture in BaseMapCard.swift exactly —
    // same coordinates, same pin register values, same zone name. Kept here as a local value
    // rather than reaching into the private extension so the test file is self-contained.

    private let alfama = BaseMapModel(
        zoneName: "Alfama",
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7139, longitude: -9.1283),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ),
        homeCoordinate: CLLocationCoordinate2D(latitude: 38.7139, longitude: -9.1283),
        places: [
            BaseMapPin(id: "p1",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7146, longitude: -9.1297),
                       register: .definitive(1)),
            BaseMapPin(id: "p2",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7131, longitude: -9.1271),
                       register: .definitive(2)),
            BaseMapPin(id: "p3",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7152, longitude: -9.1268),
                       register: .definitive(3)),
            BaseMapPin(id: "p4",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7125, longitude: -9.1290),
                       register: .definitive(nil)),
            BaseMapPin(id: "o1",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7180, longitude: -9.1340),
                       register: .fuzzy),
            BaseMapPin(id: "o2",
                       coordinate: CLLocationCoordinate2D(latitude: 38.7100, longitude: -9.1230),
                       register: .fuzzy),
        ]
    )

    // MARK: - Snapshot

    @Test("snapshot-mode — deterministic placeholder: zone capsule, pins, home marker, zone label")
    func snapshotMode() {
        // snapshotMode: true is mandatory for L3 — deterministic, no live tiles, no network.
        assertDesignSnapshot(
            BaseMapCard(model: alfama, snapshotMode: true)
                .cardSurface()
                .padding(Spacing.screenInset)
                .background(ColorRole.surfacePage),
            named: "snapshot-mode"
        )
    }
}
