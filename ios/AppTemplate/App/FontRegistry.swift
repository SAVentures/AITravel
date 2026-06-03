import CoreText
import Foundation
import OSLog

/// Registers the embedded custom faces (Schibsted Grotesk · Hanken Grotesk) with the
/// font manager at launch, so the design-system `Typography` roles can resolve them via
/// `Font.custom(_:size:relativeTo:)`. A custom face gets no Dynamic Type for free — it
/// must be registered and bound to a text style (01-typography.md T-6.1, T-6.3). A
/// missing file simply falls back to the system face of the same role.
/// Called once from `AppTemplateApp.init()` (01-architecture.md §4).
enum FontRegistry {
    private static let log = Logger(subsystem: "AppTemplate", category: "fonts")

    /// Registers every `.ttf` bundled with the app. Idempotent in practice: re-registering
    /// an already-registered face (previews, tests) reports an error we treat as benign.
    static func registerEmbeddedFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                log.debug("skipped \(url.lastPathComponent, privacy: .public): \(String(describing: error?.takeRetainedValue()), privacy: .public)")
            }
        }
    }
}
