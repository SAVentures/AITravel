/*
 AddToWalletSheet — the two-phase "Add to wallet" task sheet, presented from WalletView's ephemeral
 `@State` flag (`.sheet(isPresented:)`, 06-screens.md §6). Ports mockups/screens/wallet/add-method.html
 (phase A — the method picker) AND add-review.html (phase B — the AI-extracted review). One sheet, two
 phases, switched by an ephemeral `@State phase`.

 Chrome: a sheet, NOT glass at rest (glass is floating-chrome-only — 06 §6 / J-0.1). It draws its own
 grabber + header (title + close ×). Phase A shows three `WayToSaveRow`s (the prominent "Forward a
 confirmation" + standard "Scan"/"From a photo") and the `.fwd-addr` forward-to-email copy row. Phase B
 shows an inline AI provenance line (mockup `.rev-ai`), a review card of AI-extracted fields, the "Add to wallet" CTA, and an
 "Edit details" ghost.

 The ONE write (OD-4): the phase-B "Add to wallet" CTA runs `store.placeOrphan(...)` — the wallet slice's
 one optimistic, networked, store-owned-rollback write. MILESTONE SHORTCUT: a true "extract a brand-new
 booking from a screenshot" flow is a separate story (OD-4); to keep the optimistic+rollback machinery
 live (not vestigial) this confirm places the SEEDED orphan booking (`booking-fado-orphan`, the "Fado"
 the review card mirrors) onto day 2 — the same write the wallet's OrphanPrompt fires. On success the
 sheet dismisses (the booking appears placed); on failure `store.writeError` is set and the
 `writeError.banner` shows here (a banner, never a toast/alert — 06 §6). The write's latency surfaces as
 the `isAdding` progress affordance, which also disables re-taps (a single continuous loading state — J-9).

 Other affordances → sinks (no dead closures — 06 §4.1): the prominent "Forward" row advances to phase B
 (ephemeral `@State phase`); "Scan"/"From a photo" set an ephemeral `pendingMethod` read by an inline
 "coming soon" hint (OD-8 — deeper capture flows are separate stories); the forward-email row's copy
 button writes to `UIPasteboard`; the "Edit details" ghost sets an ephemeral `showsEditHint` stub
 (the manual-edit flow is a separate story); the close × dismisses.

 Logic out of the view: derivation → `AddToWalletPresenter`; the write → `store.placeOrphan`. The view
 holds only ephemeral UI state (`@State`).
*/
import SwiftUI
import UIKit

struct AddToWalletSheet: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// The sheet's two phases (06 §6 — a multi-step task sheet). Ephemeral UI state.
    private enum Phase { case method, review }

    /// Which phase is on screen. Starts at the method picker; the prominent "Forward" row advances to review.
    @State private var phase: Phase = .method

    /// True while `store.placeOrphan` is in flight — drives the CTA progress affordance and disables re-taps
    /// so the write latency reads as one state (04 §7 / J-9).
    @State private var isAdding = false

    /// A capture method tapped that has no destination yet (scan / photo). A placeholder sink so those rows
    /// are wired (06 §4.1), not dead closures — the future capture routes replace it (OD-8 / D-4).
    @State private var pendingMethod: String?

    /// True once "Edit details" is tapped — drives an inline stub hint (the manual-edit flow is a separate
    /// story). A real, testable effect rather than a dead closure (06 §4.1).
    @State private var showsEditHint = false

    /// Seeds the sheet's *ephemeral* starting phase. Defaults to the production entry (the method picker), so
    /// the live call site stays `AddToWalletSheet()`; the review/error `#Preview`s open on phase B directly.
    init(initialPhaseIsReview: Bool = false) {
        _phase = State(initialValue: initialPhaseIsReview ? .review : .method)
    }

    var body: some View {
        let p = AddToWalletPresenter(store: store, isAdding: isAdding)

        VStack(spacing: 0) {
            grabber
            header(p)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Direct read of store.writeError in body registers it as a SwiftUI @Observable
                    // dependency — the presenter also reads it, but through a struct intermediary that may
                    // not reliably trigger observation tracking on all SwiftUI runtime versions. This
                    // unambiguous direct read guarantees the sheet re-renders when writeError is set after a
                    // failed write (07-testing §6.6).
                    if store.writeError != nil, let message = p.writeErrorMessage {
                        errorBanner(message)
                    }

                    switch phase {
                    case .method: methodPhase(p)
                    case .review: reviewPhase(p)
                    }
                }
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .background(ColorRole.surfacePage)
        // The sheet draws its own header, so suppress the system grabber (we render `.sheet-handle`).
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Grabber + header (mockup `.sheet-handle` / `.sheet-head`)

    private var grabber: some View {
        Capsule()
            .fill(ColorRole.fillTertiary)
            .frame(width: grabberWidth, height: grabberHeight)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
            .accessibilityHidden(true)
    }

    private func header(_ p: AddToWalletPresenter) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(phase == .method ? p.methodTitle : p.reviewTitle)
                .font(Typography.title)
                .foregroundStyle(ColorRole.textPrimary)
            Spacer(minLength: Spacing.md)
            closeButton
        }
        .padding(.horizontal, Spacing.screenInset)
        .padding(.bottom, Spacing.md)
    }

    /// A quiet, content-density close × (the sheet is content, not glass chrome — J-0.1 / J-5.3). Dismisses
    /// the sheet (ephemeral `@State` owned here is gone with it).
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(Typography.subhead.weight(.semibold))
                .foregroundStyle(ColorRole.textSecondary)
                .frame(width: closeTarget, height: closeTarget)
                .background(ColorRole.fillTertiary, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("addwallet.close")
    }

    // MARK: - Phase A — method picker (mockup add-method.html)

    @ViewBuilder private func methodPhase(_ p: AddToWalletPresenter) -> some View {
        Text(p.methodSubtitle)
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

        methodList(p)

        if let pendingMethod {
            pendingMethodHint(pendingMethod)
        }

        forwardRow(p)
    }

    private func methodList(_ p: AddToWalletPresenter) -> some View {
        VStack(spacing: Spacing.md) {
            ForEach(p.methods) { method in
                methodRow(method)
            }
        }
    }

    @ViewBuilder private func methodRow(_ method: WayToSaveRowModel) -> some View {
        if method.id == "forward" {
            // The prominent row advances to the review phase (the demonstrated extract → review → confirm
            // flow). The actual networked write fires on the phase-B CTA (OD-4).
            WayToSaveRow(model: method, accessibilityID: "addwallet.method.\(method.id)") {
                phase = .review
            }
        } else {
            // Scan / From a photo: deeper capture flows that don't exist yet (OD-8). Wire the tap to a
            // placeholder sink so it is NOT a dead closure (06 §4.1); do not invent the destination.
            WayToSaveRow(model: method, accessibilityID: "addwallet.method.\(method.id)") {
                pendingMethod = method.id
            }
        }
    }

    /// The scan/photo rows route into capture flows that don't exist yet (OD-8). Rather than a dead closure
    /// or an invented screen, the tap surfaces a calm inline note — a real, testable effect (the
    /// `pendingMethod` sink is read here, 06 §4.1) the future route replaces.
    private func pendingMethodHint(_ method: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Image(systemName: "hourglass")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)
            Text("That capture flow is coming soon — for now, forward a confirmation above.")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("addwallet.pendingMethod.\(method)")
    }

    // MARK: - Forward-to-email row (mockup `.fwd-addr`)

    /// "Or forward email to" + the mono address + a NEUTRAL copy button. Not the accent — the accent budget
    /// (J-2.4, ≤ twice) is spent on the one prominent "Forward" method row. A quiet input well, same family
    /// as the clipboard well in `AddPlaceSheet`.
    private func forwardRow(_ p: AddToWalletPresenter) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(p.forwardKey)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
                Text(p.forwardEmail)
                    .font(Typography.footnote) // mono — an address reads as a measurement (T-1.2 / `.fwd-addr .v`)
                    .foregroundStyle(ColorRole.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: Spacing.sm)
            copyButton(p.forwardEmail)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
    }

    /// A quiet NEUTRAL well button (mockup `.cp`) — copies the address to the pasteboard (a real effect).
    private func copyButton(_ email: String) -> some View {
        Button {
            UIPasteboard.general.string = email
        } label: {
            Image(systemName: "doc.on.doc")
                .font(Typography.body.weight(.medium))
                .foregroundStyle(ColorRole.textSecondary)
                .frame(width: copyTarget, height: copyTarget)
                .background(ColorRole.surfaceGrouped, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy address")
        .accessibilityIdentifier("addwallet.copyEmail")
    }

    // MARK: - Phase B — AI review (mockup add-review.html)

    @ViewBuilder private func reviewPhase(_ p: AddToWalletPresenter) -> some View {
        aiLine(p)

        reviewCard(p)

        confirmCTA(p)

        if showsEditHint {
            editHint
        }

        editGhost(p)
    }

    /// The AI provenance line (mockup `.rev-ai`): a SINGLE inline row — an accent dot + a mono-caps label of
    /// what the assistant did ("READ FROM YOUR SCREENSHOT"). NOT `AIVoice` — that component's eyebrow + italic
    /// display sentence is a two-line block whose anatomy doesn't match `.rev-ai`'s one inline line.
    private func aiLine(_ p: AddToWalletPresenter) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(ColorRole.stateNow)
                .frame(width: aiDot, height: aiDot)
                .accessibilityHidden(true)
            Text(p.reviewVoiceLine)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The review card — the AI-extracted fields stacked with the standard rhythm (mockup `.rev-card`).
    private func reviewCard(_ p: AddToWalletPresenter) -> some View {
        VStack(spacing: Spacing.md) {
            ForEach(p.reviewFields) { field in
                reviewField(field, verifyTag: p.verifyTag)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
    }

    /// One review field: key label + a value rendered by kind (a Type icon-chip / a low-confidence italic +
    /// "verify" tag / a mono confirmation / a plain value). Mockup `.rev-field`.
    private func reviewField(
        _ field: AddToWalletPresenter.ReviewField,
        verifyTag: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(field.label)
                .font(Typography.caption)
                .tracking(Typography.trackCapsCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)

            reviewValue(field, verifyTag: verifyTag)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("addwallet.field.\(field.key)")
    }

    @ViewBuilder private func reviewValue(
        _ field: AddToWalletPresenter.ReviewField,
        verifyTag: String
    ) -> some View {
        if let type = field.bookingType {
            // The Type field — a small booking icon-chip + the label (mockup `.rev-type` / `.bk-ico`).
            HStack(spacing: Spacing.sm) {
                Image(systemName: type.systemImage)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.bookingMark(type))
                    .frame(width: typeChipTile, height: typeChipTile)
                    .background(ColorRole.bookingTint(type), in: .rect(cornerRadius: Radius.row))
                    .accessibilityHidden(true)
                Text(field.value)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
            }
        } else if field.lowConfidence {
            // The "When" — a low-confidence value rendered italic + a "verify" tag (mockup `.v.low`).
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(field.value)
                    .font(Typography.body.italic())
                    .foregroundStyle(ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verifyTag)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.stateNow)
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.sm)
                    .background(ColorRole.accentWashFill, in: .capsule)
            }
        } else if field.isMono {
            // The confirmation code — the mono "measurement" face (mockup `.v.mono`, T-1.2).
            Text(field.value)
                .font(Typography.footnote)
                .foregroundStyle(ColorRole.textPrimary)
        } else {
            Text(field.value)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The review-phase primary CTA — the ONE write (OD-4). `PillButton(.primary)` with the in-flight
    /// progress affordance; disabled while adding so the latency reads as one state.
    private func confirmCTA(_ p: AddToWalletPresenter) -> some View {
        PillButton(
            title: p.confirmTitle,
            tier: .primary,
            systemImage: "checkmark",
            isLoading: isAdding
        ) {
            Task { await confirmAdd() }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(isAdding ? "addwallet.progress" : "addwallet.confirm")
    }

    /// The ghost secondary — "Edit details" routes into the manual-edit flow, a separate story. Wire the tap
    /// to an ephemeral hint sink so it is NOT a dead closure (06 §4.1); do not invent the destination.
    private func editGhost(_ p: AddToWalletPresenter) -> some View {
        PillButton(title: p.editTitle, tier: .ghost) {
            showsEditHint = true
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("addwallet.edit")
    }

    /// The "Edit details" stub note — a real, testable effect read off the `showsEditHint` sink (06 §4.1)
    /// the future manual-edit flow replaces.
    private var editHint: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Image(systemName: "pencil")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)
            Text("Editing details by hand is coming soon — for now I'll add what I read.")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("addwallet.editHint")
    }

    // MARK: - Write-error banner (read off the store — never a toast/alert, 06 §6)

    /// An inline content banner: a destructive glyph + message paired (never colour alone — 02-color §6).
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

    // MARK: - The ONE write (OD-4) — optimistic networked add, store-owned rollback

    /*
     Run the wallet slice's one networked write. MILESTONE SHORTCUT (OD-4): a true "extract a brand-new
     booking" flow is a separate story; to keep the optimistic+rollback machinery live, this confirm places
     the SEEDED orphan booking (`booking-fado-orphan`, the "Fado" the review card mirrors) onto day 2 — the
     same write the wallet's OrphanPrompt fires. The store places it optimistically, fires
     `PlaceOrphanRequest`, reconciles on success, or rolls back the day + sets `writeError` on failure. On
     success we dismiss; on failure we stay so the banner shows.
    */
    private func confirmAdd() async {
        guard !isAdding else { return }
        // MILESTONE SHORTCUT (OD-4): placing the SEEDED orphan demonstrates the optimistic+rollback write —
        // the same write the wallet's OrphanPrompt fires. The target booking + day are DERIVED in the
        // presenter (mirroring `WalletPresenter`), not hardcoded; guard so a missing orphan is a no-op that
        // keeps the sheet open rather than firing a write against a stale literal id.
        let p = AddToWalletPresenter(store: store, isAdding: isAdding)
        guard let id = p.orphanBookingID else { return }
        isAdding = true
        await store.placeOrphan(bookingID: id, onDay: p.suggestedDay)
        isAdding = false
        if store.writeError == nil {
            dismiss()
        }
    }

    // MARK: - Scaled metrics (Dynamic-Type-safe, never a fixed point frame — T-6.4)

    @ScaledMetric(relativeTo: .body) private var grabberWidth: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var grabberHeight: CGFloat = 5
    @ScaledMetric(relativeTo: .body) private var closeTarget: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var copyTarget: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var typeChipTile: CGFloat = 30
    @ScaledMetric(relativeTo: .caption2) private var aiDot: CGFloat = Sizing.dot
}

// MARK: - Previews (06 §8) — seeded via AppStore.preview(wallet:), no `.shared`

#Preview("Add to wallet — method") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddToWalletSheet()
                .presentationDetents([.medium, .large])
        }
        .environment(AppStore.preview(wallet: SampleData.walletDTO()))
}

#Preview("Add to wallet — review") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddToWalletSheet(initialPhaseIsReview: true)
                .presentationDetents([.medium, .large])
        }
        .environment(AppStore.preview(wallet: SampleData.walletDTO()))
}

#Preview("Add to wallet — write error") {
    // A store whose last write failed: seed the graph, then set the rolled-back write error directly so the
    // banner renders (the same state `placeOrphan` lands in on a `.mock(failure:)` round-trip). Opened on
    // the review phase, where the banner sits above the CTA that produced it.
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddToWalletSheet(initialPhaseIsReview: true)
                .presentationDetents([.medium, .large])
        }
        .environment(failedPlaceStore())
}

/// A seeded preview store whose `placeOrphan` write has rolled back (`writeError == .placeOrphan`) — drives
/// the error-banner `#Preview` without a `.mock(failure:)` await round-trip.
@MainActor private func failedPlaceStore() -> AppStore {
    let store = AppStore.preview(wallet: SampleData.walletDTO())
    store.writeError = .placeOrphan
    return store
}
