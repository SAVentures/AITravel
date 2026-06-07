// CategoryChipSnapshotTests.swift — Layer 3 render-snapshot lock for CategoryChip.
//
// These tests are the lock on CategoryChip at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — category tint fill, mark ink, capsule radius,
// caps tracking, chip padding — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   eat         — PlaceCategory.eat: the day-mark hue for Eat tinted fill + mark ink.
//   drink       — PlaceCategory.drink: the Drink tint + mark ink.
//   stay        — PlaceCategory.stay: the Stay tint + mark ink.
//   do          — PlaceCategory.do: the Do tint + mark ink.
//   shop        — PlaceCategory.shop: the Shop tint + mark ink (ink-only hue, no day-mark day4/5 fill).
//   all-five    — All five categories in a row, confirming tint variance side-by-side — the mockup
//                 `.pl-cat` assembly (§0.A1 Done-when: "snapshots for Eat/Drink/Stay/Do/Shop").
//   eat-ax5     — AX5 compensating snapshot (§7.4 / §6.6). Same fixture as `eat` at
//                 `.accessibilityExtraExtraExtraLarge` to lock Dynamic Type scaling of the caps
//                 label at the largest accessibility category. Glass-free component — renders fully.
//
// Determinism (07-testing §6.4):
//   · No Date() — CategoryChip is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() (inside assertDesignSnapshot) registers fonts +
//     injects .disablesOneShotMotion = true — no per-file setup needed.
//   · Value-type arg only (PlaceCategory); no SampleData required.
//
// Baselines land in __Snapshots__/CategoryChipSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("CategoryChip snapshots")
struct CategoryChipSnapshotTests {

    // MARK: - eat

    /// CategoryChip for the Eat category.
    /// Renders: day-mark Eat tint fill on a Radius.tag capsule; "EAT" caps label in the Eat mark ink.
    /// Confirms the tint fill and mark ink co-occur on the correct hue — no unit test verifies that.
    @Test("eat — Eat tint fill + mark ink co-occur on Radius.tag capsule")
    @MainActor func eat() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.eat) },
            named: "eat"
        )
    }

    // MARK: - drink

    /// CategoryChip for the Drink category.
    /// Renders: day-mark Drink tint fill; "DRINK" caps label in Drink mark ink.
    @Test("drink — Drink tint fill + mark ink")
    @MainActor func drink() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.drink) },
            named: "drink"
        )
    }

    // MARK: - stay

    /// CategoryChip for the Stay category.
    /// Renders: day-mark Stay tint fill; "STAY" caps label in Stay mark ink.
    @Test("stay — Stay tint fill + mark ink")
    @MainActor func stay() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.stay) },
            named: "stay"
        )
    }

    // MARK: - do

    /// CategoryChip for the Do category.
    /// Renders: day-mark Do tint fill; "DO" caps label in Do mark ink.
    @Test("do — Do tint fill + mark ink")
    @MainActor func doCategory() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.do) },
            named: "do"
        )
    }

    // MARK: - shop

    /// CategoryChip for the Shop category.
    /// Renders: Shop tint fill (ink-derived, per D-1 decision); "SHOP" caps label in Shop mark ink.
    /// Confirms the Shop category is visually distinct from the day-mark categories.
    @Test("shop — Shop tint fill + mark ink (ink-derived hue, distinct from day-mark set)")
    @MainActor func shop() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.shop) },
            named: "shop"
        )
    }

    // MARK: - all-five

    /// All five categories in a horizontal row — the mockup `.pl-cat` assembly.
    /// Confirms tint hue variance side-by-side: each chip has a distinct fill and ink so the
    /// category is readable in both color and text (02-color §6 — never color alone).
    @Test("all-five — all five category chips side-by-side confirming hue variance")
    @MainActor func allFive() {
        assertDesignSnapshot(
            allFiveCanvas(),
            named: "all-five"
        )
    }

    // MARK: - eat-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as `eat` but rendered at
    /// accessibilityExtraExtraExtraLarge to lock Dynamic Type scaling of the caps label at
    /// the largest accessibility category. Freezes any regression where a fixed frame or
    /// missing font scaling clips the label at AX5. Glass-free component — renders fully.
    @Test("eat-ax5 — AX5 Dynamic Type: Eat chip caps label at accessibilityXXXL")
    @MainActor func eatAX5() {
        assertDesignSnapshot(
            chipCanvas { CategoryChip(.eat) }
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "eat-ax5"
        )
    }
}

// MARK: - Canvas helpers

/// Wraps a single chip in a surfacePage canvas matching the CategoryChip #Preview padding.
@MainActor
private func chipCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}

/// Wraps all five chips in a horizontal row, matching the CategoryChip #Preview layout.
@MainActor
private func allFiveCanvas() -> some View {
    HStack(spacing: Spacing.sm) {
        ForEach(PlaceCategory.allCases, id: \.self) { category in
            CategoryChip(category)
        }
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(ColorRole.surfacePage)
}
