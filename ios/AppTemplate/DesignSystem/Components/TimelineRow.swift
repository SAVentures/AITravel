// TimelineRow.swift — the day-timeline stop row + the transit connector that rides the rail between
// stops (05-components §4 "List rows" + the §04 `.tlstop`/`.tlleg`/`.modes` rail anatomy; J-2/J-7/J-8).
//
// `TimelineRow` and `TransitConnector` live in one file because they are one idea: the timeline is an
// alternating run of STOPS and the CONNECTORS between them. Both are CONTENT, so neither is ever glass
// (J-0.1 / J-8) — glass is reserved for floating chrome.
//
// PORTS FROM: `mockups/components/Components.html` §04 `.tlstop` / `.tlleg` / `.leg` / `.modes`.
//
// ── TimelineRow (a stop) — the workhorse for the day's stops (05-components §4) ──────────────────────
//   leading mark (the dot) → a primary place name + a mono meta line → a trailing mono fact + accessory.
//   • REGISTER is the product's one signature idea, exposed as a value-type enum arg (not a buried bool):
//       definitive — solid ink dot, roman display name, exact mono facts (`.d`, `.pri`).
//       fuzzy      — recessive grey dot, ITALIC display name in a lighter ink, "~" facts (`.d.fuzzy`,
//                    `.pri.it`, `--ink-600`). A fuzzy place *recedes*.
//       now        — the ONE `stateNow` mark on the screen: a STATIC ring this phase (OD-2 — no pulse;
//                    a continuous motion in a frozen foundation would be an unowned loop, J-9.3). The
//                    ring ports `.d.now`'s `0 0 0 4px surface-grouped, 0 0 0 7px state-now/16%` halo.
//   • ACCESSORY is the row's BEHAVIOUR CONTRACT (05-components §4 table), a value-type enum — the shape
//     is a promise: `.chevron` drills in (push), `.toggle` flips state in place, `.inline` does one
//     discrete action, `.check` selects in a choosing context. Don't mismatch (§4.1).
//   • Inks are binary (J-2.2/J-2.3): name `textPrimary`, mono meta + trailing fact `textSecondary`,
//     plus at most one state mark (the dot). Left-align text; RIGHT-ALIGN the trailing mono fact so the
//     eye runs the right edge (J-7.1/J-7.2).
//   • PAST = FADE, NEVER STRIKETHROUGH (the consolidated past-state rule, 05-components §4 / J-2.3): a
//     done stop drops to `textTertiary` + reduced opacity, never a line through the text.
//
// ── TransitConnector (a leg) — rides the rail between two stops (the §04 `.tlleg`) ───────────────────
//   REGISTER, a value-type enum:
//       singleMode — one leg: a mode glyph + a mono "8 min · walk" fact (`.leg`).
//       multiLeg   — a chain: leg → arrow → leg, the mono facts joined by a recessive "→" (`.arr`).
//       ways       — the set of options the AI weighs: a "WAYS" mono eyebrow + mode glyph-pills, one
//                    `.sel`ected (the `.modes` / `.mode.sel` block).
//
// Token discipline: SEMANTIC tokens + Wave-B modifiers only — zero literals, zero `Primitive.*` (J-0.2).
// `@ScaledMetric(relativeTo:)` sizes the rail width, the dot, and the now-ring (non-text metrics scale
// with Dynamic Type — T-6.4, never a fixed CGFloat). Each row is ONE VoiceOver stop
// (`.accessibilityElement(children: .combine)`, 05-components §4.2), and every colour-coded register is
// paired with a glyph/label so meaning never rides on colour alone (02-color §6). Value-type args only —
// no `AppStore`, no domain object (05-design-system.md §8); the local fixtures below drive the previews.
import SwiftUI

// MARK: - TimelineRow

/// A single stop on the day timeline: a leading state dot, a place name + mono meta, and a trailing mono
/// fact with a behaviour accessory. Screen-agnostic — takes value-type args, no `AppStore`/domain object.
struct TimelineRow: View {

    /// The product's signature register — how *certain* this stop is. Drives the dot, the name face, and
    /// the ink. A value-type arg, never a boolean buried in the view (the one idea — components.html §04).
    enum Register {
        /// Solid, lifted: an ink dot + a roman display name + exact facts.
        case definitive
        /// Recessive: a grey dot + an ITALIC display name in a lighter ink + "~" facts.
        case fuzzy
        /// The ONE current stop: the single `stateNow` mark, drawn as a STATIC ring this phase (OD-2).
        case now
    }

    /// The trailing accessory — the row's BEHAVIOUR CONTRACT (05-components §4 table). The shape is a
    /// promise; don't mismatch it to the row's actual behaviour (§4.1). A value-type enum, payload-carrying.
    enum Accessory {
        /// Drills into a child (push). `chevron.right`.
        case chevron
        /// Toggles state in place. Carries the current on/off value (the screen owns the binding).
        case toggle(Bool)
        /// One discrete action on the row — a short verb-led label, e.g. "Remove".
        case inline(String)
        /// Selected, in a choosing context — a trailing checkmark.
        case check
    }

    /// The local value-type fixture this component renders from — no `SampleData`/domain model exists in
    /// the foundation phase (05-design-system.md §8).
    struct Model {
        /// The place name (the primary line).
        var name: String
        /// The mono meta line, e.g. "OPENS 08:00 · RAMEN". Optional.
        var meta: String?
        /// The trailing mono fact, right-aligned, e.g. "08:00", "now", "~1:00". Optional.
        var fact: String?
        /// How certain this stop is — drives the dot, name face, and ink.
        var register: Register
        /// The trailing behaviour accessory, or `nil` for a fact-only stop.
        var accessory: Accessory?
        /// A past/done stop fades (never strikethrough). Independent of `register` so a *definitive* stop
        /// can also be in the past.
        var isPast: Bool

        init(
            name: String,
            meta: String? = nil,
            fact: String? = nil,
            register: Register = .definitive,
            accessory: Accessory? = nil,
            isPast: Bool = false
        ) {
            self.name = name
            self.meta = meta
            self.fact = fact
            self.register = register
            self.accessory = accessory
            self.isPast = isPast
        }
    }

    private let model: Model

    init(_ model: Model) {
        self.model = model
    }

    // The leading dot (`.tlstop .d` 13px) and the static now-ring scale with the row's text (T-6.4).
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 13
    // The now-ring's outer halo radius beyond the dot (ports `.d.now`'s `0 0 0 7px` outer ring).
    @ScaledMetric(relativeTo: .subheadline) private var nowRingInset: CGFloat = 7

    var body: some View {
        HStack(spacing: Spacing.itemGap) {
            // Leading state mark — the dot. The register's colour is ALWAYS paired with the name's face
            // (roman vs italic) + the meta, so the state never rides on colour alone (02-color §6).
            dot
                .accessibilityHidden(true)

            // Primary line + mono meta — left-aligned, binary inks (J-2.2/J-7.1).
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(model.name)
                    .font(Typography.name)
                    // Fuzzy places recede to an italic display cut in a lighter ink (the `.pri.it` register).
                    .italic(model.register == .fuzzy)
                    .foregroundStyle(nameInk)

                if let meta = model.meta {
                    Text(meta)
                        .font(Typography.caption)
                        .monospacedDigit()
                        .foregroundStyle(metaInk)
                }
            }

            Spacer(minLength: Spacing.paired)

            // Trailing mono fact — RIGHT-ALIGNED so the eye runs the right edge (J-7.2). A measurement, so
            // the mono role + tabular digits (T-1.2). Fades with the past-state.
            if let fact = model.fact {
                Text(fact)
                    .font(Typography.caption)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(metaInk)
            }

            // The behaviour accessory — its shape is the contract (05-components §4).
            if let accessory = model.accessory {
                accessoryView(accessory)
            }
        }
        // List-row vertical rhythm; ≥44pt tall as a tap target follows from the content + padding (J-1, HIG).
        .padding(.vertical, Spacing.itemGap)
        // Past stops FADE — reduced opacity + tertiary ink, NEVER a strikethrough (05-components §4 / J-2.3).
        .opacity(model.isPast ? pastOpacity : 1)
        // One VoiceOver stop — name + meta + fact + accessory read as a single phrase, not five (§4.2).
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: Dot

    @ViewBuilder private var dot: some View {
        switch model.register {
        case .now:
            // The ONE `stateNow` mark — a STATIC ring this phase (OD-2): the solid dot plus a soft halo
            // ring (the mockup `.d.now` `0 0 0 7px state-now/16%`). No pulse — that's deferred to the
            // screen that first anchors it (J-9.3, decisions.md).
            Circle()
                .fill(ColorRole.stateNow)
                .frame(width: dotSize, height: dotSize)
                .padding(nowRingInset)
                .background(
                    Circle().fill(ColorRole.stateNow.opacity(nowRingOpacity))
                )
        case .definitive:
            // The solid ink mark (`.d`, `--ink-800`) — the primary ink.
            Circle()
                .fill(ColorRole.textPrimary)
                .frame(width: dotSize, height: dotSize)
        case .fuzzy:
            // A recessive grey mark (`.d.fuzzy`) — the muted fill role; paired with the italic name so the
            // fuzzy register doesn't ride on colour alone.
            Circle()
                .fill(ColorRole.fillSecondary)
                .frame(width: dotSize, height: dotSize)
        }
    }

    /// The now-ring's halo opacity (ports `state-now/16%`). A dimmed *semantic* colour, not a literal.
    private var nowRingOpacity: Double { 0.16 }

    /// The reduced opacity a past stop fades to (fade-not-strikethrough).
    private var pastOpacity: Double { 0.55 }

    // MARK: Accessory views

    @ViewBuilder private func accessoryView(_ accessory: Accessory) -> some View {
        switch accessory {
        case .chevron:
            // Drills in (push). The recessive disclosure glyph (`.acc`).
            Image(systemName: "chevron.right")
                .font(Typography.footnote)
                .foregroundStyle(ColorRole.textSecondary)
        case .toggle(let isOn):
            // Toggles in place. A real `Toggle` so it carries the switch trait + 44pt target; the screen
            // owns the binding, so here it renders the current value inertly (a component takes value args).
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .tint(ColorRole.actionPrimary)
        case .inline(let label):
            // One discrete action — a short verb-led label in the action ink (the `.inline-act`).
            Text(label)
                .font(Typography.subhead)
                .foregroundStyle(ColorRole.actionPrimary)
        case .check:
            // Selected, in a choosing context — colour + glyph, never colour alone (02-color §6).
            Image(systemName: "checkmark")
                .font(Typography.footnote)
                .foregroundStyle(ColorRole.actionPrimary)
        }
    }

    // MARK: Inks (binary + the past fade)

    /// The name ink: primary by default; past stops fade to tertiary (fade-not-strikethrough).
    private var nameInk: Color {
        if model.isPast { ColorRole.textTertiary }
        else if model.register == .fuzzy { ColorRole.textSecondary }
        else { ColorRole.textPrimary }
    }

    /// The meta/fact ink: secondary by default; tertiary in the past.
    private var metaInk: Color {
        model.isPast ? ColorRole.textTertiary : ColorRole.textSecondary
    }

    // MARK: Accessibility

    /// Combine the name + register + meta + fact + accessory into one spoken phrase (§4.2).
    private var accessibilityLabel: String {
        var parts: [String] = [model.name]
        switch model.register {
        case .now: parts.append("now")
        case .fuzzy: parts.append("flexible")
        case .definitive: break
        }
        if let meta = model.meta { parts.append(meta) }
        if let fact = model.fact { parts.append(fact) }
        if model.isPast { parts.append("done") }
        if let accessory = model.accessory {
            switch accessory {
            case .chevron: break // the button trait carries "opens" semantics
            case .toggle(let isOn): parts.append(isOn ? "on" : "off")
            case .inline(let label): parts.append(label)
            case .check: parts.append("selected")
            }
        }
        return parts.joined(separator: ", ")
    }

    /// The accessory's behaviour trait — a chevron announces navigation; a check announces selection.
    private var accessibilityTraits: AccessibilityTraits {
        switch model.accessory {
        case .chevron: .isButton
        case .check: model.register == .definitive || !model.isPast ? .isSelected : []
        default: []
        }
    }
}

// MARK: - TransitConnector

/// The transit leg that rides the rail between two stops: a single mode, a multi-leg chain, or a set of
/// "ways" the AI weighs. Screen-agnostic — value-type args, content (never glass).
struct TransitConnector: View {

    /// One leg of transit: a mode glyph + a mono fact ("8 min · walk").
    struct Leg {
        /// An SF Symbol for the mode (e.g. "figure.walk", "tram.fill", "bus.fill").
        var systemImage: String
        /// The mono fact, e.g. "8 min · walk", "Rossio → Sintra · 40 min".
        var fact: String

        init(systemImage: String, fact: String) {
            self.systemImage = systemImage
            self.fact = fact
        }
    }

    /// One weighed option in the "ways" register: a mode glyph + a short mono count, one selected.
    struct Way: Identifiable {
        let id = UUID()
        /// An SF Symbol for the mode.
        var systemImage: String
        /// A short mono count/figure, e.g. "12", "6".
        var count: String
        /// Whether this is the selected way (the `.mode.sel` solid ink pill).
        var isSelected: Bool

        init(systemImage: String, count: String, isSelected: Bool = false) {
            self.systemImage = systemImage
            self.count = count
            self.isSelected = isSelected
        }
    }

    /// The connector's register — a value-type enum carrying its payload.
    enum Register {
        /// One leg: a mode glyph + a mono fact.
        case singleMode(Leg)
        /// A chain of legs, joined by a recessive arrow (the `.arr`).
        case multiLeg([Leg])
        /// The set of options the AI weighs: a "WAYS" eyebrow + glyph-count pills, one selected.
        case ways([Way])
    }

    private let register: Register

    init(_ register: Register) {
        self.register = register
    }

    // The mode glyph box scales with the mono fact (T-6.4).
    @ScaledMetric(relativeTo: .footnote) private var glyphSize: CGFloat = 14

    var body: some View {
        content
            // The leg sits indented from the rail, on the §04 `.tlleg` rhythm — a tight pairing gap.
            .padding(.vertical, Spacing.hairline)
            // One VoiceOver stop for the whole leg (the chain/ways read as a single phrase).
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder private var content: some View {
        switch register {
        case .singleMode(let leg):
            legView(leg)
        case .multiLeg(let legs):
            // leg → arrow → leg (the recessive `.arr` separates the mono facts).
            HStack(spacing: Spacing.paired) {
                ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                    if index > 0 {
                        Image(systemName: "arrow.right")
                            .font(Typography.caption)
                            .foregroundStyle(ColorRole.textTertiary)
                            .accessibilityHidden(true)
                    }
                    legView(leg)
                }
            }
        case .ways(let ways):
            HStack(spacing: Spacing.paired) {
                // The "WAYS" mono eyebrow — caps tracking applied at the call site (the role doesn't bake
                // it in — T-5.2), recessive ink.
                Text("Ways".uppercased())
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textTertiary)

                ForEach(ways) { way in
                    wayPill(way)
                }
            }
        }
    }

    /// One leg: the mode glyph + the mono fact, in the recessive leg inks (the §04 `.leg`).
    private func legView(_ leg: Leg) -> some View {
        HStack(spacing: Spacing.paired) {
            Image(systemName: leg.systemImage)
                .font(Typography.footnote)
                .frame(width: glyphSize, height: glyphSize)
                .foregroundStyle(ColorRole.textSecondary)
                .accessibilityHidden(true)
            Text(leg.fact)
                .font(Typography.footnote)
                .monospacedDigit()
                .foregroundStyle(ColorRole.textSecondary)
        }
    }

    /// A "way" glyph-count pill. The selected pill is a SOLID INK capsule (the `.mode.sel`, `--ink-900` /
    /// `--paper-0`) — NOT the accent: the blue stays reserved for action/now (components.html §05 cap).
    private func wayPill(_ way: Way) -> some View {
        HStack(spacing: Spacing.hairline) {
            Image(systemName: way.systemImage)
                .font(Typography.caption)
                .accessibilityHidden(true)
            Text(way.count)
                .font(Typography.caption)
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.hairline)
        .padding(.horizontal, Spacing.paired)
        // Selected = solid primary-ink capsule with on-fill text; unselected = neutral fill (a chip is a
        // pill — J-10.2). Colour is paired with the count, never colour alone (02-color §6).
        .foregroundStyle(way.isSelected ? ColorRole.surfaceGrouped : ColorRole.textSecondary)
        .background(
            way.isSelected ? ColorRole.textPrimary : ColorRole.fillTertiary,
            in: .capsule
        )
    }

    /// Combine the leg(s)/ways into a single spoken phrase (the connector is one VoiceOver stop).
    private var accessibilityLabel: String {
        switch register {
        case .singleMode(let leg):
            return leg.fact
        case .multiLeg(let legs):
            return legs.map(\.fact).joined(separator: ", then ")
        case .ways(let ways):
            let selected = ways.first(where: \.isSelected).map { ", \($0.count) selected" } ?? ""
            return "Ways" + selected
        }
    }
}

// MARK: - Previews

/// A tiny local value-type fixture for the rail previews + the Wave E snapshots — no `SampleData`/domain
/// model exists in Phase 0 (05-design-system.md §8). The `.tl` rail backing reproduces the mockup `.tl`
/// surface so the dots read against the card ground (this is a preview stage, not part of the component).
private struct RailStage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.horizontal, Spacing.cardInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .padding(Spacing.screenInset)
            .background(ColorRole.surfacePage)
    }
}

#Preview("Stop — definitive") {
    RailStage {
        TimelineRow(.init(
            name: "Tsuta ramen",
            meta: "OPENS 08:00 · RAMEN",
            fact: "08:00",
            register: .definitive,
            accessory: .chevron
        ))
    }
}

#Preview("Stop — now") {
    RailStage {
        TimelineRow(.init(
            name: "Yanaka cemetery walk",
            meta: "NOW · QUIET MORNING",
            fact: "now",
            register: .now
        ))
    }
}

#Preview("Stop — fuzzy") {
    RailStage {
        TimelineRow(.init(
            name: "somewhere for lunch",
            meta: "~ 13:00 · FLEXIBLE",
            fact: "~1:00",
            register: .fuzzy
        ))
    }
}

#Preview("Stop — past (fade, never strikethrough)") {
    RailStage {
        TimelineRow(.init(
            name: "Hotel checkout",
            meta: "DONE · 07:30",
            fact: "07:30",
            register: .definitive,
            isPast: true
        ))
    }
}

#Preview("Accessories — the behaviour contract") {
    RailStage {
        TimelineRow(.init(name: "Chevron", meta: "DRILLS INTO A CHILD",
                          register: .definitive, accessory: .chevron))
        TimelineRow(.init(name: "Switch", meta: "TOGGLES IN PLACE",
                          register: .definitive, accessory: .toggle(true)))
        TimelineRow(.init(name: "Inline action", meta: "ONE DISCRETE ACTION",
                          register: .definitive, accessory: .inline("Remove")))
        TimelineRow(.init(name: "Check", meta: "SELECTED, IN A CHOICE",
                          register: .definitive, accessory: .check))
    }
}

#Preview("Connector — single mode") {
    RailStage {
        TransitConnector(.singleMode(.init(systemImage: "figure.walk", fact: "8 min · walk")))
    }
}

#Preview("Connector — multi-leg") {
    RailStage {
        TransitConnector(.multiLeg([
            .init(systemImage: "tram.fill", fact: "Rossio → Sintra · 40 min"),
            .init(systemImage: "figure.walk", fact: "15 min · uphill"),
        ]))
    }
}

#Preview("Connector — ways") {
    RailStage {
        TransitConnector(.ways([
            .init(systemImage: "figure.walk", count: "12"),
            .init(systemImage: "tram.fill", count: "6", isSelected: true),
            .init(systemImage: "bus.fill", count: "4"),
        ]))
    }
}
