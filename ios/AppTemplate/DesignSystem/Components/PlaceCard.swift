// PlaceCard.swift — the signature definitive/fuzzy place card (05-components §3; J-8).
//
// This is the product's one idea made concrete (the plan's POV §, the mockup `.pcard` lede): a place is
// either *definitive* — solid and lifted (a white `surfaceGrouped` card, a rest shadow, a roman display
// name, exact mono facts, a photo) — or *fuzzy* — receded (a flat `surfacePage` ground, NO shadow, an
// ITALIC name in lighter ink, a glyph instead of a photo). Certainty is carried by elevation, weight, and
// italic — never a border, never a fill, never glass (05-components §3.1–3.4, J-8.1/J-8.3/J-8.4).
//
// The register is a value-type ENUM arg (`PlaceCertainty`), not a boolean buried in the view — it is the
// one idea, so it reads at the call site (plan §C, components.html §03 lede). Data comes in as a tiny
// local value-type fixture (`PlaceCardModel`); no `AppStore`, no domain object (05 §8, 01-arch §3).
//
// ── Surface ─────────────────────────────────────────────────────────────────────────────────────────
// definitive → `.cardSurface()` (B1): `surfaceGrouped` + `Radius.card` + the `rest` shadow + the
//   concentric `containerShape`. fuzzy → the SAME footprint (same inset, same `Radius.card` corner, same
//   `containerShape`) but a flat `surfacePage` fill and NO shadow — it recedes (mockup `.pcard.fuzzy`:
//   `background: paper-100; box-shadow: none`). Same footprint matters so the loading-redacted state and
//   the two registers occupy identical space (no reflow; J-9.3).
//
// ── Concentric photo ────────────────────────────────────────────────────────────────────────────────
// The photo / glyph well uses `ConcentricRectangle()` and inherits the card's corner from the parent
// `containerShape` — never a hand-picked inner radius (03-layout-spacing §5, J-7.4). The mockup's literal
// `9px` photo radius is exactly what concentric computes (outer − inset); we don't transcribe the number.
//
// ── Italic for fuzzy ────────────────────────────────────────────────────────────────────────────────
// The fuzzy name applies `.italic()` to the display `Typography.name` role (mockup `.pcard.fuzzy .nm {
// font-style: italic }`). This is the receded register's cue, distinct from the AI-voice editorial italic
// (C8) — here it signals *uncertainty*, paired with lighter `textSecondary` ink and the flat ground so it
// never reads as decoration (J-3.6 governs the one editorial moment; this is the certainty register).
//
// States covered: definitive · fuzzy · selected (a single mark, never an accent fill — 05-components §3
// selected row, J-2.4) · loading (`.redacted(.placeholder)` at the same footprint — §3 loading row, J-9.3).
// No nesting, no side-border, no glass, one elevation (05-components §3.1–3.4). Semantic tokens + the
// `cardSurface` modifier only — zero literals, zero `Primitive.*` (J-0.2).
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

    /// The photo / glyph well height — a non-text metric, so it scales with Dynamic Type via
    /// `@ScaledMetric` rather than a fixed CGFloat (T-6.4). Seeded from the mockup's 116pt well.
    @ScaledMetric(relativeTo: .body) private var wellHeight: CGFloat = 116

    private var isFuzzy: Bool { model.certainty == .fuzzy }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
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
        VStack(spacing: Spacing.paired) {
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
        VStack(alignment: .leading, spacing: Spacing.hairline) {
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
        HStack(spacing: Spacing.paired) {
            ForEach(model.tags, id: \.self) { tag in
                Text(tag.uppercased())
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .foregroundStyle(ColorRole.textSecondary)
                    .padding(.horizontal, Spacing.paired)
                    .padding(.vertical, Spacing.hairline)
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
                .padding(Spacing.paired)
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
                .padding(Spacing.cardInset)
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
