/*
 The Wallet booking-detail screen. Layout + wiring only — all derivation lives in BookingDetailPresenter
 (06-screens §3); the booking is read off the store graph by id (06-screens §5). Ports the fidelity target
 mockups/screens/wallet/booking-detail.html: a normal (non-photo) `.bd-hero` (a type-tinted icon tile +
 a mono-caps kind eyebrow + the display name + a status pill + a meta line), a three-cell `.info-grid`,
 a `.conf-row` confirmation cell, a `.det-list` key/value list, a `.placed` chip, and a bottom "Show
 boarding pass" CTA in the thumb zone — shown only when the booking carries an access pass.

 Chrome: `ScreenScaffold(.detail(title: presenter.kindTitle))` — an inline title ("Flight") + the system
 automatic back ("Wallet"), the tab bar persisting on the push (06-screens §2.2). Unlike Saved's
 PlaceDetail, booking-detail has NO full-bleed photo hero — it has a normal content hero — so `.detail` is
 the right fit (no `.custom` escalation needed). The mockup's `.screen-topbar.--over-hero` borderless
 variant is a stylistic difference the fidelity-reviewer treats as substrate, not drift. (Fidelity
 contingency: if the Share glyph + borderless topbar are ruled to require own-chrome, escalate to `.custom`
 + a `GlassCircleButton` overlay mirroring PlaceDetailView — noted, not a default.)

 The Share control: `ScreenScaffold` exposes no trailing top-bar slot yet, and a screen must never
 hand-wire a raw `.toolbar` (06 §2.6), so — exactly like SavedListView's "+" interim — the Share glyph is
 rendered in-content as a trailing-aligned row carrying its `bookingdetail.share` id + a real sink.

 Interactivity inventory (06-screens §4.1 — every affordance hits a real sink, no dead closures):
  - Back                → the system automatic back (`.detail` chrome supplies it; no own-back to wire).
  - Share (`bookingdetail.share`) → STUB (OD-8): no share sheet is built this milestone, so the tap raises
                          an in-content notice (`@State showsShareNotice`), it does not present a sheet. A
                          wired stub (decisions.md), NOT a dead closure.
  - Copy confirmation (`booking.confirmation` copy) → `UIPasteboard.general.string = code` — a REAL effect
                          performed at the screen (the ConfirmationRow component is side-effect-free, 05 §8).
  - "Show boarding pass" (`bookingdetail.showPass`) → `@State showsAccessPass` →
                          `.fullScreenCover { AccessCardView(pass:) }` (Task 3.3 — the inventory
                          destination, never folded into this screen). Shown only when a pass exists.
*/
import SwiftUI

struct BookingDetailView: View {

    @Environment(AppStore.self) private var store

    let bookingID: BookingModel.ID

    /// Ephemeral UI state only (06 §3): the OD-8 Share stub surfaces this in-content notice — no share
    /// sheet is built this milestone. A wired stub sink, never domain state, never a toast/alert.
    @State private var showsShareNotice = false

    /// Ephemeral UI state only: presents the boarding-pass takeover (`AccessCardView`) as a full-screen
    /// cover from the CTA — the interactivity-inventory destination, never domain state.
    @State private var showsAccessPass = false

    /// The hero icon-tile side — a non-text metric, so it scales with Dynamic Type (T-6.4); mirrors
    /// BookingRow's `@ScaledMetric` tile.
    @ScaledMetric(relativeTo: .body) private var heroIconSide: CGFloat = Sizing.Component.bookingDetailIcon

    var body: some View {
        let presenter = BookingDetailPresenter(store: store, bookingID: bookingID)

        ScreenScaffold(.detail(title: presenter.kindTitle), actions: {
            // The one primary CTA, pinned in the reachable thumb zone (06 §2.4) — shown only when this
            // booking carries an access pass (the presenter drives the gate). Presents the AccessCardView
            // takeover; never folded into this screen (06 §4.1).
            if presenter.hasAccessPass {
                ActionBar(
                    primaryTitle: presenter.showPassTitle,
                    primaryAccessibilityID: "bookingdetail.showPass",
                    primaryAction: { showsAccessPass = true }
                )
            }
        }) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if presenter.hasBooking {
                    shareRow
                    hero(presenter)
                    if showsShareNotice {
                        shareNotice
                    }
                    if !presenter.infoCells.isEmpty {
                        // OD-7: REUSE PlaceInfoGrid — the booking info cells share `PlaceFacts`, the exact
                        // key/value/sub shape the place facts grid renders. No duplicate BookingInfoGrid.
                        PlaceInfoGrid(cells: presenter.infoCells)
                    }
                    if let code = presenter.confirmation {
                        ConfirmationRow(
                            code: code,
                            onCopy: { copyConfirmation(code) },
                            accessibilityID: "booking.confirmation"
                        )
                    }
                    if !presenter.detailRows.isEmpty {
                        DetailList(head: presenter.kindTitle, rows: presenter.detailRows)
                    }
                    if let placed = presenter.placedLabel {
                        PlacedChip(placed)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The boarding-pass takeover (Task 3.3) — presented only from the CTA, only when a pass exists, so
        // the force-unwrap below is guarded by the same gate that shows the CTA (06 §4.1).
        .fullScreenCover(isPresented: $showsAccessPass) {
            if let pass = presenter.accessPass {
                AccessCardView(pass: pass, type: presenter.type)
            }
        }
    }

    // MARK: - Share affordance (mockup `.screen-topbar .ic` Share — interim in-content placement, 06 §2.6)

    /// The Share glyph — the mockup's top-right control. INTERIM placement (06 §2.6): `ScreenScaffold`
    /// exposes no trailing top-bar slot, and a screen must never hand-wire a raw `.toolbar`, so this mirrors
    /// SavedListView's "+" interim — a trailing-aligned in-content row keeping the `bookingdetail.share` id
    /// + the `showsShareNotice` stub sink intact. OD-8: no share sheet is built, so the tap surfaces the
    /// in-content notice below, NOT a `ShareLink`/sheet (a wired stub, not a dead closure).
    private var shareRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                showsShareNotice = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                    .frame(width: heroIconSide, height: heroIconSide)
                    .background(ColorRole.fillTertiary, in: .circle)
                    .contentShape(.circle)
            }
            .accessibilityLabel("Share booking")
            .accessibilityIdentifier("bookingdetail.share")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Hero (mockup `.bd-hero`)

    /// The non-photo hero: a type-tinted icon tile beside the mono-caps kind eyebrow + display name, with a
    /// status pill + meta line below. CONTENT, never glass (J-0.1). The icon tile mirrors BookingRow's tinted
    /// well (`bookingTint`/`bookingMark`, the earned type taxonomy — never a card fill, J-2 / J-0.4).
    private func hero(_ presenter: BookingDetailPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .center, spacing: Spacing.lg) {
                if let systemImage = presenter.systemImage {
                    Image(systemName: systemImage)
                        .font(Typography.title.weight(.medium))
                        .foregroundStyle(ColorRole.bookingMark(presenter.type))
                        .frame(width: heroIconSide, height: heroIconSide)
                        .background(ColorRole.bookingTint(presenter.type), in: .rect(cornerRadius: Radius.row))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let eyebrow = presenter.kindEyebrow {
                        // The mono-caps eyebrow (mockup `.bd-kind`) — caps + eyebrow tracking at the call site.
                        Text(eyebrow)
                            .font(Typography.caption)
                            .tracking(Typography.trackEyebrowCaption)
                            .textCase(.uppercase)
                            .foregroundStyle(ColorRole.textTertiary)
                    }
                    Text(presenter.name)
                        .font(Typography.titleLarge)
                        .foregroundStyle(ColorRole.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // The status pill + meta line (mockup `.bd-sub`).
            HStack(spacing: Spacing.sm) {
                if let status = presenter.status {
                    StatusPill(status: status)
                }
                if let meta = presenter.metaLine {
                    Text(meta)
                        .font(Typography.subhead)
                        .foregroundStyle(ColorRole.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Share notice (OD-8 stub sink)

    /// The OD-8 Share stub's in-content notice: no share sheet is built this milestone, so the Share tap
    /// surfaces this rather than presenting a sheet (no toast, no alert — 06 §6). A real share flow replaces it.
    private var shareNotice: some View {
        Text("Sharing this booking is coming soon.")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .accessibilityIdentifier("bookingdetail.shareNotice")
    }

    // MARK: - Confirmation copy sink (a real effect — 05 §8 keeps the write at the screen)

    /// The copy sink: the ConfirmationRow component is side-effect-free, so the actual pasteboard write
    /// happens here at the screen (06 §4.1 / 05 §8) — a real effect, not a no-op.
    private func copyConfirmation(_ code: String) {
        UIPasteboard.general.string = code
    }
}

// MARK: - Previews — one per interesting state (06-screens §8)

#Preview("Booking detail — TP 201 (has pass)") {
    NavigationStack {
        BookingDetailView(bookingID: "booking-tap201")
    }
    .environment(AppStore.preview(wallet: SampleData.walletDTO()))
}

#Preview("Booking detail — Castelo (no pass)") {
    NavigationStack {
        BookingDetailView(bookingID: "booking-castelo")
    }
    .environment(AppStore.preview(wallet: SampleData.walletDTO()))
}
