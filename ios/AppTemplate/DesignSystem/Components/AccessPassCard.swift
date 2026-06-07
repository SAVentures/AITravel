// AccessPassCard.swift — the day-of access (boarding-pass) card (05-design-system.md §8; 05-components §3).
// Ports the access-card mockup `.acc-card`: a `paper-0` content card lifted by the one `hero` shadow,
// holding a type-tinted `.acc-band` (icon tile + title/subtitle, hairline below), an `.acc-qr` (a
// REAL deterministic QR + a mono confirmation `.cap`, selectable), and an `.acc-meta` 3-cell hairline grid
// (Gate / Seat / Zone). The card is presented centred on a dark immersive takeover by `AccessCardView`,
// but the card itself is CONTENT — so it is a solid surface, NEVER glass (J-0.1 / J-8, 05-components §3.3).
//
// The QR is rendered, not bundled: `QRCodeView(payload:)` draws a real CoreImage QR (OD-5), deterministic
// (a fixed payload → identical pixels) so the L3 snapshot of this card is stable. The 3-cell meta grid
// REUSES `PlaceInfoGrid` (the Saved 3-cell hairline grid) fed booking meta as `[PlaceFacts]` — Gate/Seat/
// Zone are key/value with no sub-line.
//
// Value-type fixture in (`AccessPassModel`) — no AppStore, no domain object (05 §8). The component owns its
// a11y mechanism (it combines the band into one sensible label + exposes an `accessibilityID` passthrough);
// the CALLER owns the id VALUE (05 §8.1). SEMANTIC tokens only — no literal, no `Primitive.*` (J-0.2).
import SwiftUI

/// The local value-type fixture this card renders from (mapped from a domain `AccessPass`).
struct AccessPassModel: Sendable {
    /// The mono-caps kind eyebrow, e.g. "Boarding pass" (mockup `.acc-top .lab` — rendered by the
    /// screen's top bar, NOT inside the card band; the card surfaces it only in its combined a11y label).
    let kindLabel: String
    /// The pass title — the display name, e.g. "LIS → JFK · TP 201" (mockup `.acc-band .nm`).
    let title: String
    /// The meta line under the title, e.g. "Zé Maria · Sat, Aug 29 · boards 13:05" (mockup `.acc-band .mt`).
    let subtitle: String
    /// The booking type — drives the band icon tint + glyph (mockup `.acc-ico` is transport-tinted).
    let type: BookingType
    /// The SF Symbol for the band icon (the presenter supplies it; the component doesn't invent a glyph).
    let systemImage: String
    /// The string encoded into the QR (mockup `qr.svg` → a real data-driven code).
    let qrPayload: String
    /// The mono confirmation shown under the QR, e.g. "7XQK2M" (mockup `.acc-qr .cap`, selectable).
    let confirmation: String
    /// The 3-cell meta grid — Gate / Seat / Zone (mockup `.acc-meta`), fed straight to `PlaceInfoGrid`.
    let metaCells: [PlaceFacts]
}

/// The day-of access card: a type-tinted band, a deterministic QR + confirmation, and a Gate/Seat/Zone
/// grid. Screen-agnostic — a value-type fixture in, no `AppStore` (05 §8). CONTENT, never glass.
struct AccessPassCard: View {

    let model: AccessPassModel
    /// 05 §8.1: the caller owns the id VALUE; the component owns the mechanism. Absent on a preview.
    var accessibilityID: String?

    /// The band icon-tile side — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var iconTile: CGFloat = Sizing.Component.accessIconTile
    /// The QR side — a non-text metric, scales with Dynamic Type (T-6.4). Drives the `QRCodeView` frame.
    @ScaledMetric(relativeTo: .body) private var qrSide: CGFloat = Sizing.Component.accessQRSide

    var body: some View {
        VStack(spacing: 0) {
            band
            Divider().overlay(ColorRole.separator)
            qrBlock
            Divider().overlay(ColorRole.separator)
            // The meta grid reuses the Saved 3-cell hairline grid (mockup `.acc-meta` ≈ `.info-grid`).
            PlaceInfoGrid(cells: model.metaCells)
        }
        // Solid content card on `paper-0` (mockup `.acc-card { background: var(--paper-0) }`) with the one
        // reserved `hero` lift. `surfaceGrouped` is the paper-0 white role (the page-grey `surfacePage` would
        // be wrong here — and the QR's clear ground then shows this white through). One elevation, no border
        // (08-slop A-4). NEVER glass (J-0.1, §3.3).
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
        .clipShape(.rect(cornerRadius: Radius.card))
        .shadowHero()
        // One VoiceOver stop for the pass identity; the QR is decorative, the confirmation stays selectable.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(model.kindLabel), \(model.title), \(model.subtitle)")
        .accessibilityIdentifier(ifPresent: accessibilityID)
    }

    // MARK: Band — type-tinted icon tile + title/subtitle (mockup `.acc-band`)

    private var band: some View {
        HStack(spacing: Spacing.md) {
            iconTileView
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(model.subtitle)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .accessibilityElement(children: .ignore)
    }

    /// The type-tinted icon tile — a low-alpha `bookingTint` wash behind the `bookingMark` glyph
    /// (mockup `.acc-ico`, transport-tinted). The glyph carries meaning, never colour alone (02-color §6).
    private var iconTileView: some View {
        RoundedRectangle(cornerRadius: Radius.row)
            .fill(ColorRole.bookingTint(model.type))
            .frame(width: iconTile, height: iconTile)
            .overlay {
                Image(systemName: model.systemImage)
                    .font(Typography.title)
                    .foregroundStyle(ColorRole.bookingMark(model.type))
            }
            .accessibilityHidden(true)
    }

    // MARK: QR block — the real deterministic code + the selectable confirmation (mockup `.acc-qr`)

    private var qrBlock: some View {
        VStack(spacing: Spacing.lg) {
            QRCodeView(payload: model.qrPayload)
                .frame(width: qrSide, height: qrSide)
            // The confirmation — the larger mono role (`.footnote`), letter-spaced like the mockup `.cap`,
            // and selectable (mockup `user-select: all` → `.textSelection(.enabled)`).
            Text(model.confirmation)
                .font(Typography.footnote)
                .monospacedDigit()
                .tracking(Typography.trackCapsCaption)
                .foregroundStyle(ColorRole.textPrimary)
                .textSelection(.enabled)
                .accessibilityLabel("Confirmation \(model.confirmation)")
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
    }
}

// MARK: - Previews — one per meaningful state (05 §8, §10)

private extension AccessPassModel {
    /// The TP 201 boarding pass, faithful to access-card.html (the L3 fixture — deterministic QR).
    static let boardingPass = AccessPassModel(
        kindLabel: "Boarding pass",
        title: "LIS → JFK · TP 201",
        subtitle: "Zé Maria · Sat, Aug 29 · boards 13:05",
        type: .transport,
        systemImage: BookingType.transport.systemImage,
        qrPayload: "TP201|LIS-JFK|7XQK2M",
        confirmation: "7XQK2M",
        metaCells: [
            PlaceFacts(key: "Gate", value: "24", sub: nil),
            PlaceFacts(key: "Seat", value: "14A", sub: nil),
            PlaceFacts(key: "Zone", value: "2", sub: nil)
        ]
    )
}

#Preview("Boarding pass") {
    AccessPassCard(model: .boardingPass)
        .padding(Spacing.screenInset)
        // The card is presented on a dark immersive takeover; the preview shows it on that ground.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorRole.textPrimary)
}
