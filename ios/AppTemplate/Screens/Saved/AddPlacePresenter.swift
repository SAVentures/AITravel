// AddPlacePresenter.swift — stateless derivation for the add-place method sheet (06-screens.md §3).
//
// Derives, from the store + ephemeral sheet state: the three "way to save" method rows (the prominent
// reel row + the standard screenshot/search rows), the "On your clipboard" detected-URL affordance, and
// the loading / write-error display read off the store. Returns DATA (value types / strings), never
// `View`s (06 §3.1) — the sheet assembles them. Stateless, rebuilt each `body` pass (06 §3.3).
//
// Mirrors DestinationStepPresenter: a value type over `(store, …)`, cheap, pure in → out (06 §3.4).
import Foundation

struct AddPlacePresenter {

    /// The single source of truth — read for the write-error / loading display (the methods + clipboard
    /// are static copy this milestone; the store carries the live write state).
    let store: AppStore

    /// The URL detected on the clipboard, surfaced ephemerally (a stubbed value the sheet seeds from its
    /// own `@State` — pasteboard reads are a separate concern; D-4 wires only the reel/clipboard write).
    let detectedURL: String?

    /// Whether the add write is in flight — the sheet's ephemeral `@State`, set around `await
    /// store.addPlace(...)`. Surfaces the 800ms `AddPlaceRequest.mockLatency` loading affordance (04 §7).
    let isAdding: Bool

    // MARK: - Header copy (mockup `.sheet-title` / `.sheet-sub`, add-place.html)

    var title: String { "Save a place" }

    var subtitle: String {
        "Hand me anything with a place in it — I'll read it, tag it, and add it to your wishlist."
    }

    // MARK: - Method rows (mockup `.method` / `.method.primary`)

    /// The three capture methods, in mockup order: the prominent reel/video paste (the one networked
    /// write this milestone), then screenshot, then search. The screen maps each to a sink (the reel row
    /// → `store.addPlace`; the others → a route/closure, no invented destination — D-4 / 06 §4.1).
    var methods: [WayToSaveRowModel] {
        [
            WayToSaveRowModel(
                id: "reel",
                title: "Paste a reel or video",
                subtitle: "TikTok, Reel, or YouTube — I'll pull out every place it names",
                systemImage: "play.rectangle",
                prominent: true
            ),
            WayToSaveRowModel(
                id: "screenshot",
                title: "From a screenshot",
                subtitle: "A map pin, a story, or a menu photo",
                systemImage: "photo"
            ),
            WayToSaveRowModel(
                id: "search",
                title: "Search for a place",
                subtitle: "Find it by name and pin it",
                systemImage: "magnifyingglass"
            ),
        ]
    }

    // MARK: - Clipboard affordance (mockup `.fwd-addr`)

    /// Whether the "On your clipboard" row should show — only when a URL was detected.
    var showsClipboard: Bool { detectedURL?.isEmpty == false }

    /// The fixed key label above the detected URL.
    var clipboardKey: String { "On your clipboard" }

    /// The detected URL, displayed truncated by the view (the mockup ellipsises the tail).
    var clipboardURL: String { detectedURL ?? "" }

    // MARK: - Write state (read off the store — banner, never toast/alert, 06 §6)

    /// True while the add write is in flight — drives the progress affordance on the prominent row + the
    /// clipboard paste button.
    var isLoading: Bool { isAdding }

    /// The write-error banner copy, present only when the optimistic `addPlace` rolled back
    /// (`store.writeError == .addPlace`). `nil` ⇒ no banner. The view pairs it with a glyph (never color
    /// alone — 02-color §6) and stamps `writeError.banner`.
    var writeErrorMessage: String? { store.writeError?.bannerMessage }
}
