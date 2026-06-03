import Foundation

/// The transient load state for an async hydration (the read path, `03-store.md §2`).
///
/// A first-class value type so a view can `switch` on load/error instead of juggling ad-hoc
/// booleans. `failed` carries a message for surfacing; equality lets tests assert the exact state.
enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
