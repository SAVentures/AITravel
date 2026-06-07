/*
 The Saved tab home — the keystone screen of the Saved slice. Layout + wiring only; all per-state
 derivation lives in SavedListPresenter (06-screens §3). Composes ScreenScaffold(.root) (large title,
 collapses on scroll, tab bar persists). The "+" add affordance (one secondary control, 06 §2.3) opens
 AddPlaceSheet via an ephemeral `@State` sheet flag. INTERIM (06 §2.6): ScreenScaffold exposes no
 trailing-secondary-control slot, and a screen must never hand-wire a raw `.toolbar`, so the "+" is
 rendered in-content (`addAffordanceRow`) until the scaffold gains that slot. NO bottom ActionBar — the
 list mockups have none.

 Ports one structure across four states (the fidelity targets):
   mockups/screens/saved/saved-empty.html      — no places → three WayToSaveRows.
   mockups/screens/saved/saved-populated.html   — byCategory groups (dot + label + count + PlaceRows).
   mockups/screens/saved/saved-by-source.html   — SourceCards (one clip → many SourcePlaceRows).
   mockups/screens/saved/saved-search.html      — query non-empty → fuzzy PlaceRows (trailing
                                                  CategoryChip), grouped "N places" / "Also nearby",
                                                  with an AIVoice "matching by vibe" line.

 Interactivity inventory (06 §4.1 — every affordance → one sink, no dead closures):
   - SearchWell                → `query` @State (the presenter filters each keystroke).
   - SegmentedSelector         → `mode` @State (byCategory / bySource).
   - city-filter Menu          → `cityFilter` @State.
   - FilterChip (All + cats)   → `categoryFilter` @State.
   - PlaceRow tap              → store.push(PlaceDetailRoute(id:)).
   - SourceCard head tap       → toggles the `expanded` Set<String> @State.
   - SourcePlaceRow tap        → store.push(PlaceDetailRoute(id:)).
   - "+" add (addAffordanceRow)→ `showsAddSheet` @State (presents AddPlaceSheet). In-content interim
                                 placement (06 §2.6) — no slot on ScreenScaffold yet, no raw `.toolbar`.
   - WayToSaveRow taps (empty) → reel opens the add-sheet (D-4: the one built path); screenshot/search
                                 open the same sheet (their deeper capture flows are separate stories —
                                 wired, never an invented screen).
   - writeError.banner         → reads store.writeError (a banner, never a toast/alert — 06 §6).

 Logic out of the view: derivation → SavedListPresenter; navigation → store.push; the write → addPlace
 (inside AddPlaceSheet). The view holds only ephemeral UI state (@State).
*/
import SwiftUI

// MARK: - Mode (ephemeral UI state shared by the view + presenter)

/// By-category vs by-source — the `SegmentedSelector` selection. Ephemeral UI state (06 §3), not domain
/// state. `Identifiable & Hashable` so it drives `SegmentedSelector`.
enum SavedListMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case byCategory
    case bySource

    var id: String { rawValue }
    var label: String {
        switch self {
        case .byCategory: return "By category"
        case .bySource:   return "By source"
        }
    }
}

struct SavedListView: View {

    @Environment(AppStore.self) private var store

    // MARK: Ephemeral UI state only (06 §3) — never domain state

    @State private var query: String
    @FocusState private var searchFocused: Bool
    @State private var mode: SavedListMode
    @State private var cityFilter: String?
    @State private var categoryFilter: PlaceCategory?
    /// Expanded source cards (their ids). Caller-owned disclosure, exactly like SegmentedSelector's
    /// selection (the SourceCard component owns no expansion state).
    @State private var expandedSources: Set<String>
    /// The add-place sheet flag — the "+" affordance and the empty-state ways present it.
    @State private var showsAddSheet = false

    /// Seeds the screen's *ephemeral UI state* so each `#Preview` (and a future deep link into a given
    /// mode/search) renders a distinct state. All parameters default to the production launch state
    /// (by-category, empty query, nothing expanded), so the live call site stays `SavedListView()`.
    init(
        mode: SavedListMode = .byCategory,
        query: String = "",
        expandedSources: Set<String> = []
    ) {
        _mode = State(initialValue: mode)
        _query = State(initialValue: query)
        _expandedSources = State(initialValue: expandedSources)
    }

    var body: some View {
        let p = SavedListPresenter(
            store: store,
            query: query,
            mode: mode,
            cityFilter: cityFilter,
            categoryFilter: categoryFilter
        )

        ScreenScaffold(.root(title: "Saved")) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let message = writeErrorMessage {
                    errorBanner(message)
                }

                if p.isEmpty {
                    emptyState(p)
                } else if p.isSearching {
                    // saved-search.html: SearchWell → AIVoice "matching by vibe" → results. No hero/controls.
                    // INTERIM (06 §2.6): ScreenScaffold exposes no top-right secondary-control slot, so the
                    // "+" add affordance is rendered in-content rather than hand-wiring a raw `.toolbar`.
                    addAffordanceRow
                    searchWell(p)
                    searchResults(p)
                } else {
                    addAffordanceRow
                    hero(p)
                    searchWell(p)
                    controls(p)
                    if mode == .byCategory {
                        categoryPills(p)
                        categoryContent(p)
                    } else {
                        sourceContent(p)
                    }
                }
            }
            .padding(.top, Spacing.md)
        }
        // Loads the tab's data over the network (the seam confirmed in AppStore+Saved). Idempotent:
        // re-hydrating only when the graph is still absent, so returning to the tab doesn't refetch.
        .task {
            if store.savedPlaces == nil {
                await store.loadSavedPlaces()
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            AddPlaceSheet()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Add affordance (saved-*.html topbar "+")

    /// The "+" add affordance — the mockup's top-right control. INTERIM placement (06 §2.6):
    /// `ScreenScaffold` exposes no trailing-secondary-control slot, and a screen must never hand-wire a
    /// raw `.toolbar`. Until the scaffold gains that slot (a swift-design-system change), this keeps the
    /// affordance reachable in every non-empty state, with its `savedlist.add` id and `showsAddSheet` sink
    /// intact. (In the empty state the WayToSaveRows already open the same sheet.)
    private var addAffordanceRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                showsAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                    .frame(width: addHitTarget, height: addHitTarget)
                    .background(ColorRole.fillTertiary, in: .circle)
                    .contentShape(.circle)
            }
            .accessibilityLabel("Add a place")
            .accessibilityIdentifier("savedlist.add")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Hero (saved-populated / saved-by-source `.sav-hero`)

    private func hero(_ p: SavedListPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(p.eyebrow)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
            Text(p.title)
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
            Text(p.headerCounts)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Search well (sav-search)

    private func searchWell(_ p: SavedListPresenter) -> some View {
        SearchWell(
            text: $query,
            placeholder: p.searchPlaceholder,
            kbdHint: nil,
            showsClearButton: true,
            accessibilityID: "savedlist.search",
            accessibilityLabel: "Search saved places",
            focused: $searchFocused
        )
    }

    // MARK: - Controls — segmented mode + city filter (sav-controls)

    private func controls(_ p: SavedListPresenter) -> some View {
        HStack(spacing: Spacing.md) {
            SegmentedSelector(
                options: SavedListMode.allCases,
                selection: mode,
                label: \.label,
                systemImage: { _ in nil },
                accessibilityIDPrefix: "savedlist.mode",
                accessibilityLabel: "Group saved places",
                onSelect: { mode = $0 }
            )
            cityFilterMenu(p)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The "All cities" menu (mockup `.city-filter`): writes `cityFilter` @State. Each option is a real
    /// sink; nothing here is decorative.
    private func cityFilterMenu(_ p: SavedListPresenter) -> some View {
        Menu {
            ForEach(p.cityOptions) { option in
                Button {
                    cityFilter = option.cityName
                } label: {
                    if option.cityName == cityFilter {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(p.selectedCity.label)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(Typography.footnote)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(ColorRole.fillTertiary, in: .capsule)
            .contentShape(.capsule)
        }
        .accessibilityIdentifier("savedlist.cityFilter")
    }

    // MARK: - Category pills (sav-pills) — the FilterChip row

    private func categoryPills(_ p: SavedListPresenter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All" — clears the category filter.
                FilterChip(
                    label: "All",
                    isSelected: categoryFilter == nil,
                    action: { categoryFilter = nil }
                )
                .accessibilityIdentifier("savedlist.filter.all")

                ForEach(p.categoryCounts, id: \.category) { entry in
                    FilterChip(
                        label: "\(entry.category.displayLabel) \(entry.count)",
                        isSelected: categoryFilter == entry.category,
                        action: {
                            // Toggle: tapping the active category returns to "All".
                            categoryFilter = (categoryFilter == entry.category) ? nil : entry.category
                        }
                    )
                    .accessibilityIdentifier("savedlist.filter.\(entry.category.rawValue)")
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - By category (saved-populated)

    private func categoryContent(_ p: SavedListPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            ForEach(p.categoryGroups) { group in
                VStack(alignment: .leading, spacing: Spacing.md) {
                    categoryHeader(group)
                    ForEach(group.rows) { row in
                        placeRowButton(row)
                    }
                }
            }
        }
    }

    /// The group header (mockup `.daygrp`): a category dot + label + count, then a hairline rule fills the
    /// remaining width (grouping by space + one rule, not a box — J-4).
    private func categoryHeader(_ group: SavedCategoryGroup) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Circle()
                .fill(ColorRole.categoryMark(group.category))
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
            Text(group.label)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
            Text(group.countLabel)
                .font(Typography.caption)
                .monospacedDigit()
                .foregroundStyle(ColorRole.textTertiary)
            Spacer(minLength: Spacing.md)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - By source (saved-by-source)

    private func sourceContent(_ p: SavedListPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(p.sourceGroups) { group in
                SourceCard(
                    model: group,
                    isExpanded: expandedSources.contains(group.id),
                    onToggle: { toggleSource(group.id) },
                    onSelectPlace: { store.push(PlaceDetailRoute(id: $0)) },
                    accessibilityID: "sourcecard.\(group.id)"
                )
            }
        }
    }

    private func toggleSource(_ id: String) {
        if expandedSources.contains(id) {
            expandedSources.remove(id)
        } else {
            expandedSources.insert(id)
        }
    }

    // MARK: - Search results (saved-search)

    private func searchResults(_ p: SavedListPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            AIVoice(eyebrow: p.searchVoice.eyebrow, line: p.searchVoice.line)
                .frame(maxWidth: .infinity, alignment: .leading)

            if p.searchHasResults {
                ForEach(p.searchGroups) { group in
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        searchHeader(group)
                        ForEach(group.rows) { row in
                            placeRowButton(row)
                        }
                    }
                }
            } else {
                noResults()
            }
        }
    }

    private func searchHeader(_ group: SavedSearchGroup) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(group.title)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
            Text(group.subtitle)
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textTertiary)
            Spacer(minLength: Spacing.md)
        }
        .accessibilityElement(children: .combine)
    }

    private func noResults() -> some View {
        EmptyStateView(
            systemImage: "magnifyingglass",
            message: "Nothing saved matches \u{201C}\(query)\u{201D} yet."
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("savedlist.search.empty")
    }

    // MARK: - Place row → push detail (the shared list/search row wiring)

    /// Wraps the content-only `PlaceRow` in the tappable Button that pushes the detail and owns the
    /// `placerow.<id>` id (the component is content-only; the screen supplies the sink + the id — 05 §8.1).
    private func placeRowButton(_ row: PlaceRowModel) -> some View {
        Button {
            store.push(PlaceDetailRoute(id: row.id))
        } label: {
            PlaceRow(model: row)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("placerow.\(row.id)")
    }

    // MARK: - Empty state (saved-empty)

    private func emptyState(_ p: SavedListPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(p.emptyTitle)
                    .font(Typography.titleLarge)
                    .foregroundStyle(ColorRole.textPrimary)
                Text(p.emptyBody)
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: Spacing.md) {
                ForEach(p.wayToSave) { way in
                    WayToSaveRow(model: way, accessibilityID: "waytosave.\(way.id)") {
                        // D-4: the reel path is the one built capture flow (the add-sheet's networked
                        // write); the screenshot/search flows are separate stories. All three open the
                        // sheet so nothing is a dead closure — the sheet routes the future capture flows.
                        showsAddSheet = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("savedlist.emptyState")
    }

    // MARK: - Write-error banner (read off the store — never a toast/alert, 06 §6)

    private var writeErrorMessage: String? { store.writeError?.bannerMessage }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.destructive)
                .accessibilityHidden(true)
            Text(message)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("writeError.banner")
    }

    // MARK: - Scaled metrics (Dynamic-Type-safe; the group-header dot scales with its caption)

    @ScaledMetric(relativeTo: .caption) private var dotSize: CGFloat = Sizing.dot

    /// The "+" add control's tap target — the minimum 44pt target, scaled with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var addHitTarget: CGFloat = Sizing.minTapTarget
}

// MARK: - Previews (06 §8) — one per state, seeded via AppStore.preview(savedPlaces:), no `.shared`

#Preview("Saved — by category") {
    NavigationStack {
        SavedListView(mode: .byCategory)
    }
    .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}

#Preview("Saved — by source") {
    NavigationStack {
        // Pre-expand the first source clip so the expanded SourceCard (its SourcePlaceRows) shows.
        // The key matches SavedListPresenter.sourceKey for SampleData's first place.
        SavedListView(mode: .bySource, expandedSources: ["reel:saltinmycoffee:Lisbon in 48 hours"])
    }
    .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}

#Preview("Saved — search active") {
    NavigationStack {
        SavedListView(query: "rooftop")
    }
    .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}

#Preview("Saved — empty") {
    NavigationStack {
        SavedListView()
    }
    .environment(AppStore.preview(savedPlaces: SampleData.emptySavedPlacesDTO()))
}
