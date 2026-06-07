// WalletScreenSnapshotTests.swift — Layer 3 render-snapshot lock for Wallet SCREENS.
//
// These tests are the lock on the WalletView screen at authoring time. They do NOT verify
// the design (that is the fidelity-reviewer's authoring-time job); they freeze the accepted
// render so any later change that silently moves a pixel — spacing, color, font, border, icon
// substitution, shadow — fails the build.
// (07-testing §6 governing doc.)
//
// Component-level snapshots (BookingRow, StatusPill, DayGroupHeader, OrphanPromptCard,
// ConfirmationRow, DetailList, PlacedChip, AccessPassCard) are locked in Wave 1
// (Snapshots/Wallet/*SnapshotTests.swift). This file locks SCREENS ONLY — do not
// duplicate component states here.
//
// States covered (one snapshot each, per 07-testing §6.2):
//
//   WalletView
//     wallet              — populated wallet (SampleData.walletDTO()): the scrolling ScreenScaffold
//                           (.detail) with the hero context, FilterChip row, OrphanPromptCard, and
//                           DayGroupHeader + BookingRow groups co-occurring in one frame. The now-pill
//                           is a static StatusPill (no live clock, no animation) — snapshot-safe.
//     wallet-empty        — zero bookings (SampleData.emptyWalletDTO()): the rich WayToSaveRow empty
//                           state with the WalletEmptyGlyph hero instead of grouped content. Locks
//                           the empty-state layout from wallet-empty.html.
//     wallet-ax5          — AX5 compensating snapshot (§7.4). Same fixture as `wallet` at
//                           .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                           display-face hero context, FilterChip labels, and BookingRow name/meta
//                           text at the largest a11y size category.
//
// DEFERRED screen-level L3 (plan Task 4.3 + decisions.md — mirror 2026-06-06 Saved ruling):
//   BookingDetailView — if scaffolded as .custom + over-hero, the iOS-26 glass safeAreaInset path
//     mis-sizes in the offscreen host, producing blank frames. Covered by L1 (WalletPresenterTests/
//     BookingDetailPresenterTests) + L4 (WalletFlowUITests) + component snapshots (BookingInfoGrid,
//     BookingRow, ConfirmationRow, DetailList, PlacedChip). Restore screen-level L3 once
//     assertDesignSnapshot is rewritten to the drawHierarchy/key-window path.
//   AccessCardView — dark .ignoresSafeArea immersive takeover renders blank offscreen. Covered by
//     the AccessPassCard component snapshot (AccessPassCardSnapshotTests) + L4.
//   AddToWalletSheet — sheet content renders blank without a real sheet presentation context.
//     Covered by L1 (AddToWalletPresenterTests) + L4 + WayToSaveRow/AIVoice component snapshots.
//   Do NOT commit blank baselines (the 2026-06-03 onboarding-gate ruling applies).
//
// Determinism (07-testing §6.4):
//   · Live clock — SampleData.walletSimulatedNow is the pinned seed; no Date() anywhere.
//     The now/today BookingStatus values are seeded in SampleData.walletDTO() (seeded-status
//     approach, Task 2.1 decision (a)) and do not derive from the live clock.
//   · Animation — snapshots are at rest; no withAnimation in any body.
//   · One-shot entrance motion — designSystemEnvironment() injects .disablesOneShotMotion = true.
//   · Random data — only SampleData.walletDTO() / emptyWalletDTO().
//   · Font fallback — designSystemEnvironment() registers embedded fonts.
//   · StatusPill .now live-dot — the dot is rendered as a static view (OD-2 deferral in plan
//     Task 1.3); no continuous animation path; the frame is deterministic.
//
// Baselines land in __Snapshots__/WalletScreenSnapshotTests/ alongside this file.
// Committed PNGs are the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

// MARK: - WalletView snapshots

@Suite("WalletView screen snapshots")
struct WalletScreenSnapshotTests {

    // MARK: - Shared seeded stores
    //
    // @MainActor static vars: AppStore.preview(wallet:) + SampleData builders are
    // MainActor-isolated (Swift 6.2 MainActor-by-default module), so stored fixtures must be
    // actor-isolated. All consumer test methods are @MainActor so access is safe. (§6.6)

    @MainActor static var populatedStore: AppStore {
        AppStore.preview(wallet: SampleData.walletDTO())
    }

    @MainActor static var emptyStore: AppStore {
        AppStore.preview(wallet: SampleData.emptyWalletDTO())
    }

    // MARK: - wallet

    /// WalletView with a populated wallet (SampleData.walletDTO()), default .byDay filter.
    /// Renders: ScreenScaffold(.detail) chrome, the hero context ("Lisbon · 4 days · 8 bookings"),
    /// the "+" add affordance row, FilterChip row (By day / By type / Orphans), the OrphanPromptCard
    /// (one nil-dayIndex booking in the seed), and the DayGroupHeader + BookingRow groups sorted by
    /// day — all co-occurring on one frame. The StatusPill(.now) live-dot is static (OD-2 seeded).
    /// Confirms the populated layout from wallet-populated.html is correctly assembled.
    @Test("wallet — populated wallet, by-day filter: hero + chips + orphan prompt + day groups")
    @MainActor func walletPopulated() {
        assertDesignSnapshot(
            NavigationStack {
                WalletView()
            }
            .environment(Self.populatedStore),
            named: "wallet"
        )
    }

    // MARK: - wallet-empty

    /// WalletView with zero bookings (SampleData.emptyWalletDTO()).
    /// Renders the rich empty state from wallet-empty.html: WalletEmptyGlyph hero (badge composite),
    /// "No bookings yet" title + subtitle, and the three WayToSaveRow method rows (Forward / Scan /
    /// From a photo) instead of grouped content.
    /// Confirms the empty-state layout replaces ALL content zones when the wallet has no bookings.
    @Test("wallet-empty — zero bookings: WalletEmptyGlyph + WayToSaveRows empty state, no groups")
    @MainActor func walletEmpty() {
        assertDesignSnapshot(
            NavigationStack {
                WalletView()
            }
            .environment(Self.emptyStore),
            named: "wallet-empty"
        )
    }

    // MARK: - wallet-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as `wallet` at
    /// .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the display-face hero
    /// context line, FilterChip labels, BookingRow name/meta text, DayGroupHeader day + date
    /// labels, and OrphanPromptCard suggestion line at the largest accessibility size category.
    /// The .detail scaffold and content zones should scale correctly at AX5.
    @Test("wallet-ax5 — AX5: hero + chips + row text scale at accessibilityXXXL")
    @MainActor func walletAX5() {
        assertDesignSnapshot(
            NavigationStack {
                WalletView()
            }
            .environment(Self.populatedStore)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "wallet-ax5"
        )
    }
}
