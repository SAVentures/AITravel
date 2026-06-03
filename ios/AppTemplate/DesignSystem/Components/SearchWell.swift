// SearchWell.swift — the destination search field (05-components §5 / 05-forms; ports `.search` from
// mockups/screens/onboarding/state-a-screen-01-destination.html).
//
// A capsule the user types into: `[magnifier] [editable text field] [optional mono kbd hint]`.
//
// THE LOAD-BEARING DECISION (mockup `.search` caption — "a control well, not a card"): this is a FILL
// WELL, NEVER glass and NEVER a card (J-0.1 / J-8.1). Glass is reserved for floating chrome (the bars,
// the action floor); a control the user types inside the content column is a neutral `fillTertiary` well
// on the pill rung (J-10.2 — pill = a control). There is no bordered / shadowed / glass path to misuse.
//
// THIS IS A REAL EDITABLE FIELD: the well holds a live `TextField` bound to the caller's `text` — the
// user types the destination here. When `text` is empty the `TextField` shows the `placeholder` in the
// receded ink and the trailing mono `kbdHint` is shown; once typing begins the hint recedes so the value
// has the full width.
//
// Anatomy ported from the mockup `.search`:
//   • `fillTertiary` ground, `Radius.pill` shape (the mockup `--fill-tertiary` / `--r-pill`).
//   • a leading `magnifyingglass` glyph in the receded `textTertiary` ink (the mockup `--ink-400`).
//   • the value in body, primary ink (the mockup `--ink-900`); placeholder recedes to `textTertiary`.
//   • an optional trailing `kbd` hint in the MONO caption family, receded ink (the mockup `--font-mono`
//     `--ink-400`) — "return ↵" — shown only while the field is empty.
//
// Tokens only (J-0.2): semantic `ColorRole` / `Typography` / `Spacing` / `Radius` — zero literals, zero
// `Primitive.*`. Dynamic Type throughout: no fixed-pt fonts, no fixed frame; the 44pt+ floor is a
// `@ScaledMetric` so it grows with the body text style (J-0.3, T-6.4).
//
// Value-type args only (no AppStore, no domain object — 05 §8); the previews drive against `@State`.
import SwiftUI

/// The destination search field — a real, focusable `TextField` in a neutral fill pill, never glass
/// (J-0.1), never a card (J-8.1). Holds a magnifier, the editable value (or placeholder), and an optional
/// mono keyboard hint shown while empty.
struct SearchWell: View {
    /// The live search text. Bound to the caller; the field reads and writes it directly.
    @Binding var text: String
    /// The receded prompt shown when `text` is empty ("Search a city…").
    let placeholder: String
    /// The trailing mono keyboard hint, shown only while `text` is empty; `nil` hides it.
    let kbdHint: String?

    /// Field focus, OWNED BY THE CALLER. The screen drives this `@FocusState` so it can observe + control
    /// when the keyboard is up — switching into search-results mode and hiding the bottom CTA. The well
    /// treatment is the same focused or not (the mockup has no focus ring — it stays a neutral control);
    /// the binding exists for the screen's behavior, not for a visual change here.
    let focused: FocusState<Bool>.Binding

    /// The HIG minimum tap dimension — a floor; content + Dynamic Type still grow the well. `@ScaledMetric`
    /// scales it with the body text so it holds at large sizes (T-6.4); a bare `50` would not (J-0.3).
    @ScaledMetric(relativeTo: .body) private var minTapTarget: CGFloat = 50

    init(text: Binding<String>, placeholder: String, kbdHint: String? = "return ↵", focused: FocusState<Bool>.Binding) {
        self._text = text
        self.placeholder = placeholder
        self.kbdHint = kbdHint
        self.focused = focused
    }

    var body: some View {
        HStack(spacing: Spacing.paired) {
            // Leading magnifier — the search affordance, in the receded glyph ink (mockup --ink-400).
            // Scales with the body text style; no fixed pt (J-0.3).
            Image(systemName: "magnifyingglass")
                .font(Typography.body)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)

            // The live field — value in primary ink, placeholder receded. Takes the remaining width so
            // the kbd hint sits flush right (mockup `.val { flex: 1 }`).
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Typography.body)
                .foregroundStyle(ColorRole.textPrimary)
                .tint(ColorRole.actionPrimary)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused(focused)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Optional mono keyboard hint — receded, the smallest mono caption rung (mockup `.kbd`).
            // Shown only while empty so a typed value gets the full width.
            if let kbdHint, text.isEmpty {
                Text(kbdHint)
                    .font(Typography.caption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        // Horizontal card-inset (16) padding, vertical paired (8) — the mockup `padding: 0 16px` on a
        // 50pt well. No fixed frame (J-0.3); content + the min height drive the size.
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.paired)
        .frame(minHeight: minTapTarget)
        .background(ColorRole.fillTertiary, in: .capsule) // pill — a control well (J-10.2), never glass
        .contentShape(.capsule)
        // Tapping anywhere in the well focuses the field, not just the glyph-sized text rect.
        .onTapGesture { focused.wrappedValue = true }
        // VoiceOver reads this as a search field labelled "Search cities"; the placeholder/value is the
        // field's own spoken value, so we don't ignore children here.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Search cities"))
        .accessibilityAddTraits(.isSearchField)
        .accessibilityIdentifier("onboarding.search")
    }
}

// MARK: - Previews — one per meaningful state (05-design-system §8; snapshot in Wave 1)

#Preview("SearchWell — with value") {
    @Previewable @State var text = "Lisbon"
    @Previewable @FocusState var focused: Bool
    SearchWell(text: $text, placeholder: "Search a city…", focused: $focused)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage)
}

#Preview("SearchWell — placeholder only") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    SearchWell(text: $text, placeholder: "Search a city…", focused: $focused)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage)
}
