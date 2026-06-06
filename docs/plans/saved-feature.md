# Saved (saved places) — contract-level implementation plan

The first post-onboarding app surface: a full vertical slice (models → networking → design-system →
store → screens → 4-layer tests) for the **Saved** tab. Built through the agent pipeline in the
`saved` worktree. Every path below is worktree-absolute under
`/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/saved/`.

> **Exemplar to mirror throughout:** the onboarding slice (the library/book reference slice has been
> swapped out). Models → `ios/AppTemplate/Models/City.swift`, `TripDraftModel.swift`. Networking →
> `Networking/Requests/GetOnboardingContextRequest.swift`, `Responses/DTO/OnboardingContextDTO.swift`,
> `MockSeed.swift`, `MockScenario.swift`. Store → `Store/AppStore.swift`, `AppStore+Onboarding.swift`.
> Screens → `Screens/Onboarding/DestinationStepView.swift` + `DestinationStepPresenter.swift`.
> Design system → `DesignSystem/Components/{PlaceCard,FilterChip,Tag,SearchWell,EmptyStateView,SegmentedSelector}.swift`,
> `Composition/ScreenScaffold.swift`.

---

## 0. Substrate findings (read before scoping) — Saved is the first *tab*

The onboarding slice exists, but the **tab IA does not**. Confirmed via LSP/grep:

- `AppStore` has **no** `selectedTab` / `AppTab` / per-tab `NavigationPath` / `push`/`pop`/`popToRoot`.
  `RootView` is a placeholder + onboarding `.fullScreenCover` only; **no `TabView`**.
- There is **no `ScreenCatalogView`** and no `Screens/Catalog/`.
- `MockSeed` has only `onboardingContext`; `MockScenario` has only `.empty`/`.onboardingA/B/C`.
- `SampleData.seed(for:)` switches only those scenarios.

So Saved cannot assume the substrate `06-screens.md §5/§7` and `03-store.md §2` describe. **Wave 0**
below establishes the minimum tab + navigation + catalog substrate Saved (and every later tab) needs.
This is the "first feature → bootstrap the skeleton" rule applied to the *navigation* substrate (the
networking/store/sampledata substrate already exists from onboarding).

The networking core (`APIClient`/`APIClientProtocol`/`MockProvider`/`LiveProvider`/`APIError`/
`HTTPMethod`/`APIJSON`), the store core (`AppStore`/`LoadState`/`preview`), and `SampleData` + `AppDate`
**already exist** — reuse them; do not re-scaffold.

---

## Reuse-vs-new ledger (resolve duplication up front)

### Models — REUSE
- **`City`** (`Models/City.swift`) — a place's city. Reused directly as a leaf value type and at the
  wire (no per-leaf DTO), exactly as onboarding does.
- Saved places reference a city by name (the mockup shows `"Príncipe Real · Lisbon"`); the
  neighborhood is free text on the place, not the onboarding `Neighborhood` (which carries reach data).
  Do **not** reuse `Neighborhood`/`BaseLocation` — different concern.

### Models — NEW
- `SavedPlaceModel` (reference model — the mutable list row), `PlaceDTO`, and the leaf value types
  `PlaceCategory`, `PlaceSource` (associated-value enum), `PlaceProvenance`, `PlaceFacts`,
  `PlaceLocation`; the `SavedPlacesModel` container reference model; `SavedPlacesDTO`. (Tasks 1.1–1.2.)

### Design-system components — REUSE
- **`SearchWell`** — the fuzzy-search field (`.sav-search`). Already caller-owns-id; reuse verbatim.
- **`EmptyStateView`** — its existing fixture literally targets "No saved places…". Reuse for the
  zero-results case; the **rich empty-state** (`saved-empty.html`, three "ways to save" rows) is a
  *different, richer* layout → see NEW `WayToSaveRow`.
- **`FilterChip`** — the category filter pills (`.sav-pills .chip`, with a trailing count). Reuse;
  the count is rendered by the screen as part of the label, or via a small extension (Task 2.2 note).
- **`SegmentedSelector`** — the `By category` / `By source` toggle (`.seg`). Reuse (2-way).
- **`Tag`** — small caps capsule; reuse for the source-stamp timestamp pill if needed.
- **`PillButton`** — the add-place method rows' CTA / detail "Add to a trip" CTA tier.
- **`GlassCircleButton`** — the top-bar "+" add affordance and the detail back/save glyphs.
- **`ScreenScaffold` / `ScreenSection` / `RhythmSpacer` / `ActionBar`** — composition primitives.

### Design-system components — NEW (Task batch 0.A, behind the mini-freeze)
- **`PlaceRow`** — the horizontal wishlist row (`.pl`): thumb (with `src-badge` provenance stamp) +
  name/meta/source + trailing chevron or category chip. **This is NOT `PlaceCard`** — `PlaceCard` is
  the onboarding vertical definitive/fuzzy itinerary card. Different anatomy → new component.
- **`SourceCard`** — the "by source" expandable card (`.srccard`): icon-by-source + title/meta + count
  pill + caret; expanded body lists child `SourcePlaceRow`s + a foot hint. (Disclosure state is
  caller-owned ephemeral `@State`, like `SegmentedSelector` selection.)
- **`SourcePlaceRow`** — the compact child row inside an expanded `SourceCard` (`.src-place`): smaller
  thumb + name + meta-with-stamp + chevron.
- **`CategoryChip`** — the read-only tinted category label (`.pl-cat` / `.pd-kicker .pl-cat`): a mono
  caps label on a low-alpha category tint. (Distinct from interactive `FilterChip`.)
- **`WayToSaveRow`** — the rich empty-state / add-sheet method row (`.way` / `.method`): leading glyph
  tile + title/subtitle + chevron. One component serves both `saved-empty.html` and `add-place.html`.
- **`ProvenanceCard`** — the place-detail "Saved from" card (`.prov`): source thumb + who/meta + View
  button + an italic display-face quote.
- **`PlaceInfoGrid`** — the detail 3-cell facts grid (`.info-grid`): Hours / Price / Cuisine.
- **`MapSnippet`** — the detail static map well + address + Directions affordance (`.map-snip`). (Static
  placeholder canvas, like `BaseMapCard`'s placeholder treatment — no live MapKit this milestone;
  mirror `BaseMapCard.swift`.)

### Tokens — NEW (Task 0.A0, the only token edit — design-review point)
- `ColorRole.categoryEat/Drink/Stay/Do/Shop` (mark colors aliasing `Primitive.day2/day1/day3/day4` +
  an ink for Shop) **and** a `categoryTint(_:)` helper returning the low-alpha background the mockup's
  `.cat-*` uses (≈13% of the mark). **DECISION FLAG D-1** (below): the mockup uses day-mark hues as a
  *tinted fill* behind the category label, but `ColorRole` today documents `dayMark*` as "marks, not
  fills" (J-2). Either (a) add `category*` + `categoryTint` semantic roles (recommended — names the
  intent, keeps it ≤ a small chip, not a card fill), or (b) render categories ink-only. Resolve before
  Task 0.A0 lands. Primitives already exist in `foundations.css` (`--day-1..4`, `--accent-50/700` for
  the source stamp) — **no `foundations.css` edit and no codegen run is required**; this is a
  hand-authored *semantic*-tier addition only.

---

## Phase ordering (the mandatory pipeline) — with the mini-freeze barrier

```
Wave 0  — navigation/tab substrate + catalog        [SERIAL: AppStore.swift, RootView.swift, new ScreenCatalogView.swift]
   │     (Saved is the first tab — no TabView/paths/catalog exist yet)
   ▼
Wave 0.A — NEW design-system tokens + components     [batchable: each new file disjoint]
   │        → swift-design-system per task
   │        → design-reviewer mini-pass (semantic-only, Dynamic Type, glass-on-chrome-only, slop)
   │        → snapshot-lock each new component (incl. AX5 variant for type-dense rows)
   ══════════ MINI-FREEZE ══════════  (foundation already frozen from prior tracks; these EXTEND it.
   │                                   No Saved SCREEN task dispatches until 0.A is reviewed + snapshot-locked.)
   ▼
Wave 1  — models + networking + sample data + seed   [batchable, disjoint EXCEPT the 3 serial edits flagged]
   ▼
Wave 2  — store command + load state (AppStore+Saved) [SERIAL: AppStore.swift property; +Saved.swift is a new file]
   ▼
Wave 3  — screens (each: scaffold → swift-code-reviewer → fidelity-reviewer vs named mockup)
   │        SavedListView · PlaceDetailView · AddPlaceSheet      [each new files; ScreenCatalog + Routes serialized]
   ▼
Wave 4  — tests (4 layers)                           [batchable by target/file]
   ▼
GATE    — build + ios-test-coverage-check (incl. a11y-ownership lint) + swift-code-reviewer + design-reviewer slop pass
```

**Serial-edit files (coordinator must serialize):** `Store/AppStore.swift` (feature-state property +
tab/nav seams), `App/RootView.swift` (TabView), the new `Screens/Catalog/ScreenCatalogView.swift`
(brand-new section file edits are isolated, but the core view is one file), `MockSeed.swift` +
`MockScenario.swift` + `SampleData.swift` (each touched by extension where possible, but the
`seed(for:)` switch and the `MockScenario` enum are single files → serialize those three), and the
`.pbxproj` (every new file → serialize membership edits).

---

## Wave 0 — navigation/tab substrate + catalog

### Task 0.1 — Tab IA + navigation on AppStore  · `swift-screen-builder` (architecture-tier)
**Files (SERIAL):** `ios/AppTemplate/Store/AppStore.swift` (edit — add nav state + seams),
new `ios/AppTemplate/Store/AppStore+Navigation.swift` (push/pop/popToRoot + `mutateActivePath`),
new `ios/AppTemplate/Models/AppTab.swift` (leaf enum).
- `enum AppTab: String, CaseIterable, Sendable { case trip, map, saved, you }` — the four tabs in the
  mockup tab bar; `saved` is this slice's home. Each has `title`, `systemImage`, `accessibilityID`
  (`tab.trip`/`tab.map`/`tab.saved`/`tab.you`).
- On `AppStore`: `var selectedTab: AppTab = .saved` (Saved is the only built tab this milestone);
  one `NavigationPath` per tab (`tripPath/mapPath/savedPath/youPath`); `push/pop/popToRoot` +
  `mutateActivePath` per `03-store.md §2`.
- **Done-when:** builds; `push(SomeRoute())` appends to `savedPath`; matches `03-store.md §2` shape.

### Task 0.2 — RootView TabView + Saved tab root  · `swift-screen-builder`
**Files (SERIAL):** `ios/AppTemplate/App/RootView.swift` (edit).
- Replace the placeholder with an iOS-26 floating-glass `TabView(selection:)` over `AppTab`,
  `.tabBarMinimizeBehavior(.onScrollDown)`. Each tab hosts a `NavigationStack(path:)` bound to its
  store path; **only `.saved` renders `SavedListView()`** + its `.navigationDestination(for:)`
  registrations (`PlaceDetailRoute`); the other three render a `ContentUnavailableView` "Coming soon"
  placeholder (their features are separate stories — do NOT invent them; **DECISION FLAG D-2**).
- Keep the existing onboarding `.fullScreenCover` driven by `store.onboarding` layered above the tabs.
- Tab buttons carry `tab.<case>` accessibility ids.
- **Done-when:** app boots into the Saved tab; `tab.saved` resolves; onboarding cover still works;
  pushing `PlaceDetailRoute` shows `PlaceDetailView`.

### Task 0.3 — ScreenCatalog scaffold + Saved section  · `swift-screen-builder`
**Files:** new `ios/AppTemplate/Screens/Catalog/ScreenCatalogView.swift` (core, SERIAL once),
new `ios/AppTemplate/Screens/Catalog/CatalogSection+Saved.swift` (new file).
- `ScreenCatalogView` is the debug back-door per `06-screens.md §7`: a `List` of seeded entries
  reachable without the production graph. `CatalogSection+Saved.swift` registers: SavedList (standard /
  empty / by-source / search-active), PlaceDetail (a seeded id), AddPlaceSheet.
- **Done-when:** catalog lists each Saved entry; each opens its screen seeded via `AppStore.preview`.

---

## Wave 0.A — NEW design-system tokens + components (mini-freeze)

> All `swift-design-system`. Each file disjoint → batchable. After the batch: **design-reviewer
> mini-pass** then **snapshot-lock** (one snapshot per state; an **AX5** snapshot for the type-dense
> rows `PlaceRow`/`SourceCard`/`SourcePlaceRow`/`WayToSaveRow` per `07-testing.md §7.4`). No Wave-3
> screen dispatches until this wave is reviewed + locked.

### Task 0.A0 — Category color roles + tint helper  · `swift-design-system`
**Files (SERIAL — token file):** `ios/AppTemplate/DesignSystem/Tokens/ColorRole.swift` (edit).
- Add `categoryEat/Drink/Stay/Do/Shop` mark roles (alias `Primitive.day*` + an ink for Shop) and a
  `static func categoryTint(_ category: PlaceCategory) -> Color` (low-alpha background, ≈ the mockup's
  13%). **Resolve DECISION FLAG D-1 first.** No `foundations.css`/codegen change.
- **Exemplar:** the `dayMark*` block already in `ColorRole.swift`.
- **Done-when:** builds; semantic-tier only; `CategoryChip` and the detail kicker consume these; no
  primitive/literal leaks into any view.

### Task 0.A1 — `CategoryChip`  · `swift-design-system`
**Files:** new `DesignSystem/Components/CategoryChip.swift`.
- Value-type arg `PlaceCategory`. Renders a mono caps label (`Typography.caption`, `trackCapsCaption`)
  on `ColorRole.categoryTint(category)`, `Radius.tag`. Read-only (no Button). One VoiceOver stop
  (`.combine`); color paired with the text label (never color alone — 02-color §6).
- **Mockup:** `.pl-cat` / `.pd-kicker .pl-cat` in `saved-shell.css`. **Exemplar:** `Tag.swift`.
- **Done-when:** snapshots for Eat/Drink/Stay/Do/Shop; AX5 snapshot of one; no accent used.

### Task 0.A2 — `PlaceRow`  · `swift-design-system`
**Files:** new `DesignSystem/Components/PlaceRow.swift`.
- A horizontal CONTENT row on `surfaceGrouped` + `Radius.card` (the mockup's `--paper-100` `.pl`),
  **never glass** (J-0.1). Grid: 62pt thumb well (`Radius.row`, striped/`fillTertiary` photo
  placeholder + a `src-badge` provenance stamp glyph in a `paper0` circle with `Shadow.rest`) ·
  body (`name` display face / `meta` secondary / `source` mono caps with a leading source glyph) ·
  trailing slot (chevron OR a `CategoryChip`, caller's choice for list-vs-search variants).
- **Value-type fixture only** (`PlaceRowModel`: id, name, meta, sourceLabel, sourceSystemImage,
  category, thumbnail-absent placeholder, `trailing` enum `.chevron`/`.category`). No domain object,
  no store (05 §8).
- **A11y (05 §8.1):** component owns the mechanism + an `accessibilityID` PASSTHROUGH (the caller
  supplies `placerow.<id>`); component owns the combined label. Thumb/badge/chevron are
  `accessibilityHidden`. `@ScaledMetric` thumb height (mirror `PlaceCard.wellHeight`).
- **Mockup:** `.pl` in `saved-shell.css`. **Exemplar:** `PlaceCard.swift` (well/placeholder pattern)
  + `06-screens.md §8` `BookRow` shape.
- **Done-when:** snapshots for source∈{reel,screenshot,search} × trailing∈{chevron,category}; an AX5
  snapshot; a "no photo" placeholder state (never a broken-image box — J-12.4); id passthrough not baked.

### Task 0.A3 — `SourceCard` + `SourcePlaceRow`  · `swift-design-system`
**Files:** new `DesignSystem/Components/SourceCard.swift` (may hold both; or split `SourcePlaceRow.swift`).
- `SourceCard`: a CONTENT card (`surfaceGrouped`, `Radius.card`, clipped). Head grid: 52pt source-icon
  tile (tinted by source kind — reel/violet, screenshot/slate, search/neutral; reuse the day-mark
  tints), title (display) + meta (mono caps), a count pill (`fillTertiary`, `Radius.pill`, tabular
  nums), a caret that rotates when expanded (`Motion.standard`, respects Reduce Motion). Expanded body:
  a `Divider` (`ColorRole.separator`) then N `SourcePlaceRow`s, then an optional foot hint row.
- **Disclosure is caller-owned:** `isExpanded: Bool` + `onToggle: () -> Void` (state lives in the
  screen's `@State` set, like `SegmentedSelector`'s selection). Component owns no expansion state.
- `SourcePlaceRow`: 46pt thumb + name (display) + meta (with an optional accent-50 `stamp` timestamp
  pill, `accent-700` ink) + chevron. Value-type fixture; id passthrough (`sourceplacerow.<id>`).
- **A11y:** the head Button is one element with the `sourcecard.<id>` id passthrough + `.isExpanded`
  trait reflected in the value; the child rows stay independently tappable inside the expanded body
  (`.contain`, not `.ignore` — the SegmentedSelector lesson, 05 §8.1).
- **Mockup:** `.srccard` / `.src-place` / `.srccard-foot` in `saved-shell.css`. **Exemplars:**
  `SegmentedSelector.swift` (contain-vs-ignore), `PlaceCard.swift` (surface), `Tag.swift`.
- **Done-when:** snapshots collapsed/expanded (video→many) + search→single + screenshot; AX5 snapshot
  of expanded; caret rotation settles at rest under Reduce Motion; ids not baked.

### Task 0.A4 — `WayToSaveRow`  · `swift-design-system`
**Files:** new `DesignSystem/Components/WayToSaveRow.swift`.
- A glyph-tile + title/subtitle + chevron row, with a `prominent` variant (the add-sheet's first
  "Paste a reel" method) vs standard. CONTENT surface. Value-type fixture; the action is a caller
  closure; id passthrough (`waytosave.<id>` where id∈ reel/screenshot/search).
- **Mockup:** `.way` (`saved-empty.html`) and `.method`/`.method.primary` (`add-place.html`).
  **Exemplar:** `EmptyStateView.swift` + `PillButton` for the prominent tier treatment.
- **Done-when:** snapshots prominent/standard + AX5; chevron hidden from a11y; one combined label.

### Task 0.A5 — `ProvenanceCard` + `PlaceInfoGrid` + `MapSnippet`  · `swift-design-system`
**Files:** new `DesignSystem/Components/ProvenanceCard.swift`, `PlaceInfoGrid.swift`, `MapSnippet.swift`
(three disjoint files — may be three sub-tasks).
- `ProvenanceCard`: `.prov` — source thumb + who/meta + a "View" affordance (caller closure; opens the
  original — **DECISION FLAG D-3**: external/in-app player is out of scope; wire the closure, do not
  build a player screen) + an italic display-face quote. CONTENT surface.
- `PlaceInfoGrid`: `.info-grid` — three `(key, value, sub)` cells, value mono where numeric. Value-type
  `[PlaceInfoCell]`. Dynamic-Type-safe (wraps, no fixed frame).
- `MapSnippet`: `.map-snip` — a static map placeholder canvas (mirror `BaseMapCard.swift`'s placeholder,
  NO live MapKit this milestone) + address line + a "Directions" affordance (caller closure —
  **DECISION FLAG D-3** same: wiring only). Glass NOT used (it's content).
- **Mockup:** `.prov` / `.info-grid` / `.map-snip` in `saved-shell.css`. **Exemplars:** `BaseMapCard.swift`,
  `ContextNote.swift`, `TimeHint.swift`.
- **Done-when:** one snapshot each + an AX5 snapshot of `PlaceInfoGrid`; affordances expose ids
  (`provenance.view`, `mapsnippet.directions`); no glass on content.

---

## Wave 1 — models + networking + sample data + seed

### Task 1.1 — Saved-place models + leaf value types  · `swift-model-scaffold`
**Files:** new `ios/AppTemplate/Models/SavedPlaceModel.swift` (reference model + container),
new `ios/AppTemplate/Models/PlaceCategory.swift`, `PlaceSource.swift`, `PlaceProvenance.swift`,
`PlaceLocation.swift`, `PlaceFacts.swift` (leaf value types — disjoint files, batchable).

**Reference models** (`@MainActor @Observable final class`, Identifiable, identity equality, NOT
Codable — 02-models §1.1):
- `SavedPlacesModel` (the container/list owner): `let id: String`; `var places: [SavedPlaceModel]`;
  lookup `func place(id: SavedPlaceModel.ID) -> SavedPlaceModel?`. (Container participates in list
  rendering + mutates via add → reference model.)
- `SavedPlaceModel` (the row): `let id: String`; `var name: String`; `var category: PlaceCategory`;
  `var location: PlaceLocation`; `var source: PlaceSource`; `var provenance: PlaceProvenance?` (detail
  "Saved from"); `var facts: [PlaceFacts]` (the detail info grid); `var addressLine: String?`;
  `var latitude: Double?`; `var longitude: Double?` (flat doubles, never CLLocationCoordinate2D —
  mirror `BaseLocation`); `var savedAtNote: String?`.
  - Model methods (pure, in-place — 02-models §2): none strictly required for the write (the add is a
    store command), but include `restore(from: PlaceDTO)` (the rollback seam) and any pure display
    helper that returns DATA not Views.

**Leaf value types** (`nonisolated`, Codable/Equatable/Hashable/Sendable — 02-models §1.2):
- `PlaceCategory: String enum` { eat, drink, stay, `do` (escaped), shop } + `displayLabel`,
  `markRole`-free (color lives in `ColorRole`, the model stays SwiftUI-free).
- `PlaceSource` (associated-value enum, manual tag-keyed Codable per 02-models §3.2, mirror `CityMeta`):
  `case reel(handle: String, clipTitle: String?)`, `case screenshot(savedNote: String?)`,
  `case search`. Plus `var kind: SourceKind` (`reel/screenshot/search`) + `displayLabel` +
  `systemImage` (the SF Symbol the row/badge shows) for the presenter to read.
- `PlaceProvenance: struct` { sourceHandle, clipTitle?, timestamp?, quote? } — the detail "Saved from".
- `PlaceLocation: struct` { neighborhood: String, cityName: String } (free text — NOT the onboarding
  `Neighborhood`).
- `PlaceFacts: struct` { key: String, value: String, sub: String? } — one info-grid cell.

- **A11y/ID:** cross-refs as `SavedPlaceModel.ID`, never bare `String`. Stable literal seed ids
  (`"place-cevicheria"`, etc.).
- **Exemplar:** `City.swift`/`CityMeta` (the associated-value enum + manual Codable), `TripDraftModel.swift`
  (reference model shape + `restore(from:)`), `BaseLocation.swift` (flat lat/long).
- **Done-when:** builds; reference models not Codable; leaves all `nonisolated`; `PlaceSource` Codable
  is hand-written tag-keyed; cross-refs use `.ID`.

### Task 1.2 — `SavedPlacesDTO` + `PlaceDTO` + toDomain/toDTO  · `swift-model-scaffold`
**Files:** new `ios/AppTemplate/Networking/Responses/DTO/SavedPlacesDTO.swift`,
`ios/AppTemplate/Networking/Responses/DTO/PlaceDTO.swift`.
- `nonisolated struct PlaceDTO: Codable, Equatable, Sendable` — field-for-field mirror of
  `SavedPlaceModel`, reusing the leaf value types directly (no per-leaf DTO).
- `nonisolated struct SavedPlacesDTO: Codable, Equatable, Sendable` — mirrors `SavedPlacesModel`
  (`id` + `[PlaceDTO]`).
- `extension PlaceDTO { @MainActor func toDomain() -> SavedPlaceModel }`,
  `extension SavedPlaceModel { func toDTO() -> PlaceDTO }`; same for the container.
- The round-trip invariant `dto.toDomain().toDTO() == dto` must hold (tested Wave 4).
- **Exemplar:** `OnboardingContextDTO.swift` (DTO shape, `toDomain()` on MainActor).
- **Done-when:** builds; round-trip lossless; mapping total (compiler catches a model field missing
  from the DTO).

### Task 1.3 — Saved sample data + scenarios + seed wiring  · `swift-model-scaffold`
**Files:** new `ios/AppTemplate/Models/SampleData/SampleData+Saved.swift` (new file — builders),
**edit (SERIAL):** `Models/SampleData/SampleData.swift` (`seed(for:)` switch),
`Networking/MockSeed.swift` (add `savedPlaces` field), `Networking/MockScenario.swift` (add cases).
- `SampleData+Saved.swift`: `savedPlaces()` (canonical — the 24-place populated set from
  `saved-populated.html`: Eat/Drink/Stay/Do/Shop across Lisbon/Tokyo, mixed reel/screenshot/search
  sources, including a reel that yields MANY places for the by-source view), `emptySavedPlaces()`
  (0 places → the rich empty state), and the DTO snapshotters (`savedPlacesDTO()` etc. via `.toDTO()`).
  Stable literal ids matching the mockup names. Add a `simulatedNow` consistent with the seed.
- `MockSeed`: add `var savedPlaces: SavedPlacesDTO?` (default nil so `.empty` survives).
- `MockScenario`: add `case savedStandard`, `case savedEmpty`, `case savedError` (the error case is
  realized by `failureRate`, not a separate seed — but a named scenario keeps the UITest table clean).
- `SampleData.seed(for:)`: map `savedStandard → MockSeed(savedPlaces: savedPlacesDTO())`,
  `savedEmpty → MockSeed(savedPlaces: emptySavedPlacesDTO())`.
- **Exemplar:** `SampleData.swift` + `SampleData+Onboarding.swift`, `MockSeed.swift`, `MockScenario.swift`.
- **Done-when:** builds; `seed(for: .savedStandard)` returns a 24-place DTO; ids stable; `.empty` still
  yields no savedPlaces.

### Task 1.4 — `GetSavedPlacesRequest` + `AddPlaceRequest`  · `swift-networking-endpoint`
**Files:** new `ios/AppTemplate/Networking/Requests/GetSavedPlacesRequest.swift`,
new `ios/AppTemplate/Networking/Requests/AddPlaceRequest.swift`. (Two disjoint files — batchable.
Do NOT edit `APIClient`/`MockProvider`/`LiveProvider` — the one-file rule, 04 §2.)
- `GetSavedPlacesRequest: APIRequest` — `Response = SavedPlacesDTO`; `path "/saved-places"`;
  `.get`; `mockResponse(from:)` returns `seed.savedPlaces` or throws `APIError.status(404)` (mirror
  `GetOnboardingContextRequest`).
- `AddPlaceRequest: APIRequest` — `Response = PlaceDTO`; `path "/saved-places"`; `.post`;
  `body` = the new place value (an `AddPlaceBody` `nonisolated Encodable & Sendable` carrying the
  method + url/handle the sheet collected, OR a `PlaceDTO` for the resolved place — pick per the add
  flow below); `mockLatency = .milliseconds(800)` (so the loading state is exercisable — 04 §7);
  `mockResponse(from:)` computes a resolved `PlaceDTO` from the immutable seed (e.g. returns a canned
  "resolved from reel" place) — pure, synchronous, not persisted (the mock is stateless — 04 §7).
- **DECISION FLAG D-4 (add flow scope):** `add-place.html` is a *method picker* sheet (paste-reel /
  screenshot / search), each method a deeper capture flow. This milestone builds **only the sheet +
  the one networked write** (tapping "Paste a reel" with the clipboard URL fires `AddPlaceRequest`,
  optimistically inserts a resolved place, rolls back on failure). The screenshot/search capture
  destinations are **separate stories** (06-screens §4.1) — wire their taps to a route/closure but do
  NOT build those screens; surface for decision if the coordinator wants them now.
- **Exemplar:** `GetOnboardingContextRequest.swift`; the `BorrowBookRequest`/POST pattern in 04 §2.
- **Done-when:** both build; verb/method agree; `mockResponse` pure; `AddPlaceRequest.mockLatency`
  non-zero; no edit to the generic providers.

---

## Wave 2 — store command + load state

### Task 2.1 — `AppStore+Saved` (load + add command)  · `swift-screen-builder` (store-tier)
**Files:** new `ios/AppTemplate/Store/AppStore+Saved.swift`,
**edit (SERIAL):** `Store/AppStore.swift` (add `private(set) var savedPlaces: SavedPlacesModel?` +
`var savedLoadState: LoadState = .idle` + `var writeError: WriteError?` (new value type) + a
`setSavedPlaces(_:)` same-file seam mirroring `setOnboarding`), and extend `AppStore.preview` for a
saved seed OR add a `loadSeed(savedPlaces:)` seam.
- Read path: `func loadSavedPlaces() async` — `.loading` → `api.send(GetSavedPlacesRequest())` →
  `savedPlaces = dto.toDomain()` on MainActor → `.loaded`; `.failed` on throw (mirror `loadOnboarding`).
- Write command (optimistic + rollback — **required** here, this is a real networked write):
  `func addPlace(_ draft: AddPlaceBody) async`:
  1. build the optimistic `SavedPlaceModel` (pending/resolved-loading register), insert into
     `savedPlaces?.places` (in place → only the list invalidates);
  2. `do { let dto = try await api.send(AddPlaceRequest(...)); ` reconcile the inserted row from
     `dto` (e.g. `row.restore(from: dto)`) `}`
  3. `catch { remove the optimistic row (or restore the container snapshot); writeError = .addPlace }`.
  Snapshot for rollback via the container's `.toDTO()` or by removing the optimistically-added id.
- `enum WriteError: Equatable { case addPlace }` (new — 03 §2 shape).
- Add `var writeError` only if not present (it is not — onboarding has none). Flag this property add as
  the serialized `AppStore.swift` edit.
- **Exemplar:** `AppStore+Onboarding.swift` (load path, seams), `03-store.md §3` (`borrow` optimistic +
  `restore(from:)` rollback).
- **Done-when:** builds; happy path inserts + clears `writeError`; failure path removes/reverts the
  optimistic row AND sets `writeError == .addPlace`; load path sets `LoadState` correctly.

---

## Wave 3 — screens (each: scaffold → swift-code-reviewer → fidelity-reviewer)

> All `swift-screen-builder`. Each screen NAMES its mockup (the fidelity target), declares
> dot-namespaced a11y ids (05 §8.1: components own the mechanism, the screen owns the id VALUES),
> builds the interactivity inventory (06 §4.1) wiring every affordance to a model method / store
> command / route, gets a `Route` (where pushed) + a `ScreenCatalog` entry + `#Preview` per state.

### Task 3.1 — `SavedListView` + `SavedListPresenter`  · `swift-screen-builder`
**Files:** new `Screens/Saved/SavedListView.swift`, `Screens/Saved/SavedListPresenter.swift`;
**edit (SERIAL):** `Screens/Catalog/CatalogSection+Saved.swift` (catalog entries — new file, but listed
serial because 0.3 created it), `App/RootView.swift` (already registers the destination in 0.2).
- **Chrome:** `ScreenScaffold(.root(title:))` — the Saved tab home (large title collapses on scroll).
  Top-right "+" add affordance via a single secondary control (06 §2.3) → opens `AddPlaceSheet`
  (ephemeral `@State` sheet flag). NO bottom ActionBar (the mockup has none on the list).
- **Composition:** `ScreenSection`/`RhythmSpacer` for the editorial hero (eyebrow/title/sub counts),
  the `SearchWell`, the `SegmentedSelector` (By category / By source) + a city-filter control, the
  `FilterChip` row (category pills with counts), then the grouped content.
- **States derived by the presenter (stateless, in `body` — 06 §3):** `SavedListPresenter(store:,
  query:, mode:, cityFilter:, categoryFilter:)` deriving:
  - `mode` (byCategory/bySource) + `query` + filters are ephemeral `@State` the presenter reads;
  - **empty** (no places at all) → render `WayToSaveRow`×3 (the rich `saved-empty.html`);
  - **populated, byCategory** → `[CategoryGroup]` (header dot + label + count, then `PlaceRow`s) —
    `saved-populated.html`;
  - **bySource** → `[SourceGroupModel]` for `SourceCard`s (one reel → many `SourcePlaceRow`s) —
    `saved-by-source.html`; expansion is an ephemeral `Set<SavedPlaceModel.ID/SourceID>` `@State`;
  - **search-active** (query non-empty) → fuzzy-matched `PlaceRow`s with a trailing `CategoryChip`,
    grouped "N places / Also nearby" — `saved-search.html`; an AI-voice "matching by vibe" line
    (reuse `AIVoice`).
  - `headerCounts` ("24 places · 3 cities · from 11 sources").
  Presenter returns DATA (models/strings), never Views (06 §3).
- **Interactivity inventory (each wired):** a `PlaceRow` tap → `store.push(PlaceDetailRoute(id:))`;
  a `SourcePlaceRow` tap → same; a `SourceCard` head tap → toggle the expansion `@State`; the
  `SearchWell` → writes `query` `@State` the presenter filters each keystroke; `FilterChip` →
  category-filter `@State`; `SegmentedSelector` → `mode` `@State`; city-filter → `cityFilter` `@State`;
  "+" → sheet flag; `WayToSaveRow` taps → the add-method routes (**D-4**: build only the reel path;
  others wire to the sheet/route, no invented screen).
- **A11y ids (screen owns the values):** `savedlist.search`, `savedlist.mode` (segment ids
  `savedlist.mode.byCategory`/`.bySource`), `savedlist.filter.<category>`, `placerow.<id>`,
  `sourcecard.<id>`, `sourceplacerow.<id>`, `savedlist.add`, `savedlist.emptyState`,
  `writeError.banner` (the write-error banner read off `store.writeError` — no toast/alert, 06 §6).
- **`#Preview`s (one per state, seeded via `AppStore.preview`):** standard/byCategory · bySource ·
  search-active · empty.
- **Mockups (fidelity targets):** `saved-empty.html`, `saved-populated.html`, `saved-by-source.html`,
  `saved-search.html` (+ `Saved.html` is the gallery shell, not a screen).
- **Exemplar:** `DestinationStepView.swift` + `DestinationStepPresenter.swift` (search-mode swap,
  presenter shape, `#Preview` set, a11y-id ownership).
- **Done-when:** composes `ScreenScaffold(.root)`; renders all four states from the presenter; every
  affordance hits a sink (no empty closures — 06 §4.1); ids present; names its mockups; fidelity-review
  passes; one snapshot per state + an AX5 snapshot of the populated state.

### Task 3.2 — `PlaceDetailView` + `PlaceDetailPresenter` + `PlaceDetailRoute`  · `swift-screen-builder`
**Files:** new `Screens/Saved/PlaceDetailView.swift`, `PlaceDetailPresenter.swift`,
new `Screens/Routes/PlaceDetailRoute.swift`; **edit (SERIAL):** `CatalogSection+Saved.swift`.
- **Route:** `struct PlaceDetailRoute: Hashable { let id: SavedPlaceModel.ID }` (one per file, 06 §5).
- **Chrome:** the mockup is a photo-hero takeover with its own over-hero top bar + a bottom CTA. Use
  `ScreenScaffold(.detail(title:))` (inline title + back, tab bar persists on push) with the hero photo
  as the first content section and the back/save glyphs as the system back + a top-right secondary
  control; the bottom **`ActionBar`** carries "Add to a trip" (the thumb-zone CTA, 06 §2.4). (If the
  over-hero custom header is required for fidelity, use `.custom` and supply the back glyph via
  `GlassCircleButton(.back)` — **fidelity-reviewer decides**; default to `.detail`.)
- **Presenter** derives: title block (`CategoryChip` + "neighborhood · city" kicker, display name),
  the `ProvenanceCard` model (from `provenance`), the `PlaceInfoGrid` cells (from `facts`), the
  `MapSnippet` model (address + lat/long placeholder).
- **Interactivity:** "Add to a trip" CTA → **DECISION FLAG D-5** (no Trip feature this milestone) →
  wire to a no-op-with-banner or a route stub; do NOT invent the Trip screen. ProvenanceCard "View" →
  D-3 (wire only). MapSnippet "Directions" → D-3 (wire only). Back → `store.pop()`/system back.
- **A11y ids:** `placedetail.addToTrip`, `provenance.view`, `mapsnippet.directions`,
  `placedetail.back`.
- **`#Preview`:** seeded `AppStore.preview` + `PlaceDetailView(placeID: "place-cevicheria")`.
- **Mockup:** `place-detail.html`. **Exemplar:** `06-screens.md §1` `BookDetailView`; `BaseMapCard` for
  the map placeholder.
- **Done-when:** composes the scaffold + the new components; CTA in the thumb zone; back works; names
  its mockup; fidelity-review passes; one snapshot.

### Task 3.3 — `AddPlaceSheet` + `AddPlacePresenter`  · `swift-screen-builder`
**Files:** new `Screens/Saved/AddPlaceSheet.swift`, `AddPlacePresenter.swift`;
**edit (SERIAL):** `CatalogSection+Saved.swift`.
- **Chrome:** a presented sheet (`.sheet(isPresented:)` from `SavedListView`'s ephemeral `@State`).
  Sheet at rest is NOT glass (06 §6); a grabber + a header (title "Save a place" + close ×). Composes
  `WayToSaveRow`×3 (paste-reel prominent / screenshot / search) + a "On your clipboard" detected-URL
  affordance with a paste button.
- **Interactivity / the ONE write:** the paste-reel row (or the clipboard paste button) → builds an
  `AddPlaceBody` from the URL and calls `await store.addPlace(...)`; on success dismiss + the new place
  appears optimistically in the list; on failure the `writeError.banner` shows (read off the store).
  Loading state from `AddPlaceRequest.mockLatency` is surfaced (a progress affordance) — testable.
  Screenshot/search rows → D-4 (wire to route/closure, no invented destination this milestone).
- **A11y ids:** `addplace.method.reel`/`.screenshot`/`.search`, `addplace.paste`, `addplace.close`,
  `writeError.banner`.
- **`#Preview`:** the sheet over a seeded list; an error-state preview (`failureRate: 1.0`).
- **Mockup:** `add-place.html`. **Exemplar:** `ManualAddressPickerSheet.swift` (sheet mechanics),
  `06-screens.md §6`.
- **Done-when:** the reel/clipboard path fires `addPlace`; loading + error are surfaced (banner, not
  toast); other methods wired (no dead closures); names its mockup; one snapshot (+ error-state snapshot).

---

## Wave 4 — tests (the four layers)

### Task 4.1 — Model + DTO unit tests  · `swift-test-writer`
**Files:** new `AppTemplateTests/SavedPlaceModelTests.swift`, `PlaceDTORoundTripTests.swift`.
- L1: `SavedPlaceModel.restore(from:)` applies a snapshot; `SavedPlacesModel.place(id:)` returns the
  ref / nil; `PlaceSource` Codable round-trips each case (tag-keyed); `PlaceCategory` displayLabel.
- L1: DTO round-trip `dto.toDomain().toDTO() == dto` with a **plain symmetric** coder (07 §4.2 — never
  `APIJSON`). Index fixtures by stable id; identity equality → assert on fields.
- **Done-when:** green; uses `SampleData.savedPlaces()`; no live clock.

### Task 4.2 — Store command + presenter tests  · `swift-test-writer`
**Files:** new `AppTemplateTests/AppStoreSavedTests.swift`, `SavedListPresenterTests.swift`.
- L2 `@MainActor`: `addPlace` happy path (row inserted, `writeError == nil`); `addPlace` rollback
  (`failureRate: 1.0` → row removed/reverted + `writeError == .addPlace`); `loadSavedPlaces` happy +
  `.failed` (offline) paths; the decode→DTO→domain pipeline reaches the graph intact (07 §5.2).
- L1 presenter: derivation for **all four states** — empty (→ ways-to-save / emptyState message),
  populated byCategory (group order + counts), bySource (one reel → many child rows), search-active
  (fuzzy match count + grouping). Seed a store, build the presenter, assert each derived value (07 §4.3).
- **Done-when:** green; every mutating command has happy + rollback (07 §9); presenter input→output.

### Task 4.3 — Render snapshots (the lock)  · `swift-snapshot-test-writer`
**Files:** new `AppTemplateTests/SavedSnapshotTests.swift` (+ committed `__Snapshots__/`).
- L3: one snapshot per Wave-0.A component state (already locked in 0.A — do not duplicate; this task
  locks the SCREENS) — `saved-list-empty`, `saved-list-by-category`, `saved-list-by-source`,
  `saved-list-search`, `place-detail`, `add-place`, `add-place-error`; plus an **AX5** variant of
  `saved-list-by-category` and `place-detail` (07 §7.4 dynamic-type lock). Use `assertDesignSnapshot`
  + `canonicalConfig` + `#filePath` (07 §6.1/§6.5); `EXCLUDED_SOURCE_FILE_NAMES="*.png"` already set.
- **Done-when:** baselines committed; one per state; AX5 variants present; no `record: .all` left in.

### Task 4.4 — XCUITest + accessibility audit  · `swift-uitest-writer`
**Files:** new `AppTemplateUITests/SavedFlowUITests.swift`.
- L4 table-driven across scenarios (`UITEST_SCENARIO` ∈ `savedStandard`/`savedEmpty`, +
  `UITEST_FAILURE_RATE=1.0` for the add error path): the Saved tab shows rows (standard) vs the
  ways-to-save empty state; tapping a `placerow.<id>` pushes detail; toggling `savedlist.mode.bySource`
  shows `sourcecard` + expand shows children; "+" → `AddPlaceSheet` → reel path → optimistic row /
  `writeError.banner` on failure. Query by id only, `waitForExistence` (≥ the 800ms mock latency),
  never text/sleep (07 §7.3/§7.6).
- One broad `performAccessibilityAudit()` per screen under `savedStandard` (07 §7.4) with a narrow,
  documented `.elementDetection && id.isEmpty && label.isEmpty` suppression only if it flakes, paired
  with the AX5 snapshot from 4.3 as the compensating check.
- **Done-when:** green across scenarios; navigation + the add write + the error banner proven at
  runtime; audits pass (or documented suppression + named compensating check).
- **NOTE (07 §7.1):** `AppTemplateApp.init` must read `UITEST_SCENARIO`/`UITEST_FAILURE_RATE` and build
  `AppStore(api: .mock(scenario:failureRate:))` — confirm/extend this seam (likely a small edit to
  `App/AppTemplateApp.swift`, SERIAL) as part of Wave 0 or this task.

---

## GATE

`build-for-testing` clean (07 §6.6 — `build` alone leaves a stale test bundle after signature changes)
→ all four layers green → `ios-test-coverage-check` (incl. the `a11y-ownership-lint.sh` — every new
component PASSES the id through, bakes none callers must vary; 05 §8.1) → `swift-code-reviewer`
(semantic-tokens-only, logic-out-of-views, MainActor-by-default, provider-swappability) →
`design-reviewer` slop pass (08-slop: no gradient fills, no glassmorphism-on-content, the category tint
earned not reflexive) on the new components + screens → `fidelity-reviewer` already passed per screen.

---

## Open decisions (settle before/with execution)

- **D-1 (token):** category tints — add `ColorRole.category*` + `categoryTint` semantic roles (the
  mockup uses day-mark hues as a low-alpha label tint), or render categories ink-only? Recommended:
  add the roles (intent-named, chip-scale, not a card fill). No `foundations.css`/codegen change either
  way.
- **D-2 (IA):** the Trip / Map / You tabs are in the mockup tab bar but are separate features. Plan
  renders them as "Coming soon" placeholders; confirm that vs hiding them this milestone.
- **D-3 (out-of-scope affordances):** ProvenanceCard "View" (open the original reel/video), MapSnippet
  "Directions" — wire the closures only (no player / no Maps hand-off built). Confirm.
- **D-4 (add flow scope):** build only the add-place **method sheet + the one reel/clipboard networked
  write** (so optimistic+rollback is real). The screenshot/search capture flows are separate stories —
  wire their taps, do not invent the destinations. Confirm.
- **D-5 (Add to a trip):** the place-detail CTA targets a Trip feature that does not exist. Wire to a
  stub (no-op + banner, or a route placeholder); do NOT scaffold a Trip screen here. Confirm.
- **D-6 (detail chrome):** `place-detail.html` is a photo-hero with an over-hero header + bottom CTA.
  Default to `ScreenScaffold(.detail)` + `ActionBar`; allow the fidelity-reviewer to escalate to
  `.custom` (own header) if the hero overlap can't be matched otherwise.
