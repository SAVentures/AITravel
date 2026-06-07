/*
 Route value for the Travel wallet. The wallet is a `.detail` screen pushed inside the Trip tab stack
 (the mockup topbar reads "‹ Trip"), not a tab of its own — so it carries no payload (06-screens §5).
 One Route per file, `Hashable`, registered with `.navigationDestination(for:)` at the Trip tab root
 (RootView, Task 3.0 / 3.1); pushed via `store.push(WalletRoute())` onto the Trip tab's path.
*/
import Foundation

struct WalletRoute: Hashable {}
