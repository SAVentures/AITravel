/*
 The semantic motion tier — one easing personality, used with restraint. Two cubic-beziers are authored
 BY HAND from foundations.css (lines 132–133) because the codegen skips cubic-beziers, so these values
 are the contract: --ease-standard (0.32,0.72,0,1) and --ease-emph (0.22,1,0.36,1).

 Split is a rule, not a style: direct manipulation (taps, drags, sheet pulls) settles on the `smooth`
 spring to preserve gesture velocity; automatic/time-based moves use the fixed-duration ease-out curves.
 Reduce Motion: this token supplies curves only — `reduced` halves duration normally and yields nil under
 Reduce Motion; the caller owns the degradation (continuous motion goes static, springs flatten to a fade).
*/
import SwiftUI

enum Motion {

    // MARK: - Durations

    static let tap: Double = Primitive.durTap

    static let standard: Double = Primitive.durStandard

    static let sheet: Double = Primitive.durSheet

    static let slow: Double = Primitive.durSlow

    static let think: Double = Primitive.durThink

    // MARK: - Easings

    /// The house curve — critically-damped ease-out, for automatic / time-based moves.
    static func standard(_ duration: Double = Primitive.durStandard) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)
    }

    /// Emphasis curve for sheets / large moves — still ease-out, not a second personality.
    static func emph(_ duration: Double = Primitive.durSheet) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    /// Direct-manipulation spring (`.smooth` = bounce 0). Use only on user-driven motion so the
    /// gesture's velocity is preserved; never on an automatic transition.
    static let smooth: Animation = .smooth

    // MARK: - Reduce Motion

    static func reduced(_ base: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : base.speed(2)
    }
}
