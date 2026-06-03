/*
 Onboarding step 03 — base location, the immersive takeover step. Layout + wiring only; per-state
 derivation lives in BaseLocationStepPresenter. Ports state-{a,b,c}-screen-03-base-location.html
 (Alfama / Gion / Baixa).

 Two non-obvious choices:
 - The ONE glass surface is the floating leading back glyph; the map card is content on cardSurface (J-0.1).
 - One accent budget: the CTA's blue + the one AI "why" dot; the selected base-mode segment is ink (J-2.4).
*/
import SwiftUI

struct BaseLocationStepView: View {

    @Environment(AppStore.self) private var store
    @Environment(\.mapSnapshotMode) private var mapSnapshotMode   // L3 snapshots force the static map

    private var presenter: BaseLocationStepPresenter { BaseLocationStepPresenter(store: store) }

    // Clearance band pinning scroll content below the floating back glyph so nothing collides at rest.
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance

    var body: some View {
        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            OnboardingActionFloor(
                primaryTitle: presenter.ctaTitle,
                primaryAccessibilityID: "baselocation.cta",
                ghostTitle: "Pick a specific hotel or address",
                ghostAccessibilityID: "baselocation.ghost",
                ghostAction: {
                    // TODO: manual base picker — present the specific-hotel/address picker (OPEN DECISION 5).
                },
                primaryAction: {
                    if let base = presenter.selectedBase {
                        store.onboarding?.select(base: base)
                    }
                    store.advanceOnboardingStep()
                }
            )
        }) {
            ScreenSection {
                OnboardingProgressBar(stepIndex: 2)

                hero

                baseModeSelector

                switch presenter.baseMode {
                case .smart:
                    smartRecommendation
                case .manual:
                    manualStub
                }
            }
            .padding(.top, topChrome)
        }
        // Floating back glyph overlaid as chrome (not in scroll content) — the one glass surface (J-0.1).
        .overlay(alignment: .topLeading) {
            GlassCircleButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Back",
                action: { store.retreatOnboardingStep() }
            )
            .padding(.leading, Spacing.screenInset)
            .padding(.top, Spacing.sm)
            .accessibilityIdentifier("onboarding.back")
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Base location")
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
            Text("Where will you base yourself?")
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
            Text("A neighborhood is enough — we'll route around it. You can change this later.")
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Base-mode selector

    private var baseModeSelector: some View {
        SegmentedSelector(
            options: BaseModeOption.allCases,
            selection: BaseModeOption(presenter.baseMode),
            label: \.title,
            systemImage: \.systemImage,
            accessibilityIDPrefix: "basemode",
            onSelect: { option in
                store.onboarding?.setBaseMode(option.mode)
            }
        )
    }

    // MARK: - Smart recommendation

    private var smartRecommendation: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {

            VStack(alignment: .leading, spacing: Spacing.lg) {
                BaseMapCard(model: presenter.mapModel, snapshotMode: mapSnapshotMode)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    AIVoice(eyebrow: presenter.whyEyebrow, line: presenter.whyVoice)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(presenter.reachRows) { row in
                            TimeHint(row.hint)
                                .accessibilityIdentifier("baselocation.reach.\(row.id)")
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .containerShape(.rect(cornerRadius: Radius.card)) // the map inherits this concentric corner
            .cardSurface()
            .accessibilityIdentifier("baselocation.rec")

            tentativeCaption

            altNeighborhoodsRail
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tentativeCaption: some View {
        Text("Tentative · change it any time")
            .font(Typography.caption)
            .tracking(Typography.trackEyebrowCaption)
            .textCase(.uppercase)
            .foregroundStyle(ColorRole.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var altNeighborhoodsRail: some View {
        HScrollSection(
            "Other neighborhoods we weighed",
            accessibilityIDPrefix: "rail.alts"
        ) {
            ForEach(presenter.altNeighborhoods) { alt in
                AltNeighborhoodCard(alt: alt)
                    .accessibilityIdentifier("rail.alts.\(alt.id)")
            }
        }
    }

    // MARK: - Manual stub (OPEN DECISION 5 — the picker is not yet built)

    private var manualStub: some View {
        EmptyStateView(
            systemImage: "mappin.and.ellipse",
            message: "Manual base picker coming soon."
        )
        .accessibilityIdentifier("baselocation.manualstub")
    }
}

// MARK: - Base-mode option

/* Identifiable/Hashable wrapper over BaseSelectionMode so it drives the generic SegmentedSelector. */
private enum BaseModeOption: String, CaseIterable, Identifiable, Hashable {
    case smart
    case manual

    init(_ mode: BaseSelectionMode) {
        switch mode {
        case .smart: self = .smart
        case .manual: self = .manual
        }
    }

    var mode: BaseSelectionMode {
        switch self {
        case .smart: .smart
        case .manual: .manual
        }
    }

    var id: String { rawValue }

    // Kept literal to the primary (A) mockup; A/B/C vary the source word ("saved"/"plan") editorially.
    var title: String {
        switch self {
        case .smart: "Smart from saved"
        case .manual: "Pick manually"
        }
    }

    var systemImage: String? {
        switch self {
        case .smart: nil
        case .manual: "mappin"
        }
    }
}

// MARK: - Alt-neighborhood card

private struct AltNeighborhoodCard: View {
    let alt: BaseLocationStepPresenter.AltModel

    @ScaledMetric(relativeTo: .body) private var minCardWidth: CGFloat = Sizing.Component.cardMinWidth

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(alt.name)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
            Text(alt.meta)
                .font(Typography.caption)
                .monospacedDigit()
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(minWidth: minCardWidth, alignment: .leading)
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alt.name), \(alt.meta)")
    }
}

// MARK: - Previews
//
// These render the LIVE BaseMapCard (snapshotMode false); the L3 snapshot uses snapshotMode true for a
// deterministic, network-free lock (OPEN DECISION 4) — that variant is the snapshot writer's seam.

#Preview("State A · Alfama (returning, local saves)") {
    NavigationStack {
        BaseLocationStepView()
            .environment(AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation))
    }
}

#Preview("State B · Gion (saves elsewhere)") {
    NavigationStack {
        BaseLocationStepView()
            .environment(AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation))
    }
}

#Preview("State C · Baixa (first trip)") {
    NavigationStack {
        BaseLocationStepView()
            .environment(AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation))
    }
}
