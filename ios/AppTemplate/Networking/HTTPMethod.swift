import Foundation

/*
 The HTTP verb an APIRequest is sent with. Raw values are the uppercased wire spellings, so
 LiveProvider can assign URLRequest.httpMethod directly from method.rawValue. A request type's
 verb prefix (Get…, Post…, …) and its method must agree.
*/
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
