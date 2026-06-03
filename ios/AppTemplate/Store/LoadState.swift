import Foundation

/*
 Transient load state for an async hydration (read path). A first-class value type so views
 `switch` on load/error instead of juggling booleans; `failed` carries a surfacing message and
 Equatable lets tests assert the exact state.
*/
enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
