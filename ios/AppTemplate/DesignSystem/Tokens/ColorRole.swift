// ColorRole.swift — the SEMANTIC color tier (02-color §2 role vocabulary; 05-design-system.md §1–3).
//
// Every color a screen, component, or modifier touches is referenced by ROLE here — never a raw hex,
// never a `Color(...)` literal, and never a `Primitive.*` directly (J-0.2 / J-2). Each member aliases
// the generated primitive that the matching `foundations.css` semantic alias resolves to; changing the
// look is one edit at this layer (and a future dark mode becomes a token swap — 02-color §7).
//
// Restraint is enforced by OMISSION (02-color §4, 05 §3): there is deliberately no `buttonBackground`,
// no `accentFill`, and no gradient role to misuse. `actionPrimary` and `stateNow` are the ONLY accent
// surfaces — emphasis/state only, ≤ twice per screen, never chrome or a card fill (J-0.4, J-2.4).
// `dayMark1…dayMark4` are categorical *marks* (a day's color cue), never fills of size (J-2).
import SwiftUI

enum ColorRole {

    // MARK: - Text — the four-step label hierarchy (02-color §2)

    /// Titles, names, primary numerals. Headings are always primary (J-2.1).
    static let textPrimary: Color = Primitive.ink700

    /// Meta lines, sub copy, captions — the second body ink (body is binary; J-2.2).
    static let textSecondary: Color = Primitive.ink400

    /// Placeholder / disabled / past-state ONLY. Does **not** clear WCAG AA at body size, so it never
    /// carries active text (02-color §2 + §6, J-2.3).
    static let textTertiary: Color = Primitive.ink400

    /// Text drawn on the accent surface (on a `.glassProminent` CTA / action ground).
    static let textOnAccent: Color = Primitive.onAccent

    // MARK: - Background / surface — by layout, not by taste (02-color §2)

    /// The page ground.
    static let surfacePage: Color = Primitive.paper100

    /// Cards, cells, wells — a surface lives on the page, never on another card of the same tone (J-8.1).
    static let surfaceGrouped: Color = Primitive.paper0

    /// Nested surfaces (use sparingly; don't reach past `surfaceGrouped` to fake depth).
    static let surfaceElevated: Color = Primitive.paper0

    // MARK: - Fill — translucent overlays sized by shape (02-color §2)

    /// Medium shapes — a switch ground.
    static let fillSecondary: Color = Primitive.fillSecondary

    /// Large shapes — input fields, search bars, plain buttons.
    static let fillTertiary: Color = Primitive.fillTertiary

    /// Large complex areas — a grouped backing behind controls.
    static let fillQuaternary: Color = Primitive.fillQuaternary

    // MARK: - Separator — 1px, emphasis from space not thickness (02-color §2, J-4.3/J-10.4)

    /// The default hairline, over layered/translucent context (semi-transparent).
    static let separator: Color = Primitive.separator

    /// Over an opaque surface where translucency reads muddy (fully opaque).
    static let separatorOpaque: Color = Primitive.ink200

    // MARK: - Accent + state — emphasis only, ≤ twice per screen (02-color §4, J-0.4/J-2.4)

    /// The one CTA, links, focus ring.
    static let actionPrimary: Color = Primitive.accent600

    /// A now / selected dot — the state mark, paired with a glyph/label, never color alone (02-color §6).
    static let stateNow: Color = Primitive.accent500

    /// Destructive action (role: `.destructive`); never a decorative fill.
    static let destructive: Color = Primitive.destructive

    /// Dimming scrim behind modal/overlay content.
    static let scrim: Color = Primitive.scrim

    // MARK: - Day marks — categorical state cues, never fills of size (02-color §2, J-2)

    static let dayMark1: Color = Primitive.day1
    static let dayMark2: Color = Primitive.day2
    static let dayMark3: Color = Primitive.day3
    static let dayMark4: Color = Primitive.day4
}
