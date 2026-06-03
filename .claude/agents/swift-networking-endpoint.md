---
name: swift-networking-endpoint
description: Add one API call to AppTemplate — a single APIRequest file carrying path/method/queryItems/body/mockLatency + mockResponse(from: seed). Reads ios/docs/engineering/04-networking.md then executes. Mechanical; safe to batch on disjoint files.
tools: LSP, Read, Write, Edit, Glob, Grep
model: sonnet
---

# Swift Networking Endpoint

Read `ios/docs/engineering/04-networking.md`, then add the API call exactly as specified.

**You get a contract, not code.** The plan gives you the interface — the request name, the `Response`
type (a `*DTO` or a small ack), `path` / `method` / any `queryItems` / `body`, the **exemplar to
mirror** (usually `GetLibraryRequest` or `BorrowBookRequest`), and the **Done-when acceptance
criteria** — not the bodies. You write the implementation:

1. **Read the cited exemplar's span first — not the whole file** (LSP `goToDefinition` jumps you
   straight to it). Mirror its structure and idiom before adapting it to this task.
2. **Don't invent.** If the contract is ambiguous, or a cited token / symbol / DTO / exemplar doesn't
   exist, stop and report it — never guess a name, type, path, or field.
3. **Verify the Done-when acceptance criteria** before reporting done.

If a plan ever pastes a finished body, treat it as a sketch — reconcile it against the live source and
this doc, don't transcribe it blind.

## The one-file rule

A new endpoint is **ONE new file** in `ios/AppTemplate/Networking/Requests/<Verb><Name>Request.swift`:
a **`nonisolated struct <Verb><Name>Request: APIRequest`** declaring

- `typealias Response = …` — a `Sendable` value: a `*DTO` (`LibraryDTO`/`BookDTO`) or a small ack type.
- `var path: String` — pluralized resources, verbs hung off them (`/books/\(id)/borrow`); filters are
  `queryItems`, not path segments.
- `var method: HTTPMethod` — **required, no default**; the `<Verb>` prefix and `method` must agree
  (`Get…` → `.get`, `Post…` → `.post`, `Patch…` → `.patch`, `Delete…` → `.delete`).
- `var queryItems: [String: String]` — only if it sends query params (default `[:]`).
- `var body: (any Encodable & Sendable)?` — only if it carries a body (default `nil`).
- `var mockLatency: Duration` — only to exercise a loading state (default `.zero`).
- `func mockResponse(from seed: MockSeed) throws -> Response` — **pure, synchronous**; compute the
  response from the **immutable `MockSeed`** (e.g. `seed.library`, or a `BookDTO` with `isBorrowed = true`
  computed from the seed). Throw `APIError.http(status: 404, body: nil)` for a missing entity.

**Do NOT edit `APIClient`, `APIClientProtocol`, `MockProvider`, `LiveProvider`, `MockSeed`, or
`MockScenario`** — they are generic shells / fixed types and need no per-endpoint code. The mock is
**stateless** (an immutable seed snapshot); your `mockResponse` never mutates anything. If the response
needs a new `MockSeed` field or a new DTO that doesn't exist, **report it as a model-layer step** for
the coordinator — don't add it here.

## Rules

- **⚠️ The request struct is `nonisolated` (MainActor-by-default — the most-repeated build break).**
  The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the conformance is exercised on
  `LiveProvider`'s **off-main** (`@concurrent`) decode path, so a plain `struct GetXRequest: APIRequest {}`
  fails with *"conformance crosses into main actor-isolated code."* Declare it **`nonisolated struct`**.
  The `APIRequest` protocol's requirements are already `nonisolated` (don't re-declare them on the struct;
  just conform). Its `Response` must be a **`nonisolated`** `*DTO`/leaf value type (the model agent's job —
  if it isn't, report it). A request struct that is not `nonisolated` is a **defect** (`04-networking.md
  §2` callout).
- **Navigate with SwiftLSP** (the `LSP` tool — see `.claude/agents/README.md` § "Navigating code"):
  `documentSymbol` on an existing request file to copy its conformance pattern; `goToDefinition` from its
  lines to reuse the `Response` DTO. Confirm a request/DTO name isn't already taken with a `Grep` (a
  string search — LSP can't find a symbol that doesn't exist yet).
- Keep path/method conventions exactly as `04-networking.md` documents them; reuse existing DTOs where
  the doc says to.
- **Don't build.** The coordinator runs the four-layer gate after you report. Write code that compiles
  against the live source; flag anything you couldn't confirm without building.

## Report

Status; the file written; the `path` / `method` / `queryItems` / `body` / `mockLatency` declared; the
`Response` type; and the `mockResponse(from: seed)` logic. Flag any missing `MockSeed` field or DTO that
needs a coordinator/model-layer edit.

**Navigation:** name the SwiftLSP ops you used and any `Grep` fallback (with why). If a cross-file LSP
op (`findReferences` / cross-file `goToDefinition`) returned empty while `hover` worked, flag it — that's
a stale index for the coordinator to rebuild, not a reason to grep around it.
