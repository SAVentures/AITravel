// BookingRow.swift — the compact, type-aware wallet entry (`.bk` in mockups/screens/wallet/wallet-shell.css;
// 05 §8). A CONTENT row, never glass (J-0.1): a `.cardSurface()` content card at `Radius.card`, with a
// three-zone grid (mockup `.bk`'s `44px 1fr auto`) — a type-tinted icon tile (`.bk-ico`) · the
// name(display)/meta(secondary) body (`.bk-body`) · a trailing `StatusPill` over a mono confirmation code
// (`.bk-end`). A different anatomy from `PlaceRow` (no thumb well, no source/provenance line): the booking
// *type* (lodging/transport/activity/dining/other) tints only the icon tile, via the earned
// `ColorRole.bookingTint`/`bookingMark` taxonomy (≤ icon-tile low-alpha wash, never a card fill — J-2/J-0.4).
// The icon tile side is `@ScaledMetric` so the row grows with Dynamic Type (mirrors `PlaceRow.wellSize`;
// J-0.3). Tokens only (J-0.2).
//
// The `.past` register dims (mockup `.bk.past`): the name drops to `textTertiary` (the explicit "past-state"
// label role) and the icon tile drops to ~0.55 opacity, the mockup's exact past-icon dim. (The mockup's
// past *ground* is `paper-50`; there is no semantic surface role for it yet — see the BookingRow report's
// token gap. The dim still reads clearly via the name + icon treatment.)
//
// A11y (05 §8.1): the component owns the MECHANISM — ONE combined VoiceOver stop carrying title + meta +
// status + confirmation, with the icon tile and the `StatusPill` hidden — and an `accessibilityID`
// PASSTHROUGH; the CALLER owns the id VALUE (`bookingrow.<id>`). No id is baked; the optional id is attached
// only when present via `.accessibilityIdentifier(ifPresent:)` (the shared helper), never `?? ""`.
import SwiftUI

// MARK: - Local fixture (no domain model / no AppStore — value type in, per 05 §8)

/// The row's data, as a tiny local value type for the component + its previews/snapshots. A screen's
/// presenter maps its domain `BookingModel` to this; the component never sees `AppStore` or a domain object
/// (01-arch §3, 05 §8). The presenter composes the meta string + decides the leading emphasized span.
struct BookingRowModel: Sendable, Identifiable {
    let id: String
    /// The booking name — the display-face row title (mockup `.bk-body .nm`).
    let title: String
    /// The meta line (mockup `.bk-body .mt`), e.g. "Now · 10:00 · timed entry · 2 adults" — the presenter
    /// composes the whole string; the leading `timeEmphasis` slice is rendered emphasized (below).
    let meta: String
    /// The leading emphasized slice of `meta` (mockup `.bk-body .mt .time`), e.g. "Now · 10:00". When
    /// `meta` begins with this string, that prefix is drawn emphasized; `nil` renders `meta` flat.
    let timeEmphasis: String?
    /// The booking type — drives the icon-tile tint/mark (`bookingTint`/`bookingMark`) and the a11y label.
    let type: BookingType
    /// The SF Symbol shown in the icon tile (the presenter supplies it from `BookingType.systemImage`; the
    /// component does not invent a glyph).
    let systemImage: String
    /// The booking's status — drives the trailing `StatusPill` (mockup `.bk-end .pill`).
    let status: BookingStatus
    /// The mono confirmation code under the pill (mockup `.bk-end .bk-conf`), e.g. "TDC-8841". `nil` shows
    /// nothing in that slot.
    let confirmation: String?
    /// Whether this is a past entry — the dim register (mockup `.bk.past`).
    let isPast: Bool

    init(
        id: String,
        title: String,
        meta: String,
        timeEmphasis: String? = nil,
        type: BookingType,
        systemImage: String,
        status: BookingStatus,
        confirmation: String? = nil,
        isPast: Bool = false
    ) {
        self.id = id
        self.title = title
        self.meta = meta
        self.timeEmphasis = timeEmphasis
        self.type = type
        self.systemImage = systemImage
        self.status = status
        self.confirmation = confirmation
        self.isPast = isPast
    }
}

// MARK: - BookingRow

/// The compact wallet booking row. Data in as a value type; covers type∈{lodging,transport,activity,dining,
/// other} × status∈{upcoming,today,now,past} plus the dim `.past` register. Renders content only — the
/// screen wraps it in the tappable `Button`/`NavigationLink` and supplies the `bookingrow.<id>` id (05 §8.1).
struct BookingRow: View {
    let model: BookingRowModel

    /// The caller-owned a11y id (`bookingrow.<id>`). The component bakes none; attached only when present.
    let accessibilityID: String?

    /// The icon tile is a fixed dimension that must grow with Dynamic Type, so it's `@ScaledMetric`, not a
    /// fixed `CGFloat` (mirrors `PlaceRow.wellSize`; T-6.4 / J-0.3).
    @ScaledMetric(relativeTo: .body) private var iconSide: CGFloat = Sizing.Component.bookingRowIcon

    init(model: BookingRowModel, accessibilityID: String? = nil) {
        self.model = model
        self.accessibilityID = accessibilityID
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            iconTile
            bodyColumn
            endColumn
        }
        .cardSurface()
        // One VoiceOver stop carrying the whole row (05 §8.1); the icon tile + the pill are hidden below.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        // Identifier passthrough — attached ONLY when the caller supplies one (no `?? ""` foot-gun).
        .accessibilityIdentifier(ifPresent: accessibilityID)
    }

    // MARK: Icon tile — the type-tinted glyph well (mockup `.bk-ico`), dimmed in the past register

    private var iconTile: some View {
        Image(systemName: model.systemImage)
            .font(Typography.body.weight(.medium))
            .foregroundStyle(ColorRole.bookingMark(model.type))
            .frame(width: iconSide, height: iconSide)
            .background(ColorRole.bookingTint(model.type), in: .rect(cornerRadius: Radius.row))
            // The mockup's exact past-icon dim (`.bk.past .bk-ico { opacity: 0.55 }`).
            .opacity(model.isPast ? 0.55 : 1)
            .accessibilityHidden(true)
    }

    // MARK: Body — name (display) over the meta line (secondary, leading `.time` slice emphasized)

    private var bodyColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(model.title)
                .font(Typography.name)
                // The past register drops the name to the explicit "past-state" label role (mockup
                // `.bk.past .nm`); otherwise the primary ink.
                .foregroundStyle(model.isPast ? ColorRole.textTertiary : ColorRole.textPrimary)
                .lineLimit(1)

            metaLine
        }
        .frame(maxWidth: .infinity, alignment: .leading) // left-aligned (J-7.1); takes the 1fr column
    }

    /// The meta line (mockup `.bk-body .mt`): the leading `timeEmphasis` slice emphasized, the remainder
    /// secondary. When `timeEmphasis` is `nil` (or `meta` doesn't lead with it), the whole line is flat.
    private var metaLine: some View {
        Text(metaAttributed)
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .lineLimit(1)
    }

    /// Builds the meta string with the leading time slice emphasized (mockup `.mt .time { color: ink-700;
    /// font-weight: 600 }`) — semibold + the primary ink, the rest left to the line's secondary style.
    private var metaAttributed: AttributedString {
        var full = AttributedString(model.meta)
        guard
            let emphasis = model.timeEmphasis,
            !emphasis.isEmpty,
            model.meta.hasPrefix(emphasis),
            let range = full.range(of: emphasis)
        else { return full }
        full[range].font = Typography.subhead.weight(.semibold)
        full[range].foregroundColor = ColorRole.textPrimary
        return full
    }

    // MARK: End — the StatusPill over the mono confirmation code (mockup `.bk-end`)

    private var endColumn: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            // The row already speaks the status in its combined label, so the pill is hidden — via the
            // pill's OWN hide mechanism (the component owns the means; BookingRow owns the decision).
            StatusPill(status: model.status, hidesFromAccessibility: true)

            if let confirmation = model.confirmation {
                Text(confirmation)
                    .font(Typography.footnote)
                    .tracking(Typography.trackCapsCaption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: Accessibility — the combined label (status spoken as text, never colour alone; 02-color §6)

    private var accessibilityLabel: String {
        var parts = ["\(model.title).", "\(model.status.displayLabel).", "\(model.meta)."]
        if let confirmation = model.confirmation {
            parts.append("Confirmation \(confirmation).")
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Previews — the five states (lodging · transport-now · activity-today · dining-upcoming · past)
// plus an AX5 register, per 05 §8/§10.

private extension BookingRowModel {
    /// Lodging · upcoming — an amber-tinted bed glyph, the standard register.
    static let lodgingUpcoming = BookingRowModel(
        id: "casa-do-bairro",
        title: "Casa do Bairro",
        meta: "Check-in 15:00 · 2 nights · Alfama",
        timeEmphasis: "Check-in 15:00",
        type: .lodging,
        systemImage: BookingType.lodging.systemImage,
        status: .upcoming,
        confirmation: "CDB-2207"
    )
    /// Activity · now — the live "now" pill, the screen's one live moment.
    static let activityNow = BookingRowModel(
        id: "castelo",
        title: "Castelo de São Jorge",
        meta: "Now · 10:00 · timed entry · 2 adults",
        timeEmphasis: "Now · 10:00",
        type: .activity,
        systemImage: BookingType.activity.systemImage,
        status: .now,
        confirmation: "CSJ-4419"
    )
    /// Transport · today — a slate-blue plane glyph, the inverse-ground "today" pill.
    static let transportToday = BookingRowModel(
        id: "ferry-cacilhas",
        title: "Ferry to Cacilhas",
        meta: "Departs 13:40 · Cais do Sodré",
        timeEmphasis: "Departs 13:40",
        type: .transport,
        systemImage: BookingType.transport.systemImage,
        status: .today,
        confirmation: "FRC-0098"
    )
    /// Dining · upcoming — a sage-tinted fork glyph.
    static let diningUpcoming = BookingRowModel(
        id: "belcanto",
        title: "Belcanto",
        meta: "20:30 · tasting menu · 2 covers",
        timeEmphasis: "20:30",
        type: .dining,
        systemImage: BookingType.dining.systemImage,
        status: .upcoming,
        confirmation: "BLC-7741"
    )
    /// Past — the dim register: faint name + dimmed icon + the quiet "past" pill.
    static let diningPast = BookingRowModel(
        id: "time-out",
        title: "Time Out Market",
        meta: "Yesterday · 13:00 · lunch",
        timeEmphasis: "Yesterday · 13:00",
        type: .dining,
        systemImage: BookingType.dining.systemImage,
        status: .past,
        confirmation: "TOM-1180",
        isPast: true
    )
}

#Preview("Lodging · upcoming") {
    BookingRow(model: .lodgingUpcoming, accessibilityID: "bookingrow.casa-do-bairro")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Activity · now") {
    BookingRow(model: .activityNow, accessibilityID: "bookingrow.castelo")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Transport · today") {
    BookingRow(model: .transportToday, accessibilityID: "bookingrow.ferry-cacilhas")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Dining · upcoming") {
    BookingRow(model: .diningUpcoming, accessibilityID: "bookingrow.belcanto")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Past") {
    BookingRow(model: .diningPast, accessibilityID: "bookingrow.time-out")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Activity · now · AX5") {
    BookingRow(model: .activityNow, accessibilityID: "bookingrow.castelo")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
        .environment(\.dynamicTypeSize, .accessibility5)
}
