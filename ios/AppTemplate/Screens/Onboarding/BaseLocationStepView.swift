// BaseLocationStepView.swift — onboarding step 03 (base location), the immersive takeover step.
//
// NAMES ITS MOCKUPS (the fidelity gate, 06-screens §9):
//   • mockups/screens/onboarding/state-a-screen-03-base-location.html  (Alfama)
//   • mockups/screens/onboarding/state-b-screen-03-base-location.html  (Gion)
//   • mockups/screens/onboarding/state-c-screen-03-base-location.html  (Baixa)
//
// Layout + wiring ONLY (06-screens §2 / §8): the view reads `AppStore` via the environment, holds no
// domain state, places design-system components fed by a stateless `BaseLocationStepPresenter`, and
// triggers change through model methods on the draft (`setBaseMode` / `select(base:)`) + the store's step
// command (`advanceOnboardingStep`). It NEVER hand-wires `.toolbar` / `.navigationTitle` / `ScrollView` /
// structural `.padding` — chrome + scroll come from `ScreenScaffold(.immersive)`, the sticky header from
// `OnboardingProgressHeader`, the thumb-zone CTA from `OnboardingActionFloor`.
//
// Chrome intent: `.immersive` — a takeover (tab bar hidden), per the onboarding flow (06-screens §2).
//
// ── Composition primitives + components placed ─────────────────────────────────────────────────────────
//   ScreenScaffold(.immersive, actions:) · OnboardingProgressHeader (sticky) · OnboardingActionFloor
//   (the floor) · ScreenSection · RhythmSpacer · HScrollSection (the alt rail) — composition;
//   SegmentedSelector · BaseMapCard · AIVoice · TimeHint · EmptyStateView — components.
//
// ── J-rules honored ────────────────────────────────────────────────────────────────────────────────────
//   J-0.1 — the map card is CONTENT, never glass (it sits on `cardSurface`, not a glass material); glass
//           lives only on the floating progress header. The base mode pill is content (ink-pill selected).
//   J-2.4 — one accent budget: the CTA's blue + the one AI "why" dot. The selected base-mode segment is
//           ink, not accent; the progress header is neutral.
//   J-3.6 / J-6.2 — exactly one editorial italic moment: the AI "why" line.
//   J-0.2 / J-0.3 — semantic tokens only; Dynamic Type throughout (no literals, no fixed content frames).
import SwiftUI

/// Onboarding step 03 — where the traveller bases themselves. Reads the active draft via the presenter,
/// renders the smart-recommendation card (map + AI "why" + reach rows + alts) or the manual stub, and
/// commits the recommended base on the CTA before advancing the flow.
struct BaseLocationStepView: View {

    /// The single source of truth — read from the environment, never constructed here (01-arch §4).
    @Environment(AppStore.self) private var store

    /// The stateless presenter over the store — all screen-specific derivation. Rebuilt each `body` pass
    /// (06-screens §3), so it is a cheap value, not stored state.
    private var presenter: BaseLocationStepPresenter { BaseLocationStepPresenter(store: store) }

    var body: some View {
        ScreenScaffold(.immersive, actions: {
            // The solid immersive floor (mockup `.ob-action`): the primary "Use {Neighborhood} as base"
            // CTA + the "Pick a specific hotel or address" ghost. CTA commits the recommended base then
            // advances; the ghost is stubbed (OPEN DECISION 5).
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
                // The hero — mono eyebrow + display question + the calming sub (mockup `.hero`).
                hero

                // The two-path segmented selector (mockup `.seg`) — ink-pill selected, never the accent.
                baseModeSelector

                // The body switches on the chosen mode: the smart recommendation, or the manual stub.
                switch presenter.baseMode {
                case .smart:
                    smartRecommendation
                case .manual:
                    manualStub
                }
            }
        }
        // The sticky frosted progress header pins above the scrolling content (step index 2 → "03 / 05";
        // back glyph → retreat a step). The ONE glass surface on the screen (J-0.1).
        .safeAreaInset(edge: .top) {
            OnboardingProgressHeader(
                stepIndex: 2,
                leadingGlyph: .back,
                leadingAction: { store.retreatOnboardingStep() }
            )
        }
    }

    // MARK: - Hero (mockup `.hero`)

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.paired) {
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

    // MARK: - Base-mode selector (mockup `.seg`)

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

    // MARK: - Smart recommendation (mockup `.rec` — map + AI "why" + reach rows + alts)

    private var smartRecommendation: some View {
        VStack(alignment: .leading, spacing: Spacing.sectionGap) {

            // The recommendation card — white `cardSurface`, NO colored edge (mockup `.rec`). The map fills
            // its top; the body carries the AI "why" + the reach rows. The card is CONTENT (J-0.1).
            VStack(alignment: .leading, spacing: Spacing.cardInset) {
                // The map card is content, never glass (J-0.1). The presenter owns the coord → region map.
                BaseMapCard(model: presenter.mapModel)

                VStack(alignment: .leading, spacing: Spacing.cardInset) {
                    // The one editorial italic moment + its accent dot (J-3.6 / J-6.2 / J-2.4).
                    AIVoice(eyebrow: presenter.whyEyebrow, line: presenter.whyVoice)

                    // The reach rows — each a `TimeHint` chip carrying the mono measurement (mockup `.reach`).
                    VStack(alignment: .leading, spacing: Spacing.paired) {
                        ForEach(presenter.reachRows) { row in
                            TimeHint(row.hint)
                                .accessibilityIdentifier("baselocation.reach.\(row.id)")
                        }
                    }
                }
                .padding(.horizontal, Spacing.cardInset)
                .padding(.bottom, Spacing.cardInset)
            }
            .containerShape(.rect(cornerRadius: Radius.card)) // the map inherits this concentric corner
            .cardSurface()
            .accessibilityIdentifier("baselocation.rec")

            // The "Tentative · change it any time" caption (mockup `.tent`) — quiet mono caps, the contract
            // that the base stays movable. No alarm color (J-11.5).
            tentativeCaption

            // The alternatives the model weighed (mockup `.alt-head` / `.alts`) — a horizontal rail.
            altNeighborhoodsRail
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The "Tentative · change it any time" eyebrow caption (mockup `.tent`).
    private var tentativeCaption: some View {
        Text("Tentative · change it any time")
            .font(Typography.caption)
            .tracking(Typography.trackEyebrowCaption)
            .textCase(.uppercase)
            .foregroundStyle(ColorRole.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// The alt-neighborhoods rail (mockup `.alts`) — each card a quiet name + mono meta line. `HScrollSection`
    /// owns its own head inset + scroll-content margins, so the rail composes as-is; the scaffold's
    /// content-margins inset the section content and the rail's leading edge aligns to the same screen
    /// margin (no manual padding here — structure is the primitive's job, J-1 / 06-screens §2).
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

// MARK: - Base-mode option (the segmented selector's value-type fixture)

/// The base-mode segments (mockup `.seg`): the smart AI recommendation vs the manual pick. A tiny
/// `Identifiable & Hashable` wrapper over `BaseSelectionMode` so it drives the generic `SegmentedSelector`,
/// with the per-case label + leading glyph (the manual segment carries the map-pin glyph, mockup `.seg svg`).
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

    /// The segment label. "Smart from saved" in state A; the catalog can later vary this, but the mockups
    /// across A/B/C all read "Smart from …" + "Pick manually" — the recommendation source word ("saved" /
    /// "plan") is editorial and kept literal to the primary (A) mockup here.
    var title: String {
        switch self {
        case .smart: "Smart from saved"
        case .manual: "Pick manually"
        }
    }

    /// The leading glyph — text-only for smart, a map-pin for the manual segment (mockup `.seg svg`).
    var systemImage: String? {
        switch self {
        case .smart: nil
        case .manual: "mappin"
        }
    }
}

// MARK: - Alt-neighborhood card (mockup `.alts .alt`)

/// One card in the alt-neighborhoods rail: a display name over a mono meta line. Content, never chrome —
/// a quiet `surfacePage` row on `Radius.row` (mockup `.alt` `background: var(--paper-100)`).
private struct AltNeighborhoodCard: View {
    let alt: BaseLocationStepPresenter.AltModel

    /// A floor on the card width so the rail reads as even tiles (mockup `.alt min-width: 134px`), scaled
    /// with Dynamic Type so it grows with the text rather than clipping (J-0.3).
    @ScaledMetric(relativeTo: .body) private var minCardWidth: CGFloat = 134

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            Text(alt.name)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
            Text(alt.meta)
                .font(Typography.caption)
                .monospacedDigit()
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(minWidth: minCardWidth, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alt.name), \(alt.meta)")
    }
}

// MARK: - Previews — one per state (A/B/C), seeded via AppStore.preview at the .baseLocation step
//
// The previews render the LIVE `BaseMapCard` (snapshotMode false) — interactive map tiles read correctly
// in Xcode. The Wave-5 L3 SNAPSHOT, by contrast, renders `BaseMapCard(snapshotMode: true)` so the lock is
// deterministic (no network tiles) per OPEN DECISION 4 — that variant is the snapshot writer's seam, not
// this preview's.

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
