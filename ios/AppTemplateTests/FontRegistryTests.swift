import Testing
import UIKit
@testable import AppTemplate

/// Guards font embedding end to end: the `.ttf` files are bundled, `FontRegistry`
/// registers them, and the family names match the `foundations.css` tokens
/// (`--font-display: "Schibsted Grotesk"`, `--font-ui: "Hanken Grotesk"`). If a font
/// file is dropped, renamed, or fails to copy, this fails instead of silently falling
/// back to the system face. See docs/design-docs/01-typography.md T-6.
struct FontRegistryTests {
    @Test func customFacesAreRegistered() {
        FontRegistry.registerEmbeddedFonts()
        let families = Set(UIFont.familyNames)
        #expect(families.contains("Schibsted Grotesk"))
        #expect(families.contains("Hanken Grotesk"))
    }

    @Test func displayFaceResolvesToTheRealFont() {
        FontRegistry.registerEmbeddedFonts()
        let font = UIFont(name: "Schibsted Grotesk", size: 34)
        #expect(font != nil)
        #expect(font?.familyName == "Schibsted Grotesk")
    }
}
