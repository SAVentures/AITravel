import Foundation

// MARK: - City

/*
 A destination city on the onboarding step. Leaf value type, reused directly at the wire by
 OnboardingContextDTO (no separate DTO). `savedHere` drives the A/B/C state branch.
*/
nonisolated struct City: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var country: String
    var savedHere: Int
    var meta: CityMeta
}

// MARK: - CityMeta

// Associated-value enum with manual tag-keyed Codable (02-models.md §3.2).
nonisolated enum CityMeta: Equatable, Hashable, Sendable {
    case savedCount(Int)
    case planStarted
    case neighborhood(String)
    case medina

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
