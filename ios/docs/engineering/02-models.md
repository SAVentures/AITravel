# 02 — Models

The model layer lives in `ios/AppTemplate/Models/`. It has **two kinds of type**: a small set of
`@Observable` **reference models** (`Library`, `Book`) that form the mutable graph and own their own
mutations, and the **leaf value types** (everything else) they hold. The whole graph is owned by
`AppStore`. This doc describes the *shape of the data* and *where mutations live*; the orchestration
around them — optimistic writes, rollback, hydration — is `03-store.md`. The running example is the
library / book-management reference slice; swap `Library`/`Book` for your own entities.

---

## 1. Reference models vs value types

> **The decision rule:** a type is a `@MainActor @Observable final class` **reference model iff it is
> a mutable row in a list**. Everything else is a value type. (Apple's WWDC25 performance guidance:
> per-row observation means mutating one row invalidates only that row, not the whole array.)

### 1.1 The reference models — `Library`, `Book`

The container and the row both participate in list rendering and mutate, so both are reference models:

```swift
@MainActor @Observable final class Library: Identifiable {
    let id: String
    var name: String
    var books: [Book]
    func book(id: Book.ID) -> Book? { books.first { $0.id == id } }   // lookup helper for command sites
}

@MainActor @Observable final class Book: Identifiable {
    let id: String
    var title: String
    var author: Author             // value type
    var status: ReadingStatus      // value enum: .unread | .reading | .read
    var format: Format             // value enum WITH associated values (§3.2)
    var isBorrowed: Bool
    var isFavorite: Bool
    var rating: Rating?            // value type
    var detail: BookDetail?        // value type
    // designated init
}
```

Consequences of being reference `@Observable` types:

- **They are `@MainActor`-isolated** — every read and mutation is on the main actor (their isolation
  *is* their `Sendable` conformance). They therefore never cross the API boundary; the wire uses DTOs
  (§4).
- **They are NOT `Codable`.** Serialization is the DTO layer's job — the compiler forbids decoding a
  `@MainActor` type off-actor.
- **Equality is identity-based.** Don't declare value `Equatable`/`Hashable` on them; two references
  are equal iff they're the same instance. `ForEach`/`List` key on `id`, so identity equality is
  correct for diffing. Tests assert on fields, never `==` (`07-testing.md`).
- **They own their mutations as methods** (`book.toggleFavorite()`, …) — §2. Mutation is in place;
  there is no replace-the-value dance.

Nested containers: each list-participating level is its own reference model. A `Library → Shelf →
Book` hierarchy would make all three reference models; the slice keeps two.

### 1.2 The leaf value types — everything else

`Author`, `BookDetail`, `Rating`, and the enums (`ReadingStatus`, `Format`, `Genre`) stay
`struct`/`enum` and conform to `Codable, Equatable, Hashable, Sendable`:

```swift
struct Author: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
}
struct BookDetail: Codable, Equatable, Hashable, Sendable {
    var synopsis: String
    var pageCount: Int
    var coverSymbol: String        // SF Symbol for the monochrome cover placeholder
    var genre: Genre
}
struct Rating: Codable, Equatable, Hashable, Sendable {
    var stars: Int                 // 0…5
}
```

These are leaf/immutable data. A reference model holds them directly (a `Book` holds an `Author`
value); a DTO holds the *same* value types unchanged (there is no `AuthorDTO` — leaf types are already
wire-safe). The only "mutation" of leaf data is whole-value reassignment of a reference-model property
(`book.rating = Rating(stars: 4)`), which `@Observable` tracks.

> **Why keep the boundary small:** the over-invalidation Apple's guidance addresses is per-row.
> `Library`/`Book` are the container/rows; making the leaves reference types would buy no observation
> granularity and cost `Codable` and value semantics. Keep the boundary at the rows.

### 1.3 `Identifiable` and id references

Every reference model and every collection-stored value type is `Identifiable` via `let id: String`
— Swift synthesizes `ID == String`. Write cross-references as the synthesized nested type, never bare
`String`:

```swift
var authorID: Author.ID        // Author.ID == String
var bookIDs:  [Book.ID]        // e.g. on a Shelf or a borrow record
```

`Book.ID` over `String` makes a reference's intent explicit and lets the compiler catch
argument-order mistakes. Seed ids are stable literals (`"book-dune"`, `"author-herbert"`) so previews
and tests hard-link to fixtures without going through `UUID()` (§5).

---

## 2. Logic on the models

Domain mutations live on the reference models as methods — Apple's "the model owns its behavior"
stance (WWDC24 *SwiftUI essentials*). Each is a **pure, synchronous, in-place** state transition:

```swift
@MainActor @Observable final class Book {
    func toggleFavorite() { isFavorite.toggle() }
    func markRead()       { status = .read }
    func toggleBorrowed() { isBorrowed.toggle() }   // used optimistically by AppStore.borrow (03)
}
```

What does **not** live on the model: anything needing the network or cross-entity state. The
optimistic-write-then-rollback dance and the `borrowedBooks` cross-entity mirror need
`api`/`writeError`/the mirror, so they stay as thin `AppStore` wrappers that call the model method and
then orchestrate (`03-store.md`). Rule of thumb: **pure state transition → model method; network +
cross-entity effects → `AppStore` wrapper.**

Computed *display* helpers may live on the model when they're pure functions of its fields and return
**data, not `View`s** (a model never imports SwiftUI):

```swift
extension Book {
    var isOverdue: Bool { /* given a due date and a `now` passed in — never reads Date() */ }
    var statusLabel: String { status == .read ? "Read" : status == .reading ? "Reading" : "Unread" }
}
```
Screen-specific derivation that needs SwiftUI/tokens belongs in a presenter, not here (`06-screens.md`).

---

## 3. Modeling state — enums, not boolean soup

### 3.1 Mutually-exclusive state is an enum
A field with several mutually-exclusive values is an enum, never a cluster of booleans:

```swift
enum ReadingStatus: String, Codable, Equatable, Hashable, Sendable {
    case unread, reading, read
}
```
A raw-value `String` enum synthesizes `Codable` for free. **Independent** flags
(`isBorrowed`, `isFavorite`) stay as separate `Bool`s — they're orthogonal, not mutually exclusive, so
they are not "boolean soup."

### 3.2 Associated-value enums (the manual `Codable` pattern)
When each case carries its own payload, use an associated-value enum. This is the one place `Codable`
is hand-written — a keyed container with an explicit `tag`:

```swift
enum Format: Equatable, Hashable, Sendable {
    case physical(callNumber: String)
    case ebook(sizeMB: Int)
    case audiobook(minutes: Int)
}

extension Format: Codable {
    private enum CodingKeys: String, CodingKey { case tag, callNumber, sizeMB, minutes }
    private enum Tag: String, Codable { case physical, ebook, audiobook }
    // encode/decode switch on `tag`, then read the case's payload key
}
```
Use this same tag-keyed shape for any associated-value enum. Types the stdlib doesn't make `Codable`
(e.g. `ClosedRange<Date>`) are stored as flat fields (two `Date`s) with a computed accessor — never
forced through a custom coder.

---

## 4. The wire/domain DTO split

The reference models can't be the network types (they're `@MainActor` and not `Codable`). The network
boundary uses **DTOs** — value-type mirrors in `Networking/Responses/DTO/`:

```swift
struct LibraryDTO: Codable, Equatable, Sendable { … }   // mirrors Library
struct BookDTO:    Codable, Equatable, Sendable { … }   // mirrors Book
```

DTOs reuse the leaf value types directly (a `BookDTO` holds the same `Author`/`Format`/`Rating` values
a `Book` does). Mapping is explicit and total:

- `extension BookDTO { @MainActor func toDomain() -> Book }` (and `LibraryDTO`) — builds the reference
  graph on the main actor.
- `extension Book { func toDTO() -> BookDTO }` (and `Library`) — snapshots the reference graph back to
  a value DTO. Used for rollback snapshots (§ `03`) and any request body that sends a book/library.

The round-trip invariant **`dto.toDomain().toDTO() == dto`** is unit-tested (`07-testing.md §4.2`) and
is what catches a field added to the model but not the DTO. **Only the DTOs and leaf value types are
`Codable`; the reference models are not.** JSON wire format and decoding are detailed in
`04-networking.md`.

> A `restore(from: BookDTO)` method on `Book` applies a value snapshot back onto the live reference,
> so a failed optimistic write can revert in place (the rollback path in `03-store.md`).

---

## 5. SampleData — the single source of all mock data

**`SampleData` is the one place mock data is defined.** Everything that needs fake data — Xcode
previews, unit/integration tests, and the `MockProvider` the running app talks to — gets it from here.
There is no inline-constructed data anywhere else (that's how fixtures drift). Each factory returns a
`SampleSeed`:

```swift
struct SampleSeed {
    var library: Library          // a live Library/Book reference graph
    var simulatedNow: Date        // fixed clock for time-conditional state (overdue, etc.)
    // add a field per new top-level domain the UI shows
}
```

### Named seed factories (one canonical + edge-state variants)

```swift
extension SampleData {
    static func library()      -> SampleSeed   // canonical, populated — the default everywhere
    static func emptyLibrary() -> SampleSeed   // 0 books — the empty state
    static func allBorrowed()  -> SampleSeed   // every book borrowed — the zero-available edge
}
```

Add a variant whenever a screen has a state worth previewing/testing. **These names are also the
`MockScenario` cases** (`04-networking.md §7`): `MockScenario.emptyLibrary` builds its `MockSeed` from
`SampleData.emptyLibrary().toDTO()`. One set of factories, used three ways:

| Consumer | How it gets the seed |
|---|---|
| **Xcode `#Preview`** | `AppStore.preview(SampleData.library())` — a fresh store seeded directly, no network (`03-store.md §4`, `06-screens.md §8`) |
| **Unit / integration tests** | `AppStore(api: .mock())` + `store.loadSeed(seed)` (`07-testing.md §3`) |
| **UI / E2E tests** | a `MockScenario` injected at launch → the real app boots, `loadLibrary()` hits `MockProvider`, which serves that variant's `MockSeed` (`07-testing.md §7`) |

### How the domain graph and the wire seed stay in lock-step

Each factory builds the **domain reference graph** — its `library` field is a live `Library`/`Book`
object tree — so it is `@MainActor` (it constructs `@MainActor` reference models). It performs no I/O
and is cheap to rebuild, so previews and tests call it freely from their `@MainActor` contexts. The
mock backend needs the same data as **DTOs**: the stateless `MockProvider` holds an immutable seed
snapshot built by snapshotting the matching factory's graph through `.toDTO()` — one seed, two
representations, kept in lock-step (`04-networking.md`).

All seed `id`s are literals (`"book-dune"`, `"author-herbert"`) so screens and tests hard-link to
fixtures without the random `UUID()` path. `simulatedNow` is pinned to a fixed instant so
time-conditional state (an overdue badge) is deterministic everywhere.

**Seeding convention (registry-as-files):** per-domain `make*` builders live in
`Models/SampleData+<Domain>.swift` extension files, so a new model's seed is a *new file*, not an edit
to the core composer. Core `SampleData.swift` keeps `library()` (the top-level composer) and the shared
substrate. **Rule:** every new model the UI shows must be seeded in `SampleData.library()` before it
can appear in a preview or test — inline-constructed model values bypass the seed, drift from the
canonical ids, and break other surfaces.

---

## 6. Dates & formatting

All date display goes through one `AppDate` enum in `DateFormatters.swift`, exposing pre-configured
`DateFormatter`s — pinned to a fixed time zone and `en_US_POSIX` locale — plus a component builder:

| Formatter | Format | Usage |
|---|---|---|
| `AppDate.dueDate` | `"MMM d"` | borrow due dates |
| `AppDate.full` | `"EEEE, MMM d"` | detail headers |
| `AppDate.make(y:m:d:)` | — | deterministic date construction (tests/seed) |

The formatters are lazy `static` properties — created once, reused; callers never spin up their own
`DateFormatter` for the same format. **Never call the live clock** anywhere in the model layer:
time-conditional logic (`Book.isOverdue`) takes a `now: Date` argument, supplied from the store's
`simulatedNow`. The pinned `simulatedNow` is a field on `AppStore`, not a model concept — see
`03-store.md`.

---

## See also

- `01-architecture.md` §6 — the layer-level summary of this split and the read/write traces
- `03-store.md` — `AppStore` ownership, command wrappers (optimistic + rollback), `simulatedNow`
- `04-networking.md` — DTO JSON wire format, `MockProvider` seeding, the one-file endpoint pattern
- `07-testing.md` §4 — model-method, DTO round-trip, and presenter unit tests
