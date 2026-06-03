import Foundation

// MARK: - TransportMode

/// The mutually-exclusive travel modes a user can select or be recommended.
///
/// A raw-`String` enum so `Codable` is synthesised for free (`02-models.md §3.1`).
/// `CaseIterable` lets the UI build its picker without a hand-written array.
nonisolated enum TransportMode: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case walk
    case transit
    case drive
    case cycle
    case rideshare
    case bus

    /// An SF Symbol name representing this mode.
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

    /// A short display label for this mode.
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

/// The user's transport preferences for a trip: a primary mode, an optional set of
/// acceptable alternatives, and the AI-suggested mode.
///
/// Leaf value type — `Codable, Equatable, Hashable, Sendable` (`02-models.md §1.2`).
/// Held directly on `TripDraft` (the reference model); no DTO of its own.
nonisolated struct TransportSelection: Codable, Equatable, Hashable, Sendable {
    /// The mode the user selected as their primary preference.
    var primary: TransportMode
    /// Additional modes the user is happy to use alongside the primary.
    var alsoOK: Set<TransportMode>
    /// The mode the AI recommends for this trip context.
    var suggested: TransportMode
}

// MARK: - ReasonRow

/// A single row inside a `TransportRec` that surfaces one reason supporting the
/// suggested transport mode (e.g. "€1.65 per trip", "≤ 25 min to most sites").
///
/// `Identifiable` because it is collection-stored in `TransportRec.reasons`
/// and iterated in a `ForEach`; `let id: String` satisfies `Identifiable`
/// with `ID == String` per the project convention (`02-models.md §1.3`).
nonisolated struct ReasonRow: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable literal id, e.g. `"reason-cost"`.
    let id: String
    /// SF Symbol name for the leading icon.
    var systemImage: String
    /// Body copy for this row.
    var text: String
    /// Mono measurement fragment shown trailing (e.g. `"€1.65"`, `"≤ 25 min"`, `"€18+/day"`).
    var measurement: String
}

// MARK: - ContextNoteModel

/// A quiet contextual note shown beneath a recommendation card.
///
/// Named `ContextNoteModel` to avoid colliding with the `ContextNote` design-system
/// component (`DesignSystem/Components/ContextNote.swift`) which renders this data.
/// Leaf value type — no `id`, not collection-stored.
nonisolated struct ContextNoteModel: Codable, Equatable, Hashable, Sendable {
    /// Short mono caps label shown above the body (e.g. `"For your dates"`).
    var eyebrow: String
    /// Body copy, may contain bold spans at the UI layer.
    var text: String
}

// MARK: - TransportRec

/// The AI transport recommendation for a destination, carrying the suggested mode,
/// supporting reasons, and a contextual note.
///
/// Leaf value type — `Codable, Equatable, Hashable, Sendable` (`02-models.md §1.2`).
/// Reused directly by the DTO layer — no `TransportRecDTO` needed.
nonisolated struct TransportRec: Codable, Equatable, Hashable, Sendable {
    /// The AI-recommended transport mode.
    var suggestedMode: TransportMode
    /// City name and trip duration on two lines, e.g. `"Lisbon\n4 days"`.
    var cityContext: String
    /// Supporting reasons for the recommendation (displayed as `ReasonRow` rows).
    var reasons: [ReasonRow]
    /// A quiet contextual note (e.g. eyebrow `"For your dates"`, body with rain/event copy).
    var contextNote: ContextNoteModel
}
