// PillButton.swift — the tier-driven content button (05-components §1; J-6.1, J-9.1, J-11.3).
//
// One button, four hierarchy TIERS — the tier drives the look, never the reverse (§1.1). Ports the mockup
// `.btn` family (primary / secondary / ghost / destructive, components.html §01). CONTENT, never glass
// (J-0.1; glass is the bar/ActionBar only). Shape/size are TOKENS, never a fixed frame (§1.4, J-0.3): the
// 44pt hit target comes from padding, not a frame. Press commits in ≤100ms (§1, J-9.1). Label leads with a
// present-tense verb (§1.5, J-11.3). Semantic tokens only — zero literals, zero `Primitive.*`.
import SwiftUI

// MARK: - Tier (the value-type that drives the style · §1)

/// The button's hierarchy tier. The caller picks by INTENT — "is this *the* action, a lesser one, inline,
/// or destructive?" — and the style follows (§1.1, tier → style never the reverse).
enum PillButtonTier {
    /// The one action that matters in a region — the budgeted accent CTA (§1.3, J-6.1).
    case primary
    /// A real but lesser action beside the primary — a quiet grey well (§1).
    case secondary
    /// Low-stakes / inline ("See all") — transparent, no fill (§1).
    case ghost
    /// Irreversible / removing — system-red intent (§1.2, J-2). Pair with `Button(role: .destructive)`.
    case destructive
}

// MARK: - Component

/// A tier-driven content pill button. Leads with a present-tense verb (§1.5); covers default / pressed /
/// disabled / loading. Never glass (it is content, J-0.1).
struct PillButton: View {
    /// The label — a present-tense verb the user owns ("Borrow", "Return", not "Submit"; §1.5, J-11.3).
    let title: String
    /// The tier that drives the style (§1.1).
    let tier: PillButtonTier
    /// Optional leading SF Symbol, paired with the label.
    var systemImage: String?
    /// Swaps the label for an inline `ProgressView` at a stable footprint and disables input (§1 loading).
    var isLoading: Bool = false
    /// The tap handler.
    let action: () -> Void

    var body: some View {
        // Destructive carries the system role so assistive tech announces the intent (§1.2); the rest are
        // plain actions. The visual treatment is the tier's `PillButtonStyle` either way.
        Button(role: tier == .destructive ? .destructive : nil, action: action) {
            // Stable-footprint label: the title stays in the layout to hold the width; loading overlays a
            // spinner and hides the text, so nothing reflows when state flips (§1 loading).
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Typography.body.weight(.semibold))
            .opacity(isLoading ? 0 : 1)
            .overlay {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .accessibilityLabel(Text(title))
        }
        .buttonStyle(PillButtonStyle(tier: tier))
        .controlSize(.large)
        .disabled(isLoading)
        .allowsHitTesting(!isLoading)
    }
}

// MARK: - Style (tier → fill/label/press · §1.1, §1.4, J-9.1)

/// The `ButtonStyle` that renders a `PillButtonTier`. Owns the fill, the label color, the pill shape, the
/// padded 44pt hit target, and the ≤100ms press scale read from `configuration.isPressed` (§1, J-9.1).
private struct PillButtonStyle: ButtonStyle {
    let tier: PillButtonTier

    // The vertical padding that lifts the control to a ≥44pt tap target — scaled with the text so it holds
    // at large Dynamic Type (T-6.4); never a fixed frame (§1.4, J-0.3).
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = Spacing.md
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = Spacing.xl
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(labelColor)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, tier == .ghost ? Spacing.sm : horizontalPadding)
            .frame(minHeight: minTapTarget) // a MINIMUM, not a fixed height — content/Dynamic Type still grow it
            .background(background)
            .clipShape(.capsule) // pill via the shape role, not a corner literal
            .buttonBorderShape(.capsule)
            .contentShape(.capsule)
            // ≤100ms press commit — a ~0.985 scale read from the style's `isPressed`, before any animation (J-9.1).
            .scaleEffect(configuration.isPressed ? pressScale : 1)
            .animation(Motion.standard(Motion.tap), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : disabledOpacity)
    }

    // MARK: Tier → fill (§1.1)

    @ViewBuilder private var background: some View {
        switch tier {
        case .primary:
            // The one accent surface — the budgeted CTA (J-0.4/J-2.4).
            Capsule().fill(ColorRole.actionPrimary)
        case .secondary:
            // A quiet grey well — `--paper-200` in the mockup; the semantic well/grey ground here.
            Capsule().fill(ColorRole.fillTertiary)
        case .ghost:
            // Transparent — no fill (§1).
            Color.clear
        case .destructive:
            // A faint destructive wash; the label + role carry the red signal, not a solid fill (§1.2, J-2).
            Capsule().fill(ColorRole.destructive.opacity(destructiveWashOpacity))
        }
    }

    // MARK: Tier → label color (§1.1)

    private var labelColor: Color {
        switch tier {
        case .primary: ColorRole.textOnAccent
        case .secondary: ColorRole.textPrimary
        case .ghost: ColorRole.textSecondary
        case .destructive: ColorRole.destructive
        }
    }

    // MARK: Press / disabled / hit-target constants

    /// The ≤100ms press scale (§1, J-9.1) — the canonical ~0.985 commit.
    private let pressScale: CGFloat = 0.985
    /// Disabled emphasis reduction (read from the env, not a hand-dimmed color; §1 disabled state).
    private let disabledOpacity: CGFloat = 0.4
    /// The destructive fill is a faint wash (`color-mix … 9%` in the mockup `.btn.destructive`).
    private let destructiveWashOpacity: CGFloat = 0.1
    /// HIG minimum tap target — a floor, content still grows the control (§1; HIG).
    @ScaledMetric(relativeTo: .body) private var minTapTarget: CGFloat = Sizing.minTapTarget
}

// MARK: - Preview fixture (a tiny in-file value type · Wave-C rule)

/// A local value-type fixture for the previews and the Wave-E snapshots — verb-led titles per tier,
/// mirroring the mockup `.btn` labels. No domain object, no store (05 §8).
private struct PillButtonFixture {
    let title: String
    let tier: PillButtonTier
    var systemImage: String?

    static let primary = PillButtonFixture(title: "Save place", tier: .primary, systemImage: "bookmark")
    static let secondary = PillButtonFixture(title: "Preview route", tier: .secondary)
    static let ghost = PillButtonFixture(title: "See all", tier: .ghost)
    static let destructive = PillButtonFixture(title: "Remove from trip", tier: .destructive, systemImage: "trash")
}

private func previewButton(_ f: PillButtonFixture, isLoading: Bool = false) -> some View {
    PillButton(title: f.title, tier: f.tier, systemImage: f.systemImage, isLoading: isLoading) {}
}

#Preview("Primary") {
    previewButton(.primary)
        .padding()
}

#Preview("Primary — pressed") {
    // The press scale is a `ButtonStyle` state; this preview shows the resting target the press commits from.
    previewButton(.primary)
        .scaleEffect(0.985)
        .padding()
}

#Preview("Primary — disabled") {
    previewButton(.primary)
        .disabled(true)
        .padding()
}

#Preview("Primary — loading") {
    previewButton(.primary, isLoading: true)
        .padding()
}

#Preview("Secondary") {
    previewButton(.secondary)
        .padding()
}

#Preview("Ghost") {
    previewButton(.ghost)
        .padding()
}

#Preview("Destructive") {
    previewButton(.destructive)
        .padding()
}
