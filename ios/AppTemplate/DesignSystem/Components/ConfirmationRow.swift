// ConfirmationRow.swift — the booking-detail confirmation row (`.conf-row` in mockups/screens/wallet/
// wallet-shell.css; 05-design-system.md §8 / §8.1). A CONTENT row, never glass (J-0.1): a flat
// `surfaceGrouped` cell at `Radius.card` (the mockup `.conf-row` has NO shadow and NO border — a grouped
// cell sitting in the detail flow, not a lifted card, so it is NOT `.cardSurface()` which adds the rest
// shadow), with a mono-caps key ("CONFIRMATION"), the large mono code, and a trailing NEUTRAL copy button.
//
// The code is `.textSelection(.enabled)` — the mockup `.v { user-select: all }` so a long-press selects
// the whole code. The copy button is a NEUTRAL affordance: a `fillTertiary` circle with a `textSecondary`
// `doc.on.clipboard` glyph — deliberately NOT the accent (the 2026-06-06 Saved accent-budget fix:
// a copy/utility glyph is not emphasis, so it never spends the budgeted accent; J-0.4 / J-2.4). The
// button is a real sink — it calls `onCopy`; the actual `UIPasteboard` write happens at the SCREEN, never
// in a design-system component (05 §8 keeps side effects out of components).
//
// A11y (05 §8.1): the component owns the MECHANISM — one combined VoiceOver stop ("Confirmation,
// 7XQK2M") with a `.isButton`-trait copy action, the glyph hidden — and an `accessibilityID` PASSTHROUGH;
// the CALLER owns the id VALUE (`booking.confirmation`). No id is baked; the optional id is attached only
// when present via `.accessibilityIdentifier(ifPresent:)`, never `?? ""`.
//
// Semantic tokens only — no literal, no `Primitive.*` (J-0.2). Dynamic Type throughout: the code uses the
// `Typography.Component.confirmationCode` mono role (scales to AX5) and the copy button is `@ScaledMetric`
// so it grows with type (J-0.3, T-6.4).
import SwiftUI

/// The confirmation row: a mono-caps key, a large selectable mono code, and a trailing neutral copy
/// button. Screen-agnostic — value args in, no `AppStore` (05 §8). The copy button calls `onCopy`; the
/// screen performs the pasteboard write and supplies the `booking.confirmation` id.
struct ConfirmationRow: View {

    /// The confirmation code shown in the large mono `.v` slot and selected by `.textSelection(.enabled)`.
    let code: String

    /// Invoked when the copy button is tapped. The component is side-effect-free — the SCREEN writes to
    /// `UIPasteboard` (05 §8). A no-op sink is a smell; the screen wires a real effect.
    let onCopy: () -> Void

    /// The caller-owned a11y id (`booking.confirmation`). The component bakes none; attached only when
    /// present (no `?? ""` foot-gun — 05 §8.1).
    let accessibilityID: String?

    /// The copy button is a fixed dimension that must grow with Dynamic Type, so it's `@ScaledMetric`, not
    /// a fixed `CGFloat` (mockup `.conf-row .cp`; T-6.4 / J-0.3).
    @ScaledMetric(relativeTo: .body) private var copyButtonSize: CGFloat = Sizing.Component.confCopyButton

    init(code: String, onCopy: @escaping () -> Void, accessibilityID: String? = nil) {
        self.code = code
        self.onCopy = onCopy
        self.accessibilityID = accessibilityID
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            keyAndCode
                .frame(maxWidth: .infinity, alignment: .leading) // left-aligned (J-7.1); takes the 1fr column
            copyButton
        }
        .padding(Spacing.lg)
        // Flat grouped cell — `surfaceGrouped` fill at `Radius.card`, NO shadow, NO border (mockup
        // `.conf-row`; a surface is a soft shadow OR a 1px edge, never both — here it is neither: J-8.4).
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
        // One VoiceOver stop carrying the key + code, exposed as a copy button; the glyph is hidden below.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confirmation, \(code)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Copy", onCopy)
        // Identifier passthrough — attached ONLY when the caller supplies one (no `?? ""`; 05 §8.1).
        .accessibilityIdentifier(ifPresent: accessibilityID)
    }

    // MARK: Key + code — mono-caps eyebrow over the large selectable mono code (mockup `.k` / `.v`)

    private var keyAndCode: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("CONFIRMATION")
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textTertiary)

            Text(code)
                .font(Typography.Component.confirmationCode)
                .foregroundStyle(ColorRole.textPrimary)
                .textSelection(.enabled) // mockup `.v { user-select: all }` — long-press selects the code
                .fixedSize(horizontal: false, vertical: true) // grow vertically, never clip at large type
        }
    }

    // MARK: Copy button — a NEUTRAL utility affordance, never the accent (the Saved accent-budget fix)

    private var copyButton: some View {
        Button(action: onCopy) {
            Image(systemName: "doc.on.clipboard")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary) // NEUTRAL glyph — NOT accent (J-0.4 / J-2.4)
                .frame(width: copyButtonSize, height: copyButtonSize)
                .background(ColorRole.fillTertiary, in: .circle) // neutral fill against the grouped row
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        // The combined row speaks the code + the copy action; the standalone button is redundant to it.
        .accessibilityHidden(true)
    }
}

// MARK: - Previews — the canonical confirmation row (05 §8, §10)

#Preview("Confirmation row") {
    ConfirmationRow(code: "7XQK2M", onCopy: {}, accessibilityID: "booking.confirmation")
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("Confirmation row — long code") {
    ConfirmationRow(code: "TDC-8841-LIS", onCopy: {}, accessibilityID: "booking.confirmation")
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
