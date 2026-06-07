/*
 AddPlaceSheet — the "Save a place" method picker, presented as a sheet from SavedListView's ephemeral
 `@State` flag (`.sheet(isPresented:)`, 06-screens.md §6). Ports mockups/screens/saved/add-place.html.

 Chrome: a sheet, NOT glass at rest (glass is floating-chrome-only — 06 §6 / J-0.1). It draws its own
 grabber + header (title "Save a place" + a close ×), then three `WayToSaveRow`s (the prominent reel
 paste + standard screenshot/search) and an "On your clipboard" detected-URL affordance with a paste
 button.

 The ONE write (D-4): the prominent reel row AND the clipboard paste button both build an `AddPlaceBody`
 from the clipboard URL and call `await store.addPlace(_:)` — an optimistic, networked write with
 rollback owned by the store (the view never mutates the graph). On success the sheet dismisses (the new
 place appears optimistically in the list); on failure `store.writeError` is set and the
 `writeError.banner` shows here (a banner, never a toast/alert — 06 §6). The 800ms
 `AddPlaceRequest.mockLatency` loading state is surfaced via a progress affordance (testable).

 Screenshot / search are deeper capture flows that don't exist yet (D-4): their taps are wired to an
 ephemeral `pendingMethod` sink (a placeholder for the future route) so nothing ships as a dead closure
 (06 §4.1) — they do NOT invent a destination screen this milestone.

 Logic out of the view: derivation → `AddPlacePresenter`; the write → `store.addPlace`. The view holds
 only ephemeral UI state (`@State`).
*/
import SwiftUI

struct AddPlaceSheet: View {

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// The URL detected on the clipboard. Stubbed/ephemeral this milestone (the reel/clipboard write is
    /// what D-4 builds; a real pasteboard read is a separate concern) — seeded to the mockup's URL so the
    /// affordance + the write path are exercisable in previews / UI tests.
    @State private var detectedURL: String? = SampleData.stubbedClipboardURL

    /// True while `store.addPlace` is in flight — drives the progress affordance and disables re-taps so
    /// the 800ms mock latency is surfaced (a single continuous loading state, 04 §7 / J-9).
    @State private var isAdding = false

    /// The capture method tapped that has no destination yet (screenshot / search). A placeholder sink so
    /// those rows are wired (06 §4.1), not dead closures — the future capture routes replace it (D-4).
    @State private var pendingMethod: String?

    var body: some View {
        let p = AddPlacePresenter(store: store, detectedURL: detectedURL, isAdding: isAdding)

        VStack(spacing: 0) {
            grabber
            header(p)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(p.subtitle)
                        .font(Typography.subhead)
                        .foregroundStyle(ColorRole.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Direct read of store.writeError in body registers it as a SwiftUI
                    // @Observable dependency — the presenter also reads it, but through a
                    // struct intermediary that may not reliably trigger the observation
                    // tracking context on all SwiftUI runtime versions. This unambiguous
                    // direct read guarantees the sheet re-renders when writeError is set
                    // after a failed write (07-testing §6.6).
                    if store.writeError != nil, let message = p.writeErrorMessage {
                        errorBanner(message)
                    }

                    methodList(p)

                    if let pendingMethod {
                        pendingMethodHint(pendingMethod)
                    }

                    if p.showsClipboard {
                        clipboardRow(p)
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

    private func header(_ p: AddPlacePresenter) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(p.title)
                .font(Typography.title)
                .foregroundStyle(ColorRole.textPrimary)
            Spacer(minLength: Spacing.md)
            closeButton
        }
        .padding(.horizontal, Spacing.screenInset)
        .padding(.bottom, Spacing.md)
    }

    /// A quiet, content-density close × (the sheet is content, not glass chrome — J-0.1 / J-5.3). Dismisses
    /// the sheet (ephemeral `@State` owned by the presenter is gone with it).
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
        .accessibilityIdentifier("addplace.close")
    }

    // MARK: - Method list (mockup `.method-list`)

    private func methodList(_ p: AddPlacePresenter) -> some View {
        VStack(spacing: Spacing.md) {
            ForEach(p.methods) { method in
                methodRow(method)
            }
        }
    }

    @ViewBuilder private func methodRow(_ method: WayToSaveRowModel) -> some View {
        if method.id == "reel" {
            // The ONE write (D-4): the prominent reel row fires the networked add. While in flight it
            // shows the progress affordance and is disabled so the 800ms latency reads as one state.
            ZStack(alignment: .trailing) {
                WayToSaveRow(model: method, accessibilityID: "addplace.method.reel") {
                    Task { await addFromClipboard() }
                }
                if isAdding {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ColorRole.actionPrimary)
                        .padding(.trailing, Spacing.lg)
                        .accessibilityIdentifier("addplace.progress")
                }
            }
            .disabled(isAdding)
        } else {
            // Screenshot / search: deeper capture flows that don't exist yet (D-4). Wire the tap to a
            // placeholder sink so it is NOT a dead closure (06 §4.1); do not invent the destination.
            WayToSaveRow(model: method, accessibilityID: "addplace.method.\(method.id)") {
                pendingMethod = method.id
            }
            .disabled(isAdding)
        }
    }

    // MARK: - Pending-method hint (D-4: screenshot/search capture flows are separate stories)

    /// The screenshot/search rows route into capture flows that don't exist yet (D-4). Rather than a dead
    /// closure or an invented screen, the tap surfaces a calm inline note that this capture path is coming
    /// — a real, testable effect (the `pendingMethod` sink is read here, 06 §4.1) the future route replaces.
    private func pendingMethodHint(_ method: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Image(systemName: "hourglass")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)
            Text("That capture flow is coming soon — for now, paste a reel or video above.")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("addplace.pendingMethod.\(method)")
    }

    // MARK: - Clipboard affordance (mockup `.fwd-addr`)

    /// "On your clipboard" + the detected URL + a paste button. The paste button is the second entry to
    /// the ONE write — it builds the same `AddPlaceBody` and calls `store.addPlace` (D-4).
    private func clipboardRow(_ p: AddPlacePresenter) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(p.clipboardKey)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
                Text(p.clipboardURL)
                    .font(Typography.footnote) // mono — a detected address reads as measurement (T-1.2 / `.fwd-addr .v`)
                    .foregroundStyle(ColorRole.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: Spacing.sm)
            pasteButton
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        // A quiet input well, same family as SearchWell — not a bordered card (mockup `.fwd-addr`).
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.row))
    }

    /// A quiet NEUTRAL well button (mockup `.cp`) — not the accent. The accent budget (J-2.4, ≤ twice) is
    /// spent on the one earned emphasis: the prominent reel row. This second entry to the same write reads
    /// recessive: a grouped-surface well + a secondary glyph, with a neutral-tinted spinner in flight.
    private var pasteButton: some View {
        Button { Task { await addFromClipboard() } } label: {
            Group {
                if isAdding {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ColorRole.textSecondary)
                } else {
                    Image(systemName: "doc.on.clipboard")
                        .font(Typography.body.weight(.medium))
                }
            }
            .foregroundStyle(ColorRole.textSecondary)
            .frame(width: pasteTarget, height: pasteTarget)
            .background(ColorRole.surfaceGrouped, in: .circle)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
        .accessibilityLabel("Paste")
        .accessibilityIdentifier("addplace.paste")
    }

    // MARK: - Write-error banner (read off the store — never a toast/alert, 06 §6)

    /// An inline content banner: a destructive glyph + message paired (never color alone — 02-color §6).
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

    // MARK: - The ONE write (D-4) — optimistic networked add, store-owned rollback

    /// Build the `AddPlaceBody` from the detected clipboard URL and run the store's optimistic add. The
    /// store inserts an optimistic row, fires `AddPlaceRequest`, reconciles on success, or rolls back +
    /// sets `writeError` on failure. On success we dismiss; on failure we stay so the banner shows.
    private func addFromClipboard() async {
        guard let url = detectedURL, !url.isEmpty, !isAdding else { return }
        isAdding = true
        await store.addPlace(AddPlaceBody(url: url, sourceKind: .reel))
        isAdding = false
        if store.writeError == nil {
            dismiss()
        }
    }

    // MARK: - Scaled metrics (Dynamic-Type-safe, never a fixed point frame — T-6.4)

    @ScaledMetric(relativeTo: .body) private var grabberWidth: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var grabberHeight: CGFloat = 5
    @ScaledMetric(relativeTo: .body) private var closeTarget: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var pasteTarget: CGFloat = 40
}

// MARK: - Previews (06 §8) — seeded via AppStore.preview(savedPlaces:), no `.shared`

#Preview("Add place — standard") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddPlaceSheet()
                .presentationDetents([.medium, .large])
        }
        .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}

#Preview("Add place — write error") {
    // A store whose last write failed: seed the graph, then set the rolled-back write error directly so
    // the banner renders (the same state `addPlace` lands in on a `.mock(failure:)` round-trip). The
    // store is built in a helper so the ViewBuilder closure holds only the view expression.
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddPlaceSheet()
                .presentationDetents([.medium, .large])
        }
        .environment(failedAddStore())
}

/// A seeded preview store whose `addPlace` write has rolled back (`writeError == .addPlace`) — drives
/// the error-banner `#Preview` without a `.mock(failure:)` await round-trip.
@MainActor private func failedAddStore() -> AppStore {
    let store = AppStore.preview(savedPlaces: SampleData.savedPlacesDTO())
    store.writeError = .addPlace
    return store
}
