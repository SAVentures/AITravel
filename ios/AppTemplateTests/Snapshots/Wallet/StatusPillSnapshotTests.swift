// StatusPillSnapshotTests.swift — Layer 3 render-snapshot lock for StatusPill.
//
// These tests are the lock on StatusPill at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — fill color, label ink, capsule padding, now-dot size —
// fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   upcoming   — fillTertiary ground, textSecondary label. The quiet neutral register.
//   today      — textPrimary (ink-900) ground, textOnAccent inverse label. The dark register.
//   now        — stateNow accent ground, textOnAccent label, STATIC leading live dot (OD-2).
//                The dot is static here — snapshot-safe. Confirms accent fill + dot + label
//                co-occur (never color alone, 02-color §6).
//   past       — transparent ground, textTertiary label, no horizontal padding. The quiet inline mark.
//   now-ax5    — AX5 compensating snapshot (§7.4). Same fixture as the "now" pill at
//                .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                @ScaledMetric now-dot (Sizing.dot relative to .caption2) and the caption
//                label at the largest accessibility size category. Glass-free — renders fully.
//
// The now-dot is STATIC by design (OD-2 deferral): the continuous pulse lives at the screen
// that owns the live "now" moment; the component renders the dot at rest. This makes every
// StatusPill snapshot unconditionally stable (no mid-flight flake).
//
// Determinism (07-testing §6.4):
//   · No Date() — StatusPill is a pure display component with no clock dependency.
//   · No withAnimation — dot is static; snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · No SampleData required — StatusPill takes BookingStatus directly.
//
// Baselines land in __Snapshots__/StatusPillSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("StatusPill snapshots")
struct StatusPillSnapshotTests {

    // MARK: - upcoming

    /// StatusPill .upcoming — the neutral quiet register.
    /// Renders: fillTertiary capsule ground + "UPCOMING" caption label in textSecondary.
    /// No dot. Confirms the quiet register looks distinct from today's dark ground.
    @Test("upcoming — fillTertiary ground + textSecondary label, no dot")
    @MainActor func upcoming() {
        assertDesignSnapshot(
            pillCanvas { StatusPill(status: .upcoming) },
            named: "upcoming"
        )
    }

    // MARK: - today

    /// StatusPill .today — the dark inverse register.
    /// Renders: textPrimary (ink-900) capsule ground + "TODAY" caption label in textOnAccent (inverse).
    /// No dot. Confirms the dark-ground register is visually distinct from upcoming and now.
    @Test("today — textPrimary dark ground + textOnAccent inverse label, no dot")
    @MainActor func today() {
        assertDesignSnapshot(
            pillCanvas { StatusPill(status: .today) },
            named: "today"
        )
    }

    // MARK: - now

    /// StatusPill .now — the accent live-moment register with a STATIC leading dot.
    /// Renders: stateNow (accent-500) capsule ground + white static leading circle dot +
    /// "NOW" caption label in textOnAccent.
    /// The dot is STATIC (OD-2: pulse deferred to the owning screen). Confirms the dot +
    /// accent ground + label all co-occur in one frame (never color alone, 02-color §6).
    @Test("now — accent ground + static live-dot + textOnAccent label: dot + fill + label co-occur")
    @MainActor func now() {
        assertDesignSnapshot(
            pillCanvas { StatusPill(status: .now) },
            named: "now"
        )
    }

    // MARK: - past

    /// StatusPill .past — the transparent quiet inline mark.
    /// Renders: clear/transparent background + "PAST" caption label in textTertiary +
    /// no horizontal capsule padding (the mockup `.pill.past` drops pad to make it inline).
    /// Confirms the absence of capsule shape when the past pill appears inline in a row.
    @Test("past — transparent ground + textTertiary label + no horizontal pad (inline inline mark)")
    @MainActor func past() {
        assertDesignSnapshot(
            pillCanvas { StatusPill(status: .past) },
            named: "past"
        )
    }

    // MARK: - now-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as "now" at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric
    /// now-dot (Sizing.dot relative to .caption2) and the "NOW" caption label at the
    /// largest accessibility size category. The dot must remain proportional.
    /// Glass-free component — renders fully at AX5.
    @Test("now-ax5 — AX5: @ScaledMetric dot + caption label scale at accessibilityXXXL")
    @MainActor func nowAX5() {
        assertDesignSnapshot(
            pillCanvas { StatusPill(status: .now) }
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "now-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a StatusPill in a surfacePage canvas for isolated component rendering.
/// Uses leading alignment so the transparent `.past` pill isn't clipped into nothing.
@MainActor
private func pillCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
