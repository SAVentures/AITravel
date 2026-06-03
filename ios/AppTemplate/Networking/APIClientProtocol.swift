import Foundation

/*
 The whole API surface: one generic `send`. Refines `Sendable` so `APIClient`'s wrapped
 existential is compiler-verifiably safe to cross actors.

 Per-requirement `nonisolated` (not `nonisolated protocol`) — see APIRequest.swift's note.
*/
protocol APIClientProtocol: Sendable {
    nonisolated func send<R: APIRequest>(_ request: R) async throws -> R.Response
}
