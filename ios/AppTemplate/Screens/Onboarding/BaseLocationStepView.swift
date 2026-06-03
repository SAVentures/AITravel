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

    // Ephemeral UI state: whether the specific-address map sheet is up (OPEN DECISION 5).
    @State private var showingAddressPicker = false

    private var presenter: BaseLocationStepPresenter { BaseLocationStepPresenter(store: store) }

    // Clearance band pinning scroll content below the floating back glyph so nothing collides at rest.
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance

    var body: some View {
        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            OnboardingActionFloor(
                primaryTitle: presenter.ctaTitle,
                primaryEnabled: presenter.canContinue,
                primaryAccessibilityID: "baselocation.cta",
                ghostTitle: "Pick a specific hotel or address",
                ghostAccessibilityID: "baselocation.ghost",
                ghostAction: {
                    // A specific address is a base override, independent of the smart/manual segment.
                    showingAddressPicker = true
                },
                primaryAction: {
                    // A pinned address / manual neighborhood is already captured on the draft; only the
                    // smart segment (with no override) needs to commit its recommended base on continue.
                    if presenter.pinnedBaseName == nil,
                       presenter.baseMode == .smart,
                       let base = presenter.selectedBase {
                        store.onboarding?.select(base: base)
                    }
                    store.advanceOnboardingStep()
                }
            )
        }) {
            ScreenSection {
                OnboardingProgressBar(stepIndex: OnboardingStep.baseLocation.index)

                hero

                baseModeSelector

                // A specific pinned address overrides the segment; show it above whichever body is active.
                if let pinned = presenter.pinnedBaseName {
                    pinnedAddressRow(pinned)
                }

                switch presenter.baseMode {
                case .smart:
                    smartRecommendation
                case .manual:
                    manualPicker
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
        .sheet(isPresented: $showingAddressPicker) {
            ManualAddressPickerSheet(initialRegion: presenter.pickerRegion) { base in
                store.onboarding?.selectSpecificBase(base)
                store.onboarding?.setBaseMode(.manual)   // land on the manual segment showing the pick
            }
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

    // MARK: - Manual picker

    // Every neighborhood as a selectable row; the pick is captured on the draft (selectedNeighborhoodID).
    // A specific hotel/address still routes through the ghost button (OPEN DECISION 5).
    private var manualPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(presenter.manualOptions) { option in
                manualRow(option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("baselocation.manualpicker")
    }

    // Tapping the pinned address reopens the map sheet to change it.
    private func pinnedAddressRow(_ name: String) -> some View {
        Button {
            showingAddressPicker = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "mappin.circle.fill")
                    .font(Typography.title)
                    .foregroundStyle(ColorRole.textPrimary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text("Specific address · tap to change")
                        .font(Typography.caption)
                        .tracking(Typography.trackEyebrowCaption)
                        .textCase(.uppercase)
                        .foregroundStyle(ColorRole.textTertiary)
                }
                Spacer(minLength: Spacing.md)
                Image(systemName: "checkmark")
                    .font(Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorRole.surfacePage)
                    .padding(Spacing.sm)
                    .background(ColorRole.textPrimary, in: .circle)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.row)
                    .strokeBorder(ColorRole.textPrimary, lineWidth: selectionRingWidth)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("baselocation.manual.pinned")
        .accessibilityAddTraits([.isButton, .isSelected])
    }

    private func manualRow(_ option: BaseLocationStepPresenter.AltModel) -> some View {
        let isSelected = presenter.selectedNeighborhoodID == option.id
        return Button {
            store.onboarding?.selectNeighborhood(option.id)
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(option.name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text(option.meta)
                        .font(Typography.caption)
                        .monospacedDigit()
                        .foregroundStyle(ColorRole.textSecondary)
                }
                Spacer(minLength: Spacing.md)
                // Selection = ink ring + ink check, never the accent (J-2.4) — consistent with the other steps.
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorRole.surfacePage)
                        .padding(Spacing.sm)
                        .background(ColorRole.textPrimary, in: .circle)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.row)
                        .strokeBorder(ColorRole.textPrimary, lineWidth: selectionRingWidth)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("baselocation.manual.\(option.id)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// The ink ring thickness (mockup's 2pt ring), scaled with Dynamic Type so it holds at large sizes (J-0.3).
    @ScaledMetric(relativeTo: .body) private var selectionRingWidth: CGFloat = Stroke.selected
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
