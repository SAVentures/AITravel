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
// `OnboardingActionFloor` in the `actions:` thumb-zone slot. The leading affordance is a floating
// `GlassCircleButton` (× close → `cancelOnboarding()`) overlaid top-leading on the scaffold (floating
// chrome, NOT in the scroll content). The content opens with the in-content `OnboardingProgressBar`
// (step 0 · counter + segments, no glass — it scrolls with the content), then a hero (mono eyebrow +
// display question + sub) + `SearchWell` + `AIVoice` + an `HScrollSection` recent rail + a 2-column
// `LazyVGrid` of city tiles. No hand-wired `.toolbar` / `.navigationTitle` / `.padding` for structure
// (the scaffold owns chrome + the screen inset); no `ScrollView` (the scaffold owns it).
//
// ── Selection = ink ring + ink check, NEVER accent (J-2.4) ────────────────────────────────────────────
// `PlaceCard` carries the definitive (lifted) / fuzzy (received) certainty register (J-8). But its own
// `isSelected` mark is the budgeted accent fill — and the mockup's selected tile is an INK ring + INK
// check (`box-shadow … 0 0 0 2px var(--ink-900)` + an ink-900 check), NOT the accent. So the tile reads
// selection itself: a `textPrimary` (ink) ring overlay + an ink check at the top-trailing, while
// `PlaceCard` is rendered WITHOUT its accent `isSelected` mark. The screen's accent budget (≤2, J-2.4)
// is left to the CTA + the one `AIVoice` dot.
//
// ── Search-results mode (keyboard up / query typed) ───────────────────────────────────────────────────
// The `SearchWell` owns the keyboard via the view's `@FocusState searchFocused`. When focused OR a query
// is typed (`isSearching`), the screen enters RESULTS mode: the floating `OnboardingActionFloor` is
// withheld (the keyboard owns the thumb zone — the `actions:` slot renders `EmptyView()`), and the hero +
// Recent rail + grid are replaced by a vertical `LazyVStack` result list of `presenter.matchingCities`
// (the same presenter filter, surfaced as full-width rows). Picking a row commits the city, then clears
// the query + drops focus so the screen returns to the normal layout with the "Continue with …" CTA.
//
// ── Logic out of the view ─────────────────────────────────────────────────────────────────────────────
// Reads the store via `@Environment(AppStore.self)`; holds NO domain `@State`. Tile tap →
// `store.onboarding?.select(city:)` (a pure model method); CTA → `store.advanceOnboardingStep()`;
// close (the floating ×) → `store.cancelOnboarding()` (store commands). Semantic tokens only — zero literals.
import SwiftUI

/// Onboarding step 01 — the destination picker. Layout + wiring only; reads `DestinationStepPresenter`.
struct DestinationStepView: View {

    /// The single source of truth, injected at the App root (`06-screens.md §4`).
    @Environment(AppStore.self) private var store

    /// The live search query — ephemeral UI state the view owns (`06-screens.md §1`); NOT domain state.
    /// Passed into the presenter, which filters the rail + grid. The chosen city stays on the draft.
    @State private var searchText = ""

    /// Whether the search field holds the keyboard — ephemeral UI state the view owns (`06-screens.md §1`).
    /// Drives SEARCH-RESULTS mode: focus (or a non-empty query) hides the floating CTA and swaps the
    /// Recent rail + grid for a vertical result list. Passed to the `SearchWell` (it owns the focus binding).
    @FocusState private var searchFocused: Bool

    /// The 2-column grid layout for the "More cities" tiles (mockup `.pop` `grid-template-columns:
    /// 1fr 1fr`), bound at the sibling rung — the gap that groups by space (J-1 / J-4.2).
    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.itemGap),
        GridItem(.flexible(), spacing: Spacing.itemGap),
    ]

    var body: some View {
        // Rebuilt each `body` pass — cheap, and preserves the store's per-field dependency tracking.
        // The live query is threaded in so the presenter filters the rail + grid (logic stays there).
        let presenter = DestinationStepPresenter(store: store, searchText: searchText)

        // SEARCH-RESULTS mode: the keyboard is up OR a query is typed. Ephemeral UI state derived from the
        // view's own focus + query (not domain state), so it stays here, not the presenter (`06-screens.md §1`).
        // It HIDES the floating CTA (keyboard owns the thumb zone) and swaps the rail + grid for a result list.
        let isSearching = searchFocused || !searchText.isEmpty

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            // The floating CTA shows ONLY when a city selection exists on the draft (the store/model is the
            // source of truth — a fine read for this layout decision). Starting a search clears the prior
            // selection (`.onChange(of: searchFocused)` below), so the floor disappears the moment the field
            // is focused and returns only once a result is picked (which re-sets `destination`).
            if store.onboarding?.destination != nil {
                OnboardingActionFloor(
                    primaryTitle: presenter.ctaTitle,
                    primaryEnabled: presenter.canContinue,
                    primaryAccessibilityID: "destination.cta",
                    primaryAction: { store.advanceOnboardingStep() }
                )
            } else {
                EmptyView()
            }
        }) {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                // The in-content progress bar — counter + neutral segments, no glass. FIRST element,
                // scrolls with the content. The scaffold already insets content horizontally by
                // `Spacing.screenInset` (its `.contentMargins`), so the bar needs no extra inset here.
                OnboardingProgressBar(stepIndex: 0)
                // The hero shows ONLY in normal mode, above the field (the keyboard reads against the
                // field in search mode). It precedes the well so the question frames the search.
                if !isSearching {
                    hero(presenter)
                }
                // The search well renders EXACTLY ONCE, at a fixed slot with a stable `.id`, so its
                // `TextField` identity (and the keyboard focus) survives the mode switch. Rendering it in
                // both conditional arms tore down + rebuilt the field on focus, dropping focus and looping
                // `isSearching` forever (the freeze).
                searchWell()
                    .id("destination.searchwell")
                if isSearching {
                    // Result mode: a vertical list of the matching cities, below the field.
                    resultsList(presenter)
                } else {
                    // Normal mode: the editorial content below the field (AI voice + Recent rail + grid).
                    aiVoice(presenter)
                    recentRail(presenter)
                    grid(presenter)
                }
            }
            // Clear the floating leading `GlassCircleButton` (top-leading overlay): the content begins
            // BELOW it so the progress bar + hero don't collide with the × initially, then scrolls under
            // it. Scaled with Dynamic Type so the band tracks text size (J-0.3).
            .padding(.top, topChrome)
            // Starting a search drops the previous selection: the moment the field takes focus, clear the
            // chosen city so the floating CTA hides (its visibility reads `destination != nil` above) until
            // a result row re-sets the destination. A pure model method on the draft — no store reassignment.
            .onChange(of: searchFocused) { _, focused in
                if focused { store.onboarding?.clearDestination() }
            }
        }
        // The floating leading affordance: the × close glyph as a `GlassCircleButton`, overlaid
        // top-leading on the scaffold (floating chrome, NOT in the scroll content). The `.immersive`
        // safe-area handling keeps it below the notch; the top pad sets it in the top safe area (mockup).
        .overlay(alignment: .topLeading) {
            GlassCircleButton(
                systemImage: "xmark",
                accessibilityLabel: "Close",
                action: { store.cancelOnboarding() }
            )
            .padding(.leading, Spacing.screenInset)
            .padding(.top, Spacing.paired)
            .accessibilityIdentifier("onboarding.close")
        }
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

    // MARK: - Search well (editable field bound to `searchText`; bakes id `onboarding.search`)

    private func searchWell() -> some View {
        // The well is now an editable field: typing updates `searchText`, which the presenter reads to
        // filter the rail + grid. The city is still committed by tapping a (filtered) tile or chip below.
        SearchWell(text: $searchText, placeholder: "Search a city", kbdHint: "return ↵", focused: $searchFocused)
            // The component bakes `onboarding.search`; pin the screen-contract id the tests assert on too.
            .accessibilityIdentifier("destination.search")
    }

    // MARK: - Search-results list (the focused / typing mode — a vertical city list)

    /// The vertical result list shown in SEARCH mode: the presenter's `matchingCities` (already filtered by
    /// `searchText`) as full-width rows, replacing the Recent rail + grid. Selecting a row commits the city
    /// and drops back to the normal layout (the keyboard dismisses, the CTA returns).
    private func resultsList(_ presenter: DestinationStepPresenter) -> some View {
        LazyVStack(alignment: .leading, spacing: Spacing.hairline) {
            ForEach(presenter.matchingCities) { city in
                resultRow(city)
                if city.id != presenter.matchingCities.last?.id {
                    Divider()
                        .overlay(ColorRole.separator)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One result row: a leading glyph well + the city name (`Typography.name`) over a receded meta line
    /// (`Typography.caption` / `textTertiary`). Tapping commits the city (pure model method), then clears the
    /// query + drops focus so the screen returns to normal mode showing the selection + the "Continue with …" CTA.
    private func resultRow(_ city: City) -> some View {
        Button {
            // Pure model method on the draft — no networked write, no store reassignment (J-5 / 03 §3).
            store.onboarding?.select(city: city)
            // Leave search mode: drop the keyboard + clear the query so the normal layout + CTA return.
            searchFocused = false
            searchText = ""
        } label: {
            HStack(spacing: Spacing.cardInset) {
                Image(systemName: "mappin.and.ellipse")
                    .font(Typography.footnote)
                    .foregroundStyle(ColorRole.textTertiary)
                    .padding(Spacing.paired)
                    .background(ColorRole.fillTertiary, in: .circle)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(city.name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text(resultMeta(city))
                        .font(Typography.caption)
                        .foregroundStyle(ColorRole.textTertiary)
                }
                Spacer(minLength: Spacing.itemGap)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.itemGap)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("destination.result.\(city.id)")
        .accessibilityAddTraits(.isButton)
    }

    /// The receded subtitle for a result row: the country joined to the per-city meta (e.g.
    /// "Portugal · 23 saved"), mirroring the grid tile's inline meta.
    private func resultMeta(_ city: City) -> String {
        "\(city.country) · \(city.meta.displayLabel)"
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

    /// A single mini recent chip (mockup `.rcc`): a glyph well + the city name + a mono caps meta. Tappable
    /// — mirrors the grid `cityTile` wiring so a Recent city selects the destination (the CTA updates).
    private func recentChip(_ tile: CityTileModel) -> some View {
        Button {
            // Pure model method on the draft — no networked write, no store reassignment (J-5 / 03 §3).
            store.onboarding?.select(city: tile.city)
        } label: {
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
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("rail.recent.\(tile.city.id)")
        .accessibilityAddTraits(tile.isSelected ? [.isButton, .isSelected] : .isButton)
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

    /// The top clearance band that pins the scroll content below the floating leading `GlassCircleButton`
    /// (× close) so nothing collides at rest; scales with Dynamic Type (J-0.3) rather than a fixed point.
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = 68
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
