// ScreenSection.swift — a COMPOSITION primitive: a grouped content block carrying the shared vertical
// rhythm (05-design-system §9; 03-layout-spacing §2/§3; J-1/J-4.2).
//
// Every screen composes `ScreenSection` (not `SwiftUI.Section`, not hand-wired `VStack`+`.padding`) so the
// whole app shares ONE rhythm: an optional header in `Typography.title`, children stacked at the `itemGap`
// rung, and a `sectionGap` rung between the header and its content. Pulling the gaps from named rungs is
// what makes two independently-built screens *match* (J-1) — and grouping comes from SPACE, not dividers or
// boxes (J-4.2): there is no default separator. Left-aligned (J-7.1) — content reads down a single edge.
//
// The internal ≤ external padding law (03 §3): the gap that binds children together (`itemGap`, 12) is a
// LOWER rung than the gap that opens before the content under a header (`sectionGap`, 24), and a lower rung
// than the gap a screen leaves between whole sections (`sectionGap`+). Inner space stays tighter than outer
// space, so proximity does the grouping a border would otherwise fake — no divider, no box (03 §3, J-4.2).
//
// Semantic tokens only — no literal spacing/colors, no `Primitive.*` (J-0.2). Dynamic Type scales the
// header and content; no fixed frames (J-0.3).
import SwiftUI

/// A grouped content block applying the design system's semantic vertical rhythm.
///
/// - An optional `header` renders left-aligned in `Typography.title`.
/// - Children stack at the `Spacing.itemGap` (sibling, 12) rung.
/// - The header-to-content gap is the `Spacing.sectionGap` (section, 24) rung.
///
/// This is a *layout* primitive, deliberately **not** `SwiftUI.Section` (which is a list/form construct).
/// It draws **no divider** by default — groups are read by proximity (J-4.2), honoring the internal ≤
/// external padding law (03 §3): inner `itemGap` < outer `sectionGap`.
struct ScreenSection<Content: View>: View {
    private let header: String?
    private let content: Content

    init(_ header: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sectionGap) {
            if let header {
                Text(header)
                    .font(Typography.title)
                    .foregroundStyle(ColorRole.textPrimary)
            }
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScreenSection("Due this week") {
        Text("The Left Hand of Darkness")
            .font(Typography.body)
            .foregroundStyle(ColorRole.textPrimary)
        Text("A Wizard of Earthsea")
            .font(Typography.body)
            .foregroundStyle(ColorRole.textPrimary)
        Text("The Dispossessed")
            .font(Typography.body)
            .foregroundStyle(ColorRole.textPrimary)
    }
    .padding(Spacing.screenInset)
}
