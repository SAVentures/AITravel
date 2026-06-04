/*
 Onboarding step 03 — "when are you going?". Layout + wiring only; derivation lives in WhenStepPresenter,
 mutations in TripDraftModel. A month is always chosen; the precision segment reveals exact-date pickers,
 floored to the trip length from the Trip Shape step.

 Selection treatment mirrors the rest of onboarding: the precision segment is an ink pill, never the
 accent (J-2.4); the one accent budget is the floor CTA.
*/
import SwiftUI

struct WhenStepView: View {

    @Environment(AppStore.self) private var store

    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance

    var body: some View {
        let p = WhenStepPresenter(store: store)

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            OnboardingActionFloor(
                primaryTitle: p.ctaTitle,
                primaryAccessibilityID: "when.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            ScreenSection {
                Color.clear.frame(height: topChrome)

                OnboardingProgressBar(stepIndex: OnboardingStep.when.index)

                hero(p)

                whenControls(p)
            }
        }
        .overlay(alignment: .topLeading) {
            GlassCircleButton(.back, action: { store.retreatOnboardingStep() })
                .padding(.leading, Spacing.screenInset)
                .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Hero

    private func hero(_ p: WhenStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(p.question)
                .font(Typography.titleLarge)
                .foregroundStyle(ColorRole.textPrimary)
            Text(p.sub)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.xl)
    }

    // MARK: - When controls

    @ViewBuilder private func whenControls(_ p: WhenStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            SegmentedSelector(
                options: DatePrecision.allCases,
                selection: p.datePrecision,
                label: \.label,
                systemImage: { _ in nil },
                accessibilityIDPrefix: "when.precision",
                accessibilityLabel: "Date precision",
                onSelect: { store.onboarding?.setDatePrecision($0) }
            )
            

            if p.datePrecision == .exactDates {
                exactDates(p)
            } else {
                monthMenu(p)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.xl)
    }

    @ViewBuilder private func monthMenu(_ p: WhenStepPresenter) -> some View {
        Menu {
            ForEach(p.monthOptions) { option in
                Button(option.label) {
                    store.onboarding?.setTripMonth(year: option.year, month: option.month)
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(Typography.footnote)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
                Text(p.selectedMonthLabel)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Spacer(minLength: Spacing.sm)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Typography.caption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(ColorRole.fillTertiary, in: .capsule)
        }
        .accessibilityIdentifier("when.month")
        .accessibilityLabel("Trip month")
        .accessibilityValue(p.selectedMonthLabel)
    }

    @ViewBuilder private func exactDates(_ p: WhenStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                DatePicker("Start date", selection: startBinding(p), displayedComponents: .date)
                    .labelsHidden()
                    .accessibilityIdentifier("when.start")
                Image(systemName: "arrow.right")
                    .font(Typography.caption)
                    .foregroundStyle(ColorRole.textTertiary)
                DatePicker(
                    "End date",
                    selection: endBinding(p),
                    in: p.minEndDate...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .accessibilityIdentifier("when.end")
            }
            // The exact range can't be shorter than the days chosen on Trip Shape.
            Text(p.exactRangeFloorHint)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
        }
    }

    private func startBinding(_ p: WhenStepPresenter) -> Binding<Date> {
        Binding(get: { p.exactStartDefault }, set: { store.onboarding?.setExactStart($0) })
    }

    private func endBinding(_ p: WhenStepPresenter) -> Binding<Date> {
        Binding(get: { p.exactEndDefault }, set: { store.onboarding?.setExactEnd($0) })
    }
}

// MARK: - Screen-local conformance

/* DatePrecision drives the generic SegmentedSelector; identity off rawValue in the screen layer
   (same module → no @retroactive), keeping the model Identifiable-free. */
extension DatePrecision: Identifiable {
    var id: String { rawValue }
}

// MARK: - Previews

#Preview("When · A (returning)") {
    NavigationStack {
        WhenStepView()
            .environment(AppStore.preview(SampleData.onboardingAContext(), step: .when))
    }
}

#Preview("When · C (first trip)") {
    NavigationStack {
        WhenStepView()
            .environment(AppStore.preview(SampleData.onboardingCContext(), step: .when))
    }
}
