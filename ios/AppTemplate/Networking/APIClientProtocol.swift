import Foundation

/// The whole API surface: one generic `send`. `MockProvider` and `LiveProvider` are the
/// two `Sendable` conformers; `APIClient` is the thin wrapper the store/screens hold
/// (`04-networking.md §2`). The protocol refines `Sendable` so `APIClient`'s wrapped
/// existential is compiler-verifiably safe to cross actors.
protocol APIClientProtocol: Sendable {
    nonisolated func send<R: APIRequest>(_ request: R) async throws -> R.Response
}
