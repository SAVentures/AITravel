// PlaceInfoGrid.swift — the place-detail facts grid (05-design-system.md §8; 05-components §3; J-8).
// Ports the place-detail mockup `.info-grid`: a three-cell facts row (Hours · Price · Cuisine), each cell
// a mono-caps key, a display value, and an optional secondary sub-line. The single-row mockup is a plain
// `HStack` of three equal cells with a hairline `Divider` (`mockup gap: 1px; background: var(--separator)`)
// between them, the whole clipped to `Radius.card`.
//
// NB: the design system already owns a `Grid` sizing namespace (`Grid.x(n)`, Tokens/Sizing.swift), so an
// unqualified `Grid { }` resolves to THAT, not SwiftUI's layout container. The HStack sidesteps the
// collision and matches the mockup's single row exactly (no 2D grid needed).
//
// CONTENT surface, so NEVER glass (J-0.1 / J-8). Dynamic-Type-safe: each cell GROWS (no fixed frame, text
// wraps) so the row never clips at large type (J-0.3, 08-slop D-7). The value carries `.monospacedDigit()`
// so numeric facts (prices, hours) tabular-align without abandoning the display face (the plan's "value
// mono where numeric").
//
// Value-type fixture in (`[PlaceFacts]`, the existing leaf) — no AppStore, no domain object (05 §8).
// Token discipline: SEMANTIC tokens only — no literal, no `Primitive.*` (J-0.2).
import SwiftUI

/// A three-cell place-facts grid (key / value / optional sub). Screen-agnostic — a value-type `[PlaceFacts]`
/// in, no `AppStore` (05 §8). Renders one row of equal-width cells that grow with Dynamic Type.
struct PlaceInfoGrid: View {

    /// The facts to render, one per cell (mockup shows three: Hours · Price · Cuisine).
    let cells: [PlaceFacts]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, fact in
                if index > 0 {
                    // The hairline between cells — the mockup's `gap: 1px; background: separator`.
                    Divider().overlay(ColorRole.separator)
                }
                cell(fact)
                    .frame(maxWidth: .infinity, alignment: .leading) // cells grow, text wraps (J-0.3)
            }
        }
        .fixedSize(horizontal: false, vertical: true) // let cells grow vertically, never clip text (J-0.3)
        .background(ColorRole.surfaceGrouped)
        .clipShape(.rect(cornerRadius: Radius.card))
        .accessibilityIdentifier("placeinfogrid")
    }

    // MARK: A cell — mono-caps key · display value · optional secondary sub (mockup `.info-cell`)

    private func cell(_ fact: PlaceFacts) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(fact.key)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)

            Text(fact.value)
                .font(Typography.title)
                .monospacedDigit() // numeric facts tabular-align without leaving the display face
                .foregroundStyle(ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let sub = fact.sub {
                Text(sub)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        // One VoiceOver stop per cell — "Hours, Opens 12:30, Tue – Sun" — not three loose fragments.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label(for: fact))
    }

    private func label(for fact: PlaceFacts) -> String {
        if let sub = fact.sub {
            "\(fact.key), \(fact.value), \(sub)"
        } else {
            "\(fact.key), \(fact.value)"
        }
    }
}

// MARK: - Previews — the canonical three-cell grid (05 §8, §10)

private extension Array where Element == PlaceFacts {
    static let cevicheria: [PlaceFacts] = [
        PlaceFacts(key: "Hours", value: "Opens 12:30", sub: "Tue – Sun"),
        PlaceFacts(key: "Price", value: "€€€", sub: "Mains ~€22"),
        PlaceFacts(key: "Cuisine", value: "Seafood", sub: "Peruvian")
    ]
}

#Preview("Three cells") {
    PlaceInfoGrid(cells: .cevicheria)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
