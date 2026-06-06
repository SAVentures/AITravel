// ProvenanceCard.swift — the place-detail "Saved from" card (05-design-system.md §8; J-8).
// Ports the place-detail mockup `.prov`: a mono-caps "Saved from" eyebrow with a leading source mark,
// a row of (source thumb · who/meta · a "View" affordance), and an italic display-face pull-quote — the
// one editorial italic moment (J-3.6), carried by the display face, never a gradient (02-color §5).
//
// CONTENT surface, so NEVER glass (J-0.1 / J-8): the card is a recessive `surfacePage` ground (mockup
// `.prov { background: var(--paper-100) }`), and the inset "View" control lifts on `surfaceGrouped` +
// the `rest` shadow (mockup `.prov-open`). Value-type fixture in — no AppStore, no domain object (05 §8).
//
// D-3: the "View" affordance only WIRES a caller closure (open the original reel/clip) — no player is
// built this milestone. The component owns the a11y mechanism; the caller owns the id VALUE (05 §8.1):
// the affordance carries the single stable id `provenance.view` (the screen's one provenance per detail).
//
// Token discipline: SEMANTIC tokens only — no literal, no `Primitive.*` (J-0.2).
import SwiftUI

/// The "Saved from" provenance card on a place detail: source thumb + who/meta + a "View" affordance +
/// an italic display quote. Screen-agnostic — a value-type fixture in, no `AppStore` (05 §8).
struct ProvenanceCard: View {

    /// The local value-type fixture this card renders from (mapped from a domain `PlaceProvenance`).
    struct Model: Sendable {
        /// The social/clip handle that triggered the save, e.g. "@saltinmycoffee".
        var sourceHandle: String
        /// The meta line under the handle, e.g. "Reel · "Lisbon in 48 hours" · 0:42". Optional.
        var meta: String?
        /// The pull-quote — the one editorial italic moment (J-3.6). Optional.
        var quote: String?
    }

    let model: Model
    /// D-3: wired to open the original; the component builds no player. Empty for a non-interactive preview.
    var onView: () -> Void = {}

    /// The source-thumb side — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var thumbSide: CGFloat = Sizing.Component.provenanceThumb

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            eyebrow
            row
            if let quote = model.quote {
                quoteLine(quote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        // Recessive content card (mockup `.prov` = `--paper-100`). Solid, one elevation, NEVER glass (J-0.1).
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
        .containerShape(.rect(cornerRadius: Radius.card))
        .accessibilityIdentifier("provenance")
    }

    // MARK: Eyebrow — a source mark glyph + mono caps "Saved from" (mockup `.prov .lab`)

    private var eyebrow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "play.fill")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
                .accessibilityHidden(true)
            Text("Saved from")
                .font(Typography.caption)
                .tracking(Typography.trackEyebrowCaption)
                .textCase(.uppercase)
                .foregroundStyle(ColorRole.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saved from")
    }

    // MARK: Row — thumb · who/meta · the "View" affordance (mockup `.prov-row`)

    private var row: some View {
        HStack(spacing: Spacing.md) {
            sourceThumb
            who
            Spacer(minLength: Spacing.sm)
            viewButton
        }
    }

    /// The source thumbnail — the image is absent in the fixture, so a monochrome glyph placeholder on a
    /// neutral well, never a broken-image box (J-12.4, 08-slop G-1). A real screen swaps in the clip thumb.
    private var sourceThumb: some View {
        RoundedRectangle(cornerRadius: Radius.thumb)
            .fill(ColorRole.fillTertiary)
            .frame(width: thumbSide, height: thumbSide)
            .overlay {
                Image(systemName: "photo")
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textTertiary)
            }
            .accessibilityHidden(true)
    }

    /// The handle (display face, like a name) + the optional meta line (secondary ink), truncating tail.
    private var who: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(model.sourceHandle)
                .font(Typography.name)
                .foregroundStyle(ColorRole.textPrimary)
                .lineLimit(1)
            if let meta = model.meta {
                Text(meta)
                    .font(Typography.subhead)
                    .foregroundStyle(ColorRole.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: The "View" affordance — D-3 wire-only; opens the original (mockup `.prov-open`)

    /// A small lifted pill on `surfaceGrouped` + the `rest` shadow (mockup `.prov-open`). NOT glass — this
    /// is content, and the inset control's lift is a shadow, not the floating-chrome material (J-0.1).
    private var viewButton: some View {
        Button(action: onView) {
            HStack(spacing: Spacing.xs) {
                Text("View")
                Image(systemName: "arrow.up.right")
            }
            .font(Typography.subhead.weight(.semibold))
            .foregroundStyle(ColorRole.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(ColorRole.surfaceGrouped, in: .capsule)
            .shadowRest()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("provenance.view")
        .accessibilityLabel("View original from \(model.sourceHandle)")
    }

    // MARK: The quote — the one editorial italic moment, display face (J-3.6), solid ink not gradient

    private func quoteLine(_ quote: String) -> some View {
        Text(quote)
            // J-3.6: the one editorial italic moment — carried by the DISPLAY face (Schibsted), not the UI
            // family. `name` is the display role nearest the mockup `.prov .quote` (15px display italic; this
            // role is 14px display). Solid ink, never a gradient (02-color §5 / 08-slop C-3).
            .font(Typography.name.italic())
            .foregroundStyle(ColorRole.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews — one per meaningful state (05 §8, §10)

private extension ProvenanceCard.Model {
    static let full = ProvenanceCard.Model(
        sourceHandle: "@saltinmycoffee",
        meta: "Reel · “Lisbon in 48 hours” · 0:42",
        quote: "“The ceviche under that giant octopus is the best meal I had all trip — go at opening, no reservations.”"
    )
    static let quoteless = ProvenanceCard.Model(
        sourceHandle: "@saltinmycoffee",
        meta: "Screenshot · saved Apr 12"
    )
}

#Preview("With quote") {
    ProvenanceCard(model: .full)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("No quote") {
    ProvenanceCard(model: .quoteless)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
