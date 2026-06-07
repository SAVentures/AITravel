/*
 Route value for the Saved-tab place detail. Carries only the id the destination needs to look the
 place up on the store graph (`store.savedPlaces?.place(id:)`) — never the model itself (06-screens §5).
 One Route per file, `Hashable`, registered with `.navigationDestination(for:)` at the Saved tab root
 (RootView, Wave 0.2 / 3.1); pushed via `store.push(PlaceDetailRoute(id:))` onto the active tab's path.
*/
import Foundation

struct PlaceDetailRoute: Hashable {
    let id: SavedPlaceModel.ID
}
