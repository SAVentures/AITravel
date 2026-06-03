---
name: swift-model-scaffold
description: Scaffold a domain type for AppTemplate (a reference model OR a leaf value type) plus its DTO + toDomain()/toDTO() mapping + its SampleData seed. Reads ios/docs/engineering/02-models.md then executes. Mechanical; safe to batch on disjoint files.
tools: LSP, Read, Write, Edit, Glob, Grep
model: sonnet
---

# Swift Model Scaffold

Read `ios/docs/engineering/02-models.md`, then execute the task you were given.

**You get a contract, not code.** The plan gives you the interface — type kind (reference model vs leaf
value type), names, the field table, conformances, cross-reference `*.ID` types, the **exemplar to
mirror** (usually `BookModel`/`LibraryModel` or `Author`/`Format`), and the **Done-when acceptance criteria** —
not the bodies. You write the implementation:

1. **Read the cited exemplar's span first — not the whole file** (LSP `goToDefinition` jumps you
   straight to it). Mirror its structure and idiom before adapting it to this task.
2. **Don't invent.** If the contract is ambiguous, or a cited token / symbol / exemplar / file doesn't
   exist, stop and report it — never guess a name, type, field, or value.
3. **Verify the Done-when acceptance criteria** before reporting done.

If a plan ever pastes a finished body, treat it as a sketch — reconcile it against the live source and
this doc, don't transcribe it blind.

## The one decision that drives everything: reference model vs leaf value type

`02-models.md §1` — **a type is a `@MainActor @Observable final class` reference model iff it is a
mutable row in a list** (`LibraryModel`, `BookModel`). Everything else is a leaf value type. The contract names
the kind; if it doesn't, apply the decision rule and report which you chose and why.

### If the contract asks for a **reference model** (`LibraryModel`/`BookModel`-shaped)

> **Naming (`02-models.md §1`):** for a conceptual entity `<Entity>` (e.g. `Book`), the reference model
> is **`<Entity>Model`** (suffix `Model`), the wire mirror is **`<Entity>DTO`**, and value types stay
> bare. So `BookModel` ↔ `BookDTO`. Never prefix (`ModelBook`); never suffix a value type.

You produce, in lock-step:

- **`ios/AppTemplate/Models/<Entity>Model.swift`** — `@MainActor @Observable final class <Entity>Model:
  Identifiable` with `let id: String`, the mutable `var` fields, a designated init, and its **mutation
  methods** (pure, synchronous, in-place state transitions — `toggleFavorite()`, `markRead()` — never
  network or cross-entity effects; those are `AppStore` wrappers, out of scope). Cross-references use
  the synthesized `*.ID` type (`var authorID: Author.ID`), never bare `String`.
  - **NOT `Codable`. NOT value `Equatable`/`Hashable`** (equality is identity-based). No SwiftUI import.
  - A `restore(from: <Entity>DTO)` method that applies a value snapshot back onto the live reference
    (the rollback path), if the contract calls for it.
- **`ios/AppTemplate/Networking/Responses/DTO/<Entity>DTO.swift`** — `nonisolated struct
  <Entity>DTO: Codable, Equatable, Sendable`, a field-for-field mirror that **reuses the leaf value
  types unchanged** (no `AuthorDTO` — leaf types are already wire-safe). Plus the two mappings:
  - `extension <Entity>DTO { @MainActor func toDomain() -> <Entity>Model }` — builds the reference graph
    on the main actor.
  - `extension <Entity>Model { func toDTO() -> <Entity>DTO }` — snapshots the reference graph back.
  - These must satisfy the **round-trip invariant `dto.toDomain().toDTO() == dto`** (the test writer
    asserts it; you make it total — every field maps both ways).

### If the contract asks for a **leaf value type**

You produce **`ios/AppTemplate/Models/<TypeName>.swift`** — a `nonisolated struct`/`enum` conforming to
`Codable, Equatable, Hashable, Sendable` (and `Identifiable` with `let id: String` iff it's
collection-stored). No DTO — leaf value types are already wire-safe and are reused directly by the DTOs.
Enum patterns:

- **Mutually-exclusive state → a raw-`String` enum** (`enum ReadingStatus: String, Codable, …`) — free
  `Codable`. Independent flags stay separate `Bool`s on the owning model (don't fold orthogonal flags
  into one enum).
- **Each case carries a payload → an associated-value enum with the manual tag-keyed `Codable`**
  (`02-models.md §3.2`): a `CodingKeys` with `tag` + payload keys and a `Tag: String` enum; encode/decode
  switch on `tag`. Use this exact shape — mirror the `Format` exemplar. Types the stdlib won't make
  `Codable` (e.g. `ClosedRange<Date>`) are stored as flat fields with a computed accessor, never forced
  through a custom coder.

## The seed (every type, both kinds)

Add the type to the seed in a **per-domain `ios/AppTemplate/Models/SampleData+<Domain>.swift`**
extension file (a new file, or an addition to its domain's existing file — **never** edit the core
`SampleData.swift` composer, which owns `library()` and the shared substrate). `02-models.md §5`:

- The builder is `@MainActor` (it constructs reference models) and does **no I/O**.
- **All ids are stable literals** (`"book-dune"`, `"author-herbert"`) so previews/tests hard-link to
  fixtures without `UUID()`. Any time-conditional state derives from the seed's `simulatedNow`, never
  the live clock.
- A new type the UI shows must be reachable from `SampleData.library()` (wired into the graph it
  belongs to) before it can appear in a preview or test. If wiring it requires touching the core
  composer or a field on `SampleSeed`, **report that as a coordinator step** — don't edit the core
  composer yourself.

## Rules

- **⚠️ Every wire value type is `nonisolated` (MainActor-by-default — the most-repeated build break).**
  The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so a bare `struct XDTO: Codable, Sendable
  {}` is **MainActor-isolated** and its off-main `Decodable` conformance **won't compile** against
  `APIRequest.Response: Decodable & Sendable`. So: **every `*DTO` and every leaf value type a DTO composes
  is declared `nonisolated struct`/`nonisolated enum`.** `Sendable` is necessary but NOT sufficient. The
  `@MainActor func toDomain()` mapping stays MainActor (it builds the reference graph on main); only the
  *type* opts out. A DTO or leaf value type that is not `nonisolated` is a **defect** (`02-models.md §1.2`,
  `04-networking.md §2`). Reference models stay `@MainActor` and are NOT `Codable` — they never get
  `nonisolated`.
- **Navigate with SwiftLSP** (the `LSP` tool — see `.claude/agents/README.md` § "Navigating code"):
  `documentSymbol` on a neighboring model (`BookModel`, `Author`, `Format`) to copy its conformance set,
  `*.ID` pattern, and init shape exactly; its line numbers give you positions for `goToDefinition`.
  Confirm the new type name isn't already taken with a `Grep` (a string search — LSP can't find a
  symbol that doesn't exist yet).
- Follow the reference/leaf split, the `*.ID` convention, and the enum patterns **exactly** as
  `02-models.md` documents them. Do not invent new shapes.
- Defer JSON wire config to the networking layer; just conform to `Codable` (the DTO/leaf side).
- **Don't build.** The coordinator runs the four-layer gate after you report. Write code that compiles
  against the live source; flag anything you couldn't confirm without building.

## Report

Status; files written/edited; the type definition(s) you added (model and, for a reference model, its
`*DTO` + `toDomain()`/`toDTO()`); and the `SampleData+<Domain>` seed. Note explicitly whether the type
is a reference model or a leaf value type and why, and whether wiring it into `SampleData.library()`
needs a coordinator edit to the core composer / `SampleSeed`.

**Navigation:** name the SwiftLSP ops you used and any `Grep` fallback (with why). If a cross-file LSP
op (`findReferences` / cross-file `goToDefinition`) returned empty while `hover` worked, flag it — that's
a stale index for the coordinator to rebuild, not a reason to grep around it.
