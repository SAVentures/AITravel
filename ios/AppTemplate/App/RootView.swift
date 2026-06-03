import SwiftUI

/*
 The app root. Hosts a placeholder production root behind the onboarding takeover: on launch it kicks
 onboarding hydration, then presents OnboardingFlowView as a .fullScreenCover driven by the presence of
 store.onboarding. When the flow clears the draft (completion or cancel), the cover dismisses to the
 placeholder. The real tab IA replaces the placeholder later.
*/
struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showsOnboarding = false

    var body: some View {
        placeholderRoot
            // Hydrate only when no draft is present, so a re-appearance / seeded preview does not re-fetch.
            .task {
                if store.onboarding == nil {
                    await store.loadOnboarding()
                }
            }
            // `of:` is evaluated during body, so SwiftUI registers store.onboarding as a body dependency
            // and re-renders the cover when hydration sets it.
            .onChange(of: store.onboarding != nil, initial: true) { _, present in
                showsOnboarding = present
            }
            .fullScreenCover(isPresented: $showsOnboarding) {
                OnboardingFlowView()
            }
            // SwiftUI drives showsOnboarding false on an interactive/swipe dismiss; mirror it back to the
            // store so the source of truth stays in sync (the flow's own × / completion also clear it).
            .onChange(of: showsOnboarding) { _, shows in
                if !shows && store.onboarding != nil {
                    store.cancelOnboarding()
                }
            }
    }

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
