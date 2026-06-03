/*
 The destination search field — a real, focusable `TextField` in a fill pill. Ports `.search` from
 mockups/screens/onboarding/state-a-screen-01-destination.html:
 `[magnifier] [editable text field] [optional mono kbd hint]`.

 Load-bearing: this is a FILL WELL, never glass and never a card (J-0.1 / J-8.1) — glass is reserved
 for floating chrome; a control typed into inside the content column is a neutral `fillTertiary` pill
 (J-10.2). The mono `kbdHint` shows only while empty so a typed value gets the full width.
*/
import SwiftUI

struct SearchWell: View {
    @Binding var text: String
    let placeholder: String
    let kbdHint: String?

    /* Focus owned by the CALLER: the screen drives this `@FocusState` to switch into search-results
       mode and hide the bottom CTA. The well treatment is identical focused or not. */
    let focused: FocusState<Bool>.Binding

    // A floor, not a fixed size; `@ScaledMetric` grows it with the body text so it holds at AX sizes.
    @ScaledMetric(relativeTo: .body) private var minTapTarget: CGFloat = 50

    init(text: Binding<String>, placeholder: String, kbdHint: String? = "return ↵", focused: FocusState<Bool>.Binding) {
        self._text = text
        self.placeholder = placeholder
        self.kbdHint = kbdHint
        self.focused = focused
    }

    var body: some View {
        HStack(spacing: Spacing.paired) {
            Image(systemName: "magnifyingglass")
                .font(Typography.body)
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)

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

            // Shown only while empty so a typed value gets the full width.
            if let kbdHint, text.isEmpty {
                Text(kbdHint)
                    .font(Typography.caption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.paired)
        .frame(minHeight: minTapTarget)
        .background(ColorRole.fillTertiary, in: .capsule) // pill — a control well (J-10.2), never glass
        .contentShape(.capsule)
        // Tapping anywhere in the well focuses the field, not just the glyph-sized text rect.
        .onTapGesture { focused.wrappedValue = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Search cities"))
        .accessibilityAddTraits(.isSearchField)
        .accessibilityIdentifier("onboarding.search")
    }
}

// MARK: - Previews

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
