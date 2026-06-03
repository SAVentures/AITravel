// LeadingGlyph.swift — the onboarding top-bar navigation affordance (06-screens §2.3; J-0.1).
//
// The one navigation glyph the immersive onboarding flow carries: a close (×) on the first step to
// dismiss the flow, a back chevron on every step after. Ports the mockup `.ob-iconbtn` glyph.
//
// Extracted from the former `OnboardingProgressHeader` (now split into the in-content
// `OnboardingProgressBar` + a separate FLOATING `GlassCircleButton` the screens overlay). The presenter
// (`OnboardingFlowPresenter.leadingGlyph`) derives which case to show; a screen maps it onto its own
// floating `GlassCircleButton(systemImage:accessibilityLabel:)`.
import SwiftUI

/// The leading glyph the onboarding flow shows — a close (×) on the first step, a back chevron after.
///
/// Conveys the one navigation affordance the flow carries (06-screens §2.3): dismiss the flow, or step
/// back. Each case maps to its SF Symbol + its accessibility identifier + role label, so a screen can
/// render it as a floating `GlassCircleButton` without re-deriving the mapping.
enum LeadingGlyph {
    /// Dismiss the whole flow (step 0) — `xmark`.
    case close
    /// Step back to the previous step — `chevron.left`.
    case back

    /// The SF Symbol for the glyph (mockup `.ob-iconbtn svg`).
    var systemImage: String {
        switch self {
        case .close: "xmark"
        case .back: "chevron.left"
        }
    }

    /// The dot-namespaced accessibility identifier, by case.
    var accessibilityID: String {
        switch self {
        case .close: "onboarding.close"
        case .back: "onboarding.back"
        }
    }

    /// A short verb/role label for assistive tech (the glyph carries no text).
    var accessibilityLabel: String {
        switch self {
        case .close: "Close"
        case .back: "Back"
        }
    }
}
