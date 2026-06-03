# iOS Architecture

Single-target SwiftUI app (`AppTemplate` scheme, Xcode 26, **minimum iOS 26**, **Swift 6 language
mode**). This document describes the code as written — read it alongside the source before adding a
layer or file. It is domain-agnostic: the running example is a small **library / book-management**
slice (browse the library, open a book, borrow one). Swap `LibraryModel`/`BookModel` for your own entities when
you instantiate the template.

Visual language is specified in `docs/design-docs/`; this document does not restate visual rules.

> **Why this architecture exists.** It is distilled from a prior app whose architecture was sound but
> whose foundation was built too fast. Three corrections below are load-bearing — they are the reason
> a screen stays thin, testable, and faithful to its mockup, and they are not optional polish:
> (1) the **wire/domain DTO split** (§6), (2) **logic out of views** — models own mutations, stateless
> presenters own derivation (§8), and (3) **Swift 6 main-actor isolation from day one** (§9).

---

## 1. The mental model

State flows in one direction; mutations are explicit commands that loop back through the store.

```
        ┌─────────────── read path ───────────────┐
        │                                          ▼
   Network ──send(req)──▶ DTO ──toDomain()──▶ AppStore ──▶ Presenter ──▶ View
   (off-actor, Codable)   (value)   (on main)  (@Observable    (derives    (renders;
                                                reference       data, no    no logic)
                                                models)         View)
        ▲                                                                    │
        └────────────── write path: command ◀── user intent ────────────────┘
           AppStore.command(): snapshot → mutate model optimistically →
           send(req) → on failure restore(from: snapshot)
```

- **One way in:** the network hands the store *value* DTOs; the store maps them to `@MainActor`
  *reference* domain models exactly once, on the main actor.
- **One source of truth:** `AppStore` holds the whole domain graph; every screen reads it via the
  environment. No screen owns domain state.
- **Logic has a home that is not the view:** mutations are methods on the models; per-screen
  derivation is a stateless presenter; only ephemeral UI state lives in the view as `@State`.
- **Writes are optimistic and reversible:** a command snapshots, mutates the reference model in place
  (so only the affected row re-renders), sends the request, and rolls back from the snapshot on failure.

## 2. Core invariants (this doc's reading guide)

Each is elaborated in the section noted. Violations require a written entry in `docs/decisions.md`.

1. **`AppStore` is the single source of truth.** One `@Observable` store; no parallel stores. → §5
2. **Reference models for mutable list rows; value types for everything else; DTOs at the wire.** → §6
3. **Screens depend on `APIClient`, never a concrete provider.** Swap at the store boundary. → §7
4. **Logic out of views:** mutation = model method; derivation = stateless presenter; only ephemeral
   state is `@State`. No per-screen view-model. → §8
5. **Design values come only from tokens/modifiers; layout only from composition primitives.** → §8.3
6. **Swift 6 isolation:** UI + store + reference models are `@MainActor`; only value DTOs cross the
   API boundary. Zero concurrency diagnostics. → §9

## 3. Layer map

| Layer | Directory | Owns | Must NOT contain |
|---|---|---|---|
| **App** | `AppTemplate/App/` | `@main` entry, font registration, store injection, `RootView` (tabs + nav stacks) | Domain logic, networking |
| **Models** | `AppTemplate/Models/` | The domain graph: `@MainActor @Observable` **reference models** + leaf **value types** + `SampleData` | SwiftUI imports, `Codable` wire codec, UI state |
| **Store** | `AppTemplate/Store/` | `AppStore` — domain state, per-tab nav paths, load/error state, async command wrappers, cross-entity mirrors | Transport/parsing, view layout, per-entity mutations (those live on the models) |
| **Networking** | `AppTemplate/Networking/` | `APIClientProtocol`/`APIClient`, `MockProvider`/`LiveProvider`, request structs, `*DTO`s + mapping | Domain mutations, UI, observable state |
| **DesignSystem** | `AppTemplate/DesignSystem/` | `Tokens/`, `Modifiers/`, `Components/`, `Composition/` — screen-agnostic | `AppStore`/domain references except as opaque args; navigation |
| **Screens** | `AppTemplate/Screens/` | Full-screen `View`s, sheets, `Routes/`, per-screen `Presenter`s, `Catalog/` | Reusable components (→ DesignSystem), model definitions |
| **Tests** | `AppTemplateTests/`, `AppTemplateUITests/` | The four-layer pyramid (functional, integration, render snapshot, XCUITest) — see `07-testing.md` | App/production code |

### Where the iOS target sits in the template repo

```
ios-app-template/                   ← the standalone template repo
  CLAUDE.md  README.md              ← project rules + instantiation playbook
  .claude/                          ← agents/ · skills/ · commands/ · scripts/   (the workflow harness)
  docs/                             ← design-docs/ · 00–03 · decisions.md         (visual + system specs)
  mockups/                          ← foundations/ · components/ · screens/ · screenshots/   (visual source of truth)
  ios/                              ← THIS document's subject ↓
    AppTemplate.xcodeproj
    AppTemplate/                    ← app source (the seven layers)
    AppTemplateTests/               ← functional · integration · render snapshot
    AppTemplateUITests/             ← XCUITest vs MockProvider scenarios
    docs/engineering/               ← 00–07 (this file is 01; testing is the single doc 07)
```

### iOS target — full directory structure (reference slice)

```
ios/
  AppTemplate.xcodeproj/                    PBXFileSystemSynchronizedRootGroup (§11)

  AppTemplate/
    App/
      AppTemplateApp.swift                  @main · FontRegistry · .environment(store)
      RootView.swift                        TabView(value-type Tab) · NavigationStack per tab
      FontRegistry.swift                    registers embedded variable fonts at launch

    Store/
      AppStore.swift                        @MainActor @Observable · stored state · init(api:) · conveniences
      AppStore+Library.swift                feature command wrappers (optimistic borrow + rollback)
      LoadState.swift  WriteError.swift     transient store state (enum / error)

    Models/
      LibraryModel.swift                         @MainActor @Observable container reference model (holds [BookModel])
      BookModel.swift                            @MainActor @Observable row reference model (+ mutation methods)
      ReadingStatus.swift                   value enum (.unread | .reading | .read)
      Format.swift                          value enum with associated values (manual Codable)
      Author.swift  BookDetail.swift        leaf value types (Codable, Sendable)
      Genre.swift   Rating.swift            leaf value types (enum / struct)
      DateFormatters.swift                  AppDate — pinned tz/locale formatters
      SampleData/                           sample-data seed in its own dir
        SampleData.swift                    domain seed entry (fixed simulatedNow for determinism)
        SampleData+Library.swift            per-domain make* helpers

    Networking/
      APIRequest.swift                      the endpoint contract (associatedtype Response)
      APIClientProtocol.swift               one generic send<R: APIRequest>
      APIClient.swift                       final class Sendable wrapper · .live / .mock factories · APIJSON
      APIError.swift  HTTPMethod.swift
      MockProvider.swift                    stateless struct → request.mockResponse(from: seed) · failure/latency
      LiveProvider.swift                    generic shell → URLSession
      Requests/
        GetLibraryRequest.swift             GET  /library      → LibraryDTO
        BorrowBookRequest.swift             POST /books/:id/borrow
      Responses/
        DTO/
          LibraryDTO.swift                  Codable mirror + toDomain()/toDTO()
          BookDTO.swift                     Codable mirror + toDomain()/toDTO()

    DesignSystem/
      Tokens/
        ColorToken.swift  Typography.swift  Space.swift
        Radius.swift  Shadows.swift  Motion.swift            caseless enums, static members
      Modifiers/
        CardSurface.swift  OneShotPulse.swift  AIGradientText.swift
      Components/
        BookRow.swift  CoverThumbnail.swift  PillButton.swift   screen-agnostic Views (data as args)
      Composition/
        ScreenScaffold.swift  ScreenSection.swift  RhythmSpacer.swift  layout primitives every screen composes
      Resources/
        Fraunces-Variable.ttf  InterTight-Variable.ttf  JetBrainsMono-Variable.ttf

    Screens/
      BookList/
        BookListView.swift                  master · composes ScreenScaffold/ScreenSection
        BookListPresenter.swift             stateless derivation → [BookRowModel]
      BookDetail/
        BookDetailView.swift                detail · borrow action
      Routes/
        BookDetailRoute.swift               one Route value per file
      Catalog/
        CatalogSection+Books.swift          catalog entries for this feature
      ScreenCatalogView.swift               debug back-door (all screens wired)

    Assets.xcassets/                        AppIcon · AccentColor
    Preview Content/
      Preview Assets.xcassets

  AppTemplateTests/                         (Swift Testing + swift-snapshot-testing)
    Models/
      BookTests.swift                       model mutation methods
      DTORoundTripTests.swift               toDomain().toDTO() == dto
    Store/
      BorrowCommandTests.swift              optimistic apply + rollback
    Networking/
      APIRequestShapeTests.swift            path/method/body/codec
      MockProviderTests.swift               flow vs MockProvider (seed-driven)
    Snapshots/
      BookRowSnapshotTests.swift  BookListSnapshotTests.swift
    __Snapshots__/                          recorded baselines (per test class)

  AppTemplateUITests/                       (XCUITest, Xcode 26)
    BookListUITests.swift                   list states across MockProvider scenarios
    BorrowFlowUITests.swift                 borrow happy-path + failure/rollback
```

## 4. App entry chain

`AppTemplateApp` (`@main`) has two launch jobs: **register fonts** and **inject the store**.

```swift
@main
struct AppTemplateApp: App {
    @State private var store = AppStore()               // App root owns the one instance
    init() { FontRegistry.registerEmbeddedFonts() }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).preferredColorScheme(.light)
        }
    }
}
```

`RootView` hosts the tab IA. Each tab wraps a `NavigationStack` whose path is **owned by `AppStore`**
(one `NavigationPath` per tab — never local `@State` paths, so deep links and programmatic navigation
have a single source of truth). At this deployment target, the value-type `Tab` API on `TabView`
yields the native Liquid Glass floating tab bar with no availability gate. A hidden `ScreenCatalogView`
(every screen wired for review) is reachable behind a debug gesture.

Views reach the store with `@Environment(AppStore.self) private var store`. **The App root owns the
single instance** (`@State private var store = AppStore()`) and injects it; no other view constructs
one, and there is no global `.shared` singleton. Previews and tests build their own local `AppStore`
seeded from `SampleData` with a fixed `simulatedNow` (§6.4) — which is exactly why the store is
plain-initialized rather than a global: every context owns its instance.

## 5. State — `AppStore`

One `@MainActor @Observable final class AppStore` holds everything the UI reads:

```swift
@MainActor @Observable final class AppStore {
    private(set) var library: LibraryModel?             // domain reference graph (holds [BookModel])
    var loadState: LoadState = .idle               // idle | loading | loaded | failed(String)
    var writeError: WriteError?                     // surfaced by the write path; cleared on retry
    var libraryPath = NavigationPath()              // one per tab
    private(set) var borrowedBooks: [BookModel]          // cross-entity mirror, kept in sync by commands
    let api: APIClient

    init(api: APIClient = .live) { self.api = api; … }   // App root owns one; tests/previews make their own
}
```

What `AppStore` **does**: hydration (DTO→domain mapping), navigation paths, transient load/error
state, cross-entity mirrors (e.g. `borrowedBooks` gathered from books scattered across the library),
and the **thin async command wrappers** that own the optimistic-write dance (§7.4). What it **does
not** do: per-entity mutations (methods on the models, §6.3) or screen-specific derivation
(presenters, §8). After those two separations, `AppStore` is pure orchestration. Feature commands
split per file (`AppStore+Library.swift`) so parallel scaffolders don't serialize on one file (§11).

## 6. Models — reference vs value, and the DTO split

### 6.1 Why a DTO layer is forced (not chosen)

A `@MainActor @Observable` reference type **cannot** be freely `Sendable` and **cannot** be
`Codable`-decoded off the main actor — and network decoding happens off the main actor. So the type
you render and mutate cannot also be the type the network decodes. The wire side and domain side split:

```
Wire (off-actor, Sendable, Codable)        MainActor domain (@Observable, reference)
BookDTO     (Codable struct)     ──map──▶    BookModel      (@MainActor @Observable final class)
LibraryDTO  (Codable struct)     ──map──▶    LibraryModel   (@MainActor @Observable final class)
                                             holds ↓  (value types — shared by BOTH sides)
                                 Author · BookDetail · Genre · Rating  (Codable, Sendable)
```

### 6.2 The decision rule

> **Reference model iff the entity is a mutable row in a list.** Everything else is a value type.

- **Reference model** — `@MainActor @Observable final class`. Observable so mutating one row
  invalidates only that row, not the whole array — the Observation framework tracks per-property
  reads, so only views that read the changed property re-render (*Discover Observation in SwiftUI*,
  WWDC23). Identity
  equality; `ForEach` keys on `id`. **Not** `Codable`, **not** cross-actor `Sendable` (its
  `@MainActor` isolation *is* the Sendable conformance). Nested containers: each list-participating
  level is its own reference model (e.g. a `LibraryModel → Shelf → BookModel` hierarchy makes all three).
- **Value type** — `struct`/`enum`, `Codable, Equatable, Hashable, Sendable`. Leaf/immutable data;
  shared by both the DTO and the domain side.

```swift
@MainActor @Observable final class BookModel: Identifiable {
    let id: String
    var title: String
    var author: Author          // value type
    var status: ReadingStatus   // value enum: .unread | .reading | .read
    var format: Format          // value enum with associated values (see 02-models §3.2)
    var isBorrowed: Bool
    var isFavorite: Bool
    var rating: Rating?         // value type
    var detail: BookDetail?     // value type
}
```

### 6.3 Logic lives on the model

Each mutation is a pure in-place transition **method on the model** — never an index-walk on the store:

```swift
extension BookModel {
    func toggleFavorite()  { isFavorite.toggle() }
    func markRead()        { status = .read }
    func toggleBorrowed()  { isBorrowed.toggle() }   // used optimistically by the borrow command (§7.4)
}
```

A `library.book(id:)` helper returns the reference for command sites that hold only an id.

### 6.4 DTO mapping + `SampleData`

`*DTO`s mirror each reference model field-for-field, reusing leaf value types. Two extensions per entity:

```swift
extension BookDTO { @MainActor func toDomain() -> BookModel }   // build reference graph on main
extension BookModel    { func toDTO() -> BookDTO }              // snapshot reference → value (rollback, request bodies)
```

A `toDomain().toDTO() == dto` round-trip test guards mapping drift. **`SampleData` builds the domain
reference graph** (it runs in `@MainActor` contexts); the stateless `MockProvider` holds an immutable
DTO seed snapshot built from that graph via `.toDTO()`. One seed, two representations — no fixtures that
can drift apart.

## 7. Networking — protocol-driven, one file per endpoint

### 7.1 Provider-swappable surface

Screens depend on `APIClient` (the `final class` wrapper), never on `MockProvider`/`LiveProvider`.
Swapping mock → live, or mock → a test scenario, happens at the `AppStore` init boundary, not in a
screen.

### 7.2 The `APIRequest` contract

`APIClientProtocol` exposes **one generic method**; each endpoint is a `Request` struct. Adding an
endpoint is therefore *a new file*, not an edit to a shared protocol — the property that lets parallel
scaffolders add endpoints without colliding.

```swift
protocol APIClientProtocol: Sendable {
    func send<R: APIRequest>(_ request: R) async throws -> R.Response
}

protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [String: String] { get }       // default [:]
    var body: (any Encodable & Sendable)? { get }   // default nil
    var mockLatency: Duration { get }               // default .zero
    func mockResponse(from seed: MockSeed) throws -> Response   // pure; computes from the immutable seed
}
```

`MockProvider`/`LiveProvider` are thin generic shells dispatching on the request. `MockProvider` is a
**stateless value type** holding an immutable `MockSeed` (DTO snapshot) plus failure/latency knobs — no
actor, no persisted state. (`04-networking.md` is the authority on the full conventions.)

### 7.3 `APIClient` wrapper

`final class APIClient: APIClientProtocol, Sendable` wraps `any APIClientProtocol`. Because the
wrapped existential is an immutable `let` and `APIClientProtocol` refines `Sendable`, the compiler
**verifies** the conformance — plain `Sendable`, not `@unchecked`. Reserve `@unchecked Sendable` for
the rare case where a stored member is genuinely non-`Sendable` and you guarantee safety yourself
(and prefer `Mutex` from `Synchronization` over a hand-rolled lock if mutable shared state appears).
`static let live`/`mock(scenario:)` factory methods select the provider.

### 7.4 The write path (optimistic + rollback)

A write is an `AppStore` command, because it needs `api` and `writeError` (which a model method
cannot reach):

```swift
func borrow(bookID: BookModel.ID) async {
    guard let book = library?.book(id: bookID) else { return }
    let snapshot = book.toDTO()                 // value snapshot for rollback
    book.toggleBorrowed()                        // optimistic, in place → only this row re-renders
    syncBorrowedMirror()
    do { _ = try await api.send(BorrowBookRequest(id: bookID)) }
    catch { book.restore(from: snapshot); syncBorrowedMirror(); writeError = .borrow }
}
```

`restore(from: DTO)` applies a value snapshot back onto the live reference so observers see the revert.

## 8. Screens — logic out of views

The prior app's most visible failure: views tangled dozens of stateless derivations into `body`,
which made them untestable and let them drift from the mockup. The stance, per Apple's MV guidance
(WWDC24), is **not** a view-model per screen. It is a strict division of where each kind of logic
lives — a screen `View` is reduced to *layout + wiring*, nothing else:

| Concern | Lives in | Why not the view |
|---|---|---|
| Domain mutation (borrow, mark read, favorite) | a **method on the reference model** (§6.3) | reusable, unit-testable, no SwiftUI |
| Network orchestration (optimistic + send + rollback) + cross-entity effects | a **thin async `AppStore` command** (§7.4) | needs `api`/`writeError`; must be one place |
| Screen-specific *derivation* (titles, formatted strings, row view-models, offsets) | a **stateless `<Screen>Presenter`** (§8.3) | testable in→out; keeps `body` to layout |
| Ephemeral UI state (sheet presented?, animating?, local text field) | `@State` in the **view** | genuinely view-local; dies with the view |

> **The one rule that prevents drift:** if a value is *derived* from domain state, it belongs in the
> presenter; if it is *domain* state, it belongs on the model/store; only *ephemeral UI* state is
> `@State`. Nothing domain-shaped ever lives in `@State` — that was the prior app's core leak.

### 8.1 Anatomy of a screen

A screen is up to four small files, each with one job:

```
Screens/BookList/
  BookListView.swift        the View — layout + wiring only (§8.2)
  BookListPresenter.swift   stateless derivation: store → display data (§8.3)
Screens/Routes/
  BookDetailRoute.swift     a value identifying a pushable destination (§8.5)
Screens/Catalog/
  CatalogSection+Books.swift  registers the screen in the debug catalog (§8.6)
```

Reusable, screen-agnostic views (`BookRow`, `CoverThumbnail`) are **not** here — they live in
`DesignSystem/Components/`. A screen composes components; it does not define them.

### 8.2 The View — layout + wiring

Concrete skeleton; everything a screen `View` is allowed to do is shown here:

```swift
// Screens/BookList/BookListView.swift
struct BookListView: View {
    @Environment(AppStore.self) private var store       // the single source of truth (§5)
    @State private var isSearching = false              // ephemeral UI state ONLY — never domain

    var body: some View {
        let p = BookListPresenter(store: store)         // stateless derivation, rebuilt each pass (§8.3)

        ScreenScaffold(.root(title: p.title)) {          // tab root → large-title nav bar; chrome+layout seam (§8.4)
            if let message = p.emptyStateMessage {
                EmptyStateView(message: message)        // DesignSystem component
            } else {
                ScreenSection {                          // composition primitive (not SwiftUI.Section)
                    ForEach(p.rows) { row in
                        BookRow(model: row)              // component: data in, no AppStore access
                            .accessibilityIdentifier("bookrow.\(row.id)")          // §8.7
                            .onTapGesture { store.push(BookDetailRoute(id: row.id)) }  // navigation (§8.5)
                    }
                }
            }
        }
        .task { await store.loadLibrary() }             // the read path (§7, §10)
    }
}

#Preview {                                              // §8.7
    let store = AppStore(api: .mock())
    store.loadSeed(SampleData.library())                // seeds domain + fixed simulatedNow
    return BookListView().environment(store)
}
```

What the view does **not** contain: derivation (it reads `p.x`), domain mutations (it calls a model
method or a store command), hardcoded design values (tokens/components only), or a locally-owned
navigation path. Break a large `body` into `private` subviews in the same file; promote a subview to
`DesignSystem/Components/` only once a second screen needs it.

### 8.3 The presenter

A `<Screen>Presenter` is a **stateless value type** built in `body` from `(store, …ids)`. It returns
**data and view-models, never `View`s**, and it legitimately imports SwiftUI/tokens (which is exactly
why this logic can't live on the model):

```swift
// Screens/BookList/BookListPresenter.swift  (imports SwiftUI)
struct BookListPresenter {
    let store: AppStore
    var title: String { "Library" }
    var rows: [BookRowModel] {                 // BookModel → row view-model (cover, status glyph, borrowed/favorite, byline)
        (store.library?.books ?? []).map(BookRowModel.init)
    }
    var emptyStateMessage: String? { store.library?.books.isEmpty == true ? "No books yet" : nil }
}
```

Rules: (1) returns parts, never builds `Text`/`Image` — the view assembles those; (2) lives in
`Screens/`, not `Models/`; (3) stateless and built in `body`, so store dependency tracking is
preserved and rendering becomes granular for free once §6 makes rows observable; (4) **keep
derivation cheap** — it is rebuilt every `body` pass, so constructing it is free but heavy work inside
it (sorting/filtering large collections) recomputes each render; memoize anything non-trivial on the
model or store. A view with no derivation needs no presenter; add one the moment derivation appears in
`body`.

> **Why a presenter and not "just read the model in the view"?** The naive MV pattern — derivation
> logic living directly in `body` — is itself widely criticized as an anti-pattern (it can't be unit
> tested and it drifts from the mockup). The presenter is deliberately *not* that: it is a small,
> testable derivation layer, distinct from a stateful `@Observable` view-model. It is also not the
> only option — a view with trivial derivation skips it entirely.

### 8.4 Mutating from a view — command vs. model method, and composition

Two ways a view triggers a change, chosen by whether the network is involved:

| Action | Call | Why |
|---|---|---|
| **Networked write** (must persist + can fail) | `await store.borrow(bookID: id)` | the store command owns optimistic apply + rollback + `writeError` (§7.4) |
| **Pure local toggle** (no network) | `book.toggleFavorite()` | the model method is enough; no orchestration needed |

A view never reaches into `MockProvider`/`LiveProvider`, never constructs an `AppStore`, and never
hand-rolls layout. **Every screen composes the primitives in `DesignSystem/Composition/`**
(`ScreenScaffold` for the outer chrome/scroll/safe-area, `ScreenSection` for grouped content, rhythm spacers
for vertical gaps) rather than its own padding/stacks — this is what keeps screens consistent with one
another (the prior app's screens diverged because each was laid out by hand). All colors, spacing,
radii, and motion come from `DesignSystem/Tokens/`; **no literal design values in a view, ever**
(tokens are ported from `mockups/foundations/foundations.css` at foundation-freeze; later drift is
caught by a render snapshot — see `05-design-system.md`).

### 8.5 Navigation & routes

Each pushable destination is a value type in `Screens/Routes/<Name>Route.swift` (one per file):

```swift
struct BookDetailRoute: Hashable { let id: BookModel.ID }
```

Navigation state is **owned by `AppStore`** — one `NavigationPath` per tab (§4). A view pushes by
asking the store to append to the active tab's path (`store.push(BookDetailRoute(id:))`); it never
holds a local `@State` path. Each tab's root registers its destinations once:

```swift
.navigationDestination(for: BookDetailRoute.self) { route in
    BookDetailView(bookID: route.id)
}
```

Routing through the store (not local paths) is what makes deep links and programmatic navigation have
a single source of truth and survive tab switches. This is the recommended SwiftUI navigation pattern
(an `@Observable` owns the path, one per tab, no view-local `@State` path — the last point being a
documented anti-pattern for deep-linking and testability). Here `AppStore` *is* that observable: a
deliberate choice that keeps navigation atomic with domain state (load-then-navigate deep links touch
one object) and consistent with the single-source-of-truth rule. **Escape hatch:** if the app outgrows
this, extract a per-tab `Router` (`path` + `push`/`pop`/`popToRoot`) injected alongside `AppStore`;
the call sites (`store.push(…)` → `router.push(…)`) are the only change.

> **Why one `Route` struct per file (not a single per-tab `Route` enum)?** A typed `[Route]` enum
> stack is marginally more inspectable in tests, but a shared enum is a file *every* new screen must
> edit — reintroducing the serial-scaffolder collision the registry-as-files rule (§11) exists to
> avoid. Per-struct routes + type-erased `NavigationPath` keep screens parallel-scaffoldable; that
> trade is intentional. (Navigation-flow logic is still unit-testable: push a route, assert the path
> changed.)

### 8.6 The UI shell, sheets & the catalog

- **The UI shell** (when the tab bar / top bar show, and push vs. sheet vs. cover) is a set of rules
  declared through `ScreenScaffold`'s chrome intent (`.root` / `.detail` / `.immersive` / `.custom`) —
  the tab bar persists across pushes and hides only on immersive screens; tab roots get a large-title
  nav bar, detail screens an inline title + back. The full decision tables are `06-screens.md §2`.
- **Sheets/overlays** are presented with `.sheet(isPresented:)` driven by **ephemeral `@State`** on
  the presenting view; the sheet's content view lives in `Screens/`, ends in `View`, and follows the
  same rules (presenter for derivation, components for content). Modal-at-rest surfaces are not glass
  (a design rule — see `docs/design-docs/08-overlays.md`).
- **The catalog** (`ScreenCatalogView`) is a debug back-door listing every screen wired with seeded
  state, reachable behind a debug gesture (§4). Each feature registers its entries in
  `Screens/Catalog/CatalogSection+<X>.swift`; only adding a brand-new section edits the core
  `ScreenCatalogView.swift` (the one serial edit — §11).

### 8.7 Accessibility identifiers & previews

- **Identifiers** use the dot-namespaced `component.slot[.id]` convention
  (`bookrow.<id>`, `bookrow.borrowed.badge.<id>`, `book.borrowButton`) on every state-bearing element.
  The **view owns identifier placement**; the test layer queries them (`07-testing.md §7`). Set with
  `.accessibilityIdentifier("bookrow.\(book.id)")`.
- **Every screen ships a `#Preview`** that pins a locally-constructed `AppStore` seeded from
  `SampleData` (with the fixed `simulatedNow`) — the same state the render snapshot uses, so the
  preview *is* the thing that gets locked.

## 9. Concurrency (Swift 6.2, MainActor-by-default)

The project enables **Approachable Concurrency + Default Actor Isolation = `MainActor`** — the Xcode 26
default for new projects. That inverts the old chore: instead of sprinkling `@MainActor` on every type,
**all app code is MainActor-isolated by default** (App, Store, Models, Screens, DesignSystem), and you
explicitly mark only the *boundary* that must leave the main actor. (Examples in these docs still write
`@MainActor` for clarity, but at this setting it's the redundant-but-harmless default, not a
requirement.)

| Concern | Convention |
|---|---|
| **App code is `MainActor` by default** | `AppStore`, the reference models, presenters, and views are all on the main actor without annotation. Mutations and observable reads are main-thread by construction — no `DispatchQueue.main`. |
| **The boundary is what you mark — `nonisolated`, not just `Sendable`** | DTOs + leaf value types + the `APIRequest`/`APIClientProtocol` protocols (their requirements) + the request structs + `LiveProvider` + the JSON codec all decode **off the main actor**, so each is declared **`nonisolated`** — `Sendable` alone leaves a type MainActor-isolated and its off-main `Decodable` conformance then won't compile. Reference models are **not** `Codable` and never decode off-actor; `AppStore` maps `dto.toDomain()` back on the main actor (the default). **Full rule + the four failure modes: `04-networking.md §2` callout; value types: `02-models.md §1.2`.** |
| **Push genuinely parallel work behind `@concurrent`** | The off-main work — `LiveProvider`'s network call + JSON decode — is an `@concurrent` async function so it runs on the global executor; everything else stays serialized on `MainActor` (async funcs are `nonisolated(nonsending)` by default → they run on the caller's actor, not a random thread). `MockProvider` is a `Sendable` value type (§7-networking). |
| **`APIClient` is plain `Sendable`** | A `final class` wrapping an immutable `let any APIClientProtocol` (which refines `Sendable`) is compiler-verifiable — no `@unchecked`. Reserve `@unchecked` for a genuinely-unprovable member, and prefer `Mutex` over hand-rolled locks. |
| **Zero diagnostics** | Swift 6 language mode; data races are compile *errors*, not warnings. New code compiles clean. (The prior app deferred Swift 6 mode and accumulated the gap; default isolation is the correction that makes "clean" cheap.) |

## 10. End-to-end traces

**Read — load the library:**
1. `BookListView.task { await store.loadLibrary() }`.
2. `AppStore.loadLibrary()`: `loadState = .loading`; `let dto = try await api.send(GetLibraryRequest())`
   — decoded **off-actor** into `LibraryDTO`.
3. Back on main: `library = dto.toDomain()`; `loadState = .loaded`. (On throw: `loadState = .failed(…)`.)
4. `BookListView.body` builds `BookListPresenter(store:)`, reads `p.rows`, renders `ForEach(p.rows)` of `BookRow`.

**Write — borrow a book (optimistic):**
1. `BookRow`'s borrow button calls `store.borrow(bookID:)`.
2. Command snapshots `book.toDTO()`, calls `book.toggleBorrowed()` — **only that row re-renders**
   (observable reference), updates the `borrowedBooks` mirror.
3. `try await api.send(BorrowBookRequest(id:))`. On failure: `book.restore(from: snapshot)`,
   re-sync mirror, set `writeError` (the view surfaces it; there are no toasts).

## 11. Conventions & parallel-scaffolding rules

**Naming:** one public type per file, named for the type. Screens/sheets end in `View`; routes in
`Route`; presenters in `Presenter`. Modifiers are `private struct …: ViewModifier` exposed via an
`extension View` (`.cardSurface()`). Components are screen-agnostic `View`s taking data as args. Token
enums are caseless (`Typography`, `Space`, `Radius`, `Shadows`, `Motion`).

**Synchronized folders:** the project uses `PBXFileSystemSynchronizedRootGroup` — Xcode auto-includes
every `.swift` file in the registered trees, so **adding a source file needs no `.pbxproj` edit**.
This is what makes parallel scaffolding safe. `.pbxproj` edits are still required for a new SPM
dependency, a new target, or a new bundled resource.

**Registry-as-files:** new code is a new file — routes, store commands, sample-data seeds, catalog
sections, and endpoints each split per-file so agents don't serialize on a shared registry.

### Adding X → touch these

| Adding… | Files | Parallel-safe? |
|---|---|---|
| an **endpoint** | one `Networking/Requests/<Name>Request.swift` (carries its own `mockResponse`) | ✅ |
| a **screen** | `Screens/<Name>/<Name>View.swift` (+ `Presenter`), `Routes/<Name>Route.swift`, `Catalog/CatalogSection+<X>.swift` | ✅ (unless it needs a brand-new catalog section) |
| a **model field** | the reference model + its `*DTO` + the mapping + the round-trip test | ✅ |
| a **token / component / composition primitive** | `DesignSystem/{Tokens,Components,Composition}/…` + render snapshot | ✅ (in the Foundation phase) |
| a **store command** | `Store/AppStore+<Feature>.swift` | ✅ |
| a **new stored `AppStore` property** | core `AppStore.swift` | ⛔ serialize |
| a **new catalog section** | core `ScreenCatalogView.swift` | ⛔ serialize |
| an **SPM dep / target / bundled resource** | `.pbxproj` | ⛔ serialize |

## See also

- `02-models.md` · `03-store.md` · `04-networking.md` · `05-design-system.md` · `06-screens.md`
- `07-testing.md` — all four test layers (unit · integration · render snapshots · UI/E2E)
- Visual language: `docs/design-docs/00-overview.md`, `docs/design-docs/12-judgment.md`
