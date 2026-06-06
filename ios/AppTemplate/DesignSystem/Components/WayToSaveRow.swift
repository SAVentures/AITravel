// WayToSaveRow.swift — the rich empty-state / add-sheet "way to save" method row (05-components §4; J-8).
//
// A glyph-tile + title/subtitle + chevron row that drills into a capture method. One component serves
// BOTH the rich empty state (mockup `.way`, saved-empty.html) and the add-place method sheet (mockup
// `.method` / `.method.primary`, add-place.html) — same anatomy, two tiers.
//
// CONTENT, never glass (J-0.1): the row is a resting card (`surfaceGrouped` + `r-card` + rest shadow),
// not floating chrome. A `prominent` row is the SINGLE recommended method (the add-sheet's "Paste a
// reel"): it earns a faint `accentWashFill` ground + a 1px `accentWashRing` and an `actionPrimary` glyph
// tile — the accent reads as emphasis on the one recommended path (J-0.4/J-2.4/J-6.1), paired with the
// title, never a side-tab accent border (08-slop A-1) and never a saturated card fill. A standard row is
// a quiet `surfaceGrouped` tile (`textPrimary` glyph on a grouped well).
//
// The tap is a CALLER closure; the a11y id is a CALLER passthrough (`waytosave.<id>`, id ∈ reel /
// screenshot / search) — the component owns the MECHANISM (one combined label, hidden chevron), never
// bakes the id (05-design-system §8.1; the `OnboardingActionFloor` rule). Value-type fixture only, no
// AppStore/domain object (05 §8). Semantic tokens only — no literal, no `Primitive.*` (J-0.2).
import SwiftUI

// MARK: - Local fixture (no domain model / no AppStore — value type in, per 05 §8)

/// One "way to save" method, as a tiny local value type for the component + its previews/snapshots. A
/// screen maps its capture-method list to these; the component never sees `AppStore` or a domain object
/// (01-arch §3, 05 §8).
struct WayToSaveRowModel: Sendable, Identifiable {
    /// The method's stable identity (`reel` / `screenshot` / `search`) — also the a11y-id suffix a screen
    /// composes into `waytosave.<id>`.
    let id: String
    /// The method title — a present-tense phrase the user owns ("Paste a reel or video"; J-11.3).
    let title: String
    /// The one-line "what it does" subtitle — specific, calm copy, no alarm (J-11.2/J-11.5).
    let subtitle: String
    /// The leading SF Symbol shown in the glyph tile (a coherent single-weight set; J-12.1).
    let systemImage: String
    /// Whether this is the SINGLE recommended (prominent) row — the accent-washed tier (J-6.1). Exactly
    /// one row per region may be prominent; the rest are standard.
    var prominent: Bool = false

    init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        prominent: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.prominent = prominent
    }
}

// MARK: - WayToSaveRow

/// A tappable "way to save" method row. Data in as a value type; covers standard + prominent tiers. The
/// tap is a caller closure; the a11y id is a caller passthrough (the component bakes none — 05 §8.1).
struct WayToSaveRow: View {
    let model: WayToSaveRowModel
    /// The dot-namespaced id the CALLER owns (`waytosave.reel` etc.). The component attaches it only when
    /// present (no `?? ""` foot-gun) — it owns the mechanism, the screen owns the value (05 §8.1).
    var accessibilityID: String?
    /// The tap handler — the screen routes into the capture method (05-components §4.1 inventory).
    let action: () -> Void

    /// The glyph tile side — a non-text metric, so it scales with Dynamic Type (T-6.4); never a fixed
    /// frame (J-0.3). Prominent rows use the larger tile (mockup `.method .mi` vs `.way .wi`).
    @ScaledMetric(relativeTo: .body) private var standardTile: CGFloat = Sizing.Component.wayToSaveGlyph
    @ScaledMetric(relativeTo: .body) private var prominentTile: CGFloat = Sizing.Component.wayToSaveGlyphProminent

    private var tileSide: CGFloat { model.prominent ? prominentTile : standardTile }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                glyphTile
                titleAndSubtitle
                Spacer(minLength: Spacing.sm)
                chevron
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .containerShape(.rect(cornerRadius: Radius.card))
        }
        .buttonStyle(WayToSaveRowButtonStyle())
        // One combined VoiceOver stop — the title + subtitle carry the meaning; the chevron and the
        // decorative glyph are hidden (05 §8.1 / 05-components §4.2). The Button is already one element;
        // the explicit label keeps title + subtitle in a single, ordered announcement.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(model.title). \(model.subtitle)"))
        .accessibilityAddTraits(.isButton)
        // Identifier passthrough — attached ONLY when the caller supplies one (no baked id; 05 §8.1).
        .accessibilityIdentifier(ifPresent: accessibilityID)
    }

    // MARK: Glyph tile — prominent: an accent surface; standard: a grouped well (J-2.4)

    private var glyphTile: some View {
        Image(systemName: model.systemImage)
            .font(Typography.body.weight(.medium))
            .foregroundStyle(model.prominent ? ColorRole.textOnAccent : ColorRole.textPrimary)
            .frame(width: tileSide, height: tileSide)
            .background(tileBackground)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var tileBackground: some View {
        if model.prominent {
            // The budgeted accent surface (mockup `.method.primary .mi` — `accent-600` fill, no shadow).
            RoundedRectangle(cornerRadius: Radius.row).fill(ColorRole.actionPrimary)
        } else {
            // A quiet grouped well with the rest lift (mockup `.way .wi` / `.method .mi`).
            RoundedRectangle(cornerRadius: Radius.row)
                .fill(ColorRole.surfaceGrouped)
                .shadowRest()
        }
    }

    // MARK: Title + subtitle — display name over secondary sub copy (binary inks; J-2.2)

    private var titleAndSubtitle: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(model.title)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
            Text(model.subtitle)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Chevron — a "drills in" accessory, hidden from a11y (05-components §4.1, §4.2)

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textTertiary)
            .accessibilityHidden(true)
    }

    // MARK: Row surface — prominent: accent wash + ring; standard: grouped card (J-8, 08-slop A-1)

    @ViewBuilder private var rowBackground: some View {
        if model.prominent {
            // The one recommended row: a faint accent wash + a 1px accent ring (mockup `.method.primary`).
            // The ring marks the path, not a side-tab border (08-slop A-1, J-10.4).
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(ColorRole.accentWashFill)
                .strokeBorder(ColorRole.accentWashRing, lineWidth: Stroke.separator)
        } else {
            // A resting content card — grouped fill + the rest lift, no border (J-8.4 / 08-slop A-4).
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(ColorRole.surfaceGrouped)
                .shadowRest()
        }
    }
}

// MARK: - Style (the ≤100ms press commit · J-9.1)

/// The whole-row press feedback — a ~0.985 scale read from `configuration.isPressed`, committed in
/// ≤100ms before any animation (J-9.1). No fill swap; the row is content, not a tinted control.
private struct WayToSaveRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect(cornerRadius: Radius.card))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Preview fixtures (tiny in-file value types · Wave-C rule)

private extension WayToSaveRowModel {
    /// The add-sheet's SINGLE prominent method (mockup `.method.primary`, add-place.html).
    static let reel = WayToSaveRowModel(
        id: "reel",
        title: "Paste a reel or video",
        subtitle: "TikTok, Reel, or YouTube — even if it lists several spots",
        systemImage: "play.rectangle",
        prominent: true
    )
    /// A standard method (mockup `.way` / `.method`).
    static let screenshot = WayToSaveRowModel(
        id: "screenshot",
        title: "From a screenshot",
        subtitle: "A map pin, a story, or a menu photo",
        systemImage: "photo"
    )
    static let search = WayToSaveRowModel(
        id: "search",
        title: "Search for a place",
        subtitle: "Find it by name and pin it",
        systemImage: "magnifyingglass"
    )
}

private func waysStack() -> some View {
    VStack(spacing: Spacing.md) {
        WayToSaveRow(model: .reel, accessibilityID: "waytosave.reel") {}
        WayToSaveRow(model: .screenshot, accessibilityID: "waytosave.screenshot") {}
        WayToSaveRow(model: .search, accessibilityID: "waytosave.search") {}
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("Ways to save — prominent + standard") {
    waysStack()
}

#Preview("Prominent only") {
    WayToSaveRow(model: .reel, accessibilityID: "waytosave.reel") {}
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Standard only") {
    WayToSaveRow(model: .screenshot, accessibilityID: "waytosave.screenshot") {}
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}

#Preview("Ways to save — AX5") {
    waysStack()
        .environment(\.dynamicTypeSize, .accessibility5)
}
