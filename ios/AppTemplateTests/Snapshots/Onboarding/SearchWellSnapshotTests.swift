// SearchWellSnapshotTests.swift — Layer 3 render-snapshot lock for SearchWell.
//
// These tests are the lock on SearchWell at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — magnifier glyph, placeholder/value text,
// kbdHint mono capsule, fillTertiary pill well — fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   placeholder       — text is empty: magnifier + placeholder label + kbdHint mono hint co-occur.
//   with-value        — text is "Lisbon": magnifier + value text; kbdHint is hidden (text non-empty).
//   with-clear-button — text is "Lisbon" + showsClearButton:true: the xmark.circle.fill button
//                       is visible in place of the kbdHint (SearchWell.swift line 55–66). Confirms
//                       the clear affordance co-occurs with typed text and the kbdHint is absent.
//
// SearchWell requires a FocusState<Bool>.Binding (the caller owns focus state). We supply
// it from a wrapper struct that holds @FocusState so the binding is well-formed for the
// snapshot render. Focus is never active during a snapshot (no keyboard, no text entry).
// The `with-clear-button` case reuses the same @FocusState fixture wrapper, adding
// `showsClearButton: true` so the condition at SearchWell.swift line 55 is exercised.
//
// The well is embedded in a surfacePage canvas matching the #Preview padding so the PNG
// shows it in the context a real onboarding screen provides.
//
// Determinism (07-testing §6.4):
//   · No Date() — SearchWell is a pure display component with no clock dependency.
//   · No withAnimation — snapshots at rest; the well treatment is identical focused or not
//     (SearchWell.swift comment at line 17–18).
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · Fixtures mirror the #Preview values in SearchWell.swift.
//
// Baselines land in __Snapshots__/SearchWellSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

// MARK: - FocusState wrapper
//
// SearchWell's init requires a FocusState<Bool>.Binding. Swift Testing @Suite structs cannot
// hold @FocusState directly (it is a property wrapper for View types). We use a thin View
// wrapper that owns @FocusState and passes the binding into SearchWell, then snapshot
// the wrapper. The snapshot captures SearchWell's visual output — the wrapper adds no chrome.

private struct SearchWellFixture: View {
    @FocusState private var focused: Bool
    let text: String
    let placeholder: String
    var showsClearButton: Bool = false

    var body: some View {
        // Capture text into a @State-like constant binding suitable for snapshot rendering.
        // The binding never mutates during snapshot capture; the value is the initial text.
        SearchWell(
            text: .constant(text),
            placeholder: placeholder,
            showsClearButton: showsClearButton,
            focused: $focused
        )
    }
}

@Suite("SearchWell snapshots")
struct SearchWellSnapshotTests {

    // MARK: - placeholder

    /// Empty text: the magnifier glyph, placeholder label, and kbdHint mono capsule
    /// ("return ↵") co-occur. The well is the fillTertiary pill; no typed value is visible.
    @Test("placeholder — empty text: magnifier + placeholder + kbdHint visible together")
    @MainActor func placeholder() {
        assertDesignSnapshot(
            canvas {
                SearchWellFixture(text: "", placeholder: "Search a city…")
            },
            named: "placeholder"
        )
    }

    // MARK: - with-value

    /// Non-empty text ("Lisbon"): the magnifier glyph and the typed value are visible;
    /// the kbdHint is hidden (conditional on text.isEmpty — SearchWell.swift line 50).
    /// Confirms the kbdHint disappears and the value fills the available width.
    @Test("with-value — text Lisbon: magnifier + value text visible, kbdHint hidden")
    @MainActor func withValue() {
        assertDesignSnapshot(
            canvas {
                SearchWellFixture(text: "Lisbon", placeholder: "Search a city…")
            },
            named: "with-value"
        )
    }

    // MARK: - with-clear-button

    /// Non-empty text ("Lisbon") + `showsClearButton: true`: the `xmark.circle.fill` clear
    /// button appears in the trailing slot. Confirms the three signals co-occur in a single
    /// frame — magnifier glyph visible, typed text visible, clear button visible — and that the
    /// kbdHint is absent (the clear-button branch at SearchWell.swift line 55 takes priority
    /// over the kbdHint branch at line 67). No unit test can confirm that co-occurrence.
    @Test("with-clear-button — text Lisbon + showsClearButton:true: magnifier + value + clear button co-occur")
    @MainActor func withClearButton() {
        assertDesignSnapshot(
            canvas {
                SearchWellFixture(
                    text: "Lisbon",
                    placeholder: "Search a city…",
                    showsClearButton: true
                )
            },
            named: "with-clear-button"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the well in a surfacePage canvas with the same padding as the #Preview
/// in SearchWell.swift. Not a full-bleed screen; the well is a component (§6.2).
@MainActor
private func canvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
