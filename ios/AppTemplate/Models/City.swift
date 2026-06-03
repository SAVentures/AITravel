import Foundation

// MARK: - City

/// A destination city shown on the onboarding destination step.
///
/// Leaf value type — not a mutable list row, so `struct` (`02-models.md §1.2`).
/// Conforms to `Identifiable` because it is collection-stored (the city catalog).
/// Wire-safe: no DTO needed — leaf value types are reused directly by `OnboardingContextDTO`
/// (`02-models.md §1.2`, plan W2-09).
nonisolated struct City: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var country: String
    /// Number of saved places the current user has in this city (drives the A/B/C branch).
    var savedHere: Int
    /// Per-tile contextual metadata displayed beneath the city name.
    var meta: CityMeta
}

// MARK: - CityMeta

/// The per-tile contextual label shown beneath a city name in the destination grid.
///
/// Cases:
/// - `.savedCount(Int)` → "23 saved"
/// - `.planStarted`     → "plan started"
/// - `.neighborhood(String)` → e.g. "Roma Norte"
/// - `.medina`          → "medina"
///
/// Associated-value enum — manual tag-keyed `Codable` per `02-models.md §3.2`.
nonisolated enum CityMeta: Equatable, Hashable, Sendable {
    /// How many of the user's saved places are in this city.  Display: "23 saved".
    case savedCount(Int)
    /// A trip plan has already been started for this city.  Display: "plan started".
    case planStarted
    /// A notable neighbourhood label for the city.  Display: the neighbourhood name, e.g. "Roma Norte".
    case neighborhood(String)
    /// The city's historic medina district.  Display: "medina".
    case medina

    /// A short string suitable for display in a `Tag` or subtitle position.
    var displayLabel: String {
        switch self {
        case .savedCount(let n):      return "\(n) saved"
        case .planStarted:            return "plan started"
        case .neighborhood(let name): return name
        case .medina:                 return "medina"
        }
    }
}

// MARK: - CityMeta: Codable

extension CityMeta: Codable {

    private enum CodingKeys: String, CodingKey {
        case tag
        case count
        case name
    }

    private enum Tag: String, Codable {
        case savedCount
        case planStarted
        case neighborhood
        case medina
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .savedCount(let n):
            try container.encode(Tag.savedCount, forKey: .tag)
            try container.encode(n, forKey: .count)
        case .planStarted:
            try container.encode(Tag.planStarted, forKey: .tag)
        case .neighborhood(let name):
            try container.encode(Tag.neighborhood, forKey: .tag)
            try container.encode(name, forKey: .name)
        case .medina:
            try container.encode(Tag.medina, forKey: .tag)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(Tag.self, forKey: .tag)
        switch tag {
        case .savedCount:
            let n = try container.decode(Int.self, forKey: .count)
            self = .savedCount(n)
        case .planStarted:
            self = .planStarted
        case .neighborhood:
            let name = try container.decode(String.self, forKey: .name)
            self = .neighborhood(name)
        case .medina:
            self = .medina
        }
    }
}
