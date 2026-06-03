/*
 The generate moment — a single "heartbeat" sweep over a firming-up planning checklist + a faint handoff
 peek. Ports state-a-screen-05-generate.html. Value-type args only; no AppStore/domain model.

 This is the ONE place in onboarding that owns continuous motion (J-9.3): one neutral band sweeping a 3pt
 track at Motion.think. It goes STATIC under BOTH Reduce Motion and the snapshot seam — the static
 checklist carries the state, so motion is never the only signal (04-motion §4.3 / J-9.5).
 The current step's stateNow ring is the screen's single accent (the CTA is absent here — J-2.4).
*/
import SwiftUI

// MARK: - Value-type args

struct GenerationStepVM: Identifiable, Equatable, Hashable, Sendable {

    enum Status: Equatable, Hashable, Sendable {
        case done
        case current
        case pending
    }

    let id: String
    let text: String
    let detail: String? // optional mono sub-line (e.g. "5 clusters found")
    let status: Status

    init(id: String, text: String, detail: String? = nil, status: Status) {
        self.id = id
        self.text = text
        self.detail = detail
        self.status = status
    }
}

struct HandoffVM: Equatable, Hashable, Sendable {
    let title: String
    let subtitle: String
}

// MARK: - GenerationProgressView

struct GenerationProgressView: View {

    let steps: [GenerationStepVM]
    let handoff: HandoffVM?

    init(steps: [GenerationStepVM], handoff: HandoffVM? = nil) {
        self.steps = steps
        self.handoff = handoff
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hero) {
            HeartbeatSweep()

            // The static checklist carries the state even with the sweep parked (04-motion §4.3).
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    GenerationStepRow(step: step, index: index)
                }
            }

            if let handoff {
                HandoffPeekCard(handoff: handoff)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("generation.progress")
    }
}

// MARK: - The heartbeat sweep

private struct HeartbeatSweep: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.disablesOneShotMotion) private var disablesOneShotMotion

    @State private var sweeping = false

    /// Static when EITHER the user has Reduce Motion on OR the snapshot seam disables it.
    private var motionDisabled: Bool { reduceMotion || disablesOneShotMotion }

    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 3
    private let bandFraction: CGFloat = 0.35 // mockup width: 35%

    var body: some View {
        Capsule()
            .fill(ColorRole.fillSecondary)
            .frame(height: trackHeight)
            .frame(maxWidth: .infinity)
            .overlay { sweepBand }
            .clipShape(.capsule) // clip the band to the track
            .accessibilityHidden(true) // decorative; the checklist + container carry the state
            .onAppear {
                guard !motionDisabled else { return }
                withAnimation(Motion.standard(Motion.think).repeatForever(autoreverses: false)) {
                    sweeping = true
                }
            }
    }

    private var sweepBand: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let bandWidth = width * bandFraction
            // Park fully off the leading edge at rest; sweep one band-width past the trailing edge.
            let offset = sweeping ? width : -bandWidth

            if motionDisabled {
                // Static rest frame: a full-width, 40%-opacity neutral bar that still reads as "working".
                Capsule()
                    .fill(ColorRole.separatorOpaque)
                    .opacity(0.4)
            } else {
                LinearGradient(
                    colors: [.clear, ColorRole.separatorOpaque, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: bandWidth)
                .offset(x: offset)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - One checklist row

private struct GenerationStepRow: View {

    let step: GenerationStepVM
    let index: Int

    @ScaledMetric(relativeTo: .body) private var glyphSize: CGFloat = 20

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.itemGap) {
            statusGlyph
                .frame(width: glyphSize, height: glyphSize)

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                bodyLine
                if let detail = step.detail {
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("generation.step.\(index)")
        .accessibilityValue(accessibilityStatus)
    }

    /// Italic display for the current step (the one editorial moment), roman body otherwise; ink recedes
    /// for done/pending.
    @ViewBuilder private var bodyLine: some View {
        switch step.status {
        case .current:
            Text(step.text)
                .font(Typography.name.italic())
                .foregroundStyle(ColorRole.textPrimary)
                .multilineTextAlignment(.leading)
        case .done:
            Text(step.text)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textSecondary)
                .multilineTextAlignment(.leading)
        case .pending:
            Text(step.text)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textTertiary)
                .multilineTextAlignment(.leading)
        }
    }

    /// State is conveyed by fill + glyph, never color alone (02 §6).
    @ViewBuilder private var statusGlyph: some View {
        switch step.status {
        case .done:
            // Solid ink disc + a paper check — definitive.
            Circle()
                .fill(ColorRole.textPrimary)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(ColorRole.textOnAccent)
                }
        case .current:
            // The screen's ONE accent: a stateNow disc with a paper core punched out (J-2.4).
            Circle()
                .fill(ColorRole.stateNow)
                .overlay {
                    Circle()
                        .fill(ColorRole.surfacePage)
                        .padding(glyphSize * 0.25)
                }
        case .pending:
            // Hollow neutral ring — recedes (not yet drawn).
            Circle()
                .strokeBorder(ColorRole.separatorOpaque, lineWidth: ringWidth)
        }
    }

    @ScaledMetric(relativeTo: .body) private var ringWidth: CGFloat = 1.5

    private var accessibilityStatus: String {
        switch step.status {
        case .done: "done"
        case .current: "in progress"
        case .pending: "pending"
        }
    }
}

// MARK: - HandoffPeekCard

struct HandoffPeekCard: View {

    let handoff: HandoffVM

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            Text(handoff.title)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textTertiary)

            Text(handoff.subtitle)
                .font(Typography.name.italic())
                .foregroundStyle(ColorRole.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
        .opacity(0.5) // faint — the next surface isn't drawn yet
        .allowsHitTesting(false) // a preview, not a control
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("generation.handoff")
        .accessibilityLabel("\(handoff.title): \(handoff.subtitle)")
    }
}

// MARK: - Previews

#Preview("Generation — mid-progress") {
    // Settled: inject the snapshot seam so the heartbeat parks at rest. Mid-generation: 3 done, 1 current.
    GenerationProgressView(
        steps: [
            GenerationStepVM(id: "cluster", text: "Grouping your 23 places by neighborhood",
                             detail: "5 clusters found", status: .done),
            GenerationStepVM(id: "days", text: "Clustering into 4 days",
                             detail: "Alfama · Belém · Bairro Alto · Parque", status: .done),
            GenerationStepVM(id: "route", text: "Routing each day to minimize backtracking",
                             detail: "2 loops · 1 line · 1 hub", status: .done),
            GenerationStepVM(id: "sequence", text: "Sequencing the days so they flow geographically",
                             status: .current),
            GenerationStepVM(id: "meals", text: "Spacing meals and rest", status: .pending),
            GenerationStepVM(id: "tips", text: "Adding context-aware tips", status: .pending),
        ],
        handoff: HandoffVM(title: "Up next · Trip overview",
                           subtitle: "Lisbon · 4 days, your shape.")
    )
    .padding(Spacing.screenInset)
    .environment(\.disablesOneShotMotion, true)
}

#Preview("Generation — near-complete") {
    // Near-done: only the last step remains current.
    GenerationProgressView(
        steps: [
            GenerationStepVM(id: "cluster", text: "Grouping your 23 places by neighborhood",
                             detail: "5 clusters found", status: .done),
            GenerationStepVM(id: "days", text: "Clustering into 4 days", status: .done),
            GenerationStepVM(id: "route", text: "Routing each day to minimize backtracking", status: .done),
            GenerationStepVM(id: "sequence", text: "Sequencing the days so they flow geographically",
                             status: .done),
            GenerationStepVM(id: "meals", text: "Spacing meals and rest", status: .done),
            GenerationStepVM(id: "tips", text: "Adding context-aware tips", status: .current),
        ],
        handoff: HandoffVM(title: "Up next · Trip overview",
                           subtitle: "Lisbon · 4 days, your shape.")
    )
    .padding(Spacing.screenInset)
    .environment(\.disablesOneShotMotion, true)
}
