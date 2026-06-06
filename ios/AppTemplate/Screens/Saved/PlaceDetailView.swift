/*
 The Saved place-detail screen. Layout + wiring only — all derivation lives in PlaceDetailPresenter
 (06-screens §3); the place is read off the store graph by id (06-screens §5). Ports the fidelity target
 mockups/screens/saved/place-detail.html: a photo hero, a title block (category chip + "neighborhood ·
 city" kicker + display name), the "Saved from" ProvenanceCard, a three-cell PlaceInfoGrid, a MapSnippet,
 and a bottom "Add to a trip" CTA in the thumb zone.

 Chrome (D-6): default `ScreenScaffold(.detail(title:))` — inline title + the system back chevron, with the
 tab bar persisting on push. The hero photo is the first content section; the primary CTA rides the bottom
 `ActionBar` (the reachable thumb zone, 06-screens §2.4). The over-hero custom header in the mockup is left
 to a fidelity-reviewer escalation to `.custom` (D-6) — the default here is `.detail`.

 Interactivity (06-screens §4.1 — every affordance hits a real sink, no dead closures):
  - "Add to a trip"  → D-5: no Trip feature this milestone → an ephemeral info banner (`@State`); NOT a
                        Trip screen (never invent the destination).
  - ProvenanceCard "View" → D-3: wire-only; opens the original — no player built. Sink is a stubbed action.
  - MapSnippet "Directions" → D-3: wire-only; Maps hand-off — none built. Sink is a stubbed action.
  - Back → the system back chevron (`.detail` chrome); `store.pop()` is the programmatic equivalent.
*/
import SwiftUI

struct PlaceDetailView: View {

    @Environment(AppStore.self) private var store

    let placeID: SavedPlaceModel.ID

    /// Ephemeral UI state only (06-screens §4): the D-5 "Add to a trip" stub surfaces this in-view info
    /// banner (the Trip feature does not exist yet) — never domain state, never a toast/alert.
    @State private var showsAddToTripNotice = false

    /// The hero photo height — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var heroHeight: CGFloat = Sizing.Component.placeDetailHero

    var body: some View {
        let presenter = PlaceDetailPresenter(store: store, placeID: placeID)

        ScreenScaffold(.detail(title: presenter.title), actions: {
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
    }

    // MARK: - Hero (mockup `.pd-hero`)

    /// The photo banner. No real image in the fixture, so a monochrome glyph placeholder on a neutral well
    /// — never a broken-image box (J-12.4) — under a bottom scrim for legibility of any over-hero chrome.
    /// CONTENT, never glass (J-0.1).
    private var hero: some View {
        ZStack(alignment: .bottom) {
            ColorRole.fillTertiary
                .overlay {
                    Image(systemName: "photo")
                        .font(Typography.titleLarge)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            // A legibility scrim under the photo (earned, not decorative — it darkens the photo's foot so
            // an over-hero title/back read; solid-to-clear, never a colored gradient fill, 08-slop C-3).
            LinearGradient(
                colors: [.clear, ColorRole.scrim],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: heroHeight / 2)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        }
        .frame(height: heroHeight)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: Radius.card))
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
                Text(presenter.locationLine)
                    .font(Typography.caption)
                    .foregroundStyle(ColorRole.textSecondary)
            }
            Text(presenter.displayName)
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
