// SearchWell.swift — the destination control well (05-components §5 / 05-forms; ports `.search` from
// mockups/screens/onboarding/state-a-screen-01-destination.html).
//
// A capsule the user taps to focus the destination: `[magnifier] [value text] [optional mono kbd hint]`.
//
// THE LOAD-BEARING DECISION (mockup `.search` caption — "a control well, not a card"): this is a FILL
// WELL, NEVER glass and NEVER a card (J-0.1 / J-8.1). Glass is reserved for floating chrome (the bars,
// the action floor); a control the user taps inside the content column is a neutral `fillTertiary` well
// on the pill rung (J-10.2 — pill = a control). There is no bordered / shadowed / glass path to misuse.
//
// THIS MILESTONE IS DISPLAY + TAP-TO-FOCUS (plan W1-05): the well shows a read-only `value` and reports
// `onTap` — the city is chosen from the tiles below, so there is NO live `TextField` here. When `value`
// is empty the well shows the `placeholder` in the receded ink, matching the static mockup.
//
// Anatomy ported from the mockup `.search`:
//   • `fillTertiary` ground, `Radius.pill` shape (the mockup `--fill-tertiary` / `--r-pill`).
//   • a leading `magnifyingglass` glyph in the receded `textTertiary` ink (the mockup `--ink-400`).
//   • the value `.val` in semibold body, primary ink (the mockup `font-weight: 600` / `--ink-900`).
//   • an optional trailing `kbd` hint in the MONO caption family, receded ink (the mockup `--font-mono`
//     `--ink-400`) — "return ↵".
//
// Tokens only (J-0.2): semantic `ColorRole` / `Typography` / `Spacing` / `Radius` — zero literals, zero
// `Primitive.*`. The glyph + kbd are non-text-paired so the well still reads as "search Lisbon, return"
// to VoiceOver via the combined value below.
//
// Value-type args only (no AppStore, no domain object — 05 §8); the previews drive against literals.
import SwiftUI

/// The destination search well — read-only display + tap-to-focus. A neutral fill pill, never glass
/// (J-0.1), never a card (J-8.1). Holds a magnifier, the chosen value (or placeholder), and an optional
/// mono keyboard hint. The press commits in ≤100ms before any animation (J-9.1) via the `ButtonStyle`.
struct SearchWell: View {
    /// The chosen destination, shown read-only. Empty → the `placeholder` shows in the receded ink.
    let value: String
    /// The receded prompt shown when `value` is empty ("Search a city…").
    let placeholder: String
    /// The trailing mono keyboard hint; `nil` hides it. Defaults to the mockup's "return ↵".
    let kbdHint: String?
    /// Tap → the caller focuses the field / scrolls to the tiles. No live entry in this milestone.
    let onTap: () -> Void

    init(
        value: String,
        placeholder: String,
        kbdHint: String? = "return ↵",
        onTap: @escaping () -> Void
    ) {
        self.value = value
        self.placeholder = placeholder
        self.kbdHint = kbdHint
        self.onTap = onTap
    }

    /// Whether the well is showing the chosen value or the receded prompt — drives the value ink so a
    /// placeholder reads as the past/placeholder role (J-2, textTertiary), never an active primary ink.
    private var isFilled: Bool { !value.isEmpty }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.paired) {
                // Leading magnifier — the search affordance, in the receded glyph ink (mockup --ink-400).
                // Scales with the body text style; no fixed pt (J-0.3).
                Image(systemName: "magnifyingglass")
                    .font(Typography.body)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)

                // The value (or placeholder). Semibold so the chosen city carries weight on the neutral
                // well (the mockup `.val` font-weight: 600); takes the remaining width so the kbd hint
                // sits flush right (mockup `.val { flex: 1 }`).
                Text(isFilled ? value : placeholder)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(isFilled ? ColorRole.textPrimary : ColorRole.textTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)

                // Optional mono keyboard hint — receded, the smallest mono caption rung (mockup `.kbd`).
                if let kbdHint {
                    Text(kbdHint)
                        .font(Typography.caption)
                        .foregroundStyle(ColorRole.textTertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(SearchWellButtonStyle())
        // One combined element: VoiceOver reads "Search, <value>" with the search trait, not three
        // disconnected glyphs (02-color §6 — never a glyph alone). The value is the spoken value.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Search"))
        .accessibilityValue(Text(isFilled ? value : placeholder))
        .accessibilityAddTraits(.isSearchField)
        .accessibilityIdentifier("onboarding.search")
    }
}

// MARK: - Well style (fill · pill · press · 44pt target)

/// The well's capsule treatment: a neutral `fillTertiary` ground on the pill rung, with the press
/// committing in ≤100ms before the release animation (J-9.1). NEVER glass — the well is content the user
/// taps, not floating chrome (J-0.1). All values are semantic tokens.
private struct SearchWellButtonStyle: ButtonStyle {
    /// The HIG minimum tap dimension — a floor; content + Dynamic Type still grow the well. `@ScaledMetric`
    /// scales it with the body text so it holds at large sizes (T-6.4); a bare `50` would not (J-0.3).
    @ScaledMetric(relativeTo: .body) private var minTapTarget: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Horizontal card-inset (16) padding, vertical paired (8) — the mockup `padding: 0 16px` on a
            // 50pt well. No fixed frame (J-0.3); content + the min height drive the size.
            .padding(.horizontal, Spacing.cardInset)
            .padding(.vertical, Spacing.paired)
            .frame(minHeight: minTapTarget)
            .background(ColorRole.fillTertiary, in: .capsule) // pill — a control well (J-10.2)
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
    }
}

// MARK: - Previews — one per meaningful state (05-design-system §8; snapshot in Wave 1)

#Preview("SearchWell — with value") {
    SearchWell(value: "Lisbon", placeholder: "Search a city…", onTap: {})
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage)
}

#Preview("SearchWell — placeholder only") {
    SearchWell(value: "", placeholder: "Search a city…", onTap: {})
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage)
}
