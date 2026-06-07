import Foundation

/*
 Transient write-failure state for an optimistic store command (write path). A first-class value
 type — set by the command on rollback, cleared on success/retry — so a view can `switch` on it
 and surface a banner (06-screens.md §6) instead of juggling booleans. One case per write op
 (03-store.md §2). Equatable lets tests assert the exact failure.
*/
enum WriteError: Equatable, Sendable {
    /// The optimistic `addPlace` write failed and the inserted row was rolled back.
    case addPlace

    /// The optimistic `placeOrphan` write failed and the booking's `dayIndex` was restored.
    case placeOrphan

    /// User-facing banner copy for this write failure (06-screens §6 — a banner, never a toast/alert,
    /// paired with a glyph, never colour alone — 02-color §6).
    var bannerMessage: String {
        switch self {
        case .addPlace:
            "Couldn't save that place. Check your connection and try again."
        case .placeOrphan:
            "Couldn't add that to your wallet. Check your connection and try again."
        }
    }
}
