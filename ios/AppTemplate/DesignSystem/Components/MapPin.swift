// MapPin.swift — the map marker carrying the product's one signature idea, definitive vs fuzzy vs now.
//
// Ports the components mockup `.pin` (§08 — "Map pins — definitive · fuzzy · now"):
//   .pin .mk        — the teardrop marker: a pill with one sharp corner, rotated 45°
//                     (`border-radius: 999px 999px 999px 2px; transform: rotate(45deg)`), the glyph
//                     counter-rotated so it reads upright (`.mk span { transform: rotate(-45deg) }`).
//   .pin.def  .mk   — solid ink ground (`--ink-900`), a number / `●` glyph on paper (`--paper-0`).
//   .pin.fuzzy .mk  — soft grey ground (`--paper-300`), an italic `~` glyph in lighter ink (`--ink-500`).
//   .pin.now  .mk   — the blue now ground (`--state-now`), a `●` glyph on accent (`--on-accent`), with a
//                     soft ring (`box-shadow: 0 0 0 6px state-now @ 16%`).
//
// The three registers ARE the product's point of view (the plan's "definitive vs fuzzy" signature) and
// run through cards, timeline rows, and pins alike — so the register is a VALUE-TYPE ENUM arg
// (`PinRegister`), never a boolean or an ad-hoc style (05 §8, plan Wave C note).
//
// Survives grayscale (02-color §6, never colour alone): each register is conveyed by COLOUR **and**
// SHAPE/GLYPH — the definitive number/`●` on ink, the italic `~` on grey, the `●` on the blue ring — so a
// colour-blind or monochrome reader still tells the three apart by the glyph and the now-ring.
//
// The now register is a STATIC ring this phase (OD-2): the mockup shows a pulsing now-ring, but a
// continuous motion in the frozen foundation would be an unowned loop (J-9.3 — ≤1 continuous motion *per
// screen*). The pulse is deferred to the screen that first anchors it; here the ring is drawn at rest.
// NEVER a continuous pulse in this component.
//
// @ScaledMetric (T-6.4): the marker is a non-text metric, so the pin size scales with the glyph's mono
// caption text style via `@ScaledMetric(relativeTo:)` — never a fixed CGFloat, never a fixed frame (J-0.3).
//
// Semantic tokens only; zero literals / `Primitive.*` (J-0.2). Content, never chrome — a pin is NOT glass
// (J-0.1). Value-type args only; the local `PinRegister` fixture drives the previews + the Wave E snapshot.
import SwiftUI

struct MapPin: View {

    /// Which of the three registers this pin is — the product's one signature idea, as a value type.
    /// Conveyed by colour **and** glyph/shape so it survives grayscale (02-color §6).
    enum PinRegister {
        /// A fixed stop — solid ink, a sequence number (or `●` when unnumbered). Lifted and certain.
        case definitive(Int?)
        /// A flexible stop — soft grey, an italic `~` glyph. Recessive and approximate.
        case fuzzy
        /// The user's current place — the blue `stateNow` ground + a static ring, a `●` glyph. The one
        /// now marker per screen (J-6.3). Static ring this phase (OD-2) — never a continuous pulse.
        case now
    }

    private let register: PinRegister

    init(_ register: PinRegister) {
        self.register = register
    }

    var body: some View {
        // The teardrop marker: a rounded square with one sharpened corner, rotated 45° so the point sits
        // at the bottom; the glyph is counter-rotated to read upright. Shape is part of how the register
        // survives grayscale.
        ZStack {
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: Radius.pill,
                    bottomLeading: Radius.pill,
                    bottomTrailing: Radius.thumb,   // the one sharpened corner → the pin's point
                    topTrailing: Radius.pill
                )
            )
            .fill(markerFill)
            .frame(width: pinSize, height: pinSize)
            // The now ring: a static stroke of the now colour at low opacity (the mockup's 16% halo).
            // Drawn at rest — no animation (OD-2 / J-9.3).
            .background {
                if showsRing {
                    Circle()
                        .stroke(ColorRole.stateNow.opacity(0.16), lineWidth: ringWidth)
                        .frame(width: pinSize + ringWidth * 2, height: pinSize + ringWidth * 2)
                }
            }
            .rotationEffect(.degrees(45))

            glyph
                .font(Typography.caption)        // mono caption — the mockup's mono-semibold marker glyph
                .foregroundStyle(glyphInk)
        }
        // Colour is always paired with a label so the register is announced, never colour alone
        // (02-color §6).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Register → glyph / colour (colour AND shape/glyph, never colour alone)

    @ViewBuilder private var glyph: some View {
        switch register {
        case let .definitive(number):
            // A sequence number when present, else a solid dot — both read as "fixed and certain".
            Text(number.map(String.init) ?? "●")
        case .fuzzy:
            // The italic `~` glyph — the recessive, approximate register (mirrors the mockup's italic).
            Text("~").italic()
        case .now:
            // The filled dot — "you are here, now".
            Text("●")
        }
    }

    private var markerFill: Color {
        switch register {
        case .definitive: return ColorRole.textPrimary      // solid ink (mockup `--ink-900`)
        case .fuzzy:      return ColorRole.fillSecondary     // soft grey ground (mockup `--paper-300`)
        case .now:        return ColorRole.stateNow          // the blue now ground (mockup `--state-now`)
        }
    }

    private var glyphInk: Color {
        switch register {
        case .definitive: return ColorRole.textOnAccent      // paper glyph on ink (mockup `--paper-0`)
        case .fuzzy:      return ColorRole.textSecondary      // lighter ink on grey (mockup `--ink-500`)
        case .now:        return ColorRole.textOnAccent       // glyph on the accent (mockup `--on-accent`)
        }
    }

    private var showsRing: Bool {
        if case .now = register { return true }
        return false
    }

    private var accessibilityLabel: String {
        switch register {
        case let .definitive(number):
            return number.map { "Stop \($0)" } ?? "Definitive stop"
        case .fuzzy: return "Flexible stop"
        case .now:   return "Now"
        }
    }

    // The marker scales with the glyph's mono caption text style so it stays optically matched at every
    // Dynamic Type size (T-6.4); never a bare fixed CGFloat. The @Large base mirrors the mockup's 26px mark.
    @ScaledMetric(relativeTo: .caption2) private var pinSize: CGFloat = 26
    // The now ring's stroke width scales alongside the marker (the mockup's 6px halo).
    @ScaledMetric(relativeTo: .caption2) private var ringWidth: CGFloat = 6
}

// MARK: - Preview

#Preview("MapPin — definitive · fuzzy · now") {
    // Local value-type fixtures — no SampleData / domain model exists in Phase 0 (05 §8, plan Wave C note).
    let registers: [MapPin.PinRegister] = [.definitive(2), .fuzzy, .now]
    HStack(spacing: Spacing.hero) {
        ForEach(Array(registers.enumerated()), id: \.offset) { _, register in
            MapPin(register)
        }
    }
    .padding(Spacing.hero)
    .background(ColorRole.surfacePage)
}
