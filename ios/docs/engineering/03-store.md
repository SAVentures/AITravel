# 03 — AppStore: State Architecture

`AppStore` is the one object the whole UI reads. This doc covers its ownership, the shape of the state
it holds, where mutations live (the two-tier split with `02-models.md`), hydration, and the
deterministic clock. The domain types themselves are `02-models.md`; the network it talks to is
`04-networking.md`.

---

## 1. Single source of truth

```swift
@MainActor
@Observable
final class AppStore {
    init(api: APIClient = .live) { self.api = api }   // no private/singleton — see below
}
```

`@MainActor` puts every mutation and observable read on the main thread — no manual
`DispatchQueue.main.async` in views. `final` prevents subclassing. `@Observable` (Observation
framework) makes each stored property observable, so SwiftUI re-renders only the views that read a
changed property.

**Ownership: the App root owns the one instance; there is no global singleton.** `AppTemplateApp`
holds `@State private var store = AppStore()` and injects it with `.environment(store)`; views read it
via `@Environment(AppStore.self) private var store` (and `@Bindable var store = store` for two-way
bindings). Previews and tests construct their *own* local `AppStore` and seed it — which is exactly why
`init` is public and non-singleton: every context (app, preview, test, UI-test) owns its instance. (We
dropped the `.shared` singleton deliberately — `01-architecture.md §5`, validated against current
SwiftUI guidance.)

There are **no parallel stores**. Every domain concept lives in one graph; a screen reads the slice it
needs off `AppStore` and never duplicates it into local `@State` unless it is strictly ephemeral UI
state.

---

## 2. State shape

```swift
@MainActor @Observable final class AppStore {
    // — domain graph (hydrated from the network; see §5) —
    private(set) var library: LibraryModel?          // the @Observable reference graph (02-models)
    private(set) var borrowedBooks: [BookModel] = []  // cross-entity mirror, kept in sync by commands (§4)

    // — transient store state —
    var loadState: LoadState = .idle            // idle | loading | loaded | failed(String)
    var writeError: WriteError?                  // set by the write path; cleared on retry (surfaced as a banner)

    // — navigation (one path per tab) —
    var selectedTab: AppTab = .library
    var libraryPath = NavigationPath()
    var youPath     = NavigationPath()

    // — deterministic clock (§6) —
    var simulatedNow: Date = AppDate.make(y: 2026, m: 6, d: 2)

    let api: APIClient
}
```

- **`library` is `private(set)`** — only `AppStore` replaces the graph (at hydration); views mutate
  *through* commands or model methods, never by reassigning the graph.
- **`borrowedBooks`** is a flat mirror gathered from books scattered in the library — the canonical
  cross-entity example (§4.2). It is derived state the store keeps coherent, not a second source of
  truth.
- **`LoadState` / `WriteError`** are small value types (`Models/` or `Store/`), so load and error are
  first-class state a view can switch on, not ad-hoc booleans:
  ```swift
  enum LoadState: Equatable { case idle, loading, loaded, failed(String) }
  enum WriteError: Equatable { case borrow /* one case per write op */ }
  ```

### Navigation paths (one per tab)
Each tab owns exactly one `NavigationPath`; the tab's `NavigationStack` drives presentation from it. A
view pushes through a convenience that appends to the **active** tab's path (never a view-local path):

```swift
func push(_ route: some Hashable) { mutateActivePath { $0.append(route) } }
func pop()                        { mutateActivePath { if !$0.isEmpty { $0.removeLast() } } }
func popToRoot()                  { mutateActivePath { $0 = NavigationPath() } }

private func mutateActivePath(_ change: (inout NavigationPath) -> Void) {
    switch selectedTab {
    case .library: change(&libraryPath)
    case .you:     change(&youPath)
    }
}
```
Why navigation lives here (and the per-`Route`-struct choice) is settled in `01-architecture.md §8.5`;
this is just where the state sits.

---

## 3. Where mutations live

Mutations split into two tiers — this is the rule that keeps the store thin and the models reusable.

**Tier 1 — pure state transitions live on the reference models** as methods (`02-models.md §2`).
Given a `BookModel` reference, the change is a direct in-place mutation; because `BookModel` is `@Observable`,
only the views reading the changed property invalidate:

```swift
book.toggleFavorite()   // isFavorite.toggle()
book.markRead()         // status = .read
```
A view calls these directly when the change is **purely local** (no network).

**Tier 2 — networked / cross-entity orchestration lives on `AppStore`** as thin `async` command
wrappers. A wrapper resolves the reference, applies the model transition *optimistically*, fires the
API write, and **rolls back from a DTO snapshot** on failure (you can't "reassign back" a reference the
views already hold):

```swift
// Store/AppStore+Library.swift
func borrow(bookID: BookModel.ID) async {
    guard let book = library?.book(id: bookID) else { return }
    let snapshot = book.toDTO()                  // value snapshot for rollback
    book.toggleBorrowed()                         // optimistic, in place → only this row re-renders
    syncBorrowedMirror()
    do { _ = try await api.send(BorrowBookRequest(id: bookID)) }
    catch { book.restore(from: snapshot); syncBorrowedMirror(); writeError = .borrow }
}
```

| Command (Tier 2) | Model transition it drives | Extra orchestration |
|---|---|---|
| `borrow(bookID:)` | `book.toggleBorrowed()` | POST borrow; sync `borrowedBooks`; rollback via `restore(from:)` |
| `returnBook(bookID:)` | `book.toggleBorrowed()` | POST return; sync mirror; rollback |
| `setRating(bookID:stars:)` | `book.rating = …` | PATCH rating; rollback |

`library?.book(id:)` is the lookup helper that returns the reference for an id (no by-index walk).
Name commands as verb phrases (`borrow`, `returnBook`, `setRating`).

### 3.2 Cross-entity mirrors
Some state spans the graph — `borrowedBooks` is every borrowed book, wherever it sits. The store keeps
it coherent with one private helper that every command touching borrow-state calls:

```swift
private func syncBorrowedMirror() {
    borrowedBooks = library?.books.filter(\.isBorrowed) ?? []
}
```
A mirror is *derived* — never mutate it directly; re-derive it after the underlying change so it can't
drift from the graph.

---

## 4. Hydration & seeding

The store has two ways to get its graph, and only two:

**Production — hydrate from the network** (the read path, `01-architecture.md §10`), mapping the wire
DTO to the domain graph once, on the main actor:

```swift
func loadLibrary() async {
    loadState = .loading
    do {
        let dto = try await api.send(GetLibraryRequest())   // LibraryDTO, decoded off-actor
        library = dto.toDomain()                            // map on MainActor
        syncBorrowedMirror()
        loadState = .loaded
    } catch {
        loadState = .failed(String(describing: error))
    }
}
```

**Previews & tests — seed directly** from `SampleData` (no network), pinning the clock:

```swift
func loadSeed(_ seed: SampleSeed) {
    library = seed.library
    simulatedNow = seed.simulatedNow
    syncBorrowedMirror()
    loadState = .loaded
}
```
This is the synchronous, no-network path: the graph is set directly from a `SampleData` factory
(`02-models.md §5`), so the screen renders deterministically — the same state the render snapshot locks
(`07-testing.md`). (The *network* path, `loadLibrary()`, is what UI/E2E tests exercise — there the
`MockProvider` scenario supplies the seed.)

### The `preview` factory (DRY the boilerplate)

Every `#Preview` would otherwise repeat "make a mock store, seed it, return it." Collapse that into one
factory — a **fresh instance each call** (not a shared singleton), so previews stay isolated:

```swift
extension AppStore {
    @MainActor
    static func preview(_ seed: SampleSeed = SampleData.library()) -> AppStore {
        let store = AppStore(api: .mock())
        store.loadSeed(seed)
        return store
    }
}
```

Previews then read `.environment(AppStore.preview())` or `.environment(AppStore.preview(SampleData
.emptyLibrary()))` (`06-screens.md §8`). Tests that want the same convenience use it too; tests that need
to drive the network use `AppStore(api: .mock(...))` and `await loadLibrary()` instead.

---

## 5. Determinism via `simulatedNow`

```swift
/// The simulated "now". Pinning it makes every time-conditional surface deterministic —
/// overdue badges, due-soon nudges — with no real-clock dependency.
var simulatedNow: Date
```

`simulatedNow` is seeded by `SampleData.library()` to a fixed instant. **Every time-dependent piece of
UI and logic reads `store.simulatedNow`, never `Date()`** — and model-layer time logic takes it as an
argument (`book.isOverdue(now: store.simulatedNow)`, `02-models.md §6`). This is what makes previews,
snapshots, and time-conditional tests reproducible. To exercise a specific moment (e.g. a book just
gone overdue), a test sets `store.simulatedNow = AppDate.make(...)`.

---

## 6. Convenience computed properties

Read-only derivations that several screens share live as computed properties on `AppStore` (anything
*screen-specific* belongs in that screen's presenter instead, `06-screens.md`):

```swift
var overdueBooks: [BookModel] {
    (library?.books ?? []).filter { $0.isOverdue(now: simulatedNow) }
}
var isLoaded: Bool { if case .loaded = loadState { return true } else { return false } }
```

---

## 7. Adding state — checklist

1. **Add an observable property** (a plain `var`; `@Observable` tracks it) to `AppStore`. This is the
   one case that edits core `AppStore.swift` — a serialized shared-file edit (`01-architecture.md §11`).
2. **Seed it** — add the field to `SampleSeed` and populate it in `Models/SampleData+<Domain>.swift`
   (a new file, not an edit to core `SampleData.swift`).
3. **Decide where the mutation lives.** Pure in-place transition → a **method on the reference model**
   (`02-models.md §2`). Needs the network or touches other state → a thin `async` **wrapper in
   `Store/AppStore+<Feature>.swift`** (optimistic → write → `restore(from:)` rollback) — a new file,
   not an edit to core `AppStore.swift`.
4. **It's `@MainActor` for free** — extension methods on `AppStore` inherit its actor isolation. Don't
   reach into the store from a background task; hop with `await MainActor.run { … }` if bridging from a
   non-isolated context.

---

## See also

- `01-architecture.md` §5 (ownership) · §8.5 (navigation) · §10 (read/write traces)
- `02-models.md` — the reference models, their mutation methods, the DTO `toDomain()`/`toDTO()` mapping
- `04-networking.md` — `APIClient`, `MockProvider` (stateless), the requests these commands send
- `07-testing.md` §5 — command tests (happy path + rollback) and the `loadSeed` determinism pattern
