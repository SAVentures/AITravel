import Foundation

// MARK: - TripShapeStrategy

/// The three mutually-exclusive shape strategies the user can pick in Step 02.
///
/// A raw-`String` enum so `Codable` synthesis is free and wire values are human-readable
/// (`02-models.md §3.1`). The UI-visible label and eyebrow are on `TripShapeOption`
/// (which wraps a strategy with its full display payload), not here — the model layer
/// never imports SwiftUI.
nonisolated enum TripShapeStrategy: String, Codable, Equatable, Hashable, Sendable {
    /// Card A — user pins an explicit day count.
    case fixedDays
    /// Card B — itinerary covers the user's saved-place bucket.
    /// `TripShapeOption.lockable == true` when this case is active and `savedHere == 0`.
    case coverBucket
    /// Card C — highlights-only shape, used in state C's taste form path.
    case highlights
}

// MARK: - MetricFragment

/// One fragment of a card's metric strip.
///
/// A strip is a short sequence of these — e.g. `["4 days", " · ", "skips 9"]` where
/// "skips 9" may be `.struck`. Leaf value type; reused directly by `TripShapeCardModel`
/// in the presenter and by `TripShapeCard` on the component side (`02-models.md §1.2`).
nonisolated struct MetricFragment: Codable, Equatable, Hashable, Sendable {
    /// The display text of this fragment.
    var text: String
    /// When `true` the presenter renders this fragment in a heavier/primary style.
    var emphasis: Bool
    /// When `true` the presenter renders this fragment with a strikethrough.
    var struck: Bool

    init(text: String, emphasis: Bool = false, struck: Bool = false) {
        self.text = text
        self.emphasis = emphasis
        self.struck = struck
    }
}

// MARK: - DiagramSpec

/// The data-driven specification for the embedded diagram inside a `TripShapeCard`.
///
/// Each case carries its own payload, so this is an associated-value enum with the
/// manual tag-keyed `Codable` pattern (`02-models.md §3.2`). The component layer maps
/// these cases to its own `TripShapeDiagram` view enum; the model layer stays
/// SwiftUI-free.
nonisolated enum DiagramSpec: Equatable, Hashable, Sendable {
    /// A row of dot columns: `filled` indices are rendered solid, `dim` indices muted.
    case fixedDays(filled: [Int], dim: [Int])
    /// A grid of day-colored dots; `dayCounts` is the number of dots per column bucket.
    case coverBucket(dayCounts: [Int])
    /// Horizontal bars ranked by value. `pickIndex` highlights the suggested pick;
    /// `dimIndex` mutes one bar (e.g. the locked/off option).
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

/// A fully-resolved display option for one trip-shape card in Step 02.
///
/// Collection-stored (the three options live in an array on `OnboardingContextDTO` and
/// are iterated by the presenter), so it is `Identifiable` with a stable literal id
/// (`"shape-fixed-days"`, `"shape-cover-bucket"`, `"shape-highlights"`).
/// Leaf value type — already wire-safe, reused directly by the DTO layer (`02-models.md §1.2`).
///
/// - Note: `coverBucket` options carry `lockable == true` when the destination has no
///   saved places (`savedHere == 0`). The lock copy lives in `lockReason`.
nonisolated struct TripShapeOption: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable literal id — e.g. `"shape-fixed-days"`.
    let id: String
    /// Which strategy this option represents.
    var strategy: TripShapeStrategy
    /// Short eyebrow label displayed above the title — e.g. `"A · Fixed days"`.
    var eyebrow: String
    /// Primary display title of the card.
    var title: String
    /// Optional one-liner beneath the title.
    var tagline: String?
    /// The sequence of metric fragments rendered as a mono strip on the card.
    var metricStrip: [MetricFragment]
    /// Data-driven spec for the embedded diagram.
    var diagram: DiagramSpec
    /// Whether this option can become locked (always `true` for `.coverBucket`).
    var lockable: Bool
    /// Human-readable reason shown on the lock overlay when `lockable && savedHere == 0`.
    /// E.g. `"Save places in Kyoto to unlock"`.
    var lockReason: String?
}
