// DestinationStepView.swift — onboarding step 01, the destination picker (plan W4-01).
//
// ── Names its mockup (the fidelity gate, 06-screens §9) ───────────────────────────────────────────────
// Ports `mockups/screens/onboarding/state-a-screen-01-destination.html` (A — returning, local saves),
// `state-b-screen-01-destination.html` (B — saves elsewhere), and `state-c-screen-01-destination.html`
// (C — first trip). The three states differ only in derived COPY + the selected city; the structure is
// one screen. All per-state derivation lives in `DestinationStepPresenter`; this view is layout +
// wiring ONLY (`06-screens.md §1`).
//
// ── Chrome + composition ──────────────────────────────────────────────────────────────────────────────
// Immersive takeover: `ScreenScaffold(.immersive)` (tab bar hidden) with the floating
// `OnboardingActionFloor` in the `actions:` thumb-zone slot. The content is the sticky
// `OnboardingProgressHeader` (step 0, close glyph) + a hero (mono eyebrow + display question + sub) +
// `SearchWell` + `AIVoice` + an `HScrollSection` recent rail + a 2-column `LazyVGrid` of city tiles.
// No hand-wired `.toolbar` / `.navigationTitle` / `.padding` for structure (the scaffold owns chrome +
// the screen inset); no `ScrollView` (the scaffold owns it).
//
// ── Selection = ink ring + ink check, NEVER accent (J-2.4) ────────────────────────────────────────────
// `PlaceCard` carries the definitive (lifted) / fuzzy (received) certainty register (J-8). But its own
// `isSelected` mark is the budgeted accent fill — and the mockup's selected tile is an INK ring + INK
// check (`box-shadow … 0 0 0 2px var(--ink-900)` + an ink-900 check), NOT the accent. So the tile reads
// selection itself: a `textPrimary` (ink) ring overlay + an ink check at the top-trailing, while
// `PlaceCard` is rendered WITHOUT its accent `isSelected` mark. The screen's accent budget (≤2, J-2.4)
// is left to the CTA + the one `AIVoice` dot.
//
// ── Logic out of the view ─────────────────────────────────────────────────────────────────────────────
// Reads the store via `@Environment(AppStore.self)`; holds NO domain `@State`. Tile tap →
// `store.onboarding?.select(city:)` (a pure model method); CTA → `store.advanceOnboardingStep()`;
// close → `store.cancelOnboarding()` (store commands). Semantic tokens only — zero literals.
import SwiftUI

/// Onboarding step 01 — the destination picker. Layout + wiring only; reads `DestinationStepPresenter`.
struct DestinationStepView: View {

    /// The single source of truth, injected at the App root (`06-screens.md §4`).
    @Environment(AppStore.self) private var store

    /// The 2-column grid layout for the "More cities" tiles (mockup `.pop` `grid-template-columns:
    /// 1fr 1fr`), bound at the sibling rung — the gap that groups by space (J-1 / J-4.2).
    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.itemGap),
        GridItem(.flexible(), spacing: Spacing.itemGap),
    ]

    var body: some View {
        // Rebuilt each `body` pass — cheap, and preserves the store's per-field dependency tracking.
        let presenter = DestinationStepPresenter(store: store)

        ScreenScaffold(.immersive, actions: {
            OnboardingActionFloor(
                primaryTitle: presenter.ctaTitle,
                primaryEnabled: presenter.canContinue,
                primaryAccessibilityID: "destination.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                header(presenter)
                hero(presenter)
                searchWell(presenter)
                aiVoice(presenter)
                recentRail(presenter)
                grid(presenter)
            }
        }
    }

    // MARK: - Sticky progress header (step 0 · close)

    private func header(_ presenter: DestinationStepPresenter) -> some View {
        OnboardingProgressHeader(
            stepIndex: 0,
            leadingGlyph: .close,
            leadingAction: { store.cancelOnboarding() }
        )
    }

    // MARK: - Hero — mono eyebrow + display question + sub (mockup `.hero`)

    private func hero(_ presenter: DestinationStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.paired) {
            Text(presenter.eyebrow)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
            Text(presenter.question)
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
            Text(presenter.sub)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Search well (read-only display + tap-to-focus; bakes id `onboarding.search`)

    private func searchWell(_ presenter: DestinationStepPresenter) -> some View {
        SearchWell(
            value: presenter.searchValue,
            placeholder: "Search a city…",
            onTap: {}   // tap-to-focus is a no-op this milestone — the city is chosen from the tiles
        )
        // The component bakes `onboarding.search`; pin the screen-contract id the tests assert on too.
        .accessibilityIdentifier("destination.search")
    }

    // MARK: - AI voice — the one editorial italic line (mockup `.ai`)

    private func aiVoice(_ presenter: DestinationStepPresenter) -> some View {
        AIVoice(eyebrow: presenter.aiVoice.eyebrow, line: presenter.aiVoice.line)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recent rail (mockup `.rail` — mini city chips)

    private func recentRail(_ presenter: DestinationStepPresenter) -> some View {
        // The rail bleeds to the screen edges itself (HScrollSection owns its inset), so it sits OUTSIDE
        // the section column's inset; the outer scaffold inset is the column's, the rail manages its own.
        HScrollSection("Recent", meta: "Last 6 months", accessibilityIDPrefix: "rail.recent") {
            ForEach(presenter.recentCities) { tile in
                recentChip(tile)
            }
        }
    }

    /// A single mini recent chip (mockup `.rcc`): a glyph well + the city name + a mono caps meta.
    private func recentChip(_ tile: CityTileModel) -> some View {
        HStack(spacing: Spacing.paired) {
            Image(systemName: "photo")
                .font(Typography.footnote)
                .foregroundStyle(ColorRole.textTertiary)
                .padding(Spacing.paired)
                .background(ColorRole.fillTertiary, in: .circle)
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(tile.city.name)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Text(tile.city.country)
                    .font(Typography.caption)
                    .tracking(Typography.trackCapsCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
            }
        }
        .padding(.vertical, Spacing.paired)
        .padding(.horizontal, Spacing.cardInset)
        .background(ColorRole.fillTertiary, in: .capsule)
        .accessibilityElement(children: .combine)
    }

    // MARK: - More-cities grid (mockup `.pop` — 2×2 PlaceCard tiles)

    private func grid(_ presenter: DestinationStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            // The grid head — display title + mono caps meta (mockup `.rail-head` over `.pop`).
            HStack(alignment: .firstTextBaseline) {
                Text("More cities")
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Spacer(minLength: Spacing.itemGap)
                Text("From your saves")
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: gridColumns, spacing: Spacing.itemGap) {
                ForEach(presenter.gridCities) { tile in
                    cityTile(tile)
                }
            }
        }
    }

    /// One destination tile: a tappable `PlaceCard` in its certainty register, with the SELECTION read
    /// as an INK ring + INK check (NOT the accent — J-2.4), and the floating "plan started" `Tag`.
    private func cityTile(_ tile: CityTileModel) -> some View {
        Button {
            // Pure model method on the draft — no networked write, no store reassignment (J-5 / 03 §3).
            store.onboarding?.select(city: tile.city)
        } label: {
            PlaceCard(
                model: PlaceCardModel(
                    id: tile.city.id,
                    name: tile.city.name,
                    facts: tile.metaLabel,
                    certainty: tile.certainty
                )
                // NOTE: PlaceCard's own `isSelected` is the budgeted ACCENT mark; we deliberately do not
                // pass it — selection is rendered below as an ink ring + ink check to match the mockup.
            )
            .overlay(alignment: .topTrailing) { tileBadge(tile) }
            .overlay { selectionRing(tile) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("destination.city.\(tile.city.id)")
        .accessibilityAddTraits(tile.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// The selected tile's INK ring (mockup `.pcard.sel { box-shadow … 0 0 0 2px var(--ink-900) }`) —
    /// a `textPrimary` (ink) stroke at the card corner, NEVER the accent (J-2.4). Absent when unselected.
    @ViewBuilder
    private func selectionRing(_ tile: CityTileModel) -> some View {
        if tile.isSelected {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(ColorRole.textPrimary, lineWidth: selectionRingWidth)
        }
    }

    /// The top-trailing badge: the INK check on the selected tile (mockup `.pcard.sel .check`), or the
    /// floating "plan started" `Tag` on an unselected planStarted tile (mockup `.pcard .saved`).
    @ViewBuilder
    private func tileBadge(_ tile: CityTileModel) -> some View {
        if tile.isSelected {
            Image(systemName: "checkmark")
                .font(Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(ColorRole.surfacePage)        // paper glyph on the ink chip
                .padding(Spacing.paired)
                .background(ColorRole.textPrimary, in: .circle) // ink chip — NOT the accent (J-2.4)
                .padding(Spacing.cardInset)
                .accessibilityHidden(true)
        } else if tile.showsPlanStartedBadge {
            Tag(tile.city.meta.displayLabel)
                .padding(Spacing.cardInset)
        }
    }

    /// The ink ring thickness (mockup's 2pt ring), scaled with Dynamic Type so it holds at large sizes
    /// rather than staying a fixed point value (J-0.3).
    @ScaledMetric(relativeTo: .body) private var selectionRingWidth: CGFloat = 2
}

// MARK: - Previews — one per A/B/C seed (06-screens §8; AppStore.preview seam, no .shared)

#Preview("Destination · A (returning, local saves)") {
    DestinationStepView()
        .environment(AppStore.preview(SampleData.onboardingAContext(), step: .destination))
}

#Preview("Destination · B (saves elsewhere)") {
    DestinationStepView()
        .environment(AppStore.preview(SampleData.onboardingBContext(), step: .destination))
}

#Preview("Destination · C (first trip)") {
    DestinationStepView()
        .environment(AppStore.preview(SampleData.onboardingCContext(), step: .destination))
}
