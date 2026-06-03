// TripShapeStepView.swift — onboarding Step 02 (plan W4-02): the "one view, two bodies" step.
//
// NAMES ITS MOCKUPS (the fidelity gate, `06-screens.md §9`):
//   • mockups/screens/onboarding/state-a-screen-02-trip-shape.html  (A — three shape cards)
//   • mockups/screens/onboarding/state-b-screen-02-trip-shape.html  (B — "Cover the bucket" LOCKED)
//   • mockups/screens/onboarding/state-c-screen-02-trip-shape.html  (C — the taste form)
//
// One step, one chrome, one CTA, two structurally-different bodies (OPEN DECISION 2): the presenter's
// `step02Mode` switches `.shapeCards` (A/B) vs `.tasteForm` (C). Layout + wiring ONLY (`06-screens.md
// §1`): all derivation + the model → component mapping live in `TripShapeStepPresenter`; mutations go to
// the `TripDraft` model methods (`select(strategy:)` / `setDays` / `toggleInterest` / `setPace`) and the
// store's step-nav commands. No domain state in `@State` — the draft lives on `AppStore`.
//
// Chrome: `ScreenScaffold(.immersive)` (takeover — tab bar hidden), a floating `GlassCircleButton` back
// glyph overlaid top-leading (→ `retreatOnboardingStep()`), the in-content `OnboardingProgressBar`
// (step index 1 of 5, counter + segments, no glass) as the FIRST content element, and the SOLID
// `OnboardingActionFloor` in the thumb zone (the CTA → `advanceOnboardingStep()`). Exactly ONE foot
// `AIVoice` (the one editorial italic moment, J-6.2). Selected card = ink ring + check, never the accent
// (J-2.4); selected chip / pace segment = solid ink, never the accent (the components' load-bearing call).
import SwiftUI

/// Onboarding Step 02 — trip shape. Renders the three shape cards (A/B) or the taste form (C) under one
/// immersive chrome + one CTA, driven by `TripShapeStepPresenter.step02Mode`.
struct TripShapeStepView: View {

    /// The single source of truth, injected at the App root (`06-screens.md §4`).
    @Environment(AppStore.self) private var store

    var body: some View {
        let p = TripShapeStepPresenter(store: store)

        ScreenScaffold(.immersive, actions: {
            OnboardingActionFloor(
                primaryTitle: p.ctaTitle,
                primaryAccessibilityID: "tripshape.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            // Clear the floating leading `GlassCircleButton` (top-leading overlay): a top band so the
            // progress bar + hero open BELOW the back glyph and don't collide at rest, then scroll under
            // it. Scaled with Dynamic Type so the band tracks text size (J-0.3).
            Color.clear.frame(height: topChrome)

            // The in-content progress bar — counter + neutral segments, no glass. FIRST element, scrolls
            // with the content (the named mockups put it inside the scroll). Step index 1 of 5. The
            // scaffold already insets content horizontally by `Spacing.screenInset`, so no extra inset.
            OnboardingProgressBar(stepIndex: 1)

            hero(p)

            switch p.step02Mode {
            case .shapeCards: shapeCardsBody(p)
            case .tasteForm:  tasteFormBody(p)
            }

            // The one editorial italic moment on the screen (J-6.2) — the foot AI line.
            footVoice(for: p)
                .padding(.top, Spacing.sectionGap)
        }
        // The floating leading affordance: the back glyph as a `GlassCircleButton`, overlaid top-leading
        // on the scaffold (floating chrome, NOT in the scroll content) → retreat a step. The `.immersive`
        // safe-area handling keeps it below the notch; the top pad sets it in the top safe area (mockup).
        .overlay(alignment: .topLeading) {
            GlassCircleButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Back",
                action: { store.retreatOnboardingStep() }
            )
            .padding(.leading, Spacing.screenInset)
            .padding(.top, Spacing.paired)
            .accessibilityIdentifier("onboarding.back")
        }
    }

    // MARK: - Hero — eyebrow · question · sub (the named mockups' `.hero`)

    @ViewBuilder
    private func hero(_ p: TripShapeStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            Text(p.heroEyebrow.uppercased())
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textTertiary)
            Text(p.heroQuestion)
                .font(Typography.titleLarge)
                .tracking(Typography.titleLargeTracking)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(p.heroSub)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.paired)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.sectionGap)
    }

    // MARK: - Body A/B — three selectable shape cards (state-a/b-screen-02)

    @ViewBuilder
    private func shapeCardsBody(_ p: TripShapeStepPresenter) -> some View {
        VStack(spacing: Spacing.itemGap) {
            ForEach(p.shapeCards) { card in
                TripShapeCard(
                    id: card.id,
                    eyebrow: card.eyebrow,
                    title: card.title,
                    metricStrip: card.metricStrip,
                    diagram: card.diagram,
                    register: card.register,
                    isSelected: card.isSelected,
                    embeddedControl: card.embedsStepper ? embeddedStepper(p) : nil,
                    // Tap selects the strategy. A locked card's `onSelect` never fires (the component
                    // makes it inert), so this is a safe no-op there.
                    onSelect: { store.onboarding?.select(strategy: card.strategy) }
                )
            }
        }
        .padding(.top, Spacing.sectionGap)
    }

    /// The inline `DayStepper` embedded under the fixed-days card's title (state-a/b-screen-02's
    /// `.stepper`). Erased so the card only reserves the slot; drives the draft's `setDays`.
    private func embeddedStepper(_ p: TripShapeStepPresenter) -> AnyView {
        AnyView(
            DayStepper(value: p.tasteDays, range: OnboardingRange.tripDays) {
                store.onboarding?.setDays($0)
            }
        )
    }

    // MARK: - Body C — the taste form (state-c-screen-02)

    @ViewBuilder
    private func tasteFormBody(_ p: TripShapeStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sectionGap) {
            // How long — the standalone day stepper.
            tasteBlock(eyebrow: "How long") {
                DayStepper(value: p.tasteDays, range: OnboardingRange.tripDays) {
                    store.onboarding?.setDays($0)
                }
            }

            // What you're into — the multi-select interest chip grid.
            tasteBlock(eyebrow: "What you're into", hint: "pick a few") {
                interestGrid(p)
            }

            // Pace — the 3-way segmented selector (Easy / Balanced / Packed).
            tasteBlock(eyebrow: "Pace") {
                SegmentedSelector(
                    options: p.paceOptions,
                    selection: p.pace,
                    label: \.label,
                    systemImage: { _ in nil },
                    accessibilityIDPrefix: "pace",
                    onSelect: { store.onboarding?.setPace($0) }
                )
            }
        }
        .padding(.top, Spacing.sectionGap)
    }

    /// A labelled taste-form block: a mono caps eyebrow (+ an optional right-aligned hint, the mockup's
    /// `.tlab .h`) over its control. The internal-≤-external rhythm keeps the label bound to its control.
    @ViewBuilder
    private func tasteBlock<Control: View>(
        eyebrow: String,
        hint: String? = nil,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(eyebrow.uppercased())
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textTertiary)
                if let hint {
                    Spacer(minLength: Spacing.paired)
                    Text(hint)
                        .font(Typography.subhead)
                        .foregroundStyle(ColorRole.textSecondary)
                }
            }
            control()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The interest chips in a wrapping grid (the mockup's `.chips` flex-wrap). Each chip toggles its
    /// interest independently — a multi-select group (not single), so the chips carry their own selected
    /// state from the taste profile. The chip → `Interest` mapping comes from zipping the presenter's
    /// ordered cases with its chip models.
    @ViewBuilder
    private func interestGrid(_ p: TripShapeStepPresenter) -> some View {
        let columns = [GridItem(.adaptive(minimum: interestChipMinWidth), spacing: Spacing.paired, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.paired) {
            ForEach(Array(zip(p.interests, p.interestChips)), id: \.0) { interest, chip in
                FilterChip(
                    label: chip.label,
                    isSelected: chip.isSelected,
                    action: { store.onboarding?.toggleInterest(interest) }
                )
                .accessibilityIdentifier("interest.\(interest.rawValue)")
            }
        }
    }

    // MARK: - Foot AIVoice — the one editorial moment (J-6.2)

    @ViewBuilder
    private func footVoice(for p: TripShapeStepPresenter) -> some View {
        switch p.step02Mode {
        case .shapeCards:
            AIVoice(
                eyebrow: "Which to pick",
                line: "Fixed days is the safe call once flights are booked. Cover the bucket trades time for completeness."
            )
        case .tasteForm:
            AIVoice(
                eyebrow: "How we'll use this",
                line: "A few stops a day at your chosen pace, leaning into what you picked — with room left to wander."
            )
        }
    }

    /// The interest-chip grid's adaptive minimum column width — a non-text metric, so it scales with
    /// Dynamic Type (J-0.3) rather than a fixed point value. Seeded so a short chip ("Art") and a long one
    /// ("Architecture") both lay out cleanly across two-ish columns at body size.
    @ScaledMetric(relativeTo: .subheadline) private var interestChipMinWidth: CGFloat = 104

    /// The top clearance band that pins the scroll content below the floating leading `GlassCircleButton`
    /// (back glyph) so nothing collides at rest; scales with Dynamic Type (J-0.3) rather than a fixed point.
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = 68
}

// MARK: - Screen-local conformances / constants

/// `SegmentedSelector` is generic over `Identifiable & Hashable`. `Pace` is `Hashable` already; key its
/// identity off the raw value so the selector can iterate it (the model layer stays `Identifiable`-free —
/// this conformance is added in the screen layer that needs it; same module, so no `@retroactive`).
extension Pace: Identifiable {
    var id: String { rawValue }
}

/// The trip-length range the day steppers clamp to — shared by the embedded (card A) and standalone
/// (state C) steppers so both honor one bound (kept off the magic-number path; J-0.2 spirit).
private enum OnboardingRange {
    static let tripDays: ClosedRange<Int> = 1...14
}

// MARK: - Previews — one per A/B/C branch, seeded via `AppStore.preview(_:step:)` (`06-screens.md §8`)

#Preview("Trip shape · A — returning, 3 cards") {
    TripShapeStepView()
        .environment(AppStore.preview(SampleData.onboardingAContext(), step: .tripShape))
}

#Preview("Trip shape · B — cover-bucket LOCKED") {
    TripShapeStepView()
        .environment(AppStore.preview(SampleData.onboardingBContext(), step: .tripShape))
}

#Preview("Trip shape · C — taste form") {
    TripShapeStepView()
        .environment(AppStore.preview(SampleData.onboardingCContext(), step: .tripShape))
}
