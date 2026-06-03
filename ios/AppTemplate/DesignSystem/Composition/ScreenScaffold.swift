/*
 The outermost composition primitive: it owns a screen's chrome, scroll, safe-area, and standard inset
 so no screen hand-wires `.toolbar` / `.padding` / a `ScrollView`. A screen declares its intent via
 `ScreenChrome`; the scaffold maps that to platform chrome and supplies the shared layout container.
 This is the anti-divergence seam (01-arch §8.4) — the prior app's screens drifted because each laid
 out its own chrome and margins by hand.

 Gotcha: `.toolbar(.hidden, for: .tabBar)` is a no-op until a `TabView` hosts the scaffold (screen
 phase). It's declared now anyway so screens inherit the intent for free; previewed standalone in a
 `NavigationStack`.
*/
import SwiftUI

/// The composition primitive every screen composes. `Actions` defaults to `EmptyView` so the scaffold is
/// complete and previewable before the `ActionBar` primitive exists. No glass on the body — glass is
/// reserved for the bars and the floating `actions` slot (J-0.1).
struct ScreenScaffold<Content: View, Actions: View>: View {
    private let chrome: ScreenChrome
    private let background: Color
    private let content: Content
    private let actions: Actions

    init(
        _ chrome: ScreenChrome,
        background: Color = ColorRole.surfacePage,
        @ViewBuilder actions: () -> Actions = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.chrome = chrome
        self.background = background
        self.actions = actions()
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.horizontal, Spacing.screenInset, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .scrollContentBackground(.hidden)
        .background(background)
        .modifier(ScreenChromeModifier(chrome: chrome))
        // The bar owns its own thumb-zone padding, so no extra spacing token is introduced here.
        .safeAreaInset(edge: .bottom) { actions }
    }
}

/// Maps a `ScreenChrome` intent onto SwiftUI's platform chrome, kept as a private `ViewModifier` so the
/// `switch` reads in one place and the scaffold body stays declarative.
private struct ScreenChromeModifier: ViewModifier {
    let chrome: ScreenChrome

    func body(content: Content) -> some View {
        switch chrome {
        case let .root(title):
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)

        case let .detail(title):
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)

        case .immersive:
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)

        case .custom:
            // The screen draws its own header and back — no system nav bar.
            content
                .toolbar(.hidden, for: .navigationBar)

        case let .sheet(title):
            // Solid at rest; only the grabber is glass (05-components §6.1).
            content
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .presentationDragIndicator(.visible)
        }
    }
}

// Previewed standalone inside a `NavigationStack` (no `RootView`/`TabView` at the foundation phase).
#Preview("root") {
    NavigationStack {
        ScreenScaffold(.root(title: "Library")) {
            ScreenSection("Due this week") {
                Text("The Left Hand of Darkness")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textPrimary)
                Text("A Wizard of Earthsea")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textPrimary)
                Text("The Dispossessed")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textPrimary)
            }
        }
    }
}

#Preview("detail") {
    NavigationStack {
        ScreenScaffold(.detail(title: "A Wizard of Earthsea")) {
            ScreenSection {
                Text("Ursula K. Le Guin")
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Text("A boy with a great gift for magic is sent to study at a school of wizardry.")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textSecondary)
            }
        }
    }
}
