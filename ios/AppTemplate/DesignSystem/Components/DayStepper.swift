// DayStepper.swift — the −/value/+ day stepper (W1-03; ports `.stepper` from
// mockups/screens/onboarding/state-a-screen-02-trip-shape.html (inline, in card A) and
// state-c-screen-02-trip-shape.html (standalone, in the taste form)).
//
// A compact control that names a trip length: a `−` glyph button, a display-face number with a mono unit
// ("days"), and a `+` glyph button — all on a single neutral well pill. The number is the DISPLAY face
// (Schibsted Grotesk, semibold, `Typography.title`-ish) so the count reads as the value; the unit is MONO
// (`Typography.footnote`) so it reads as measurement, vertically aligned (J-7.2 / T-1.2). The mockup maps
// the number to `--font-display` bold on `--ink-900` (→ `textPrimary`) and the unit to `--font-mono` on
// `--ink-600` (→ `textSecondary`), on a `--paper-200` well (→ `fillSecondary`).
//
// ── This is CONTENT, never glass (J-0.1) ──────────────────────────────────────────────────────────────
// The ± buttons are plain glyph buttons on a solid neutral well, NOT `.glass` — a stepper is content the
// user operates, not floating chrome. Only the bar/ActionBar layer is glass (05-components §3.3); the
// single glass component is `GlassCircleButton` (a bar glyph). These buttons are `.plain`.
//
// ── Clamp to range; disable at bounds ─────────────────────────────────────────────────────────────────
// The value is clamped into `range`; `−` is disabled at `range.lowerBound` and `+` at `range.upperBound`
// (a disabled glyph drops to `textTertiary` via the environment, never a hand-dimmed color). `onChange`
// fires only when the value actually moves.
//
// ── Accessibility: one adjustable element, plus discrete ids ──────────────────────────────────────────
// The value reads as a single adjustable element (`.adjustable` trait + increment/decrement actions) with
// `.accessibilityValue("\(n) days")`, so VoiceOver users swipe up/down to change it. The discrete `−`/`+`
// buttons keep their own ids (`daystepper.decrement` / `daystepper.increment`) for the XCUITest path, and
// `daystepper.value` carries the count.
//
// Semantic tokens only — zero literals, zero `Primitive.*` (J-0.2). Each ± button keeps a 44pt minimum hit
// target via `@ScaledMetric` (never a fixed CGFloat — T-6.4); the number scales with Dynamic Type (J-0.3).
import SwiftUI

/// A `−`/value/`+` stepper for a small integer (a trip's day count). Display-face number + mono unit on a
/// neutral well pill; the ± buttons clamp to `range` and disable at the bounds.
///
/// Data in as value-type args only — no `AppStore`, no domain object (05-design-system §8). The caller owns
/// the value and applies the new one in `onChange`.
struct DayStepper: View {

    /// The current count. Rendered clamped into `range`; the caller stores whatever `onChange` hands back.
    let value: Int

    /// The inclusive range the value is clamped to. `−` disables at `lowerBound`, `+` at `upperBound`.
    let range: ClosedRange<Int>

    /// The unit shown after the number, in mono ("days"). A short noun — never running prose.
    let unit: String

    /// Fired with the new (already-clamped) value when the user steps. Not called when at a bound.
    let onChange: (Int) -> Void

    /// The HIG-minimum 44pt tap target for each ± button — a floor that grows with Dynamic Type so the
    /// touch area holds at large text sizes (T-6.4); a bare `44` would not scale (J-0.3).
    @ScaledMetric(relativeTo: .title2) private var buttonHitTarget: CGFloat = 44

    init(
        value: Int,
        range: ClosedRange<Int>,
        unit: String = "days",
        onChange: @escaping (Int) -> Void
    ) {
        self.value = value
        self.range = range
        self.unit = unit
        self.onChange = onChange
    }

    /// The value clamped into range — what the view actually renders and reasons about for the bounds.
    private var clamped: Int { min(max(value, range.lowerBound), range.upperBound) }

    private var canDecrement: Bool { clamped > range.lowerBound }
    private var canIncrement: Bool { clamped < range.upperBound }

    private func step(by delta: Int) {
        let next = min(max(clamped + delta, range.lowerBound), range.upperBound)
        guard next != clamped else { return }
        onChange(next)
    }

    var body: some View {
        HStack(spacing: 0) {
            glyphButton(systemImage: "minus", label: "Fewer days", enabled: canDecrement) {
                step(by: -1)
            }
            .accessibilityIdentifier("daystepper.decrement")

            valueFace
                .accessibilityIdentifier("daystepper.value")

            glyphButton(systemImage: "plus", label: "More days", enabled: canIncrement) {
                step(by: 1)
            }
            .accessibilityIdentifier("daystepper.increment")
        }
        // The internal padding that sets the well around the ± buttons (the mockup's 3–4px ring); the well
        // hugs its content, never a fixed width (J-0.3).
        .padding(Spacing.hairline)
        .background(ColorRole.fillSecondary, in: .capsule) // neutral well, pill shape (J-10.2)
        // One adjustable element so VoiceOver swipes change the count; the discrete buttons stay tappable
        // for the XCUITest path. The value text below carries the spoken "\(n) days".
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(clamped) \(unit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(by: 1)
            case .decrement: step(by: -1)
            @unknown default: break
            }
        }
    }

    // MARK: - The display-number + mono-unit face

    /// `[display number] [mono unit]`, baseline-aligned. The number is the display face (semibold,
    /// `Typography.title`) with tabular figures so it doesn't jitter as it changes (J-7.2); the unit is
    /// mono `footnote` in `textSecondary` (measurement, not the value). The hairline rung (4pt) sits
    /// between them — the mockup's ~4–5px number↔unit gap (J-1).
    private var valueFace: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.hairline) {
            Text("\(clamped)")
                .font(Typography.title)
                .tracking(Typography.titleTracking)
                .monospacedDigit() // tabular numerals so the width is steady across values (J-7.2 / T-1.2)
                .foregroundStyle(ColorRole.textPrimary)
            Text(unit)
                .font(Typography.footnote) // mono — the unit reads as measurement (T-1.2)
                .foregroundStyle(ColorRole.textSecondary)
        }
        // Breathing room either side of the value, between the two glyph buttons (the mockup's `.v`
        // horizontal padding). Sibling rung — the value is the content between the controls.
        .padding(.horizontal, Spacing.itemGap)
        // The value is announced by the container's `.accessibilityValue`; hide the raw text so VoiceOver
        // doesn't read "4 days" twice.
        .accessibilityHidden(true)
    }

    // MARK: - A circular plain glyph button (content, never glass — J-0.1)

    /// A `−`/`+` glyph as a circular plain button with a 44pt hit target. Disabled (at a bound) the glyph
    /// recedes to `textTertiary` via the environment — never a hand-dimmed color (05-components intro).
    private func glyphButton(
        systemImage: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Typography.subhead.weight(.semibold)) // a small, even-weight glyph; scales with text
                .frame(width: buttonHitTarget, height: buttonHitTarget)
                .contentShape(.circle)
        }
        .buttonStyle(DayStepperGlyphButtonStyle()) // plain content button — NOT `.glass` (J-0.1)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: - The glyph button style (press · disabled · circular content fill)

/// The ± button's treatment, driven by `configuration.isPressed` so the press commits in ≤100ms before the
/// release animation (J-9.1). On press the glyph picks up a faint `surfacePage` disc (the mockup's
/// `button:hover { background: var(--paper-0) }`). Reads `.isEnabled` for the disabled register; all values
/// are semantic tokens. Content, never glass (J-0.1).
private struct DayStepperGlyphButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? ColorRole.textPrimary : ColorRole.textTertiary)
            // The pressed disc — a subtle lift on the neutral well, the mockup's hover affordance.
            .background(
                Circle()
                    .fill(ColorRole.surfacePage)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Previews — one per meaningful state (05-design-system §8; snapshot matrix Wave 1)

#Preview("DayStepper — mid-range") {
    StatefulPreviewWrapper(4) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}

#Preview("DayStepper — at min") {
    StatefulPreviewWrapper(1) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}

#Preview("DayStepper — at max") {
    StatefulPreviewWrapper(14) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.cardInset)
    .background(ColorRole.surfacePage)
}

/// A tiny `@State` host so the previews are live (the ± buttons move the number) without a domain store —
/// no `AppStore`, no domain object (05-design-system §8).
private struct StatefulPreviewWrapper<Content: View>: View {
    @State private var value: Int
    private let content: (Binding<Int>) -> Content

    init(_ initial: Int, @ViewBuilder content: @escaping (Binding<Int>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
