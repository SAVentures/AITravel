// Spacing.swift — the SEMANTIC spacing tier: the t-shirt gap/padding ladder (03-layout-spacing §2; 05 §1).
// Every gap/inset is named by ROLE — a t-shirt rung (`md`/`xl`) or a named layout role (`screenInset`) —
// never a literal or raw `Primitive.*` (J-0.2/J-1). Each rung's value is its @Large reference; a component
// that must scale wires `@ScaledMetric(relativeTo:)` itself (an enum has no property-wrapper context, T-6.4).
import SwiftUI

enum Spacing {
    // t-shirt scale — the gap/padding API (value = the @Large reference)
    static let xs    = Primitive.spaceXs    // 4
    static let sm    = Primitive.spaceSm    // 8
    static let md    = Primitive.spaceMd    // 12
    static let lg    = Primitive.spaceLg    // 16
    static let xl    = Primitive.spaceXl    // 24
    static let `2xl` = Primitive.space2Xl   // 32
    static let `3xl` = Primitive.space3Xl   // 48
    static let `4xl` = Primitive.space4Xl   // 64

    // named layout roles (kept) — a margin/clearance is a role, not a rung
    static let screenInset      = Primitive.spaceLg    // 16 — standard compact horizontal screen margin
    static let chromeClearance  = Primitive.space4Xl   // 64 — clearance below the floating ×/back glyph

    // component-specific gap insets (single-component)
    enum Component {
        static let timelineNowRing = Primitive.spaceSm   // 8 — TimelineRow now-ring halo inset
    }
}
