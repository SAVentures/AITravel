/*
 Stateless derivation for the Saved tab home (SavedListView). Given the store + the screen's ephemeral
 UI state (query, mode, cityFilter, categoryFilter), it derives the DATA the four states render — never
 a View (06-screens §3). Rebuilt each `body` pass; constructed in `body` so the store's per-field
 dependency tracking is preserved.

 Ports the four state mockups (mockups/screens/saved/):
 - saved-empty       → `wayToSave` (3 WayToSaveRowModels) when there are no places at all.
 - saved-populated   → `categoryGroups` ([CategoryGroup]: dot + label + count + PlaceRowModels).
 - saved-by-source   → `sourceGroups` ([SourceCardModel]: one clip → many SourcePlaceRowModels).
 - saved-search      → `searchGroups` (query non-empty → fuzzy PlaceRowModels w/ trailing CategoryChip,
                       grouped "N places" / "Also nearby").

 Reads `store.savedPlaces`. The reference-model rows are read here only to map them into the
 design-system components' value-type fixtures (PlaceRowModel / SourceCardModel / …).
*/
import SwiftUI

// MARK: - Derived view-models (DATA, not Views)

/// One "By category" group — the mockup `.daygrp` header (a category dot + label + count) over its
/// `PlaceRow`s. `category` drives the header dot colour; `rows` are the already-mapped row fixtures.
struct SavedCategoryGroup: Identifiable, Sendable {
    let category: PlaceCategory
    let count: Int
    let rows: [PlaceRowModel]

    var id: PlaceCategory { category }
    /// Header label, e.g. "Eat".
    var label: String { category.displayLabel }
    /// Header count line, e.g. "7 places".
    var countLabel: String { "\(count) \(count == 1 ? "place" : "places")" }
}

/// One "search results" group — the mockup `.daygrp` ("6 places · across 2 cities" / "Also nearby ·
/// matched loosely") over its `PlaceRow`s (trailing `CategoryChip`, the search variant).
struct SavedSearchGroup: Identifiable, Sendable {
    let id: String
    /// The group title, e.g. "6 places" or "Also nearby".
    let title: String
    /// The group sub label, e.g. "across 2 cities" or "matched loosely".
    let subtitle: String
    let rows: [PlaceRowModel]
}

/// One city-filter option for the "All cities" control (the mockup `.city-filter` menu).
struct SavedCityOption: Identifiable, Hashable, Sendable {
    /// `nil` is the "All cities" sentinel; a non-nil name filters to that city.
    let cityName: String?
    var id: String { cityName ?? "all" }
    var label: String { cityName ?? "All cities" }
}

// MARK: - SavedListPresenter

struct SavedListPresenter {

    let store: AppStore
    /// The live search query (ephemeral `@State` the presenter filters on each keystroke).
    let query: String
    /// By-category vs by-source (ephemeral `@State`).
    let mode: SavedListMode
    /// `nil` = all cities; a city name narrows every state to that city (ephemeral `@State`).
    let cityFilter: String?
    /// `nil` = all categories; a category narrows the by-category list (the "All" pill, ephemeral `@State`).
    let categoryFilter: PlaceCategory?

    init(
        store: AppStore,
        query: String = "",
        mode: SavedListMode = .byCategory,
        cityFilter: String? = nil,
        categoryFilter: PlaceCategory? = nil
    ) {
        self.store = store
        self.query = query
        self.mode = mode
        self.cityFilter = cityFilter
        self.categoryFilter = categoryFilter
    }

    // MARK: - Graph access

    private var allPlaces: [SavedPlaceModel] { store.savedPlaces?.places ?? [] }

    /// Places after the city filter only (the filter that applies across every mode).
    private var cityFiltered: [SavedPlaceModel] {
        guard let cityFilter else { return allPlaces }
        return allPlaces.filter { $0.location.cityName == cityFilter }
    }

    // MARK: - Top-level state

    /// No places saved at all → the rich empty state (saved-empty), regardless of mode/query.
    var isEmpty: Bool { allPlaces.isEmpty }

    /// A non-blank query switches to the search-results layout (saved-search).
    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Hero copy (saved-populated / saved-by-source heroes)

    var eyebrow: String { "Wishlist" }

    var title: String {
        switch mode {
        case .byCategory: return "Places you've saved"
        case .bySource:   return "Saved by source"
        }
    }

    /// The hero sub line — "24 places · 3 cities · from 11 sources" (by-category) /
    /// "11 sources · 24 places · one clip can hold many" (by-source). Counts are derived from the graph,
    /// digits not spelled out (J-11.4).
    var headerCounts: String {
        let places = allPlaces.count
        let cities = distinctCityNames.count
        let sources = distinctSourceKeys.count
        switch mode {
        case .byCategory:
            return "\(places) \(places == 1 ? "place" : "places") · "
                + "\(cities) \(cities == 1 ? "city" : "cities") · "
                + "from \(sources) \(sources == 1 ? "source" : "sources")"
        case .bySource:
            return "\(sources) \(sources == 1 ? "source" : "sources") · "
                + "\(places) \(places == 1 ? "place" : "places") · one clip can hold many"
        }
    }

    // MARK: - Search field placeholder (saved-populated `.q` copy)

    var searchPlaceholder: String {
        switch mode {
        case .byCategory: return "Search saved — try \u{201C}rooftop\u{201D} or \u{201C}pastéis\u{201D}"
        case .bySource:   return "Search saved — by place or creator"
        }
    }

    // MARK: - Empty state — three "ways to save" (saved-empty `.ways`)

    var emptyTitle: String { "Save places from anywhere" }

    var emptyBody: String {
        "Drop a reel, a screenshot, or a name — I'll pull out the place, tag it, "
            + "and keep it for whichever trip it fits."
    }

    /// The three capture methods, prominent reel first (mirrors the add-sheet's WayToSaveRow list).
    var wayToSave: [WayToSaveRowModel] {
        [
            WayToSaveRowModel(
                id: "reel",
                title: "Paste a reel or video",
                subtitle: "TikTok, Reel, or YouTube — even if it lists several spots",
                systemImage: "play.rectangle",
                prominent: true
            ),
            WayToSaveRowModel(
                id: "screenshot",
                title: "From a screenshot",
                subtitle: "A map pin, a story, or a menu photo",
                systemImage: "photo"
            ),
            WayToSaveRowModel(
                id: "search",
                title: "Search for a place",
                subtitle: "Find it by name and pin it",
                systemImage: "magnifyingglass"
            ),
        ]
    }

    // MARK: - Filters

    /// Distinct city names across all places (for the header count + the city-filter menu), order-stable.
    var distinctCityNames: [String] {
        orderedUnique(allPlaces.map(\.location.cityName))
    }

    /// The city-filter options — "All cities" then each distinct city.
    var cityOptions: [SavedCityOption] {
        [SavedCityOption(cityName: nil)] + distinctCityNames.map { SavedCityOption(cityName: $0) }
    }

    /// The currently-selected city option (resolves `cityFilter` to its menu option).
    var selectedCity: SavedCityOption { SavedCityOption(cityName: cityFilter) }

    /// Per-category counts within the current city filter — drives the `FilterChip` row labels + the "All"
    /// chip. Order follows `PlaceCategory.allCases` (Eat → Drink → Stay → Do → Shop), as the mockup pills.
    var categoryCounts: [(category: PlaceCategory, count: Int)] {
        PlaceCategory.allCases.compactMap { category in
            let count = cityFiltered.filter { $0.category == category }.count
            return count == 0 ? nil : (category, count)
        }
    }

    /// The total across the current city filter — the "All" pill's implicit count.
    var allCount: Int { cityFiltered.count }

    // MARK: - By category (saved-populated)

    /// Grouped, ordered Eat → Drink → Stay → Do → Shop, after the city + category filters. Each group's
    /// rows are mapped to `PlaceRowModel` with the chevron trailing (a row drills into its detail).
    var categoryGroups: [SavedCategoryGroup] {
        let categories: [PlaceCategory]
        if let categoryFilter {
            categories = [categoryFilter]
        } else {
            categories = PlaceCategory.allCases
        }
        return categories.compactMap { category in
            let places = cityFiltered.filter { $0.category == category }
            guard !places.isEmpty else { return nil }
            return SavedCategoryGroup(
                category: category,
                count: places.count,
                rows: places.map { row(for: $0, trailing: .chevron) }
            )
        }
    }

    // MARK: - By source (saved-by-source)

    /// Source groups for the `SourceCard`s — one entry per distinct source key (a reel clip / a screenshot
    /// batch / a search), each holding its child `SourcePlaceRowModel`s. A reel that yielded many places
    /// becomes one card with many children (the mockup's "Lisbon in 48 hours · 3 places").
    var sourceGroups: [SourceCardModel] {
        var order: [String] = []
        var buckets: [String: [SavedPlaceModel]] = [:]
        for place in cityFiltered {
            let key = sourceKey(for: place.source)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(place)
        }
        return order.compactMap { key in
            guard let places = buckets[key], let first = places.first else { return nil }
            return SourceCardModel(
                id: key,
                title: sourceTitle(for: first.source),
                meta: sourceMeta(for: first.source),
                kind: first.source.kind,
                places: places.map { childRow(for: $0) },
                footHint: footHint(for: first.source, count: places.count)
            )
        }
    }

    // MARK: - Search (saved-search)

    /// The AI-voice "matching by vibe" line (reuses `AIVoice`), derived from the query.
    var searchVoice: (eyebrow: String, line: String) {
        let terms = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map(String.init)
            .joined(separator: " · ")
        return (
            eyebrow: "Matching by vibe",
            line: terms.isEmpty ? "Reading your saved places by feel." : terms
        )
    }

    /// The search result groups: a primary "N places · across M cities" group (direct matches) and an
    /// optional "Also nearby · matched loosely" group (a looser tail). Rows carry the trailing
    /// `CategoryChip` (the search variant).
    var searchGroups: [SavedSearchGroup] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        let direct = cityFiltered.filter { matches($0, query: q, loose: false) }
        let directIDs = Set(direct.map(\.id))
        let loose = cityFiltered.filter { !directIDs.contains($0.id) && matches($0, query: q, loose: true) }

        var groups: [SavedSearchGroup] = []
        if !direct.isEmpty {
            let cities = orderedUnique(direct.map(\.location.cityName)).count
            groups.append(
                SavedSearchGroup(
                    id: "matches",
                    title: "\(direct.count) \(direct.count == 1 ? "place" : "places")",
                    subtitle: "across \(cities) \(cities == 1 ? "city" : "cities")",
                    rows: direct.map { row(for: $0, trailing: .category) }
                )
            )
        }
        if !loose.isEmpty {
            groups.append(
                SavedSearchGroup(
                    id: "nearby",
                    title: "Also nearby",
                    subtitle: "matched loosely",
                    rows: loose.map { row(for: $0, trailing: .category) }
                )
            )
        }
        return groups
    }

    /// Whether the current search yielded nothing (so the view can show a zero-results message).
    var searchHasResults: Bool { !searchGroups.isEmpty }

    // MARK: - Row mapping (domain → component value type)

    private func row(for place: SavedPlaceModel, trailing: PlaceRowTrailing) -> PlaceRowModel {
        PlaceRowModel(
            id: place.id,
            name: place.name,
            meta: place.location.displayLine,
            sourceLabel: place.source.displayLabel.uppercased(),
            sourceSystemImage: place.source.systemImage,
            category: place.category,
            hasThumbnail: false,
            trailing: trailing
        )
    }

    private func childRow(for place: SavedPlaceModel) -> SourcePlaceRowModel {
        SourcePlaceRowModel(
            id: place.id,
            name: place.name,
            meta: place.location.displayLine,
            stamp: place.provenance?.timestamp
        )
    }

    // MARK: - Source grouping helpers

    /// A stable key that groups places sharing one source clip / screenshot batch / search.
    private func sourceKey(for source: PlaceSource) -> String {
        switch source {
        case let .reel(handle, clipTitle):
            return "reel:\(handle):\(clipTitle ?? "")"
        case let .screenshot(savedNote):
            return "screenshot:\(savedNote ?? "")"
        case .search:
            return "search"
        }
    }

    private func sourceTitle(for source: PlaceSource) -> String {
        switch source {
        case let .reel(handle, clipTitle):
            return clipTitle ?? "@\(handle)"
        case let .screenshot(savedNote):
            return savedNote ?? "Screenshot"
        case .search:
            return "Search"
        }
    }

    private func sourceMeta(for source: PlaceSource) -> String {
        switch source {
        case let .reel(handle, _):
            return "Reel · @\(handle)".uppercased()
        case let .screenshot(savedNote):
            return (savedNote ?? "Screenshot").uppercased()
        case .search:
            return "Searched".uppercased()
        }
    }

    private func footHint(for source: PlaceSource, count: Int) -> String? {
        guard source.kind == .reel, count > 1 else { return nil }
        return "Watch the original — pinned at each mention."
    }

    /// A distinct-source key for the header count (one reel clip counts once).
    private var distinctSourceKeys: [String] {
        orderedUnique(allPlaces.map { sourceKey(for: $0.source) })
    }

    // MARK: - Fuzzy match

    /// A direct match hits the name; a loose match also considers the neighborhood / category / source.
    private func matches(_ place: SavedPlaceModel, query: String, loose: Bool) -> Bool {
        let haystacks: [String]
        if loose {
            haystacks = [
                place.name,
                place.location.neighborhood,
                place.location.cityName,
                place.category.displayLabel,
                place.source.displayLabel,
            ]
        } else {
            haystacks = [place.name, place.category.displayLabel]
        }
        return haystacks.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    // MARK: - Utility

    private func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }
}
