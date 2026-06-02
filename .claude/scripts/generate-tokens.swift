#!/usr/bin/env swift
//
// generate-tokens.swift — codegen the design-system PRIMITIVE tokens from the
// mockups token source of truth (mockups/foundations/foundations.css) into
// ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift.
//
// foundations.css is the SINGLE SOURCE OF TRUTH for raw values. This script runs
// at foundation-freeze (and whenever a value changes) so the Swift primitives
// NEVER drift from the CSS by hand-transcription. The generated file is COMMITTED
// and MUST NOT be hand-edited. The SEMANTIC and COMPONENT token tiers are
// hand-authored in Swift (they are design intent, not transcription).
// See ios/docs/engineering/05-design-system.md §1–2.
//
// Convention — every primitive is a `:root` custom property `--<name>: <value>;`:
//   --ink-900:   oklch(0.23 0.02 265);  → Primitive.ink900   (Color)
//   --paper-0:   oklch(0.99 0.005 80);  → Primitive.paper0   (Color)
//   --space-4:   16px;                  → Primitive.space4   (CGFloat)
//   --radius-lg: 18px;                  → Primitive.radiusLg (CGFloat)
//   --dur-base:  240ms;                 → Primitive.durBase  (Double, seconds)
// Type is inferred from the value: oklch(...) → Color, …px → CGFloat,
// …ms → Double (seconds), bare number → Double. Compound values (shadows,
// gradients) are skipped — author those in the semantic tier by hand.
//
// Usage: swift .claude/scripts/generate-tokens.swift [foundations.css] [out.swift]

import Foundation

let args = CommandLine.arguments
let cssPath = args.count > 1 ? args[1] : "mockups/foundations/foundations.css"
let outPath = args.count > 2 ? args[2] : "ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift"

guard let css = try? String(contentsOfFile: cssPath, encoding: .utf8) else {
    FileHandle.standardError.write(Data("generate-tokens: cannot read \(cssPath)\n".utf8))
    exit(1)
}

// --- oklch(L C H [/ A]) → sRGB (0...1), standard Björn-Ottosson conversion ---
func srgb(fromOKLCH raw: String) -> (r: Double, g: Double, b: Double, a: Double)? {
    let inner = raw.replacingOccurrences(of: "oklch(", with: "").replacingOccurrences(of: ")", with: "")
    let slash = inner.split(separator: "/", maxSplits: 1)
    let c = slash[0].split(whereSeparator: { $0 == " " }).compactMap { Double($0) }
    guard c.count == 3 else { return nil }
    let alpha = slash.count > 1 ? (Double(slash[1].trimmingCharacters(in: .whitespaces)) ?? 1) : 1
    let (L, C, hDeg) = (c[0], c[1], c[2])
    let h = hDeg * .pi / 180
    let aLab = C * cos(h), bLab = C * sin(h)
    let l_ = L + 0.3963377774 * aLab + 0.2158037573 * bLab
    let m_ = L - 0.1055613458 * aLab - 0.0638541728 * bLab
    let s_ = L - 0.0894841775 * aLab - 1.2914855480 * bLab
    let l = l_*l_*l_, m = m_*m_*m_, s = s_*s_*s_
    func gamma(_ x: Double) -> Double {
        let v = max(0, min(1, x))
        return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1/2.4) - 0.055
    }
    return (gamma( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s),
            gamma(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s),
            gamma(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s),
            alpha)
}

func camel(_ kebab: String) -> String {
    let parts = kebab.split(separator: "-")
    guard let first = parts.first else { return kebab }
    return ([String(first)] + parts.dropFirst().map(\.capitalized)).joined()
}

var colors: [(String, String)] = []
var lengths: [(String, String)] = []
var scalars: [(String, String)] = []

let re = try! NSRegularExpression(pattern: "--([a-zA-Z0-9-]+)\\s*:\\s*([^;]+);")
for m in re.matches(in: css, range: NSRange(css.startIndex..., in: css)) {
    let name = String(css[Range(m.range(at: 1), in: css)!])
    let value = String(css[Range(m.range(at: 2), in: css)!]).trimmingCharacters(in: .whitespaces)
    let id = camel(name)
    if value.hasPrefix("oklch("), let c = srgb(fromOKLCH: value) {
        colors.append((id, String(format: "Color(.sRGB, red: %.4f, green: %.4f, blue: %.4f, opacity: %.4f)", c.r, c.g, c.b, c.a)))
    } else if value.hasSuffix("px"), let n = Double(value.dropLast(2)) {
        lengths.append((id, String(format: "%g", n)))
    } else if value.hasSuffix("ms"), let n = Double(value.dropLast(2)) {
        scalars.append((id, String(format: "%g", n / 1000)))
    } else if let n = Double(value) {
        scalars.append((id, String(format: "%g", n)))
    } // else: compound value — author in the semantic tier by hand
}

var out = """
// Primitive.generated.swift — GENERATED from \(cssPath) by .claude/scripts/generate-tokens.swift.
// DO NOT EDIT BY HAND. Change a value in foundations.css and re-run the generator (same commit).
// Primitives are raw values; reference them ONLY from the SEMANTIC token tier
// (ColorRole / Spacing / Typography / …), never from a view. See 05-design-system.md §1–2.
import SwiftUI

enum Primitive {

"""
for (id, v) in colors  { out += "    static let \(id) = \(v)\n" }
if !colors.isEmpty { out += "\n" }
for (id, v) in lengths { out += "    static let \(id): CGFloat = \(v)\n" }
if !lengths.isEmpty { out += "\n" }
for (id, v) in scalars { out += "    static let \(id): Double = \(v)\n" }
out += "}\n"

do {
    try out.write(toFile: outPath, atomically: true, encoding: .utf8)
    print("generate-tokens: \(colors.count) colors, \(lengths.count) lengths, \(scalars.count) scalars → \(outPath)")
} catch {
    FileHandle.standardError.write(Data("generate-tokens: cannot write \(outPath): \(error)\n".utf8))
    exit(1)
}
