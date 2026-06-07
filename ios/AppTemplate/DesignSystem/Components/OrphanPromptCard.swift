// OrphanPromptCard.swift — the AI orphan-placement prompt (05-components §8; wallet plan 1.5).
// Ports the mockup `.orphan` (wallet-shell.css): a CONTENT card on a faint accent WASH + a 1px accent
// ring — the one earned accent moment on the populated wallet (the `now` status pill is the other; the
// design-reviewer holds the ≤2/screen budget, J-0.4/J-2.4). NOT glass (J-0.1): the wash is a low-L
// `accent-50` fill, not a translucent material, and it sits flat on the page.
//
// Anatomy (`.orphan`): a mono-caps `.lab` with an accent `.mk` dot · a `.row` (a booking-type-tinted
// icon tile + name + meta) · an italic display `.line` (the product's AI voice — same italic-display
// idiom as `AIVoice`, with inline-bold emphasis via Markdown so "21:00 show"/"Day 2" read as the
// mockup's `<b>` spans) · an `.acts` floor (Pin primary / Not now ghost). The accent is concentrated in
// the wash + the `.mk` dot + the Pin button; the label text stays `textSecondary` so the accent is a
// presence, not the room (J-2.4). Left-aligned (J-7.1), binary inks (J-2.2), tokens only (J-0.2).
//
// A11y (05 §8.1): the component owns the MECHANISM (three id passthroughs + the row's combined label);
// the CALLER owns the VALUES (`orphan.pin` / `orphan.dismiss` / `orphan.row`). No id is baked, none is
// `?? ""` — `.accessibilityIdentifier(ifPresent:)`. Value-type fixture in; no AppStore/domain (05 §8).
import SwiftUI

// MARK: - Fixture (value type in — no domain model / no AppStore, per 05 §8)

/// One orphan-placement prompt's data — the screen maps its domain (a booking with `dayIndex == nil`)
/// to this tiny value type. The component never sees `AppStore` or a domain object (01-arch §3, 05 §8).
struct OrphanPromptModel: Sendable {
    /// The mono-caps eyebrow label (e.g. "1 BOOKING NOT YET PLACED"). Kept short — caps tracking is for
    /// brief eyebrows only (J-3.5).
    let labelCaps: String
    /// The orphan booking's name, display face (mockup `.orphan .nm`).
    let bookingName: String
    /// The secondary meta line (e.g. "Bairro Alto · confirmation TDC-8841"; mockup `.orphan .mt`).
    let bookingMeta: String
    /// The booking's type — drives the icon tile tint + the SF Symbol glyph.
    let type: BookingType
    /// The SF Symbol for the booking (the presenter supplies it — usually `type.systemImage`; the
    /// component never invents a glyph, 05 §8).
    let systemImage: String
    /// The AI suggestion line — the one editorial italic moment (J-3.6). Markdown is honoured so the
    /// presenter can **bold** the key facts the way the mockup's `<b>` spans do.
    let suggestionLine: String
    /// The primary action title (e.g. "Pin to Day 2") — a present-tense verb the user owns (J-11.3).
    let pinTitle: String
    /// The dismiss action title (e.g. "Not now").
    let dismissTitle: String

    init(
        labelCaps: String,
        bookingName: String,
        bookingMeta: String,
        type: BookingType,
        systemImage: String,
        suggestionLine: String,
        pinTitle: String,
        dismissTitle: String
    ) {
        self.labelCaps = labelCaps
        self.bookingName = bookingName
        self.bookingMeta = bookingMeta
        self.type = type
        self.systemImage = systemImage
        self.suggestionLine = suggestionLine
        self.pinTitle = pinTitle
        self.dismissTitle = dismissTitle
    }
}

// MARK: - OrphanPromptCard

/// The AI orphan-placement prompt card. The booking row is itself tappable (opens the booking detail);
/// the Pin/Not-now actions are caller closures. Caller-owned a11y ids for all three affordances.
struct OrphanPromptCard: View {
    let model: OrphanPromptModel
    /// Fired by the primary "Pin to Day N" action (the screen runs the place-orphan write).
    let onPin: () -> Void
    /// Fired by "Not now" (the screen hides the prompt this session — a local, non-graph dismissal).
    let onDismiss: () -> Void
    /// Fired by tapping the booking row (the screen pushes the booking detail).
    let onSelect: () -> Void
    /// The CALLER's id for the Pin button (e.g. `orphan.pin`); `nil` attaches none (no `""` foot-gun).
    var pinAccessibilityID: String? = nil
    /// The CALLER's id for the dismiss button (e.g. `orphan.dismiss`).
    var dismissAccessibilityID: String? = nil
    /// The CALLER's id for the booking row (e.g. `orphan.row`).
    var rowAccessibilityID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            label
            row
                .padding(.top, Spacing.md)   // `.orphan .lab { margin-bottom: 12px }`
            suggestion
                .padding(.top, Spacing.lg)   // `.orphan .line { margin-top: 14px }` → lg rung
            actions
                .padding(.top, Spacing.lg)   // `.orphan .acts { margin-top: 14px }` → lg rung
        }
        .padding(Spacing.lg)                 // `.orphan { padding: 16px }`
        .frame(maxWidth: .infinity, alignment: .leading)
        // CONTENT card on the earned accent wash + a 1px accent ring (mockup `.orphan` background +
        // `box-shadow: 0 0 0 1px accent-100`). The ring is the one place a coloured hairline is earned —
        // it marks the AI suggestion, paired with the wash + dot + Pin, NOT a side-tab accent border
        // (08-slop A-1, J-10.4). Never glass (J-0.1).
        .background(ColorRole.accentWashFill, in: .rect(cornerRadius: Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(ColorRole.accentWashRing, lineWidth: Stroke.separator)
        }
    }

    // MARK: Label — mono caps eyebrow + the accent dot (mockup `.orphan .lab`)

    private var label: some View {
        HStack(spacing: Spacing.sm) {
            // The accent `.mk` dot — the single accent appearance in the eyebrow, paired with the label
            // (never colour alone — 02-color §6, J-2.4). Scales with the caps text so it stays optically
            // aligned at every Dynamic Type size (T-6.4).
            Circle()
                .fill(ColorRole.actionPrimary)
                .frame(width: markSize, height: markSize)
            Text(model.labelCaps)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // The eyebrow mark — a small dot that scales with the mono caps text (mirrors `AIVoice`'s markSize).
    @ScaledMetric(relativeTo: .caption2) private var markSize: CGFloat = Sizing.dot

    // MARK: Row — the orphan booking (a tappable element that opens the detail; mockup `.orphan .row`)

    private var row: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                bookingIcon
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(model.bookingName)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                        .lineLimit(1)
                    Text(model.bookingMeta)
                        .font(Typography.subhead)
                        .foregroundStyle(ColorRole.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(OrphanRowStyle())
        // ONE a11y element for the row: the caller's id + name/meta combined, so it stays independently
        // resolvable/tappable (the row opens the detail). The icon glyph is decorative.
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(ifPresent: rowAccessibilityID)
        .accessibilityLabel("\(model.bookingName), \(model.bookingMeta)")
    }

    /// The booking-type icon tile (mockup `.orphan .row .bk-ico` — 40pt): the low-alpha type tint behind
    /// the deeper type mark glyph — a mark paired with a glyph, never colour alone (02-color §6). The
    /// side is a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var iconTile: CGFloat = Sizing.Component.orphanRowIcon

    private var bookingIcon: some View {
        Image(systemName: model.systemImage)
            .font(Typography.title)
            .foregroundStyle(ColorRole.bookingMark(model.type))
            .frame(width: iconTile, height: iconTile)
            .background(ColorRole.bookingTint(model.type), in: .rect(cornerRadius: Radius.row))
            .accessibilityHidden(true)
    }

    // MARK: Suggestion — the italic display AI voice line (mockup `.orphan .line`)

    private var suggestion: some View {
        // Display face, italic — the one editorial moment (J-3.6), the same idiom as `AIVoice`. Solid
        // ink, never gradient text (02-color §5). Markdown renders the **bold** spans (mockup `.line b`:
        // `font-style: normal; font-weight: 600; color: ink-900`) so the key facts stand out inline.
        Text(.init(model.suggestionLine))
            .font(Typography.callout.italic())
            .foregroundStyle(ColorRole.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions — Pin (primary) / Not now (ghost) (mockup `.orphan .acts`)

    private var actions: some View {
        // ONE primary per region (J-6.1): Pin is the primary, Not now is demoted to a ghost. The Pin's
        // accent fill is part of the budgeted accent moment (wash + dot + Pin).
        HStack(spacing: Spacing.sm) {
            PillButton(title: model.pinTitle, tier: .primary, action: onPin)
                .frame(maxWidth: .infinity)   // `.orphan .acts .pin { flex: 1 }`
                .accessibilityIdentifier(ifPresent: pinAccessibilityID)
            PillButton(title: model.dismissTitle, tier: .ghost, action: onDismiss)
                .accessibilityIdentifier(ifPresent: dismissAccessibilityID)
        }
    }
}

// MARK: - Orphan row button style (tap feedback only — ≤100ms, J-9.1)

private struct OrphanRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Preview — the one meaningful state (05 §8, §10)

private extension OrphanPromptModel {
    static let fado = OrphanPromptModel(
        labelCaps: "1 BOOKING NOT YET PLACED",
        bookingName: "Fado at Tasca do Chico",
        bookingMeta: "Bairro Alto · confirmation TDC-8841",
        type: .activity,
        systemImage: BookingType.activity.systemImage,
        suggestionLine: "This reads like a **21:00 show** — it fits your **Day 2** evening, after dinner in Alfama.",
        pinTitle: "Pin to Day 2",
        dismissTitle: "Not now"
    )
}

#Preview("OrphanPromptCard") {
    OrphanPromptCard(
        model: .fado,
        onPin: {},
        onDismiss: {},
        onSelect: {},
        pinAccessibilityID: "orphan.pin",
        dismissAccessibilityID: "orphan.dismiss",
        rowAccessibilityID: "orphan.row"
    )
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
