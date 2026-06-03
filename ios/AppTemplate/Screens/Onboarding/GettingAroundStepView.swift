// GettingAroundStepView.swift — onboarding Step 04: "How will you get around?" (plan W4-04).
//
// The fourth immersive step of the ONE adaptive `OnboardingFlow`: the AI reads the trip and suggests a
// transport mode, lays out the reasons (€ / ¥) + a quiet conditional caveat, then hands the decision to
// the user via a two-tier control — a single-select "Mostly" mode (what we optimize around) + a
// multi-select "Also OK" set (what we can mix in). Layout + wiring only: all derivation lives in
// `GettingAroundStepPresenter`; mutations go to the `TripDraft` model methods (`setPrimaryMode` /
// `toggleAlsoOK`) and the store's step nav (`advanceOnboardingStep`).
//
// NAMES ITS MOCKUPS (the fidelity gate, 06-screens §9):
//   `mockups/screens/onboarding/screen-04-getting-around.html`        (shared A / C — Lisbon €)
//   `mockups/screens/onboarding/state-b-screen-04-getting-around.html` (B — Kyoto ¥)
//
// Composition (06-screens §2): `ScreenScaffold(.immersive)` + a floating `GlassCircleButton` back glyph
// overlaid top-leading (→ `retreatOnboardingStep()`), the in-content `OnboardingProgressBar` (stepIndex 3,
// counter + segments, no glass) as the FIRST content element, the `OnboardingActionFloor` in the bottom
// thumb zone via `actions:`, and `ScreenSection` / `RhythmSpacer` carrying the vertical rhythm — no
// hand-wired chrome, padding, or `ScrollView`.
//
// The ONE editorial italic moment (J-3.6 / J-6.2 / OPEN-DECISION-7): only the rec line's mode word
// ("transit.") is italic — built here as a roman lead-in + an italic display tail. The AI eyebrow above
// it is plain mono (no second AIVoice line). The accent budget (J-2.4, ≤ 2) is the floor CTA + the one
// `stateNow` suggested dot under the "Mostly" selector; the context note carries NO alarm color (J-11.5).
import SwiftUI

/// Onboarding Step 04 — the transport-mode step. Reads `AppStore` from the environment, derives via
/// `GettingAroundStepPresenter`, and holds no domain state (the selection lives on the `TripDraft`).
struct GettingAroundStepView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let p = GettingAroundStepPresenter(store: store)

        ScreenScaffold(.immersive, actions: {
            OnboardingActionFloor(
                primaryTitle: p.ctaTitle,
                primaryAccessibilityID: "gettingaround.cta",
                primaryAction: { store.advanceOnboardingStep() }
            )
        }) {
            // Clear the floating leading `GlassCircleButton` (top-leading overlay): a top band so the
            // progress bar + hero open BELOW the back glyph and don't collide at rest, then scroll under
            // it. Scaled with Dynamic Type so the band tracks text size (J-0.3).
            Color.clear.frame(height: topChrome)

            // The in-content progress bar — counter + neutral segments, no glass. FIRST element, scrolls
            // with the content; stepIndex 3 (4 / 05). The scaffold already insets content horizontally by
            // `Spacing.screenInset`, so the bar needs no extra inset here.
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
        // The floating leading affordance: the back glyph as a `GlassCircleButton`, overlaid top-leading
        // on the scaffold (floating chrome, NOT in the scroll content) → retreat one step. The `.immersive`
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

    // MARK: - Hero (the shared `.hero` block — eyebrow · question · sub)

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

    // MARK: - The AI rec card (`.rec` — a `cardSurface` with the ONE italic editorial line)

    @ViewBuilder private func recCard(_ p: GettingAroundStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            // The plain mono AI eyebrow — NO accent dot (the budget is the suggested dot + the CTA).
            Text(p.recEyebrow)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)

            // The rec headline + the mono city/days context, baseline-aligned across the top of the card.
            HStack(alignment: .top, spacing: Spacing.itemGap) {
                // The ONE editorial italic moment: a roman lead-in + an italic display tail (the mode
                // word). Solid ink, never gradient text (02-color §5).
                (
                    Text(p.recLineLead)
                        .font(Typography.name)
                    + Text(p.recLineEmphasis)
                        .font(Typography.name.italic())
                        .foregroundStyle(ColorRole.textSecondary)
                )
                .foregroundStyle(ColorRole.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

                // The mono city/days context (multi-line) as a quiet tag.
                Tag(p.cityContext)
            }

            // The reason strip — a quiet separator over the € / ¥ `TimeHint` rows.
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

    // MARK: - The conditional context note (`.note` — quiet, NO alarm color — J-11.5)

    @ViewBuilder private func contextNote(_ note: (eyebrow: String, text: String)) -> some View {
        ContextNote(
            eyebrow: note.eyebrow,
            text: note.text,
            systemImage: "cloud.rain"
        )
    }

    // MARK: - "Your call" divider (the `.divider` caption rule)

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

    // MARK: - The two-tier mode control (`.ctrl` — "Mostly" selector + "Also OK" chips)

    @ViewBuilder private func modeControl(_ p: GettingAroundStepPresenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sectionGap) {
            // Tier 1 — "Mostly": the 4-way single-select segmented control (→ setPrimaryMode).
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

                // The mono suggested hint + its ONE `stateNow` dot (the body's single accent, J-2.4).
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

            // Tier 2 — "Also OK": the multi-select chip row (→ toggleAlsoOK).
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

    /// The tier head row: a mono caps label + a quiet inline hint (mockup `.tier-head`).
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

    /// The 1pt-on-the-grid separator thickness, scaled with text so the seam holds at large Dynamic Type
    /// (J-0.3 — never a fixed visual frame).
    @ScaledMetric(relativeTo: .body) private var separatorThickness: CGFloat = 1

    /// The suggested-hint dot, scaled with the caption caps text so it stays optically aligned (T-6.4).
    @ScaledMetric(relativeTo: .caption2) private var suggestedDotSize: CGFloat = 6

    /// The top clearance band that pins the scroll content below the floating leading `GlassCircleButton`
    /// (back glyph) so nothing collides at rest; scales with Dynamic Type (J-0.3) rather than a fixed point.
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = 68
}

// MARK: - Screen-local conformance

/// `SegmentedSelector` is generic over `Identifiable & Hashable`. `TransportMode` is `Hashable` already;
/// key its identity off the raw value so the selector can iterate it (the model layer stays
/// `Identifiable`-free — this conformance is added in the screen layer that needs it; same module, so no
/// `@retroactive`). Mirrors the `extension Pace: Identifiable` in `TripShapeStepView.swift`.
extension TransportMode: Identifiable {
    var id: String { rawValue }
}

// MARK: - "Also OK" chip row (the multi-select `.alsook` flow — a private same-file subview)

/// The wrapping multi-select chip row for the "Also OK" tier. A `private struct` in the same file
/// (06-screens §1) — promoted to `DesignSystem/` only once a second screen needs a wrapping chip flow.
/// Each chip is the design-system `FilterChip` (solid-ink + check when selected); the row owns only the
/// wrapping layout + the per-mode accessibility identifier (`transport.alsook.<mode>`).
private struct AlsoOKChipRow: View {
    let modes: [TransportMode]
    let selected: Set<TransportMode>
    let onToggle: (TransportMode) -> Void

    var body: some View {
        // A simple wrapping flow at the `paired` rung (mockup `.alsook gap: 8px`, `flex-wrap`).
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

// MARK: - FlowLayout (a tiny wrapping layout for the chip row)

/// A minimal wrapping flow `Layout` — places subviews left-to-right, wrapping to the next line when the
/// row width is exceeded (the chip row's `flex-wrap`). Lives here because it is layout-only and the chip
/// row is the only consumer so far; semantic `Spacing` only, no fixed content frames (J-0.3).
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

    /// Group subview indices into rows that fit within `maxWidth`, tracking each row's width + height.
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

// MARK: - Previews (one per A / B / C seed at the `.gettingAround` step — 06-screens §8)

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
