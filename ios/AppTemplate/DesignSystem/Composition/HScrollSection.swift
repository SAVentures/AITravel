// HScrollSection.swift — a COMPOSITION primitive: an eyebrow head over a horizontal scroll rail
// (05-design-system §9; 03-layout-spacing §2/§4; J-1 / J-4.2 / J-7.1 / J-7.3).
//
// The reusable horizontal-rail shell: a left-aligned head (a display title + an optional mono caps meta)
// over a horizontally-scrolling row of caller-built items. Screens compose THIS for every rail — the
// destination Recent-cities rail, the alt-neighborhoods rail — so they share ONE rhythm and ONE head
// vocabulary instead of hand-wiring `ScrollView(.horizontal)` + padding per screen (J-1 anti-divergence).
//
// PORTS FROM:
//   `mockups/screens/onboarding/state-a-screen-01-destination.html` `.rail-head` / `.rail` / `.rcc`
//   `mockups/screens/onboarding/state-a-screen-03-base-location.html`  `.alt-head` / `.alts` / `.alt`
//     head row  `.rail-head { justify-content: space-between }`        → baseline-aligned HStack (J-7.3)
//     title     `.rail-head .l` display semibold `var(--ink-900)`      → `Typography.name` · `textPrimary`
//     meta      `.rail-head .r` mono caps `var(--text-tertiary)`       → `Typography.caption` mono · `textTertiary`
//     row gap   `.rail/.alts { gap: 8px }`                             → `Spacing.paired` (paired rung — J-1)
//     edge      `.rail/.alts { padding: 0 22px }`                      → `Spacing.screenInset` (compact margin — 03 §4)
//     head→rail `.rail-head { margin: … 0 12px }`                      → `Spacing.itemGap` (head ↔ rail — J-1)
//
// Token discipline: SEMANTIC tokens only — zero literals, zero `Primitive.*` (J-0.2). This is CONTENT, so
// it is NEVER glass (J-0.1 / J-8). The head meta caps tracking is applied from the named token
// (`trackEyebrowCaption`, T-5.2). No divider — the head and rail are grouped by SPACE (J-4.2). Dynamic
// Type scales the head and the items; no fixed frames (J-0.3).
//
// Generic over a caller `@ViewBuilder` content slot — the rail hosts whatever cards/chips the screen builds
// (value-type-driven), never an `AppStore` or a domain object (05 §8). The edge inset rides
// `.contentMargins(.horizontal, …, for: .scrollContent)` so the leading/trailing items align to the screen
// margin while the scroll content still bleeds under it on overscroll.
import SwiftUI

/// A horizontal scroll rail with a left-aligned eyebrow head. Compose it for any rail of small cards/chips:
/// a display `title`, an optional mono caps `meta`, and a `@ViewBuilder` row of caller content scrolled at
/// the `Spacing.paired` rung, inset to the standard screen margin. Content, never chrome (J-0.1).
struct HScrollSection<Content: View>: View {

    private let title: String
    private let meta: String?
    /// An optional accessibility-id prefix for the scroll container (e.g. "rail.recent" / "rail.alts").
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
        // Head ↔ rail bound at the sibling rung — grouped by SPACE, no divider (J-1 / J-4.2).
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            // The head row — title and meta share a baseline, pushed to opposite edges (J-7.3). Inset to the
            // standard screen margin so it lines up with the leading edge of the first rail item.
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)

                if let meta {
                    Spacer(minLength: Spacing.itemGap)
                    Text(meta)
                        .font(Typography.caption)
                        .tracking(Typography.trackEyebrowCaption)
                        .textCase(.uppercase)
                        .foregroundStyle(ColorRole.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenInset)

            // The rail — caller items at the paired rung, the leading/trailing items inset to the screen
            // margin via scroll-content margins (so overscroll still bleeds under the edge correctly).
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Spacing.paired) {
                    content
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, Spacing.screenInset, for: .scrollContent)
            .accessibilityIdentifier(accessibilityIDPrefix ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(meta.map { "\(title), \($0)" } ?? title)
    }
}

#Preview("Recent rail") {
    // Local value-type fixture — no SampleData / domain model exists in Phase 0. The rail hosts whatever
    // small cards/chips the screen builds; here a minimal stand-in chip in semantic tokens.
    HScrollSection("Recent", meta: "Last 6 months", accessibilityIDPrefix: "rail.recent") {
        ForEach(["Lisbon", "Tokyo", "Mexico City", "Reykjavík"], id: \.self) { city in
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(city)
                    .font(Typography.name)
                    .foregroundStyle(ColorRole.textPrimary)
                Text("Saved")
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .textCase(.uppercase)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .padding(Spacing.cardInset)
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
                .padding(Spacing.cardInset)
                .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
        }
    }
    .padding(.vertical, Spacing.screenInset)
}
