import SwiftUI

/// `@main` entry. Two launch jobs once the pipeline fills the app in: register fonts
/// and inject the single `AppStore`. For now the scaffold just hosts `RootView`.
/// See ios/docs/engineering/01-architecture.md §4.
@main
struct AppTemplateApp: App {
    init() { FontRegistry.registerEmbeddedFonts() }   // embed + register the custom faces (01-arch §4)

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)   // light-mode only (design decision)
        }
    }
}
