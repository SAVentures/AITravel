/*
 The −/value/+ day stepper. Ports `.stepper` from mockups/screens/onboarding/state-{a,c}-screen-02-trip-shape.html.
 CONTENT, never glass (J-0.1): plain ± glyph buttons on a solid well. The value is one adjustable
 element (VoiceOver swipe); the discrete ± buttons keep their own ids for the XCUITest path.
*/
import SwiftUI

/// A `−`/value/`+` stepper for a small integer. The caller owns the value and applies the new one in `onChange`.
struct DayStepper: View {

    let value: Int
    let range: ClosedRange<Int>
    let unit: String

    /// Fired with the new (already-clamped) value. Not called when at a bound.
    let onChange: (Int) -> Void

    /// HIG tap-target floor that grows with Dynamic Type — a bare literal would not scale (T-6.4).
    @ScaledMetric(relativeTo: .title2) private var buttonHitTarget: CGFloat = Sizing.minTapTarget

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
        .padding(Spacing.xs)
        .background(ColorRole.fillSecondary, in: .capsule)
        // One adjustable element so VoiceOver swipes change the count; the discrete buttons stay tappable.
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

    private var valueFace: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            // Reserve the widest value's width (monospacedDigit alone only steadies same-digit-count
            // values — 9→10 still grows a glyph and shifts the ± buttons). A hidden sizer holds the slot;
            // the live value renders inside it, so the capsule width is constant across the whole range.
            Text(String(range.upperBound))
                .font(Typography.title)
                .tracking(Typography.titleTracking)
                .monospacedDigit()
                .hidden()
                .overlay {
                    Text("\(clamped)")
                        .font(Typography.title)
                        .tracking(Typography.titleTracking)
                        .monospacedDigit() // tabular numerals so the width is steady across values (J-7.2)
                        .foregroundStyle(ColorRole.textPrimary)
                }
            Text(unit)
                .font(Typography.footnote) // mono — the unit reads as measurement (T-1.2)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        // The value is announced by the container's `.accessibilityValue`; hide the raw text so it isn't read twice.
        .accessibilityHidden(true)
    }

    // MARK: - A circular plain glyph button

    private func glyphButton(
        systemImage: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Typography.subhead.weight(.semibold))
                .frame(width: buttonHitTarget, height: buttonHitTarget)
                .contentShape(.circle)
        }
        .buttonStyle(DayStepperGlyphButtonStyle()) // plain content button — NOT `.glass` (J-0.1)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: - The glyph button style

/// The ± button's treatment. On press the glyph picks up a faint `surfacePage` disc (the press commits in
/// ≤100ms before the release animation — J-9.1).
private struct DayStepperGlyphButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? ColorRole.textPrimary : ColorRole.textTertiary)
            .background(
                Circle()
                    .fill(ColorRole.surfacePage)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("DayStepper — mid-range") {
    StatefulPreviewWrapper(4) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("DayStepper — at min") {
    StatefulPreviewWrapper(1) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

#Preview("DayStepper — at max") {
    StatefulPreviewWrapper(14) { value in
        DayStepper(value: value.wrappedValue, range: 1...14) { value.wrappedValue = $0 }
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}

/// A tiny `@State` host so the previews are live (the ± buttons move the number) without a domain store.
private struct StatefulPreviewWrapper<Content: View>: View {
    @State private var value: Int
    private let content: (Binding<Int>) -> Content

    init(_ initial: Int, @ViewBuilder content: @escaping (Binding<Int>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
