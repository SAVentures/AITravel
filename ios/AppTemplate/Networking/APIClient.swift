import Foundation

/*
 The single concrete handle the store and screens hold — a thin class over one immutable provider.
 The provider is a `let` and `APIClientProtocol` refines `Sendable`, so the compiler verifies a
 plain `Sendable` conformance (no `@unchecked`). Provider swaps happen only here, via the factories;
 nothing outside this folder references `MockProvider`/`LiveProvider`.
*/
final class APIClient: APIClientProtocol, Sendable {
    private let provider: any APIClientProtocol

    init(provider: any APIClientProtocol) {
        self.provider = provider
    }

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        try await provider.send(request)
    }
}

extension APIClient {
    static var live: APIClient {
        APIClient(provider: LiveProvider())
    }

    /*
     A client over the stateless `MockProvider`, seeded for `scenario`. `failure` throws on every
     `send` (drives write-error/offline paths); `latency` delays each response (drives loading states).
    */
    static func mock(
        scenario: MockScenario = .empty,
        failure: APIError? = nil,
        latency: Duration = .zero
    ) -> APIClient {
        let provider = MockProvider(
            seed: SampleData.seed(for: scenario),
            failure: failure,
            latency: latency
        )
        return APIClient(provider: provider)
    }
}

/*
 Namespace vending the pinned JSON coders: camelCase properties, snake_case on the wire. Symmetric
 round-trip tests must use plain coders, not these — the snake-case strategy is asymmetric on
 acronym/ID keys.
*/
nonisolated enum APIJSON {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
