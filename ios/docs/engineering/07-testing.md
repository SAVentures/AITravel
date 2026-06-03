# 07 — Testing

The single testing document for the app. It covers all four layers of the test pyramid — unit,
integration, render snapshots, and UI/E2E — plus the determinism rules that keep the suite a real
quality gate rather than a green-light rubber stamp.

> **Why one doc.** Splitting testing across three files let each layer be reasoned about in isolation,
> which is how the prior app shipped screens that *built and passed* yet didn't match their mockups —
> the gates measured the wrong things. Here the four layers, and the cross-cutting rule that **every
> change must move the right layer**, live together so coverage gaps are visible.

> **Getting it right vs. keeping it locked.** Visual *fidelity to the mockup* is an **authoring-time**
> job — the foundation-freeze gate and the fidelity-reviewer agent get it right once, before a screen
> is accepted (see `05-design-system.md` / `06-screens.md`). The HTML mockups
> (`mockups/foundations/foundations.css`) are the **reference the Swift tokens are ported from** at
> that point — not a test oracle we diff against on every run. Tests are not where design is verified;
> they are the **lock**: a committed render-snapshot baseline (§6) fails the build the moment a *later*
> change silently moves a pixel — including a token that drifted in a way that matters visually. Build
> right → snapshot → locked.

> **The governing principle — green build ≠ done.** A change is complete only when the layer that can
> actually catch its failure mode is green: logic → a functional test; a component/screen → a render
> snapshot that locks it; a flow → an XCUITest across mock scenarios. Compiling and "looks right in
> the preview" are not coverage. → §9.

---

## 1. The pyramid

| Layer | Scope | Speed | Catches |
|---|---|---|---|
| **1 — Unit** | Pure functions: model logic & mutations, DTO round-trips, presenter derivation | ~ms each | Wrong logic, broken mapping, bad derivation |
| **2 — Integration** | `AppStore` ↔ `MockProvider` flows; command → state chains; decode → DTO → domain pipelines | ~tens of ms | Wrong wiring, broken optimistic/rollback, codec mismatch |
| **3 — Render snapshot** | SwiftUI views rendered at a fixed viewport, pixel-diffed against a committed baseline | ~seconds/view | **Visual regression** — a later change drifting spacing/color/font/border/icon/shadow from the locked baseline |
| **4 — UI / E2E** | The real compiled app driven through its UI against a `MockProvider` scenario | ~minutes/suite | Broken navigation, gestures, async load, accessibility |

**What belongs where** (book domain):
- **L1** — `BookModel.toggleBorrowed()` flips `isBorrowed`; `BookDTO.toDomain().toDTO() == dto`;
  `BookListPresenter.rows` count/order/derived fields; `BookModel.isOverdue` given a fixed `simulatedNow`.
- **L2** — `store.borrow(bookID:)` fires `BorrowBookRequest` through `MockProvider`, mutates the
  reference `BookModel`, and rolls back on failure; a `LibraryDTO` payload decodes and maps to a `LibraryModel`
  graph with the expected books.
- **L3** — a `BookRow` in its `.borrowed` state renders the borrowed badge **and** the dimmed cover
  **and** the correct byline simultaneously; no unit test can confirm that co-occurrence.
- **L4** — tapping a book row pushes `BookDetail`; the borrow button's failure path surfaces the
  write-error banner.

---

## 2. Frameworks & target layout

| Target | Kind | Imports | Owns |
|---|---|---|---|
| `AppTemplate` | app | **zero third-party deps** | production code only |
| `AppTemplateTests` | unit-test bundle | `Testing`, `SnapshotTesting`, `@testable import AppTemplate` | layers 1–3 |
| `AppTemplateUITests` | UI-test bundle | `XCTest` only (links the app binary at runtime) | layer 4 |

- **Default framework: Swift Testing** (`@Test` / `#expect` / `#require`). New logic tests use it.
- **XCTest coexists** — `XCUITest` (L4) is XCTest-based, and snapshot tests may be either. Don't
  rewrite existing XCTest; new logic starts in Swift Testing. Both run in one `xcodebuild test`.
- **The app target has no SPM dependencies and never imports a test framework.** The only third-party
  dependency in the whole project is [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing)
  (verify the latest release when scaffolding), added to `AppTemplateTests` only.

```swift
import Testing
@testable import AppTemplate

@Test("borrowing a book flips isBorrowed")
func borrowFlips() {
    let book = SampleData.library().library.books.first(where: { !$0.isBorrowed })!
    book.toggleBorrowed()
    #expect(book.isBorrowed)
}
```

---

## 3. Determinism — fixtures and the clock

Every test that needs domain data calls **`SampleData.library()`** rather than constructing models
inline — the same seed the screens use for `#Preview`. A seed change that breaks a test is then a real
signal, not an authoring accident. Index fixtures by **stable id** (`"book-dune"`), never by array
position, so reseeding/reordering can't silently invalidate an assertion.

**Never call the live clock.** `Date()`, `Date(timeIntervalSinceNow:)`, `Calendar.current`, and
`Locale.current` are banned in tests — they make time/locale-conditional state (e.g. an *overdue*
badge) flaky. The seed exposes a fixed `simulatedNow`; the store reads it. For a specific offset,
build the date with the deterministic helper:

```swift
let now = SampleData.library().simulatedNow          // fixed Date, committed in the seed
let due = TestDate.make(y: 2026, m: 6, d: 1)          // explicit, timezone-pinned
```

Reference models use **identity equality** — assert on *fields*, never `==` between two constructed
instances. Value equality belongs to DTOs and leaf value types.

---

## 4. Layer 1 — Unit

Exercises one type/function with no live collaborators.

### 4.1 Model logic & mutations
The model-owned transitions (§6.3 of `01-architecture.md`) test as pure in-place changes:

| What | Assertion |
|---|---|
| `BookModel.toggleFavorite()` / `markRead()` / `toggleBorrowed()` | the single field flips; no side effects |
| `LibraryModel.book(id:)` | returns the reference for a known id, `nil` for an unknown one |
| computed properties (e.g. `BookModel.isOverdue` given `simulatedNow`) | pure function of inputs, no `Date()` |

### 4.2 DTO round-trip
The reference models aren't `Codable`; the round-trip runs through the mapping:

```swift
@Test func bookRoundTrips() throws {
    let dto = SampleData.libraryDTO().books[0]
    #expect(dto.toDomain().toDTO() == dto)   // mapping is lossless both ways
}
```
Use a **plain symmetric `JSONEncoder`/`JSONDecoder`** (`.iso8601` dates) for any JSON round-trip —
**not** `APIJSON`, whose `.convertToSnakeCase`/`.convertFromSnakeCase` is asymmetric on acronym/ID keys
(`bookID` → `book_id` → `bookId` — the capitalized `ID` is lost on the way back) and would falsely fail
a symmetric round-trip. This test guards mapping drift: a field added to `BookModel` but not `BookDTO`
breaks the round-trip.

### 4.3 Presenter derivation
A `<Screen>Presenter` is a stateless value over `(store, …ids)`, so it tests as input → output with no
rendering: seed an `AppStore`, build the presenter, assert each derived value.

```swift
@Test func bookListPresenterDerivesRows() {
    let store = AppStore(api: .mock())
    store.loadSeed(SampleData.library())
    let p = BookListPresenter(store: store)
    #expect(p.rows.count == store.library?.books.count)
    #expect(p.rows.first?.byline == "Frank Herbert")
    #expect(p.emptyStateMessage == nil)
}
```
This is the proof that pulling derivation out of `body` changed no behavior — paired with the
byte-identical screen snapshot (§6).

> **No token-parity test.** Tokens are ported from `mockups/foundations/foundations.css` at
> foundation-freeze time (reviewed there, see `05-design-system.md`); the mockups are the authoring
> reference, not a runtime oracle. A token that drifts in a way that matters visually breaks a render
> snapshot (§6); WCAG-AA contrast is checked by the accessibility audit (§7.4). Neither needs a
> hardcoded CSS-mirror suite.

---

## 5. Layer 2 — Integration

Needs ≥2 collaborators. The network is replaced by `APIClient.mock()` wrapping `MockProvider`, seeded
from `SampleData.library()` — deterministic, fixture-shaped responses.

### 5.1 `AppStore` ↔ `MockProvider` — the command suite
Runs `@MainActor` (matching `AppStore`), reseeding a fresh store per test. **Every mutating command
gets two tests:**

```swift
@Test @MainActor func borrowHappyPath() async {
    let store = makeStore()                       // .mock(), seeded
    let id = store.library!.books.first(where: { !$0.isBorrowed })!.id
    await store.borrow(bookID: id)
    #expect(store.library!.book(id: id)!.isBorrowed)
    #expect(store.writeError == nil)
    #expect(store.borrowedBooks.contains { $0.id == id })
}

@Test @MainActor func borrowRollsBackOnFailure() async {
    let store = makeStore(failureRate: 1.0)       // MockProvider injects an APIError
    let id = store.library!.books.first(where: { !$0.isBorrowed })!.id
    await store.borrow(bookID: id)
    #expect(!store.library!.book(id: id)!.isBorrowed)   // restored from snapshot
    #expect(store.writeError == .borrow)
}
```
The happy path proves the optimistic transition sticks; the rollback path (`failureRate = 1.0`) proves
`restore(from:)` reverts the reference *and* sets `writeError`. For a pure transition with no network,
call the model method directly.

### 5.2 Decode → DTO → domain pipeline
Drive a request through `APIClient.mock()`, encode the response back and decode it with the plain
symmetric coder, then map to the domain — proving the off-actor wire payload reaches the on-actor graph
intact:
```swift
@Test func libraryResponseReachesDomain() async throws {
    let resp = try await api.send(GetLibraryRequest())     // resp.library is LibraryDTO
    let round = try encodeRoundTrip(resp)                  // plain symmetric coder
    #expect(round.library.id == resp.library.id)
    let domain = await round.library.toDomain()            // on @MainActor
    #expect(domain.books.contains { $0.isBorrowed })
}
```

### 5.3 Request wire shape
Encode each `APIRequest` body with `.convertToSnakeCase` and inspect the dictionary, so the keys the
backend will index are pinned (`book_id`, `due_date`) and nested types serialize under the exact key.

---

## 6. Layer 3 — Render snapshots (the lock)

The **lock** on a screen/component you already got right at authoring time. It does not verify the
design (that's the fidelity-reviewer's job); it freezes the accepted render so any *later* change that
silently moves a pixel — spacing, color, font, border, icon substitution, shadow — fails the build.
Keep it **thin: one snapshot per screen/component state**, no more. Build right → snapshot → locked.

### 6.1 The pinned helper
Every snapshot goes through one wrapper so all visual tests render identically regardless of file.

```swift
/// The single viewport for every render snapshot. iPhone 17 Pro logical frame.
/// Re-record all baselines if this changes.
let canonicalConfig = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 393, height: 852),
    traits: UITraitCollection(traitsFrom: [
        .init(userInterfaceStyle: .light),
        .init(displayScale: 3),
    ])
)

@MainActor
func assertDesignSnapshot<V: View>(_ view: V, named name: String,
                                   file: StaticString = #filePath,   // #filePath, NOT #file — see §6.5
                                   testName: String = #function, line: UInt = #line) {
    let host = UIHostingController(rootView: view.designSystemEnvironment())
    host.overrideUserInterfaceStyle = .light
    assertSnapshot(of: host, as: .image(on: canonicalConfig),
                   named: name, file: file, testName: testName, line: line)
}
```
`designSystemEnvironment()` registers embedded fonts and injects an `AppStore` seeded from
`SampleData.library()` at the fixed `simulatedNow` — the same state `#Preview` uses. Use the
`UIHostingController` path (respects safe area, traits, @3x) for screen-level snapshots; either path is
fine for isolated components. **The helper takes no `snapshotDirectory:`** — swift-snapshot-testing 1.19
has no such parameter; the baseline directory is derived from `file` (`#filePath`), full stop.

### 6.2 What to snapshot
- **Every component, in each of its key states.** The state name becomes the `named:` argument / PNG
  filename. e.g. `BookRow`: `.available` · `.borrowed` · `.reading` · `.favorite`; `PillButton`:
  `.primary` · `.ghost`; composition primitives in a representative layout.
- **Every product screen, once,** seeded at `simulatedNow`. e.g. `book-list`, `book-detail`,
  `book-list-empty`. Catalog/playground scaffolding is excluded.

### 6.3 Baselines
PNGs land in `__Snapshots__/<TestClassName>/` **alongside the test** and are **committed — they are
the contract.** Never `.gitignore` them. First run records and fails with "recorded"; commit the PNG;
subsequent runs diff. Intentional appearance change → re-record locally with
`withSnapshotTesting(record: .all)`, review every diff, commit. **Never leave `record: .all` in
committed code** — that silently re-records and hides regressions.

### 6.4 Determinism checklist
| Source of flake | Mitigation |
|---|---|
| Live clock | `seed.simulatedNow` / `TestDate.make(…)` only |
| Animation mid-flight | snapshot at rest; never `withAnimation` in a snapshot |
| One-shot entrance motion (e.g. `.oneShotPulse`) | inject `.environment(\.disablesOneShotMotion, true)` so it settles to 1.0 before capture, else the frame is caught mid-pulse and flakes |
| Random data | only `SampleData.library()` |
| Font fallback | `designSystemEnvironment()` registers fonts |
| Simulator/OS/scale change | one pinned simulator (§8); re-record on pin change |

### 6.5 Infrastructure gotchas (each bit on first real use — fix once, here)
The snapshot infra has four sharp edges under **MainActor-by-default + synchronized folders (pbxproj
objectVersion 77)**. Get them right up front:

| Symptom | Cause | Fix |
|---|---|---|
| `XCTestCase` subclass **won't compile** in the unit-test target | `XCTestCase.init` is `nonisolated`; it clashes with the target's MainActor default | **Snapshot (and all functional) tests use Swift Testing** — `@Suite` + `@Test @MainActor`, never `XCTestCase`. `XCTestCase` is reserved for the **XCUITest target only** (its own module, §7). |
| `You can't save the file … the volume is read only` on first record | the helper passed **`#file`**, which `xcodebuild` remaps to a non-writable path | the helper's `file:` default is **`#filePath`** (the real on-disk path), never `#file` (§6.1). |
| `extra argument 'snapshotDirectory'` | that parameter doesn't exist in swift-snapshot-testing 1.19 | don't pass it — the dir derives from `#filePath`. Pin the library's actual `assertSnapshot` signature before calling. |
| `Multiple commands produce …/<State>.png` at build time | synchronized folders bundle the committed baseline PNGs into the test target; same-named PNGs across suites collide when flattened | set **`EXCLUDED_SOURCE_FILE_NAMES = "*.png"`** on the test target. NB: hand-authored `membershipExceptions` in the `.pbxproj` are **silently ignored** under objectVersion 77 — the build setting is the only thing that works. |

---

## 7. Layer 4 — UI / E2E (XCUITest)

Drive the real app through its UI against a chosen `MockProvider` scenario, no network. XCUITest is the
project's "Playwright for iOS": `XCUIApplication().launch()`, scenario via `launchEnvironment`, query by
accessibility identifier, assert with `waitForExistence`. Xcode 26 adds record/replay/review tooling on
the same stable API.

### 7.1 Scenario injection via launch environment
The app reads known keys at launch and constructs its `AppStore`/`MockProvider` accordingly — the
injection seam, **not** a global (the store is owned at the App root, §4 of `01-architecture.md`).

```swift
// AppTemplateApp.init() — illustrative
let env = ProcessInfo.processInfo.environment
let scenario = MockScenario(rawValue: env["UITEST_SCENARIO"] ?? "") ?? .standard
let failureRate = Double(env["UITEST_FAILURE_RATE"] ?? "") ?? 0
let now = env["UITEST_NOW"].flatMap { ISO8601DateFormatter().date(from: $0) }
_store = State(initialValue: AppStore(api: .mock(scenario: scenario, failureRate: failureRate),
                                      now: now))
```

| Key | Values | Effect |
|---|---|---|
| `UITEST_SCENARIO` | `standard` · `emptyLibrary` · `allBorrowed` | selects the `SampleData` factory |
| `UITEST_FAILURE_RATE` | `0.0`…`1.0` | `MockProvider` injects `APIError`s |
| `UITEST_NOW` | ISO-8601 | pins the clock for time-conditional state |

```swift
enum MockScenario: String, Sendable {
    case standard       // SampleData.library() — the default
    case emptyLibrary   // 0 books — exercises empty state
    case allBorrowed    // every book borrowed — exercises the borrowed/zero-available state
}
```

### 7.2 Table-driven across states
Exercise one screen against every scenario in a single test, so coverage gaps are obvious:
```swift
let scenarios: [(scenario: String, hasRows: Bool, canBorrow: Bool)] = [
    ("standard",     true,  true),
    ("emptyLibrary", false, false),
    ("allBorrowed",  true,  false),
]
for s in scenarios {
    let app = makeLaunchedApp(scenario: s.scenario); defer { app.terminate() }
    app.tabBars.buttons["tab.library"].tap()
    #expect(app.cells["bookrow.book-dune"].waitForExistence(timeout: 4) == s.hasRows)
}
```

### 7.3 Query by accessibility identifier, never by text
Text is locale-sensitive and changes with copy; identifiers are stable contracts. Use the dot-namespaced
`component.slot[.id]` convention from `06-screens.md` — `tab.library`, `bookrow.<id>`,
`bookrow.borrowed.badge.<id>`, `book.borrowButton`, `writeError.banner`. Set with
`.accessibilityIdentifier("bookrow.\(book.id)")`. Wait with `waitForExistence(timeout:)` — **never
`sleep()`**.

### 7.4 Accessibility audit
Run one `performAccessibilityAudit()` per screen under the `standard` scenario:
```swift
@MainActor func testBookListAudit() throws {
    let app = makeLaunchedApp(scenario: "standard")
    app.tabBars.buttons["tab.library"].tap()
    try app.performAccessibilityAudit()   // .contrast, .dynamicType, .hitRegion, …
}
```
Suppress a **documented** exemption per-type via the `issueHandler` closure (return `true` to suppress
that one issue, `false` to fail) — and tag the exempt element with a dedicated identifier so the handler
matches it without hardcoding text. Suppress narrowly; never blanket-return `true`.

### 7.5 Screenshots = triage only
`XCTAttachment(screenshot:)` at key states gives a CI failure visual context. These are **never
diffed** and have no baselines — that's layer 3's job. Don't conflate the two.

### 7.6 Flakiness
| Source | Mitigation |
|---|---|
| Text queries | identifiers only |
| Animations | `waitForExistence`; disable animations via launch arg |
| Time state | always pass `UITEST_NOW` |
| Slow boot | launch in `setUp`, not each method |
| Async load latency | timeout ≥ the mock latency for that endpoint |

---

## 8. Running the tests

```
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO test
```
- Swap `test` → `build` to compile only (confirm a new file joined the target).
- Filter: `-only-testing:AppTemplateTests/BookListPresenterTests`.
- **One pinned simulator** for the whole suite (render snapshots are sensitive to model/OS/scale).
  When the pin changes: update this doc, re-record snapshots, review every diff, commit them in a
  dedicated `chore: re-record snapshots for simulator pin change` commit.

---

## 9. The coverage gate

Coverage is enforced at the commit step (the `ios-test-coverage-check` skill), not left to judgment.
Before a branch merges:

1. **Every logic change ships a functional test** (L1/L2) — model method, command (incl. rollback),
   DTO round-trip, presenter, or codec shape.
2. **Every new/changed component or screen ships a render snapshot** (L3) that **locks** its key states.
3. **Every new screen or flow ships an XCUITest** (L4) across its `MockProvider` scenarios, plus an
   accessibility audit.

Visual *fidelity to the mockup* is **not** on this list — it's gotten right at authoring time by the
foundation-freeze and the fidelity-reviewer, then locked by step 2. A PR that adds a screen but no
locking snapshot, or a command but no rollback test, is **incomplete** — the gate fails it. This is the
structural answer to "it built and looked fine but wasn't actually right."

---

## See also

- `01-architecture.md` §10–11 — the layers under test, the read/write traces these exercise
- `03-store.md` · `04-networking.md` — `AppStore` commands and `MockProvider`/`MockScenario` wiring
- `05-design-system.md` — tokens, composition primitives, the **foundation-freeze** gate, a11y-id conventions
- `06-screens.md` — presenter shape, the `component.slot[.id]` convention, the **fidelity-reviewer** gate
- `mockups/foundations/foundations.css` — the authoring reference tokens are ported from (not a test oracle)
- `docs/design-docs/12-judgment.md`, `16-accessibility.md` — the visual rules the authoring gates enforce (tests only lock the result)
