import Foundation

// MARK: - AppTab

/*
 The four root tabs in the app's tab bar. Leaf value type (02-models.md §1.2) — `nonisolated` and
 `Sendable` so it crosses actor boundaries freely. Drives `AppStore.selectedTab` and the per-tab
 `NavigationPath` switch in `AppStore+Navigation.swift`. `saved` is the only tab built this milestone;
 the others are placeholders (their features are separate stories).

 SwiftUI-free: `systemImage` is a raw SF Symbol name (a string), not an `Image`, so the model stays
 free of any UI framework. The view builds the label from `title` + `systemImage`.
*/
nonisolated enum AppTab: String, CaseIterable, Sendable {
    case trip
    case map
    case saved
    case you

    /// The tab bar label.
    var title: String {
        switch self {
        case .trip:  return "Trip"
        case .map:   return "Map"
        case .saved: return "Saved"
        case .you:   return "You"
        }
    }

    /// SF Symbol name for the tab bar glyph (a string — the model stays SwiftUI-free).
    var systemImage: String {
        switch self {
        case .trip:  return "suitcase"
        case .map:   return "map"
        case .saved: return "bookmark"
        case .you:   return "person.crop.circle"
        }
    }

    /// Dot-namespaced accessibility identifier for the tab button (06-screens.md §10).
    var accessibilityID: String {
        switch self {
        case .trip:  return "tab.trip"
        case .map:   return "tab.map"
        case .saved: return "tab.saved"
        case .you:   return "tab.you"
        }
    }
}
