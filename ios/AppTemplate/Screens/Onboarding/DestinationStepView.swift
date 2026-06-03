/*
 Onboarding step 01 — the destination picker. Layout + wiring only; per-state derivation (copy,
 selected city) lives in DestinationStepPresenter. Ports one structure across three states:
 mockups/screens/onboarding/state-{a,b,c}-screen-01-destination.html.

 Two non-obvious choices:
 - Selection renders as an ink ring + ink check, never PlaceCard's accent mark (J-2.4).
 - Search mode (field focused or query typed) withholds the floating CTA and swaps the hero/rail/grid
   for a result list; picking a row commits the city and exits search.
*/
import SwiftUI

struct DestinationStepView: View {

    @Environment(AppStore.self) private var store

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.itemGap),
        GridItem(.flexible(), spacing: Spacing.itemGap),
    ]

    var body: some View {
        let presenter = DestinationStepPresenter(store: store, searchText: searchText)
        let isSearching = searchFocused || !searchText.isEmpty

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            /* CTA shows only while a city is selected; focusing search clears it (below), hiding the floor. */
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
                OnboardingProgressBar(stepIndex: 0)
                if !isSearching {
                    hero(presenter)
                }
                /*
                 Render the well exactly once at a stable .id: placing the same focusable TextField in
                 both arms of `isSearching` tore it down on focus, dropping focus and looping (the freeze).
                */
                searchWell()
                    .id("destination.searchwell")
                if isSearching {
                    resultsList(presenter)
                } else {
                    aiVoice(presenter)
                    recentRail(presenter)
                    grid(presenter)
                }
            }
            .padding(.top, topChrome)   // clear the floating × overlay
            .onChange(of: searchFocused) { _, focused in
                if focused { store.onboarding?.clearDestination() }   // search drops the prior selection
            }
        }
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

    // MARK: - Hero

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

    // MARK: - Search well

    private func searchWell() -> some View {
        SearchWell(text: $searchText, placeholder: "Search a city", kbdHint: "return ↵", focused: $searchFocused)
            .accessibilityIdentifier("destination.search")   // screen-contract id the tests assert on
    }

    // MARK: - Search-results list

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

    private func resultRow(_ city: City) -> some View {
        Button {
            store.onboarding?.select(city: city)
            searchFocused = false   // commit + leave search mode
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

    private func resultMeta(_ city: City) -> String {
        "\(city.country) · \(city.meta.displayLabel)"
    }

    // MARK: - AI voice

    private func aiVoice(_ presenter: DestinationStepPresenter) -> some View {
        AIVoice(eyebrow: presenter.aiVoice.eyebrow, line: presenter.aiVoice.line)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recent rail

    private func recentRail(_ presenter: DestinationStepPresenter) -> some View {
        HScrollSection("Recent", meta: "Last 6 months", accessibilityIDPrefix: "rail.recent") {
            ForEach(presenter.recentCities) { tile in
                recentChip(tile)
            }
        }
    }

    private func recentChip(_ tile: CityTileModel) -> some View {
        Button {
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

    // MARK: - More-cities grid

    private func grid(_ presenter: DestinationStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
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

    private func cityTile(_ tile: CityTileModel) -> some View {
        Button {
            store.onboarding?.select(city: tile.city)
        } label: {
            /* Deliberately omit PlaceCard's accent `isSelected` mark — selection is the ink ring + check below (J-2.4). */
            PlaceCard(
                model: PlaceCardModel(
                    id: tile.city.id,
                    name: tile.city.name,
                    facts: tile.metaLabel,
                    certainty: tile.certainty
                )
            )
            .overlay(alignment: .topTrailing) { tileBadge(tile) }
            .overlay { selectionRing(tile) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("destination.city.\(tile.city.id)")
        .accessibilityAddTraits(tile.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func selectionRing(_ tile: CityTileModel) -> some View {
        if tile.isSelected {
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(ColorRole.textPrimary, lineWidth: selectionRingWidth)
        }
    }

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
    @ScaledMetric(relativeTo: .body) private var selectionRingWidth: CGFloat = Stroke.selected

    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance   // clears the floating × at rest
}

// MARK: - Previews

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
