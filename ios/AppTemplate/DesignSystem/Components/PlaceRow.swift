// PlaceRow.swift — the horizontal wishlist row (`.pl` in mockups/screens/saved/saved-shell.css; 05 §8).
//
// A CONTENT row, never glass (J-0.1): a `surfaceGrouped` card at `Radius.card`, lifted by the one rest
// shadow (`.cardSurface()`), with a three-zone grid — a 62pt thumb well · the name/meta/source body · a
// trailing chevron OR a `CategoryChip` (the caller's choice via the `trailing` enum, for the list-vs-search
// variants the screen renders). The thumb carries a `src-badge` provenance stamp (a `surfaceGrouped` circle
// lifted by `Shadow.rest`, with the source glyph) and, when no photo is present, a monochrome glyph
// placeholder — never a broken-image box (J-12.4, 08-slop G-1). The well height is `@ScaledMetric` so the
// row grows with Dynamic Type (mirrors `PlaceCard.wellHeight`; J-0.3). Tokens only (J-0.2).
//
// A11y (05 §8.1): the component owns the MECHANISM — one combined VoiceOver stop carrying name + meta +
// source + category, with the thumb/badge/chevron hidden — and an `accessibilityID` PASSTHROUGH; the
// CALLER owns the id VALUE (`placerow.<id>`). No id is baked; the optional id is attached only when present
// via `.accessibilityIdentifier(ifPresent:)` (the shared helper), never `?? ""`.
import SwiftUI

// MARK: - Trailing affordance — the list-vs-search variant, as a value-type arg

/// What sits in the row's trailing slot. `.chevron` for the standard wishlist list (a place pushes to its
/// detail); `.category` for the search results, where the `CategoryChip` re-states the kind inline.
enum PlaceRowTrailing: Sendable {
    /// A disclosure chevron — the row drills into a detail (mockup `.pl .chev`).
    case chevron
    /// A read-only `CategoryChip` — the search variant (mockup `.pl .pl-cat`).
    case category
}

// MARK: - Local fixture (no domain model / no AppStore — value type in, per 05 §8)

/// The row's data, as a tiny local value type for the component + its previews/snapshots. A screen maps
/// its domain place to this; the component never sees `AppStore` or a domain object (01-arch §3, 05 §8).
struct PlaceRowModel: Sendable, Identifiable {
    let id: String
    /// The place name — the display-face row title (mockup `.pl-body .nm`).
    let name: String
    /// The neighborhood · city meta line (mockup `.pl-body .mt`), e.g. "Príncipe Real · Lisbon".
    let meta: String
    /// The provenance label — mono caps, e.g. "FROM @TASTEMAKER" (mockup `.pl-body .src` text).
    let sourceLabel: String
    /// The SF Symbol the source line + the thumbnail provenance stamp both show (the source kind glyph).
    let sourceSystemImage: String
    /// The place's category — drives the trailing `CategoryChip` (and the combined a11y label).
    let category: PlaceCategory
    /// Whether a real photo exists. `false` renders the monochrome glyph placeholder (J-12.4), never a
    /// broken-image box; a real screen swaps its photo into the well when this is `true`.
    let hasThumbnail: Bool
    /// The trailing affordance — chevron (list) or category chip (search).
    let trailing: PlaceRowTrailing

    init(
        id: String,
        name: String,
        meta: String,
        sourceLabel: String,
        sourceSystemImage: String,
        category: PlaceCategory,
        hasThumbnail: Bool,
        trailing: PlaceRowTrailing
    ) {
        self.id = id
        self.name = name
        self.meta = meta
        self.sourceLabel = sourceLabel
        self.sourceSystemImage = sourceSystemImage
        self.category = category
        self.hasThumbnail = hasThumbnail
        self.trailing = trailing
    }
}

// MARK: - PlaceRow

/// The horizontal wishlist row. Data in as a value type; covers source∈{reel,screenshot,search} ×
/// trailing∈{chevron,category}, plus the no-photo placeholder. Renders content only — the screen wraps it
/// in the tappable `Button`/`NavigationLink` and supplies the `placerow.<id>` id (05 §8.1).
struct PlaceRow: View {
    let model: PlaceRowModel

    /// The caller-owned a11y id (`placerow.<id>`). The component bakes none; attached only when present.
    let accessibilityID: String?

    /// The thumb well is a fixed dimension that must grow with Dynamic Type, so it's `@ScaledMetric`, not a
    /// fixed `CGFloat` (mirrors `PlaceCard.wellHeight`; T-6.4 / J-0.3).
    @ScaledMetric(relativeTo: .body) private var wellSize: CGFloat = Sizing.Component.placeRowThumb
    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = Sizing.Component.placeRowBadge

    init(model: PlaceRowModel, accessibilityID: String? = nil) {
        self.model = model
        self.accessibilityID = accessibilityID
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            thumb
            bodyColumn
            trailing
        }
        .cardSurface()
        // One VoiceOver stop carrying the whole row (05 §8.1); the thumb/badge/chevron are hidden below.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        // Identifier passthrough — attached ONLY when the caller supplies one (no `?? ""` foot-gun).
        .accessibilityIdentifier(ifPresent: accessibilityID)
    }

    // MARK: Thumb well — a media well with the provenance stamp, or a monochrome placeholder

    private var thumb: some View {
        RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
            .fill(ColorRole.fillTertiary)
            .frame(width: wellSize, height: wellSize)
            // No photo in the design-system fixture: a monochrome glyph placeholder, never a broken-image
            // box (J-12.4, 08-slop G-1). A real screen swaps in the place photo when `hasThumbnail`.
            .overlay { if !model.hasThumbnail { placeholderGlyph } }
            .overlay(alignment: .bottomTrailing) { sourceBadge }
            .accessibilityHidden(true)
    }

    /// The "no photo yet" stand-in — a single neutral photo glyph (mockup leaves `.pl-thumb` a flat fill).
    private var placeholderGlyph: some View {
        Image(systemName: "photo")
            .font(Typography.title)
            .foregroundStyle(ColorRole.textTertiary)
    }

    /// The provenance stamp on the thumbnail corner (mockup `.src-badge`): a `surfaceGrouped` circle lifted
    /// off the card by the one rest shadow (no border, no glass — J-8.4), carrying the source-kind glyph.
    private var sourceBadge: some View {
        Image(systemName: model.sourceSystemImage)
            .font(Typography.caption)
            .foregroundStyle(ColorRole.textPrimary)
            .frame(width: badgeSize, height: badgeSize)
            .background(ColorRole.surfaceGrouped, in: .circle)
            .shadowRest()
            // Nudged so the circle overhangs the well corner, as the mockup's negative offset does.
            .offset(x: badgeSize / 4, y: badgeSize / 4)
    }

    // MARK: Body — name (display) / meta (secondary) / source (mono caps with a leading source glyph)

    private var bodyColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(model.name)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
                .lineLimit(1)

            Text(model.meta)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .lineLimit(1)

            sourceLine
        }
        .frame(maxWidth: .infinity, alignment: .leading) // left-aligned (J-7.1); takes the 1fr column
    }

    /// The provenance line — a leading source glyph + mono caps label (mockup `.pl-body .src`).
    private var sourceLine: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: model.sourceSystemImage)
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textTertiary)
            Text(model.sourceLabel)
                .font(Typography.caption)
                .tracking(Typography.trackCapsCaption)
                .foregroundStyle(ColorRole.textSecondary)
                .lineLimit(1)
        }
        .padding(.top, Spacing.xs) // a touch more air above the source than between name↔meta (mockup `.src`)
    }

    // MARK: Trailing — chevron (list) or the read-only CategoryChip (search)

    @ViewBuilder private var trailing: some View {
        switch model.trailing {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true) // the row is one combined element; the chevron is decoration
        case .category:
            CategoryChip(model.category)
        }
    }

    // MARK: Accessibility — the combined label (color/category always paired with text; 02-color §6)

    private var accessibilityLabel: String {
        "\(model.name). \(model.category.displayLabel). \(model.meta). \(model.sourceLabel)."
    }
}

// MARK: - Previews — source × trailing, plus the no-photo placeholder (05 §8, §10)

private extension PlaceRowModel {
    /// A reel source (Instagram/TikTok provenance) with the chevron — the standard list row.
    static let reelChevron = PlaceRowModel(
        id: "cevicheria",
        name: "A Cevicheria",
        meta: "Príncipe Real · Lisbon",
        sourceLabel: "FROM @TASTEMAKER",
        sourceSystemImage: "play.rectangle",
        category: .eat,
        hasThumbnail: true,
        trailing: .chevron
    )
    /// A screenshot source with the trailing category chip — the search-results variant.
    static let screenshotCategory = PlaceRowModel(
        id: "bar-alto",
        name: "Bar Alto",
        meta: "Bairro Alto · Lisbon",
        sourceLabel: "FROM A SCREENSHOT",
        sourceSystemImage: "camera.viewfinder",
        category: .drink,
        hasThumbnail: true,
        trailing: .category
    )
    /// A search source with the chevron — and no photo yet (the placeholder state).
    static let searchNoPhoto = PlaceRowModel(
        id: "kissaten",
        name: "Yanaka Kissaten",
        meta: "Yanaka · Tokyo",
        sourceLabel: "FOUND IN SEARCH",
        sourceSystemImage: "magnifyingglass",
        category: .stay,
        hasThumbnail: false,
        trailing: .chevron
    )
}

#Preview("Reel · chevron") {
    PlaceRow(model: .reelChevron, accessibilityID: "placerow.cevicheria")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Screenshot · category") {
    PlaceRow(model: .screenshotCategory, accessibilityID: "placerow.bar-alto")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Search · no photo") {
    PlaceRow(model: .searchNoPhoto, accessibilityID: "placerow.kissaten")
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}
