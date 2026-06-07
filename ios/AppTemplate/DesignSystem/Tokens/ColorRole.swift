// ColorRole.swift — the SEMANTIC color tier (02-color §2; 05-design-system.md §1–3). Every color is
// referenced by ROLE — never a hex, `Color(...)` literal, or `Primitive.*` directly (J-0.2/J-2); one edit
// here reskins, and dark mode becomes a token swap (02-color §7). Restraint by OMISSION (02-color §4):
// no `buttonBackground`/`accentFill`/gradient role to misuse — `actionPrimary` + `stateNow` are the only
// accent surfaces (≤ twice/screen, never chrome or a fill; J-0.4/J-2.4); `dayMark*` are marks, not fills.
import SwiftUI

enum ColorRole {

    // MARK: - Text — the four-step label hierarchy (02-color §2)

    /// Titles, names, primary numerals. Headings are always primary (J-2.1).
    static let textPrimary: Color = Primitive.ink700

    /// Meta lines, sub copy, captions — the second body ink (body is binary; J-2.2).
    static let textSecondary: Color = Primitive.ink400

    /// Placeholder / disabled / past-state ONLY. Does **not** clear WCAG AA at body size, so it never
    /// carries active text (02-color §2 + §6, J-2.3).
    static let textTertiary: Color = Primitive.ink400

    /// Text drawn on the accent surface (on a `.glassProminent` CTA / action ground).
    static let textOnAccent: Color = Primitive.onAccent

    // MARK: - Background / surface — by layout, not by taste (02-color §2)

    /// The page ground.
    static let surfacePage: Color = Primitive.paper100

    /// Cards, cells, wells — a surface lives on the page, never on another card of the same tone (J-8.1).
    static let surfaceGrouped: Color = Primitive.paper0

    /// Nested surfaces (use sparingly; don't reach past `surfaceGrouped` to fake depth).
    static let surfaceElevated: Color = Primitive.paper0

    /// A FLAT wallet booking-row cell — the recessive grey ground a `BookingRow`/`ConfirmationRow` sits on,
    /// no shadow (mockup `.bk` / `.conf-row` `background: var(--paper-100)`). Distinct from `surfacePage`
    /// (the same paper-100 *page* ground) by ROLE: this names the cell, not the page (J-8.1, §10.1).
    static let surfaceBookingRow: Color = Primitive.paper100

    /// A PAST booking-row cell — the dimmed register ground (mockup `.bk.past` `background: var(--paper-50)`).
    /// The barely-grey alt surface carries the "past" register so the row's ink can stay legible (J-2.3).
    static let surfaceBookingRowPast: Color = Primitive.paper50

    // MARK: - Immersive takeover — the dark day-of boarding-pass ground (02-color §2; wallet OD-8)
    //
    // The day-of access card (`AccessCardView`) is a DARK takeover (mockup `.acc-screen` `background:
    // var(--ink-900)`): a focused scanning context where the white card + raised brightness read against
    // dark ink. This is the one inverse ground in the light-mode app — a deliberate, scoped role (the
    // semantic tier makes a future dark-mode a token swap, 02-color §7). Its on-ground text is the
    // inverse of the page hierarchy below: a faint white label/hint, never the ink `text*` roles.

    /// The dark immersive takeover ground (mockup `.acc-screen` background — `ink-900`). The one inverse
    /// surface; scoped to the day-of access takeover, never a card or page fill.
    static let surfaceImmersive: Color = Primitive.ink900

    /// A muted label/hint drawn ON the dark immersive ground (mockup `.acc-top .lab` / `.acc-hint` —
    /// `oklch(1 0 0 / ~0.55)`). The inverse of `textTertiary`; only valid over `surfaceImmersive`.
    static let textOnImmersive: Color = Primitive.onAccent.opacity(0.6)

    /// The faint translucent circle behind the close glyph on the dark ground (mockup `.acc-top .x`
    /// `background: oklch(1 0 0 / 0.12)`). NOT glass — a plain styled fill that avoids the offscreen-blank
    /// gap a real glass material leaves in a snapshot (wallet OD-8 / 06-screens §2.4).
    static let fillOnImmersive: Color = Primitive.onAccent.opacity(0.12)

    /// The close glyph ink on the dark ground (mockup `.acc-top .x` `color: oklch(1 0 0 / 0.85)`).
    static let glyphOnImmersive: Color = Primitive.onAccent.opacity(0.85)

    // MARK: - Fill — translucent overlays sized by shape (02-color §2)

    /// Medium shapes — a switch ground.
    static let fillSecondary: Color = Primitive.fillSecondary

    /// Large shapes — input fields, search bars, plain buttons.
    static let fillTertiary: Color = Primitive.fillTertiary

    /// Large complex areas — a grouped backing behind controls.
    static let fillQuaternary: Color = Primitive.fillQuaternary

    // MARK: - Separator — 1px, emphasis from space not thickness (02-color §2, J-4.3/J-10.4)

    /// The default hairline, over layered/translucent context (semi-transparent).
    static let separator: Color = Primitive.separator

    /// Over an opaque surface where translucency reads muddy (fully opaque).
    static let separatorOpaque: Color = Primitive.ink200

    // MARK: - Accent + state — emphasis only, ≤ twice per screen (02-color §4, J-0.4/J-2.4)

    /// The one CTA, links, focus ring.
    static let actionPrimary: Color = Primitive.accent600

    /// A now / selected dot — the state mark, paired with a glyph/label, never color alone (02-color §6).
    static let stateNow: Color = Primitive.accent500

    /// Destructive action (role: `.destructive`); never a decorative fill.
    static let destructive: Color = Primitive.destructive

    /// Dimming scrim behind modal/overlay content.
    static let scrim: Color = Primitive.scrim

    /// A low-alpha ink wash for photo legibility UNDER floating chrome (a full-bleed hero's foot, where an
    /// over-hero back/title must read). Distinct from `scrim` — that is the heavy MODAL dim (~0.22); this
    /// is a faint photo-legibility tint at ~the mockup's `.pd-hero .scrim` opacity (saved-shell.css). Used
    /// only as the dark stop of a clear→ink legibility gradient, never as a fill of size (J-0.4/J-2).
    static let heroScrim: Color = Primitive.ink900.opacity(0.12)

    // MARK: - Day marks — categorical state cues, never fills of size (02-color §2, J-2)

    static let dayMark1: Color = Primitive.day1
    static let dayMark2: Color = Primitive.day2
    static let dayMark3: Color = Primitive.day3
    static let dayMark4: Color = Primitive.day4

    // MARK: - Category marks — the saved-place taxonomy cue, never a fill of size (02-color §2, J-2)
    //
    // Each category aliases an existing day-mark hue (mockup `.cat-dot.*` / `.cat-*` text in
    // saved-shell.css); Shop is a deliberate neutral (no fifth hue to invent — the mockup uses ink).
    // Like `dayMark*` these are MARKS, paired with a glyph/label, not surfaces. The one named exception
    // is `categoryTint` below: a ≤ chip-scale low-alpha label tint (the mockup's `.cat-*` background),
    // NOT a card fill — restraint kept by the opacity, not by omission.

    static let categoryEat: Color = Primitive.day2   // sage
    static let categoryDrink: Color = Primitive.day1 // amber
    static let categoryStay: Color = Primitive.day3  // slate blue
    static let categoryDo: Color = Primitive.day4    // muted violet
    static let categoryShop: Color = Primitive.ink600 // neutral ink (mockup `.cat-shop` label)

    /// The category's mark color — for the leading dot / label ink on a `CategoryChip` or kicker.
    static func categoryMark(_ category: PlaceCategory) -> Color {
        switch category {
        case .eat:   return categoryEat
        case .drink: return categoryDrink
        case .stay:  return categoryStay
        case .do:    return categoryDo
        case .shop:  return categoryShop
        }
    }

    /// The low-alpha background behind a ≤ chip-scale category label (mockup `.cat-*` ~13% of the mark;
    /// Shop reuses `fillTertiary`, the neutral well wash). Sized for a chip, never a card fill (J-2).
    static func categoryTint(_ category: PlaceCategory) -> Color {
        switch category {
        case .eat:   return categoryEat.opacity(0.13)
        case .drink: return categoryDrink.opacity(0.13)
        case .stay:  return categoryStay.opacity(0.13)
        case .do:    return categoryDo.opacity(0.12)
        case .shop:  return Primitive.fillTertiary
        }
    }

    // MARK: - Source marks — the provenance cue (reel / screenshot / search), never a fill of size
    //
    // The SourceCard's icon tile is tinted by where a place came from (mockup `.srccard-ico.reel/.shot/
    // .search` in saved-shell.css): a reel reuses the violet day-mark, a screenshot the slate, and search
    // a neutral ink — paired with an SF Symbol, never colour alone (02-color §6). Like `dayMark*`/
    // `category*` these are MARKS; the tile background is the one named low-alpha exception below (a
    // 52pt tile, not a card fill — restraint kept by the opacity, not by omission).

    static let sourceReel: Color = Primitive.day4   // muted violet
    static let sourceScreenshot: Color = Primitive.day3 // slate blue
    static let sourceSearch: Color = Primitive.ink600 // neutral ink (mockup `.srccard-ico.search`)

    /// The source's mark colour — the glyph ink on a source-icon tile / provenance stamp.
    static func sourceMark(_ kind: SourceKind) -> Color {
        switch kind {
        case .reel:       return sourceReel
        case .screenshot: return sourceScreenshot
        case .search:     return sourceSearch
        }
    }

    /// The low-alpha tile background behind a source glyph (mockup `.srccard-ico.*` ~12–13% of the mark;
    /// search reuses `fillTertiary`, the neutral wash). Sized for a 52pt tile, never a card fill (J-2).
    static func sourceTint(_ kind: SourceKind) -> Color {
        switch kind {
        case .reel:       return sourceReel.opacity(0.12)
        case .screenshot: return sourceScreenshot.opacity(0.13)
        case .search:     return Primitive.fillTertiary
        }
    }

    // MARK: - Saved-at stamp — the timestamp pill on a source-grouped place row (accent-paired)
    //
    // The mockup `.src-place .stamp` is a small mono timestamp pill: `accent-700` ink on an `accent-50`
    // wash. This is the one accent-tinted *fill* in the saved vocabulary — earned because it is a tiny
    // chip-scale pill (not chrome, not a card; J-0.4 / J-2.4) and the accent pairs with the label text.

    /// The timestamp-stamp pill ink (mockup `.src-place .stamp` colour — `accent-700`).
    static let stampInk: Color = Primitive.accent700

    /// The timestamp-stamp pill wash (mockup `.src-place .stamp` background — `accent-50`).
    static let stampFill: Color = Primitive.accent50

    // MARK: - Accent wash — the one prominent CONTENT row tint (the add-sheet's first method)
    //
    // The mockup `.method.primary` (add-place.html) lifts the first "Paste a reel" method onto a faint
    // accent wash + a 1px accent ring — the way to mark the recommended path without spending the
    // budgeted accent CTA on a list row. Earned, not reflexive: it is the SINGLE prominent row on the
    // sheet (J-6.1), the accent reads as emphasis not chrome (J-0.4/J-2.4), and the tint is a low-L wash
    // (`accent-50`), never a saturated fill. The glyph tile inside it still uses `actionPrimary` +
    // `textOnAccent` (the budgeted accent surface) — paired with the title, never colour alone.

    /// The faint accent wash behind a single prominent content row (mockup `.method.primary` background —
    /// `accent-50`). A wash, not a saturated fill; reserved for the one recommended row (J-0.4/J-6.1).
    static let accentWashFill: Color = Primitive.accent50

    /// The 1px accent ring on that prominent row (mockup `.method.primary` `box-shadow: 0 0 0 1px
    /// accent-100`). The one place a coloured hairline is earned — it marks the recommended path, paired
    /// with the wash + title, not a side-tab accent border (08-slop A-1, J-10.4).
    static let accentWashRing: Color = Primitive.accent100

    // MARK: - Booking-type marks — the wallet booking-type taxonomy cue, never a fill of size (02-color §2, J-2)
    //
    // The wallet's booking *type* (lodging / transport / activity / dining / other) tints the icon tile of
    // a `BookingRow` / booking-detail hero / access-pass band (mockup `.bk-ico.*` / `.bd-ico.*` /
    // `.acc-ico` in wallet-shell.css). A distinct taxonomy from `category*` (the saved-place taxonomy) and
    // `source*` (provenance), but the SAME earned-tint class: each aliases an existing `day*` hue (NO new
    // primitive) and the tile background is a ≤ icon-tile low-alpha wash (~12–13% of the mark), not a card
    // fill — restraint kept by the opacity (J-2/J-0.4). Marks pair with an SF Symbol, never colour alone.

    static let bookingLodging: Color = Primitive.day1   // amber  (mockup `.bk-ico.lodging`)
    static let bookingTransport: Color = Primitive.day3 // slate blue (mockup `.bk-ico.transport`)
    static let bookingActivity: Color = Primitive.day4  // muted violet (mockup `.bk-ico.activity`)
    static let bookingDining: Color = Primitive.day2    // sage (mockup `.bk-ico.dining`)
    static let bookingOther: Color = Primitive.ink600   // neutral ink (mockup `.bk-ico.other`)

    /// The booking type's mark colour — the glyph ink on a booking icon tile / hero / pass band.
    static func bookingMark(_ type: BookingType) -> Color {
        switch type {
        case .lodging:   return bookingLodging
        case .transport: return bookingTransport
        case .activity:  return bookingActivity
        case .dining:    return bookingDining
        case .other:     return bookingOther
        }
    }

    /// The low-alpha tile background behind a booking glyph (mockup `.bk-ico.*` ~12–13% of the mark;
    /// `.other` reuses `fillTertiary`, the neutral wash). Sized for an icon tile, never a card fill (J-2).
    static func bookingTint(_ type: BookingType) -> Color {
        switch type {
        case .lodging:   return bookingLodging.opacity(0.12)
        case .transport: return bookingTransport.opacity(0.13)
        case .activity:  return bookingActivity.opacity(0.12)
        case .dining:    return bookingDining.opacity(0.13)
        case .other:     return Primitive.fillTertiary
        }
    }
}
