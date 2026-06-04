/*
 Composition primitive: a left-aligned eyebrow head over a horizontal scroll rail of caller-built items.
 Screens compose this for every rail (Recent-cities, alt-neighborhoods) so they share one rhythm instead
 of hand-wiring ScrollView(.horizontal) + padding. Ports `.rail-head`/`.rail` and `.alt-head`/`.alts`
 from the onboarding destination/base-location mockups.

 The edge inset rides `.contentMargins(.horizontal, …, for: .scrollContent)` so leading/trailing items
 align to the screen margin while overscroll still bleeds under it.
*/
import SwiftUI

struct HScrollSection<Content: View>: View {

    private let title: String
    private let meta: String?
    private let accessibilityIDPrefix: String?
    private let content: Content

    init(
        _ title: String,
        meta: String? = nil,
        accessibilityIDPrefix: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.meta = meta
        self.accessibilityIDPrefix = accessibilityIDPrefix
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)

                if let meta {
                    Spacer(minLength: Spacing.md)
                    Text(meta)
                        .font(Typography.caption)
                        .tracking(Typography.trackEyebrowCaption)
                        .textCase(.uppercase)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenInset)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    content
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, Spacing.screenInset, for: .scrollContent)
            .accessibilityIdentifier(ifPresent: accessibilityIDPrefix)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(meta.map { "\(title), \($0)" } ?? title)
    }
}

#Preview("Recent rail") {
    HScrollSection("Recent", meta: "Last 6 months", accessibilityIDPrefix: "rail.recent") {
        ForEach(["Lisbon", "Tokyo", "Mexico City", "Reykjavík"], id: \.self) { city in
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(city)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Text("Saved")
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .padding(Spacing.lg)
            .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        }
    }
    .padding(.vertical, Spacing.screenInset)
}

#Preview("Head-only meta omitted") {
    HScrollSection("Other neighborhoods we weighed", accessibilityIDPrefix: "rail.alts") {
        ForEach(["Bairro Alto", "Chiado", "Príncipe Real"], id: \.self) { name in
            Text(name)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
                .padding(Spacing.lg)
                .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        }
    }
    .padding(.vertical, Spacing.screenInset)
}
