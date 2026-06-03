/*
 A quiet context-note row: leading glyph + mono caps eyebrow + body line whose key spans are emphasized
 by WEIGHT, never color. Ports screen-04-getting-around.html `.note`.

 Deliberately carries NO alarm color (no destructive, no accent, no "!" — J-11.5): a considered caveat
 earns trust by being calm. Content, so never glass (J-0.1).
*/
import SwiftUI

struct ContextNote: View {

    let eyebrow: String
    let text: String
    /// Substrings of `text` to emphasize by WEIGHT — never an alarm color (J-2 / J-11.5).
    let emphasis: [String]
    let systemImage: String?

    init(eyebrow: String, text: String, emphasis: [String] = [], systemImage: String? = nil) {
        self.eyebrow = eyebrow
        self.text = text
        self.emphasis = emphasis
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.itemGap) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textTertiary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(eyebrow)
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)

                Text(emphasizedText)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        .accessibilityIdentifier("contextnote")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow): \(text)")
    }

    private var emphasizedText: AttributedString {
        var attributed = AttributedString(text)
        for span in emphasis where !span.isEmpty {
            var search = attributed.startIndex
            while let range = attributed[search...].range(of: span) {
                attributed[range].font = Typography.subhead.weight(.semibold)
                attributed[range].foregroundColor = ColorRole.textPrimary
                search = range.upperBound
            }
        }
        return attributed
    }
}

#Preview("With emphasis") {
    ContextNote(
        eyebrow: "For your dates",
        text: "Rain 2 of 4 days — transit keeps the plan dry without changing the shape.",
        emphasis: ["Rain 2 of 4 days"],
        systemImage: "cloud.rain"
    )
    .padding(Spacing.screenInset)
}

#Preview("Text only") {
    ContextNote(
        eyebrow: "Lots of saves here",
        text: "We can lean on the 23 places you've already saved."
    )
    .padding(Spacing.screenInset)
}
