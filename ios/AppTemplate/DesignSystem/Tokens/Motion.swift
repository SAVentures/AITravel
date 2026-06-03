// Motion.swift — the SEMANTIC motion tier (04-motion; 05-design-system.md §1). One restrained easing
// personality. The two cubic-beziers are hand-authored from foundations.css (codegen skips beziers) and
// ARE the contract: standard (0.32,0.72,0,1), emph (0.22,1,0.36,1). Split rule: direct manipulation uses
// the `smooth` spring (keeps gesture velocity), automatic moves use the curves; `reduced` → nil under
// Reduce Motion (caller owns degradation).
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
