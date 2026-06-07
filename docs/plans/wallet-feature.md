# Wallet feature — contract-level implementation plan

The **Travel Wallet & Bookings** vertical slice: a per-trip wallet that groups bookings by day, an
AI orphan-placement prompt, a type-aware booking detail, a full-screen day-of access (boarding-pass)
takeover, and an add-to-wallet flow (method picker → AI-extracted review). Second feature slice after
onboarding + Saved.

- **Worktree (all paths absolute):** `/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/wallet/`
- **App source root:** `…/ios/AppTemplate/`
- **Exemplar feature to mirror end-to-end:** **Saved** (`Models/SavedPlaceModel.swift`,
  `Networking/Requests/GetSavedPlacesRequest.swift` + `AddPlaceRequest.swift`,
  `Store/AppStore+Saved.swift`, `Models/SampleData/SampleData+Saved.swift`, `Screens/Saved/*`,
  `DesignSystem/Components/{PlaceRow,SourceCard,WayToSaveRow}.swift`).
- **Mockups (fidelity targets):** `…/mockups/screens/wallet/{Wallet,wallet-populated,wallet-empty,
  booking-detail,access-card,add-method,add-review}.html` + `wallet-shell.css` + `qr.svg`.

> **Contracts only — no code bodies.** Where a signature is shown it is the interface to implement; any
> multi-line snippet is a **sketch the executor reconciles against live source**. The substrate
> (`APIClient`/`AppStore`/`MockProvider`/`MockSeed`/`SampleData`/composition primitives) already exists
> from onboarding + Saved — **this is NOT a first feature; there is no Wave 0 bootstrap.**

---

## 0. Phase ordering (with the foundation mini-freeze barrier)

```
Wave 1  — DESIGN SYSTEM (tokens → components)        ── [MINI-FREEZE] ──
            new ColorRole/Sizing roles + ~9 new components, each design-reviewed + snapshot-locked.
            NO wallet screen scaffolds until this wave is reviewed + its component snapshots are green.
   │
   ▼   (barrier)
Wave 2  — MODELS + NETWORKING (parallel, disjoint files)
            BookingModel/WalletModel + leaf value types + DTOs + SampleData+Wallet + MockSeed/Scenario
            wiring + Get/PlaceOrphan requests + AppStore+Wallet load/command.
   │
   ▼
Wave 3  — SCREENS (each: scaffold → consistency-review → fidelity-review vs its named mockup)
            + the navigation substrate edits (AppTab? / RootView / Routes) — SERIAL where shared.
   │
   ▼
Wave 4  — TESTS (L1 unit · L2 integration · L3 render-snapshot · L4 XCUITest + a11y audit)
   │
   ▼
Four-layer gate → finish-branch
```

**The mini-freeze is the one hard barrier.** It mirrors the Saved "Wave 0.A component batch + mini-freeze"
(`decisions.md` precedent): the design system grew once for Saved, is design-reviewed + snapshot-locked,
then screens compose it. No `swift-screen-builder` runs on a wallet screen until every Wave-1 component
has a green render snapshot and the design-reviewer has passed it.

---

## 1. Reuse-vs-new ledger

### Reuse as-is (no change)
| Existing symbol | File | Used by |
|---|---|---|
| `ScreenScaffold` / `ScreenChrome` / `ScreenSection` / `RhythmSpacer` | `DesignSystem/Composition/` | every wallet screen |
| `ActionBar` | `DesignSystem/Composition/ActionBar.swift` | booking-detail "Show boarding pass" CTA |
| `WayToSaveRow` (+ `WayToSaveRowModel`) | `DesignSystem/Components/WayToSaveRow.swift` | wallet-empty "three ways", add-method sheet method list |
| `AIVoice` | `DesignSystem/Components/AIVoice.swift` | orphan prompt's AI line; add-review "Read from your screenshot" eyebrow |
| `GlassCircleButton` | `DesignSystem/Components/GlassCircleButton.swift` | access-card close ×; over-hero back/share on booking-detail |
| `EmptyStateView` | `DesignSystem/Components/EmptyStateView.swift` | (fallback only; wallet-empty uses its own rich layout) |
| `PillButton` | `DesignSystem/Components/PillButton.swift` | orphan "Pin to Day N" / "Not now"; add-review CTA + ghost |
| `LeadingGlyph`, `Tag` | `DesignSystem/Components/` | available if a screen needs them |
| All tokens: `Spacing`, `Radius`, `Stroke`, `Typography`, `Motion`, `Shadows`, `Grid` | `DesignSystem/Tokens/` | everywhere |

### NEW design-system work (Wave 1)
| New symbol | Kind | Ports (wallet-shell.css) | Why new (not reuse) |
|---|---|---|---|
| `ColorRole.bookingTint(_:)` / `bookingMark(_:)` | semantic role fn | `.bk-ico.lodging/.transport/.activity/.dining/.other` | new taxonomy (booking *type*), distinct from `categoryTint`/`sourceTint`; aliases the same `day1…day4` hues |
| `Sizing.Component.*` (booking-row icon, bd-hero icon, access-qr, info-cell, etc.) | semantic dimension | the new components' fixed dims | each is a single-component `Grid.x(n)` dim with no current home |
| `BookingRow` (+ `BookingRowModel`) | component | `.bk` / `.bk-ico` / `.bk-body` / `.bk-end` | type-aware compact wallet entry; `PlaceRow` is a different anatomy (no thumb well, no source line) |
| `StatusPill` (+ `BookingStatus` mapping) | component | `.pill.upcoming/.today/.now/.past` | new status vocabulary; `Tag` is a different shape (no live-dot, no per-status fill) |
| `DayGroupHeader` | component | `.daygrp` (`.n` + `.d` + `.rule`) | day-number + date + filling hairline; not the Saved `categoryHeader` (which is a dot+label) |
| `OrphanPromptCard` (+ `OrphanPromptModel`) | component | `.orphan` | AI placement card (accent-wash ground + AI line + Pin/Not-now); no existing equivalent |
| `BookingInfoGrid` (+ cell value type) | component | `.info-grid`/`.info-cell` | 3-cell hairline-separated detail grid; `PlaceInfoGrid` is the Saved analog — **decide reuse vs new (OD-7)** |
| `ConfirmationRow` | component | `.conf-row` | mono confirmation + copy button |
| `DetailList` (+ row value type) | component | `.det-list`/`.det-row` | quiet key→value list with hairlines |
| `PlacedChip` | component | `.placed` | "Placed on Day N" check chip |
| `AccessPassCard` (+ `AccessPassModel`) | component | `.acc-card`/`.acc-band`/`.acc-qr`/`.acc-meta` | the boarding-pass card incl. the QR — **needs a QR renderer (OD-5)** |
| `WalletEmptyGlyph` (badge composite) | component (small) | `.empty .glyph` + `.badge` | the empty hero glyph with an accent + badge; small enough to be a private subview if preferred |

> The wallet-empty "three ways" and add-method "method list" both port `WayToSaveRow` (the Saved
> component). Confirm its `WayToSaveRowModel` (id/title/subtitle/systemImage/prominent) covers the wallet
> copy; if so, reuse with new fixtures only.

---

## 2. WAVE 1 — Design system (mini-freeze)

Owning agent: **`swift-design-system`** (tokens + components). Reviewer gate: **`design-reviewer`** +
component render snapshots (Wave-4 writer pre-stages these per the existing pattern, or the design agent
stages them with the component — mirror how Saved's `SourceCard`/`PlaceRow` snapshots were created).
Tokens edit is **SERIAL** on `ColorRole.swift` / `Sizing.swift` (flag to coordinator).

### Task 1.1 — Tokens (SERIAL: `ColorRole.swift`, `Sizing.swift`)
Exemplar to mirror: `ColorRole.sourceTint(_:)`/`sourceMark(_:)` and `Sizing.Component.*`.

**`ColorRole` additions** — a *booking-type* taxonomy (marks + ≤icon-tile low-alpha tints, never card
fills; same earned-tint class as `categoryTint`/`sourceTint`, kept restrained by opacity per the
2026-06-06 Saved decision):
```
enum BookingType { case lodging, transport, activity, dining, other }   // see model task 2.1
static func bookingMark(_:) -> Color    // lodging→day1, transport→day3, activity→day4, dining→day2, other→ink600
static func bookingTint(_:) -> Color    // each mark at the mockup alpha (~0.12–0.13); other→fillTertiary
```
Mockup hues (from `wallet-shell.css` `.bk-ico.*`): lodging `day-1`, transport `day-3`, activity `day-4`,
dining `day-2`, other `fillTertiary/ink-600`. **No new primitives** — these alias existing `day*`/`ink*`.
The `now` status pill uses `stateNow` (`accent-500`) + `textOnAccent`; `today` uses `textPrimary` ground
+ inverse label (`.pill.today { background: ink-900; color: paper-0 }`).

**`Sizing.Component` additions** (each `Grid.x(n)`; values from `wallet-shell.css`, snapped on-grid):
| Member | px (grid) | Source |
|---|---|---|
| `bookingRowIcon` | 44 = `x(11)` | `.bk-ico` |
| `bookingDetailIcon` | 52 = `x(13)` | `.bd-ico` (54→52 snap) |
| `accessIconTile` | 44 = `x(11)` | `.acc-ico` (42→44 snap) |
| `accessQRSide` | 208 = `x(52)` | `.acc-qr .code` (210→208 snap) |
| `orphanRowIcon` | 40 = `x(10)` | `.orphan .row .bk-ico` |
| `walletEmptyGlyph` | 96 = `x(24)` | `.empty .glyph` |
| `walletEmptyBadge` | 32 = `x(8)` | `.empty .glyph .badge` (34→32 snap) |
| `confCopyButton` | 32 = `x(8)` | `.conf-row .cp` (30→32 snap) |

Off-grid CSS values snap ≤4px to the grid (the established `decisions.md` rule); record any snap as a
one-line decision if >2px shift on a load-bearing dim.

**Done-when:** new roles/dims compile; zero `Primitive.*`/literal references leak into a view later;
design-reviewer confirms the booking taxonomy reuses hues (no new primitive), accent stays ≤2/screen.

### Task 1.2 — `BookingRow` + `BookingRowModel` (`DesignSystem/Components/BookingRow.swift`)
Exemplar: `DesignSystem/Components/PlaceRow.swift` (value-type fixture, `accessibilityID` passthrough,
content card, `@ScaledMetric` dims, content-only — caller wraps the Button + supplies the id).
Ports `.bk` (grid `44px 1fr auto`): a type-tinted icon tile · name(display)/meta(secondary, with an
emphasized `.time` span) · trailing `StatusPill` over a mono confirmation code. `.past` register dims
(`paper-50` ground, `ink-600` name, icon opacity 0.55).

Fixture:
```
struct BookingRowModel: Sendable, Identifiable {
    let id: String
    let title: String          // .bk-body .nm
    let meta: String           // .bk-body .mt  (presenter composes "Now · 10:00 · timed entry · 2 adults")
    let timeEmphasis: String?  // .bk-body .mt .time  (leading emphasized span, e.g. "Now · 10:00")
    let type: BookingType      // drives icon glyph + bookingTint/bookingMark
    let systemImage: String    // SF Symbol for the type (presenter supplies; component does not invent)
    let status: BookingStatus  // drives the StatusPill
    let confirmation: String?  // .bk-conf mono code
    let isPast: Bool           // .bk.past dim register
}
```
A11y: ONE combined element (title + meta + status + confirmation); icon/pill hidden; `bookingrow.<id>`
id passthrough via `.accessibilityIdentifier(ifPresent:)`. **Done-when:** renders 5 states (lodging,
transport-now, activity-today, dining-upcoming, past) + an AX5; snapshot-locked.

### Task 1.3 — `StatusPill` (`DesignSystem/Components/StatusPill.swift`)
Exemplar: `DesignSystem/Components/Tag.swift` (small mono pill).
Ports `.pill`: mono-caps label, per-status fill. `BookingStatus` enum (leaf — define in the model task
2.1, the component consumes it): `.upcoming` (fillTertiary/ink600), `.today` (textPrimary ground/inverse
label), `.now` (`stateNow` ground + `textOnAccent` + a **static** live-dot — see OD-2 deferral), `.past`
(transparent, `textTertiary`, no horizontal pad). A11y: the pill's text IS its label; mark it
`.accessibilityHidden(true)` when its parent row already speaks the status (BookingRow does).
**Done-when:** 4 snapshots (one per status) + the now-dot static; AX5 of `.now`.

### Task 1.4 — `DayGroupHeader` (`DesignSystem/Components/DayGroupHeader.swift`)
Exemplar: Saved `SavedListView.categoryHeader` (a `firstTextBaseline` HStack of label + count +
filling hairline). Ports `.daygrp`: a display `.n` ("Day 2") + mono-caps `.d` ("Thu · Aug 27 · today")
+ a `separator` rule filling remaining width. Value args: `dayLabel`, `dateLabel`, `isToday: Bool`.
A11y: combined ("Day 2, Thursday August 27, today"). **Done-when:** 2 snapshots (today / not-today).

### Task 1.5 — `OrphanPromptCard` + `OrphanPromptModel` (`DesignSystem/Components/OrphanPromptCard.swift`)
Exemplar: `SourceCard` (content card, value fixture, caller closures) + reuse `AIVoice` for the AI line
and `PillButton(.primary)`/`(.ghost)` for actions. Ports `.orphan`: an `accentWashFill` ground + 1px
`accentWashRing` (the existing earned accent-wash roles), a mono-caps `.lab` with an accent `.mk` dot,
a `.row` (orphan icon + name + meta), an italic display `.line` (the AI suggestion, via `AIVoice` or a
direct italic Text — pick to match `AIVoice`'s anatomy), and `.acts` (Pin / Not now).
```
struct OrphanPromptModel: Sendable {
    let labelCaps: String          // "1 BOOKING NOT YET PLACED"
    let bookingName: String        // "Fado at Tasca do Chico"
    let bookingMeta: String        // "Bairro Alto · confirmation TDC-8841"
    let type: BookingType          // the orphan booking's type tint/glyph
    let systemImage: String
    let suggestionLine: String     // the AI italic line (presenter composes; component renders)
    let pinTitle: String           // "Pin to Day 2"
    let dismissTitle: String       // "Not now"
}
```
Caller closures: `onPin`, `onDismiss`, `onSelect` (tapping the row opens the booking detail). A11y ids
the *caller* supplies: `orphan.pin`, `orphan.dismiss`, `orphan.row`. **Done-when:** 1 snapshot + AX5.

> **Accent budget (J-2.4):** the orphan card uses the accent as the wash ground + the `.mk` dot + the
> primary Pin button. That is at the edge. The design-reviewer must confirm the accent appears ≤2× on the
> *populated wallet screen as a whole* (the `now` pill is the other). The orphan wash + the now pill is
> exactly two — flag if a screen adds a third.

### Task 1.6 — `BookingInfoGrid` (+ cell type) (`DesignSystem/Components/BookingInfoGrid.swift`)
**Decide OD-7 first** (reuse `PlaceInfoGrid` vs new). If new: exemplar is `PlaceInfoGrid` (the Saved
3-cell hairline grid). Ports `.info-grid`/`.info-cell`: 3 columns, 1px `separator` gutters, each cell =
mono-caps `.k` / display `.v` / secondary `.vs`. Value: `[InfoCell(key, value, sub?)]` (likely reuse
`PlaceFacts`-shaped or `PlaceInfoGrid`'s existing cell type). **Done-when:** 3-cell snapshot + AX5.

### Task 1.7 — `ConfirmationRow` (`DesignSystem/Components/ConfirmationRow.swift`)
Ports `.conf-row`: a `surfaceGrouped` row, mono-caps `.k` + large mono `.v` (`user-select: all` →
`.textSelection(.enabled)`), a trailing neutral copy button (`.cp`, glyph `doc.on.clipboard`). Caller:
`code: String`, `onCopy: () -> Void`, `accessibilityID` passthrough (`booking.confirmation`).
**Done-when:** 1 snapshot; the copy button is a real sink (UIPasteboard write at the screen, not here).

### Task 1.8 — `DetailList` (+ row type) (`DesignSystem/Components/DetailList.swift`)
Ports `.det-list`/`.det-rows`/`.det-row`: a mono-caps section head (`.det-head`) + a `surfaceGrouped`
clipped list of key/value rows separated by hairlines (last has none). Value: `head: String`,
`rows: [DetailListRow(key, value)]`. A11y: head as heading; each row combined. **Done-when:** snapshot
(5-row flight detail) + AX5.

### Task 1.9 — `PlacedChip` (`DesignSystem/Components/PlacedChip.swift`)
Ports `.placed`: a `fillTertiary` pill with a check glyph + "Placed on Day N · date". Value: `text`,
`systemImage` (default `checkmark`). **Done-when:** 1 snapshot.

### Task 1.10 — `AccessPassCard` + `AccessPassModel` (`DesignSystem/Components/AccessPassCard.swift`)
**Decide OD-5 (QR renderer) first.** Exemplar: `ProvenanceCard` (a content card with a band + body) +
`MapSnippet` (a canvas placeholder). Ports `.acc-card`: a `paper-0` card with `Shadow.hero`, an
`.acc-band` (transport-tinted icon tile + name/meta, hairline below), an `.acc-qr` (the QR image +
`.cap` mono confirmation), and an `.acc-meta` 3-cell hairline grid (Gate/Seat/Zone). The card itself is
CONTENT (never glass). The QR per OD-5:
- **Default (recommended):** render a real QR with `CoreImage.CIFilterBuiltins.CIQRCodeGenerator` from
  the confirmation/pass payload string — deterministic, light-mode, no dependency. A small private
  `QRCodeView(payload:)` subview in this file (or `DesignSystem/Components/QRCodeView.swift`).
```
struct AccessPassModel: Sendable {
    let kindLabel: String      // "Boarding pass"
    let title: String          // "LIS → JFK · TP 201"
    let subtitle: String       // "Zé Maria · Sat, Aug 29 · boards 13:05"
    let type: BookingType      // tint for the band icon
    let systemImage: String
    let qrPayload: String      // the string encoded into the QR
    let confirmation: String   // .cap mono
    let metaCells: [(key: String, value: String)]   // Gate/Seat/Zone
}
```
**Done-when:** card renders with a deterministic QR (fixed payload → identical pixels); 1 component
snapshot of the *card* (NOT the dark takeover chrome — see L3 note). AX5 of the card.

### Task 1.11 (optional small) — `WalletEmptyGlyph`
The empty hero glyph (`.empty .glyph` + accent `.badge`). May be a private subview inside the
wallet-empty screen instead of a shared component (promote only if a 2nd screen needs it). Default:
**private subview in the wallet screen**, not a component task. Listed for completeness.

**WAVE-1 EXIT (mini-freeze):** all of 1.1–1.10 compiled, design-reviewed (semantic-tokens-only, Dynamic
Type, glass-on-chrome-only, accent ≤2/screen, slop scan), and each component's render snapshot committed
& green. Only then dispatch Wave 3.

---

## 3. WAVE 2 — Models + Networking (parallel, disjoint files)

### Task 2.1 — Domain models + leaf value types (`swift-model-scaffold`)
Files (all new, disjoint): `Models/BookingModel.swift` (container `TripWalletModel` + row
`BookingModel`), `Models/BookingType.swift`, `Models/BookingStatus.swift`, `Models/BookingDetailInfo.swift`,
`Models/AccessPass.swift`.
Exemplar: `Models/SavedPlaceModel.swift` (container + row, both `@MainActor @Observable final class`,
identity equality, `restore(from:)` seam) and `Models/PlaceSource.swift` (associated-value Codable enum),
`Models/PlaceFacts.swift`/`PlaceLocation.swift` (nonisolated leaf value types).

**Reference models** (mutable list rows → reference, per 02-models §1):
```
@MainActor @Observable final class TripWalletModel: Identifiable {
    let id: String
    var tripCityName: String        // "Lisbon" (hero context)
    var dayCount: Int               // 4
    var bookings: [BookingModel]
    func booking(id: BookingModel.ID) -> BookingModel?   // lookup helper
    // Tier-1 mutations for the orphan-placement write (mirror SavedPlacesModel.insert/reconcile/rollback):
    func place(bookingID: BookingModel.ID, onDay dayIndex: Int)   // sets the booking's dayIndex
    func restoreDay(bookingID:, to previousDayIndex: Int?)        // rollback seam
}

@MainActor @Observable final class BookingModel: Identifiable {
    let id: String
    var title: String
    var type: BookingType
    var status: BookingStatus            // value enum (derive vs store — see note)
    var dayIndex: Int?                   // nil = orphan (not yet placed)
    var startTime: String?               // "10:00" / "Departs 13:40" (display string; no live clock)
    var subtitleParts: [String]          // ["timed entry","2 adults"] etc.
    var confirmation: String?
    var detail: BookingDetailInfo?       // value type — the booking-detail payload
    var accessPass: AccessPass?          // value type — present iff this booking has a day-of pass
    func restore(from dto: BookingDTO)   // rollback seam (mirror SavedPlaceModel.restore)
}
```
**Leaf value types** (`nonisolated`, `Codable, Equatable, Hashable, Sendable`):
```
nonisolated enum BookingType: String, CaseIterable, Codable, …  { case lodging, transport, activity, dining, other; var displayLabel; var systemImage }
nonisolated enum BookingStatus: String, Codable, …             { case upcoming, today, now, past }
nonisolated struct BookingDetailInfo: Codable, …  { var kind: String; var infoCells: [InfoCell]; var detailRows: [DetailRow]; var placedLabel: String? }
nonisolated struct InfoCell: Codable, …           { var key, value: String; var sub: String? }   // or reuse PlaceFacts
nonisolated struct DetailRow: Codable, …          { var key, value: String }
nonisolated struct AccessPass: Codable, …         { var kindLabel, title, subtitle, qrPayload, confirmation: String; var metaCells: [InfoCell] }
```
**Decision note (status):** the mockup shows Now/Today/Upcoming/Past relative to a pinned date. Per
02-models §2/§6, **never read the live clock** — either (a) store `status` as seeded value data (simplest,
deterministic, matches the mockup), or (b) compute from `dayIndex` + `store.simulatedNow` + a per-booking
date. **Recommend (a) seeded `status`** for the milestone (no live-clock derivation) and surface the
"compute from simulatedNow" upgrade as OD-3. The `systemImage` per type lives on `BookingType`, keeping
SwiftUI out of the model.

**Done-when:** both reference models are `@MainActor @Observable final class`, not Codable; leaves are
`nonisolated`; cross-refs use `BookingModel.ID`; `restore(from:)` present; compiles (DTO forward-ref ok
until 2.2).

### Task 2.2 — DTOs + mapping (`swift-model-scaffold`)
Files: `Networking/Responses/DTO/BookingDTO.swift`, `Networking/Responses/DTO/TripWalletDTO.swift`.
Exemplar: `Networking/Responses/DTO/PlaceDTO.swift` + `SavedPlacesDTO.swift`.
```
nonisolated struct BookingDTO: Codable, Equatable, Sendable { /* field-for-field mirror of BookingModel */ }
extension BookingDTO { @MainActor func toDomain() -> BookingModel }
extension BookingModel { func toDTO() -> BookingDTO }
nonisolated struct TripWalletDTO: Codable, Equatable, Sendable { var id; var tripCityName; var dayCount; var bookings: [BookingDTO] }
extension TripWalletDTO { @MainActor func toDomain() -> TripWalletModel }
extension TripWalletModel { func toDTO() -> TripWalletDTO }
```
**Done-when:** mapping TOTAL both ways; round-trip `dto.toDomain().toDTO() == dto` holds (tested 4.x with
a **plain symmetric coder**, not `APIJSON`); leaves reused unchanged.

### Task 2.3 — Endpoints (`swift-networking-endpoint`) — one file each
Files: `Networking/Requests/GetWalletRequest.swift`, `Networking/Requests/PlaceOrphanRequest.swift`.
Exemplar: `GetSavedPlacesRequest.swift` (read, `.zero` latency, 404 on missing seed) + `AddPlaceRequest.swift`
(write, `.milliseconds(...)` latency, body, canned `mockResponse`).
```
nonisolated struct GetWalletRequest: APIRequest {                  // GET /wallet
    typealias Response = TripWalletDTO
    var path = "/wallet"; var method: HTTPMethod = .get; var mockLatency = .zero
    func mockResponse(from seed: MockSeed) throws -> TripWalletDTO {
        guard let wallet = seed.wallet else { throw APIError.status(404) }; return wallet
    }
}
nonisolated struct PlaceOrphanRequest: APIRequest {               // POST /wallet/bookings/{id}/place
    let id: BookingModel.ID; let dayIndex: Int
    typealias Response = BookingDTO
    var path: String { "/wallet/bookings/\(id)/place" }; var method: HTTPMethod = .post
    var mockLatency: Duration = .milliseconds(600)
    var body: (any Encodable & Sendable)? { PlaceOrphanBody(dayIndex: dayIndex) }
    func mockResponse(from seed: MockSeed) throws -> BookingDTO { /* compute placed booking from seed */ }
}
nonisolated struct PlaceOrphanBody: Encodable, Sendable { var dayIndex: Int }
```
**Endpoint count depends on OD-4** (does the orphan "Pin to Day N" persist? does add-to-wallet persist?).
If the milestone keeps writes local-only (like onboarding's deferral), `PlaceOrphanRequest` is still the
recommended one networked write to exercise the optimistic+rollback machinery (mirrors Saved's `addPlace`).
**Done-when:** each is one file; verb/method agree; `mockResponse` pure from seed; **do NOT edit
`APIClient`/`MockProvider`/`LiveProvider`**.

### Task 2.4 — Seed + scenario wiring
Files: `Models/SampleData/SampleData+Wallet.swift` (new), plus SERIAL edits to
`Networking/MockSeed.swift` (add `var wallet: TripWalletDTO?` field, defaulted),
`Networking/MockScenario.swift` (add `.walletStandard`, `.walletEmpty`, `.walletError` cases), and
`Models/SampleData/SampleData.swift` (add the new cases to `seed(for:)`).
Exemplar: `SampleData+Saved.swift` (DTO builders callable from `seed(for:)`; `@MainActor` reference-graph
builders calling `toDomain()`; stable literal ids; pinned `simulatedNow`).
- `walletDTO()` — the populated Lisbon wallet faithful to `wallet-populated.html`: 4 days, 8 bookings
  (Day 1 past ×2: Casa do Bairro lodging, Time Out Market dining; Day 2 today: Castelo de São Jorge
  activity-**now**, Ferry to Cacilhas transport-today; Day 3: Jerónimos activity, Belcanto dining; Day 4:
  TAP Air transport with an `accessPass`), **plus 1 orphan** (Fado at Tasca do Chico, activity, dayIndex
  nil) so the orphan prompt + the "Orphans · 1" chip render. Hero context "Lisbon · 4 days · 8 bookings".
- `emptyWalletDTO()` — a wallet with 0 bookings (or the trip context with empty `bookings`) → the rich
  empty state.
- `walletAccessPass()` — the booking-detail/access fixture (TP 201, gate 24, seat 14A, zone 2,
  conf 7XQK2M, `qrPayload`) faithful to `booking-detail.html`/`access-card.html`.
- Stable ids: `booking-tap201`, `booking-fado-orphan`, etc. Pin `walletSimulatedNow` to the mockup
  "today = Thu Aug 27" instant (so the `now`/`today` statuses are deterministic — and if OD-3 picks
  computed status later, this is the seam).
- `seed(for:)`: `.walletStandard → MockSeed(wallet: walletDTO())`, `.walletEmpty → MockSeed(wallet:
  emptyWalletDTO())`, `.walletError → MockSeed(wallet: walletDTO())` (error via `failureRate: 1.0`).

**Done-when:** `SampleData.walletDTO()` builds the exact 8-bookings-+-1-orphan set; reference-graph
builder round-trips through `toDomain()`; `MockSeed`/`MockScenario`/`seed(for:)` extended without breaking
existing `.empty`/saved/onboarding seeds (all fields defaulted).

### Task 2.5 — Store load + command (SERIAL on `AppStore.swift`; new `AppStore+Wallet.swift`)
Files: SERIAL edit `Store/AppStore.swift` (add `private(set) var wallet: TripWalletModel?`,
`var walletLoadState: LoadState = .idle`, a `setWallet(_:)` same-file seam, a `loadSeed(wallet:)` seam,
and a `static func preview(wallet:)` factory — all mirroring the existing `savedPlaces` members); add a
`WriteError` case `.placeOrphan` (SERIAL on `Store/WriteError.swift`). New `Store/AppStore+Wallet.swift`.
Exemplar: `Store/AppStore+Saved.swift` (`loadSavedPlaces` read path; `addPlace` optimistic+rollback).
```
extension AppStore {
    func loadWallet() async { /* .loading → GetWalletRequest → setWallet(dto.toDomain()) → .loaded ; catch → setWallet(nil), .failed */ }
    func placeOrphan(bookingID: BookingModel.ID, onDay dayIndex: Int) async {
        // optimistic: capture previous dayIndex; wallet.place(bookingID:onDay:); fire PlaceOrphanRequest;
        // reconcile from resolved DTO; on failure wallet.restoreDay(...) + writeError = .placeOrphan
    }
}
```
**Done-when:** read path mirrors `loadSavedPlaces`; the write is optimistic-then-reconcile with a
`restore`/`restoreDay` rollback path + `writeError`; the command holds no raw graph mutation (each is a
`TripWalletModel` method, Tier-1). Flag `AppStore.swift` + `WriteError.swift` as serial shared-file edits.

---

## 4. WAVE 3 — Screens (each: scaffold → consistency-review → fidelity-review)

Owning agent: **`swift-screen-builder`**. Reviewers: **`swift-code-reviewer`** (consistency) +
**`fidelity-reviewer`** (vs the named mockup). **One screen = one task.** Build the interactivity
inventory before "done"; every affordance hits one sink (model method / store command / route /
ephemeral `@State`); a destination that doesn't exist is a wired stub or an OPEN DECISION, never an
invented screen.

### Task 3.0 — Navigation substrate (SERIAL — resolve OD-1 first)
Files (SERIAL): `Screens/Routes/WalletRoute.swift` (new), `Screens/Routes/BookingDetailRoute.swift` (new),
`App/RootView.swift` (register destinations on the Trip tab stack), and **possibly** `Models/AppTab.swift`
(only if OD-1 chooses a dedicated `.wallet` tab — recommended NO).
Exemplar: `Screens/Routes/PlaceDetailRoute.swift` + `App/RootView.swift`'s `case .saved` block
(swap-in pattern: tab root → real screen + `.navigationDestination(for:)`).
```
struct WalletRoute: Hashable {}                          // the wallet itself (pushed in the Trip stack)
struct BookingDetailRoute: Hashable { let id: BookingModel.ID }
```
**Per the mockups (decisive):** the wallet tab bar shows **Trip · Map · Saved · You** and the wallet
topbar's back reads **"‹ Trip"** → **Wallet is a `.detail` screen pushed inside the Trip tab stack**, NOT
a new tab. So:
- In `RootView.stack(for: .trip)`: register `.navigationDestination(for: WalletRoute.self)` →
  `WalletView()` and `.navigationDestination(for: BookingDetailRoute.self)` → `BookingDetailView(bookingID:)`.
- The Trip tab root is still `comingSoon` this milestone. **OD-1: how does the user reach Wallet?** The
  Trip-tab home that pushes `WalletRoute` is a separate, unspecified story. Options surfaced below — the
  coordinator must settle it before 3.1 ships (the wallet screen itself is buildable; its *entry point*
  is the open question). **Recommended interim:** add a single "Travel wallet" affordance to the
  `comingSoon` Trip placeholder that pushes `WalletRoute` (a wired stub entry, not a fabricated Trip home),
  AND register the wallet in `ScreenCatalogView` — **except there is no catalog yet** (see OD-6).
**Done-when:** routes are one-file `Hashable`; destinations registered once at the Trip root; tab bar
persists across the push (`.detail` chrome). Flag `RootView.swift` (+ `AppTab.swift` if OD-1 says so) as
serial edits.

### Task 3.1 — `WalletView` + `WalletPresenter` (`Screens/Wallet/`)
**Named mockups:** `mockups/screens/wallet/wallet-populated.html` (populated) **and**
`wallet-empty.html` (empty) — one screen, two states (like `SavedListView`'s four states).
Exemplar: `Screens/Saved/SavedListView.swift` + `SavedListPresenter.swift`.
- **Chrome:** `ScreenScaffold(.detail(title: "Travel wallet"))` — pushed in the Trip stack, inline title,
  automatic back (the mockup `.screen-topbar` with `‹ Trip` + centered "Travel wallet"). The "+" add is
  the **one secondary top control** — per the Saved interim (06 §2.6: no scaffold trailing-control slot),
  render it in-content as an `addAffordanceRow` (id `wallet.add`) OR via the scaffold's trailing slot if
  one now exists — mirror exactly what `SavedListView.addAffordanceRow` does.
- **Presenter derives** (DATA, never Views): `heroContext` ("Lisbon · 4 days · 8 bookings"); `isEmpty`;
  `filterChips` (By day [on] / By type / Orphans + count + dot); `orphan: OrphanPromptModel?`;
  `dayGroups: [WalletDayGroup]` each (`dayLabel`, `dateLabel`, `isToday`, `rows: [BookingRowModel]`);
  the empty-state copy + `wayToSave: [WayToSaveRowModel]` (Forward / Scan / From a photo). Sort/group by
  `dayIndex`; past days dim via `BookingRowModel.isPast`.
- **Composition:** `ScreenSection`/`RhythmSpacer`; the orphan card (`OrphanPromptCard`), `DayGroupHeader`
  + `BookingRow`s per group, the filter chips (reuse `FilterChip`), the empty `WayToSaveRow`s + the
  empty glyph.
- **Interactivity inventory → sinks:**
  | Affordance | Sink |
  |---|---|
  | "+" add (`wallet.add`) | `@State showsAddSheet` → presents `AddToWalletSheet` (Task 3.4) |
  | filter chips By day/By type/Orphans | `@State walletFilter` (presenter re-derives) |
  | BookingRow tap (`bookingrow.<id>`) | `store.push(BookingDetailRoute(id:))` |
  | OrphanPrompt "Pin to Day N" (`orphan.pin`) | `await store.placeOrphan(bookingID:onDay:)` (the write) — OR ephemeral if OD-4 keeps it local |
  | OrphanPrompt "Not now" (`orphan.dismiss`) | `@State` dismiss (hide the prompt this session) — local, no graph mutation |
  | OrphanPrompt row tap (`orphan.row`) | `store.push(BookingDetailRoute(id:))` |
  | empty WayToSaveRow taps (`waytosave.<id>`) | `@State showsAddSheet` (all three open the add sheet; deeper capture flows are separate stories) |
  | writeError banner (`writeError.banner`) | reads `store.writeError == .placeOrphan` |
- **`.task`:** `if store.wallet == nil { await store.loadWallet() }` (idempotent).
- **`#Preview`s:** `AppStore.preview(wallet: SampleData.walletDTO())` (populated) and
  `…(wallet: SampleData.emptyWalletDTO())` (empty) — wrapped in `NavigationStack`.
- **a11y ids:** `wallet.add`, `walletfilter.byday|bytype|orphans`, `bookingrow.<id>`,
  `daygroup.<index>`, `orphan.pin|dismiss|row`, `wallet.emptyState`, `waytosave.<id>`, `writeError.banner`.
**Done-when:** composes `ScreenScaffold(.detail)`; names mockups `wallet-populated.html`+`wallet-empty.html`;
all ids present; no dead closures; fidelity-reviewed; L3 snapshot (it's a scaffolded scrolling screen —
should render; the `now`-pill is static so it's snapshot-safe).

### Task 3.2 — `BookingDetailView` + `BookingDetailPresenter` (`Screens/Wallet/`)
**Named mockup:** `mockups/screens/wallet/booking-detail.html`.
Exemplar: `Screens/Saved/PlaceDetailView.swift` (`.custom` over-hero header pattern) — but booking-detail
is simpler: it has **no full-bleed photo hero**; it has a normal `.bd-hero` (icon tile + kind + name +
status pill + meta) with a `.screen-topbar.--over-hero` (back + Share). So:
- **Chrome:** `ScreenScaffold(.detail(title: presenter.kindTitle))` is the natural fit (inline title
  "Flight" + back "Wallet", tab bar persists). The mockup's `--over-hero` topbar is a stylistic variant
  (no hairline) over a non-photo hero; `.detail` is acceptable. **If** the fidelity-reviewer rules the
  share-glyph + the borderless topbar require own-chrome, escalate to `.custom` + `GlassCircleButton`
  overlay (mirror `PlaceDetailView`) — note this as a fidelity contingency, not a default.
- **Presenter derives:** `kindTitle` ("Flight"); the hero (`type`, `systemImage`, `kindEyebrow`
  "TAP Air Portugal · TP 201", `name` "Lisbon → New York", `status`, `metaLine`); `infoCells`
  (Depart/Arrive/Seat); `confirmation`; `detailList` (the `.det-list` rows); `placedLabel`; whether an
  `accessPass` exists (drives the CTA).
- **Composition:** the hero block, `BookingInfoGrid`, `ConfirmationRow`, `DetailList`, `PlacedChip`, and
  the bottom `ActionBar` "Show boarding pass" CTA when an access pass exists.
- **Interactivity → sinks:**
  | Affordance | Sink |
  |---|---|
  | Back (`bookingdetail.back`) | `store.pop()` (own-back only if `.custom`; else the system back) |
  | Share (`bookingdetail.share`) | **wired stub** — D-style: no share sheet built; `@State` notice (surface OD-8) |
  | Copy confirmation (`booking.confirmation` copy) | `UIPasteboard.general.string = code` (a real effect) |
  | "Show boarding pass" (`bookingdetail.showPass`) | `@State showsAccessPass` → `.fullScreenCover` presents `AccessCardView` (Task 3.3) |
- **`#Preview`s:** the TP 201 booking (has pass) + a no-pass booking, seeded via
  `AppStore.preview(wallet:)` then `BookingDetailView(bookingID: "booking-tap201")`.
- **a11y ids:** `bookingdetail.back`, `bookingdetail.share`, `booking.confirmation`,
  `bookingdetail.showPass`.
**Done-when:** names `booking-detail.html`; ports the hero/grid/conf/detail/placed/CTA; the pass CTA
presents the takeover; copy works; fidelity-reviewed. **L3:** see note — if `.custom`+over-hero, screen
snapshot is DEFERRED (offscreen-blank gap); covered by L1+L4 + the component snapshots.

### Task 3.3 — `AccessCardView` (`Screens/Wallet/`)
**Named mockup:** `mockups/screens/wallet/access-card.html`. **The interactivity-inventory destination of
the booking-detail "Show boarding pass" affordance — its own screen task (06 §4.1), never folded into 3.2.**
Exemplar: chrome pattern from onboarding `.fullScreenCover` + `.immersive`; `GlassCircleButton` for the ×.
- **Chrome:** `ScreenScaffold(.immersive)` (tab bar hidden) presented as a `.fullScreenCover` — a dark
  (`ink900`) takeover. The mockup is a dark ground with a white-status-bar `.acc-top` (label + close ×),
  the centered `AccessPassCard`, and an `.acc-hint`. Brightness-raise ("Screen brightness raised") is a
  real-device affordance — **wire it as a `UIScreen.main.brightness` set on appear / restore on
  disappear, OR a wired no-op with the hint copy** (surface OD-8 nuance; recommend the real brightness
  bump, restored on dismiss).
- **Composition:** `AccessPassCard` (the Wave-1 component, with its deterministic QR) centered on the
  dark ground; the close × (`GlassCircleButton` or a plain glyph — note the × in the mockup is a faint
  white circle, not glass; a plain styled button is fine and avoids the glass-offscreen-blank gap).
- **Interactivity → sinks:** close × (`accesscard.close`) → `dismiss()`; the QR + confirmation are
  display-only (the `.cap` is `.textSelection(.enabled)`).
- **`#Preview`:** the TP 201 pass via a fixture; standalone (no nav).
- **a11y ids:** `accesscard.close`, `accesscard.pass` (the card), `accesscard.confirmation`.
**Done-when:** names `access-card.html`; presents as a dark immersive takeover; QR renders deterministically;
the close dismisses. **L3:** the dark `ignoresSafeArea` takeover renders blank offscreen — screen snapshot
DEFERRED; covered by the `AccessPassCard` component snapshot (Task 1.10) + L4.

### Task 3.4 — `AddToWalletSheet` + `AddToWalletPresenter` (`Screens/Wallet/`)
**Named mockups:** `mockups/screens/wallet/add-method.html` (method picker) **and** `add-review.html`
(the AI-extracted review). One sheet, two phases (method → review), like the Saved `AddPlaceSheet` but
with a second confirm step.
Exemplar: `Screens/Saved/AddPlaceSheet.swift` (sheet = solid at rest, own grabber/header/×, method list,
the write + write-error banner, the in-flight progress).
- **Chrome:** a `.sheet(isPresented:)` from `WalletView`'s `@State`, `.presentationDetents([.medium,
  .large])`, own grabber + header (title "Add to wallet" / "Check the details" + close ×). Solid, not
  glass at rest.
- **Phase A (method):** `WayToSaveRow`s (Forward a confirmation [prominent] / Scan a pass or ticket /
  From a photo) + the `.fwd-addr` "Or forward email to wallet@aitravel.app" copy row.
- **Phase B (review):** an `AIVoice` eyebrow ("Read from your screenshot"), a `rev-card` of fields
  (Type [icon chip] / Name / When [low-confidence italic + a "verify" tag] / Where / Confirmation [mono]),
  the "Add to wallet" CTA (`PillButton(.primary)`) + an "Edit details" ghost.
- **Interactivity → sinks:**
  | Affordance | Sink |
  |---|---|
  | "Forward a confirmation" (prominent) | advances to Phase B (`@State phase`) — and/or fires the write per OD-4 |
  | "Scan" / "From a photo" | wired `@State pendingMethod` stub (deeper capture flows are separate stories) |
  | copy email (`addwallet.copyEmail`) | `UIPasteboard` write |
  | "Add to wallet" CTA (`addwallet.confirm`) | `await store.placeOrphan(...)` / a wallet add command (OD-4) → on success dismiss + the booking appears; on failure the banner |
  | "Edit details" ghost (`addwallet.edit`) | wired `@State` stub (manual-edit flow is a separate story) |
  | close × (`addwallet.close`) | `dismiss()` |
  | writeError banner (`writeError.banner`) | reads `store.writeError` |
- **The 800ms-style latency** of the write surfaces a progress affordance + disables re-taps (mirror
  `AddPlaceSheet.isAdding`).
- **`#Preview`s:** method phase + review phase + write-error, seeded via `AppStore.preview(wallet:)`.
- **a11y ids:** `addwallet.method.<id>`, `addwallet.copyEmail`, `addwallet.confirm`, `addwallet.edit`,
  `addwallet.close`, `addwallet.field.<key>`, `addwallet.progress`.
**Done-when:** names `add-method.html`+`add-review.html`; two-phase flow wired; the one write goes through
the store (optimistic+rollback) with the banner on failure; no dead closures. **L3:** sheet content renders
blank offscreen → screen snapshot DEFERRED; covered by L1 (presenter) + L4 + the `WayToSaveRow`/`AIVoice`
component snapshots.

---

## 5. WAVE 4 — Tests (the four-layer pyramid)

Targets: `AppTemplateTests` (L1–L3, Swift Testing + swift-snapshot-testing), `AppTemplateUITests` (L4,
XCTest). Exemplars: `AppTemplateTests/{Models,Screens,Store,Snapshots/Saved}/…`, `AppTemplateUITests/
SavedFlowUITests.swift`. Determinism: `SampleData.walletDTO()` + `walletSimulatedNow`, never the live clock;
assert on fields (reference models are identity-equal); index by stable id.

### Task 4.1 — L1 unit (`swift-test-writer`)
Files: `AppTemplateTests/Models/BookingDTORoundTripTests.swift`,
`AppTemplateTests/Models/BookingModelTests.swift`,
`AppTemplateTests/Screens/WalletPresenterTests.swift`.
- **DTO round-trip:** `BookingDTO`/`TripWalletDTO` `toDomain().toDTO() == dto` with a **plain symmetric
  `JSONEncoder`/`JSONDecoder`** (NOT `APIJSON` — the acronym caveat). Guards mapping drift.
- **Model methods:** `TripWalletModel.place(bookingID:onDay:)` sets `dayIndex`; `restoreDay(...)` reverts;
  `booking(id:)` returns the ref / nil; `BookingType.systemImage`/`displayLabel`; `BookingStatus` mapping.
- **Presenter:** seed a store, build `WalletPresenter`, assert `heroContext`, `dayGroups` count/order
  (past days dim, today flagged), `orphan` present iff a nil-dayIndex booking exists, filter derivations,
  empty-state copy when `emptyWalletDTO()`. Plus a `BookingDetailPresenter` test (info cells, pass
  presence drives the CTA) and an `AddToWalletPresenter` test (the two phases' field derivations).
**Done-when:** every model method + presenter derived value has an assertion; round-trip green.

### Task 4.2 — L2 integration (`swift-test-writer`)
File: `AppTemplateTests/Store/AppStoreWalletTests.swift`. Exemplar: `AppTemplateTests/Store/AppStoreSavedTests.swift`.
- **Read path:** `await store.loadWallet()` via `.mock(scenario: .walletStandard)` → `wallet` populated,
  `.loaded`; `.walletEmpty` → empty graph; failure (`failureRate: 1.0`) → `.failed` + nil graph (no
  partial leak).
- **Write happy path:** `await store.placeOrphan(bookingID:onDay:)` → the orphan's `dayIndex` set,
  `writeError == nil`.
- **Write rollback:** `failureRate: 1.0` → `dayIndex` restored to nil, `writeError == .placeOrphan`.
- **Decode→DTO→domain:** `GetWalletRequest` response encodes/decodes (plain coder) and maps to a graph
  with the expected 8+1 bookings.
**Done-when:** every mutating command has happy + rollback; read path covers loaded/empty/failed.
**OD-4 note:** if the milestone defers the write (local-only, like onboarding's deferral), record a
`decisions.md` deferral entry and cover read-path failure + the local `place`/`restoreDay` model methods
at L1 instead — but **recommend keeping `placeOrphan` as the one real write** so the rollback machinery
isn't vestigial.

### Task 4.3 — L3 render snapshots (`swift-snapshot-test-writer`)
Files under `AppTemplateTests/Snapshots/Wallet/`. Exemplar: `Snapshots/Saved/{PlaceRow,SourceCard,
SavedScreen}SnapshotTests.swift` + `Support/DesignSnapshot.swift` (`assertDesignSnapshot`, the pinned
`canonicalConfig`, `#filePath`, `EXCLUDED_SOURCE_FILE_NAMES=*.png`).
- **Component snapshots (Wave 1, staged here):** `BookingRow` (5 states + AX5), `StatusPill` (4 + now-AX5),
  `DayGroupHeader` (2), `OrphanPromptCard` (1 + AX5), `BookingInfoGrid` (1 + AX5), `ConfirmationRow` (1),
  `DetailList` (1 + AX5), `PlacedChip` (1), `AccessPassCard` (1 + AX5 — the QR deterministic).
- **Screen snapshot:** `WalletView` populated + empty (the `.detail` scaffolded scrolling screen — it
  renders offscreen; the static `now`-pill is snapshot-safe). **`saved-list`-style naming:** `wallet`,
  `wallet-empty`.
- **DEFERRED (framework gap — record a `decisions.md` entry mirroring the 2026-06-06 Saved decision):**
  `BookingDetailView` (if `.custom`+over-hero), `AccessCardView` (dark `ignoresSafeArea` takeover), and
  `AddToWalletSheet` (sheet content) all render blank in the offscreen host → **no screen-level L3 baseline**
  for these three; they are covered by L1 + L4 + their component snapshots (`AccessPassCard`,
  `BookingInfoGrid`, `BookingRow`, `WayToSaveRow`, `AIVoice`). Do NOT commit blank baselines.
- Any glass surface (none of the wallet content uses glass except `ActionBar`/`GlassCircleButton` chrome,
  which also render blank offscreen) is excluded from component snapshots.
**Done-when:** every Wave-1 component has a committed, non-blank baseline; the wallet `.detail` screen
populated+empty are locked; the deferrals are documented.

### Task 4.4 — L4 XCUITest + a11y audit (`swift-uitest-writer`)
File: `AppTemplateUITests/WalletFlowUITests.swift`. Exemplar: `AppTemplateUITests/SavedFlowUITests.swift`
+ the broad-audit + `issueHandler` suppression pattern (`decisions.md` 2026-06-03).
- **Scenario injection:** the app reads `UITEST_SCENARIO` ∈ `walletStandard|walletEmpty|walletError`,
  `UITEST_FAILURE_RATE`, `UITEST_NOW` at launch (the seam already exists in `AppTemplateApp.init` for
  scenarios; **wire the new wallet scenarios + `UITEST_FAILURE_RATE` consumption** — note `UITEST_FAILURE_RATE`
  is currently an unconsumed hook per `decisions.md`; this is the write that activates it).
- **Reachability:** because Wallet is pushed inside the Trip tab (OD-1), the test taps `tab.trip` then the
  Trip-placeholder's "Travel wallet" entry (OD-1's interim affordance) to push `WalletRoute`, OR — if a
  catalog is added (OD-6) — reaches it via the catalog. Settle OD-1 before this test.
- **Table-driven across scenarios:** standard (rows present, orphan prompt shows), empty (no rows, three
  ways shown), error (the place-orphan write surfaces `writeError.banner`).
- **One real interaction per screen:** tap `bookingrow.booking-tap201` → `BookingDetailView` appears →
  tap `bookingdetail.showPass` → `accesscard.close` exists → close; tap `wallet.add` → `AddToWalletSheet`
  appears → close. Query by id only, `waitForExistence`, never `sleep`.
- **a11y audit:** broad `performAccessibilityAudit { }` per screen under `walletStandard`, suppressing
  only the documented, compensated types (`.dynamicType` → AX5 snapshots; `.contrast` over glass chrome →
  design-doc call; the static `now`-dot `.hitRegion` if it's informational). Each suppression is
  `(id, auditType)`-scoped + named-compensating, per the `decisions.md` rule.
- **Combined-container note:** if `BookingDetailView`'s grid/detail rows collapse to a container, assert
  the container + the above-fold interaction, not deep child ids (the Saved L4 lesson).
**Done-when:** every wallet screen is reachable + has one real interaction + a passing audit across its
scenarios; the place-orphan error path surfaces the banner.

---

## 6. Serial / shared-file edits (flag to the coordinator)

| File | Edit | Wave |
|---|---|---|
| `DesignSystem/Tokens/ColorRole.swift` | `bookingMark`/`bookingTint` | 1 |
| `DesignSystem/Tokens/Sizing.swift` | new `Sizing.Component` dims | 1 |
| `Networking/MockSeed.swift` | `var wallet: TripWalletDTO?` | 2 |
| `Networking/MockScenario.swift` | `.walletStandard/.walletEmpty/.walletError` | 2 |
| `Models/SampleData/SampleData.swift` | new `seed(for:)` cases | 2 |
| `Store/AppStore.swift` | `wallet` graph + `walletLoadState` + seams + `preview(wallet:)` | 2 |
| `Store/WriteError.swift` | `.placeOrphan` case | 2 |
| `App/RootView.swift` | register `WalletRoute`/`BookingDetailRoute` on the Trip stack | 3 |
| `Models/AppTab.swift` | ONLY if OD-1 chooses a dedicated `.wallet` tab (recommended NO) | 3 |
| `App/AppTemplateApp.swift` | wire wallet `UITEST_SCENARIO` + `UITEST_FAILURE_RATE` | 4 |

All other files are new and disjoint (parallelizable within a wave). The pbxproj uses synchronized
folders (objectVersion 77) so new files join the target automatically.

---

## 7. OPEN DECISIONS — settle before the dependent wave

1. **(OD-1, blocks 3.0/3.1/4.4) — How is the Wallet screen reached?** The mockups place it as a `.detail`
   pushed inside the **Trip** tab (`‹ Trip` back; tab bar Trip·Map·Saved·You), but the Trip tab is a
   `comingSoon` placeholder with no home this milestone. The wallet itself is buildable; its *entry point*
   is unspecified. Options: (a) **recommended interim** — add one "Travel wallet" affordance to the Trip
   placeholder that pushes `WalletRoute` (wired stub entry, no fabricated Trip home); (b) build a minimal
   Trip home now (out of scope — a separate story); (c) reach it only via a debug catalog (OD-6).
2. **(OD-2) — The `now` status-pill live dot pulse.** `wallet-shell.css` `.pill.now .lv` animates
   (`@keyframes lvp`). Per the deferred-pulse decision (2026-06-02 OD-2), build the dot **static** in
   `StatusPill` and add the continuous pulse only at the screen that owns a live "now" (here, `WalletView`),
   budgeted ≤1 continuous motion/screen and respecting Reduce Motion + the snapshot `disablesOneShotMotion`
   seam. Confirm: static dot for the milestone, pulse deferred? (Recommended: yes.)
3. **(OD-3) — Booking status: seeded vs computed.** Recommend storing `BookingStatus` as seeded value data
   (deterministic, matches the mockup, no live-clock derivation). Computing it from `simulatedNow` +
   per-booking dates is a later upgrade. Confirm seeded for now.
4. **(OD-4) — Which writes persist this milestone?** Two candidate networked writes: orphan "Pin to Day N"
   (`placeOrphan`) and add-to-wallet confirm. Recommend **one real write — `placeOrphan`** — to exercise
   optimistic+rollback (mirrors Saved's `addPlace`); the add-to-wallet confirm can either share that
   command's shape or be a local optimistic insert. If both are deferred to local-only, record a deferral
   (like onboarding) — but then the rollback machinery is vestigial. Confirm the write surface.
5. **(OD-5, blocks 1.10/3.3) — QR rendering.** The mockup uses a static `qr.svg`. Recommend rendering a
   **real, deterministic QR via CoreImage `CIQRCodeGenerator`** from the pass payload (no dependency,
   light-mode, snapshot-stable). Alternative: bundle `qr.svg` as a static asset (a fixed image, simpler but
   not data-driven). Confirm CoreImage QR vs static asset.
6. **(OD-6) — No `ScreenCatalogView` exists.** `06-screens §7` and the gates assume a catalog back-door,
   but this repo has none (onboarding/Saved shipped without it). Wallet inherits that absence. Confirm:
   skip the catalog (reach screens via `#Preview` + L4 only, as Saved did) — or introduce a catalog now
   (a new serial `ScreenCatalogView.swift`, out of this slice's scope unless requested).
7. **(OD-7) — Reuse `PlaceInfoGrid` for `BookingInfoGrid`?** Both are 3-cell hairline-separated key/value
   grids (`.info-grid` ≈ Saved's). If `PlaceInfoGrid`'s API + anatomy match the booking-detail grid,
   **reuse it** (skip Task 1.6) and feed it booking cells; otherwise build `BookingInfoGrid`. Needs a quick
   anatomy compare by the design agent. Recommend: reuse if the cell shape matches.
8. **(OD-8) — Stub affordances with no destination this milestone:** booking-detail **Share**, the
   add-sheet **Scan / From a photo / Edit details**, and the access-card **brightness raise**. Recommend
   wiring each to a real, testable sink (an in-content notice / `pendingMethod` `@State` / a real
   `UIScreen.brightness` bump) rather than an empty closure or an invented screen — exactly the Saved
   D-3/D-5 stub pattern. Confirm the stub treatment (and whether brightness-raise is real or copy-only).

---

## 8. Acceptance gates (per the four quality gates)

- **Mini-freeze:** Wave-1 components design-reviewed (semantic-tokens-only, Dynamic Type, glass-on-chrome-
  only, accent ≤2/screen, slop scan clean) + every component snapshot green, BEFORE any wallet screen
  scaffolds.
- **Consistency:** every wallet screen composes `ScreenScaffold` + `ScreenSection`/`RhythmSpacer`; no raw
  `.toolbar`/`.padding`/`ScrollView` for structure; no literals/primitives in views.
- **Fidelity:** each screen names its mockup and is fidelity-reviewed against it before acceptance.
- **Coverage:** every logic change ships an L1/L2 test (incl. the `placeOrphan` rollback); every component
  + the wallet `.detail` screen ship an L3 lock; the wallet flow ships an L4 test + a11y audit; the three
  offscreen-blank screens' L3 deferrals are documented in `decisions.md`.
- **Build clean** + all four layers green → finish-branch.
