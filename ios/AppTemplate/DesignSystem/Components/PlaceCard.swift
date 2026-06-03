// PlaceCard.swift — the signature definitive/fuzzy place card (05-components §3; J-8).
// Certainty is carried by elevation + weight + italic — never a border/fill/glass (§3.1–3.4, J-8). The
// register is a value-type enum arg; data is a local fixture, no AppStore/domain object (05 §8, 01-arch §3).
// definitive → `.cardSurface()`; fuzzy → the SAME footprint (flat `surfacePage`, no shadow, italic name in
// lighter ink) so registers + redacted loading share one footprint, no reflow (J-9.3). The photo well uses
// `ConcentricRectangle()` to inherit the card corner — never a hand-picked inner radius (03 §5, J-7.4).
// States: definitive · fuzzy · selected (one mark, never an accent fill — J-2.4) · loading. Tokens only (J-0.2).
import SwiftUI

// MARK: - The register — the product's one idea, as a value-type arg

/// Whether a place is pinned-down or still loose. Drives the whole card's treatment (plan POV §,
/// components.html §03): a *definitive* place is lifted and roman; a *fuzzy* one recedes and is italic.
enum PlaceCertainty: Sendable {
    /// Solid + lifted: white card, rest shadow, roman name, exact mono facts, a photo.
    case definitive
    /// Receded: flat ground, no shadow, italic name in lighter ink, a glyph instead of a photo.
    case fuzzy
}

// MARK: - Local fixture (no domain model / no AppStore — value type in, per 05 §8)

/// The card's data, as a tiny local value type for the component + its previews/snapshots. A screen maps
/// its domain place to this; the component never sees `AppStore` or a domain object (01-arch §3, 05 §8).
struct PlaceCardModel: Sendable, Identifiable {
    let id: String
    /// The place name. Roman when definitive, italic when fuzzy.
    let name: String
    /// The exact (definitive) or approximate (fuzzy) facts line — mono measurement (times, distances,
    /// prices): e.g. "08:00 · 8 MIN WALK · ¥1,200" or "~ 13:00 · NEAR YANAKA".
    let facts: String
    /// Short read-only tags (definitive: "Ramen", "Michelin"); empty for a fuzzy place.
    let tags: [String]
    /// Whether this place is pinned-down or loose — the register that drives the treatment.
    let certainty: PlaceCertainty

    init(
        id: String,
        name: String,
        facts: String,
        tags: [String] = [],
        certainty: PlaceCertainty
    ) {
        self.id = id
        self.name = name
        self.facts = facts
        self.tags = tags
        self.certainty = certainty
    }
}

// MARK: - PlaceCard

/// The definitive/fuzzy place card. Data in as a value type; covers definitive · fuzzy · selected ·
/// loading. Selected is a single mark; loading is a redacted footprint-stable placeholder (05-components §3).
struct PlaceCard: View {
    let model: PlaceCardModel
    /// A single selected mark (a checkmark), never an accent fill or border (05-components §3 selected, J-2.4).
    var isSelected: Bool = false
    /// Redacts the card at the same footprint while data loads (05-components §3 loading, J-9.3).
    var isLoading: Bool = false

    /// The photo / glyph well height — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var wellHeight: CGFloat = Sizing.Component.placeCardWell

    private var isFuzzy: Bool { model.certainty == .fuzzy }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            photoWell
            nameAndFacts
            if !model.tags.isEmpty { tagRow }
        }
        .modifier(SurfaceForRegister(certainty: model.certainty))
        .overlay(alignment: .topTrailing) { selectionMark }
        .redacted(reason: isLoading ? .placeholder : [])
        // One VoiceOver stop, not five (05-components §4.2).
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Photo well — definitive: a photo glyph; fuzzy: a small ring glyph (never a broken-image box)

    private var photoWell: some View {
        ConcentricRectangle() // inherits the card corner from the parent `containerShape` (03 §5)
            .fill(ColorRole.fillTertiary)
            .frame(height: wellHeight)
            .overlay { isFuzzy ? AnyView(fuzzyGlyph) : AnyView(definitivePhotoPlaceholder) }
            // The image is absent in the design-system fixture: a monochrome glyph placeholder, never a
            // broken-image box (J-12.4, 08-slop G-1). A real screen swaps in the place photo here.
            .accessibilityHidden(true)
    }

    /// Definitive: a contained photo glyph + a mono caps marker (mockup `.pcard .photo`).
    private var definitivePhotoPlaceholder: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "photo")
                .font(Typography.title)
                .foregroundStyle(ColorRole.textTertiary)
            Text("PLACE PHOTO")
                .font(Typography.caption)
                .tracking(Typography.trackCapsCaption)
                .foregroundStyle(ColorRole.textTertiary)
        }
    }

    /// Fuzzy: a single neutral ring glyph standing in for "no photo yet" (mockup `.pcard.fuzzy .photo .ring`).
    private var fuzzyGlyph: some View {
        Circle()
            .fill(ColorRole.separatorOpaque)
            .frame(width: wellHeight * 0.18, height: wellHeight * 0.18)
    }

    // MARK: Name + facts — definitive: roman display name; fuzzy: italic display name in lighter ink

    private var nameAndFacts: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(model.name)
                .font(Typography.name)
                .italic(isFuzzy) // the fuzzy register's cue — italic display name (mockup `.fuzzy .nm`)
                .foregroundStyle(isFuzzy ? ColorRole.textSecondary : ColorRole.textPrimary)
            Text(model.facts)
                .font(Typography.footnote) // exact (or approximate) mono facts
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // left-aligned (J-7.1)
    }

    // MARK: Tags — read-only mono capsules (definitive only)

    private var tagRow: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(model.tags, id: \.self) { tag in
                Text(tag.uppercased())
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .foregroundStyle(ColorRole.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.tag))
            }
        }
    }

    // MARK: Selected — a single accent mark, never a fill or border (05-components §3, J-2.4)

    @ViewBuilder private var selectionMark: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.name)
                .foregroundStyle(ColorRole.actionPrimary)
                .padding(Spacing.sm)
                .accessibilityHidden(true) // surfaced via the combined label below instead
        }
    }

    // MARK: Accessibility — color/italic certainty always paired with a label (02-color §6)

    private var accessibilityLabel: String {
        let register = isFuzzy ? "Tentative place" : "Place"
        let selected = isSelected ? ", selected" : ""
        return "\(register): \(model.name)\(selected). \(model.facts)"
    }
}

// MARK: - Surface for the register — definitive lifts via `.cardSurface()`; fuzzy recedes (flat, no shadow)

/// Applies the certainty register's surface. Definitive uses the shared `.cardSurface()` modifier (B1):
/// `surfaceGrouped` + `Radius.card` + the rest shadow + concentric `containerShape`. Fuzzy mirrors the
/// SAME footprint (same inset, same corner, same `containerShape`) on a flat `surfacePage` fill with NO
/// shadow — so the two registers and the redacted loading state share one footprint (no reflow; J-9.3).
private struct SurfaceForRegister: ViewModifier {
    let certainty: PlaceCertainty

    func body(content: Content) -> some View {
        switch certainty {
        case .definitive:
            content.cardSurface()
        case .fuzzy:
            content
                .padding(Spacing.lg)
                .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
                .containerShape(.rect(cornerRadius: Radius.card))
        }
    }
}

// MARK: - Previews — one per meaningful state (05 §8, §10)

private extension PlaceCardModel {
    static let definitive = PlaceCardModel(
        id: "tsuta",
        name: "Tsuta",
        facts: "08:00 · 8 MIN WALK · ¥1,200",
        tags: ["Ramen", "Michelin"],
        certainty: .definitive
    )
    static let fuzzy = PlaceCardModel(
        id: "lunch",
        name: "somewhere for lunch",
        facts: "~ 13:00 · NEAR YANAKA",
        certainty: .fuzzy
    )
}

#Preview("Definitive") {
    PlaceCard(model: .definitive)
        .padding()
        .background(ColorRole.surfacePage)
}

#Preview("Fuzzy") {
    PlaceCard(model: .fuzzy)
        .padding()
        .background(ColorRole.surfacePage)
}

#Preview("Selected") {
    PlaceCard(model: .definitive, isSelected: true)
        .padding()
        .background(ColorRole.surfacePage)
}

#Preview("Loading") {
    PlaceCard(model: .definitive, isLoading: true)
        .padding()
        .background(ColorRole.surfacePage)
}
