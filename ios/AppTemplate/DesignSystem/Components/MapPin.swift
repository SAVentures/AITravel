// MapPin.swift — the map marker carrying the product's signature register: definitive · fuzzy · now.
// Ports the components mockup `.pin` (§08): a teardrop marker (pill with one sharp corner, rotated 45°,
// glyph counter-rotated upright). Register is conveyed by COLOUR **and** glyph/shape so it survives
// grayscale (02-color §6). Content, never glass (J-0.1); semantic tokens only (J-0.2).
// The now-ring is STATIC this phase (OD-2) — a continuous pulse would be an unowned loop (J-9.3).
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

    // The marker + halo scale with the glyph's mono caption text style (T-6.4); never a fixed CGFloat.
    @ScaledMetric(relativeTo: .caption2) private var pinSize: CGFloat = Sizing.Component.mapPin
    @ScaledMetric(relativeTo: .caption2) private var ringWidth: CGFloat = Stroke.Component.mapPinRing
}

// MARK: - Preview

#Preview("MapPin — definitive · fuzzy · now") {
    // Local value-type fixtures — no SampleData / domain model exists in Phase 0 (05 §8, plan Wave C note).
    let registers: [MapPin.PinRegister] = [.definitive(2), .fuzzy, .now]
    HStack(spacing: Spacing.`2xl`) {
        ForEach(Array(registers.enumerated()), id: \.offset) { _, register in
            MapPin(register)
        }
    }
    .padding(Spacing.`2xl`)
    .background(ColorRole.surfacePage)
}
