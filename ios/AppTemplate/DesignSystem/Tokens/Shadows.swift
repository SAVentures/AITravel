// Shadows.swift — the SEMANTIC elevation tier (03-layout-spacing §9; 05-design-system.md §1, §5; J-8.4).
//
// Depth is ONE restrained elevation system — three solid tones, one glass — expressing *hierarchy*,
// never decoration (J-8.4). There are exactly three tiers, and a surface picks one by ROLE:
//
//     • rest  — the default card lift; a card lives on the page (J-8.1). Consumed by `.cardSurface()` (B1).
//     • hero  — the ONE elevated/active surface per screen; reserved for a single emphasis (J-8.4).
//     • glass — floating chrome only (bars, sheet grabber, map chip). This is normally the SYSTEM's job:
//               native Liquid Glass (the `glassEffect` material) carries its own shadow (05-design-system
//               §6, J-0.1/J-8.3). We author `glass` here ONLY as a static frost approximation for the
//               component snapshots (the mockup `.glass-stage` parity) — it is NOT for content, and a real
//               glass bar in the app must use the system material, not this modifier.
//
// Never the hairline + wide-diffuse-shadow combo (08-slop A-4, J-8.4): a surface is *either* a 1px edge
// *or* a soft shadow, never a glowing floater. So `.cardSurface()` ships a shadow and NO border.
//
// ── Why this file is hand-authored (not generated) ──────────────────────────────────────────────────
// `Primitive.generated.swift` is codegen'd from `foundations.css`, but the generator SKIPS compound
// values — and every elevation tier is a multi-layer shadow (`--shadow-rest/-hero/-glass`,
// foundations.css 122–129). So these are authored BY HAND here from the exact CSS values; the authored
// sRGB + offsets below ARE the contract. `Primitive.generated.swift` is never touched.
//
// ── oklch → sRGB conversion (matching the generator) ────────────────────────────────────────────────
// foundations.css tints every shadow with one cool dark ink, `oklch(0.30 0.02 245)`; the glass inset
// highlight is `oklch(1 0 0)` (pure white). Converted via OKLab→linear-sRGB→gamma (the same path the
// token generator uses), the alpha carried straight from the CSS `/ A`:
//
//     oklch(0.30 0.02 245)  →  sRGB(0.1473, 0.1845, 0.2171)   (a cool slate ink)
//     oklch(1    0    0)    →  sRGB(1.0000, 1.0000, 1.0000)   (white)
//
// ── CSS blur → SwiftUI radius ───────────────────────────────────────────────────────────────────────
// CSS `box-shadow` blur is ~2× a SwiftUI `.shadow(radius:)` Gaussian sigma, so we map `radius = blur / 2`.
// CSS offsets (x, y) carry straight to SwiftUI `.shadow(x:y:)`. Each CSS comma-separated layer is one
// `.shadow(...)` call; per OD-3 the tiers are per-tier `ViewModifier`s that apply the layers OUTER-to-
// INNER, in the same order they appear in the CSS (the widest, softest layer first, then the tight
// contact layer) so the composite reads identically.
import SwiftUI

enum Shadows {

    // MARK: - The cool slate ink every shadow layer is tinted with (oklch(0.30 0.02 245))

    /// `oklch(0.30 0.02 245)` → sRGB. The shared shadow ink; alpha is supplied per layer below.
    fileprivate static func slate(_ opacity: Double) -> Color {
        Color(.sRGB, red: 0.1473, green: 0.1845, blue: 0.2171, opacity: opacity)
    }

    /// `oklch(1 0 0)` → sRGB white. The glass inset highlight only.
    fileprivate static func highlight(_ opacity: Double) -> Color {
        Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: opacity)
    }

    // MARK: - rest — the default card lift (consumed by `.cardSurface()`, B1)
    //
    // foundations.css `--shadow-rest`:
    //   0 1px  2px oklch(0.30 0.02 245 / 0.05 )   ← contact layer
    //   0 4px 14px oklch(0.30 0.02 245 / 0.055)   ← ambient layer

    /// The default elevation for a content card — subtle, not a glow (J-8.4).
    static func rest() -> some ViewModifier { RestShadow() }

    // MARK: - hero — the one elevated/active surface per screen (reserved emphasis)
    //
    // foundations.css `--shadow-hero`:
    //   0  2px  6px oklch(0.30 0.02 245 / 0.07)
    //   0 14px 34px oklch(0.30 0.02 245 / 0.10)

    /// A single emphasis per screen — reaching for this on more than one surface is a tell (J-8.4).
    static func hero() -> some ViewModifier { HeroShadow() }

    // MARK: - glass — floating-chrome frost parity (SNAPSHOTS only, never content)
    //
    // foundations.css `--shadow-glass`:
    //   inset 0 0.5px 0 oklch(1 0 0 / 0.55)        ← top highlight (no blur)
    //   0  1px  1px oklch(0.30 0.02 245 / 0.04)    ← contact layer
    //   0 10px 28px oklch(0.30 0.02 245 / 0.12)    ← cast layer
    //
    // NOTE: glass elevation is normally the SYSTEM's job (the native Liquid Glass material carries its own
    // shadow). This tier exists ONLY to approximate the mockup frost in component snapshots — it must not
    // dress content, and a real glass bar uses `glassEffect`, not this (05-design-system §6, J-0.1/J-8.3).
    static func glass() -> some ViewModifier { GlassShadow() }
}

// MARK: - Per-tier modifiers (OD-3) — layers applied outer-to-inner, in CSS order

/// `--shadow-rest` — two layers, contact over ambient.
private struct RestShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            // 0 1px 2px / 0.05  → radius 1
            .shadow(color: Shadows.slate(0.05), radius: 1, x: 0, y: 1)
            // 0 4px 14px / 0.055 → radius 7
            .shadow(color: Shadows.slate(0.055), radius: 7, x: 0, y: 4)
    }
}

/// `--shadow-hero` — two layers, lifted higher than `rest`.
private struct HeroShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            // 0 2px 6px / 0.07 → radius 3
            .shadow(color: Shadows.slate(0.07), radius: 3, x: 0, y: 2)
            // 0 14px 34px / 0.10 → radius 17
            .shadow(color: Shadows.slate(0.10), radius: 17, x: 0, y: 14)
    }
}

/// `--shadow-glass` — frost approximation for snapshots only (NOT content; system owns real glass).
private struct GlassShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            // inset 0 0.5px 0 white/0.55 — an inset top highlight. SwiftUI `.shadow` has no inset, so the
            // 0-blur highlight is approximated with a tight inner-edge overlay (no offset, no spread).
            .overlay(alignment: .top) {
                Shadows.highlight(0.55)
                    .frame(height: 0.5)
                    .allowsHitTesting(false)
            }
            // 0 1px 1px / 0.04 → radius 0.5 (contact)
            .shadow(color: Shadows.slate(0.04), radius: 0.5, x: 0, y: 1)
            // 0 10px 28px / 0.12 → radius 14 (cast)
            .shadow(color: Shadows.slate(0.12), radius: 14, x: 0, y: 10)
    }
}

// MARK: - View conveniences — so a modifier/component reads `.shadowRest()` not `.modifier(Shadows.rest())`

extension View {
    /// Default card lift (consumed by `.cardSurface()`, B1). 03-layout-spacing §9 / J-8.4.
    func shadowRest() -> some View { modifier(Shadows.rest()) }

    /// The one elevated/active surface per screen — reserved emphasis. 03-layout-spacing §9 / J-8.4.
    func shadowHero() -> some View { modifier(Shadows.hero()) }

    /// Floating-chrome frost parity for SNAPSHOTS only — never content; the system owns real glass
    /// elevation (05-design-system §6, J-0.1/J-8.3).
    func shadowGlass() -> some View { modifier(Shadows.glass()) }
}
