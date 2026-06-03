# 04 — Networking

> Source of truth: `ios/AppTemplate/Networking/` — `APIClient.swift`, `APIClientProtocol.swift`,
> `APIRequest.swift`, `HTTPMethod.swift`, `APIError.swift`, `APIJSON` (in `APIClient.swift`),
> `MockProvider.swift`, `LiveProvider.swift`, `Requests/`, `Responses/DTO/`.

The networking layer has one job: hand `AppStore` value-type DTOs it can map to the domain graph, and
accept value-type bodies back. It is provider-swappable, protocol-driven, and adds an endpoint as *one
new file*. The DTO types and their mapping are `02-models.md §4`; the commands that call these requests
are `03-store.md`.

---

## 1. Provider-swappable boundary

Every screen and the store depend on **`APIClient`**. Nothing outside this folder imports or references
`MockProvider`/`LiveProvider`:

```
APIClientProtocol   (protocol — the whole API surface: one generic send)
       ├── MockProvider   (in-process fake — previews, UI tests, unit tests, on-device demo)
       └── LiveProvider   (URLSession HTTP — production)
APIClient               (final class wrapper — the only type the store/screens touch)
```

`APIClient` is a thin `final class` wrapper exposing one concrete type to the store/screens (so they
hold `let api: APIClient`, not `any APIClientProtocol`). Both providers are **value types** —
`MockProvider` is a stateless struct (§7) and `LiveProvider` wraps a `URLSession` — so there is no
shared mutable backend to coordinate. `APIClient` conforms to **plain `Sendable`, not `@unchecked`**:
its only stored property is an immutable `let impl: any APIClientProtocol`, and `APIClientProtocol`
refines `Sendable`, so the compiler verifies it (`01-architecture.md §9`). (A struct wrapper would work
too now that providers are value types; the class is kept for a stable single handle and is just as
safe.)

### Factory methods

```swift
extension APIClient {
    static let live: APIClient                                   // default production client (reads config)
    static func live(baseURL: URL,
                     authProvider: @escaping @Sendable () async -> String?) -> APIClient
    static func mock(scenario: MockScenario = .standard,
                     failureRate: Double = 0) -> APIClient        // wraps MockProvider
}
```
Call sites read `AppStore(api: .live)` or `AppStore(api: .mock())` — the concrete provider is invisible,
and swapping mock → live (or scenario → scenario) happens only at the `AppStore` init boundary
(`03-store.md`).

> **Why the fake lives at the network seam (not the store).** A decided, deliberate choice: because
> the mock is a *failable, delayable backend*, it is the only thing that lets us test the failure modes
> the prior app shipped blind to — **loading states, the write-error banner, optimistic-update
> rollback, and offline** (`failureRate`/`mockLatency`, §7; the rollback test in `07-testing.md §5.1`).
> Seeding `AppStore` directly would make those paths untestable and the optimistic-write/`restore(from:)`
> machinery vestigial. The DTO boundary (§3) is not mock ceremony either — `@MainActor @Observable`
> models can't be `Codable`/`Sendable`, so DTOs are required the moment any real backend or persistence
> exists, and `toDTO()` is also what produces the rollback snapshot. The mock itself is **stateless**
> (an immutable DTO seed snapshot, §7) — it persists no mutations, because the client applies writes
> optimistically against a single-session `AppStore` and never re-fetches to observe its own write.
> That keeps all the failure-path testability with none of the actor/seeding machinery.

---

## 2. The protocol — one generic method

`APIClientProtocol` is `Sendable` and has exactly one method; each endpoint is a `Request` struct that
carries its own wire description *and* mock behavior:

```swift
protocol APIClientProtocol: Sendable {
    nonisolated func send<R: APIRequest>(_ request: R) async throws -> R.Response
}

protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable
    nonisolated var path: String { get }
    nonisolated var method: HTTPMethod { get }                 // no default — the verb prefix and method must agree
    nonisolated var queryItems: [String: String] { get }        // default [:]
    nonisolated var body: (any Encodable & Sendable)? { get }    // default nil
    nonisolated var mockLatency: Duration { get }                // default .zero
    nonisolated func mockResponse(from seed: MockSeed) throws -> Response   // pure: computes from the immutable seed
}
```

> ### ⚠️ The wire boundary is `nonisolated` — not just `Sendable` (the single most-repeated build break)
> The project is **MainActor-by-default** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `01-architecture.md
> §9`), so *every* type, protocol, and protocol requirement is MainActor-isolated **unless you mark it
> otherwise**. `Sendable` alone does **not** opt a declaration out of the actor — it only says the value is
> safe to pass. Because `LiveProvider.send` decodes **off the main actor** (`@concurrent`), every
> declaration it touches on that path must be explicitly **`nonisolated`**, or the compiler rejects the
> mismatch — and it fails at the *use site* (the off-main decode), so each layer breaks independently:
>
> | Mark `nonisolated` | Why |
> |---|---|
> | every **`APIRequest` protocol requirement** (`var path`, `method`, `queryItems`, `body`, `mockLatency`, `func mockResponse`) — and the same default-impl members in the `extension` | the requirements are read from the nonisolated `send` |
> | `APIClientProtocol.send` | it's the `@concurrent` entry point |
> | every **request struct** — `nonisolated struct GetXRequest: APIRequest` | its conformance must satisfy the nonisolated requirements |
> | every **DTO and every leaf value type it composes** (`Codable`) — see `02-models.md §9` | `Response: Decodable & Sendable` is decoded off-main; a MainActor-isolated `Decodable` conformance can't satisfy it |
> | `LiveProvider`, and the JSON codec helper (`nonisolated enum APIJSON`) | they run the off-main build/decode |
>
> The `@MainActor func toDomain()` mapping (built on the main actor) and the providers' `Sendable`
> conformance **stay** — only the wire-path declarations opt out of the default actor. Rule of thumb: *if it
> crosses to the background, it carries the `nonisolated` keyword; `Sendable` is necessary but not
> sufficient.*

`MockProvider` and `LiveProvider` are **generic shells** that dispatch on the request — they hold no
per-endpoint code. `MockProvider.send` injects failure / sleeps `mockLatency`, then calls
`request.mockResponse(from: seed)` (synchronous — the seed is an immutable value, §7). `LiveProvider
.send` is an **`@concurrent`** async method (the project is MainActor-by-default, `01-architecture.md
§9`) so the `URLRequest` build → network call → JSON decode runs off the main actor; the decoded
`R.Response` (a `Sendable` DTO) crosses back, and `AppStore` maps `toDomain()` on the main actor.

### Adding an endpoint — the one-file rule

A new endpoint is **one new file** `Networking/Requests/<Verb><Name>Request.swift`:

```swift
nonisolated struct GetLibraryRequest: APIRequest {     // nonisolated — it crosses the wire (see callout above)
    typealias Response = LibraryDTO
    var path: String { "/library" }
    var method: HTTPMethod { .get }
    func mockResponse(from seed: MockSeed) throws -> LibraryDTO {
        seed.library
    }
}

nonisolated struct BorrowBookRequest: APIRequest {
    let id: Book.ID
    typealias Response = BookDTO
    var path: String { "/books/\(id)/borrow" }
    var method: HTTPMethod { .post }
    func mockResponse(from seed: MockSeed) throws -> BookDTO {
        guard var book = seed.library.books.first(where: { $0.id == id }) else { throw APIError.http(status: 404, body: nil) }
        book.isBorrowed = true                       // computed from the immutable seed; not persisted
        return book
    }
}
```

**Do NOT edit `APIClient`, `MockProvider`, or `LiveProvider`** — they need no per-endpoint code. This
is what lets parallel scaffolders add endpoints simultaneously without colliding (`01-architecture.md
§11`). **Naming:** `<Verb><Name>Request`, Verb ∈ `Get`/`Post`/`Patch`/`Delete`; the prefix and `method`
must agree.

---

## 3. Domain models never cross the wire — the DTO boundary

`APIRequest.Response` is `Decodable & Sendable`. The domain reference models (`Library`, `Book`) are
`@MainActor`-isolated and **not** `Codable`, so they satisfy neither half — decoding happens off the
main actor. **The wire types are value-type DTOs:**

- DTOs live in `Networking/Responses/DTO/` — `nonisolated struct LibraryDTO`, `BookDTO` (`Codable,
  Equatable, Sendable`), field-for-field mirrors. **They — and every leaf value type they compose
  (`Author`, `Format`, `Rating`, `BookDetail`) — are `nonisolated`** (see the §2 callout + `02-models.md
  §9`): their `Codable` conformance is exercised off-main, which a MainActor-isolated type can't satisfy.
- Every request/response that represents a `Library`/`Book` uses the DTO: `GetLibraryRequest.Response`
  is `LibraryDTO`; `BorrowBookRequest.Response` is `BookDTO`.
- **Mapping is the caller's job, on the main actor — not the provider's.** `AppStore` maps after the
  `await`:
  ```swift
  let dto = try await api.send(GetLibraryRequest())   // LibraryDTO — decoded off-actor
  library = dto.toDomain()                             // built on MainActor
  ```
  The reverse (`book.toDTO()`) produces request bodies and rollback snapshots; the round-trip
  `dto.toDomain().toDTO() == dto` is unit-tested (`07-testing.md §4.2`).

This keeps the providers ignorant of the domain graph and keeps `Decodable & Sendable` honest.

---

## 4. Path & method conventions

Write `var path: String` against these rules:
- **Resources are pluralized** — `/books`, `/authors`, `/library`.
- **Actions on a resource are verbs hung off it** — `/books/{id}/borrow`, `/books/{id}/return`.
- **Filters/search are query items, not path segments** — `GET /books` with `queryItems = ["q": term]`.

```swift
// GetLibraryRequest      GET   /library
// GetBookRequest         GET   /books/{id}
// BorrowBookRequest      POST  /books/{id}/borrow
// ReturnBookRequest      POST  /books/{id}/return
// SetRatingRequest       PATCH /books/{id}
// SearchBooksRequest     GET   /books            queryItems ["q": term]
```

| Method | Example requests |
|---|---|
| `GET` | `GetLibraryRequest`, `GetBookRequest`, `SearchBooksRequest` |
| `POST` | `BorrowBookRequest`, `ReturnBookRequest` |
| `PATCH` | `SetRatingRequest` |
| `DELETE` | (none in the slice) |

`HTTPMethod` is a small enum in `Networking/HTTPMethod.swift` (`get`/`post`/`patch`/`delete`).

---

## 5. JSON encoding & decoding

`APIJSON` is a caseless enum (namespace) vending configured coders; `LiveProvider` and tests use these
factories:

```swift
enum APIJSON {
    static func encoder() -> JSONEncoder   // .convertToSnakeCase, .iso8601
    static func decoder() -> JSONDecoder   // .convertFromSnakeCase, .iso8601
}
```

| Setting | Encoder | Decoder |
|---|---|---|
| Key strategy | `.convertToSnakeCase` | `.convertFromSnakeCase` |
| Date strategy | `.iso8601` | `.iso8601` |

All `Request` bodies and `Response`/DTO types use Swift camelCase property names; the coder handles the
wire translation. **Caveat for tests:** `.convertToSnakeCase`/`.convertFromSnakeCase` is *asymmetric* on
acronym/ID keys (`bookID` → `book_id` → `bookId`), so symmetric round-trip tests use a plain
`JSONEncoder`/`JSONDecoder`, never `APIJSON` (`07-testing.md §4.2`). The reference models are
deliberately not `Codable`; responses representing them use the `*DTO`s (§3).

---

## 6. Error surface

`APIError` is the closed error type thrown by `send`. Call sites never see raw `URLError`/`DecodingError`
— `LiveProvider` maps every failure before it propagates:

```swift
enum APIError: Error, LocalizedError, Sendable {
    case transport(Error)                         // DNS, connection refused, TLS
    case http(status: Int, body: ErrorEnvelope?)  // non-2xx
    case decoding(Error)                          // 2xx but payload failed to decode
    case offline                                  // URLError.notConnectedToInternet
    case unauthorized                             // 401 / 403
    case rateLimited(retryAfter: TimeInterval?)   // 429; parses Retry-After
}

struct ErrorEnvelope: Codable, Sendable { let code: String; let message: String; let details: [String: String]? }
```

Mapping in `LiveProvider.send`: `.notConnectedToInternet` → `.offline`; other URLSession error →
`.transport`; 2xx decode failure → `.decoding`; 401/403 → `.unauthorized`; 429 → `.rateLimited`; other
non-2xx → `.http(status:body:)`. `MockProvider` surfaces `.http(404, …)` for a missing entity, keeping
the mock honest about the contract. The store catches `APIError` in its write path and sets
`writeError` (`03-store.md`); the view surfaces it as a banner (no toasts).

---

## 7. MockProvider & scenarios

`MockProvider` is a **stateless value type** — the in-process backend with no persisted mutable state.
It holds an **immutable DTO seed snapshot** (`MockSeed`, a `Sendable` value of `*DTO`s — never the
`@MainActor` reference models) plus the two behavior knobs:

```swift
nonisolated struct MockSeed: Sendable { var library: LibraryDTO /* + a field per top-level entity */ }

nonisolated struct MockProvider: APIClientProtocol {   // nonisolated value type → Sendable; no actor, no @unchecked
    let seed: MockSeed
    let failureRate: Double
    let latency: Duration

    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        if failureRate > 0, Double.random(in: 0..<1) < failureRate { throw Self.randomError() }
        if latency > .zero { try await Task.sleep(for: latency) }
        return try request.mockResponse(from: seed)        // pure, synchronous
    }
}
```

**Why no `MockStore` actor.** The earlier design used a stateful actor that persisted mutations and
lazily seeded itself on first use (to dodge a `MainActor.assumeIsolated`-traps-off-main crash — a real
bug from the prior app). It isn't needed: writes are applied **optimistically on the client** against a
single-session `AppStore` that never re-fetches to observe its own write, so a persistent fake backend
buys nothing here. An immutable value seed is `Sendable` with nothing to synchronize and nothing to
seed lazily — the whole actor/seeding bug class disappears. The seed is built once by snapshotting a
`SampleData.library()` graph through `.toDTO()` (`02-models.md §5`). **Escalate to a stateful
`MockStore` only if a future flow needs write-then-read-back fidelity** (multi-step generative flows,
etc.).

Two knobs select behavior, set at the `AppStore` init boundary (and driven by launch args in UI tests,
`07-testing.md §7`):

```swift
enum MockScenario: String, Sendable {
    case standard       // SampleData.library() — the default
    case emptyLibrary   // 0 books — exercises the empty state
    case allBorrowed    // every book borrowed — exercises the zero-available state
}
```
- **`scenario`** picks which `SampleData` seed variant is snapshotted into the `MockSeed`.
- **`failureRate: Double`** (0…1) injects random `APIError`s on each call from a fixed pool
  (`.offline`, `.http(500, …)`, `.rateLimited(retryAfter: 5)`, `.transport(…)`) — drives the write-error
  and offline paths in tests.
- **`latency: Duration`** delays responses so loading states are exercisable.

Generative/slow endpoints set `mockLatency` (e.g. `.milliseconds(800)`) so loading states are
exercised; the default is `.zero` for snappy tests.

---

## Quick reference

| Want to… | Touch |
|---|---|
| Add an endpoint | one new `Networking/Requests/<Verb><Name>Request.swift` conforming to `APIRequest` |
| Change wire encoding | `APIJSON.encoder()` / `.decoder()` in `APIClient.swift` |
| Add a mock scenario | a `MockScenario` case + its `SampleData` seed variant |
| Simulate failures | `APIClient.mock(failureRate:)` |
| Read an error in UI | switch on `APIError` (each case has a `LocalizedError` description) — surfaced via `writeError` |
| Add an HTTP method | the `HTTPMethod` enum |

## See also

- `02-models.md` §4 — DTO mirrors, `toDomain()`/`toDTO()`, the round-trip invariant
- `03-store.md` §3–4 — the commands that send these requests; optimistic write + rollback; hydration
- `07-testing.md` §5, §7 — integration tests through `MockProvider`; launch-arg scenario injection
- `01-architecture.md` §7 — the layer-level summary; §9 — why `APIClient` is plain `Sendable`
