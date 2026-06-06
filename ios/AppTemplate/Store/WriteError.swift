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
}
