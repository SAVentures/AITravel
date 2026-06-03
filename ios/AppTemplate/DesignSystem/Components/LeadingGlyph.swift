/*
 The one navigation glyph onboarding carries: close (×) on the first step to dismiss, back chevron after.
 Ports the mockup `.ob-iconbtn` glyph. The presenter derives the case; a screen maps it onto its own
 floating `GlassCircleButton(systemImage:accessibilityLabel:)`.
*/
import SwiftUI

enum LeadingGlyph {
    case close
    case back

    var systemImage: String {
        switch self {
        case .close: "xmark"
        case .back: "chevron.left"
        }
    }

    var accessibilityID: String {
        switch self {
        case .close: "onboarding.close"
        case .back: "onboarding.back"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .close: "Close"
        case .back: "Back"
        }
    }
}
