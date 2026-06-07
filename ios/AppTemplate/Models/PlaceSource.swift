import Foundation

// MARK: - SourceKind

// Flat discriminator for UI that needs to branch on source type without pattern-matching the full enum.
nonisolated enum SourceKind: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case reel
    case screenshot
    case search
}

// MARK: - PlaceSource

// Associated-value enum with manual tag-keyed Codable (02-models.md §3.2).
// Each case describes how a place was discovered and saved.
nonisolated enum PlaceSource: Equatable, Hashable, Sendable {
    /// Saved from a social-media reel. `handle` is required; `clipTitle` is optional metadata.
    case reel(handle: String, clipTitle: String?)
    /// Saved from a screenshot. `savedNote` is an optional user-supplied annotation.
    case screenshot(savedNote: String?)
    /// Saved via in-app search.
    case search

    // MARK: Derived helpers (pure, SwiftUI-free — data only)

    var kind: SourceKind {
        switch self {
        case .reel:       return .reel
        case .screenshot: return .screenshot
        case .search:     return .search
        }
    }

    var displayLabel: String {
        switch self {
        case .reel(let handle, _):       return "Reel · @\(handle)"
        case .screenshot(let note):      return note ?? "Screenshot"
        case .search:                    return "Search"
        }
    }

    var systemImage: String {
        switch self {
        case .reel:       return "play.rectangle"
        case .screenshot: return "photo"
        case .search:     return "magnifyingglass"
        }
    }
}

// MARK: - PlaceSource: Codable

extension PlaceSource: Codable {

    private enum CodingKeys: String, CodingKey {
        case tag
        case handle
        case clipTitle
        case savedNote
    }

    private enum Tag: String, Codable {
        case reel
        case screenshot
        case search
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .reel(let handle, let clipTitle):
            try container.encode(Tag.reel, forKey: .tag)
            try container.encode(handle, forKey: .handle)
            try container.encodeIfPresent(clipTitle, forKey: .clipTitle)
        case .screenshot(let savedNote):
            try container.encode(Tag.screenshot, forKey: .tag)
            try container.encodeIfPresent(savedNote, forKey: .savedNote)
        case .search:
            try container.encode(Tag.search, forKey: .tag)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(Tag.self, forKey: .tag)
        switch tag {
        case .reel:
            let handle = try container.decode(String.self, forKey: .handle)
            let clipTitle = try container.decodeIfPresent(String.self, forKey: .clipTitle)
            self = .reel(handle: handle, clipTitle: clipTitle)
        case .screenshot:
            let savedNote = try container.decodeIfPresent(String.self, forKey: .savedNote)
            self = .screenshot(savedNote: savedNote)
        case .search:
            self = .search
        }
    }
}
