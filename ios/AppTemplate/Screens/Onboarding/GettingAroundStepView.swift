/*
 Onboarding step 04 — "How will you get around?". Layout + wiring only; derivation lives in
 GettingAroundStepPresenter. Ports screen-04-getting-around.html (A/C — Lisbon €) and its state-b
 variant (Kyoto ¥).

 Two non-obvious choices:
 - The ONE editorial italic moment is only the rec line's mode word — a roman lead-in + an italic
   display tail (J-3.6 / OPEN-DECISION-7). The AI eyebrow stays plain mono.
 - Accent budget (J-2.4, ≤ 2) is the floor CTA + the one stateNow suggested dot; the context note
   carries NO alarm color (J-11.5).
*/
import SwiftUI

struct GettingAroundStepView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let p = GettingAroundStepPresenter(store: store)

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped, actions: {
            OnboardingActionFloor(
                primaryTitle: p.ctaTitle,
                primaryAccessibilityID: "gettingaround.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            // Top band so content opens below the floating back glyph and doesn't collide at rest.
            Color.clear.frame(height: topChrome)

            OnboardingProgressBar(stepIndex: OnboardingStep.gettingAround.index)

            RhythmSpacer(.section)

            ScreenSection {
                hero(p)
                RhythmSpacer(.section)
                recCard(p)
                if let note = p.contextNote {
                    contextNote(note)
                }
                divider
                modeControl(p)
            }

            RhythmSpacer(.hero)
        }
        // Back glyph as floating chrome (NOT in scroll content), top-leading → retreat one step.
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

    // MARK: - Hero

    @ViewBuilder private func hero(_ p: GettingAroundStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text(p.heroEyebrow)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textSecondary)
            Text(p.heroQuestion)
                .font(Typography.titleLarge)
                .tracking(Typography.titleLargeTracking)
                .foregroundStyle(ColorRole.textPrimary)
            Text(p.heroSub)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The AI rec card

    @ViewBuilder private func recCard(_ p: GettingAroundStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            Text(p.recEyebrow)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)

            HStack(alignment: .top, spacing: Spacing.itemGap) {
                // The ONE editorial italic moment: roman lead-in + italic display tail (the mode word).
                (
                    Text(p.recLineLead)
                        .font(Typography.name)
                    + Text(p.recLineEmphasis)
                        .font(Typography.name.italic())
                        .foregroundStyle(ColorRole.textSecondary)
                )
                .foregroundStyle(ColorRole.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Tag(p.cityContext)
            }

            Rectangle()
                .fill(ColorRole.separator)
                .frame(height: separatorThickness)
                .padding(.top, Spacing.paired)

            VStack(alignment: .leading, spacing: Spacing.paired) {
                ForEach(Array(p.reasonRows.enumerated()), id: \.offset) { _, reason in
                    HStack(alignment: .top, spacing: Spacing.paired) {
                        TimeHint(reason)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: - The conditional context note

    @ViewBuilder private func contextNote(_ note: (eyebrow: String, text: String)) -> some View {
        ContextNote(
            eyebrow: note.eyebrow,
            text: note.text,
            systemImage: "cloud.rain"
        )
    }

    // MARK: - "Your call" divider

    private var divider: some View {
        HStack(spacing: Spacing.itemGap) {
            line
            Text("Your call")
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(ColorRole.separator)
            .frame(height: separatorThickness)
            .frame(maxWidth: .infinity)
    }

    // MARK: - The two-tier mode control

    @ViewBuilder private func modeControl(_ p: GettingAroundStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sectionGap) {
            // Tier 1 — "Mostly": single-select segmented control.
            VStack(alignment: .leading, spacing: Spacing.paired) {
                tierHead(title: "Mostly", hint: "what we optimize around")

                SegmentedSelector(
                    options: p.mostlyOptions,
                    selection: p.primaryMode,
                    label: \.label,
                    systemImage: { $0.systemImage },
                    accessibilityIDPrefix: "transport.mostly",
                    onSelect: { mode in store.onboarding?.setPrimaryMode(mode) }
                )

                // The suggested hint + its ONE stateNow dot (the body's single accent, J-2.4).
                HStack(spacing: Spacing.paired) {
                    Circle()
                        .fill(ColorRole.stateNow)
                        .frame(width: suggestedDotSize, height: suggestedDotSize)
                    Text(p.suggestedHint)
                        .font(Typography.caption)
                        .tracking(Typography.trackEyebrowCaption)
                        .textCase(.uppercase)
                        .foregroundStyle(ColorRole.textTertiary)
                }
                .accessibilityElement(children: .combine)
            }

            // Tier 2 — "Also OK": multi-select chip row.
            VStack(alignment: .leading, spacing: Spacing.paired) {
                tierHead(title: "Also OK", hint: "we can mix these in")

                AlsoOKChipRow(
                    modes: p.alsoOKModes,
                    selected: p.selectedAlsoOK,
                    onToggle: { mode in store.onboarding?.toggleAlsoOK(mode) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func tierHead(title: String, hint: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.itemGap) {
            Text(title)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
            Spacer(minLength: Spacing.paired)
            Text(hint)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textSecondary)
        }
    }

    // MARK: - Scaled metrics

    @ScaledMetric(relativeTo: .body) private var separatorThickness: CGFloat = Stroke.separator
    @ScaledMetric(relativeTo: .caption2) private var suggestedDotSize: CGFloat = Sizing.dot
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance
}

// MARK: - Screen-local conformance

/* SegmentedSelector is generic over Identifiable & Hashable; the model layer stays Identifiable-free,
   so key TransportMode's identity off rawValue here in the screen layer. Same module → no @retroactive. */
extension TransportMode: Identifiable {
    var id: String { rawValue }
}

// MARK: - "Also OK" chip row

/* Wrapping multi-select chip row for the "Also OK" tier — private same-file subview; promote to
   DesignSystem/ only once a second screen needs a wrapping chip flow. Each chip is FilterChip. */
private struct AlsoOKChipRow: View {
    let modes: [TransportMode]
    let selected: Set<TransportMode>
    let onToggle: (TransportMode) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.paired) {
            ForEach(modes, id: \.self) { mode in
                FilterChip(
                    label: mode.label,
                    isSelected: selected.contains(mode),
                    action: { onToggle(mode) }
                )
                .accessibilityIdentifier("transport.alsook.\(mode.rawValue)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FlowLayout

/* A minimal wrapping flow Layout — places subviews left-to-right, wrapping when the row width is
   exceeded. Lives here because the chip row is the only consumer so far. */
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let advance = (current.indices.isEmpty ? 0 : spacing) + size.width
            if x + advance > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.indices.append(index)
            current.width = (current.indices.count == 1 ? 0 : current.width + spacing) + size.width
            current.height = max(current.height, size.height)
            x += advance
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}

// MARK: - Previews

#Preview("Getting around — A · Lisbon €") {
    NavigationStack {
        GettingAroundStepView()
    }
    .environment(AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround))
}

#Preview("Getting around — B · Kyoto ¥") {
    NavigationStack {
        GettingAroundStepView()
    }
    .environment(AppStore.preview(SampleData.onboardingBContext(), step: .gettingAround))
}

#Preview("Getting around — C · Lisbon first trip") {
    NavigationStack {
        GettingAroundStepView()
    }
    .environment(AppStore.preview(SampleData.onboardingCContext(), step: .gettingAround))
}
