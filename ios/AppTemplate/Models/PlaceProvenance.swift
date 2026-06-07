import Foundation

// MARK: - PlaceProvenance

/*
 The "Saved from" provenance record for a saved place. Carries the social/clip handle that
 triggered the save, an optional display title, an ISO-8601 timestamp string, and an optional
 pull-quote shown on the ProvenanceCard. Leaf value type — wire-safe, no DTO.
*/
nonisolated struct PlaceProvenance: Codable, Equatable, Hashable, Sendable {
    var sourceHandle: String
    var clipTitle: String?
    var timestamp: String?
    var quote: String?
}
