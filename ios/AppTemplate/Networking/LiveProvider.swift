import Foundation

/*
 Production URLSession provider — a generic shell that dispatches on the request and holds no
 per-endpoint code. `send` is @concurrent: build → network → decode runs off the main actor,
 the Sendable DTO crosses back, and the store maps toDomain() on the main actor.

 Every failure is mapped into APIError before it propagates — call sites never see a raw
 URLError/DecodingError. No real backend ships with the template, so baseURL is a placeholder.
*/
nonisolated struct LiveProvider: APIClientProtocol, Sendable {
    var baseURL: URL = URL(string: "https://api.example.com")!
    var session: URLSession = .shared

    @concurrent
    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        let urlRequest = try makeURLRequest(for: request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.offline
        } catch {
            throw APIError.transport(error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.status(http.statusCode)
        }

        do {
            return try APIJSON.decoder().decode(R.Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func makeURLRequest<R: APIRequest>(for request: R) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        )
        if !request.queryItems.isEmpty {
            components?.queryItems = request.queryItems
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            throw APIError.transport(URLError(.badURL))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        if let body = request.body {
            urlRequest.httpBody = try APIJSON.encoder().encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}
