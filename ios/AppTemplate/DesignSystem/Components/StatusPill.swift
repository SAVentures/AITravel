// StatusPill.swift — the booking status pill: a small mono-caps capsule that carries a booking's
// temporal status (Upcoming · Today · Now · Past) by per-status fill (05-components §5). Ports the mockup
// `.pill` (wallet-shell.css §"Status pill"): a `Radius.pill` capsule, a short MONO caps label
// (`Typography.caption`, caps tracking at the call site — T-5.2), each status a distinct neutral/accent
// ground — never a side-border or gradient (§5.1, J-2.4, 08-slop A-1/C-1).
//
// The four registers (mockup `.pill.upcoming/.today/.now/.past`):
//   • upcoming — neutral `fillTertiary` ground, `textSecondary` label.
//   • today    — `textPrimary` ground, `textOnAccent` inverse label (the dark register).
//   • now      — the ONE accent ground (`stateNow` = accent-500) + `textOnAccent` label + a leading live
//                dot, paired with the label, never colour alone (02-color §6). The dot is STATIC here
//                (OD-2: the continuous pulse is DEFERRED — the screen that owns a live "now" adds it,
//                budgeted ≤1 continuous motion/screen + Reduce-Motion-gated; the component renders it
//                static so it stays snapshot-safe).
//   • past     — transparent ground, `textTertiary` label, no horizontal padding (a quiet inline mark).
//
// Content, never glass (J-0.1); content-hugging, Dynamic Type (J-0.3). Semantic tokens only. The pill's
// text IS its label; a parent row that already speaks the status hides it via `hidesFromAccessibility`
// (the component owns the `.accessibilityHidden` mechanism; the CALLER owns the decision — default false).
import SwiftUI

struct StatusPill: View {

    private let status: BookingStatus
    private let hidesFromAccessibility: Bool

    /// - Parameters:
    ///   - status: the booking's temporal status — drives the label, fill, and (for `.now`) the live dot.
    ///   - hidesFromAccessibility: when the parent (e.g. `BookingRow`) already announces the status as part
    ///     of a combined element, pass `true` so the pill isn't read twice. Defaults to `false` — a
    ///     standalone pill IS its own label (the caller owns this decision; the component owns the means).
    init(status: BookingStatus, hidesFromAccessibility: Bool = false) {
        self.status = status
        self.hidesFromAccessibility = hidesFromAccessibility
    }

    /// The leading live dot for the `.now` status, scaled with the caption text style so it tracks Dynamic
    /// Type (mirrors `Tag`'s now-dot — `Sizing.dot` relative to `.caption2`).
    @ScaledMetric(relativeTo: .caption2) private var dotSize: CGFloat = Sizing.dot

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if status == .now {
                // STATIC live dot (OD-2: pulse deferred to the owning screen). Paired with the label below,
                // so the status is never colour alone (02-color §6).
                Circle()
                    .fill(ColorRole.textOnAccent)
                    .frame(width: dotSize, height: dotSize)
            }
            Text(status.displayLabel.uppercased())
                .font(Typography.caption)
                .tracking(Typography.trackCapsCaption)
                .foregroundStyle(labelColor)
        }
        // Content-hugging capsule — the mockup `.pill` `padding: 4px 8px`; `.past` drops the horizontal
        // pad (an inline mark, not a chip). J-0.3: content drives size, no fixed frame.
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, status == .past ? 0 : Spacing.sm)
        .background(fill, in: .rect(cornerRadius: Radius.pill))
        // Colour is paired with the label, so the status is announced as text — never colour alone.
        .accessibilityElement(children: .combine)
        // The component OWNS the hide mechanism; the caller owns whether to hide (default: speak it).
        .accessibilityHidden(hidesFromAccessibility)
    }

    /// The per-status capsule ground (mockup `.pill.<status>` background).
    private var fill: Color {
        switch status {
        case .upcoming: ColorRole.fillTertiary
        case .today:    ColorRole.textPrimary
        case .now:      ColorRole.stateNow
        case .past:     .clear
        }
    }

    /// The per-status label ink (mockup `.pill.<status>` color).
    private var labelColor: Color {
        switch status {
        case .upcoming: ColorRole.textSecondary
        case .today:    ColorRole.textOnAccent
        case .now:      ColorRole.textOnAccent
        case .past:     ColorRole.textTertiary
        }
    }
}

// MARK: - Preview

#Preview("StatusPill — four registers") {
    HStack(spacing: Spacing.sm) {
        StatusPill(status: .upcoming)
        StatusPill(status: .today)
        StatusPill(status: .now)
        StatusPill(status: .past)
    }
    .padding(Spacing.lg)
    .background(ColorRole.surfacePage)
}
