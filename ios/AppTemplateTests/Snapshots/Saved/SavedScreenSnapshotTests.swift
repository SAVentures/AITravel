// SavedScreenSnapshotTests.swift — Layer 3 render-snapshot lock for Saved tab SCREENS.
//
// These tests are the lock on the Saved screens at authoring time. They do NOT verify the
// design (that is the fidelity-reviewer's authoring-time job); they freeze the accepted render so
// any later change that silently moves a pixel — spacing, color, font, border, icon substitution,
// shadow — fails the build.
// (07-testing §6 governing doc.)
//
// Component-level snapshots (PlaceRow, SourceCard, CategoryChip, WayToSaveRow, ProvenanceCard,
// PlaceInfoGrid, MapSnippet) are locked in Wave 0.A (Snapshots/Saved/*SnapshotTests.swift).
// This file locks SCREENS ONLY — do not duplicate component states here.
//
// States covered (one snapshot each, per 07-testing §6.2):
//
//   SavedListView
//     saved-list-by-category     — populated list in By-category mode (the default production state).
//                                   Locks the hero header, SegmentedSelector, FilterChip row, and
//                                   grouped PlaceRow content all co-occurring on one frame.
//     saved-list-by-source       — populated list in By-source mode with one SourceCard pre-expanded
//                                   (mirrors the #Preview). Locks the SourceCard layout within the
//                                   live screen chrome.
//     saved-list-search          — search-active state (query: "rooftop"). Locks the SearchWell focus
//                                   prompt, the fuzzy-matched PlaceRow results, and the AIVoice line.
//     saved-list-empty           — zero places. Locks the rich WayToSaveRow empty state from
//                                   saved-empty.html instead of grouped content.
//     saved-list-by-category-ax5 — AX5 compensating snapshot (§7.4). Same fixture as
//                                   saved-list-by-category at .accessibilityExtraExtraExtraLarge.
//                                   Locks Dynamic Type scaling of the display-face hero title,
//                                   FilterChip labels, and PlaceRow text at the largest a11y category.
//
// PlaceDetailView and AddPlaceSheet screen-level L3 are DEFERRED (decisions.md 2026-06-06):
//   PlaceDetailView uses ScreenScaffold(.custom) + an .ignoresSafeArea full-bleed hero; the iOS-26
//   glass safeAreaInset path mis-sizes in the offscreen host, producing blank frames.
//   AddPlaceSheet content renders blank when hosted without a real sheet presentation context.
//   Committing blank baselines is false confidence (the 2026-06-03 onboarding-gate ruling applies).
//   Both screens are covered by L1 (PlaceDetailPresenterTests / AddPlacePresenterTests), L4
//   (SavedFlowUITests), and their already-locked component snapshots (ProvenanceCard, PlaceInfoGrid,
//   MapSnippet, WayToSaveRow). Restore screen-level L3 once assertDesignSnapshot is rewritten to
//   the drawHierarchy/key-window path where glass renders (decisions.md 2026-06-06).
//
// Determinism (07-testing §6.4):
//   · Live clock — SampleData.savedSimulatedNow is the pinned seed; no Date() anywhere.
//   · Animation — snapshots are at rest; no withAnimation in any body.
//   · One-shot entrance motion — designSystemEnvironment() injects .disablesOneShotMotion = true.
//   · Random data — only SampleData.savedPlacesDTO() / emptySavedPlacesDTO().
//   · Font fallback — designSystemEnvironment() registers embedded fonts.
//   · Expanded-source key mirrors the SavedListView #Preview comment exactly.
//
// Baselines land in __Snapshots__/SavedScreenSnapshotTests/ alongside this file.
// Committed PNGs are the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

// MARK: - SavedListView snapshots

@Suite("SavedListView screen snapshots")
struct SavedListScreenSnapshotTests {

    // MARK: - Shared seeded stores
    //
    // @MainActor static vars: AppStore.preview(savedPlaces:) + SampleData builders are
    // MainActor-isolated (Swift 6.2 MainActor-by-default module), so stored fixtures must be
    // actor-isolated. All consumer test methods are @MainActor so access is safe. (§6.6)

    @MainActor static var populatedStore: AppStore {
        AppStore.preview(savedPlaces: SampleData.savedPlacesDTO())
    }

    @MainActor static var emptyStore: AppStore {
        AppStore.preview(savedPlaces: SampleData.emptySavedPlacesDTO())
    }

    // MARK: - saved-list-by-category

    /// SavedListView in By-category mode, populated store (the production default state).
    /// Renders: hero header (eyebrow / title / sub counts), SearchWell, SegmentedSelector (By category
    /// selected), FilterChip row, and grouped PlaceRow content sorted by category.
    /// Confirms all five chrome and content zones co-occur in a single frame.
    @Test("saved-list-by-category — populated list, by-category mode: hero + chips + grouped rows")
    @MainActor func savedListByCategory() {
        assertDesignSnapshot(
            NavigationStack {
                SavedListView(mode: .byCategory)
            }
            .environment(Self.populatedStore),
            named: "saved-list-by-category"
        )
    }

    // MARK: - saved-list-by-source

    /// SavedListView in By-source mode, one SourceCard pre-expanded (the first reel source),
    /// mirroring the #Preview. The expanded key "reel:saltinmycoffee:Lisbon in 48 hours" matches
    /// SavedListPresenter.sourceKey for SampleData's first reel place.
    /// Renders: SegmentedSelector (By source selected), collapsed + expanded SourceCards, child
    /// SourcePlaceRows visible inside the expanded card — all co-occurring on one frame.
    @Test("saved-list-by-source — by-source mode, first reel card expanded: SourceCards + child rows visible")
    @MainActor func savedListBySource() {
        assertDesignSnapshot(
            NavigationStack {
                SavedListView(
                    mode: .bySource,
                    expandedSources: ["reel:saltinmycoffee:Lisbon in 48 hours"]
                )
            }
            .environment(Self.populatedStore),
            named: "saved-list-by-source"
        )
    }

    // MARK: - saved-list-search

    /// SavedListView in search-active state (query: "rooftop"), populated store.
    /// Renders: SearchWell with a query, fuzzy-matched PlaceRow results (with trailing CategoryChips),
    /// the AIVoice "matching by vibe" line, and the search group header.
    /// Confirms the search-mode layout with results replaces the category/source segmented view.
    @Test("saved-list-search — search-active: SearchWell query + fuzzy PlaceRows + AIVoice line")
    @MainActor func savedListSearch() {
        assertDesignSnapshot(
            NavigationStack {
                SavedListView(query: "rooftop")
            }
            .environment(Self.populatedStore),
            named: "saved-list-search"
        )
    }

    // MARK: - saved-list-empty

    /// SavedListView with zero places (emptySavedPlacesDTO). Renders the rich empty state from
    /// saved-empty.html: three WayToSaveRow method rows instead of grouped content, with the
    /// "Save your first place" hero + subtitle.
    /// Confirms the empty-state layout replaces ALL content zones when savedPlaces is empty.
    @Test("saved-list-empty — zero places: rich WayToSaveRow empty state, no grouped content")
    @MainActor func savedListEmpty() {
        assertDesignSnapshot(
            NavigationStack {
                SavedListView()
            }
            .environment(Self.emptyStore),
            named: "saved-list-empty"
        )
    }

    // MARK: - saved-list-by-category-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as saved-list-by-category at
    /// .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the display-face hero
    /// title, FilterChip labels, PlaceRow name/meta text, and @ScaledMetric category dot at the
    /// largest accessibility size category. Glass-bearing screen — content zones should scale
    /// correctly regardless of glass chrome render fidelity.
    @Test("saved-list-by-category-ax5 — AX5: hero title + chips + row text scale at accessibilityXXXL")
    @MainActor func savedListByCategoryAX5() {
        assertDesignSnapshot(
            NavigationStack {
                SavedListView(mode: .byCategory)
            }
            .environment(Self.populatedStore)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "saved-list-by-category-ax5"
        )
    }
}
