// TripShapeCard.swift — the selectable trip-shape choice card with an embedded shape diagram
// (05-components §3/§5; ports `.scard` from mockups/screens/onboarding/state-a/b-screen-02-trip-shape.html).
//
// One step-02 choice: "how should this trip fit?" Each card names a strategy (A · Fixed days, B · Cover the
// bucket, C · Just the highlights), states the consequence as a mono metric strip, and *shows the shape* with
// a small embedded diagram in a trailing column. The card mirrors `PlaceCard`'s definitive/fuzzy register:
//
// ── Register (a value-type enum arg, like `PlaceCertainty`) ───────────────────────────────────────────
// `.selectable`  — unselected recedes onto a flat `surfacePage` ground (mockup `.scard` = `paper-100`, no
//   shadow); selected lifts to `.cardSurface()` PLUS a 2pt `textPrimary` ink ring + an ink check
//   (mockup `.scard.sel` = `surface-grouped` + `shadow-rest` + `0 0 0 2px var(--ink-900)`). Certainty is
//   carried by elevation + the ink ring/check — never the accent, never a side-border (J-8, J-2.4).
// `.locked(reason:)` — the mockup `.scard.off`: reduced opacity, the title recedes, and a lockline (lock
//   glyph + reason) replaces the metric strip. NOT tappable, NOT selectable (state B's "Cover the bucket"
//   before any local saves).
//
// ── Three embedded diagrams (`TripShapeDiagram`, 3 private sub-views) ─────────────────────────────────
// `.fixedDays`  → `FixedDaysDiagram`: columns of dots, trailing dots dimmed (the day budget).
// `.coverBucket`→ `CoverBucketDiagram`: a 5-col grid of day-COLORED dots (`dayMark1…4` + a neutral 5th) —
//   categorical neighborhood marks, never fills of size (J-2 / 02-color §2). Locked → neutral dots.
// `.rankedBars` → `RankedBarsDiagram`: a rotated-square mark + a width-% bar per row (the ranking).
//
// Data in as value-type args only; no `AppStore`, no domain object (05 §8). Semantic tokens + the
// `cardSurface` modifier only — zero literals, zero `Primitive.*`, NEVER glass (J-0.1/J-0.2).
import SwiftUI

// MARK: - The register — selectable vs locked, as a value-type arg

/// How a trip-shape card behaves and reads. `.selectable` recedes flat / lifts-with-ink-ring on selection;
/// `.locked` is the dimmed, un-tappable "needs local saves first" state (mockup `.scard` / `.scard.off`).
enum TripShapeRegister: Equatable, Sendable {
    /// A choosable shape: flat `surfacePage` when unselected, lifted `cardSurface` + 2pt ink ring + ink
    /// check when selected.
    case selectable
    /// A shape that needs a precondition (e.g. local saves): reduced opacity, a lockline with the reason,
    /// not an actionable element.
    case locked(reason: String)
}

// MARK: - The metric strip fragment — a mono consequence span

/// One mono fragment in the metric strip ("hits 14 of 23", "skips 9"). `emphasis` darkens it to ink
/// (mockup `.prev b`); `struck` strikes it through in muted ink (mockup `.prev .skip`).
struct MetricToken: Identifiable, Equatable, Sendable {
    let id: String
    /// The fragment text. Mono, sits in the strip.
    let text: String
    /// Darken to `textPrimary` for the named number (mockup `.prev b`).
    let emphasis: Bool
    /// Strike through + mute to `textTertiary` for a skipped count (mockup `.prev .skip`).
    let struck: Bool

    init(_ text: String, emphasis: Bool = false, struck: Bool = false) {
        self.id = text
        self.text = text
        self.emphasis = emphasis
        self.struck = struck
    }
}

// MARK: - The embedded diagram — the shape of each choice, as value args

/// Which shape diagram the trailing column renders, with its data as plain value args (no view passed in).
enum TripShapeDiagram: Equatable, Sendable {
    /// Columns of dots — the day budget; `filled` dots per column are solid, `dim` are receded
    /// (mockup `.d-fixed`: `.dt` vs `.dt.dim`). Each pair is one column.
    case fixedDays(filled: [Int], dim: [Int])
    /// A 5-column grid of day-COLORED dots — counts per neighborhood mark, laid out in run order
    /// (mockup `.d-cover`: `.c1…c4` = `day-1…4`, `.c5` = neutral). Categorical marks (J-2).
    case coverBucket(dayCounts: [Int])
    /// Ranked bars — each value is a 0…1 width fraction; `pick` highlights one row's mark, `dim` recedes
    /// one (mockup `.d-high`: `.r` / `.r.pick` / `.r.dim`).
    case rankedBars(values: [Double], dim: Int?, pick: Int?)
}

// MARK: - TripShapeCard

/// A selectable trip-shape card: `[eyebrow] [display title] [mono metric strip] [embedded diagram]`, with an
/// ink check when selected. Covers the selectable (unselected / selected) and locked registers; all three
/// diagrams render from value args. An optional `embeddedControl` slot hosts the inline `DayStepper` (card A).
struct TripShapeCard: View {
    /// The card's caller id suffix (`a` / `b` / `c`) → `tripshape.<id>` and `tripshape.<id>.check/.locked`.
    let id: String
    /// The mono caps eyebrow, e.g. "A · Fixed days".
    let eyebrow: String
    /// The display title, e.g. "Pack four great days."
    let title: String
    /// The mono metric strip fragments (some emphasised, some struck). Empty when locked (the lockline shows).
    var metricStrip: [MetricToken] = []
    /// The embedded shape diagram for the trailing column.
    let diagram: TripShapeDiagram
    /// The register — selectable (flat/lifted) or locked (dimmed + lockline).
    let register: TripShapeRegister
    /// Whether this selectable card is the chosen one (ink ring + check). Ignored when locked.
    var isSelected: Bool = false
    /// An optional inline control under the title (the `DayStepper` for card A). Erased so the screen owns
    /// the concrete control; the component only reserves the slot.
    var embeddedControl: AnyView? = nil
    /// Select action. A no-op is passed for a locked card (it isn't tappable).
    var onSelect: () -> Void = {}

    /// The trailing diagram column width — a non-text metric, so it scales with Dynamic Type via
    /// `@ScaledMetric` rather than a fixed CGFloat (J-0.3). Seeded from the mockup's 100pt column.
    @ScaledMetric(relativeTo: .body) private var diagramColumnWidth: CGFloat = 100

    private var lockReason: String? {
        if case let .locked(reason) = register { return reason }
        return nil
    }

    private var isLocked: Bool { lockReason != nil }

    /// Selected only matters for the selectable register (a locked card never shows the ring/check).
    private var showsSelected: Bool { isSelected && !isLocked }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.itemGap) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            diagramColumn
                .frame(width: diagramColumnWidth)
        }
        .modifier(TripShapeSurface(register: register, isSelected: showsSelected))
        .overlay(alignment: .topTrailing) { selectionMark }
        .opacity(isLocked ? lockedOpacity : 1)
        .contentShape(.rect(cornerRadius: Radius.card))
        .modifier(SelectAction(isEnabled: !isLocked, action: onSelect))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eyebrow + ". " + title)
        .accessibilityAddTraits(showsSelected ? [.isSelected] : [])
        .modifier(LockedAccessibility(reason: lockReason))
        // Locked → `tripshape.<id>.locked`; otherwise `tripshape.<id>` (the id is applied last so it wins).
        .accessibilityIdentifier(isLocked ? "tripshape.\(id).locked" : "tripshape.\(id)")
    }

    /// The locked register's recede — a single muted-opacity step (mockup `.scard.off { opacity: 0.55 }`),
    /// kept as a named constant fraction rather than a magic literal at the call site.
    private var lockedOpacity: Double { 0.55 }

    // MARK: Content column — eyebrow · title · (control) · metric strip OR lockline

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.paired) {
            eyebrowLabel
            Text(title)
                .font(Typography.title)
                .tracking(Typography.titleTracking)
                .foregroundStyle(titleColor)
                .fixedSize(horizontal: false, vertical: true) // wrap, never truncate (J-0.3)

            if let embeddedControl {
                embeddedControl
            }

            Spacer(minLength: Spacing.paired) // push the strip / lockline to the bottom (mockup `margin-top: auto`)

            if let lockReason {
                lockline(reason: lockReason)
            } else if !metricStrip.isEmpty {
                metricStripView
            }
        }
    }

    /// The mono caps eyebrow. The leading token ("A") reads strong (`textPrimary`); the remainder is the
    /// tertiary caps label (mockup `.lab` with the strong `.lab .n`).
    private var eyebrowLabel: some View {
        Text(eyebrow.uppercased())
            .font(Typography.caption)
            .tracking(Typography.trackEyebrowCaption)
            .foregroundStyle(ColorRole.textTertiary)
            .accessibilityHidden(true) // surfaced via the combined label
    }

    /// Selected / definitive → `textPrimary`; unselected selectable → `textSecondary` (mockup
    /// `.scard:not(.sel) .ttl`); locked → `textTertiary` (mockup `.scard.off .ttl`).
    private var titleColor: Color {
        if isLocked { return ColorRole.textTertiary }
        return showsSelected ? ColorRole.textPrimary : ColorRole.textSecondary
    }

    // MARK: Metric strip — mono consequence fragments separated by a middot

    private var metricStripView: some View {
        WrappingHStack(spacing: Spacing.paired) {
            ForEach(Array(metricStrip.enumerated()), id: \.element.id) { index, token in
                if index > 0 {
                    Text("·")
                        .font(Typography.caption)
                        .foregroundStyle(ColorRole.textTertiary)
                }
                Text(token.text)
                    .font(Typography.caption)
                    .foregroundStyle(metricColor(token))
                    .strikethrough(token.struck, color: ColorRole.textTertiary)
            }
        }
        .padding(.top, Spacing.paired)
        .overlay(alignment: .top) { Divider().overlay(ColorRole.separator) } // the strip's hairline top rule
        .accessibilityHidden(true)
    }

    private func metricColor(_ token: MetricToken) -> Color {
        if token.struck { return ColorRole.textTertiary }
        return token.emphasis ? ColorRole.textPrimary : ColorRole.textSecondary
    }

    // MARK: Lockline — lock glyph + mono reason (the `.off` state's strip replacement)

    private func lockline(reason: String) -> some View {
        HStack(spacing: Spacing.paired) {
            Image(systemName: "lock")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textTertiary)
            Text(reason)
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.paired)
        .overlay(alignment: .top) { Divider().overlay(ColorRole.separator) }
        .accessibilityHidden(true)
    }

    // MARK: Diagram column — a hairline column rule + the embedded diagram

    private var diagramColumn: some View {
        diagramBody
            .frame(maxHeight: .infinity)
            .padding(.leading, Spacing.itemGap)
            // A column rule between the content and the diagram — a structural hairline between two regions
            // of one card (J-4.3 emphasis from space, not a side-tab border — J-8).
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(ColorRole.separator)
                    .frame(width: 1)
            }
    }

    @ViewBuilder private var diagramBody: some View {
        switch diagram {
        case let .fixedDays(filled, dim):
            FixedDaysDiagram(filled: filled, dim: dim)
        case let .coverBucket(dayCounts):
            CoverBucketDiagram(dayCounts: dayCounts, isLocked: isLocked)
        case let .rankedBars(values, dim, pick):
            RankedBarsDiagram(values: values, dim: dim, pick: pick)
        }
    }

    // MARK: Selected — a single ink check pill, never an accent fill (J-2.4)

    @ViewBuilder private var selectionMark: some View {
        if showsSelected {
            Image(systemName: "checkmark")
                .font(Typography.caption.weight(.bold))
                .foregroundStyle(ColorRole.textOnAccent)
                .padding(Spacing.paired)
                .background(ColorRole.textPrimary, in: .circle) // ink pill, not the accent
                .padding(Spacing.itemGap)
                .accessibilityIdentifier("tripshape.\(id).check")
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Accessibility helper — locked cards get a hint (and aren't an actionable element)

/// A locked card surfaces its reason as a VoiceOver hint and is NOT given the button trait (the `SelectAction`
/// modifier adds `.isButton` only for an unlocked card), so it reads as inert (J-2.4 / 06-screens a11y).
private struct LockedAccessibility: ViewModifier {
    let reason: String?

    func body(content: Content) -> some View {
        if let reason {
            content.accessibilityHint(reason)
        } else {
            content
        }
    }
}

// MARK: - The select gesture — present only for an unlocked card (a locked card isn't actionable)

private struct SelectAction: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onTapGesture(perform: action)
                .accessibilityAddTraits(.isButton)
        } else {
            content
        }
    }
}

// MARK: - Surface for the register — selected lifts (cardSurface + ink ring); unselected/locked recede flat

/// Applies the register's surface. Selected (selectable) → `.cardSurface()` + a 2pt `textPrimary` ink ring
/// (mockup `.scard.sel` = `surface-grouped` + `shadow-rest` + `0 0 0 2px var(--ink-900)`). Unselected and
/// locked → the SAME footprint (same inset, same `Radius.card` corner) on a flat `surfacePage` fill with NO
/// shadow (mockup `.scard` = `paper-100`, no shadow), so registers share one footprint (no reflow; J-9.3).
private struct TripShapeSurface: ViewModifier {
    let register: TripShapeRegister
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .cardSurface()
                .overlay {
                    // The selected ink ring — 2pt `textPrimary`, the certainty cue (NOT the accent, J-2.4).
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(ColorRole.textPrimary, lineWidth: Stroke.selected)
                }
        } else {
            content
                .padding(Spacing.cardInset)
                .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
                .containerShape(.rect(cornerRadius: Radius.card))
        }
    }
}

// MARK: - Diagram 1 — Fixed days (columns of dots, trailing dimmed)

/// Columns of dots — the day budget. Each column shows `filled` solid dots then `dim` receded dots, stacked
/// bottom-up (mockup `.d-fixed`: `.dt` solid `ink-700`, `.dt.dim` receded `ink-300`). Categorical, no fills
/// of size — just presence/absence of a day's dots (J-2).
private struct FixedDaysDiagram: View {
    let filled: [Int]
    let dim: [Int]

    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = 5

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.hairline) {
            ForEach(Array(filled.enumerated()), id: \.offset) { index, filledCount in
                column(filled: filledCount, dim: dim.indices.contains(index) ? dim[index] : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func column(filled: Int, dim: Int) -> some View {
        VStack(spacing: Spacing.hairline) {
            ForEach(0 ..< dim, id: \.self) { _ in dot(ColorRole.separatorOpaque) }
            ForEach(0 ..< filled, id: \.self) { _ in dot(ColorRole.textSecondary) }
        }
        .padding(.vertical, Spacing.hairline)
        .frame(maxWidth: .infinity)
        .background(ColorRole.fillTertiary, in: .rect(cornerRadius: Radius.thumb))
    }

    private func dot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: dotSize, height: dotSize)
    }
}

// MARK: - Diagram 2 — Cover the bucket (5-col grid of day-colored marks)

/// A 5-column grid of day-COLORED dots — counts per neighborhood mark, expanded in run order across the grid
/// (mockup `.d-cover`: `.c1…c4` = `day-1…4`, `.c5` = a neutral 5th). These are categorical marks, never fills
/// of size (J-2 / 02-color §2). When locked, every dot collapses to a neutral receded mark (mockup
/// `.scard.off .d-cover .dt { background: ink-200 }`).
private struct CoverBucketDiagram: View {
    /// Counts per mark (index 0→mark1 … 4→neutral 5th). Expanded into a flat dot list in run order.
    let dayCounts: [Int]
    let isLocked: Bool

    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = 7

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.hairline), count: 5)

    /// The categorical palette: the four day marks + a neutral 5th (mockup `.c5 = ink-400`).
    private func markColor(_ markIndex: Int) -> Color {
        switch markIndex {
        case 0: ColorRole.dayMark1
        case 1: ColorRole.dayMark2
        case 2: ColorRole.dayMark3
        case 3: ColorRole.dayMark4
        default: ColorRole.textTertiary
        }
    }

    /// Flatten the per-mark counts into (color) dots in run order.
    private var dots: [Color] {
        var out: [Color] = []
        for (markIndex, count) in dayCounts.enumerated() {
            let color = isLocked ? ColorRole.separatorOpaque : markColor(markIndex)
            out.append(contentsOf: Array(repeating: color, count: max(0, count)))
        }
        return out
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.hairline) {
            ForEach(Array(dots.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

// MARK: - Diagram 3 — Ranked bars (rotated-square mark + width-% bar per row)

/// Rows of a rotated-square mark + a width-fraction bar — the ranking (mockup `.d-high`). `pick` highlights
/// one row's mark to a mid ink, `dim` recedes one row's mark + bar fill (mockup `.r.pick` / `.r.dim`).
private struct RankedBarsDiagram: View {
    /// Per-row bar fill as a 0…1 fraction of the track width.
    let values: [Double]
    let dim: Int?
    let pick: Int?

    @ScaledMetric(relativeTo: .caption2) private var markSize: CGFloat = 7
    @ScaledMetric(relativeTo: .caption2) private var barHeight: CGFloat = 3

    var body: some View {
        VStack(spacing: Spacing.paired) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                row(value: value, isDim: index == dim, isPick: index == pick)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func row(value: Double, isDim: Bool, isPick: Bool) -> some View {
        HStack(spacing: Spacing.paired) {
            RoundedRectangle(cornerRadius: Radius.tag)
                .fill(markColor(isDim: isDim, isPick: isPick))
                .frame(width: markSize, height: markSize)
                .rotationEffect(.degrees(45))
            GeometryReader { proxy in
                Capsule()
                    .fill(ColorRole.fillTertiary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(isDim ? ColorRole.separatorOpaque : ColorRole.textSecondary)
                            .frame(width: max(0, min(1, value)) * proxy.size.width)
                    }
            }
            .frame(height: barHeight)
        }
    }

    private func markColor(isDim: Bool, isPick: Bool) -> Color {
        if isDim { return ColorRole.separatorOpaque }
        if isPick { return ColorRole.textTertiary }
        return ColorRole.textSecondary
    }
}

// MARK: - WrappingHStack — a tiny flow layout for the metric strip fragments (no fixed frame; J-0.3)

/// Lays its subviews left-to-right, wrapping to the next line when the row is full. Used by the metric strip
/// so fragments + middots flow at any Dynamic Type size rather than truncating (mockup `.prev` = `flex-wrap`).
private struct WrappingHStack: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                maxRowWidth = max(maxRowWidth, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        maxRowWidth = max(maxRowWidth, rowWidth)
        return CGSize(width: min(maxRowWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Previews — one per meaningful state (05-design-system §8, §10)

#Preview("A — selected · stepper · fixed days") {
    TripShapeCard(
        id: "a",
        eyebrow: "A · Fixed days",
        title: "Pack four great days.",
        metricStrip: [
            MetricToken("hits 14 of 23", emphasis: true),
            MetricToken("skips 9", struck: true),
        ],
        diagram: .fixedDays(filled: [4, 3, 4, 2], dim: [0, 0, 0, 1]),
        register: .selectable,
        isSelected: true,
        embeddedControl: AnyView(
            Text("− 4 days +")
                .font(Typography.footnote)
                .foregroundStyle(ColorRole.textPrimary)
                .padding(.vertical, Spacing.paired)
                .padding(.horizontal, Spacing.itemGap)
                .background(ColorRole.fillSecondary, in: .capsule)
        ),
        onSelect: {}
    )
    .padding(Spacing.screenInset)
    .background(ColorRole.surfacePage)
}

#Preview("B — locked · cover bucket") {
    TripShapeCard(
        id: "b",
        eyebrow: "B · Cover the bucket",
        title: "Hit everything you saved.",
        diagram: .coverBucket(dayCounts: [3, 4, 4, 5, 7]),
        register: .locked(reason: "Save places in Kyoto to unlock")
    )
    .padding(Spacing.screenInset)
    .background(ColorRole.surfacePage)
}

#Preview("C — unselected · ranked bars") {
    TripShapeCard(
        id: "c",
        eyebrow: "C · Just the highlights",
        title: "The best of yours, plus the unmissable.",
        metricStrip: [
            MetricToken("top 14 of yours", emphasis: true),
            MetricToken("+ 3 picks"),
        ],
        diagram: .rankedBars(values: [0.92, 0.78, 0.64, 0.58, 0.34], dim: 4, pick: 3),
        register: .selectable,
        isSelected: false,
        onSelect: {}
    )
    .padding(Spacing.screenInset)
    .background(ColorRole.surfacePage)
}
