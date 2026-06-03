// RhythmSpacer.swift — a composition primitive: the gap ladder, exposed as vertical spacers (05 §9; J-1).
//
// Screens and components reach for a *named rung* of vertical breathing room instead of typing a number.
// Every rung maps to the matching `Spacing.*` semantic token, so two independently-built screens land on
// the same rhythm (J-1: vertical gaps come from named rungs only — never an off-ladder literal). This
// primitive references the SEMANTIC tier exclusively (no `Primitive.*`, no literal height).
//
// LEGAL RHYTHM GAP vs FORBIDDEN FIXED CONTENT FRAME (J-0.3, J-1):
//   J-0.3 forbids fixed frames on **text / content containers** — a label or card pinned to a hard height
//   clips and breaks Dynamic Type. A `RhythmSpacer` is NOT a content container: it carries no text, no
//   intrinsic content, just *empty vertical space*. A fixed *gap* height is exactly the contract — the
//   ladder rungs (4/8/12/16/24/32) are deliberately constant so the macro-rhythm is identical at every
//   text size. So `Spacer().frame(height: Spacing.<rung>)` is legal precisely because it sizes a gap, not
//   content. (No `.fixedSize` is used — that would freeze surrounding content, which we never do.)
import SwiftUI

/// A fixed-height vertical gap drawn from the semantic gap ladder (`Spacing.*`), so screens never type a
/// raw number for vertical rhythm. A gap, not a content frame — see the file header for the J-0.3/J-1
/// distinction.
struct RhythmSpacer: View {

    /// The named rungs of the six-rung gap ladder (03-layout-spacing §2, J-1). Each maps 1:1 to a
    /// `Spacing.*` role below — there is no off-ladder rung.
    enum Rung {
        /// 4 — the tightest pairing (eyebrow ↔ title). → `Spacing.hairline`
        case hairline
        /// 8 — icon ↔ label; cover ↔ first baseline. → `Spacing.paired`
        case paired
        /// 12 — between siblings (title ↔ subtitle). → `Spacing.itemGap`
        case sibling
        /// 16 — card/row inset rhythm. → `Spacing.cardInset`
        case card
        /// 24 — the default between-group rhythm (section ↔ section). → `Spacing.sectionGap`
        case section
        /// 32 — the widest breath (hero ↔ first control). → `Spacing.hero`
        case hero
    }

    private let rung: Rung

    init(_ rung: Rung) {
        self.rung = rung
    }

    /// The semantic gap height for the selected rung. Maps to `Spacing.*` only — never a literal.
    private var height: CGFloat {
        switch rung {
        case .hairline: Spacing.hairline
        case .paired:   Spacing.paired
        case .sibling:  Spacing.itemGap
        case .card:     Spacing.cardInset
        case .section:  Spacing.sectionGap
        case .hero:     Spacing.hero
        }
    }

    var body: some View {
        // A fixed *gap* height (legal, J-1) — not a fixed content frame (forbidden, J-0.3). No `.fixedSize`.
        Spacer()
            .frame(height: height)
    }
}

#Preview("Rung stack") {
    VStack(alignment: .leading, spacing: 0) {
        Text("hairline")
        RhythmSpacer(.hairline)
        Text("paired")
        RhythmSpacer(.paired)
        Text("sibling")
        RhythmSpacer(.sibling)
        Text("card")
        RhythmSpacer(.card)
        Text("section")
        RhythmSpacer(.section)
        Text("hero")
        RhythmSpacer(.hero)
        Text("end")
    }
    .padding(Spacing.screenInset)
}
