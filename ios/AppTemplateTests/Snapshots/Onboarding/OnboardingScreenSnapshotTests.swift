// OnboardingScreenSnapshotTests.swift — Layer 3 render-snapshot lock for the five onboarding step screens.
//
// These tests are the **lock** on each onboarding screen at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — spacing, color, font, icon, shadow — fails the build.
// (07-testing §6 governing doc.)
//
// Screens and states covered (one snapshot per meaningful state, per 07-testing §6.2):
//
//   DestinationStepView
//     destination-a   — state A: "Where are you headed?", 23 Lisbon saves, savedCount AI voice
//     destination-b   — state B: "Where are you headed?", Kyoto, 0-here saves, taste-reading AI voice
//     destination-c   — state C: "Where to first?", Lisbon first-trip AI voice (different question copy)
//     destination-a-ax5 — state A at .accessibility5 Dynamic Type (AX5 audit compensating control)
//
//   TripShapeStepView
//     tripshape-a     — state A: .shapeCards body, Lisbon 23 saves, all three cards unlocked
//     tripshape-b     — state B: .shapeCards body, Kyoto, "Cover the bucket" card locked
//     tripshape-c     — state C: .tasteForm body (structurally different — interest chips + pace picker)
//
//   BaseLocationStepView
//     baselocation-a  — state A: Alfama neighborhood, Lisbon map, 23 saves context
//     baselocation-b  — state B: Gion neighborhood, Kyoto map, taste-read context
//     baselocation-c  — state C: Baixa neighborhood, Lisbon map, first-trip context
//
//   GettingAroundStepView
//     gettingaround-a  — states A (Lisbon transit rec, rain note) — canonical for A
//     gettingaround-b  — state B: Kyoto transit rec, blossom-crowd note, ¥ fares
//     NOTE: state C uses the same lisbonTransportRec() as state A — identical presenter output
//           → C is merged with A; one snapshot is the lock for both.
//
//   GeneratingStepView
//     generating-a    — state A: 23-saves Lisbon plan, "Grouping your 23 places" first done step
//     generating-b    — state B: Kyoto plan, "Pulling Kyoto's best" first done step, ¥ context
//     generating-c    — state C: Lisbon first-trip plan, "Choosing Lisbon's best for food…" done step
//
// Determinism (07-testing §6.4):
//   · No Date() / live clock — all stores are seeded via AppStore.preview(_:step:).
//   · No withAnimation — all views rendered at rest.
//   · designSystemEnvironment() in assertDesignSnapshot injects:
//       \.disablesOneShotMotion = true  (settles entrance motion / GenerationProgressView sweep)
//       \.mapSnapshotMode = true        (BaseLocationStepView reads this env key and renders its
//                                        static map placeholder — no network tiles, no flake)
//   · All seeds come from SampleData onboarding factories (stable literal IDs).
//   · Fixed viewport via canonicalConfig (iPhone 17 Pro, 393×852, @3x, .light).
//
// Baselines land in __Snapshots__/OnboardingScreenSnapshotTests/ alongside this file and are
// committed as the visual contract. First run records (fails with "recorded") — commit the PNGs;
// subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("Onboarding screen render snapshots")
@MainActor
struct OnboardingScreenSnapshotTests {

    // MARK: - DestinationStepView

    @Test("destination-a — returning user, 23 Lisbon saves, savedCount AI voice")
    func destinationA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        assertDesignSnapshot(
            DestinationStepView().environment(store),
            named: "destination-a"
        )
    }

    @Test("destination-b — saves elsewhere, Kyoto, 0 here, taste-reading AI voice")
    func destinationB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .destination)
        assertDesignSnapshot(
            DestinationStepView().environment(store),
            named: "destination-b"
        )
    }

    @Test("destination-c — first trip, 'Where to first?' question copy, first-trip AI voice")
    func destinationC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .destination)
        assertDesignSnapshot(
            DestinationStepView().environment(store),
            named: "destination-c"
        )
    }

    // MARK: - DestinationStepView — AX5 Dynamic Type audit compensating control
    //
    // The XCUITest accessibility audit suppresses .dynamicType because UIKit's
    // performAccessibilityAudit cannot introspect SwiftUI Font.custom(relativeTo:) scaling.
    // This snapshot is the compensating check: it proves every text role in the destination
    // screen scales gracefully at the maximum Dynamic Type step (decisions.md §AX5-snapshot).

    @Test("destination-a-ax5 — AX5 Dynamic Type, proves text scales at accessibility5")
    func destinationAAX5() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .destination)
        assertDesignSnapshot(
            DestinationStepView()
                .environment(store)
                .dynamicTypeSize(.accessibility5),
            named: "destination-a-ax5"
        )
    }

    // MARK: - TripShapeStepView

    @Test("tripshape-a — shapeCards body, Lisbon 23 saves, all three cards unlocked")
    func tripShapeA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .tripShape)
        assertDesignSnapshot(
            TripShapeStepView().environment(store),
            named: "tripshape-a"
        )
    }

    @Test("tripshape-b — shapeCards body, Kyoto, 'Cover the bucket' card locked with reason")
    func tripShapeB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .tripShape)
        assertDesignSnapshot(
            TripShapeStepView().environment(store),
            named: "tripshape-b"
        )
    }

    @Test("tripshape-c — tasteForm body (structurally different: interest chips + pace picker)")
    func tripShapeC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .tripShape)
        assertDesignSnapshot(
            TripShapeStepView().environment(store),
            named: "tripshape-c"
        )
    }

    // MARK: - BaseLocationStepView

    @Test("baselocation-a — Alfama neighborhood, Lisbon map, 23-saves context")
    func baseLocationA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .baseLocation)
        assertDesignSnapshot(
            BaseLocationStepView().environment(store),
            named: "baselocation-a"
        )
    }

    @Test("baselocation-b — Gion neighborhood, Kyoto map, taste-read context")
    func baseLocationB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .baseLocation)
        assertDesignSnapshot(
            BaseLocationStepView().environment(store),
            named: "baselocation-b"
        )
    }

    @Test("baselocation-c — Baixa neighborhood, Lisbon map, first-trip context")
    func baseLocationC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .baseLocation)
        assertDesignSnapshot(
            BaseLocationStepView().environment(store),
            named: "baselocation-c"
        )
    }

    // MARK: - GettingAroundStepView
    //
    // State C uses the same lisbonTransportRec() as state A — the presenter derives identical
    // output (same suggestedMode, cityContext, reasonRows, contextNote) for both A and C.
    // A and C would produce a byte-identical snapshot; one snapshot locks both.
    // State B (Kyoto) differs: different city context ("Kyoto · Gion\n4 days"), different
    // fare labels (¥ vs €), and a blossom-crowd context note.

    @Test("gettingaround-a — Lisbon transit rec, rain context note, € fares (locks A and C)")
    func gettingAroundA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .gettingAround)
        assertDesignSnapshot(
            GettingAroundStepView().environment(store),
            named: "gettingaround-a"
        )
    }

    @Test("gettingaround-b — Kyoto transit rec, blossom-crowd note, ¥ fares")
    func gettingAroundB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .gettingAround)
        assertDesignSnapshot(
            GettingAroundStepView().environment(store),
            named: "gettingaround-b"
        )
    }

    // MARK: - GeneratingStepView
    //
    // All three states differ in checklist step labels, sub text, and handoff line,
    // so each warrants its own snapshot even though the structural layout is identical.
    // Note: GeneratingStepView calls store.startGeneration() in .task — the store's
    // synchronous advanceGeneration() seam is not called here; the view is snapshotted at
    // the seed's currentStepIndex (index 1, one step done + one current) before any task fires.

    @Test("generating-a — Lisbon 23-saves plan, 'Grouping your 23 places' done, 'Clustering' current")
    func generatingA() {
        let store = AppStore.preview(SampleData.onboardingAContext(), step: .generating)
        assertDesignSnapshot(
            GeneratingStepView().environment(store),
            named: "generating-a"
        )
    }

    @Test("generating-b — Kyoto plan, 'Pulling Kyoto's best' done, 'Clustering' current")
    func generatingB() {
        let store = AppStore.preview(SampleData.onboardingBContext(), step: .generating)
        assertDesignSnapshot(
            GeneratingStepView().environment(store),
            named: "generating-b"
        )
    }

    @Test("generating-c — Lisbon first-trip plan, 'Choosing Lisbon's best for food…' done")
    func generatingC() {
        let store = AppStore.preview(SampleData.onboardingCContext(), step: .generating)
        assertDesignSnapshot(
            GeneratingStepView().environment(store),
            named: "generating-c"
        )
    }
}
