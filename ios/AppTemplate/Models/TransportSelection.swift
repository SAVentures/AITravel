import Foundation

// MARK: - TransportMode

nonisolated enum TransportMode: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case walk
    case transit
    case drive
    case cycle
    case rideshare
    case bus

    var systemImage: String {
        switch self {
        case .walk:      "figure.walk"
        case .transit:   "tram.fill"
        case .drive:     "car.fill"
        case .cycle:     "bicycle"
        case .rideshare: "car.2.fill"
        case .bus:       "bus.fill"
        }
    }

    var label: String {
        switch self {
        case .walk:      "Walk"
        case .transit:   "Transit"
        case .drive:     "Drive"
        case .cycle:     "Cycle"
        case .rideshare: "Rideshare"
        case .bus:       "Bus"
        }
    }
}

// MARK: - TransportSelection

/* Leaf value type held directly on TripDraftModel; no DTO of its own. */
nonisolated struct TransportSelection: Codable, Equatable, Hashable, Sendable {
    var primary: TransportMode
    var alsoOK: Set<TransportMode>
    var suggested: TransportMode
}

// MARK: - ReasonRow

/* One reason supporting the suggested mode, collection-stored in TransportRec.reasons. */
nonisolated struct ReasonRow: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var systemImage: String
    var text: String
    var measurement: String  // mono fragment shown trailing, e.g. "€1.65", "≤ 25 min"
}

// MARK: - ContextNoteModel

/* Named ...Model to avoid colliding with the ContextNote design-system component that renders it. */
nonisolated struct ContextNoteModel: Codable, Equatable, Hashable, Sendable {
    var eyebrow: String
    var text: String
}

// MARK: - TransportRec

/* The AI transport recommendation for a destination. Reused directly by the DTO layer — no TransportRecDTO. */
nonisolated struct TransportRec: Codable, Equatable, Hashable, Sendable {
    var suggestedMode: TransportMode
    var cityContext: String  // city + duration on two lines, e.g. "Lisbon\n4 days"
    var reasons: [ReasonRow]
    var contextNote: ContextNoteModel
}
