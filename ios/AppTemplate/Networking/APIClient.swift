import Foundation

/// The single concrete handle the store and screens hold — a thin `final class` wrapping one
/// immutable provider. Because the wrapped existential is a `let` and `APIClientProtocol`
/// refines `Sendable`, the compiler **verifies** the `Sendable` conformance: plain `Sendable`,
/// no `@unchecked` (`01-architecture.md §9`, `04-networking.md §1`). Nothing outside this folder
/// references `MockProvider`/`LiveProvider`; swapping providers happens only here, via the factories.
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
    /// The default production client, backed by `LiveProvider` (`URLSession` HTTP).
    static var live: APIClient {
        APIClient(provider: LiveProvider())
    }

    /// A client backed by the stateless `MockProvider`, built from the seed for `scenario`.
    /// - Parameters:
    ///   - scenario: which `SampleData` seed variant to snapshot into the `MockSeed`.
    ///   - failure: an `APIError` to throw on every `send` — drives the write-error/offline paths.
    ///   - latency: a delay applied before each response — drives loading states.
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

/// Caseless namespace vending the pinned JSON coders. All `Request` bodies and `Response`/DTO
/// types use camelCase property names; the coder handles the snake_case wire translation
/// (`04-networking.md §5`). Symmetric round-trip tests use plain coders, never these, because
/// the snake-case strategy is asymmetric on acronym/ID keys.
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
