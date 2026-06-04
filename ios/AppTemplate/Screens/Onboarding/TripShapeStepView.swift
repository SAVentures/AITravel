/*
 Onboarding step 02 — "one view, two bodies." Layout + wiring only; derivation lives in
 TripShapeStepPresenter, mutations in TripDraftModel. Ports state-{a,b,c}-screen-02-trip-shape.html.

 The presenter's step02Mode switches structurally-different bodies under one chrome + one CTA:
 .shapeCards (A/B) vs .tasteForm (C).

 Selection renders as ink ring + check / solid ink, never the accent (J-2.4).
*/
import SwiftUI

struct TripShapeStepView: View {

    @Environment(AppStore.self) private var store

    var body: some View {
        let p = TripShapeStepPresenter(store: store)

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            OnboardingActionFloor(
                primaryTitle: p.ctaTitle,
                primaryEnabled: p.canContinue,
                primaryAccessibilityID: "tripshape.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            // Top band that clears the floating back glyph so content opens below it, then scrolls under.
            Color.clear.frame(height: topChrome)

            OnboardingProgressBar(stepIndex: 1)

            hero(p)

            switch p.step02Mode {
            case .shapeCards: shapeCardsBody(p)
            case .tasteForm:  tasteFormBody(p)
            }

            footVoice(for: p)
                .padding(.top, Spacing.xl)
        }
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

    @ViewBuilder
    private func hero(_ p: TripShapeStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(p.heroQuestion)
                .font(Typography.titleLarge)
                .tracking(Typography.titleLargeTracking)
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(p.heroSub)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.xl)
    }

    // MARK: - Body A/B

    @ViewBuilder
    private func shapeCardsBody(_ p: TripShapeStepPresenter) -> some View {
        VStack(spacing: Spacing.md) {
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
                    onSelect: { store.onboarding?.select(strategy: card.strategy) }
                )
            }
        }
        .padding(.top, Spacing.xl)
    }

    // Erased so the card only reserves the slot, regardless of the embedded control's type.
    private func embeddedStepper(_ p: TripShapeStepPresenter) -> AnyView {
        AnyView(
            DayStepper(value: p.tasteDays, range: OnboardingRange.tripDays) {
                store.onboarding?.setDays($0)
            }
        )
    }

    // MARK: - Body C

    @ViewBuilder
    private func tasteFormBody(_ p: TripShapeStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            tasteBlock(eyebrow: "How long") {
                DayStepper(value: p.tasteDays, range: OnboardingRange.tripDays) {
                    store.onboarding?.setDays($0)
                }
            }

            tasteBlock(eyebrow: "What you're into", hint: "pick a few") {
                interestGrid(p)
            }

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
        .padding(.top, Spacing.xl)
    }

    // A labelled taste-form block: caps eyebrow (+ optional right-aligned hint) over its control.
    @ViewBuilder
    private func tasteBlock<Control: View>(
        eyebrow: String,
        hint: String? = nil,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(eyebrow.uppercased())
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textTertiary)
                if let hint {
                    Spacer(minLength: Spacing.sm)
                    Text(hint)
                        .font(Typography.subhead)
                        .foregroundStyle(ColorRole.textSecondary)
                }
            }
            control()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The chip → Interest mapping comes from zipping the presenter's ordered cases with its chip models.
    @ViewBuilder
    private func interestGrid(_ p: TripShapeStepPresenter) -> some View {
        let columns = [GridItem(.adaptive(minimum: interestChipMinWidth), spacing: Spacing.sm, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(zip(p.interests, p.interestChips)), id: \.0) { interest, chip in
                FilterChip(
                    label: chip.label,
                    systemImage: interest.systemImage,
                    isSelected: chip.isSelected,
                    action: { store.onboarding?.toggleInterest(interest) }
                )
                .accessibilityIdentifier("interest.\(interest.rawValue)")
            }
        }
    }

    // MARK: - Foot AIVoice

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

    @ScaledMetric(relativeTo: .subheadline) private var interestChipMinWidth: CGFloat = Sizing.Component.chipColumn

    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance
}

// MARK: - Screen-local conformances / constants

/* Identifiable lives in the screen layer (not the model) so the model stays Identifiable-free; same
   module, so no @retroactive. */
extension Pace: Identifiable {
    var id: String { rawValue }
}

// Shared by the embedded (card A) and standalone (state C) steppers so both clamp to one bound.
private enum OnboardingRange {
    static let tripDays: ClosedRange<Int> = 1...14
}

// MARK: - Previews

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
