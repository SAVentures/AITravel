// OnboardingProgressHeader.swift — a COMPOSITION primitive: the sticky glass header for the immersive
// onboarding takeover (06-screens §2.3 top bar = back/close only; J-0.1/J-2.4/J-8.3).
//
// Ports the mockup `screen-shell.css` `.ob-header` / `.ob-topbar` / `.ob-progress` / `.ob-counter`. The
// header is the screen's ONE piece of floating chrome — a sticky frosted bar — so `glassChrome()` IS
// allowed here (J-0.1: glass on floating chrome only). It carries two rows:
//
//   1. a 3-column top bar `[leading glyph] [spacer] [NN / 05 mono counter]` — close or back ONLY, never a
//      primary action (06-screens §2.3; primaries live in the thumb-zone floor); and
//   2. a 5-segment NEUTRAL progress bar below — todo / done / cur drawn in INK, never the accent. The blue
//      budget (J-2.4: ≤ 2 appearances) is reserved for the CTA + the one AI/now mark, so the chrome stays
//      neutral (shell-css comment: "neutral progress — NO accent").
//
// ── Glass-on-glass demotion (J-8.3) ───────────────────────────────────────────────────────────────────
// The contract says reuse `GlassCircleButton` for the leading glyph. But the header itself is glass
// (`glassChrome()`), and `GlassCircleButton` carries its OWN `.buttonStyle(.glass)` — nesting the two
// would stack glass on glass (J-8.3, "two translucent layers read as dishwater"). `GlassCircleButton`'s
// own contract says exactly this: when it sits inside an already-glass bar it is DEMOTED to a plain glyph
// button by the host. The host has no glass-drop parameter to pass, and the mockup `.ob-iconbtn` is itself
// a plain `fill-tertiary` circle (NOT glass) — so the leading glyph is rendered here as the demoted plain
// form: a `fillTertiary` circle with an ink glyph, matching both J-8.3 and the mockup.
//
// Semantic tokens only — no literal, no `Primitive.*` (J-0.2). The segment height + glyph hit target scale
// with Dynamic Type via `@ScaledMetric` (never a fixed CGFloat — J-0.3).
import SwiftUI

/// The leading glyph the onboarding header shows — a close (×) on the first step, a back chevron after.
///
/// Conveys the one navigation affordance the top bar carries (06-screens §2.3): dismiss the flow, or step
/// back. Each case maps to its SF Symbol + its accessibility identifier + role label.
enum LeadingGlyph {
    /// Dismiss the whole flow (step 0) — `xmark`.
    case close
    /// Step back to the previous step — `chevron.left`.
    case back

    /// The SF Symbol for the glyph (mockup `.ob-iconbtn svg`).
    fileprivate var systemImage: String {
        switch self {
        case .close: "xmark"
        case .back: "chevron.left"
        }
    }

    /// The dot-namespaced accessibility identifier, by case.
    fileprivate var accessibilityID: String {
        switch self {
        case .close: "onboarding.close"
        case .back: "onboarding.back"
        }
    }

    /// A short verb/role label for assistive tech (the glyph carries no text).
    fileprivate var accessibilityLabel: String {
        switch self {
        case .close: "Close"
        case .back: "Back"
        }
    }
}

/// A sticky frosted-glass header for the immersive onboarding flow: a back/close glyph + a mono `NN / 05`
/// step counter, over a 5-segment neutral progress bar.
///
/// Data in as value-type args only — no `AppStore`, no domain object (05-design-system §8). This is
/// floating chrome, so it carries the system Liquid Glass material (`glassChrome()`, J-0.1); the progress
/// bar is strictly neutral ink so the accent budget (J-2.4) is left to the CTA + the one AI/now mark.
struct OnboardingProgressHeader: View {

    /// The current step, 0-based (0–4). Segments at or before this index read as `done`/`cur`.
    let stepIndex: Int

    /// The total number of steps (the progress bar segment count + the counter denominator). Default 5.
    let totalSteps: Int

    /// Which leading glyph the top bar shows — `.close` on the first step, `.back` after.
    let leadingGlyph: LeadingGlyph

    /// The tap action for the leading glyph (dismiss / step back).
    let leadingAction: () -> Void

    /// The neutral progress segment height (~4pt base, mockup `.ob-seg height: 4px`), scaled with Dynamic
    /// Type so the bar grows with the user's text size rather than staying a fixed point value (J-0.3).
    @ScaledMetric(relativeTo: .caption) private var segmentHeight: CGFloat = 4

    /// The leading glyph's 44×44pt minimum hit target — the HIG floor — scaled with Dynamic Type (J-0.3).
    @ScaledMetric(relativeTo: .body) private var glyphHitTarget: CGFloat = 44

    init(
        stepIndex: Int,
        totalSteps: Int = 5,
        leadingGlyph: LeadingGlyph,
        leadingAction: @escaping () -> Void
    ) {
        self.stepIndex = stepIndex
        self.totalSteps = totalSteps
        self.leadingGlyph = leadingGlyph
        self.leadingAction = leadingAction
    }

    /// The 1-based step for the counter + the accessibility value (mockup `.ob-counter` reads `NN / 05`).
    private var displayStep: Int { min(stepIndex, totalSteps - 1) + 1 }

    var body: some View {
        VStack(spacing: Spacing.itemGap) {
            topBar
            progressBar
        }
        .padding(.horizontal, Spacing.screenInset)
        .padding(.vertical, Spacing.cardInset)
        // The ONE piece of floating chrome on the immersive flow → the system Liquid Glass material
        // (J-0.1). No hand-rolled translucency — the system computes the frost (mockup `.ob-header`).
        .glassChrome()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityValue("Step \(displayStep) of \(totalSteps)")
    }

    // MARK: - Top bar — `[leading glyph] [spacer] [NN / 05 counter]` (mockup `.ob-topbar`)

    private var topBar: some View {
        HStack(spacing: Spacing.paired) {
            leadingButton
            Spacer(minLength: Spacing.paired)
            counter
        }
    }

    /// The leading glyph — DEMOTED from `GlassCircleButton` to a plain `fillTertiary` glyph button because
    /// it sits inside the glass header (no glass-on-glass, J-8.3; matches the mockup's plain `.ob-iconbtn`).
    private var leadingButton: some View {
        Button(action: leadingAction) {
            Image(systemName: leadingGlyph.systemImage)
                .imageScale(.medium)
                .foregroundStyle(ColorRole.textPrimary)
                .frame(width: glyphHitTarget, height: glyphHitTarget)
                .background(ColorRole.fillTertiary, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(leadingGlyph.accessibilityLabel)
        .accessibilityIdentifier(leadingGlyph.accessibilityID)
    }

    /// The mono `NN / 05` step counter (mockup `.ob-counter`): tabular caps mono, the current step in the
    /// strong ink (`textPrimary`), the rest in the receded `textTertiary`.
    private var counter: some View {
        (
            Text(stepLabel(displayStep))
                .foregroundStyle(ColorRole.textPrimary)
            + Text(" / ")
                .foregroundStyle(ColorRole.textTertiary)
            + Text(stepLabel(totalSteps))
                .foregroundStyle(ColorRole.textTertiary)
        )
        .font(Typography.caption)
        .tracking(Typography.trackEyebrowCaption)
        .monospacedDigit()
        .accessibilityHidden(true)
    }

    /// Two-digit zero-padded mono step label (`1` → `01`, mockup reads `01 / 05`).
    private func stepLabel(_ n: Int) -> String {
        String(format: "%02d", n)
    }

    // MARK: - Progress — 5 NEUTRAL segments (mockup `.ob-progress`; J-2.4 no accent in chrome)

    private var progressBar: some View {
        HStack(spacing: Spacing.paired) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(segmentColor(at: index))
                    .frame(height: segmentHeight)
            }
        }
    }

    /// The segment ink, strictly neutral (NO accent — the blue budget is the CTA's, J-2.4). Mirrors the
    /// mockup's ramp: `cur` = the darkest ink (`textPrimary`), `done` = a darker neutral (`textTertiary`),
    /// `todo` = the lighter neutral (`separatorOpaque`).
    private func segmentColor(at index: Int) -> Color {
        if index == stepIndex {
            ColorRole.textPrimary          // cur — mockup `.ob-seg.cur` (ink-900)
        } else if index < stepIndex {
            ColorRole.textTertiary         // done — mockup `.ob-seg.done` (darker neutral)
        } else {
            ColorRole.separatorOpaque      // todo — mockup `.ob-seg` (lighter neutral)
        }
    }
}

// MARK: - Previews

#Preview("Step 1 · close") {
    VStack {
        OnboardingProgressHeader(
            stepIndex: 0,
            leadingGlyph: .close,
            leadingAction: {}
        )
        Spacer()
    }
    .background(ColorRole.surfacePage)
}

#Preview("Step 3 · back") {
    VStack {
        OnboardingProgressHeader(
            stepIndex: 2,
            leadingGlyph: .back,
            leadingAction: {}
        )
        Spacer()
    }
    .background(ColorRole.surfacePage)
}
