// GenerationProgressView.swift — the generate moment: the one continuous "heartbeat" sweep over a
// firming-up planning checklist, with a faint handoff peek (06-judgment J-9.3 / J-6.5; 04-motion §4;
// 07-testing.md §6.4).
//
// This is the ONE place in onboarding that owns continuous motion — a single neutral sweep across a 3pt
// track that `repeatForever` at `Motion.think` (1.7s), mirroring `LoadingSkeleton`'s shimmer discipline:
// at most one continuous motion (J-9.3), and it goes STATIC under BOTH Reduce Motion and the snapshot
// seam (`\.disablesOneShotMotion`) — never the only signal, the static checklist carries the state too
// (04-motion §4.3 / J-9.5). The sweep is additive neutral light, never a gradient FILL or text (08-slop
// C-1 / C-3).
//
// PORTS FROM: `mockups/screens/onboarding/state-a-screen-05-generate.html`
//   .think          a 3px `--ink-100` track with a `transparent → --ink-400 → transparent` band sweeping
//                   left→right, 35% width, `sweep 1700ms var(--ease-standard) infinite`
//                   → `ColorRole.fillSecondary` track + `Radius.pill` + `Motion.standard(Motion.think).repeatForever`
//   @media reduced  `.think::after { animation: none; left: 0; width: 100%; opacity: 0.4; }`
//                   → static 40%-opacity full bar under motion-disabled
//   .steps .s.done  solid `--ink-900` circle + check, `--ink-700` body
//                   → `ColorRole.textPrimary` disc + check glyph, `textSecondary` body
//   .steps .s.cur   a single blue ring (`--accent-500` disc with a `--paper-0` 5px inset = ring — the ONE
//                   accent), italic display body `--ink-900`
//                   → `ColorRole.stateNow` ring + `Typography.name.italic()` `textPrimary` body
//   .steps .s.todo  hollow 1.5px `--ink-200` ring, receded `--ink-400` body
//                   → `ColorRole.separatorOpaque` hollow ring, `textTertiary` body
//   .steps .s .m    mono sub-line (`5 clusters found`) `--ink-500`
//                   → `Typography.caption` mono, `textTertiary`
//   .handoff        faint (`opacity: 0.5`) `--paper-100` card, `--r-card`, mono caps eyebrow + italic
//                   display line — the next surface isn't drawn yet
//                   → `ColorRole.surfacePage` card at `Radius.card`, half opacity, non-interactive
//
// Exactly ONE accent on this view: the current step's `stateNow` ring (the CTA is absent on the generate
// screen, so this is the screen's single accent appearance — J-2.4). Selection / state is conveyed by
// fill + glyph + weight, never color alone (02-color §6). Value-type args only; no `AppStore`, no domain
// model (05-design-system.md §8). Semantic tokens only — zero literals / `Primitive.*` (J-0.2). Content,
// never glass (J-0.1).
import SwiftUI

// MARK: - Value-type args

/// One planning step in the generation checklist — a value-type fixture, no domain model (05 §8).
struct GenerationStepVM: Identifiable, Equatable, Hashable, Sendable {

    /// The step's status: firming up from `.pending` (hollow) → `.current` (the one blue ring + italic) →
    /// `.done` (solid ink + check). Enum over boolean soup (02 §3).
    enum Status: Equatable, Hashable, Sendable {
        case done
        case current
        case pending
    }

    let id: String
    /// The step body line (e.g. "Grouping your 23 places by neighborhood").
    let text: String
    /// An optional mono sub-line (e.g. "5 clusters found"). `nil` = no sub-line.
    let detail: String?
    let status: Status

    init(id: String, text: String, detail: String? = nil, status: Status) {
        self.id = id
        self.text = text
        self.detail = detail
        self.status = status
    }
}

/// The faint "up next" peek at the surface being drawn — a value-type fixture (05 §8).
struct HandoffVM: Equatable, Hashable, Sendable {
    /// The mono caps eyebrow (e.g. "Up next · Trip overview").
    let title: String
    /// The italic display line (e.g. "Lisbon · 4 days, your shape.").
    let subtitle: String
}

// MARK: - GenerationProgressView

/// The generate moment: a continuous heartbeat sweep above a firming-up checklist, with a faint handoff
/// peek. Screen-agnostic — takes value-type args, no `AppStore`, no domain object (05 §8).
struct GenerationProgressView: View {

    /// The planning steps, top→bottom; their `status` drives each row's register.
    let steps: [GenerationStepVM]
    /// The faint "up next" peek; `nil` omits it.
    let handoff: HandoffVM?

    init(steps: [GenerationStepVM], handoff: HandoffVM? = nil) {
        self.steps = steps
        self.handoff = handoff
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hero) {
            HeartbeatSweep()

            // The static checklist — never the only signal for the loop (04-motion §4.3): even with the
            // sweep parked, the firmed-up rows carry the state.
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

// MARK: - The one continuous motion: the heartbeat sweep (J-9.3 / J-6.5)

/// A 3pt neutral track with a single neutral band sweeping across it forever at `Motion.think` — the ONE
/// allowed continuous motion (J-9.3). Goes static under BOTH Reduce Motion and the snapshot seam, mirroring
/// `LoadingSkeleton` (04-motion §4.4 / J-9.5; 07-testing.md §6.4): a parked, 40%-opacity full bar.
private struct HeartbeatSweep: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.disablesOneShotMotion) private var disablesOneShotMotion

    /// Drives the single sweep. `false` parks the band off the leading edge (rest); `onAppear` flips it to
    /// start the repeat — only when motion is allowed.
    @State private var sweeping = false

    /// Static when EITHER the user has Reduce Motion on OR the snapshot seam disables it.
    private var motionDisabled: Bool { reduceMotion || disablesOneShotMotion }

    // The track height scales with Dynamic Type so the heartbeat keeps its weight at every text size
    // (T-6.4) — never a bare fixed CGFloat. Seeded from the mockup's 3px `.think` height.
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 3

    /// The fraction of the track the sweeping band occupies (mockup `width: 35%`).
    private let bandFraction: CGFloat = 0.35

    var body: some View {
        // The neutral track (`--ink-100` → the low neutral fill role).
        Capsule()
            .fill(ColorRole.fillSecondary)
            .frame(height: trackHeight)
            .frame(maxWidth: .infinity)
            .overlay { sweepBand }
            .clipShape(.capsule) // overflow: hidden — the band is clipped to the track
            .accessibilityHidden(true) // decorative; the checklist + container carry the state
            .onAppear {
                guard !motionDisabled else { return }
                withAnimation(Motion.standard(Motion.think).repeatForever(autoreverses: false)) {
                    sweeping = true
                }
            }
    }

    /// The single neutral band — `transparent → ink-400 → transparent`, additive light, never a fill or
    /// text (08-slop C-1 / C-3). When motion is disabled it never animates: a parked 40%-opacity full bar
    /// (the mockup's `@media reduced` rest frame), so the static state still reads as "working".
    private var sweepBand: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let bandWidth = width * bandFraction
            // Park fully off the leading edge at rest; sweep one band-width past the trailing edge.
            let offset = sweeping ? width : -bandWidth

            if motionDisabled {
                // Static rest frame: a full-width, 40%-opacity neutral bar — no animation, no band.
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

// MARK: - One checklist row, firming up (done / current / pending)

/// A single planning step row: a leading status glyph + the body line, optionally a mono sub-line. The
/// status drives the register — `.done` (solid ink + check, receded body), `.current` (the ONE blue ring +
/// italic display body — the screen's single accent), `.pending` (hollow ring, receded body).
private struct GenerationStepRow: View {

    let step: GenerationStepVM
    let index: Int

    // The status glyph scales with the body text (T-6.4) — the mockup's 20px `.gl`.
    @ScaledMetric(relativeTo: .body) private var glyphSize: CGFloat = 20

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.itemGap) {
            statusGlyph
                .frame(width: glyphSize, height: glyphSize)

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                bodyLine
                if let detail = step.detail {
                    Text(detail)
                        .font(Typography.caption) // mono sub-line (5 clusters found …)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("generation.step.\(index)")
        .accessibilityValue(accessibilityStatus)
    }

    /// The body line — italic display for the current step (the one editorial moment, reusing the AIVoice /
    /// `Typography.name.italic()` idiom), roman body otherwise. Ink by register: receded for done/pending,
    /// primary for the current step.
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

    /// The leading status glyph — solid ink disc + check (done), the one blue `stateNow` ring (current),
    /// or a hollow neutral ring (pending). State is conveyed by fill + glyph, never color alone (02 §6).
    @ViewBuilder private var statusGlyph: some View {
        switch step.status {
        case .done:
            // Solid ink disc + a paper check — definitive (J-8: certainty).
            Circle()
                .fill(ColorRole.textPrimary)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(ColorRole.textOnAccent)
                }
        case .current:
            // The ONE accent: a blue ring (a `stateNow` disc with a paper core punched out). The screen's
            // single accent appearance (J-2.4) — the CTA is absent on the generate moment.
            Circle()
                .fill(ColorRole.stateNow)
                .overlay {
                    Circle()
                        .fill(ColorRole.surfacePage)
                        .padding(glyphSize * 0.25)
                }
        case .pending:
            // Hollow neutral ring — fuzzy, recedes (J-8: low certainty, not yet drawn).
            Circle()
                .strokeBorder(ColorRole.separatorOpaque, lineWidth: ringWidth)
        }
    }

    // The pending ring's hairline weight scales with the glyph (mockup `1.5px`).
    @ScaledMetric(relativeTo: .body) private var ringWidth: CGFloat = 1.5

    private var accessibilityStatus: String {
        switch step.status {
        case .done: "done"
        case .current: "in progress"
        case .pending: "pending"
        }
    }
}

// MARK: - HandoffPeekCard — the faint "up next" peek

/// A faint, non-interactive peek at the surface being drawn next: a mono caps eyebrow above an italic
/// display line, on a quiet page card at half opacity (the next surface isn't drawn yet). Content, never
/// glass (J-0.1); value-type arg only (05 §8).
struct HandoffPeekCard: View {

    let handoff: HandoffVM

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            // Mono caps eyebrow (Up next · Trip overview) — caps tracking at the call site (T-5.2).
            Text(handoff.title)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .foregroundStyle(ColorRole.textTertiary)

            // The italic display line — reuses the AIVoice / `Typography.name.italic()` idiom.
            Text(handoff.subtitle)
                .font(Typography.name.italic())
                .foregroundStyle(ColorRole.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
        // Faint — the next surface isn't drawn yet (mockup `opacity: 0.5`).
        .opacity(0.5)
        // Non-interactive peek — it's a preview, not a control.
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("generation.handoff")
        .accessibilityLabel("\(handoff.title): \(handoff.subtitle)")
    }
}

// MARK: - Previews (settled — motion disabled per 07-testing.md §6.4)

#Preview("Generation — mid-progress") {
    // Settled: inject the snapshot seam so the heartbeat parks at rest (no mid-sweep frame), matching how
    // the L3 snapshot captures it (07-testing.md §6.4). Mid-generation: 3 done, 1 current, 2 pending.
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
    // Near-done: only the last step remains current. Settled (motion disabled).
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
