// MapPinSnapshotTests.swift — Layer 3 render-snapshot lock for MapPin (07-testing §6).
//
// Locks the three register states of `MapPin` against the canonical iPhone 17 Pro viewport.
// Any later change that silently shifts the teardrop fill, glyph, now-ring, colour, or size
// will fail the build here.
//
// States covered:
//   definitive  — MapPin(.definitive(2)): solid ink ground, sequence-number glyph.
//   fuzzy       — MapPin(.fuzzy):         soft grey ground, italic ~ glyph.
//   now         — MapPin(.now):           stateNow blue ground, ● glyph, static ring at rest.
//
// Ground: a neutral surfacePage fill with generous padding — representative of a pin
// floating over a map surface. The ground is intentionally minimal so the lock is on the
// pin geometry, not the surrounding content.
//
// Governing rules (07-testing §6.1–6.4):
//   • One snapshot per state — thin lock.
//   • Rendered at rest — no `withAnimation`, no live clock.
//   • `designSystemEnvironment()` (called inside assertDesignSnapshot) registers fonts and
//     injects `.disablesOneShotMotion = true` — the now ring is already static per OD-2,
//     but the flag ensures any entrance shimmer settles before capture.
//   • No `record: .all` in committed code.
//   • Baselines land in __Snapshots__/MapPinSnapshotTests/ alongside this file and are committed.
//
// API reference: ios/AppTemplate/DesignSystem/Components/MapPin.swift
//   MapPin.init(_ register: PinRegister)
//   PinRegister: .definitive(Int?) | .fuzzy | .now

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("MapPin snapshots")
struct MapPinSnapshotTests {

    // MARK: - definitive

    /// Solid ink ground, sequence-number glyph ("2") — lifted and certain register.
    /// Locks: teardrop fill (textPrimary / ink), glyph colour (textOnAccent), number text,
    /// pin size, and the sharpened bottom-trailing corner in one frame.
    @Test("definitive — solid ink ground, sequence-number glyph")
    @MainActor func definitive() {
        assertDesignSnapshot(
            MapPin(.definitive(2))
                .padding(Spacing.hero)
                .background(ColorRole.surfacePage),
            named: "definitive"
        )
    }

    // MARK: - fuzzy

    /// Soft grey ground, italic ~ glyph — recessive and approximate register.
    /// Locks: teardrop fill (fillSecondary / paper-300), italic glyph colour (textSecondary),
    /// and the visual recession relative to the definitive state in one frame.
    @Test("fuzzy — soft grey ground, italic ~ glyph")
    @MainActor func fuzzy() {
        assertDesignSnapshot(
            MapPin(.fuzzy)
                .padding(Spacing.hero)
                .background(ColorRole.surfacePage),
            named: "fuzzy"
        )
    }

    // MARK: - now

    /// stateNow blue ground, ● glyph, static ring at rest — current-location register (OD-2).
    /// Locks: teardrop fill (stateNow), glyph colour (textOnAccent), and the static ring
    /// stroke (stateNow @ 16% opacity, ringWidth) all co-occurring in one frame.
    /// The ring is drawn at rest — no continuous pulse this phase (J-9.3 / OD-2).
    @Test("now — stateNow ground, ● glyph, static ring at rest")
    @MainActor func now() {
        assertDesignSnapshot(
            MapPin(.now)
                .padding(Spacing.hero)
                .background(ColorRole.surfacePage),
            named: "now"
        )
    }
}
