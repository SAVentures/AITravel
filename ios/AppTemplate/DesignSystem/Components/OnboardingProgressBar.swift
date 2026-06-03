// OnboardingProgressBar.swift — an IN-CONTENT component: the onboarding step progress indicator
// (05-components §3; 02-color §2; J-0.2/J-0.3/J-2.4).
//
// Ports the mockup `.ob-progress` / `.ob-seg` / `.ob-counter` (mockups/screens/onboarding/screen-shell.css)
// — the 5-segment NEUTRAL progress bar + the mono `NN / 05` step counter. Previously these lived in the
// sticky GLASS `OnboardingProgressHeader`; they are now PLAIN IN-CONTENT content that scrolls with the
// step (the leading × is a separate floating `GlassCircleButton` the screens overlay themselves).
//
// ── NO glass, NO × button — this is resting content, not chrome ───────────────────────────────────────
// A `Components/` view is content on a solid surface and never touches glass (J-0.1, 05-components §3.3).
// This bar is exactly that: it paints neutral ink segments + a mono counter, with no `glassChrome()`, no
// `glassEffect`, and no navigation glyph. The dismiss affordance is the screen's floating chrome, not here.
//
// ── Strictly neutral ink — the accent budget is the CTA's (J-2.4) ─────────────────────────────────────
// The segment ramp is drawn in INK only (never the accent): the blue budget (≤ 2 appearances) is reserved
// for the CTA + the one AI/now mark, so the progress stays neutral (shell-css comment: "neutral progress").
//
// Semantic tokens only — no literal, no `Primitive.*` (J-0.2). The segment height scales with Dynamic Type
// via `@ScaledMetric` (never a fixed CGFloat — J-0.3).
import SwiftUI

/// The onboarding step progress indicator: a row of 5 neutral progress segments followed by a mono
/// `NN / 05` step counter.
///
/// Data in as value-type args only — no `AppStore`, no domain object (05-design-system §8). Plain
/// in-content content (NO glass, NO close button); the dismiss affordance is a separate floating
/// `GlassCircleButton` the screen overlays.
struct OnboardingProgressBar: View {

    /// The current step, 0-based (0–4). Segments at or before this index read as `done`/`cur`.
    let stepIndex: Int

    /// The total number of steps (the segment count + the counter denominator). Default 5.
    var totalSteps: Int = 5

    /// The neutral progress segment height (~4pt base, mockup `.ob-seg height: 4px`), scaled with Dynamic
    /// Type so the bar grows with the user's text size rather than staying a fixed point value (J-0.3).
    @ScaledMetric(relativeTo: .caption) private var segmentHeight: CGFloat = 4

    /// The 1-based step for the counter + the accessibility value (mockup `.ob-counter` reads `NN / 05`).
    private var displayStep: Int { min(stepIndex, totalSteps - 1) + 1 }

    var body: some View {
        HStack(spacing: Spacing.paired) {
            progressSegments
            counter
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityValue("Step \(stepIndex + 1) of \(totalSteps)")
    }

    // MARK: - Progress — 5 NEUTRAL segments (mockup `.ob-progress`; J-2.4 no accent in chrome)

    private var progressSegments: some View {
        HStack(spacing: Spacing.paired) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(segmentColor(at: index))
                    .frame(height: segmentHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// The segment ink, strictly neutral (NO accent — the blue budget is the CTA's, J-2.4). Mirrors the
    /// mockup ramp: `cur` = the darkest ink (`textPrimary`/ink-900), `done` = a darker neutral
    /// (`textTertiary`/ink-300), `todo` = the lighter neutral (`separatorOpaque`/ink-100).
    private func segmentColor(at index: Int) -> Color {
        if index == stepIndex {
            ColorRole.textPrimary          // cur — mockup `.ob-seg.cur` (ink-900)
        } else if index < stepIndex {
            ColorRole.textTertiary         // done — mockup `.ob-seg.done` (darker neutral)
        } else {
            ColorRole.separatorOpaque      // todo — mockup `.ob-seg` (lighter neutral)
        }
    }

    // MARK: - Counter — mono `NN / 05` (mockup `.ob-counter`)

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
}

// MARK: - Previews

#Preview("Step 1 of 5") {
    OnboardingProgressBar(stepIndex: 0)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("Step 3 of 5") {
    OnboardingProgressBar(stepIndex: 2)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("Step 5 of 5") {
    OnboardingProgressBar(stepIndex: 4)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
