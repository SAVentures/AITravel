import SwiftUI

/// The app root. Reads the single injected `AppStore` (`AppTemplateApp` owns it — the App-root-owns-one
/// -store rule, `01-architecture.md §4`) and hosts the production root behind the onboarding takeover.
///
/// Until the real tab IA is built, the root is a placeholder (the dismiss target). On launch it kicks
/// the onboarding hydration, then presents `OnboardingFlowView` as a `.fullScreenCover` takeover driven
/// by `store.onboarding != nil` (`06-screens.md §2.5` — a cover for a focused takeover). When the flow
/// dismisses to root (`completeGeneration()` / `cancelOnboarding()` set `onboarding = nil`), the cover
/// dismisses back to this placeholder.
struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store

        placeholderRoot
            // Kick the flow on launch — only when no draft is present (so a re-appearance / a seeded
            // preview does not re-fetch). The read path lives on the store (`06-screens.md §4`).
            .task {
                if store.onboarding == nil {
                    await store.loadOnboarding()
                }
            }
            // The onboarding takeover. Bound to the presence of a draft: hydration presents it, the
            // dismiss-to-root commands clear it (`onboarding = nil`) and the cover dismisses.
            .fullScreenCover(
                isPresented: Binding(
                    get: { store.onboarding != nil },
                    set: { isPresented in
                        // SwiftUI drives this false on an interactive dismiss; mirror it to the store so
                        // the source of truth stays in sync (the flow's own × also clears it).
                        if !isPresented { store.cancelOnboarding() }
                    }
                )
            ) {
                OnboardingFlowView()
            }
    }

    /// The placeholder production root — the dismiss target for the onboarding cover. The real tab IA +
    /// per-tab `NavigationStack`s arrive through the pipeline.
    private var placeholderRoot: some View {
        ContentUnavailableView(
            "AppTemplate",
            systemImage: "books.vertical",
            description: Text("Scaffold ready — screens arrive through the pipeline.")
        )
    }
}

#Preview {
    RootView()
        .environment(AppStore.preview(SampleData.onboardingAContext()))
}
