import Foundation

/// The in-process fake backend: a **stateless** value type holding an immutable seed plus
/// two behavior knobs (`04-networking.md §7`). It persists no mutations — writes are applied
/// optimistically on the client against a single-session `AppStore` that never re-fetches to
/// observe its own write — so a value seed is `Sendable` with nothing to synchronize.
///
/// `send` honors latency, injects the configured failure if any, then computes the response
/// purely from the seed via `request.mockResponse(from:)`.
struct MockProvider: APIClientProtocol, Sendable {
    let seed: MockSeed
    let failure: APIError?
    let latency: Duration

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        if latency > .zero {
            try await Task.sleep(for: latency)
        }
        if let failure {
            throw failure
        }
        return try request.mockResponse(from: seed)
    }
}
