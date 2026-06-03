// AIVoice.swift — the italic editorial line: the product's AI voice, one moment per hero (J-3.6).
// The explicit TYPE-NOT-GRADIENT replacement for the old "AI gradient" — carried by the display face in
// italic + a mono eyebrow + ONE accent dot, never a gradient/glow (02-color §5; 08-slop A-5/C-1/C-3).
// Ports the components mockup `.ai` (§06): mono caps eyebrow with a `stateNow` dot, above the italic
// `Typography.name` voice line. Left-aligned (J-7.1), binary inks (J-2.2), content not chrome (J-0.1).
// Value-type args only (05 §8).
import SwiftUI

/// A single editorial line in the product's AI voice: a mono caps eyebrow with one accent dot, above an
/// italic display line. Type-not-gradient by design (02-color §5). Content, never chrome (J-0.1).
struct AIVoice: View {

    /// The short mono-caps label (e.g. "ITINERARY"). Kept brief — caps tracking is for short eyebrows only.
    let eyebrow: String
    /// The voice line — the one editorial italic moment (J-3.6). One sentence with a point (J-11.1).
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Eyebrow: one accent dot + mono caps label. The dot is the single accent appearance and is
            // paired with the label (never color alone — 02-color §6, J-2.4).
            HStack(spacing: Spacing.sm) {
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

    // The eyebrow mark — a small dot that scales with the mono caps text so it stays optically aligned at
    // every Dynamic Type size (T-6.4).
    @ScaledMetric(relativeTo: .caption2) private var markSize: CGFloat = Sizing.dot
}

#Preview("AIVoice") {
    // Local value-type fixture — no SampleData / domain model exists in Phase 0.
    AIVoice(
        eyebrow: "ITINERARY",
        line: "A slow morning in the old town, then the coast before the light goes."
    )
    .padding(Spacing.lg)
}
