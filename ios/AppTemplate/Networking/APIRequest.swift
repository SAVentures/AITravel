import Foundation

/*
 The endpoint contract. One `struct` per endpoint carries both its wire description and its mock
 behavior, so adding an endpoint is one new file and providers stay ignorant of per-endpoint code.
 `Response` is `Decodable & Sendable` (decoded off-main by `LiveProvider`, crossed back as a value);
 domain models never appear here — responses representing them use their `*DTO`.

 Each requirement is `nonisolated` individually, NOT `nonisolated protocol APIRequest`. The whole-protocol
 cascade (SE-0449) is the cleaner spec-ideal, but on this Xcode 26 toolchain it spuriously infers unrelated
 call sites (APIClient.mock) as nonisolated and breaks the build (forums.swift.org/t/80430). Revisit when fixed.
*/
protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    nonisolated var path: String { get }
    nonisolated var method: HTTPMethod { get }
    nonisolated var queryItems: [String: String] { get }
    nonisolated var body: (any Encodable & Sendable)? { get }
    nonisolated var mockLatency: Duration { get }

    nonisolated func mockResponse(from seed: MockSeed) throws -> Response
}

extension APIRequest {
    nonisolated var queryItems: [String: String] { [:] }
    nonisolated var body: (any Encodable & Sendable)? { nil }
    nonisolated var mockLatency: Duration { .zero }
}
