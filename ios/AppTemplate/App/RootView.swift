import SwiftUI

/*
 The app root. Hosts the production tab IA — an iOS-26 floating-glass `TabView` over `AppTab`, one tab
 per case, each driving its own per-tab `NavigationStack` off the matching store path
 (`savedPath`/`walletPath`/`homePath`/`youPath`). Onboarding is a takeover layered above the tabs: a
 `.fullScreenCover` driven by the presence of `store.onboarding`; when the flow clears the draft
 (completion or cancel), the cover dismisses back to the tabs.

 Glass lives on the tab bar chrome only (the system material) — never on content (J-0.1). The Saved and
 Wallet tabs are real (`SavedListView` / `WalletView` roots, registering `PlaceDetailRoute` /
 `BookingDetailRoute`); Home and You are placeholders this milestone (decision D-2).
*/
struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showsOnboarding = false
    @State private var didAutoLoad = false

    var body: some View {
        @Bindable var store = store

        TabView(selection: $store.selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    stack(for: tab)
                }
                .accessibilityIdentifier(tab.accessibilityID)
            }
        }
        // iOS-26 floating glass tab bar: minimizes (not hides) as content scrolls down.
        .tabBarMinimizeBehavior(.onScrollDown)
        // The live app starts onboarding from a CTA inside the tabs (not auto-launch): auto-hydrating on
        // appear would re-fire when the cover dismissed on completion/cancel, bouncing the user back to
        // step 1. UI tests still need the launch-env start-step path, so auto-load only under test, once.
        .task {
            guard !didAutoLoad else { return }
            didAutoLoad = true
            if isUITestLaunch, store.onboarding == nil {
                await store.loadOnboarding()
            }
        }
        // `of:` is evaluated during body, so SwiftUI registers store.onboarding as a body dependency and
        // re-renders the cover when the trigger (or the test path) sets it.
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

    // Each tab hosts its own NavigationStack bound to the matching store path, so pushes route through the
    // active tab's path (never a view-local one) and the tab bar persists across pushes (06-screens §2.2).
    @ViewBuilder
    private func stack(for tab: AppTab) -> some View {
        @Bindable var store = store

        switch tab {
        case .saved:
            // The Saved tab home + the place-detail destination registered once at the root so every
            // pushed `PlaceDetailRoute` inherits it (06-screens §5).
            NavigationStack(path: $store.savedPath) {
                SavedListView()
                    .navigationDestination(for: PlaceDetailRoute.self) { route in
                        PlaceDetailView(placeID: route.id)
                    }
            }
        case .wallet:
            // The Wallet tab root (now a real top-level tab, not pushed inside Trip) + the booking-detail
            // destination registered once at the root so every pushed `BookingDetailRoute` inherits it
            // (06-screens §5).
            NavigationStack(path: $store.walletPath) {
                WalletView()
                    .navigationDestination(for: BookingDetailRoute.self) { route in
                        BookingDetailView(bookingID: route.id)
                    }
            }
        case .home:
            NavigationStack(path: $store.homePath) {
                comingSoon(tab)
            }
        case .you:
            NavigationStack(path: $store.youPath) {
                comingSoon(tab)
            }
        }
    }

    // Placeholder root for a not-yet-built tab. Content surface — never glass (J-0.1).
    private func comingSoon(_ tab: AppTab) -> some View {
        ContentUnavailableView(
            tab.title,
            systemImage: tab.systemImage,
            description: Text("Coming soon")
        )
        .accessibilityIdentifier("tab.\(tab.rawValue).comingSoon")
        .scrollDisabled(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorRole.surfaceGrouped)
    }

    // UI tests inject a launch scenario / start step; the live app does not, so it lands on the tabs.
    private var isUITestLaunch: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["UITEST_START_STEP"] != nil || env["UITEST_SCENARIO"] != nil
    }
}

#Preview {
    RootView()
        .environment(AppStore.preview(SampleData.onboardingAContext()))
}
