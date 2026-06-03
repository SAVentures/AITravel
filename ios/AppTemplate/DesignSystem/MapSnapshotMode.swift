import SwiftUI

/*
 Render-snapshot seam for MapKit. Screens read `\.mapSnapshotMode` and pass it to `BaseMapCard` so an
 L3 snapshot draws the deterministic placeholder (no network tiles) instead of the live `Map`. Default
 false → the running app shows the live map; the snapshot environment injects true (07-testing §6.4).
*/
extension EnvironmentValues {
    @Entry var mapSnapshotMode: Bool = false
}
