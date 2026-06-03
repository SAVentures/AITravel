import Foundation

// MARK: - ReachRow

/* One row in a neighborhood's reach summary, rendered by `TimeHint` on the base-location step. */
nonisolated struct ReachRow: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let systemImage: String
    let label: String
    let detail: String?
    let measurement: String  // mono / tabular digits so numerals align in TimeHint (J-7.2 / T-1.2)

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

/* A neighborhood option for the base-location step — read-only display data composed into `BaseLocation`. */
nonisolated struct Neighborhood: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let placeCount: Int
    let blurb: String  // single-word character word, e.g. "central" — presenter may capitalize/style
    let reachRows: [ReachRow]
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
