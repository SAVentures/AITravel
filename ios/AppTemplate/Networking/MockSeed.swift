import Foundation

/// The immutable DTO snapshot the ``MockProvider`` serves — a `Sendable` value with no
/// persisted mutable state. Requests compute their `mockResponse(from:)` purely from this
/// seed (`04-networking.md §7`).
///
/// It starts **empty**. Each feature adds its top-level entity as a stored field via an
/// extension (e.g. `var library: LibraryDTO`), and `SampleData.seed(for:)` populates those
/// fields per scenario. Keeping the core type empty here lets parallel feature scaffolders
/// add fields without colliding on this file.
struct MockSeed: Sendable {}
