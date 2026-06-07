// SourceCard.swift — the "by source" expandable card + its child row (05-components §8; J-8).
// Ports the mockup `.srccard` / `.src-place` / `.srccard-foot` (saved-shell.css): a CONTENT card —
// `surfaceGrouped`, `Radius.card`, CLIPPED, never glass (J-0.1). One source (a reel / screenshot /
// search) can yield many places; the expanded body lists them as `SourcePlaceRow`s.
//
// Disclosure is CALLER-OWNED: `isExpanded` + `onToggle` (the expansion `Set` lives in the screen's
// `@State`, exactly like `SegmentedSelector`'s selection). The component owns NO expansion state.
//
// A11y (05 §8.1): the head Button is ONE element carrying a `sourcecard.<id>` id passthrough + the
// expanded/collapsed state spoken via its `.accessibilityValue`; the child rows stay INDEPENDENTLY tappable inside the
// expanded body via `.accessibilityElement(children: .contain)` — NOT `.ignore`/`.combine`, which would
// collapse the children and kill per-row XCUITest taps (the SegmentedSelector lesson). Value-type
// fixtures only; no AppStore/domain object (05 §8). Tokens only (J-0.2).
import SwiftUI

// MARK: - Fixtures (value types in — no domain model / no AppStore, per 05 §8)

/// One source group's data, as a tiny local value type the screen maps its domain to. The component
/// never sees `AppStore` or a domain object (01-arch §3, 05 §8).
struct SourceCardModel: Sendable, Identifiable {
    let id: String
    /// The source title, display face (e.g. "@lisbonfoodie" / "Screenshots" / "Search").
    let title: String
    /// The mono-caps meta line (e.g. "REEL · 2 WEEKS AGO").
    let meta: String
    /// How this source was captured — drives the icon glyph + the tile tint.
    let kind: SourceKind
    /// The places this source yielded (rendered when expanded).
    let places: [SourcePlaceRowModel]
    /// An optional foot hint shown at the bottom of the expanded body (mockup `.srccard-foot`).
    let footHint: String?

    init(
        id: String,
        title: String,
        meta: String,
        kind: SourceKind,
        places: [SourcePlaceRowModel],
        footHint: String? = nil
    ) {
        self.id = id
        self.title = title
        self.meta = meta
        self.kind = kind
        self.places = places
        self.footHint = footHint
    }
}

/// One child row inside an expanded `SourceCard` — the compact place row (mockup `.src-place`).
struct SourcePlaceRowModel: Sendable, Identifiable {
    let id: String
    /// The place name, display face.
    let name: String
    /// The meta line (e.g. "Príncipe Real · Lisbon").
    let meta: String
    /// An optional saved-at timestamp stamp pill (mockup `.src-place .stamp`, e.g. "0:42").
    let stamp: String?

    init(id: String, name: String, meta: String, stamp: String? = nil) {
        self.id = id
        self.name = name
        self.meta = meta
        self.stamp = stamp
    }
}

// MARK: - SourceCard

/// The "by source" expandable card. Collapsed = the head only; expanded = head + divider + child rows
/// (+ an optional foot hint). Disclosure is caller-owned (`isExpanded` + `onToggle`).
struct SourceCard: View {
    let model: SourceCardModel
    /// Caller-owned disclosure (the screen's `@State` set). The component owns no expansion state.
    let isExpanded: Bool
    /// Fired when the head is tapped — the caller flips its `isExpanded` source of truth.
    let onToggle: () -> Void
    /// Per-row tap, handed the row id (the screen pushes the place detail).
    let onSelectPlace: (SourcePlaceRowModel.ID) -> Void
    /// The CALLER's id for the head Button (e.g. `sourcecard.<id>`); `nil` attaches none (no `""`
    /// foot-gun — 05 §8.1). The caller owns the value; the component owns the mechanism.
    var accessibilityID: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            head
            if isExpanded {
                expandedBody
            }
        }
        // CONTENT card: a grouped surface clipped to the card corner — never glass (J-0.1). `.clipShape`
        // matches the mockup `.srccard { overflow: hidden }` so the child-row dividers stay inside the
        // corner. No shadow: a source card sits flat on the page like the other saved-list rows.
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
        .clipShape(.rect(cornerRadius: Radius.card))
    }

    // MARK: Head — the tappable disclosure row (ONE a11y element)

    private var head: some View {
        Button(action: onToggle) {
            SourceCardHead(model: model, isExpanded: isExpanded)
        }
        .buttonStyle(SourceCardHeadStyle())
        // ONE a11y element for the whole head: the caller's id, the title+meta+count as the label, and the
        // expansion state as a spoken value, so VoiceOver announces "Expanded"/"Collapsed". (SwiftUI's
        // `AccessibilityTraits` has no `.isExpanded`, so the value is the single source for the state.)
        // The child rows are NOT here — they live in the expanded body as their own independently-tappable
        // elements (see `expandedBody`).
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(ifPresent: accessibilityID)
        .accessibilityLabel(headAccessibilityLabel)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }

    private var headAccessibilityLabel: String {
        let count = model.places.count
        let noun = count == 1 ? "place" : "places"
        return "\(model.title), \(model.meta), \(count) \(noun)"
    }

    // MARK: Expanded body — divider, then the child rows, then an optional foot hint

    private var expandedBody: some View {
        // `.contain` (NOT `.ignore`/`.combine`): the body is a covering group, but each child row stays an
        // independent, individually-resolvable, hittable element — so per-row XCUITest taps
        // (`app.buttons["sourceplacerow.<id>"]`) keep resolving and VoiceOver reaches each place. This is
        // the SegmentedSelector lesson (05 §8.1).
        VStack(spacing: 0) {
            Divider().overlay(ColorRole.separator)
            VStack(spacing: 0) {
                ForEach(Array(model.places.enumerated()), id: \.element.id) { index, place in
                    SourcePlaceRow(
                        model: place,
                        onTap: { onSelectPlace(place.id) },
                        accessibilityID: "sourceplacerow.\(place.id)"
                    )
                    // A hairline between rows (mockup `.src-place { border-bottom }`), none after the last.
                    if index < model.places.count - 1 {
                        Divider().overlay(ColorRole.separator)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            if let footHint = model.footHint {
                footRow(footHint)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The bottom hint inside an expanded source (mockup `.srccard-foot`): a hairline rule, a small glyph,
    /// and a line of secondary copy.
    private func footRow(_ hint: String) -> some View {
        VStack(spacing: 0) {
            Divider().overlay(ColorRole.separator)
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .accessibilityHidden(true)
                Text(hint)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        // One combined stop for the hint; its glyph is decorative.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Source card head content (inside the Button label)

/// The head's visual content: a source-icon tile · title + meta · a count pill + a caret. Split out so the
/// `Button` label stays declarative.
private struct SourceCardHead: View {
    let model: SourceCardModel
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: Spacing.lg) {
            sourceIcon
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(model.title)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                    .lineLimit(1)
                Text(model.meta)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .foregroundStyle(ColorRole.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Spacing.md) {
                countPill
                caret
            }
        }
    }

    /// The source-icon tile, tinted by source kind (mockup `.srccard-ico.reel/.shot/.search`). The glyph
    /// ink is the source mark; the tile is the low-alpha source tint — a mark paired with a glyph, never
    /// colour alone (02-color §6).
    @ScaledMetric(relativeTo: .body) private var iconTile: CGFloat = Sizing.Component.sourceIconTile

    private var sourceIcon: some View {
        Image(systemName: glyph)
            .font(Typography.title)
            .foregroundStyle(ColorRole.sourceMark(model.kind))
            .frame(width: iconTile, height: iconTile)
            .background(ColorRole.sourceTint(model.kind), in: .rect(cornerRadius: Radius.row))
            .accessibilityHidden(true)
    }

    private var glyph: String {
        switch model.kind {
        case .reel:       return "play.rectangle.fill"
        case .screenshot: return "photo.on.rectangle"
        case .search:     return "magnifyingglass"
        }
    }

    /// The count pill — tabular mono on a neutral fill (mockup `.srccard-count`).
    private var countPill: some View {
        Text("\(model.places.count)")
            .font(Typography.footnote)
            .monospacedDigit()
            .foregroundStyle(ColorRole.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.pill))
            .accessibilityHidden(true) // the count is in the head's combined label
    }

    /// The caret — rotates 180° when expanded. The rotation VALUE always reflects `isExpanded`, so it
    /// settles correctly at rest; only the *transition* is animated, and Reduce Motion drops the
    /// animation (the caret still ends rotated). Mockup `.srccard-caret` + `.srccard.open .caret`.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var caret: some View {
        Image(systemName: "chevron.down")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textTertiary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .animation(reduceMotion ? nil : Motion.standard(Motion.standard), value: isExpanded)
            .accessibilityHidden(true) // expansion is announced via the head's value/trait
    }
}

// MARK: - Source card head button style (tap feedback only — ≤100ms, §6)

private struct SourceCardHeadStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(Spacing.lg)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - SourcePlaceRow

/// The compact child row inside an expanded `SourceCard` (mockup `.src-place`): a thumb · name + meta
/// (with an optional saved-at stamp pill) · a trailing chevron. Value-type fixture in; the tap is a
/// caller closure; the `accessibilityID` is a passthrough the caller owns (05 §8.1).
struct SourcePlaceRow: View {
    let model: SourcePlaceRowModel
    let onTap: () -> Void
    /// The CALLER's id (e.g. `sourceplacerow.<id>`); `nil` attaches none (no `""` foot-gun — 05 §8.1).
    var accessibilityID: String? = nil

    /// The thumb side — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var thumbSide: CGFloat = Sizing.Component.sourcePlaceThumb

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                thumb
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(model.name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                        .lineLimit(1)
                    metaLine
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.md)
            .contentShape(.rect)
        }
        .buttonStyle(SourcePlaceRowStyle())
        // ONE a11y element per row: the caller's id + the name/meta/stamp as a combined label, so every
        // row is independently resolvable/tappable inside the parent's `.contain` group (05 §8.1).
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(ifPresent: accessibilityID)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        var parts = [model.name, model.meta]
        if let stamp = model.stamp { parts.append("at \(stamp)") }
        return parts.joined(separator: ", ")
    }

    /// The thumbnail well — a striped/neutral photo placeholder (the image is absent in the fixture; a
    /// monochrome well, never a broken-image box — J-12.4, mirrors PlaceCard's photo placeholder).
    private var thumb: some View {
        RoundedRectangle(cornerRadius: Radius.thumb)
            .fill(ColorRole.fillTertiary)
            .frame(width: thumbSide, height: thumbSide)
            .overlay {
                Image(systemName: "photo")
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .accessibilityHidden(true)
    }

    /// The meta line: secondary copy with an optional accent saved-at stamp pill (mockup `.src-place .mt`
    /// + `.stamp`). The stamp pairs accent ink with text, never colour alone (02-color §6).
    private var metaLine: some View {
        HStack(spacing: Spacing.sm) {
            Text(model.meta)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .lineLimit(1)
            if let stamp = model.stamp {
                Text(stamp)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .foregroundStyle(ColorRole.stampInk)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(ColorRole.stampFill, in: .rect(cornerRadius: Radius.tag))
            }
        }
    }
}

// MARK: - Source place row button style (tap feedback only)

private struct SourcePlaceRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Previews — one per meaningful state (05 §8, §10)

private extension SourceCardModel {
    static let reelMany = SourceCardModel(
        id: "reel-lisbonfoodie",
        title: "@lisbonfoodie",
        meta: "REEL · 2 WEEKS AGO",
        kind: .reel,
        places: [
            .init(id: "p1", name: "A Cevicheria", meta: "Príncipe Real · Lisbon", stamp: "0:12"),
            .init(id: "p2", name: "Time Out Market", meta: "Cais do Sodré · Lisbon", stamp: "0:34"),
            .init(id: "p3", name: "Pastéis de Belém", meta: "Belém · Lisbon", stamp: "1:05"),
        ],
        footHint: "One reel · three places, in the order they appeared."
    )
    static let searchSingle = SourceCardModel(
        id: "search-1",
        title: "Search",
        meta: "SEARCH · YESTERDAY",
        kind: .search,
        places: [
            .init(id: "p4", name: "Sushi Saito", meta: "Akasaka · Tokyo"),
        ]
    )
    static let screenshot = SourceCardModel(
        id: "shot-1",
        title: "Screenshots",
        meta: "SCREENSHOT · LAST MONTH",
        kind: .screenshot,
        places: [
            .init(id: "p5", name: "Fabrica Coffee", meta: "Baixa · Lisbon", stamp: "saved"),
            .init(id: "p6", name: "LX Factory", meta: "Alcântara · Lisbon", stamp: "saved"),
        ]
    )
}

#Preview("SourceCard — collapsed") {
    SourceCard(
        model: .reelMany,
        isExpanded: false,
        onToggle: {},
        onSelectPlace: { _ in }
    )
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("SourceCard — expanded (reel → many)") {
    SourceCard(
        model: .reelMany,
        isExpanded: true,
        onToggle: {},
        onSelectPlace: { _ in }
    )
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("SourceCard — expanded (search → single)") {
    SourceCard(
        model: .searchSingle,
        isExpanded: true,
        onToggle: {},
        onSelectPlace: { _ in }
    )
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("SourceCard — expanded (screenshot)") {
    SourceCard(
        model: .screenshot,
        isExpanded: true,
        onToggle: {},
        onSelectPlace: { _ in }
    )
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("SourcePlaceRow") {
    VStack(spacing: 0) {
        SourcePlaceRow(
            model: .init(id: "p1", name: "A Cevicheria", meta: "Príncipe Real · Lisbon", stamp: "0:12"),
            onTap: {},
            accessibilityID: "sourceplacerow.p1"
        )
        Divider().overlay(ColorRole.separator)
        SourcePlaceRow(
            model: .init(id: "p4", name: "Sushi Saito", meta: "Akasaka · Tokyo"),
            onTap: {},
            accessibilityID: "sourceplacerow.p4"
        )
    }
    .padding(.horizontal, Spacing.lg)
    .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
