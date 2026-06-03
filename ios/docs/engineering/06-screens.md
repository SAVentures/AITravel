# 06 — Screens: Structure & Wiring

How screens are composed, wired to navigation, connected to state, verified against their mockup, and
made testable. It is the recipe-level companion to `01-architecture.md §8` (which gives the shape).
It does **not** specify appearance — tokens, typography, spacing, color roles, the glass/▢ rules are
owned by `docs/design-docs/` and the design-system port (`05-design-system.md`). This doc owns
structure; `design-docs/` owns look. The running example is the library / book slice.

> **The screen layer is where the prior app's quality actually broke.** Screens drifted from the
> mockups and diverged from each other because each was hand-laid-out and tangled logic into `body`.
> Two mechanisms in this doc prevent that: **composition primitives** every screen must compose (§2,
> consistency) and the **fidelity gate** every screen passes before it's accepted (§9, mockup match).

---

## 1. View composition

Every screen is a `struct … : View` named `…View`. A `body` is **layout + wiring only** — derivation
goes to a presenter (§3), mutations to model methods / store commands (§4), and design values to the
design system. Break a large `body` into **private `@ViewBuilder` properties or `private struct`
subviews in the same file**; nothing leaks to callers. Promote a subview to `DesignSystem/Components/`
only once a second screen needs it.

```swift
struct BookDetailView: View {
    @Environment(AppStore.self) private var store
    let bookID: BookModel.ID

    var body: some View {
        let p = BookDetailPresenter(store: store, bookID: bookID)
        ScreenScaffold(.detail(title: p.title)) {        // pushed screen → inline title + back (§2)
            cover(p)             // private @ViewBuilder subviews
            metadata(p)
            borrowControls(p)
        }
    }
    @ViewBuilder private func cover(_ p: BookDetailPresenter) -> some View { … }
}
```

---

## 2. The UI shell — chrome & composition

The shell is the persistent chrome around screen content. Four layers, each with one owner — screens
*declare* their shell, they don't hand-wire it:

| Layer | What | Owner | When it shows |
|---|---|---|---|
| **Tab bar** (bottom) | top-level switcher (LibraryModel · You) | `RootView` — not screens | always at tab roots; **persists into pushes**; hidden only on immersive screens |
| **Top bar** (nav bar) | title · back **only** | the `NavigationStack`, via `ScreenScaffold` | **large title at roots; inline + back on pushed screens** |
| **Action bar** (thumb zone) | the screen's primary action(s) | the screen, via `ScreenScaffold(actions:)` | when a screen has a primary CTA; floats above the tab bar |
| **Overlays** (sheet / cover) | a transient modal task | the presenting view (`@State`) | a side task or a takeover; **covers all bars** |

Glass is for these floating chrome layers only — never on content (a design non-negotiable; see
`docs/design-docs/`).

> **Primary actions live in the thumb zone, never the top bar.** The top-bar criticism is a
> *reachability* one — Cancel/Done/Filter buttons sit out of thumb reach on large phones, and iOS 26
> itself moved search and primary actions to the bottom. So the top bar carries only the title and back
> (low-frequency, learned targets; swipe-back covers reachability); every primary CTA goes in the
> bottom `ActionBar`. At most a *secondary/overflow* control may sit top-right.

### 2.1 `ScreenScaffold` — the one chrome + layout primitive

Every screen composes `ScreenScaffold` instead of hand-wiring `.toolbar` / `.navigationTitle` /
`.padding` / `ScrollView`. It declares the screen's **chrome intent** and lays out the content:

```swift
enum ScreenChrome {
    case root(title: String)       // tab root → large-title nav bar (collapses on scroll)
    case detail(title: String)     // pushed   → inline title + automatic back chevron
    case immersive(title: String)  // takeover → inline title + tab bar HIDDEN
    case custom                    // screen draws its own header; nav bar hidden (rare — must supply back)
}

ScreenScaffold(.detail(title: book.title), actions: {
    ActionBar { PillButton("Borrow") { Task { await store.borrow(bookID: id) } } }
}) {
    ScreenSection { /* content */ }
}
```

`ScreenScaffold` maps the chrome intent → platform chrome so screens never touch it directly:
`.root` → `.navigationTitle(_:) + .navigationBarTitleDisplayMode(.large)`; `.detail` → inline title
(+ automatic back); `.immersive` → inline title + `.toolbar(.hidden, for: .tabBar)`; `.custom` →
`.toolbar(.hidden)` (you render and own the header + back). The optional `actions:` slot renders an
`ActionBar` pinned in the thumb zone. `ScreenScaffold` also owns the safe-area, the `ScrollView`, the
standard inset, and the iOS 26 **scroll-edge effect** under the glass bars
(`.scrollEdgeEffectStyle(.soft, for: .all)`) so content fades correctly beneath them — and composes the
layout primitives:

| Primitive | Role |
|---|---|
| `ScreenSection(header:) { … }` | a grouped block with the standard inter-section rhythm |
| `RhythmSpacer(.section / .item)` | the canonical vertical gaps (token-backed; never a literal `Spacer`/`.padding(17)`) |
| `ActionBar { … }` | the bottom thumb-zone bar holding a screen's primary CTA(s); glass, floats above the tab bar |

### 2.2 Tab bar — show / hide

Owned by `RootView` (the value-type `Tab` `TabView`; iOS 26 floating glass). Rules:
- **Visible at every tab root**, and **persists across pushes within a tab** — top-level switching
  stays one tap away (the platform default).
- **Hidden only on `.immersive` / `.custom` screens** (reader, capture, onboarding, a blocking flow)
  via `.toolbar(.hidden, for: .tabBar)` — an explicit, deliberate opt-out, never a per-detail default.
- Always **covered** by a sheet / full-screen cover (modal context).
- The floating bar **minimizes on scroll** via `.tabBarMinimizeBehavior(.onScrollDown)` — a system
  affordance, distinct from hiding.
- **Search, if present, is a `.search`-role `Tab`** (iOS 26): it sits visually separate and morphs into
  a bottom search field when selected — the platform's bottom-reachable search pattern. Prefer this
  over a top `.searchable` for a tab app.
- A **persistent, app-global** control (e.g. a now-playing strip, a global search field) uses the
  system **`tabViewBottomAccessory { … }`** (with `TabViewBottomAccessoryPlacement`), which docks above
  the tab bar and is owned by `RootView`. (A *per-screen* CTA is the scaffold's `ActionBar`, §2.4 — not
  this.)

### 2.3 Top bar — title + back only

The top bar carries **only the title and back** — never a primary action (those go in the `ActionBar`,
§2.4). This is the reachability fix: large phones put top-right buttons out of thumb reach, and iOS 26
moved actions to the bottom.

- **Pushed screen → `.detail`:** inline title + automatic back chevron. Always — you need back.
- **Tab root → `.root`:** system large title, collapses to inline on scroll. Native, glass, free
  Dynamic Type, accessible. (The large *title* is fine and recommended for roots; only top-bar
  *actions* are the anti-pattern.)
- **At most one secondary/overflow control** may sit top-right (e.g. a `•••` menu) — never the primary
  CTA.
- **Hide the nav bar (`.custom`) only** when a screen renders its own hero header — rare, and it must
  then supply its own back if pushed. (The prior app's per-screen "no top bar" special-casing is
  exactly the inconsistency the single `.root`/`.custom` intent replaces.)

### 2.4 Action bar — the thumb zone

A screen's primary action(s) live in the bottom `ActionBar` (glass, floats above the tab bar), supplied
via `ScreenScaffold(actions:)`. This is where the reachable CTA goes — `Borrow`, `Return`, `Save`. Keep
it to one primary (optionally one secondary) action; more than that is a sign the screen is doing too
much. The `ActionBar` sits above the tab bar at a tab root, or alone on a `.detail`/`.immersive` screen.

`ActionBar` vs `tabViewBottomAccessory`: the **`ActionBar` is per-screen** (this screen's CTA, scoped to
the scaffold and gone when you leave). The system **`tabViewBottomAccessory` is app-global** (persists
across tabs — a now-playing strip, a global search). Same thumb zone, different lifetime; pick by scope.

The `ActionBar`'s glass and its buttons use the **system Liquid Glass material** — `.buttonStyle(.glass)`
/ `.glassProminent` on the CTA, grouped in a `GlassEffectContainer` — never a hand-rolled glass recipe
(the design-system port wraps this; `05-design-system.md`). Glass on floating chrome only, never on
content (`docs/design-docs/`).

### 2.5 Sheet vs. push vs. cover — the decision rule

| Use | When | Mechanics |
|---|---|---|
| **Push** | a *child of what you're viewing* (list → detail) — hierarchical, stays in the tab | `store.push(Route)` (§5) |
| **Sheet** | a *self-contained side task you finish and dismiss* (borrow confirm, edit, filter, picker, peek) — returns to origin | `.sheet(isPresented:)` on ephemeral `@State` (§6) |
| **Full-screen cover** | a *focused takeover* (onboarding, capture, blocking flow) — rare | `.fullScreenCover` (§6); usually `.immersive` chrome |

Heuristic: *"child of this?"* → push · *"detour I'll finish and leave?"* → sheet · *"needs to own the
screen?"* → cover.

### 2.6 The rule that prevents drift

**A screen never hand-wires chrome or top-level layout** — no raw `.toolbar` / `.navigationTitle` /
`.navigationBarHidden`, and no raw `.padding(_:)` / `VStack(spacing:)` / `ScrollView` for structure. It
declares `ScreenScaffold(<intent>)` and composes `ScreenSection` / `RhythmSpacer`, which carry the
tokens. That single seam is what makes two independently-built screens share one chrome and one rhythm
(the prior app diverged precisely because each wired its own). Inner, component-local spacing still
uses **semantic** tokens (`Spacing.itemGap`, never the primitive `Space.s2` or a literal — see
`05-design-system.md §1`).

---

## 3. Screen logic — presenters

Per Apple's Model-View stance (WWDC24): a `View` reads the `@Observable` store/models directly; there
is **no per-screen view-model**. Stateless *derivation* (resolving a model by id, mapping a domain
value to a component prop, computing an offset) goes into a **stateless `<Screen>Presenter`** value
type co-located with the screen:

```swift
// Screens/BookList/BookListPresenter.swift  — imports SwiftUI (returns view-side models)
struct BookListPresenter {
    let store: AppStore
    var title: String { "Library" }
    var rows: [BookRowModel] { (store.library?.books ?? []).map(BookRowModel.init) }
    var emptyStateMessage: String? { store.library?.books.isEmpty == true ? "No books yet" : nil }
}
```

Rules (full rationale in `01-architecture.md §8.3`):
1. **Returns data / view-models, never builds `View`s.** A derivation that produced a `Text` returns
   its parts; the view assembles the `Text`. This keeps it pure and unit-testable.
2. **Lives in `Screens/`, not `Models/`** — it legitimately imports SwiftUI/tokens, which is exactly
   why it can't move onto the reference model.
3. **Stateless, constructed in `body`** (`let p = BookListPresenter(store: store)`), preserving the
   store's dependency tracking and getting finer-grained for free as the models are `@Observable`.
4. **Tested as pure in → out** (`07-testing.md §4.3`): seed an `AppStore`, build the presenter, assert
   each derived value. Keep derivation cheap — it's rebuilt every `body` pass.

A screen with trivial derivation needs no presenter; add one the moment derivation appears in `body`.

---

## 4. Reading & mutating state

Every screen obtains the store via `@Environment` (injected once at the root, `03-store.md`); `private
struct` subviews in the same file declare it independently — the environment propagates:

```swift
@Environment(AppStore.self) private var store
// for two-way bindings to store properties:
@Bindable var store = store      // then bind $store.x
```

Mutations, by whether the network is involved:

| Action | Call | Owner |
|---|---|---|
| Networked write (persists, can fail) | `await store.borrow(bookID: id)` | a thin async store command (optimistic + rollback, `03-store.md §3`) |
| Pure local toggle (no network) | `book.toggleFavorite()` | a model method (`02-models.md §2`) |

**Ephemeral UI state only** lives in the view as `@State` (a sheet flag, a local search field, an
animation toggle). **No screen owns domain state** — it lives in `AppStore`. A view never instantiates
an `AppStore`, never references a concrete provider, and never hand-rolls layout.

---

## 5. Navigation

**Routes** are `Hashable` value types, one per file in `Screens/Routes/<Name>Route.swift`, carrying
only the ids the destination needs to look the model up:

```swift
struct BookDetailRoute: Hashable { let id: BookModel.ID }
```

**Views push** by appending to the active tab's `NavigationPath` (owned by `AppStore`, never a
view-local path) via the store convenience:

```swift
store.push(BookDetailRoute(id: row.id))   // appends to the selected tab's path
// back:
store.pop()                               // removeLast() on the active path
```

**Destinations** are registered once at the tab root so every pushed screen inherits them:

```swift
.navigationDestination(for: BookDetailRoute.self) { route in
    BookDetailView(bookID: route.id)
}
```

Why navigation lives on `AppStore`, and why one `Route` struct per file (vs a shared enum), is settled
in `01-architecture.md §8.5` (per-tab paths + deep-link/testability; per-file routes keep screens
parallel-scaffoldable).

### Adding a new screen
1. `<Name>View.swift` (+ a `<Name>Presenter.swift` if it derives anything) under `Screens/<Name>/`.
2. A `Hashable` `Route` in `Screens/Routes/<Name>Route.swift`, registered with
   `.navigationDestination(for:)` on the appropriate root.
3. A catalog entry in `Screens/Catalog/CatalogSection+<X>.swift` (§7).
4. A `#Preview` (§8) and accessibility identifiers (§10).
All are *new files* except a brand-new catalog section; this is what keeps screen-building
parallel-scaffoldable (`01-architecture.md §11`).

---

## 6. Sheets & overlays — mechanics

*When* to reach for a sheet vs. a push vs. a cover is the decision rule in §2.5; this is *how*.

A sheet is presented with `.sheet(isPresented:)` driven by **ephemeral `@State`** on the presenting
view; a takeover uses `.fullScreenCover(isPresented:)` (usually paired with `.immersive` chrome so the
tab bar hides). The presented content is a `…View` in `Screens/` that follows the same rules — presenter
for derivation, composes the primitives, components for content — and a task sheet carries a header with
**Cancel / Done** (or a grabber for a peek). Per the design rules, a modal/sheet **at rest is not
glass** (glass is floating-chrome-only — `docs/design-docs/08-overlays.md`); bottom-sheet detents live
there too. Errors are **never** a toast or an alert — they surface as the `writeError` banner the
screen reads off the store.

---

## 7. The catalog (`ScreenCatalogView`)

`ScreenCatalogView` is a **debug back-door** — not production IA — listing every screen wired with
seeded state so a reviewer (human or the fidelity-reviewer agent, §9) can reach any screen without
walking the production graph. Each feature registers its entries in
`Screens/Catalog/CatalogSection+<X>.swift`; only adding a brand-new section edits core
`ScreenCatalogView.swift` (the one serial edit). When you add a screen, add its catalog entry.

---

## 8. Previews — how a screen gets its mock data

Mock data is defined once, in `SampleData` (`02-models.md §5`). A `#Preview` consumes it through the
**`AppStore.preview(_:)`** factory (`03-store.md §4`) — a fresh, locally-constructed, seeded store (no
`.shared`), wrapped in a `NavigationStack` when the screen expects nav context. The preview *is* the
state the render snapshot locks, so they must match.

```swift
#Preview("BookList — standard") {
    NavigationStack { BookListView() }
        .environment(AppStore.preview())                            // SampleData.library() by default
}

#Preview("BookList — empty") {
    NavigationStack { BookListView() }
        .environment(AppStore.preview(SampleData.emptyLibrary()))   // an edge-state variant
}
```

- **Pick the state by choosing the seed factory** — `library()` / `emptyLibrary()` / `allBorrowed()`
  (`02-models.md §5`); add a variant when a screen has a state worth showing.
- **Ship one `#Preview` per interesting state** (standard, empty, all-borrowed, error) — each is
  reviewable and becomes a render-snapshot baseline (`07-testing.md §6`).
- A detail screen takes its id from the seed: `AppStore.preview()` then
  `BookDetailView(bookID: "book-dune")` (the literal ids are stable, `02-models.md §5`).
- Previews never hit the network — `preview(_:)` seeds the store directly. The *networked* path
  (`loadLibrary()` → `MockProvider` scenario) is what UI/E2E tests drive (`07-testing.md §7`).

---

## 9. Fidelity to the mockup — the authoring-time gate

This is where "build it right the first time" lives for screens. Visual fidelity is **not** verified by
a test (we removed the design-test ceremony, `07-testing.md`); it is verified **when the screen is
authored**, against its mockup, then *locked* by a snapshot.

- **Every screen names its mockup.** A screen's acceptance criteria ("done-when") cite the specific
  `mockups/screens/<name>.html` (and its committed screenshot) it ports. A screen with no named mockup
  is not done.
- **The `fidelity-reviewer` agent compares the rendered screen to that mockup** — structure, spacing
  rhythm, component choices, the design non-negotiables — and reports drift as findings, before the
  screen is accepted. (Paired with the `foundation-freeze` gate, which locks the design system *before*
  any screen is built, `05-design-system.md`.)
- **Then the snapshot locks it** (`07-testing.md §6`): once the screen matches, its render snapshot is
  the tripwire against later drift.

So the order is: foundation frozen → screen ported from its named mockup → fidelity-reviewed → snapshot
committed. Getting it right is front-loaded; the test only keeps it from un-building.

---

## 10. Accessibility identifiers (for testing)

State-bearing elements and every element a UI test must address carry a stable
`.accessibilityIdentifier`, dot-namespaced `component.slot[.id]`, lowercase. The **view owns
placement**; the test layer queries them (`07-testing.md §7`).

| Element | Identifier |
|---|---|
| Library / You tab buttons | `tab.library` · `tab.you` |
| A book row | `bookrow.<id>` |
| The borrowed badge on a row | `bookrow.borrowed.badge.<id>` |
| The favorite control | `bookrow.favorite.<id>` |
| The borrow / return button (detail) | `book.borrowButton` · `book.returnButton` |
| Empty-state message | `booklist.emptyState` |
| Write-error banner | `writeError.banner` |

Apply on the outermost `View` of the element; parameterize with the id for elements that repeat across
rows (`bookrow.borrowed.badge.\(book.id)`) and use the bare form when only presence is asserted.

```swift
BookRow(model: row).accessibilityIdentifier("bookrow.\(row.id)")
```

---

## See also

- `01-architecture.md` §8 — the screen layer's shape (this doc is the recipe)
- `02-models.md` · `03-store.md` — the models a screen reads, the commands it calls
- `05-design-system.md` — tokens, modifiers, components, the composition primitives, foundation-freeze
- `07-testing.md` §6–7 — render snapshots (the lock) and XCUITest (the identifiers above)
- `docs/design-docs/` — all appearance decisions; when structure and look conflict, fix code to match
