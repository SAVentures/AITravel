import SwiftUI

/// Placeholder root. The real tab IA + `AppStore` injection + per-tab `NavigationStack`s
/// are built through the pipeline (Phase 1+); this stub only exists so the freshly
/// scaffolded project builds green. See ios/docs/engineering/01-architecture.md §4.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "AppTemplate",
            systemImage: "books.vertical",
            description: Text("Scaffold ready — screens arrive through the pipeline.")
        )
    }
}

#Preview {
    RootView()
}
