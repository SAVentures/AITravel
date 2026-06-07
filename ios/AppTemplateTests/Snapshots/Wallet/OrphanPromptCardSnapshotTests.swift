// OrphanPromptCardSnapshotTests.swift — Layer 3 render-snapshot lock for OrphanPromptCard.
//
// These tests are the lock on OrphanPromptCard at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — accent-wash ground, ring, eyebrow mark, orphan row icon tile,
// AI italic suggestion line, Pin/Not-now button layout — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   fado             — the one meaningful state (per 05 §8, §10): the Fado at Tasca do Chico
//                      orphan card. Renders: accentWashFill ground + 1px accentWashRing border +
//                      mono-caps eyebrow ("1 BOOKING NOT YET PLACED") with an accent dot mark +
//                      activity-tinted orphan booking row (icon + name + meta) + italic AI
//                      suggestion line + "Pin to Day 2" primary PillButton + "Not now" ghost.
//                      Confirms the full accent-wash card, the orphan row, the AI line, and both
//                      actions all co-occur in one frame.
//   fado-ax5         — AX5 compensating snapshot (§7.4). Same fixture as "fado" at
//                      .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                      mono-caps eyebrow, the orphan booking name/meta, the italic suggestion
//                      text, and the PillButton labels at the largest accessibility size category.
//                      Glass-free card — renders fully at AX5.
//
// Accent budget note (J-2.4): the orphan card uses the accent as the wash ground + the dot +
// the primary Pin button — confirmed to be ≤2 on the populated wallet screen as a whole (the
// "now" pill is the other). This snapshot locks the card in isolation; the screen-level count
// is a design-reviewer concern at fidelity-review time.
//
// Determinism (07-testing §6.4):
//   · No Date() — OrphanPromptCard is a pure display component; no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the preview in OrphanPromptCard.swift exactly (OrphanPromptModel.fado).
//   · No SampleData required — OrphanPromptModel is a value type.
//
// Baselines land in __Snapshots__/OrphanPromptCardSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("OrphanPromptCard snapshots")
struct OrphanPromptCardSnapshotTests {

    // MARK: - Shared fixture (mirrors OrphanPromptModel.fado in OrphanPromptCard.swift)
    //
    // @MainActor static var: OrphanPromptModel init is MainActor-isolated (Swift 6.2
    // MainActor-by-default module); stored fixtures in a @MainActor suite are safe. (§6.6)

    @MainActor static var fadoModel: OrphanPromptModel {
        OrphanPromptModel(
            labelCaps: "1 BOOKING NOT YET PLACED",
            bookingName: "Fado at Tasca do Chico",
            bookingMeta: "Bairro Alto · confirmation TDC-8841",
            type: .activity,
            systemImage: BookingType.activity.systemImage,
            suggestionLine: "This reads like a **21:00 show** — it fits your **Day 2** evening, after dinner in Alfama.",
            pinTitle: "Pin to Day 2",
            dismissTitle: "Not now"
        )
    }

    // MARK: - fado

    /// OrphanPromptCard: the fado activity booking, not yet placed.
    /// Renders: accentWashFill ground + 1px accentWashRing + mono-caps eyebrow with accent dot +
    /// activity-tinted orphan row (ticket icon + "Fado at Tasca do Chico" + meta) +
    /// italic AI suggestion line + "Pin to Day 2" primary PillButton + "Not now" ghost.
    /// Confirms the full accent-wash card layout — wash ground, ring, orphan row, AI line,
    /// and both action buttons co-occur in one frame (no unit test can confirm co-occurrence).
    @Test("fado — full accent-wash card: wash ground + orphan row + AI line + pin/not-now actions")
    @MainActor func fado() {
        assertDesignSnapshot(
            cardCanvas {
                OrphanPromptCard(
                    model: Self.fadoModel,
                    onPin: {},
                    onDismiss: {},
                    onSelect: {},
                    pinAccessibilityID: "orphan.pin",
                    dismissAccessibilityID: "orphan.dismiss",
                    rowAccessibilityID: "orphan.row"
                )
            },
            named: "fado"
        )
    }

    // MARK: - fado-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as "fado" at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the mono-caps eyebrow
    /// label, the orphan booking name and meta text, the italic AI suggestion line, and both
    /// PillButton labels at the largest accessibility size category. Glass-free — renders fully.
    @Test("fado-ax5 — AX5: eyebrow + booking name/meta + AI line + button labels at accessibilityXXXL")
    @MainActor func fadoAX5() {
        assertDesignSnapshot(
            cardCanvas {
                OrphanPromptCard(
                    model: Self.fadoModel,
                    onPin: {},
                    onDismiss: {},
                    onSelect: {},
                    pinAccessibilityID: "orphan.pin",
                    dismissAccessibilityID: "orphan.dismiss",
                    rowAccessibilityID: "orphan.row"
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "fado-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the card in a surfacePage canvas matching the OrphanPromptCard #Preview padding.
@MainActor
private func cardCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
