// LoadingSkeleton.swift — redacted placeholder rows at the REAL content footprint, so nothing reflows
// when data lands (05-components §9; ports mockups/components/Components.html §09 `.skel`).
//
// At most ONE shimmer on screen: a single continuous sweep across the whole skeleton (J-9.3). It goes
// STATIC (highlight parked off-screen) under EITHER Reduce Motion (J-9.5 — the footprint still reads
// "loading") OR the injected `disablesOneShotMotion` snapshot seam (07-testing.md §6.4, so a snapshot
// settles to rest instead of catching a mid-flight frame). Content, never glass (J-0.1).
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

    // Redaction-bar / square heights scale with Dynamic Type so the placeholder holds the real footprint
    // at every text size (T-6.4). The square mirrors a 44 tap-target cell (one source: Sizing.minTapTarget).
    @ScaledMetric(relativeTo: .body) private var primaryBarHeight: CGFloat = Sizing.Component.skeletonPrimaryBar
    @ScaledMetric(relativeTo: .subheadline) private var secondaryBarHeight: CGFloat = Sizing.Component.skeletonSecondaryBar
    @ScaledMetric(relativeTo: .body) private var squareSide: CGFloat = Sizing.minTapTarget

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
        HStack(spacing: Spacing.md) {
            // Leading thumbnail placeholder (the `.b.sq` square).
            RoundedRectangle(cornerRadius: Radius.thumb)
                .fill(ColorRole.fillSecondary)
                .frame(width: squareSide, height: squareSide)

            // The text column: a primary line + a shorter, slimmer secondary line (`.w1` / `.w2`),
            // left-aligned (J-7.1). `maxWidth` fractions hold the real two-line text footprint.
            VStack(alignment: .leading, spacing: Spacing.sm) {
                bar(height: primaryBarHeight, widthFraction: 0.55)
                bar(height: secondaryBarHeight, widthFraction: 0.80)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The real list-row inset (the `.skrow` 14/16 footprint).
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
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
