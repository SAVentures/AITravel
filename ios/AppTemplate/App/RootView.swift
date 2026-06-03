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
    @State private var showsOnboarding = false

    var body: some View {
        placeholderRoot
            // Kick the flow on launch — only when no draft is present (so a re-appearance / a seeded
            // preview does not re-fetch). The read path lives on the store (`06-screens.md §4`).
            .task {
                if store.onboarding == nil {
                    await store.loadOnboarding()
                }
            }
            // The onboarding takeover. Driven by a local `@State` Bool that mirrors the presence of a
            // draft. `of:` is evaluated *during* body, so SwiftUI registers `store.onboarding` as a
            // dependency of this body and re-renders when hydration sets it (`06-screens.md §2.5` — a
            // cover for a focused takeover).
            .onChange(of: store.onboarding != nil, initial: true) { _, present in
                showsOnboarding = present
            }
            .fullScreenCover(isPresented: $showsOnboarding) {
                OnboardingFlowView()
            }
            // SwiftUI drives `showsOnboarding` false on an interactive/swipe dismiss; mirror it to the
            // store so the source of truth stays in sync (the flow's own × / completion also clear it).
            .onChange(of: showsOnboarding) { _, shows in
                if !shows && store.onboarding != nil {
                    store.cancelOnboarding()
                }
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
