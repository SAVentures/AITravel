// DetailList.swift — the quiet key→value detail list (05-design-system.md §8; 05-components; J-10.4).
// Ports the booking-detail mockup `.det-list`: a mono-caps section head (`.det-head`) above a
// `surfaceGrouped` clipped (`Radius.card`) list of key/value rows (`.det-row`), each row separated from
// the next by a 1px `separator` hairline (mockup `border-bottom: 0.5px var(--separator)`), the last row
// carrying no separator (`.det-row:last-child { border-bottom: none }`).
//
// Mirrors `PlaceInfoGrid`'s idiom: a `ColorRole.surfaceGrouped` ground clipped to `Radius.card`, with
// hairlines drawn as `Divider().overlay(ColorRole.separator)` — NOT SwiftUI's `Grid`, which collides with
// the design-system `Grid` sizing namespace (Tokens/Sizing.swift). The "last row has no separator" rule
// is honoured by emitting the hairline BEFORE each row except the first.
//
// CONTENT surface, so NEVER glass (J-0.1 / J-8). Dynamic-Type-safe: the key/value share each row's width
// (key leading, value trailing) and grow vertically — no fixed frame, text wraps — so the list never
// clips at large type (J-0.3, 08-slop D-7).
//
// Reuses the existing leaf value type `DetailRow` (Models/DetailRow.swift: { key, value }) — the same
// type `BookingDetailInfo.detailRows` carries — so the presenter feeds this list directly (05 §8).
// Token discipline: SEMANTIC tokens only — no literal, no `Primitive.*` (J-0.2).
import SwiftUI

/// A quiet key→value detail list under a mono-caps head. Screen-agnostic — a value-type `[DetailRow]`
/// in, no `AppStore` (05 §8). The rows render in a hairline-separated card that grows with Dynamic Type.
struct DetailList: View {

    /// The mono-caps section head (mockup `.det-head`, e.g. "FLIGHT DETAILS").
    let head: String

    /// The key/value rows (mockup `.det-row`), in order. Reuses the existing `DetailRow` leaf.
    let rows: [DetailRow]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // The mono-caps section head — a heading for VoiceOver navigation.
            Text(head)
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
                .padding(.leading, Spacing.xs) // mockup `.det-head { padding-left: 2px }`
                .accessibilityAddTraits(.isHeader)

            // The clipped card of rows (mockup `.det-rows`).
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        // The hairline between rows — the mockup's `border-bottom: 0.5px separator`,
                        // emitted before each row except the first so the last row has none.
                        Divider().overlay(ColorRole.separator)
                    }
                    detailRow(row)
                }
            }
            .background(ColorRole.surfaceGrouped)
            .clipShape(.rect(cornerRadius: Radius.card))
        }
        .accessibilityIdentifier("detaillist")
    }

    // MARK: A row — secondary key (leading) · emphasized value (trailing) (mockup `.det-row`)

    private func detailRow(_ row: DetailRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(row.key)
                .font(Typography.callout)
                .foregroundStyle(ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.sm)

            Text(row.value)
                .font(Typography.callout)
                .fontWeight(.semibold) // mockup `.det-row .v { font-weight: 600 }`
                .foregroundStyle(ColorRole.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        // One VoiceOver stop per row — "Departs, Sat 13:40 LIS" — not two loose fragments.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.key), \(row.value)")
    }
}

// MARK: - Previews — the canonical flight detail list (05 §8, §10)

private extension Array where Element == DetailRow {
    static let flight: [DetailRow] = [
        DetailRow(key: "Airline", value: "TAP Air Portugal"),
        DetailRow(key: "Flight", value: "TP 201"),
        DetailRow(key: "Departs", value: "Sat 13:40 · LIS"),
        DetailRow(key: "Arrives", value: "Sat 18:05 · JFK"),
        DetailRow(key: "Aircraft", value: "A330neo")
    ]
}

#Preview("Flight detail") {
    DetailList(head: "Flight details", rows: .flight)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
