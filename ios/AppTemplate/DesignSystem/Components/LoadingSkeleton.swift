// LoadingSkeleton.swift — redacted placeholder rows at the real content footprint (05-components §9;
// 06-judgment J-9.3; 07-testing.md §6.4).
//
// The loading state for a list/card region: redacted bars laid out at the REAL footprint of the content
// that will arrive, so nothing reflows when data lands (05-components §9). At most ONE shimmer runs on
// screen — a single continuous sweep across the whole skeleton, not a loop per bar (J-9.3: at most one
// continuous motion). Everything else is static.
//
// PORTS FROM: `mockups/components/Components.html` §09 `.skel`
//   surface  `.skel { background: var(--surface-grouped); border-radius: var(--r-card);
//             box-shadow: var(--shadow-rest); overflow: hidden; }`
//                                              → `ColorRole.surfaceGrouped` + `Radius.card` + `.shadowRest()`
//   row      `.skrow { grid 44px 1fr; gap: 13px; padding: 14px 16px; }`
//                                              → leading square + text column, `Spacing.itemGap` gap,
//                                                `Spacing.cardInset` inset (the real list-row footprint)
//   bar      `.skel .b { background: var(--paper-200); border-radius: 6px; height: 12px; }`
//                                              → redaction bar: `ColorRole.fillSecondary` ground (the
//                                                neutral redaction overlay role) + `Radius.tag` corners
//   square   `.skel .b.sq { 44×44; border-radius: 9px; }`   → the leading thumbnail placeholder (`Radius.thumb`)
//   widths   `.w1 { 55% }` `.w2 { 80%; height: 9px }`       → primary-line + secondary-line bar widths
//   shimmer  `.skel .b::after { linear-gradient sweep; animation: shim 1.3s infinite; }`
//                                              → ONE highlight sweep across the whole skeleton (J-9.3)
//
// ── The redaction-bar color ──────────────────────────────────────────────────────────────────────────
// The mockup fills the bars with `--paper-200` (a flat well tone). In the SEMANTIC tier the role for a
// neutral redaction overlay is `ColorRole.fillSecondary` (a low-opacity ink fill) — the plan's
// `ColorRole.fill*` instruction. Authoring against the role (not the raw `paper-200` primitive) keeps the
// file token-pure (J-0.2): zero literals, zero `Primitive.*`.
//
// ── Motion: static under BOTH Reduce Motion and the snapshot seam ─────────────────────────────────────
// The shimmer goes STATIC (no animation; the highlight parked off-screen at rest) when EITHER:
//   • `@Environment(\.accessibilityReduceMotion)` is on — continuous motion goes static, not deleted
//     (04-motion §7, J-9.5); the redacted footprint still communicates "loading".
//   • `\.disablesOneShotMotion` is injected `true` — the snapshot seam (07-testing.md §6.4) so a render
//     snapshot settles to rest instead of catching the sweep mid-flight and flaking.
// The sweep itself uses `Motion.standard(...)` (the one house easing) repeated forever — never a raw
// `.timingCurve`/`.linear` inline (J-0.2 / J-9.2). This is the only continuous motion the component owns.
//
// Value-type args only; no `AppStore`, no domain model (05-design-system.md §8). NEVER glass — this is
// content, glass is floating chrome only (J-0.1 / J-8).
import SwiftUI

// MARK: - The snapshot / one-shot-motion seam (07-testing.md §6.4)

/// When `true`, any one-shot or continuous entrance motion (a shimmer, an `.oneShotPulse`) settles to its
/// resting frame instead of animating — so a render snapshot captures rest, not a mid-flight frame
/// (07-testing.md §6.4). Default `false` (motion runs in the live app). The snapshot helper injects
/// `true` (`designSystemEnvironment()`); production never sets it.
///
/// Declared here because `LoadingSkeleton` is the first component in the foundation to own continuous
/// motion (the B3 `OneShotPulse` modifier is deferred — OD-2). Any later one-shot motion reads the same
/// key, so the snapshot seam is uniform.
private struct DisablesOneShotMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// The snapshot seam: settle one-shot / continuous motion to rest when `true` (07-testing.md §6.4).
    var disablesOneShotMotion: Bool {
        get { self[DisablesOneShotMotionKey.self] }
        set { self[DisablesOneShotMotionKey.self] = newValue }
    }
}

// MARK: - LoadingSkeleton

/// A redacted loading placeholder: rows of grey bars at the real list-row footprint, on one grouped
/// surface, with at most one shimmer sweeping across the whole skeleton (J-9.3). Screen-agnostic — takes a
/// tiny value-type fixture (a row count), no `AppStore`, no domain object (05-design-system.md §8).
struct LoadingSkeleton: View {

    /// The local value-type fixture: how many redacted rows to lay out at the real footprint. No
    /// `SampleData` / domain model exists in the foundation phase.
    let rowCount: Int

    init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.disablesOneShotMotion) private var disablesOneShotMotion

    /// Drives the single sweep. `false` parks the highlight off the leading edge (the rest frame); the
    /// `onAppear` flips it to `true` to start the repeating sweep — only when motion is allowed.
    @State private var sweeping = false

    /// Motion is static when EITHER the user has Reduce Motion on OR the snapshot seam disables it.
    private var motionDisabled: Bool { reduceMotion || disablesOneShotMotion }

    // The redaction-bar heights scale with Dynamic Type so the placeholder keeps the real footprint at
    // every text size (T-6.4) — never a bare fixed CGFloat. Seeded from the mockup's bar heights.
    @ScaledMetric(relativeTo: .body) private var primaryBarHeight: CGFloat = 12
    @ScaledMetric(relativeTo: .subheadline) private var secondaryBarHeight: CGFloat = 9
    @ScaledMetric(relativeTo: .body) private var squareSide: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                skeletonRow
            }
        }
        // One grouped surface with the rest lift — the mockup `.skel` (ports `.cardSurface`'s look but
        // without its outer padding, since each row carries its own inset, matching `.skel`/`.skrow`).
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
        .clipShape(.rect(cornerRadius: Radius.card)) // overflow: hidden — the sweep is clipped to the card
        .shadowRest()
        // THE one shimmer (J-9.3): a single highlight sweeping the whole skeleton, masked to the redaction
        // shapes so only the bars catch the light. Static (parked) under Reduce Motion / the snapshot seam.
        .overlay { shimmer }
        // It is decorative loading affordance — one VoiceOver stop announcing the state, not the bars.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
        .onAppear {
            guard !motionDisabled else { return }
            withAnimation(Motion.standard(Motion.slow).repeatForever(autoreverses: false)) {
                sweeping = true
            }
        }
    }

    // MARK: - A redacted row at the real list-row footprint

    private var skeletonRow: some View {
        HStack(spacing: Spacing.itemGap) {
            // Leading thumbnail placeholder (the `.b.sq` square).
            RoundedRectangle(cornerRadius: Radius.thumb)
                .fill(ColorRole.fillSecondary)
                .frame(width: squareSide, height: squareSide)

            // The text column: a primary line + a shorter, slimmer secondary line (`.w1` / `.w2`),
            // left-aligned (J-7.1). `maxWidth` fractions hold the real two-line text footprint.
            VStack(alignment: .leading, spacing: Spacing.paired) {
                bar(height: primaryBarHeight, widthFraction: 0.55)
                bar(height: secondaryBarHeight, widthFraction: 0.80)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The real list-row inset: horizontal `cardInset`, vertical `itemGap` (the `.skrow` 14/16 footprint).
        .padding(.horizontal, Spacing.cardInset)
        .padding(.vertical, Spacing.itemGap)
    }

    /// One redaction bar — a `fillSecondary` capsule-cornered rectangle at a fraction of the column width.
    private func bar(height: CGFloat, widthFraction: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.tag)
            .fill(ColorRole.fillSecondary)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .scaleEffect(x: widthFraction, anchor: .leading)
    }

    // MARK: - The single shimmer sweep (J-9.3)

    /// One highlight band that sweeps across the whole skeleton. A `GeometryReader` sizes the sweep so a
    /// fixed offset maps to "fully left of content" (rest) → "fully right of content" (end). When motion is
    /// disabled it never animates and `sweeping` stays `false`, so the band sits parked off the leading
    /// edge — invisible at rest. The band is additive light (a soft white highlight), never a gradient FILL
    /// or text (08-slop C-1/C-3); it only momentarily brightens the grey bars.
    private var shimmer: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // Park fully off the leading edge at rest; sweep one band-width past the trailing edge.
            let offset = sweeping ? width : -width
            LinearGradient(
                colors: [.clear, ColorRole.surfaceGrouped.opacity(0.55), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
            .offset(x: offset)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
        }
        .opacity(motionDisabled ? 0 : 1) // fully static at rest — no band visible under the snapshot seam
    }
}

#Preview("Loading") {
    // Settled preview: inject the snapshot seam so the shimmer parks at rest (no mid-sweep frame in the
    // preview canvas), matching how the Wave E snapshot captures it (07-testing.md §6.4).
    LoadingSkeleton(rowCount: 3)
        .padding(Spacing.screenInset)
        .environment(\.disablesOneShotMotion, true)
}

#Preview("Loading — live shimmer") {
    // The live state: the single sweep runs (Reduce Motion off, snapshot seam default false).
    LoadingSkeleton(rowCount: 3)
        .padding(Spacing.screenInset)
}
