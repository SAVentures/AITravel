// CompositionSnapshotTests.swift — Layer 3 render-snapshot lock for the composition primitives.
//
// Freezes the accepted render for `ScreenScaffold`, `ScreenSection`, `RhythmSpacer`, and `ActionBar`
// so any later change that silently moves a pixel — spacing, color, font, chrome, glass — fails the
// build. One assertion per component state; thin by design (07-testing §6, §6.2).
//
// States covered:
//   scaffold-root           — ScreenScaffold(.root) in a NavigationStack; large title, placeholder rows
//   scaffold-detail         — ScreenScaffold(.detail) in a NavigationStack; inline title + back zone
//   scaffold-immersive      — ScreenScaffold(.immersive) in a NavigationStack; minimal/inline, tab hidden
//   section                 — ScreenSection("Header") with two placeholder text rows
//   rhythm                  — VStack of labelled blocks separated by representative RhythmSpacer rungs
//   actionbar-primary       — ActionBar, primary CTA only, over placeholder content
//   actionbar-primary-secondary — ActionBar with primary + secondary action, over placeholder content
//
// Determinism (07-testing §6.4):
//   - No Date() / live clock — all components are store-free and clock-free in Phase 0.
//   - No withAnimation — all views rendered at rest.
//   - designSystemEnvironment() in the helper registers fonts and injects
//     \.disablesOneShotMotion = true (settles any entrance motion before capture).
//   - Fixed viewport via canonicalConfig (iPhone 17 Pro, 393×852, @3x, .light).
//   - Scaffold variants wrap in NavigationStack so ScreenChromeModifier fires; safe-area/traits
//     are applied through the UIHostingController path in assertDesignSnapshot.
//
// Baselines land in __Snapshots__/CompositionSnapshotTests/ alongside this file and are committed.
// First run records (fails with "recorded") — commit the PNGs; subsequent runs diff.

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("Composition primitive render snapshots")
@MainActor
struct CompositionSnapshotTests {

    // MARK: - ScreenScaffold

    @Test("scaffold-root — large title, placeholder content")
    func scaffoldRoot() {
        let view = NavigationStack {
            ScreenScaffold(.root(title: "Library")) {
                ScreenSection("Due this week") {
                    Text("The Left Hand of Darkness")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text("A Wizard of Earthsea")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text("The Dispossessed")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                }
            }
        }

        assertDesignSnapshot(view, named: "scaffold-root")
    }

    @Test("scaffold-detail — inline title, back zone, placeholder content")
    func scaffoldDetail() {
        let view = NavigationStack {
            ScreenScaffold(.detail(title: "A Wizard of Earthsea")) {
                ScreenSection {
                    Text("Ursula K. Le Guin")
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text("A boy with a great gift for magic is sent to study at a school of wizardry.")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textSecondary)
                }
            }
        }

        assertDesignSnapshot(view, named: "scaffold-detail")
    }

    @Test("scaffold-immersive — minimal inline title, tab bar hidden, placeholder content")
    func scaffoldImmersive() {
        let view = NavigationStack {
            ScreenScaffold(.immersive) {
                ScreenSection {
                    Text("Reader mode — immersive chrome.")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                    Text("The tab bar is hidden and the nav bar is minimal.")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textSecondary)
                }
            }
        }

        assertDesignSnapshot(view, named: "scaffold-immersive")
    }

    // MARK: - ScreenSection

    @Test("section — header + two placeholder rows")
    func section() {
        let view = ScreenSection("Reading list") {
            Text("Dune — Frank Herbert")
                .font(Typography.body)
                .foregroundStyle(ColorRole.textPrimary)
            Text("Neuromancer — William Gibson")
                .font(Typography.body)
                .foregroundStyle(ColorRole.textPrimary)
        }
        .padding(Spacing.screenInset)

        assertDesignSnapshot(view, named: "section")
    }

    // MARK: - RhythmSpacer

    @Test("rhythm — labelled blocks separated by representative rungs")
    func rhythm() {
        let view = VStack(alignment: .leading, spacing: 0) {
            Text("hairline (4)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.hairline)
            Text("paired (8)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.paired)
            Text("sibling (12)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.sibling)
            Text("card (16)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.card)
            Text("section (24)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.section)
            Text("hero (32)")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
            RhythmSpacer(.hero)
            Text("end")
                .font(Typography.caption)
                .foregroundStyle(ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)

        assertDesignSnapshot(view, named: "rhythm")
    }

    // MARK: - ActionBar

    @Test("actionbar-primary — glass prominent CTA, no secondary")
    func actionBarPrimary() {
        let view = ZStack(alignment: .bottom) {
            ColorRole.surfacePage.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    Text("Content scrolls under the floating action bar.")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.screenInset)
            .frame(maxHeight: .infinity, alignment: .top)

            ActionBar(
                primaryTitle: "Borrow",
                primaryAccessibilityID: "actionbar.primary",
                primaryAction: {}
            )
        }

        assertDesignSnapshot(view, named: "actionbar-primary")
    }

    @Test("actionbar-primary-secondary — prominent CTA + outline secondary")
    func actionBarPrimarySecondary() {
        let view = ZStack(alignment: .bottom) {
            ColorRole.surfacePage.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    Text("Content scrolls under the floating action bar.")
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.screenInset)
            .frame(maxHeight: .infinity, alignment: .top)

            ActionBar(
                primaryTitle: "Borrow",
                primaryAccessibilityID: "actionbar.primary",
                secondary: .init(
                    "Add to list",
                    accessibilityID: "actionbar.secondary",
                    action: {}
                ),
                primaryAction: {}
            )
        }

        assertDesignSnapshot(view, named: "actionbar-primary-secondary")
    }
}
