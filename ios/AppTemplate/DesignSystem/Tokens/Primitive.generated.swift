// Primitive.generated.swift — GENERATED from mockups/foundations/foundations.css by .claude/scripts/generate-tokens.swift.
// DO NOT EDIT BY HAND. Change a value in foundations.css and re-run the generator (same commit).
// Primitives are raw values; reference them ONLY from the SEMANTIC token tier
// (ColorRole / Spacing / Typography / …), never from a view. See 05-design-system.md §1–2.
import SwiftUI

enum Primitive {
    static let accent700 = Color(.sRGB, red: 0.0424, green: 0.3464, blue: 0.7322, opacity: 1.0000)
    static let accent600 = Color(.sRGB, red: 0.0000, green: 0.4524, blue: 0.9383, opacity: 1.0000)
    static let accent500 = Color(.sRGB, red: 0.0000, green: 0.5185, blue: 1.0000, opacity: 1.0000)
    static let accent300 = Color(.sRGB, red: 0.5766, green: 0.7550, blue: 0.9949, opacity: 1.0000)
    static let accent100 = Color(.sRGB, red: 0.8293, green: 0.9175, blue: 1.0000, opacity: 1.0000)
    static let accent50 = Color(.sRGB, red: 0.9169, green: 0.9601, blue: 1.0000, opacity: 1.0000)
    static let onAccent = Color(.sRGB, red: 0.9796, green: 0.9909, blue: 1.0000, opacity: 1.0000)
    static let ink900 = Color(.sRGB, red: 0.1550, green: 0.1663, blue: 0.1784, opacity: 1.0000)
    static let ink800 = Color(.sRGB, red: 0.2458, green: 0.2561, blue: 0.2672, opacity: 1.0000)
    static let ink700 = Color(.sRGB, red: 0.3350, green: 0.3464, blue: 0.3578, opacity: 1.0000)
    static let ink600 = Color(.sRGB, red: 0.4082, green: 0.4180, blue: 0.4278, opacity: 1.0000)
    static let ink500 = Color(.sRGB, red: 0.5165, green: 0.5272, blue: 0.5371, opacity: 1.0000)
    static let ink400 = Color(.sRGB, red: 0.6130, green: 0.6220, blue: 0.6301, opacity: 1.0000)
    static let ink300 = Color(.sRGB, red: 0.7293, green: 0.7385, blue: 0.7469, opacity: 1.0000)
    static let ink200 = Color(.sRGB, red: 0.8383, green: 0.8454, blue: 0.8518, opacity: 1.0000)
    static let ink100 = Color(.sRGB, red: 0.9025, green: 0.9097, blue: 0.9162, opacity: 1.0000)
    static let ink50 = Color(.sRGB, red: 0.9461, green: 0.9509, blue: 0.9553, opacity: 1.0000)
    static let paper0 = Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0000)
    static let paper50 = Color(.sRGB, red: 0.9852, green: 0.9871, blue: 0.9896, opacity: 1.0000)
    static let paper100 = Color(.sRGB, red: 0.9531, green: 0.9587, blue: 0.9663, opacity: 1.0000)
    static let paper200 = Color(.sRGB, red: 0.9254, green: 0.9328, blue: 0.9429, opacity: 1.0000)
    static let paper300 = Color(.sRGB, red: 0.8979, green: 0.9071, blue: 0.9196, opacity: 1.0000)
    static let fillSecondary = Color(.sRGB, red: 0.5066, green: 0.5292, blue: 0.5482, opacity: 0.1200)
    static let fillTertiary = Color(.sRGB, red: 0.5066, green: 0.5292, blue: 0.5482, opacity: 0.0700)
    static let fillQuaternary = Color(.sRGB, red: 0.5066, green: 0.5292, blue: 0.5482, opacity: 0.0450)
    static let separator = Color(.sRGB, red: 0.3127, green: 0.3380, blue: 0.3590, opacity: 0.1600)
    static let scrim = Color(.sRGB, red: 0.0861, green: 0.0861, blue: 0.0861, opacity: 0.2200)
    static let destructive = Color(.sRGB, red: 0.8018, green: 0.1556, blue: 0.1539, opacity: 1.0000)
    static let day1 = Color(.sRGB, red: 0.7162, green: 0.4910, blue: 0.3355, opacity: 1.0000)
    static let day2 = Color(.sRGB, red: 0.3650, green: 0.5602, blue: 0.4377, opacity: 1.0000)
    static let day3 = Color(.sRGB, red: 0.3123, green: 0.5122, blue: 0.6313, opacity: 1.0000)
    static let day4 = Color(.sRGB, red: 0.5717, green: 0.4299, blue: 0.6160, opacity: 1.0000)

    static let typeTitleLargeSize: CGFloat = 28
    static let typeTitleSize: CGFloat = 18
    static let typeNameSize: CGFloat = 14
    static let typeBodySize: CGFloat = 14
    static let typeCalloutSize: CGFloat = 13
    static let typeSubheadSize: CGFloat = 13
    static let typeFootnoteSize: CGFloat = 12
    static let typeCaptionSize: CGFloat = 11
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 16
    static let s4: CGFloat = 24
    static let s5: CGFloat = 32
    static let s6: CGFloat = 40
    static let s7: CGFloat = 48
    static let s8: CGFloat = 56
    static let spaceXs: CGFloat = 4
    static let spaceSm: CGFloat = 8
    static let spaceMd: CGFloat = 12
    static let spaceLg: CGFloat = 16
    static let spaceXl: CGFloat = 24
    static let space2Xl: CGFloat = 32
    static let space3Xl: CGFloat = 48
    static let space4Xl: CGFloat = 64
    static let rTag: CGFloat = 6
    static let rThumb: CGFloat = 8
    static let rRow: CGFloat = 12
    static let rCard: CGFloat = 16
    static let rPill: CGFloat = 999
    static let strokeSelected: CGFloat = 2
    static let strokeSeparator: CGFloat = 1
    static let strokeProgressRing: CGFloat = 1.5
    static let strokeMapPinRing: CGFloat = 6

    static let weightRegular: Double = 400
    static let weightMedium: Double = 500
    static let weightSemibold: Double = 600
    static let weightBold: Double = 700
    static let durTap: Double = 0.1
    static let durStandard: Double = 0.22
    static let durSheet: Double = 0.32
    static let durSlow: Double = 0.42
    static let durThink: Double = 1.7
}
