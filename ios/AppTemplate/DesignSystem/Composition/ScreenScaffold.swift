// ScreenScaffold.swift — the outermost COMPOSITION primitive: it owns a screen's chrome, scroll,
// safe-area, and standard inset so no screen ever hand-wires `.toolbar` / `.padding` / a `ScrollView`
// (05-design-system §9; 01-architecture §8.4; 03-layout-spacing §4; the iOS 26 scroll-edge effect).
//
// A screen declares *what kind of screen it is* via `ScreenChrome` and hands `ScreenScaffold` its content;
// the scaffold translates the intent to platform chrome and supplies the shared layout container. This is
// the anti-divergence seam (01-arch §8.4): the prior app's screens diverged because each laid out its own
// chrome and margins by hand.
//
// What the scaffold owns:
//   - A vertical `ScrollView` + the standard horizontal screen inset, applied through the layout guide via
//     `.contentMargins(.horizontal, Spacing.screenInset, for: .scrollContent)` — NEVER a hardcoded margin
//     (03 §4). The inset shifts scrollable content while the glass bars stay put.
//   - The `ScreenChrome` → platform-chrome mapping (title style, back affordance, tab-bar visibility,
//     sheet grabber) — see the table below and `ScreenChrome.swift`.
//   - The iOS 26 `scrollEdgeEffectStyle` so content scrolls UNDER the glass bars, and the removal of any
//     custom bar/scroll backgrounds (`.scrollContentBackground(.hidden)`, `.containerBackground(.clear,
//     for: .navigation)`) so the system glass shows through rather than a painted panel (05-components §7.1).
//   - A `ColorRole.surfacePage` page background. **No glass on the scaffold body itself** — glass lives only
//     on the bars and on the optional floating `actions` bar it hosts in the thumb zone (J-0.1).
//   - The optional floating `actions` slot (the `ActionBar`, B-COMP5) overlaid in the bottom thumb zone.
//     It is a generic `@ViewBuilder` defaulting to `EmptyView`, so the scaffold compiles and is useful
//     before `ActionBar` exists; a screen passes its `ActionBar` (or any chrome) here.
//
// Semantic tokens only — no literal margins/colors, no `Primitive.*` (J-0.2). Content drives height; the
// scaffold sets **no fixed frames** (J-0.3) — every text style scales with Dynamic Type.
//
// Chrome-intent → platform-chrome mapping (the contract the fidelity-reviewer checks; mirrors
// `ScreenChrome.swift`'s table):
//
//   .root(title)   → `.navigationTitle` + `.navigationBarTitleDisplayMode(.large)`; tab bar visible.
//   .detail(title) → inline title + automatic back; tab bar persists across the push.
//   .immersive     → `.toolbar(.hidden, for: .tabBar)` + a minimal/inline title; a deliberate takeover.
//   .custom        → no system header (the screen draws its own); tab bar untouched.
//   .sheet(title)  → `.presentationDragIndicator(.visible)` (the grabber) + no nav bar; an optional inline
//                     title. A sheet is solid at rest — only the grabber is glass (05-components §6.1).
//
// Note on tab-bar modifiers: `.toolbar(.hidden, for: .tabBar)` is a NO-OP outside a `TabView`. At this
// (foundation) phase there is no `TabView`/`NavigationStack`/`RootView` wiring — those land in the screen
// phase — so the scaffold is previewed standalone inside a `NavigationStack` and the tab-bar intent only
// becomes live once a screen hosts it in a tab. The scaffold still declares the intent now so screens
// inherit it for free.
import SwiftUI

/// The outermost composition primitive every screen composes: it maps a `ScreenChrome` intent to platform
/// chrome and owns the scroll container, safe-area, standard horizontal inset, scroll-edge glass effect,
/// page background, and an optional floating actions bar.
///
/// Generic over its scrolling `Content` and over the floating `Actions` slot (the `ActionBar`, supplied by
/// a screen). `Actions` defaults to `EmptyView` so the scaffold is complete and previewable before the
/// `ActionBar` primitive exists.
///
/// ```swift
/// ScreenScaffold(.root(title: "Library")) {
///     ScreenSection("Due this week") { /* rows */ }
/// }
/// ```
///
/// Semantic tokens only; no fixed frames; no glass on the body (glass is reserved for the bars and the
/// floating `actions` slot — J-0.1). See `05-design-system §9` and `01-architecture §8.4`.
struct ScreenScaffold<Content: View, Actions: View>: View {
    private let chrome: ScreenChrome
    private let background: Color
    private let content: Content
    private let actions: Actions

    /// - Parameters:
    ///   - chrome: the screen's chrome intent, mapped to platform chrome (`ScreenChrome.swift`).
    ///   - background: the page tone behind the scaffold body. Defaults to `ColorRole.surfacePage` (the
    ///     grey ground); an immersive screen can opt into a different semantic tone (e.g.
    ///     `ColorRole.surfaceGrouped` for a white ground). Semantic tokens only — never a literal.
    ///   - actions: an optional floating chrome slot (e.g. the `ActionBar`) overlaid in the bottom thumb
    ///     zone. Defaults to `EmptyView` so the scaffold compiles without an `ActionBar`.
    ///   - content: the scrollable screen content; it drives height and is inset by `Spacing.screenInset`.
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
        // The standard compact horizontal screen margin, via the layout guide — never a literal (03 §4).
        .contentMargins(.horizontal, Spacing.screenInset, for: .scrollContent)
        // Content scrolls UNDER the glass bars; the system draws the soft scroll-edge effect, not us.
        .scrollEdgeEffectStyle(.soft, for: .all)
        // Don't paint our own scroll/nav backgrounds — let the system glass and our page tone show through.
        .scrollContentBackground(.hidden)
        // The page tone sits behind everything; the scaffold body itself is never glass (J-0.1).
        .background(background)
        .modifier(ScreenChromeModifier(chrome: chrome))
        // The optional floating actions bar (the `ActionBar`) rides the bottom thumb zone over the content;
        // the bar owns its own thumb-zone padding, so no extra spacing token is introduced here.
        .safeAreaInset(edge: .bottom) { actions }
    }
}

/// Maps a `ScreenChrome` intent onto SwiftUI's platform chrome. Kept as a private `ViewModifier` so the
/// `switch` over intents reads in one place and the scaffold body stays declarative.
private struct ScreenChromeModifier: ViewModifier {
    let chrome: ScreenChrome

    func body(content: Content) -> some View {
        switch chrome {
        case let .root(title):
            // A tab's home: large navigation title, no back, tab bar visible.
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)

        case let .detail(title):
            // A pushed detail: inline title + automatic back; the tab bar persists across the push.
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)

        case .immersive:
            // A takeover (reader/capture/onboarding): minimal inline title, tab bar hidden.
            // `.toolbar(.hidden, for: .tabBar)` is a no-op until a `TabView` hosts this (screen phase).
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)

        case .custom:
            // The screen draws its own header and supplies its own back — no system nav bar.
            content
                .toolbar(.hidden, for: .navigationBar)

        case let .sheet(title):
            // A presented sheet: the grabber is visible and there is no nav bar (solid at rest;
            // only the grabber is glass — 05-components §6.1). An optional inline title.
            content
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .presentationDragIndicator(.visible)
        }
    }
}

// The scaffold owns the macro-chrome only; vertical rhythm comes from `ScreenSection`/`RhythmSpacer`.
// Previewed standalone inside a `NavigationStack` (there is no `RootView`/`TabView` at the foundation
// phase). Two variants: a `.root` (large title) and a `.detail` (inline title + back).
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
