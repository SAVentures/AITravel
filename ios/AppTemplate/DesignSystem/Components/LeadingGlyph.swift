/*
 The one navigation glyph onboarding carries: close (×) on the first step to dismiss, back chevron after.
 Ports the mockup `.ob-iconbtn` glyph. The presenter derives the case; a screen feeds it straight into the
 `GlassCircleButton(_:action:)` convenience init, which makes THIS enum the single owner of the
 glyph → assistive-tech label → accessibility-id mapping for the back/close navigation chrome.
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
