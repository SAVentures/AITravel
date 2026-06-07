// MapSnippet.swift — the place-detail static map well (05-design-system.md §8; J-8 / J-12.4).
// Ports the place-detail mockup `.map-snip`: a static graph-paper map canvas with a centered location pin,
// over an address bar carrying the address line and a "Directions" affordance.
//
// NO live MapKit this milestone — the canvas is a deterministic placeholder, mirroring `BaseMapCard`'s
// snapshotMode treatment (live tiles are non-deterministic and would flake an L3 snapshot — J-12.4). A
// real screen can swap a live `Map` behind the same footprint later; the component ships the placeholder.
//
// CONTENT surface, so NEVER glass (J-0.1 / J-8): the canvas + address bar are solid surfaces. The accent
// appears here only as the location pin (a single state mark) and the "Directions" link color
// (`actionPrimary`) — both paired with a glyph/label, never color alone (02-color §6).
//
// D-3: the "Directions" affordance only WIRES a caller closure (Maps hand-off) — none is built this
// milestone. The component owns the a11y mechanism; the caller owns the id VALUE (05 §8.1): the affordance
// carries the single stable id `mapsnippet.directions` (one map snippet per detail).
//
// Value-type fixture in (an address string) — no AppStore, no domain object (05 §8). SEMANTIC tokens only.
import SwiftUI

/// A static map snippet: a graph-paper placeholder canvas with a centered pin, an address line, and a
/// "Directions" affordance. Screen-agnostic — a value-type fixture in, no `AppStore` (05 §8).
struct MapSnippet: View {

    /// The address line shown in the bar, e.g. "R. dom Pedro V 129, Príncipe Real".
    let address: String
    /// D-3: wired to hand off to Maps; the component builds no hand-off. Empty for a non-interactive preview.
    var onDirections: () -> Void = {}

    /// The canvas height — a non-text metric, so it scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var canvasHeight: CGFloat = Sizing.Component.mapSnippetCanvas

    var body: some View {
        VStack(spacing: 0) {
            canvas
            addressBar
        }
        .clipShape(.rect(cornerRadius: Radius.card))
        .accessibilityIdentifier("mapsnippet")
    }

    // MARK: Canvas — a static graph-paper placeholder + a centered pin (mockup `.map-snip .canvas`)

    private var canvas: some View {
        ZStack {
            ColorRole.surfacePage
            GraphPaper(pitch: gridPitch).stroke(ColorRole.separator, lineWidth: gridLine)
            // The location pin — the accent as a single state mark, paired with its glyph (02-color §6).
            Image(systemName: "mappin")
                .font(Typography.title)
                .foregroundStyle(ColorRole.actionPrimary)
        }
        .frame(height: canvasHeight)
        .frame(maxWidth: .infinity)
        // Decorative context: collapse to one labeled element so the grid/pin aren't loose a11y nodes.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of \(address)")
    }

    // MARK: Address bar — the address line + the "Directions" affordance (mockup `.map-snip .addr`)

    private var addressBar: some View {
        HStack(spacing: Spacing.md) {
            Text(address)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            directionsButton
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(ColorRole.surfacePage)
    }

    /// "Directions" — D-3 wire-only. A mono-caps link in the action color with a leading send glyph
    /// (mockup `.addr .go`). Inline text link, so the accent reads as a link, not a fill (02-color §6).
    private var directionsButton: some View {
        Button(action: onDirections) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "location.fill")
                Text("Directions")
                    .tracking(Typography.trackCapsCaption)
                    .textCase(.uppercase)
            }
            .font(Typography.caption)
            .foregroundStyle(ColorRole.actionPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mapsnippet.directions")
        .accessibilityLabel("Directions to \(address)")
    }

    /// The graph-paper grid line — a non-text metric, scales with Dynamic Type (T-6.4).
    @ScaledMetric(relativeTo: .body) private var gridLine: CGFloat = Stroke.separator

    /// The graph-paper grid pitch — a non-text metric, scales with Dynamic Type (T-6.4). Read here on the
    /// MainActor and passed into the (nonisolated) `Shape`, since `Sizing.Component` is MainActor-isolated.
    @ScaledMetric(relativeTo: .body) private var gridPitch: CGFloat = Sizing.Component.mapSnippetGridPitch

    /// A repeating square grid — the static "map" texture (mockup's repeating-linear-gradient lines).
    /// Pitch is the mockup's `26px`, snapped to an on-grid 4pt multiple (28); supplied by the View body
    /// (the token is MainActor-isolated, so it's captured there and stored, not read in `path(in:)`).
    private struct GraphPaper: Shape {
        let pitch: CGFloat
        func path(in rect: CGRect) -> Path {
            var path = Path()
            var x = rect.minX
            while x <= rect.maxX {
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
                x += pitch
            }
            var y = rect.minY
            while y <= rect.maxY {
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
                y += pitch
            }
            return path
        }
    }
}

// MARK: - Preview — the static snippet (05 §8, §10)

#Preview("MapSnippet") {
    MapSnippet(address: "R. dom Pedro V 129, Príncipe Real")
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
