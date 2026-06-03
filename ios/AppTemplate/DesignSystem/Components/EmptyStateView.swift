// EmptyStateView.swift — the considered empty state: it earns the same editorial care as the happy path
// (05-components §9; J-11.6). Ports the mockup `.empty` (components.html §09): a monochrome SF Symbol
// glyph (recessed ink, never a broken-image box — J-12.4), one calm specific display-face line (no alarm
// — J-11.5), and an OPTIONAL single secondary `PillButton` (never the budgeted accent — J-2.4/J-6.1).
// CONTENT on a resting `.cardSurface()`, never glass (J-0.1); centered as the rare standalone block (J-7.1).
// Value-type args only (05 §8); semantic tokens only.
import SwiftUI

struct EmptyStateView: View {
    /// The monochrome SF Symbol glyph — a placeholder, never a broken-image box (J-12.4).
    let systemImage: String
    /// The one editorial line — specific, calm copy; no alarm, no exclamation (J-11.5).
    let message: String
    /// The offered action's label — a present-tense verb the user owns ("Add a place"; J-11.3). When
    /// `nil`, the empty state only explains and renders no button.
    var actionTitle: String?
    /// The action handler, paired with `actionTitle`.
    var action: (() -> Void)?

    /// The glyph box, scaled with the editorial line so it tracks Dynamic Type (T-6.4) — a placeholder
    /// metric, never a fixed frame (J-0.3).
    @ScaledMetric(relativeTo: .headline) private var glyphSize: CGFloat = Sizing.Component.emptyStateGlyph

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Monochrome, recessed glyph — the placeholder ink (textTertiary ≈ the mockup's `--ink-300`),
            // never a colored fill or a broken-image box (J-12.4, 02-color §2).
            Image(systemName: systemImage)
                .font(.system(size: glyphSize, weight: .light))
                .foregroundStyle(ColorRole.textTertiary)
                .accessibilityHidden(true)

            // The one editorial line — display face, primary ink, centered (the rare standalone-block
            // case where centering is right, J-7.1).
            Text(message)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // The one offered action — a secondary-tier PillButton (a real but lesser action; the empty
            // state never claims the budgeted accent CTA, §9 / J-2.4 / J-6.1). Rendered only when present.
            if let actionTitle, let action {
                PillButton(title: actionTitle, tier: .secondary, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .cardSurface()
        // One VoiceOver stop: the glyph is decorative, the message + action carry the meaning.
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview fixture (a tiny in-file value type · Wave-C rule)

/// A local value-type fixture for the preview + the Wave-E snapshot — calm, specific copy mirroring the
/// mockup `.empty` ("No saved places in Lisbon yet." + "Add a place"). No domain object, no store (05 §8).
private struct EmptyStateFixture {
    let systemImage: String
    let message: String
    var actionTitle: String?

    /// The mockup `.empty`: a bookmark glyph, one editorial line, one secondary action.
    static let savedPlaces = EmptyStateFixture(
        systemImage: "bookmark",
        message: "No saved places in Lisbon yet.",
        actionTitle: "Add a place"
    )
}

#Preview("Empty — glyph, one line, one action") {
    let fixture = EmptyStateFixture.savedPlaces
    EmptyStateView(
        systemImage: fixture.systemImage,
        message: fixture.message,
        actionTitle: fixture.actionTitle
    ) {}
        .padding(Spacing.lg)
        .background(ColorRole.surfacePage)
}
