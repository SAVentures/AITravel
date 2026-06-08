import Foundation

// MARK: - AppTab

/*
 The four root tabs in the app's tab bar. Leaf value type (02-models.md §1.2) — `nonisolated` and
 `Sendable` so it crosses actor boundaries freely. Drives `AppStore.selectedTab` and the per-tab
 `NavigationPath` switch in `AppStore+Navigation.swift`. `home` is the default landing tab;
 the others are placeholders (their features are separate stories).

 SwiftUI-free: `systemImage` is a raw SF Symbol name (a string), not an `Image`, so the model stays
 free of any UI framework. The view builds the label from `title` + `systemImage`.
*/
nonisolated enum AppTab: String, CaseIterable, Sendable {
    case saved
    case wallet
    case home
    case you

    /// The tab bar label.
    var title: String {
        switch self {
        case .saved:  return "Saved"
        case .wallet: return "Wallet"
        case .home:   return "Home"
        case .you:    return "You"
        }
    }

    /// SF Symbol name for the tab bar glyph (a string — the model stays SwiftUI-free).
    var systemImage: String {
        switch self {
        case .saved:  return "bookmark"
        case .wallet: return "wallet.pass"
        case .home:   return "house"
        case .you:    return "person.crop.circle"
        }
    }

    /// Dot-namespaced accessibility identifier for the tab button (06-screens.md §10).
    var accessibilityID: String {
        switch self {
        case .saved:  return "tab.saved"
        case .wallet: return "tab.wallet"
        case .home:   return "tab.home"
        case .you:    return "tab.you"
        }
    }
}
