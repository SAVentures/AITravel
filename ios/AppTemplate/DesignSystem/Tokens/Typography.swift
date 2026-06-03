// Typography.swift — the SEMANTIC type tier (01-typography T-0/T-2/T-5/T-6; 05-design-system.md §4).
// Each role binds a Dynamic Type text style (scales to AX5) over a `Primitive.type*Size` — never a raw
// size, `Font.system(size:)`, or `.custom(fixedSize:)` (T-0.1/T-6.1, J-0.3). Three families (T-1):
// display = Schibsted Grotesk (titles/names/numerals), UI = Hanken Grotesk (body/chrome/meta), mono =
// system monospaced (measurement). `name` → display per OD-4; no `@ScaledMetric` here (fonts only, T-6.4).
import SwiftUI

enum Typography {

    // MARK: - Display roles — Schibsted Grotesk (T-2: names, titles, hero numerals)

    /// The screen hero title — one per screen (T-2, T-4.1). `.largeTitle` · bold · display, with the
    /// big-display negative tracking baked in (`trackDisplay`, T-5).
    static let titleLarge: Font = Font
        .custom(displayFamily, size: Primitive.typeTitleLargeSize, relativeTo: .largeTitle)
        .weight(weight(Primitive.weightBold))

    /// Section / card titles. `.title2` · semibold · display, with dense-display tracking (`trackTight`).
    static let title: Font = Font
        .custom(displayFamily, size: Primitive.typeTitleSize, relativeTo: .title2)
        .weight(weight(Primitive.weightSemibold))

    /// The item name in a row/card (a place name). `.headline` · semibold · display; system tracking
    /// (the name sits at body size, where loose tracking would be a slop tell — T-5.2). Bound to display
    /// per OD-4.
    static let name: Font = Font
        .custom(displayFamily, size: Primitive.typeNameSize, relativeTo: .headline)
        .weight(weight(Primitive.weightSemibold))

    // MARK: - UI roles — Hanken Grotesk (T-2: body, chrome, meta — system tracking, T-5.2)

    /// Running copy, primary row text. `.body` · regular · UI.
    static let body: Font = Font
        .custom(uiFamily, size: Primitive.typeBodySize, relativeTo: .body)
        .weight(weight(Primitive.weightRegular))

    /// Dense secondary copy. `.callout` · regular · UI.
    static let callout: Font = Font
        .custom(uiFamily, size: Primitive.typeCalloutSize, relativeTo: .callout)
        .weight(weight(Primitive.weightRegular))

    /// Meta lines, sub copy. `.subheadline` · regular · UI.
    static let subhead: Font = Font
        .custom(uiFamily, size: Primitive.typeSubheadSize, relativeTo: .subheadline)
        .weight(weight(Primitive.weightRegular))

    // MARK: - Mono roles — system monospaced (T-1.2: measurement, vertically aligned numerals)

    /// Metadata, mono caps. `.footnote` · regular · system monospaced — bound to the `.footnote` text
    /// style (not a fixed size) so it still scales (T-0.1/T-6.1). Caps/eyebrow tracking is NOT baked in:
    /// a caps eyebrow applies it at the call site via `.tracking(_:)` (see `trackCaps` / `trackEyebrow`).
    static let footnote: Font = Font.system(.footnote, design: .monospaced)
        .weight(weight(Primitive.weightRegular))

    /// Smallest meta, eyebrow caps. `.caption2` · regular · system monospaced — scales off `.caption2`
    /// (T-0.1). As with `footnote`, eyebrow tracking is the caller's to apply, not the role's (T-5.2).
    static let caption: Font = Font.system(.caption2, design: .monospaced)
        .weight(weight(Primitive.weightRegular))

    // MARK: - Tracking (T-5) — em-relative letter-spacing, call-site-applied where loose

    // The registered family names (the EXACT names FontRegistry registers — FontRegistryTests verifies).
    private static let displayFamily = "Schibsted Grotesk" // hero titles, names, numerals
    private static let uiFamily = "Hanken Grotesk"         // body, chrome, meta

    // Tracking values from foundations.css `--track-*` (lines 140–143), authored by hand because codegen
    // skips tracking. These are em fractions; convert to points at the call site with `tracking(_:size:)`
    // (`.tracking(_:)` takes POINTS and is size-aware per T-5.1 — use it, never `.kerning()`).
    //
    // T-5.2: loose tracking belongs ONLY on short mono-caps eyebrows; body/UI stay at system tracking. So
    // the roles above do NOT apply caps/eyebrow tracking. `titleLarge`/`title` are the one exception — their
    // display tracking is baked into the role below (they're display, not body, and never wrap as eyebrows).

    /// titleLarge hero — tighten the big display face (−0.02em).
    private static let trackDisplay: CGFloat = -0.02
    /// title / dense display (−0.015em).
    private static let trackTight: CGFloat = -0.015
    /// Mono caption caps, e.g. "DAY 2 · DEFINITIVE" (+0.06em). Exposed for a caps caller to apply.
    static let trackCaps: CGFloat = 0.06
    /// Short mono eyebrow caps — the loosest, caps-only (+0.085em). Exposed for an eyebrow caller to apply.
    static let trackEyebrow: CGFloat = 0.085

    /// Convert an em-relative tracking value (e.g. `trackEyebrow`) to the points `.tracking(_:)` expects,
    /// for a caller laying out a caps eyebrow at a known reference size:
    /// `Text("DAY 2").font(.caption).tracking(Typography.tracking(Typography.trackEyebrow, size: 11))`.
    /// (em → pt = em × size; T-5.1 — use `.tracking`, never `.kerning`.)
    static func tracking(_ em: CGFloat, size: CGFloat) -> CGFloat { em * size }

    // MARK: - Helpers

    /// Map a `Primitive.weight*` rung (the 400/500/600/700 numeric weight from foundations.css) to a
    /// SwiftUI `Font.Weight`. Keeps the weight authored once in the CSS contract.
    private static func weight(_ rung: Double) -> Font.Weight {
        switch rung {
        case Primitive.weightBold: .bold
        case Primitive.weightSemibold: .semibold
        case Primitive.weightMedium: .medium
        default: .regular
        }
    }

    /// Bake the display tracking into `titleLarge` / `title`: these are display roles (not body, never
    /// eyebrows), so their negative tracking is part of the role. A caller applies it as
    /// `Text(t).font(.titleLarge).tracking(Typography.titleLargeTracking)`.
    static let titleLargeTracking: CGFloat = tracking(trackDisplay, size: Primitive.typeTitleLargeSize)
    static let titleTracking: CGFloat = tracking(trackTight, size: Primitive.typeTitleSize)

    /// Pre-baked caps/eyebrow tracking against the caption rung (`Primitive.typeCaptionSize`), so a caps
    /// caller applies `.tracking(Typography.trackCapsCaption)` and never reaches a size at the call site.
    /// Short mono caps eyebrows ("DAY 2", "WAYS") don't need per-size re-scaling — they sit at the caption
    /// rung by design (T-5.2), so the reference size is baked into the role here, not passed by the caller.
    static let trackCapsCaption: CGFloat = tracking(trackCaps, size: Primitive.typeCaptionSize)
    static let trackEyebrowCaption: CGFloat = tracking(trackEyebrow, size: Primitive.typeCaptionSize)
}
