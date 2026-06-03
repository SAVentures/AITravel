/*
 The step-02 trip-shape choice card. Ports `.scard` from
 mockups/screens/onboarding/state-a/b-screen-02-trip-shape.html: a strategy eyebrow + title, a mono
 consequence strip, and an embedded shape diagram in a trailing column.

 Mirrors PlaceCard's definitive/fuzzy register, but certainty is carried by elevation + a 2pt textPrimary
 ink ring/check — never the accent, never a side-border (J-8, J-2.4). `.locked` recedes to opacity 0.55
 and swaps the metric strip for a lockline; it is inert (not tappable, no button trait).
*/
import SwiftUI

// MARK: - The register — selectable vs locked, as a value-type arg

enum TripShapeRegister: Equatable, Sendable {
    case selectable
    case locked(reason: String)
}

// MARK: - The metric strip fragment — a mono consequence span

/// One mono fragment in the metric strip. `emphasis` darkens to ink; `struck` strikes through a skipped count.
struct MetricToken: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
    let emphasis: Bool
    let struck: Bool

    init(_ text: String, emphasis: Bool = false, struck: Bool = false) {
        self.id = text
        self.text = text
        self.emphasis = emphasis
        self.struck = struck
    }
}

// MARK: - The embedded diagram — the shape of each choice, as value args

enum TripShapeDiagram: Equatable, Sendable {
    /// Each (filled, dim) pair is one column of dots — the day budget; dim dots recede.
    case fixedDays(filled: [Int], dim: [Int])
    /// Counts per day mark, expanded into a 5-column grid of day-colored dots in run order.
    case coverBucket(dayCounts: [Int])
    /// Each value is a 0…1 bar-width fraction; `pick` highlights one row's mark, `dim` recedes one.
    case rankedBars(values: [Double], dim: Int?, pick: Int?)
}

// MARK: - TripShapeCard

struct TripShapeCard: View {
    /// Caller id suffix (`a`/`b`/`c`) → `tripshape.<id>` and `tripshape.<id>.check/.locked`.
    let id: String
    let eyebrow: String
    let title: String
    var metricStrip: [MetricToken] = []
    let diagram: TripShapeDiagram
    let register: TripShapeRegister
    var isSelected: Bool = false
    /// An optional inline control under the title (the DayStepper for card A); erased so the screen owns it.
    var embeddedControl: AnyView? = nil
    var onSelect: () -> Void = {}

    /// Scales with Dynamic Type rather than a fixed CGFloat (J-0.3). Seeded from the mockup's 100pt column.
    @ScaledMetric(relativeTo: .body) private var diagramColumnWidth: CGFloat = 100

    private var lockReason: String? {
        if case let .locked(reason) = register { return reason }
        return nil
    }

    private var isLocked: Bool { lockReason != nil }

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
        .accessibilityIdentifier(isLocked ? "tripshape.\(id).locked" : "tripshape.\(id)")
    }

    private var lockedOpacity: Double { 0.55 } // mockup `.scard.off { opacity: 0.55 }`

    // MARK: Content column

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

            Spacer(minLength: Spacing.paired) // push strip/lockline to the bottom (mockup `margin-top: auto`)

            if let lockReason {
                lockline(reason: lockReason)
            } else if !metricStrip.isEmpty {
                metricStripView
            }
        }
    }

    private var eyebrowLabel: some View {
        Text(eyebrow.uppercased())
            .font(Typography.caption)
            .tracking(Typography.trackEyebrowCaption)
            .foregroundStyle(ColorRole.textTertiary)
            .accessibilityHidden(true) // surfaced via the combined label
    }

    private var titleColor: Color {
        if isLocked { return ColorRole.textTertiary }
        return showsSelected ? ColorRole.textPrimary : ColorRole.textSecondary
    }

    // MARK: Metric strip

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
        .overlay(alignment: .top) { Divider().overlay(ColorRole.separator) }
        .accessibilityHidden(true)
    }

    private func metricColor(_ token: MetricToken) -> Color {
        if token.struck { return ColorRole.textTertiary }
        return token.emphasis ? ColorRole.textPrimary : ColorRole.textSecondary
    }

    // MARK: Lockline

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

    // MARK: Diagram column

    private var diagramColumn: some View {
        diagramBody
            .frame(maxHeight: .infinity)
            .padding(.leading, Spacing.itemGap)
            // A structural hairline between the two regions — emphasis from space, not a side-tab border (J-8).
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

    // MARK: Selected

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

// MARK: - Accessibility helper — locked cards get a hint

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

// MARK: - The select gesture — present only for an unlocked card

private struct SelectAction: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onTapGesture(perform: action)
                .accessibilityAddTraits(.isButton)
                // `.onTapGesture` only fires on a real touch; the explicit action makes the card
                // ACTIVATABLE by VoiceOver and XCUITest (the `.isButton` trait alone is a lie without it).
                .accessibilityAction { action() }
        } else {
            content
        }
    }
}

// MARK: - Surface for the register

/// Selected lifts to `.cardSurface()` + a 2pt ink ring; unselected/locked share the SAME footprint on a flat
/// `surfacePage` fill with no shadow, so the registers don't reflow (J-9.3).
private struct TripShapeSurface: ViewModifier {
    let register: TripShapeRegister
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .cardSurface()
                .overlay {
                    // The certainty cue is the ink ring, NOT the accent (J-2.4).
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

/// Categorical day marks, never fills of size (J-2 / 02-color §2); when locked every dot recedes to neutral.
private struct CoverBucketDiagram: View {
    /// Counts per mark (index 0→mark1 … 4→neutral 5th), expanded into a flat dot list in run order.
    let dayCounts: [Int]
    let isLocked: Bool

    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = 7

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.hairline), count: 5)

    private func markColor(_ markIndex: Int) -> Color {
        switch markIndex {
        case 0: ColorRole.dayMark1
        case 1: ColorRole.dayMark2
        case 2: ColorRole.dayMark3
        case 3: ColorRole.dayMark4
        default: ColorRole.textTertiary
        }
    }

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

// MARK: - WrappingHStack — a tiny flow layout for the metric strip fragments

/// Wraps subviews to the next line when a row is full, so the strip flows at any Dynamic Type size (J-0.3).
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

// MARK: - Previews

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
