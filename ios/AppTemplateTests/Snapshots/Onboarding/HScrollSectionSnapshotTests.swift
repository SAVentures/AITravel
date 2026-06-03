// HScrollSectionSnapshotTests.swift — Layer 3 render-snapshot lock for HScrollSection.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// States covered (§6.2 — one snapshot per key state):
//   with-meta    — title + uppercase meta label in the eyebrow head; horizontal city-chip rail.
//                  Mirrors the "Recent rail" #Preview from HScrollSection.swift.
//   without-meta — title only (meta omitted); meta label is absent and title is the sole head.
//                  Mirrors the "Head-only meta omitted" #Preview from HScrollSection.swift.
//
// Both states lock the full composition: eyebrow head (title + optional meta), the ScrollView
// rail, the item chips, and the contentMargins edge inset. No unit test can confirm that these
// elements co-occur with the correct rhythm and spacing.
//
// HScrollSection is a generic composition primitive — it accepts any @ViewBuilder content. The
// representative items (city-name chips on surfacePage ground with Radius.row) match the preview
// fixtures exactly, so the baseline locks the same representative content the author reviewed.
//
// Ground: surfacePage background with vertical screenInset padding (matching the preview context).
//
// Determinism (§6.4):
//   - No Date() — HScrollSection carries no time state.
//   - No withAnimation — rendered at rest (horizontal scroll position is at leading edge).
//   - designSystemEnvironment() injects \.disablesOneShotMotion = true.
//   - Fixtures are static string arrays identical to the preview fixtures.
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("HScrollSection snapshots")
@MainActor
struct HScrollSectionSnapshotTests {

    // MARK: - Snapshots

    @Test("with-meta — eyebrow head (title + uppercase meta); horizontal chip rail")
    func withMeta() {
        assertDesignSnapshot(
            HScrollSection("Recent", meta: "Last 6 months", accessibilityIDPrefix: "rail.recent") {
                ForEach(["Lisbon", "Tokyo", "Mexico City", "Reykjavík"], id: \.self) { city in
                    VStack(alignment: .leading, spacing: Spacing.hairline) {
                        Text(city)
                            .font(Typography.name)
                            .foregroundStyle(ColorRole.textPrimary)
                        Text("Saved")
                            .font(Typography.caption)
                            .tracking(Typography.trackEyebrowCaption)
                            .textCase(.uppercase)
                            .foregroundStyle(ColorRole.textTertiary)
                    }
                    .padding(Spacing.cardInset)
                    .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
                }
            }
            .padding(.vertical, Spacing.screenInset)
            .background(ColorRole.surfaceGrouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
            named: "with-meta"
        )
    }

    @Test("without-meta — title-only eyebrow head; meta label absent; horizontal chip rail")
    func withoutMeta() {
        assertDesignSnapshot(
            HScrollSection("Other neighborhoods we weighed",
                           accessibilityIDPrefix: "rail.alts") {
                ForEach(["Bairro Alto", "Chiado", "Príncipe Real"], id: \.self) { name in
                    Text(name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                        .padding(Spacing.cardInset)
                        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.row))
                }
            }
            .padding(.vertical, Spacing.screenInset)
            .background(ColorRole.surfaceGrouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
            named: "without-meta"
        )
    }
}
