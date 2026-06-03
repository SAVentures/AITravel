// EmptyStateView.swift — the considered empty state (05-components §9; J-11.6, J-12.4, J-13.5).
//
// An empty region earns the SAME editorial care as the happy path — a considered empty state is a craft
// signal, never an afterthought (J-11.6 / J-13.5). Ports the mockup `.empty` (components.html §09):
//
//   • a MONOCHROME SF Symbol glyph — recessed placeholder ink (the mockup `.empty .g` is `--ink-300`),
//     NEVER a broken-image box and never a stock illustration (J-12.4, 08-slop G-1).
//   • ONE editorial line of specific copy in the DISPLAY face (`Typography.name` — the mockup `.empty .ln`
//     is `--font-display` weight 500 / 17, exactly the `name` role). Calm and specific ("No saved places
//     in Lisbon yet."), not an alarm — no exclamation marks, no "Error" copy (J-11.5).
//   • ONE offered action — a `PillButton` at the SECONDARY tier (a real but lesser action; the empty
//     state isn't *the* CTA of the screen, so it never claims the budgeted accent — §9, J-2.4/J-6.1).
//
// This is CONTENT, not floating chrome — so it sits on a resting `.cardSurface()` (the mockup `.empty`
// is `surface-grouped` + `r-card` + `shadow-rest`) and is NEVER glass (J-0.1). Content is centered here
// (the one place centering is right — a standalone hero/empty block, J-7.1), left-alignment being the
// row/list default.
//
// @ScaledMetric (T-6.4): the glyph is a non-text metric, so its box scales with the line text via
// `@ScaledMetric(relativeTo:)` rather than a fixed CGFloat (J-0.3). Nothing is fixed-framed.
//
// Value-type args only — `systemImage` + `message` + an optional `actionTitle`/`action` (no AppStore, no
// domain object; 05 §8). The action is optional because some empty regions only explain, they don't act;
// when present it is the single secondary `PillButton`. Semantic tokens + the C1 PillButton only — zero
// literals, zero `Primitive.*`, zero glass.
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
    /// metric, never a fixed frame (J-0.3). 44pt mirrors the mockup `.empty .g`.
    @ScaledMetric(relativeTo: .headline) private var glyphSize: CGFloat = 44

    var body: some View {
        VStack(spacing: Spacing.cardInset) {
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
        .padding(Spacing.cardInset)
        .background(ColorRole.surfacePage)
}
