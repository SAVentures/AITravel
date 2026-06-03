// Motion.swift — the SEMANTIC motion tier (04-motion §1 / §3 / §7; J-9; 05-design-system.md §1, §5).
//
// One easing PERSONALITY, used with restraint. There is exactly ONE curve for the whole app: a
// critically-damped EASE-OUT that decelerates into rest and never overshoots (04-motion §1, J-9.2).
// No per-component curves; a second curve "for this one transition" is the first crack. Members are
// referenced by ROLE here — a view never authors a `.timingCurve(...)` or a raw `Primitive.dur*`
// inline (J-0.2).
//
// Durations are a fixed ladder (§2); pick a rung by WHAT is moving, never a value in between:
//
//     tap → standard → sheet → slow
//
// Springs vs curves (§3) — the split is a rule, not a style choice:
//   • DIRECT MANIPULATION (taps, drags, sheet pulls) settles on a SPRING — use `smooth` (bounce 0),
//     which preserves the gesture's velocity and retargets if interrupted (J-9.2, WWDC23 10158).
//   • AUTOMATIC / time-based (a fade, a push, an appearing badge) uses the fixed-duration EASE-OUT
//     curve (`standard(_:)` / `emph(_:)`) — the system started it; there is no velocity to honor.
// Spring/overshoot is forbidden everywhere except a single scoped reward moment (§5) — NOT built in
// this phase (no reward component exists yet).
//
// The two cubic-beziers below are authored BY HAND from `foundations.css` (lines 132–133); the codegen
// skips cubic-beziers, so the authored values here are the contract:
//     --ease-standard: cubic-bezier(0.32, 0.72, 0, 1)   critically-damped ease-out (the house curve)
//     --ease-emph:     cubic-bezier(0.22, 1, 0.36, 1)    settle, no overshoot (sheets / emphasis)
//
// Reduce Motion is MANDATORY (§7, J-9.5). `reduced(_:reduceMotion:)` halves duration in the normal
// path and yields `nil` (a static cross-fade at the call site) under Reduce Motion. The token only
// supplies the curves; the CALLER owns the degradation policy:
//   • continuous motion / shimmer (§4) goes STATIC — a resting skeleton, not a loop;
//   • springs (direct manipulation, §3) FLATTEN to a cross-fade;
//   • a reward tick (§5) FADES in, it does not spring.
// Read `@Environment(\.accessibilityReduceMotion)` in the view and gate through this helper.
import SwiftUI

enum Motion {

    // MARK: - Durations (the ladder · §2)

    /// Taps, toggles, chip selects, press-state release. The release plays AFTER the ≤100ms commit (§2.1).
    static let tap: Double = Primitive.durTap

    /// The default — most state changes, fades, badge swaps.
    static let standard: Double = Primitive.durStandard

    /// Sheets and presented surfaces rising to a detent.
    static let sheet: Double = Primitive.durSheet

    /// Full-screen / cover transitions — the slowest rung.
    static let slow: Double = Primitive.durSlow

    /// The one continuous AI sweep (04-motion §4).
    static let think: Double = Primitive.durThink

    // MARK: - Easings (the one personality · §1, §3)

    /// The house curve — a critically-damped ease-out, app-wide (§1; `--ease-standard`). Use for
    /// automatic / time-based transitions (fades, pushes, an appearing badge). Defaults to the
    /// `standard` rung; pass another rung when a heavier move warrants it.
    static func standard(_ duration: Double = Primitive.durStandard) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)
    }

    /// The emphasis curve — settles without overshoot (`--ease-emph`). For sheets / large emphasis
    /// moves; defaults to the `sheet` rung. Still ease-out, NOT a second personality — it shares the
    /// no-overshoot resolve (§1.1).
    static func emph(_ duration: Double = Primitive.durSheet) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    /// The direct-manipulation spring — `.smooth` is bounce 0 (the `withAnimation` default since iOS 17)
    /// (§3, WWDC23 10158). Use ONLY for user-driven motion (drags, sheet pulls, sliders) so the gesture's
    /// velocity is preserved; never on an automatic transition (that is the bouncy-where-it-shouldn't-be
    /// tell, J-9.2).
    static let smooth: Animation = .smooth

    // MARK: - Reduce Motion (mandatory · §7)

    /// Gate an animation through Reduce Motion. Under Reduce Motion returns `nil` — the change applies
    /// instantly, and the CALLER substitutes a static cross-fade (`degrade, don't delete`, §7.1); in the
    /// normal path returns `base` with its duration HALVED where the curve carries one (§2.2).
    ///
    /// The token supplies the curve only — continuous motion going static (§4.4) and springs flattening
    /// to a fade (§7) are the caller's responsibility, decided at the call site alongside
    /// `@Environment(\.accessibilityReduceMotion)`.
    static func reduced(_ base: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : base.speed(2)
    }
}
