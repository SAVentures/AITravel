import Foundation

/// The closed error type thrown by ``APIClientProtocol/send(_:)``.
///
/// Call sites never see raw `URLError`/`DecodingError` — `LiveProvider` maps every
/// failure into one of these cases before it propagates, and `MockProvider` surfaces
/// `.status(404)` for a missing entity so the mock stays honest about the contract
/// (`04-networking.md §6`). The store catches this in its write path and surfaces it as
/// a `writeError` banner.
enum APIError: Error, LocalizedError, Sendable {
    /// Transport-level failure: DNS, connection refused, TLS — anything below HTTP.
    case transport(Error)
    /// A 2xx response whose payload failed to decode into `R.Response`.
    case decoding(Error)
    /// A non-2xx HTTP status.
    case status(Int)
    /// No network path to the host (`URLError.notConnectedToInternet`).
    case offline

    var errorDescription: String? {
        switch self {
        case .transport:
            return "Couldn't reach the server. Check your connection and try again."
        case .decoding:
            return "The server sent something we couldn't read."
        case let .status(code):
            return "The server responded with an error (status \(code))."
        case .offline:
            return "You're offline. Reconnect to continue."
        }
    }
}
