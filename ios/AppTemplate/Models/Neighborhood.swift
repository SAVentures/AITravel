import Foundation

// MARK: - ReachRow

/// One row in a neighborhood's reach summary — a transport mode, a label, an optional secondary
/// span, and a mono measurement. Rendered by the `TimeHint` component on the base-location step.
///
/// Leaf value type: not a mutable list row, so it stays a `struct` (02-models.md §1.2).
/// Wire-safe as-is — no separate DTO required.
nonisolated struct ReachRow: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable literal id, e.g. `"reach-alfama-walk"`.
    let id: String
    /// SF Symbol name for the leading transport glyph, e.g. `"figure.walk"`.
    let systemImage: String
    /// The primary label, e.g. `"Walk to most saves"`.
    let label: String
    /// An optional secondary span that follows the label, e.g. `"from the base"`. `nil` when
    /// the label alone is sufficient.
    let detail: String?
    /// The mono measurement — tabular digits, e.g. `"≤ 25 min"` or `"12 min"`. Rendered in the
    /// `TimeHint` mono role so numerals align (J-7.2 / T-1.2).
    let measurement: String

    init(
        id: String,
        systemImage: String,
        label: String,
        detail: String? = nil,
        measurement: String
    ) {
        self.id = id
        self.systemImage = systemImage
        self.label = label
        self.detail = detail
        self.measurement = measurement
    }
}

// MARK: - Neighborhood

/// A neighborhood option for the base-location step: a name, a place count, a one-word character
/// blurb, the set of reach rows, and a recommended flag.
///
/// Leaf value type: not a mutable list row — it is display data composed into `BaseLocation` and
/// surfaced read-only by the base-location presenter (02-models.md §1.2). Wire-safe as-is.
nonisolated struct Neighborhood: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable literal id, e.g. `"neighborhood-alfama"`.
    let id: String
    /// Display name, e.g. `"Alfama"`.
    let name: String
    /// Number of saved places within the neighborhood, e.g. `18`.
    let placeCount: Int
    /// A single-word character blurb surfaced below the name, e.g. `"central"`, `"quieter"`,
    /// `"west"`. Kept short — the presenter may capitalize or style it.
    let blurb: String
    /// The reach rows displayed in the `TimeHint` rail below the neighborhood card.
    let reachRows: [ReachRow]
    /// Whether the AI recommends this neighborhood as the base for the current draft.
    let isRecommended: Bool

    init(
        id: String,
        name: String,
        placeCount: Int,
        blurb: String,
        reachRows: [ReachRow],
        isRecommended: Bool
    ) {
        self.id = id
        self.name = name
        self.placeCount = placeCount
        self.blurb = blurb
        self.reachRows = reachRows
        self.isRecommended = isRecommended
    }
}
