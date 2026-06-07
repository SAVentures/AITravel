import SwiftUI

/*
 The app root. Hosts the production tab IA — an iOS-26 floating-glass `TabView` over `AppTab`, one tab
 per case, each driving its own per-tab `NavigationStack` off the matching store path
 (`tripPath`/`mapPath`/`savedPath`/`youPath`). The app boots into `.saved` (the only built tab this
 milestone). Onboarding is a takeover layered above the tabs: a `.fullScreenCover` driven by the presence
 of `store.onboarding`; when the flow clears the draft (completion or cancel), the cover dismisses back to
 the tabs.

 Glass lives on the tab bar chrome only (the system material) — never on content (J-0.1). The Trip / Map
 / You tabs are placeholders this milestone (decision D-2); the Saved tab is a placeholder *temporarily*
 (Wave 3 swaps its root to `SavedListView` + registers `PlaceDetailRoute`).
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
        case .trip:
            // The Trip tab home (placeholder this milestone) + the wallet destinations registered once at
            // the root so every pushed WalletRoute / BookingDetailRoute inherits them (06-screens §5). The
            // wallet is a `.detail` pushed inside the Trip stack (mockup back reads "‹ Trip"), not a tab.
            NavigationStack(path: $store.tripPath) {
                tripHome(tab)
                    .navigationDestination(for: WalletRoute.self) { _ in
                        WalletView()
                    }
                    .navigationDestination(for: BookingDetailRoute.self) { route in
                        BookingDetailView(bookingID: route.id)
                    }
            }
        case .map:
            NavigationStack(path: $store.mapPath) {
                comingSoon(tab)
            }
        case .saved:
            // The Saved tab home (Wave 3) + the place-detail destination registered once at the root so
            // every pushed `PlaceDetailRoute` inherits it (06-screens §5).
            NavigationStack(path: $store.savedPath) {
                SavedListView()
                    .navigationDestination(for: PlaceDetailRoute.self) { route in
                        PlaceDetailView(placeID: route.id)
                    }
            }
        case .you:
            NavigationStack(path: $store.youPath) {
                comingSoon(tab)
            }
        }
    }

    // The Trip tab home this milestone (OD-1): the coming-soon placeholder is kept (no fabricated Trip
    // home), augmented with the single wired entry that makes the Travel wallet reachable + L4-testable.
    // Tapping it pushes WalletRoute onto the active (Trip) tab's path via the store nav seam — mirroring
    // how the Saved tab pushes PlaceDetailRoute. Content surface — never glass (J-0.1).
    private func tripHome(_ tab: AppTab) -> some View {
        comingSoon(tab)
            .safeAreaInset(edge: .bottom) {
                Button {
                    store.push(WalletRoute())
                } label: {
                    Label("Travel wallet", systemImage: "wallet.pass")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.actionPrimary)
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.xl)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("trip.openWallet")
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
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
