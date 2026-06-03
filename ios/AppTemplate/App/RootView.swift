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
    @State private var didAutoLoad = false

    var body: some View {
        placeholderRoot
            // The live app starts onboarding from the button (not auto-launch): auto-hydrating on appear
            // re-fired when the cover dismissed on completion/cancel, bouncing the user back to step 1.
            // UI tests still need the launch-env start-step path, so auto-load only under test, exactly once.
            .overlay(alignment: .bottom) { startButton }
            .task {
                guard !didAutoLoad else { return }
                didAutoLoad = true
                if isUITestLaunch, store.onboarding == nil {
                    await store.loadOnboarding()
                }
            }
            // `of:` is evaluated during body, so SwiftUI registers store.onboarding as a body dependency
            // and re-renders the cover when the button (or the test path) sets it.
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

    // UI tests inject a launch scenario / start step; the live app does not, so it lands on the root.
    private var isUITestLaunch: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["UITEST_START_STEP"] != nil || env["UITEST_SCENARIO"] != nil
    }

    private var placeholderRoot: some View {
        ContentUnavailableView(
            "AppTemplate",
            systemImage: "books.vertical",
            description: Text("Scaffold ready — screens arrive through the pipeline.")
        )
    }

    // Floating glass CTA — the one accent on the root, used to start the onboarding takeover.
    private var startButton: some View {
        Button {
            Task { await store.loadOnboarding() }
        } label: {
            Label("Plan a trip", systemImage: "sparkles")
        }
        .buttonStyle(.glassProminent)
        .tint(ColorRole.actionPrimary)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .disabled(store.onboardingLoadState == .loading)
        .padding(.bottom, Spacing.xl)
        .accessibilityIdentifier("root.startOnboarding")
    }
}

#Preview {
    RootView()
        .environment(AppStore.preview(SampleData.onboardingAContext()))
}
