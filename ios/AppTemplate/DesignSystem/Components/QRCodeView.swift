// QRCodeView.swift — a real, deterministic QR renderer (05-design-system.md §8; J-8 / J-12.4).
// Ports the access-card mockup `.acc-qr .code` (a static `qr.svg`) to a REAL, data-driven QR rendered
// from the pass payload with CoreImage's `CIQRCodeGenerator` (OD-5: render a real QR, no dependency).
//
// DETERMINISTIC by construction (the L3 snapshot lock depends on it): a fixed `payload` → identical
// matrix → identical pixels. No animation, no clock, no randomness — the generator is a pure function of
// the payload bytes + correction level. The CIImage is upscaled with an INTEGER nearest-neighbour
// transform (no smoothing) so the matrix stays crisp, then SwiftUI draws it with `.interpolation(.none)`
// so scaling to the caller's frame never blurs the modules (the "no smoothing" rule).
//
// Light-mode: black modules on a clear ground (the caller's `paper-0` card shows through), per
// access-card.html. CONTENT, never glass (J-0.1). Size is driven by the CALLER's frame
// (`Sizing.Component.accessQRSide` at the call site) — this view fills whatever frame it's given.
//
// No domain object, no AppStore (05 §8). SEMANTIC tokens only (the radius); the QR colours are intrinsic
// to a scannable code (black-on-light), not a themeable surface role.
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// A real QR code rendered from `payload`. Deterministic (fixed payload → identical pixels), light-mode
/// (black on clear), nearest-neighbour scaled to fill the caller's frame. Screen-agnostic — a string in,
/// no `AppStore` (05 §8).
struct QRCodeView: View {

    /// The string encoded into the QR (a boarding-pass / confirmation payload).
    let payload: String

    var body: some View {
        Group {
            if let image = Self.qrImage(for: payload) {
                Image(decorative: image, scale: 1)
                    // Nearest-neighbour: scaling the small matrix to the frame must never smooth the
                    // modules (a blurred QR is unscannable). This is the "no smoothing" rule.
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                // A payload should always encode; if CoreImage ever returns nil, fall back to a neutral
                // well rather than a broken-image box (J-12.4, 08-slop G-1).
                ColorRole.fillTertiary
            }
        }
        .clipShape(.rect(cornerRadius: Radius.thumb))
        // The code is decorative for VoiceOver — the caller (the pass card) speaks the confirmation; a
        // pixel matrix has no meaningful label of its own.
        .accessibilityHidden(true)
    }

    // MARK: - Generation — pure + deterministic (no clock, no animation)

    /// One shared software `CIContext` — building a context per render is wasteful, and a single context
    /// keeps the rasterisation path identical run-to-run (snapshot stability).
    private static let context = CIContext(options: [.useSoftwareRenderer: true])

    /// Generate the QR as a `CGImage` from `payload`. Pure: same input → byte-identical output.
    /// - `correctionLevel` "M" (~15%) matches a typical boarding-pass density.
    /// - The 1pt matrix is upscaled by an integer factor with a non-smoothing transform so the modules
    ///   stay square before SwiftUI lays it into the frame.
    private static func qrImage(for payload: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let matrix = filter.outputImage else { return nil }
        // Upscale the tiny module matrix by a fixed integer factor (nearest-neighbour) so the rendered
        // CGImage carries crisp pixels; SwiftUI then fits it to the caller's frame.
        let scaled = matrix.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        return context.createCGImage(scaled, from: scaled.extent)
    }

    /// A fixed nearest-neighbour upscale of the raw matrix (~1pt/module). Constant → deterministic.
    private static let scaleFactor: CGFloat = 12
}

// MARK: - Preview — a deterministic code (05 §8, §10)

#Preview("QR code") {
    QRCodeView(payload: "TP201|LIS-JFK|7XQK2M")
        .frame(width: Sizing.Component.accessQRSide, height: Sizing.Component.accessQRSide)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
