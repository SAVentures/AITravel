// AccessCardView.swift — the day-of boarding-pass takeover (06-screens.md §2/§4.1; wallet Task 3.3).
// Names its mockup: mockups/screens/wallet/access-card.html.
//
// A DARK immersive takeover, presented as a `.fullScreenCover` from booking-detail's "Show boarding pass"
// affordance (the interactivity-inventory destination, never folded into the detail screen — 06 §4.1). It
// ports `.acc-screen`: an `ink-900` ground holding `.acc-top` (a mono-caps kind label + a plain close ×),
// the centred `AccessPassCard` (the Wave-1 component, with its real deterministic QR), and an `.acc-hint`
// scanning line. Chrome is `ScreenScaffold(.immersive)` (tab bar hidden) over the immersive surface role.
//
// OD-8 (real brightness): on appear the screen captures `UIScreen.main.brightness` and raises it to 1.0 so
// a scanner reads the QR; on disappear it restores the captured value. Wrapped so it's a harmless no-op in
// previews/tests (no screen → no capture, no restore).
//
// Layout + wiring only (06 §1): no derivation worth a presenter (the model is built once in `init` from the
// passed `AccessPass`), so this screen has no `<Name>Presenter`. The only affordance is the close × →
// `dismiss()`; the QR + confirmation are display-only (the card owns the selectable confirmation).
import SwiftUI

struct AccessCardView: View {

    /// The fully-resolved fixture the centred card renders from (built in `init` from the booking's
    /// `AccessPass` — see the convenience init below). Held as a stored value: no domain object, no store.
    private let model: AccessPassModel

    /// Dismisses the `.fullScreenCover` (the close × sink — 06 §4.1).
    @Environment(\.dismiss) private var dismiss

    /// OD-8: the device brightness captured on appear, restored on disappear. `nil` until appear (and on a
    /// platform with no `UIScreen`, e.g. a snapshot host) so the restore is a harmless no-op.
    @State private var savedBrightness: CGFloat?

    /// The close-× faint circle side — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var closeTile: CGFloat = Sizing.Component.accessCloseTile

    /// Primary init — the leaf `AccessPass` value the booking carries. Derives the card's `type` + glyph for
    /// a boarding pass (`.transport` → airplane); a future non-flight pass would pass them through instead.
    init(pass: AccessPass, type: BookingType = .transport) {
        self.model = AccessPassModel(
            kindLabel: pass.kindLabel,
            title: pass.title,
            subtitle: pass.subtitle,
            type: type,
            systemImage: type.systemImage,
            qrPayload: pass.qrPayload,
            confirmation: pass.confirmation,
            metaCells: pass.metaCells
        )
    }

    /// Escape hatch for callers that already hold a fully-built `AccessPassModel` (e.g. a custom glyph).
    init(model: AccessPassModel) {
        self.model = model
    }

    var body: some View {
        // A static takeover (no CTA to reach, no overflow) → `scrollDisabled`; the dark immersive ground is
        // the one inverse surface role. The scaffold supplies the horizontal inset, safe area, and hides the
        // tab bar (`.immersive`); this screen never hand-wires chrome (06 §2.6).
        ScreenScaffold(.immersive, background: ColorRole.surfaceImmersive, scrollDisabled: true) {
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                AccessPassCard(model: model, accessibilityID: "accesscard.pass")
                Spacer(minLength: 0)
                hint
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // OD-8 — raise brightness for scanning on appear, restore the captured value on dismiss. Guarded so
        // it is a no-op anywhere `UIScreen` is unavailable (previews/snapshots/tests).
        .onAppear { raiseBrightness() }
        .onDisappear { restoreBrightness() }
    }

    // MARK: - Top bar — the mono-caps kind label + the plain close × (mockup `.acc-top`)

    private var topBar: some View {
        HStack {
            // The kind eyebrow drawn on the dark ground (mockup `.acc-top .lab` — faint white mono-caps).
            Text(model.kindLabel)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textOnImmersive)
            Spacer(minLength: Spacing.md)
            closeButton
        }
        .padding(.top, Spacing.sm)
    }

    /// The close × — a PLAIN styled glyph button (NOT glass): a faint white circle on the dark ground
    /// (mockup `.acc-top .x`). Plain by design — a real glass material leaves an offscreen-blank gap in a
    /// snapshot of the dark takeover (OD-8 / 06 §2.4). 44pt hit target; the visible circle is smaller.
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.glyphOnImmersive)
                .frame(width: closeTile, height: closeTile)
                .background(ColorRole.fillOnImmersive, in: .circle)
                .frame(width: Sizing.minTapTarget, height: Sizing.minTapTarget)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("accesscard.close")
    }

    // MARK: - Hint — the scanning line under the card (mockup `.acc-hint`)

    private var hint: some View {
        Text("Screen brightness raised · hold steady at the scanner")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textOnImmersive)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.xl)
    }

    // MARK: - OD-8 brightness (real, guarded)

    /// Capture the current brightness once and raise it to full for scanning. No-op if there's no screen.
    private func raiseBrightness() {
        guard let screen = UIScreen.current else { return }
        if savedBrightness == nil { savedBrightness = screen.brightness }
        screen.brightness = 1.0
    }

    /// Restore the brightness captured on appear, then clear the capture.
    private func restoreBrightness() {
        guard let screen = UIScreen.current, let saved = savedBrightness else { return }
        screen.brightness = saved
        savedBrightness = nil
    }
}

/// The active `UIScreen`, resolved from the connected window scene — `nil` in a context with no screen
/// (a snapshot/test host), so the OD-8 brightness bump degrades to a harmless no-op there. Avoids the
/// deprecated `UIScreen.main` while keeping the brightness affordance real on device.
private extension UIScreen {
    static var current: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
    }
}

// MARK: - Previews — the TP 201 pass on the dark takeover (06 §8; standalone, no nav)

#Preview("Access card — TP 201 boarding pass") {
    AccessCardView(pass: SampleData.tap201AccessPass())
}
