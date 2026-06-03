import Foundation

/// The endpoint contract. Each endpoint is one `struct` conforming to `APIRequest` that
/// carries both its wire description (`path`/`method`/`queryItems`/`body`) and its mock
/// behavior (`mockLatency`/`mockResponse(from:)`) — so adding an endpoint is *one new
/// file* and the providers stay ignorant of per-endpoint code (`04-networking.md §2`).
///
/// The `Response` is `Decodable & Sendable` because it is decoded off the main actor by
/// `LiveProvider` and crosses back as a value; the reference domain models never appear
/// here — responses representing them use their `*DTO` (`04-networking.md §3`).
protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    /// The path component of the URL, e.g. `/library` or `/books/{id}/borrow`.
    nonisolated var path: String { get }
    /// The HTTP verb. No default — the request's verb prefix and `method` must agree.
    nonisolated var method: HTTPMethod { get }
    /// Query items appended to the URL. Defaults to empty.
    nonisolated var queryItems: [String: String] { get }
    /// The request body, if any. A `Sendable` value type encoded with `APIJSON`. Defaults to `nil`.
    nonisolated var body: (any Encodable & Sendable)? { get }
    /// Delay the `MockProvider` applies before responding, so loading states are exercisable. Defaults to `.zero`.
    nonisolated var mockLatency: Duration { get }

    /// Pure synchronous computation of the response from the immutable mock seed.
    nonisolated func mockResponse(from seed: MockSeed) throws -> Response
}

extension APIRequest {
    nonisolated var queryItems: [String: String] { [:] }
    nonisolated var body: (any Encodable & Sendable)? { nil }
    nonisolated var mockLatency: Duration { .zero }
}
