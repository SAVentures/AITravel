/*
 The tab-navigation seam: push/pop/popToRoot operate on the ACTIVE tab's NavigationPath, never a
 view-local path (03-store.md §2). Each tab owns exactly one path on the core store; a screen pushes a
 `Route` value through `push(_:)` and the active tab's `NavigationStack` presents it.

 This is the navigation substrate — no feature logic. Feature commands live in their own
 `AppStore+<Feature>.swift` extensions (the onboarding/saved seam idiom).
*/
import Foundation
import SwiftUI

extension AppStore {

    // MARK: - Navigation (operate on the active tab's path)

    /// Append a `Route` value to the active tab's path.
    func push(_ route: some Hashable) {
        mutateActivePath { $0.append(route) }
    }

    /// Drop the top of the active tab's path (no-op when already at root).
    func pop() {
        mutateActivePath { if !$0.isEmpty { $0.removeLast() } }
    }

    /// Clear the active tab's path back to its root.
    func popToRoot() {
        mutateActivePath { $0 = NavigationPath() }
    }

    // MARK: - Helper

    /// Apply a mutation to whichever tab's path is currently selected.
    private func mutateActivePath(_ change: (inout NavigationPath) -> Void) {
        switch selectedTab {
        case .saved:  change(&savedPath)
        case .wallet: change(&walletPath)
        case .home:   change(&homePath)
        case .you:    change(&youPath)
        }
    }
}
