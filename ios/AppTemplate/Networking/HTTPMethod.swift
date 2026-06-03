import Foundation

/// The HTTP verb an ``APIRequest`` is sent with.
///
/// Raw values are the uppercased wire spellings, so `LiveProvider` can set
/// `URLRequest.httpMethod` directly from `method.rawValue`. The verb prefix of a
/// request type (`Get…`, `Post…`, …) and its `method` must agree (`04-networking.md §4`).
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
