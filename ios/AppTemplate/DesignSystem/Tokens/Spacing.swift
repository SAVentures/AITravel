// Spacing.swift — the SEMANTIC spacing tier: the six-rung named gap ladder (03-layout-spacing §1–2; J-1).
//
// Every vertical gap and inset a screen, component, or modifier reaches for is named by ROLE here — never
// a literal, never a raw `Primitive.*`, never an off-grid number (J-0.2 / J-1). The ladder is what makes
// two independently-built screens *match*: both pull "the gap after a section header" from `sectionGap`,
// so both land on 24 (03 §2). Each rung maps to the generated primitive that the `foundations.css` 4/8-grid
// value resolves to; do **not** invent a rung in between, and nothing lands off the 4/8 spine (03 §1, J-1).
//
// The raw 8pt spine (`Primitive.s1…s8`) is deliberately NOT re-aliased wholesale — a named role exists only
// where a primitive plays a layout role (here: `screenInset`, the standard compact horizontal margin, 03 §4).
//
// `@ScaledMetric` BOUNDARY (T-6.4): these tokens are plain `CGFloat`s and do **not** use `@ScaledMetric` —
// that property wrapper requires a `View`/property-wrapper context, which an enum has none of. The token
// holds the @Large (base) value; any component metric that must scale with the user's text size wires
// `@ScaledMetric(relativeTo:)` in the component itself, seeding it from the relevant `Spacing.*` base.
// Rhythm gaps remain legal at a fixed value (a gap is not a fixed content frame — J-0.3).
import SwiftUI

enum Spacing {

    // MARK: - The six-rung gap ladder (03-layout-spacing §2, J-1)

    /// 4 — the tightest pairing: eyebrow ↔ title, tag ↔ name. The only legal 4pt sub-step (03 §1).
    static let hairline: CGFloat = Primitive.gapHairline

    /// 8 — icon ↔ label in a chip; cover ↔ first text baseline.
    static let paired: CGFloat = Primitive.gapPaired

    /// 12 — title ↔ subtitle; meta ↔ title within a card (sibling spacing).
    static let itemGap: CGFloat = Primitive.gapSibling

    /// 16 — card padding; list-row vertical padding. Internal inset sits in a larger outer gap (03 §3).
    static let cardInset: CGFloat = Primitive.gapCard

    /// 24 — section header ↔ first row; hero ↔ first section. The default between-group rhythm.
    static let sectionGap: CGFloat = Primitive.gapSection

    /// 32 — screen hero ↔ first control; sheet inner top. The widest breath on the ladder.
    static let hero: CGFloat = Primitive.gapBreath

    // MARK: - Layout margin — the standard compact horizontal inset (03-layout-spacing §4)

    /// 16 — the standard horizontal screen margin on compact width. Prefer wiring this through the
    /// layout-margin guide (`.safeAreaPadding` / `.contentMargins`) rather than a raw `.padding(16)` (03 §4).
    static let screenInset: CGFloat = Primitive.s3

    /// 64 — the clearance band below the floating ×/back glyph so scroll content doesn't collide with the
    /// chrome at rest. A named LAYOUT role like `screenInset` — exempt from the gap ladder (it is not a
    /// between-group rhythm gap). 64 is on the 8pt spine (8×8); it was snapped from a prior 68.
    static let chromeClearance: CGFloat = Primitive.spaceChromeClear
}
