import Foundation

// MARK: - TripShapeStrategy

/*
 The three mutually-exclusive shape strategies the user picks in Step 02. Raw-`String` for free
 `Codable` and human-readable wire values; display labels live on `TripShapeOption`, not here.
*/
nonisolated enum TripShapeStrategy: String, Codable, Equatable, Hashable, Sendable {
    case fixedDays
    /// `TripShapeOption.lockable == true` when this case is active and `savedHere == 0`.
    case coverBucket
    case highlights
}

// MARK: - MetricFragment

/// One fragment of a card's metric strip — e.g. `["4 days", " · ", "skips 9"]` where "skips 9" may be `.struck`.
nonisolated struct MetricFragment: Codable, Equatable, Hashable, Sendable {
    var text: String
    var emphasis: Bool
    var struck: Bool

    init(text: String, emphasis: Bool = false, struck: Bool = false) {
        self.text = text
        self.emphasis = emphasis
        self.struck = struck
    }
}

// MARK: - DiagramSpec

/*
 Data-driven spec for the embedded diagram inside a `TripShapeCard`. Associated-value enum, so it
 uses the manual tag-keyed `Codable` pattern below. The component layer maps these to its own
 `TripShapeDiagram` view enum; the model layer stays SwiftUI-free.
*/
nonisolated enum DiagramSpec: Equatable, Hashable, Sendable {
    /// `filled` indices render solid, `dim` indices muted.
    case fixedDays(filled: [Int], dim: [Int])
    /// `dayCounts` is the number of dots per column bucket.
    case coverBucket(dayCounts: [Int])
    /// `pickIndex` highlights the suggested pick; `dimIndex` mutes one bar (e.g. the locked option).
    case rankedBars(values: [Double], pickIndex: Int?, dimIndex: Int?)
}

extension DiagramSpec: Codable {
    private enum CodingKeys: String, CodingKey {
        case tag
        case filled, dim            // fixedDays
        case dayCounts              // coverBucket
        case values, pickIndex, dimIndex  // rankedBars
    }

    private enum Tag: String, Codable {
        case fixedDays, coverBucket, rankedBars
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixedDays(let filled, let dim):
            try container.encode(Tag.fixedDays, forKey: .tag)
            try container.encode(filled, forKey: .filled)
            try container.encode(dim, forKey: .dim)
        case .coverBucket(let dayCounts):
            try container.encode(Tag.coverBucket, forKey: .tag)
            try container.encode(dayCounts, forKey: .dayCounts)
        case .rankedBars(let values, let pickIndex, let dimIndex):
            try container.encode(Tag.rankedBars, forKey: .tag)
            try container.encode(values, forKey: .values)
            try container.encodeIfPresent(pickIndex, forKey: .pickIndex)
            try container.encodeIfPresent(dimIndex, forKey: .dimIndex)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(Tag.self, forKey: .tag)
        switch tag {
        case .fixedDays:
            let filled = try container.decode([Int].self, forKey: .filled)
            let dim = try container.decode([Int].self, forKey: .dim)
            self = .fixedDays(filled: filled, dim: dim)
        case .coverBucket:
            let dayCounts = try container.decode([Int].self, forKey: .dayCounts)
            self = .coverBucket(dayCounts: dayCounts)
        case .rankedBars:
            let values = try container.decode([Double].self, forKey: .values)
            let pickIndex = try container.decodeIfPresent(Int.self, forKey: .pickIndex)
            let dimIndex = try container.decodeIfPresent(Int.self, forKey: .dimIndex)
            self = .rankedBars(values: values, pickIndex: pickIndex, dimIndex: dimIndex)
        }
    }
}

// MARK: - TripShapeOption

/*
 A fully-resolved display option for one trip-shape card in Step 02. The three options live in an
 array on `OnboardingContextDTO`, so `Identifiable` with a stable literal id (e.g. `"shape-fixed-days"`).
 `.coverBucket` options carry `lockable == true` when the destination has no saved places
 (`savedHere == 0`); the lock copy is `lockReason`.
*/
nonisolated struct TripShapeOption: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var strategy: TripShapeStrategy
    var eyebrow: String
    var title: String
    var tagline: String?
    var metricStrip: [MetricFragment]
    var diagram: DiagramSpec
    var lockable: Bool
    var lockReason: String?
}
