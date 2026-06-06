// CategoryChip.swift — the read-only tinted category label for a saved place (Saved slice).
// Ports the mockup `.pl .pl-cat` / `.pd-kicker .pl-cat` (saved-shell.css): a `Radius.tag` capsule, a
// short MONO caps label (`Typography.caption`, caps tracking — T-5.2) inked with the category's mark
// colour, on the matching low-alpha `categoryTint` ground (the mockup's `.cat-*` background ~13% of the
// mark). This is NOT interactive — no Button (distinct from `FilterChip`); it is a content label.
// The category is conveyed by the TEXT (`displayLabel`), never colour alone (02-color §6); colour +
// label ride one VoiceOver stop (`.combine`). Content, never glass (J-0.1); content-hugging (J-0.3).
// No accent — categories use the day-mark hues via `categoryTint`/`categoryMark`, not `actionPrimary`
// (J-0.4). Value-type arg only (05 §8). Mirrors `Tag.swift`.
import SwiftUI

struct CategoryChip: View {

    private let category: PlaceCategory

    init(_ category: PlaceCategory) {
        self.category = category
    }

    var body: some View {
        Text(category.displayLabel.uppercased())
            .font(Typography.caption)
            .tracking(Typography.trackCapsCaption)
            // The label is inked with the category's mark colour — the second cue is the text itself
            // (`displayLabel`), so the category survives grayscale / colour-blindness (02-color §6).
            .foregroundStyle(ColorRole.categoryMark(category))
            // Content-hugging capsule — the mockup `.pl-cat` `padding: 3px 7px` (J-0.3; content sizes it).
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            // The low-alpha category tint behind a ≤ chip-scale label — a tint, never a card fill (J-2).
            .background(ColorRole.categoryTint(category), in: .rect(cornerRadius: Radius.tag))
            // One stop: the tint + label read as a single labelled element (the category as text).
            .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("CategoryChip — Eat / Drink / Stay / Do / Shop") {
    HStack(spacing: Spacing.sm) {
        ForEach(PlaceCategory.allCases, id: \.self) { category in
            CategoryChip(category)
        }
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
