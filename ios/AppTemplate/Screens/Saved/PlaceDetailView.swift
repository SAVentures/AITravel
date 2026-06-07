/*
 The Saved place-detail screen. Layout + wiring only — all derivation lives in PlaceDetailPresenter
 (06-screens §3); the place is read off the store graph by id (06-screens §5). Ports the fidelity target
 mockups/screens/saved/place-detail.html: a full-bleed photo hero with an over-hero floating glass header,
 a title block (category chip + "neighborhood · city" kicker + display name), the "Saved from"
 ProvenanceCard, a three-cell PlaceInfoGrid, a MapSnippet, and a bottom "Add to a trip" CTA in the thumb zone.

 Chrome (D-6 rework): `ScreenScaffold(.custom)` — the mockup is a full-bleed edge-to-edge photo hero with a
 floating glass header drawn OVER it (`.pd-hero` + `.screen-topbar.--over-hero`). `.detail` cannot match
 that (it imposes a system inline nav bar + the standard horizontal content inset on the hero), so we
 escalate to `.custom` and own the header + back ourselves (06-screens §2.3 own-back requirement). The hero
 photo is drawn full-bleed (no horizontal content margin, square corners, into the top safe area); the rest
 of the content keeps the normal screen inset below it. The primary CTA rides the bottom `ActionBar` (the
 reachable thumb zone, 06-screens §2.4).

 Interactivity (06-screens §4.1 — every affordance hits a real sink, no dead closures):
  - Back glyph (over-hero) → `store.pop()` (the own-back the `.custom` chrome requires). id `placedetail.back`.
  - Bookmark glyph (over-hero) → STUB: this place is already saved and there is no unsave story this
    milestone, so the tap raises an in-content notice (`@State`), it does not mutate the graph. A wired
    stub (decisions.md entry), NOT a dead closure. id `placedetail.bookmark`.
  - "Add to a trip"  → D-5: no Trip feature this milestone → an ephemeral info banner (`@State`); NOT a
                        Trip screen (never invent the destination).
  - ProvenanceCard "View" → D-3: wire-only; opens the original — no player built. Sink is a stubbed action.
  - MapSnippet "Directions" → D-3: wire-only; Maps hand-off — none built. Sink is a stubbed action.
*/
import SwiftUI

struct PlaceDetailView: View {

    @Environment(AppStore.self) private var store

    let placeID: SavedPlaceModel.ID

    /// Ephemeral UI state only (06-screens §4): the D-5 "Add to a trip" stub surfaces this in-view info
    /// banner (the Trip feature does not exist yet) — never domain state, never a toast/alert.
    @State private var showsAddToTripNotice = false

    /// Ephemeral UI state only: the bookmark stub's in-view notice (no unsave story this milestone — the
    /// place is already saved). A wired stub sink, not a graph mutation (see decisions.md).
    @State private var showsBookmarkNotice = false

    /// The hero photo height — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var heroHeight: CGFloat = Sizing.Component.placeDetailHero

    var body: some View {
        let presenter = PlaceDetailPresenter(store: store, placeID: placeID)

        ScreenScaffold(.custom, actions: {
            // The one primary CTA, pinned in the reachable thumb zone (06-screens §2.4). D-5: the Trip
            // feature is a separate story — this raises an info banner, it does not push a Trip screen.
            ActionBar(
                primaryTitle: presenter.addToTripTitle,
                primaryAccessibilityID: "placedetail.addToTrip",
                primaryAction: { showsAddToTripNotice = true }
            )
        }) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if presenter.hasPlace {
                    hero
                    titleBlock(presenter)
                    if showsBookmarkNotice {
                        bookmarkNotice
                    }
                    if showsAddToTripNotice {
                        addToTripNotice
                    }
                    if let provenance = presenter.provenance {
                        ProvenanceCard(model: provenance, onView: openProvenanceSource)
                    }
                    if !presenter.facts.isEmpty {
                        PlaceInfoGrid(cells: presenter.facts)
                    }
                    if let address = presenter.address {
                        MapSnippet(address: address, onDirections: openDirections)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The over-hero floating glass header — the one glass surface on this screen (content stays
        // non-glass, J-0.1). It owns the back the `.custom` chrome requires (06-screens §2.3) and the
        // bookmark; both float over the photo. Mirrors onboarding's GlassCircleButton chrome overlay.
        .overlay(alignment: .top) {
            overHeroHeader
        }
    }

    // MARK: - Over-hero floating glass header (mockup `.screen-topbar.--over-hero`)

    /// Back + bookmark glyphs on the system Liquid Glass material, floating over the hero photo. Built from
    /// `GlassCircleButton` (the one component that touches glass — it IS floating chrome) like the
    /// onboarding back/close overlay. Both carry a real sink + an accessibility id (no dead chrome).
    private var overHeroHeader: some View {
        HStack {
            GlassCircleButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Back",
                accessibilityID: "placedetail.back",
                action: { store.pop() }
            )
            Spacer(minLength: Spacing.sm)
            GlassCircleButton(
                systemImage: "bookmark.fill",
                accessibilityLabel: "Saved",
                accessibilityID: "placedetail.bookmark",
                action: { showsBookmarkNotice = true }
            )
        }
        .padding(.horizontal, Spacing.screenInset)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Hero (mockup `.pd-hero`)

    /// The full-bleed photo banner. No real image in the fixture, so a monochrome glyph placeholder on a
    /// neutral well — never a broken-image box (J-12.4) — under a bottom legibility wash so the over-hero
    /// glass header reads. Edge-to-edge: it negates the scaffold's standard horizontal inset and runs into
    /// the top safe area, with SQUARE corners (the mockup's `.pd-hero` is a full-bleed banner, not a card).
    /// CONTENT, never glass (J-0.1).
    private var hero: some View {
        ZStack(alignment: .bottom) {
            ColorRole.fillTertiary
                .overlay {
                    Image(systemName: "photo")
                        .font(Typography.titleLarge)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            // A legibility wash under the photo (earned, not decorative — it darkens the photo's foot so the
            // over-hero glass header reads; clear-to-ink, never a colored gradient fill, 08-slop C-3). Uses
            // the hero-specific `heroScrim` role (a faint photo-legibility ink), NOT the heavy modal `scrim`.
            LinearGradient(
                colors: [.clear, ColorRole.heroScrim],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: heroHeight / 2)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        }
        .frame(height: heroHeight)
        .frame(maxWidth: .infinity)
        // Full-bleed: cancel the scaffold's horizontal content margin so the photo runs edge-to-edge, and
        // extend into the top safe area so it sits beneath the floating header (the mockup `.pd-hero`).
        .padding(.horizontal, -Spacing.screenInset)
        .ignoresSafeArea(edges: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place photo")
    }

    // MARK: - Title block (mockup `.pd-titleblock`)

    private func titleBlock(_ presenter: PlaceDetailPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                if let category = presenter.category {
                    CategoryChip(category)
                }
                // The "neighborhood · city" where-line: mono caps (mockup `.pd-kicker .where`). The font is
                // already the mono caption role; caps + eyebrow tracking are applied at the call site.
                Text(presenter.locationLine)
                    .font(Typography.caption)
                    .textCase(.uppercase)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textSecondary)
            }
            Text(presenter.displayName)
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bookmark notice (bookmark stub sink)

    /// The bookmark stub's in-content notice: the place is already saved and there is no unsave story this
    /// milestone, so the tap surfaces this rather than mutating the graph (no toast, no alert — 06-screens §6).
    private var bookmarkNotice: some View {
        Text("Saved. Removing places from Saved is coming soon.")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .accessibilityIdentifier("placedetail.bookmarkNotice")
    }

    // MARK: - Add-to-trip notice (D-5 stub sink)

    /// The D-5 info banner: the "Add to a trip" CTA has no Trip feature to push to yet, so it surfaces
    /// this in-content notice (no toast, no alert — 06-screens §6). A real Trip screen replaces this.
    private var addToTripNotice: some View {
        Text("Trips are coming soon — this place will be ready to add.")
            .font(Typography.subhead)
            .foregroundStyle(ColorRole.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .accessibilityIdentifier("placedetail.addToTripNotice")
    }

    // MARK: - Out-of-scope affordance sinks (D-3 wire-only)

    /// D-3: open the original reel/clip. No player is built this milestone — wiring only. A follow-up
    /// story owns the destination; surfaced for a coordinator decision (do not invent it here).
    private func openProvenanceSource() {
        // Intentionally a wired no-op sink (D-3): the destination is a separate story.
    }

    /// D-3: hand off to Maps for directions. No hand-off is built this milestone — wiring only.
    private func openDirections() {
        // Intentionally a wired no-op sink (D-3): the destination is a separate story.
    }
}

// MARK: - Previews — one per interesting state (06-screens §8)

#Preview("Place detail — A Cevicheria") {
    NavigationStack {
        PlaceDetailView(placeID: "place-cevicheria")
    }
    .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}

#Preview("Place detail — search-saved (no provenance)") {
    NavigationStack {
        PlaceDetailView(placeID: "place-cantinho-avillez")
    }
    .environment(AppStore.preview(savedPlaces: SampleData.savedPlacesDTO()))
}
