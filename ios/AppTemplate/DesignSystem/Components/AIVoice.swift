// AIVoice.swift — the italic editorial line: the product's AI voice (06-judgment J-3.6; 02-color §5).
//
// One editorial moment per hero, used for the product's *voice* and nothing else (J-3.6 / J-6.2). This
// is the explicit TYPE-NOT-GRADIENT replacement for the old iridescent "AI gradient": the voice is
// carried by the expressive display face in italic, a restrained mono eyebrow, and ONE accent dot — never
// a `LinearGradient`, never gradient text, never a glow (02-color §5; 08-slop A-5 / C-1 / C-3).
//
// Ports the components mockup `.ai` (§06):
//   .ai .lab   — mono caps eyebrow + a small accent mark dot (`var(--accent-500)` → `stateNow`)
//   .ai .line  — the display face, italic, the voice line (`var(--font-display) font-style: italic`)
//
// Anatomy (top→bottom), left-aligned (J-7.1):
//   eyebrow row : [dot]  EYEBROW CAPS        — `Typography.caption` (mono) + caps tracking at the call
//                                              site (T-5.2), `textSecondary`; one `stateNow` dot mark.
//   line        : the italic voice line      — `Typography.name` display `.italic()`, `textPrimary`.
//
// Restraint (the slop scan): exactly one accent appearance (the dot — J-2.4 budget), one editorial
// italic moment (J-3.6), binary inks (eyebrow secondary, line primary — J-2.2), no card/glass/border
// (this is content, never chrome — J-0.1). Semantic tokens only; zero literals / `Primitive.*` (J-0.2).
//
// Value-type args only; no `AppStore`, no domain model (05 §8). A tiny local fixture drives `#Preview`.
import SwiftUI

/// A single editorial line in the product's AI voice: a mono caps eyebrow with one accent dot, above an
/// italic display line. Type-not-gradient by design (02-color §5). Content, never chrome (J-0.1).
struct AIVoice: View {

    /// The short mono-caps label (e.g. "ITINERARY"). Kept brief — caps tracking is for short eyebrows only.
    let eyebrow: String
    /// The voice line — the one editorial italic moment (J-3.6). One sentence with a point (J-11.1).
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            // Eyebrow: one accent dot + mono caps label. The dot is the single accent appearance and is
            // paired with the label (never color alone — 02-color §6, J-2.4).
            HStack(spacing: Spacing.paired) {
                Circle()
                    .fill(ColorRole.stateNow)
                    .frame(width: markSize, height: markSize)
                Text(eyebrow)
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textSecondary)
            }

            // The voice line: display face, italic — the one editorial moment (J-3.6). Solid ink, never
            // gradient text (02-color §5). `text-wrap: pretty` ≈ balanced multi-line wrapping.
            Text(line)
                .font(Typography.name.italic())
                .foregroundStyle(ColorRole.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow): \(line)")
    }

    // The eyebrow mark — a small dot that scales with the eyebrow's mono caps text so it stays optically
    // aligned at every Dynamic Type size (T-6.4). Seeded from the caps tracking reference size; never a
    // bare fixed CGFloat.
    @ScaledMetric(relativeTo: .caption2) private var markSize: CGFloat = 7
}

#Preview("AIVoice") {
    // Local value-type fixture — no SampleData / domain model exists in Phase 0.
    AIVoice(
        eyebrow: "ITINERARY",
        line: "A slow morning in the old town, then the coast before the light goes."
    )
    .padding(Spacing.cardInset)
}
