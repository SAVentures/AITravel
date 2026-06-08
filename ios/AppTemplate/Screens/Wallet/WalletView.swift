/*
 The Travel-wallet keystone screen — the per-trip wallet that groups bookings by day, surfaces the AI
 orphan-placement prompt, and offers the add-to-wallet flow. Layout + wiring only; all per-state
 derivation lives in WalletPresenter (06-screens §3).

 Chrome: ScreenScaffold(.root(title: "Travel wallet")) — the Wallet tab root, so the large title
 collapses on scroll, the tab bar persists, and there is NO back button (it is a top-level tab, not
 pushed). The "+" add is the one secondary top control, passed to the scaffold's `trailingAction:` slot
 as a floating top-trailing `GlassCircleButton` (id `wallet.add`) — floated as chrome, never in scroll
 content (06 §2.6, J-0.1). NO bottom ActionBar — the wallet list mockups have none.

 Ports one structure across two states (the fidelity targets):
   mockups/screens/wallet/wallet-populated.html — heroContext + filter chips + the orphan prompt + per-day
                                                  DayGroupHeader + BookingRows.
   mockups/screens/wallet/wallet-empty.html      — no bookings → the WalletEmptyGlyph + three WayToSaveRows.

 Interactivity inventory (06 §4.1 — every affordance → one sink, no dead closures):
   - "+" add (scaffold trailingAction, wallet.add) → `showsAddSheet` @State → presents AddToWalletSheet.
   - filter chips (walletfilter.byday|…)      → `filter` @State (the presenter re-derives the grouping).
   - BookingRow tap (bookingrow.<id>)         → store.push(BookingDetailRoute(id:)).
   - OrphanPromptCard "Pin to Day N" (orphan.pin)   → await store.placeOrphan(bookingID:onDay:) (the write).
   - OrphanPromptCard "Not now" (orphan.dismiss)    → `orphanDismissed` @State (hides the prompt this session).
   - OrphanPromptCard row tap (orphan.row)          → store.push(BookingDetailRoute(id:)).
   - empty WayToSaveRow taps (waytosave.<id>)       → `showsAddSheet` @State (all three open the add sheet;
                                                      deeper capture flows are separate stories).
   - writeError.banner                        → reads store.writeError?.bannerMessage (a banner, never a
                                                  toast/alert — 06 §6).

 Logic out of the view: derivation → WalletPresenter; navigation → store.push; the write → store.placeOrphan.
 The view holds only ephemeral UI state (@State).
*/
import SwiftUI

struct WalletView: View {

    @Environment(AppStore.self) private var store

    // MARK: Ephemeral UI state only (06 §3) — never domain state

    /// The active grouping/filter — the FilterChip selection.
    @State private var filter: WalletFilter
    /// The add-to-wallet sheet flag — the "+" affordance and the empty-state ways present it.
    @State private var showsAddSheet = false
    /// Whether the orphan prompt has been dismissed this session (the "Not now" local sink — no graph
    /// mutation; the booking stays orphaned, the prompt simply hides).
    @State private var orphanDismissed = false

    /// Seeds the screen's *ephemeral UI state* so each `#Preview` (and a future deep link into a filter)
    /// renders a distinct state. The parameter defaults to the production launch state (by day), so the
    /// live call site stays `WalletView()`.
    init(filter: WalletFilter = .byDay) {
        _filter = State(initialValue: filter)
    }

    var body: some View {
        let p = WalletPresenter(store: store, filter: filter)

        ScreenScaffold(
            .root(title: "Travel wallet"),
            scrollDisabled: p.isEmpty,
            trailingAction: {
                GlassCircleButton(
                    systemImage: "plus",
                    accessibilityLabel: "Add to wallet",
                    accessibilityID: "wallet.add"
                ) { showsAddSheet = true }
            }
        ) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if let message = writeErrorMessage {
                    errorBanner(message)
                }

                if p.isEmpty {
                    emptyState(p)
                } else {
                    heroContext(p)
                    filterChips(p)
                    if !orphanDismissed, let orphan = p.orphan {
                        orphanPrompt(orphan, suggestedDay: p.suggestedDay, bookingID: p.orphanBookingID)
                    }
                    dayGroupsContent(p)
                }
            }
            .padding(.top, Spacing.md)
        }
        // Loads the wallet over the network (the seam confirmed in AppStore+Wallet). Idempotent:
        // re-hydrating only when the graph is still absent, so returning to the screen doesn't refetch.
        .task {
            if store.wallet == nil {
                await store.loadWallet()
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            AddToWalletSheet()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Hero context (mockup `.wal-sub .ctx`)

    private func heroContext(_ p: WalletPresenter) -> some View {
        Text(p.heroContext)
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
    }

    // MARK: - Filter chips (mockup `.wal-sub .chips`) — the FilterChip row

    private func filterChips(_ p: WalletPresenter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(p.filterChips) { chip in
                    FilterChip(
                        label: chipLabel(chip),
                        isSelected: filter == chip.filter,
                        action: { filter = chip.filter }
                    )
                    .accessibilityIdentifier("walletfilter.\(chip.filter.rawValue.lowercased())")
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    /// "Orphans 1" — the Orphans chip carries its unplaced count; the rest are bare labels.
    private func chipLabel(_ chip: WalletFilterChip) -> String {
        guard let count = chip.count, count > 0 else { return chip.label }
        return "\(chip.label) \(count)"
    }

    // MARK: - Orphan prompt (mockup `.orphan`)

    @ViewBuilder
    private func orphanPrompt(
        _ model: OrphanPromptModel,
        suggestedDay: Int,
        bookingID: BookingModel.ID?
    ) -> some View {
        OrphanPromptCard(
            model: model,
            onPin: {
                guard let bookingID else { return }
                Task { await store.placeOrphan(bookingID: bookingID, onDay: suggestedDay) }
            },
            onDismiss: { orphanDismissed = true },
            onSelect: {
                guard let bookingID else { return }
                store.push(BookingDetailRoute(id: bookingID))
            },
            pinAccessibilityID: "orphan.pin",
            dismissAccessibilityID: "orphan.dismiss",
            rowAccessibilityID: "orphan.row"
        )
    }

    // MARK: - Grouped content (mockup `.daygrp` + `.bk-list`)

    private func dayGroupsContent(_ p: WalletPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            ForEach(Array(p.dayGroups.enumerated()), id: \.element.id) { index, group in
                VStack(alignment: .leading, spacing: Spacing.md) {
                    DayGroupHeader(
                        dayLabel: group.dayLabel,
                        dateLabel: group.dateLabel,
                        isToday: group.isToday
                    )
                    .accessibilityIdentifier("daygroup.\(index)")
                    ForEach(group.rows) { row in
                        bookingRowButton(row)
                    }
                }
            }
        }
    }

    /// Wraps the content-only `BookingRow` in the tappable Button that pushes the booking detail and owns
    /// the `bookingrow.<id>` id (the component is content-only; the screen supplies the sink + id — 05 §8.1).
    private func bookingRowButton(_ row: BookingRowModel) -> some View {
        Button {
            store.push(BookingDetailRoute(id: row.id))
        } label: {
            BookingRow(model: row)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bookingrow.\(row.id)")
    }

    // MARK: - Empty state (mockup wallet-empty `.empty`)

    private func emptyState(_ p: WalletPresenter) -> some View {
        // Mockup `.empty`: the hero block (glyph · title · body) is horizontally AND vertically centered
        // in the viewport (`align-items/justify-content: center; height: 100%`); the three ways stay
        // full-width rows below. Spacers above/below the hero do the vertical centering within the scaffold.
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: Spacing.xl)

            VStack(spacing: Spacing.md) {
                WalletEmptyGlyph()
                Text(p.emptyTitle)
                    .font(Typography.titleLarge)
                    .foregroundStyle(ColorRole.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(p.emptyBody)
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Spacer(minLength: Spacing.xl)

            VStack(spacing: Spacing.md) {
                ForEach(p.wayToSave) { way in
                    WayToSaveRow(model: way, accessibilityID: "waytosave.\(way.id)") {
                        // All three ways open the add sheet; the deeper capture flows (scan/photo) are
                        // separate stories — wired here so nothing is a dead closure, the sheet routes them.
                        showsAddSheet = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wallet.emptyState")
    }

    // MARK: - Write-error banner (read off the store — never a toast/alert, 06 §6)

    private var writeErrorMessage: String? { store.writeError?.bannerMessage }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.destructive)
                .accessibilityHidden(true)
            Text(message)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("writeError.banner")
    }
}

// MARK: - WalletEmptyGlyph (mockup wallet-empty `.empty .glyph` + accent `.badge`)

/// The empty-state hero glyph: a quiet wallet mark on a grouped well, with a small accent "+" badge
/// pinned to its corner (mockup `.empty .glyph` + `.badge`). A private subview (per the plan's Task 1.11 —
/// promoted to a shared component only if a second screen needs it). The accent badge is the empty
/// screen's one earned accent moment (J-0.4/J-2.4): paired with the glyph, never colour alone. The badge
/// is decorative — the empty state already speaks its title/body — so it is hidden from a11y. Semantic
/// tokens only (J-0.2); the tile + badge scale with Dynamic Type (J-0.3).
private struct WalletEmptyGlyph: View {

    @ScaledMetric(relativeTo: .body) private var glyphSide: CGFloat = Sizing.Component.walletEmptyGlyph
    @ScaledMetric(relativeTo: .body) private var badgeSide: CGFloat = Sizing.Component.walletEmptyBadge

    var body: some View {
        Image(systemName: "wallet.bifold")
            .font(Typography.titleLarge)
            .foregroundStyle(ColorRole.textSecondary)
            .frame(width: glyphSide, height: glyphSide)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "plus")
                    .font(Typography.footnote.weight(.bold))
                    .foregroundStyle(ColorRole.textOnAccent)
                    .frame(width: badgeSide, height: badgeSide)
                    .background(ColorRole.actionPrimary, in: .circle)
                    .offset(x: badgeSide / 3, y: -badgeSide / 3)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Previews (06 §8) — one per state, seeded via AppStore.preview(wallet:), no `.shared`

#Preview("Wallet — populated") {
    NavigationStack {
        WalletView()
    }
    .environment(AppStore.preview(wallet: SampleData.walletDTO()))
}

#Preview("Wallet — empty") {
    NavigationStack {
        WalletView()
    }
    .environment(AppStore.preview(wallet: SampleData.emptyWalletDTO()))
}
