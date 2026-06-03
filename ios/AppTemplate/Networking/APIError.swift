import Foundation

/*
 The closed error type thrown by APIClientProtocol. Call sites never see raw
 URLError/DecodingError — LiveProvider maps every failure into one of these cases, and
 MockProvider surfaces .status(404) for a missing entity to stay honest about the contract.
 The store catches this in its write path and surfaces it as a writeError banner.
*/
enum APIError: Error, LocalizedError, Sendable {
    case transport(Error)
    case decoding(Error)
    case status(Int)
    case offline  // URLError.notConnectedToInternet

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
