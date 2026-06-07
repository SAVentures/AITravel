// AccessPassCardSnapshotTests.swift — Layer 3 render-snapshot lock for AccessPassCard + QRCodeView.
//
// These tests are the lock on AccessPassCard and QRCodeView at authoring time. They do not verify
// the design (that is the fidelity-reviewer's job); they freeze the accepted render so any later
// change that silently moves a pixel — band icon tint, kind/title/subtitle typography, QR matrix,
// confirmation mono label, meta-cell hairline grid, Shadow.hero depth — fails the build.
// (07-testing §6 governing doc.)
//
// *** COORDINATOR NOTE — CoreImage offscreen-render risk ***
// AccessPassCard uses Shadow.hero (a UIKit drop-shadow applied via the UIHostingController path)
// and QRCodeView uses CoreImage.CIQRCodeGenerator. Both features MAY render blank or absent in
// the offscreen UIHostingController host (the documented framework gap: §6.5, decisions.md
// 2026-06-06 — the same path that causes glass/over-hero screens to produce blank frames).
// The QR specifically uses a software-renderer CIContext (.useSoftwareRenderer: true), which
// was chosen to maximise offscreen-render stability, but a blank QR block is still possible.
// The coordinator MUST visually inspect the recorded PNGs:
//   · If the QR renders (black matrix visible): commit and the lock is valid.
//   · If the QR block is blank/grey (CoreImage nil fallback): defer the QR column of the card
//     snapshot, document in decisions.md, and rely on the QRCodeView standalone snapshot (below)
//     as the CoreImage health-check.
//   · If the entire card is blank (Shadow.hero host gap): defer AccessPassCard to the
//     drawHierarchy/key-window path (decisions.md 2026-06-06 precedent).
// Do NOT commit a blank baseline — a blank PNG is false confidence, not a lock.
//
// States covered (one snapshot each, per 07-testing §6.2):
//   boarding-pass            — the TP 201 card (faithful to access-card.html): transport-tinted
//                              band icon tile + "Boarding pass" kind + "LIS → JFK · TP 201"
//                              title + "Zé Maria · Sat, Aug 29 · boards 13:05" subtitle +
//                              QR (payload "TP201|LIS-JFK|7XQK2M") + "7XQK2M" mono cap +
//                              Gate 24 / Seat 14A / Zone 2 meta grid.
//                              Presented on ink-900 dark ground (matching the immersive takeover
//                              context from the access-card mockup).
//   boarding-pass-ax5        — AX5 compensating snapshot (§7.4). Same card fixture at
//                              .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling
//                              of the @ScaledMetric band icon tile (Sizing.Component.accessIconTile)
//                              and QR side (Sizing.Component.accessQRSide), the band title/subtitle
//                              text, and the meta-grid key/value labels at the largest a11y category.
//   qr-fixed-payload         — Isolated QRCodeView with the fixed TP 201 payload. Deterministic:
//                              "TP201|LIS-JFK|7XQK2M" → identical matrix → identical pixels.
//                              This is the CoreImage health-check snapshot: if this one renders
//                              (black matrix visible on paper-0), CoreImage works offscreen and
//                              the boarding-pass card's QR column should also render correctly.
//                              If THIS is blank, CoreImage is not rendering offscreen in the
//                              current simulator; the coordinator defers both and opens a
//                              drawHierarchy path investigation.
//
// Determinism (07-testing §6.4):
//   · No Date() — all are pure display components; no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · QR generation: CIQRCodeGenerator is a pure function of payload bytes — fixed payload
//     "TP201|LIS-JFK|7XQK2M" → byte-identical output on every run.
//   · .useSoftwareRenderer: true in QRCodeView.context maximises offscreen stability.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror AccessPassModel.boardingPass + QRCodeView #Preview exactly.
//   · No SampleData required — AccessPassModel/QRCodeView take value-type args.
//
// Baselines land in __Snapshots__/AccessPassCardSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded".
// Do NOT leave record: .all in committed code (§6.3).
// Do NOT commit blank baselines — see coordinator note above.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("AccessPassCard + QRCodeView snapshots")
struct AccessPassCardSnapshotTests {

    // MARK: - Shared fixture (mirrors AccessPassModel.boardingPass in AccessPassCard.swift)
    //
    // @MainActor static var: AccessPassModel init is MainActor-isolated (Swift 6.2
    // MainActor-by-default module). All consumer test methods are @MainActor. (§6.6)

    @MainActor static var boardingPassModel: AccessPassModel {
        AccessPassModel(
            kindLabel: "Boarding pass",
            title: "LIS → JFK · TP 201",
            subtitle: "Zé Maria · Sat, Aug 29 · boards 13:05",
            type: .transport,
            systemImage: BookingType.transport.systemImage,
            qrPayload: "TP201|LIS-JFK|7XQK2M",
            confirmation: "7XQK2M",
            metaCells: [
                PlaceFacts(key: "Gate", value: "24", sub: nil),
                PlaceFacts(key: "Seat", value: "14A", sub: nil),
                PlaceFacts(key: "Zone", value: "2", sub: nil),
            ]
        )
    }

    // MARK: - boarding-pass

    /// AccessPassCard: TP 201 boarding pass, transport-tinted band.
    /// Renders (if CoreImage + Shadow.hero work offscreen):
    ///   Band — transport (airplane) icon tile (tinted) + "Boarding pass" mono kind +
    ///          "LIS → JFK · TP 201" display title + "Zé Maria · Sat, Aug 29 · boards 13:05".
    ///   QR block — CoreImage "TP201|LIS-JFK|7XQK2M" matrix + "7XQK2M" selectable mono cap.
    ///   Meta grid — Gate/24, Seat/14A, Zone/2 (PlaceInfoGrid hairline columns).
    ///   Shadow.hero lift on the paper-0 card over the dark (ink-900) ground.
    /// Presented on the dark immersive ground matching the access-card.html context.
    ///
    /// COORDINATOR: inspect the recorded PNG — QR + shadow may render blank. See file header.
    @Test("boarding-pass — transport band + QR (TP201 payload) + meta grid + hero shadow on dark ground")
    @MainActor func boardingPass() {
        assertDesignSnapshot(
            cardCanvas {
                AccessPassCard(
                    model: Self.boardingPassModel,
                    accessibilityID: "accesscard.pass"
                )
            },
            named: "boarding-pass"
        )
    }

    // MARK: - boarding-pass-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as boarding-pass at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric
    /// band icon tile (Sizing.Component.accessIconTile) and QR side (Sizing.Component.accessQRSide),
    /// the band title/subtitle text, the mono confirmation cap, and the Gate/Seat/Zone meta
    /// grid key/value labels at the largest accessibility size category.
    ///
    /// COORDINATOR: inspect the recorded PNG — QR + shadow may render blank. See file header.
    @Test("boarding-pass-ax5 — AX5: @ScaledMetric icon + QR side + band text + meta grid at accessibilityXXXL")
    @MainActor func boardingPassAX5() {
        assertDesignSnapshot(
            cardCanvas {
                AccessPassCard(
                    model: Self.boardingPassModel,
                    accessibilityID: "accesscard.pass"
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "boarding-pass-ax5"
        )
    }

    // MARK: - qr-fixed-payload

    /// Isolated QRCodeView: the CoreImage health-check snapshot.
    /// Renders the TP 201 payload "TP201|LIS-JFK|7XQK2M" as a QR matrix.
    /// A fixed payload → identical bytes → identical matrix → identical pixels on every run.
    /// The QR is rendered via CIQRCodeGenerator with .useSoftwareRenderer: true, nearest-
    /// neighbour upscaled (no smoothing), black on a clear ground over paper-0.
    ///
    /// COORDINATOR: this snapshot isolates the CoreImage offscreen-render question from the
    /// full card. If this PNG shows a black QR matrix: CoreImage works offscreen here → the
    /// card snapshot's QR column should also render. If this is blank (grey fillTertiary
    /// fallback or empty): CoreImage is not rendering offscreen → defer both this and the card
    /// snapshots and open a drawHierarchy/key-window path investigation.
    @Test("qr-fixed-payload — CoreImage health-check: TP201 payload → deterministic matrix (no smoothing)")
    @MainActor func qrFixedPayload() {
        assertDesignSnapshot(
            qrCanvas {
                QRCodeView(payload: "TP201|LIS-JFK|7XQK2M")
                    .frame(
                        width: Sizing.Component.accessQRSide,
                        height: Sizing.Component.accessQRSide
                    )
            },
            named: "qr-fixed-payload"
        )
    }
}

// MARK: - Canvas helpers

/// Wraps the AccessPassCard in the dark immersive context matching access-card.html,
/// with screenInset padding and centered layout (mirrors the #Preview fixture).
@MainActor
private func cardCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorRole.textPrimary)
}

/// Wraps the isolated QRCodeView in a surfacePage canvas (paper-0 ground so black modules
/// are visible, confirming CoreImage rendered a non-empty matrix).
@MainActor
private func qrCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(ColorRole.surfacePage)
}
