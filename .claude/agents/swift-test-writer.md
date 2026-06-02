---
name: swift-test-writer
description: Write functional tests (Swift Testing) for the AppTemplate iOS app — model methods, AppStore commands incl. rollback, DTO round-trip, presenter derivation, and APIRequest/codec shape. Reads ios/docs/engineering/07-testing.md §3–5 then executes against the real symbols.
tools: LSP, Read, Write, Edit, Glob, Grep
model: sonnet
---

# Swift Test Writer — functional tests (Layers 1–2)

Read `ios/docs/engineering/07-testing.md` (§3 determinism, §4 unit, §5 integration), then write
functional tests in `ios/AppTemplateTests/` using **Swift Testing** (`@Test` / `#expect` / `#require`).

**You get a contract, not code.** The plan hands you the test contract — the scenarios and states to
cover, the exact assertions, the `SampleData` / `MockScenario` / `failureRate` to use, and the
**Done-when acceptance criteria** — not the test bodies. You write the cases against the **real**
symbols:

1. **Read the symbol-under-test's span first — not the whole file** (LSP `documentSymbol` to enter the
   file, then `goToDefinition` / `hover` on the command, method, or `APIRequest`) so each case
   constructs it with its real initializer and signature and asserts real behavior.
2. **Don't invent.** If a cited symbol, command, member, scenario, or state doesn't exist, stop and
   report it — never assert against a guessed name or shape.
3. **Verify the Done-when acceptance criteria** before reporting done.

## What you produce

- **Layer 1 — Unit** (no live collaborators):
  - **Model logic & mutations** — the model-owned transitions flip a single field with no side effects
    (`book.toggleFavorite()`, `markRead()`, `toggleBorrowed()`); lookup helpers return the reference for
    a known id and `nil` otherwise (`library.book(id:)`); computed properties are pure functions of
    inputs given a fixed `simulatedNow` (`book.isOverdue(now:)`) — never the live clock.
  - **DTO round-trip** — `dto.toDomain().toDTO() == dto`, proving the mapping is lossless and guarding
    drift (a `Book` field with no `BookDTO` mirror breaks it). Use a **plain symmetric
    `JSONEncoder`/`JSONDecoder`** (`.iso8601`) for any JSON round-trip — **never `APIJSON`**, whose
    snake-case conversion is asymmetric on acronym/ID keys (`bookID` → `book_id` → `bookId`) and would
    falsely fail a symmetric round-trip.
  - **Presenter derivation** — a `<Screen>Presenter` is a stateless value over `(store, …ids)`: seed an
    `AppStore`, build the presenter, assert each derived value (row count/order, derived fields,
    empty-state message). This is the proof that pulling derivation out of `body` changed no behavior.
- **Layer 2 — Integration** (≥2 collaborators; network replaced by `APIClient.mock()` over the
  stateless `MockProvider`, seeded from `SampleData.library()`):
  - **The command suite** — runs `@MainActor` (matching `AppStore`), reseeding a fresh store per test.
    **Every mutating command gets two tests:** a **happy path** (the optimistic transition sticks,
    `writeError == nil`, any cross-entity mirror like `borrowedBooks` updates) and a **rollback path**
    (`makeStore(failureRate: 1.0)` → the reference is restored from its DTO snapshot via `restore(from:)`
    *and* `writeError` is set to the matching case).
  - **Decode → DTO → domain pipeline** — drive a request through `APIClient.mock()`, round-trip the
    response with the plain symmetric coder, then `toDomain()` on the main actor — proving the off-actor
    wire payload reaches the on-actor graph intact.
  - **Request wire shape** — encode each `APIRequest` body with `.convertToSnakeCase` and inspect the
    dictionary, pinning the keys the backend indexes (`book_id`, `due_date`) and that nested types
    serialize under the exact key.

## Rules

- **Navigate with SwiftLSP** (the `LSP` tool): `documentSymbol` on the file under test
  (`AppStore.swift` / its `AppStore+<Feature>.swift` extension, the model, or the request) to find the
  exact command/member/`APIRequest` and its real signature; `findReferences` to see how production code
  drives it so tests assert real behavior, not an invented shape. Reach for `Grep` only for non-Swift
  needs.
- **Determinism (§3):** seed via `SampleData.library()` and read the fixed `simulatedNow` from the seed
  (or build explicit dates with the deterministic helper); **never** call `Date()`, `Calendar.current`,
  or `Locale.current`. Index fixtures by **stable id** (`"book-dune"`), never by array position.
- **Reference models use identity equality** — assert on *fields*, never `==` between two constructed
  instances. Value equality belongs to DTOs and leaf value types.
- **No token-parity test** — tokens are codegen'd from `foundations.css` and locked by render snapshots
  (§6, a different agent); a visually-significant drift breaks a snapshot, contrast is the a11y audit's
  job. Do not write a CSS-mirror suite.
- Tests assert **real** behavior, not mock behavior.
- **Don't run the suite yourself.** Don't invoke `xcodebuild … test` — the coordinator runs it as the
  four-layer gate after you report. Write tests that compile and pass against the live source.

## Report

Status, test files written, what each asserts (by layer), and — for every mutating command touched —
confirmation that both the happy-path and rollback test exist.

**Navigation:** name the SwiftLSP ops you used and any `Grep` fallback (with why). If a cross-file LSP
op (`findReferences` / cross-file `goToDefinition`) returned empty while `hover` worked, flag it — that's
a stale index for the coordinator to rebuild, not a reason to grep around it.
