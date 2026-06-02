# Comprehensive iOS Design References

This is a machine-aggregated grounding corpus for authoring the v2 AI Travel iOS design docs (typography, color, layout/spacing, motion, components, accessibility, navigation, design tokens, visual principles, anti-slop, and craft teardowns). It was compiled from ~100 sources spanning Apple's Human Interface Guidelines, WWDC sessions, official API docs, practitioner blogs, GitHub references, and Apple Design Award teardowns. Each rule is deduped and sharpened across briefs, with numbers, API names, and do/don't specifics preserved and a brief source citation per bullet.

## Typography

- Default to system fonts and reach for the four families by role: SF Pro for UI body/chrome (`.system`), SF Mono for timestamps/numbers/code (`.system(design: .monospaced)`), New York for editorial reading (`.system(design: .serif)`), SF Pro Rounded (`.rounded`) for soft/playful — system fonts get free Dynamic Type, optical sizing, and per-size tracking; custom fonts do not unless wired up (Apple HIG Typography / WWDC20 10175).
- Drive every text size from the 11 built-in Dynamic Type text styles, not hardcoded sizes; default (Large) point sizes: largeTitle 34, title1 28, title2 22, title3 20, headline 17, body 17, callout 16, subhead 15, footnote 13, caption1 12, caption2 11 — each auto-adjusts tracking and leading per size (Apple HIG Typography).
- Establish hierarchy with the text-style ladder plus weight, not arbitrary point sizes: Body and Headline are both 17pt and differ only by weight (Body Regular, Headline Semibold) (Apple HIG Typography table).
- Keep body text at the 17pt floor and never render any text below 11pt; Footnote=13pt and Caption1=12pt are for secondary/meta text, Caption2=11pt is the smallest standard style (Apple HIG Typography table).
- Let optical size switch automatically at the 20pt boundary: SF Text below 20pt, SF Display at 20pt+; with variable SF Pro the transition is continuous between 17–28pt and stays synced to point size — never manually pick Text vs Display (WWDC20 10175 / Apple HIG).
- Treat tracking as size-specific and inverse to size (HIG tables run ~+41 at 6pt down to 0 at 80pt+) and let the system supply it; if customizing use `.tracking(_:)` (semantic, size-aware), not `.kerning()` (WWDC20 10175 / Apple HIG tracking tables).
- SF Pro tracking is automatic and size-specific: 17pt body ≈ -0.43pt (-2.5%), 15pt secondary ≈ -0.24pt (-1.6%), 13pt tertiary ≈ -0.08pt (-0.61%) — never apply one global letter-spacing value across sizes (learnui.design iOS Font Guidelines).
- Leading is baked into each style (body 22, headline 22, callout 21, subhead 20, footnote 18, caption1 16, caption2 13, title3 24, title2 28, title1/largeTitle 34/41); adjust only ±2pt via `.leading(.tight)`/`.loose`, don't hand-tune line spacing otherwise (Apple HIG / WWDC20 10175).
- Derive emphasis variants from the style via `.bold()`/`.italic()` so they still scale (e.g. `Font.footnote.bold()` = 13pt Semibold; emphasized title1 = 28pt Bold) (WWDC20 10175).
- Scale custom fonts with `Font.custom(_:size:relativeTo:)` (e.g. `Font.custom("Avenir-Medium", size: 34, relativeTo: .title)`); without `relativeTo` it only scales off `.body`, and `.custom(_:fixedSize:)` opts out of scaling entirely (WWDC20 10175 / useyourloaf).
- In UIKit/bridging, scale custom fonts via `UIFontMetrics(forTextStyle:).scaledFont(for:)` and set `adjustsFontForContentSizeCategory = true`; use `UIFontMetrics.default.scaledValue(for:)` for arbitrary CGFloats (WWDC20 10175 / useyourloaf).
- Scale non-text metrics (padding, icon sizes, spacing) with `@ScaledMetric(relativeTo: .body) var padding: CGFloat = 20` (must be `var`); pin to a relevant text style so layouts don't break at large sizes (WWDC20 10175 / avanderlee).
- Support the full Dynamic Type range — iOS 18+ has 12 sizes (7 standard xSmall–xxxLarge + 5 accessibility AX1–AX5, body up to ~310% at AX5); test at AX5 and cap only specific surfaces with `.dynamicTypeSize(...DynamicTypeSize.accessibility1)`, never disable scaling globally (Apple HIG Typography).
- Use SF Mono / `.monospaced` (or `.monospacedDigit()` on a proportional font) for timestamps, prices, distances, and durations so fixed advance widths keep numbers vertically aligned in lists/tables (Apple HIG Typography).
- Define a small set of named semantic type roles mapped onto text styles + weight (e.g. screenTitle→.largeTitle/.title, sectionHeader→.headline, body→.body, metaLabel→.footnote/.caption mono, captionSecondary→.caption2) so one mapping changes everywhere (Apple HIG Typography / WWDC20 10175).
- Enable tightening-for-truncation with `.allowsTightening(true)` (UIKit `allowsDefaultTighteningForTruncation`) so long strings tighten tracking before truncating rather than dropping to an off-scale size (WWDC20 10175).
- Keep reading line length to roughly 50–75 characters; a 390pt iPhone column satisfies this for body text, but watch iPad and landscape where full-width text becomes fatiguing (Apple HIG Typography).

## Color

- Map every color to a semantic role (`.text(.primary)`, `.background(.secondary)`, `outlineTertiary`), never a raw RGB value, and centralize so one edit re-themes the app; don't redefine the meaning of dynamic system colors (Apple HIG Color / ColorTokensKit).
- Prefer Apple's dynamic system colors (`UIColor.label`, `.systemBackground`, `Color.accentColor`, `.primary`/`.secondary`) so light/dark and accessibility settings adapt for free; hardcoded colors break dark mode (Apple HIG Color / Apple Color docs).
- Use the 4-step label hierarchy for text emphasis instead of custom grays: `.label` > `.secondaryLabel` > `.tertiaryLabel` > `.quaternaryLabel`, all semi-transparent so they composite over any background (Apple UIKit / Sarunw Dark color cheat sheet).
- Choose grouped vs system background sets by layout and reserve secondary for cards: grouped uses `.systemGroupedBackground` (container) > `.secondarySystemGroupedBackground` (card/cell) > `.tertiarySystemGroupedBackground` (nested); plain views use `.systemBackground`/`.secondary…`/`.tertiary…` (contagious.dev / Apple UIKit).
- Use fill colors (not backgrounds) for UI-element overlays sized by shape: `.secondarySystemFill` (medium, switch bg), `.tertiarySystemFill` (large — input fields, search bars, buttons), `.quaternarySystemFill` (large complex areas) — fills are translucent overlays atop backgrounds (Apple UIKit).
- Hit WCAG AA: 4.5:1 for body text, 3:1 for large text (≥18pt regular or ≥14pt bold); target ~5:1 to leave margin against hex/rounding drift, AAA is 7:1 (Ethan Gardner / LogRocket OKLCH / WCAG).
- Never use color as the sole signal — pair color-coded state with a glyph, label, shape, or pattern so it survives color-blindness and Reduce Transparency (Apple HIG Accessibility/Color).
- Build ramps in OKLCH/LCH so equal numeric steps look equal: OKLCH is perceptually uniform (equal L looks equally bright across hues) and avoids CIELab's blue-to-purple hue drift; used by CSS Color 4, Tailwind v4, and ColorTokensKit (ColorTokensKit / LogRocket OKLCH / color-ramp.com).
- Generate a multi-stop ramp per hue rather than ad-hoc shades — ColorTokensKit emits 20-stop ramps (_50 near-white to _1000 near-black) via perceptually-uniform interpolation, with semantic accessors (foreground/background/outline × primary/secondary/tertiary) resolving the right stop per light/dark (ColorTokensKit-Swift).
- Tint neutrals toward the brand hue (0–100% primary influence) so grays harmonize with the accent; keep tint chroma low (~0.005–0.01 OKLCH) so neutrals still read neutral — pure neutrals clash against tinted surfaces (incluud color-contrast-checker / Rampa).
- Practice restraint: one accent used sparingly to mark key actions, lean monochromatic with shades of one hue plus tinted neutrals, and cap the palette at ≤4 colors (Altamira / Envato / Apple HIG accentColor).
- Set the global accent once via the asset-catalog `AccentColor` (or `.tint`/`.accentColor`) so controls inherit it app-wide; don't overload it per-screen (Apple Specifying color scheme / Apple accentColor).
- In dark mode, elevate by getting lighter, not by inverting — iOS uses darker base and lighter elevated background values and swaps to elevated automatically when a view is smaller than full screen (Slide Over, split view) (contagious.dev / Medium Dark Mode).
- Use the right separator token for the surface: `.separator` is semi-transparent for layered/translucent contexts, `.opaqueSeparator` is fully opaque for opaque surfaces where translucency looks muddy (Apple UIKit / Sarunw).
- Verify pairings programmatically — ColorTokensKit's `contrastRatio(to:method:)` supports WCAG 2.x (1–21) and APCA (signed Lc); gate token pairs in tests rather than eyeballing (ColorTokensKit-Swift).

## Layout & Spacing

- Build the entire spacing scale on an 8pt grid (8, 16, 24, 32, 40, 48, 56) using 4pt only as a fine sub-step (icon-to-label gaps, dense metadata); aligning to 8 keeps rhythm crisp at @2x/@3x (Cieden / Apple HIG).
- Enforce internal ≤ external spacing for grouping: padding inside an element must be ≤ the margin separating it from siblings (a card with 16pt internal padding needs ≥16pt, commonly 24pt, gap to the next group) or distinct cards read as one block (Cieden).
- Standard horizontal screen margin is 16pt compact, ~20pt on larger widths; bare `.padding()` applies the 16pt system default — prefer `.padding(.horizontal)` so it tracks the layout-margin guide instead of hardcoding (Apple HIG Layout / SwiftUI default padding).
- Minimum interactive tap target is 44×44pt; pad small glyphs (e.g. a 24pt icon) out to 44pt rather than shrinking the touch region (Apple HIG).
- Always lay critical content inside the safe area (UIKit `safeAreaLayoutGuide` / SwiftUI safe-area system); top inset covers status (20pt) + nav (44pt), bottom is 34pt for the Face ID home indicator — reserve `.ignoresSafeArea()` for intentional full-bleed backgrounds only (Apple HIG / safeAreaInsets docs).
- Cap line length with a readable measure: UIKit `readableContentGuide` (~600–700pt max text width); SwiftUI lacks a direct equivalent, so widen safe-area/contentMargins on `.regular` horizontalSizeClass (iPad) rather than letting text run edge-to-edge (Apple HIG readableContentGuide / Swift with Majid).
- Shift scrollable content with `.contentMargins(edge, value, for: .scrollContent)` (keeps bars stationary) and move only the scrollbar with `.scrollIndicators`; use `.safeAreaPadding` when you want content + indicators shifted together (Swift with Majid — Content margins).
- Pick one of three iOS 26 shape types for every rounded element: Fixed (constant radius), Capsule (radius = half container height; the system default for sliders, switches, bars, buttons in touch layouts), or Concentric (radius derived from parent minus padding) (WWDC25 356).
- Nest shapes concentrically so inner radius = outer radius − padding (outer 24pt with 12pt padding → ~12pt inner corners); let the system compute it to avoid "pinched" or "flared" corners (WWDC25 356 / nilcoalescing).
- Wire concentricity in SwiftUI with `.containerShape(.rect(cornerRadius: 24))` on the parent, then `ConcentricRectangle()` or `.rect(corners: .concentric)` on the child; use `.concentric(minimum:)` for a floor and `isUniform: true` for equal corners (container must conform to `RoundedRectangularShape`) (nilcoalescing ConcentricRectangle).
- Near a phone screen edge use a capsule set in with extra margin so it breathes; near a window edge (iPad/Mac) align a concentric shape to the window's corner radius (WWDC25 356).
- Optically center rather than just mathematically center — trust the eye over pixel-equal insets when a shape's visual mass is asymmetric (e.g. a play triangle nudged right in a circle) (WWDC25 356).
- Keep line height on the same 4/8 rhythm as spacing (e.g. 14/15/21pt) so baselines snap to the vertical grid and paragraphs stack predictably (Cieden).
- Use a deliberate stack ladder of gap tokens — tight 4–8pt (label/value, icon/text), default 16pt (within a card), section 24–32pt (between groups) — increasing gap signals stronger separation; don't sprinkle arbitrary values (Cieden / designsystems.com).
- Design adaptively against layout-margin and safe-area guides (SwiftUI `safeAreaPadding` gated on `horizontalSizeClass`), not fixed device sizes; landscape side insets differ by device (Dynamic Island ~59–62pt vs notch ~44–50pt) — never hardcode them (Apple HIG Layout / safeAreaInsets).

## Motion

- Use springs for user-driven motion (taps, drags, swipes, toggles, sliders, pull-to-refresh) because they preserve gesture velocity and "pick up right where the gesture ends"; reserve ease curves (easeInOut/easeOut) for automatic, time-based motion the system starts (WWDC23 10158).
- Spring is the default — plain `withAnimation { }` (no argument) gives a spring (the `.smooth` preset, bounce 0) since iOS 17; only specify a curve to override the default (WWDC23 10158 / 10156).
- Prefer the duration/bounce spring model for new code: `.spring(duration: 0.6, bounce: 0.2)` where bounce ranges -1.0…1.0 (0 = smooth, 0.15 subtle, 0.3 noticeably playful, >0.4 too extreme, <0 scroll-like decay) — set duration first for pacing, then bounce for character (WWDC23 10158).
- Know the three presets: `.smooth` (no bounce, serious UI, the `withAnimation` default), `.snappy` (small bounce, brisk feedback), `.bouncy` (larger bounce, playful); tune via `.snappy(duration: 0.4)` or `.bouncy(duration: 1.0, extraBounce: 0.2)` (WWDC23 10156).
- Legacy spring defaults: `.spring()` = response 0.55, dampingFraction 0.825, blendDuration 0; dampingFraction is inverse to springiness (0.5 bouncy, 0.75 balanced, 0.95 subtle, >1.0 overdamped) — use response ~0.3 for button presses, ~0.9 for dramatic modal transitions (Apple Animation.spring docs / createwithswift).
- Use `.interactiveSpring(response:dampingFraction:blendDuration:)` for live, continuously-updating gesture tracking — lower latency, higher blendDuration than a settling `.spring()` (Apple interactiveSpring docs / WWDC23 10158).
- Prefer `.animation(_:value:)` over `withAnimation` to avoid accidental animations: `withAnimation` animates all affected attributes in the transaction, while `.animation(.bouncy, value: selected)` scopes to one value and lets you stack different curves per attribute (WWDC23 10156).
- Animate transform-style effects (`scaleEffect`, `offset`, `rotationEffect`, opacity, shadow radius, color) which interpolate cheaply via `Animatable`/`VectorArithmetic`; avoid animating layout-recomputing properties (width/height/padding), and use `geometryGroup()` (iOS 17+) / `drawingGroup()` to apply transforms without affecting ancestor layout (SwiftUI Lab / SwiftDifferently / WWDC23 10156).
- Spring interruptions merge and retarget (`shouldMerge = true`: current velocity carries into the new target) so they feel continuous; timing-curve animations have `shouldMerge = false` and combine additively — another reason to use springs for anything interruptible (WWDC23 10156 / 10158).
- Honor Reduce Motion via `@Environment(\.accessibilityReduceMotion)` (UIKit `UIAccessibility.isReduceMotionEnabled`): swap large transform/oscillation animations for a dissolve/cross-fade or color shift, but don't remove animation that conveys meaning; test both settings (createwithswift / Apple HIG Motion).
- Avoid the patterns Apple flags: oscillating motion with large amplitude near 0.2 Hz, and large animations simulating objects flying in/out of the full screen — keep amplitudes small and contained (Apple HIG Motion).
- Never rely on animation alone to communicate something important — pair motion with a static/textual cue since people may not see it (Apple HIG Motion).
- Tap feedback must commit in ≤100ms — run the press/highlight visual immediately, then play the spring; don't gate the press state behind an animation (measured tap-to-haptic latency runs ~114ms) (AITravel CLAUDE.md / Alibaba lifetips study).
- Reserve success/warning/error notification haptics for completed flows, not in-flight micro-interactions; use `UIImpactFeedbackGenerator` (light/soft) for taps/toggles and call `prepare()` before the user acts (~38ms saving) — preparing and firing in the same instant gives no benefit (Newly / Sarunw UIFeedbackGenerator).
- Design haptics into interactions tied to discrete state changes with `.sensoryFeedback(.success, trigger:)` / `.impact` / `.selection`, matching the haptic class to meaning (Things 3 fires Taptic feedback on pickup-to-drag, Magic Plus deform, task check-off, pull-to-search) (MacStories Things 3 / Apple Animation and haptics).
- Make draggable/primary controls subtly deform under direct manipulation (Things 3's Magic Plus "ever so slightly deforms its shape" as you drag) — tactility is the object visibly responding to the finger, not just translating (Cultured Code / MacStories).
- Keep continuous/looping motion to a single purposeful element (e.g. one AI "thinking" strip); `.repeatForever(autoreverses:)` for loops, used sparingly and disabled under Reduce Motion (AITravel CLAUDE.md, `--dur-think 1600ms`).
- Use critically-damped, non-bouncy ease-out `cubic-bezier(0.32, 0.72, 0, 1)` for chrome/transitions with a fixed duration ladder — fast 120ms, base 240ms, long 320ms (sheets/screens), map 480ms (camera/pin/reorder), think 1600ms; map to `.timingCurve(0.32,0.72,0,1, duration:)` or a bounce-0 spring, reserving bouncy springs for direct manipulation (AITravel CLAUDE.md).
- Keep standard transitions short (~200–500ms) and never multi-second decorative motion; anything animating >1–2s without a functional reason reads as gratuitous (Apple HIG Motion / AITravel tokens).

## Components

- Every interactive control gets a minimum 44×44pt hit target (buttons, list accessories, toolbar items, tab items); pad the touch area even when the glyph is smaller — inline text links are the only common exception (Apple HIG / LogRocket).
- Pick the SwiftUI `buttonStyle` by hierarchy tier, not look: `.glassProminent`/`.borderedProminent` = single primary action, `.glass`/`.bordered` = secondary, `.plain`/`.borderless` = tertiary/inline; `.glass`/`.glassProminent` require iOS 26 + Xcode 26, and use one prominent button per context (avanderlee / Apple glassProminent docs).
- Tag dangerous actions with `Button(role: .destructive)` (system renders red and announces intent to assistive tech) and pair with `role: .cancel` in dialogs — don't hand-color a button red to fake destructive semantics (avanderlee).
- Liquid Glass goes only on the floating navigation layer (nav bars, toolbars, tab bars, bottom accessories, floating/circle buttons, sheets, popovers, menus); never on lists, tables, cards, media, or any surface holding primary content (createwithswift / letsdev).
- Keep text off glass on a solid layer, holding WCAG 4.5:1, and honor Reduce Transparency / Increase Contrast which fall back to more opaque backgrounds (letsdev / designedforhumans).
- A tab bar holds 3–5 stable destinations that are "places" (nouns), never actions — keep +, Scan, Create, Pay, and onboarding out of it; labels ~11pt (Medium design-bootcamp / learnui.design).
- In iOS 26 the tab bar is an inset (~21pt from edges) floating Liquid Glass capsule that can compact to the active tab on scroll-down and re-expand on scroll-up; only adopt minimize-on-scroll if tabs act as background-mode selectors (learnui.design / Medium design-bootcamp).
- Use a tab-bar accessory view for persistent global UI (mini player, active order, filter), not a stacked toolbar; never stack a bottom toolbar + tab bar on one screen, and don't hide the tab bar on routine detail/form screens — hide only for modals or immersive media (Medium design-bootcamp).
- Drive sheet height with `.presentationDetents([.medium, .large])` (.medium ≈ half, .large = full; custom via `.fraction(_:)`/`.height(_:)`); the system shows the drag grabber automatically at 2+ detents, override with `.presentationDragIndicator(.visible/.hidden)` (nilcoalescing / Apple presentationDetents docs).
- Use a sheet for a subordinate, swipe-dismissible subtask; switch to `fullScreenCover` for complex/immersive flows where accidental dismissal is costly, and don't trap swipe-to-dismiss on unsaved changes without a confirmation dialog (Apple HIG Sheets).
- Shape toolbar/nav buttons via `ToolbarItem` placement, which auto-applies glass (`confirmationAction` → glassProminent; cancellationAction/primaryAction get matching glass); split groups with `ToolbarSpacer(.flexible/.fixed)` so capsules don't merge into one blob (Swift with Majid — Glassifying toolbars).
- Set button shape with `buttonBorderShape` (`.automatic`, `.capsule`, `.circle`, `.roundedRectangle(radius:)`) — Liquid Glass nav buttons are typically circles, inline content buttons capsules/rounded rects — and size with `controlSize` (`.mini`…`.extraLarge`) rather than hardcoding frames (avanderlee / learnui.design).
- List typography: 17pt primary row text (body), 15pt secondary (subheadline), 13pt captions/footnotes often at reduced opacity; never below 11pt even at the smallest Dynamic Type setting (learnui.design / Apple HIG).
- Use standard list accessories on the trailing edge to signal behavior: chevron = drills in, checkmark = selected in a choosing context, switch = toggles in place, inline text button = discrete action — don't show a chevron on a non-navigating row (learnui.design iOS 26 list cells).
- Render custom button states from `ButtonStyle` configuration, not gestures: read `configuration.isPressed` (commit press in ≤100ms), `configuration.role` for destructive/cancel, and the `.disabled()` environment for the dimmed state (avanderlee / Apple HIG).
- The navigation bar uses a 34pt bold large title that collapses to a 17pt semibold centered inline title on scroll, with a glass/blur background; reserve ~21pt for the home indicator (learnui.design).

## Liquid Glass (iOS 26)

- Apply glass with `glassEffect(_ glass: Glass = .regular, in shape: S = Capsule, isEnabled: Bool = true)`; customize via `.glassEffect(in: .rect(cornerRadius: 16.0))` or `.circle`, and apply it last in the modifier chain after other appearance modifiers (conorluddy / Xcode 26 system prompts).
- Use only the navigation/chrome layer for glass (nav bars, tab bars, toolbars, sidebars, menus, floating controls) — never lists, tables, media, scrollable content, or full-screen backgrounds (conorluddy / Apple HIG Materials).
- Never stack glass on glass — it can't sample other glass and produces confusing hierarchy; group nearby elements in one `GlassEffectContainer` instead of nesting modifiers (conorluddy).
- Wrap multiple glass elements in `GlassEffectContainer(spacing:)` for a shared sampling region (mandatory for correct blending, morphing, and performance) — without it glass can't sample neighbors and you pay a per-element cost (Xcode 26 system prompts / conorluddy).
- The container `spacing` parameter is the morph/merge threshold: elements closer than `spacing` blend and morph together — match it to your `HStack` spacing (e.g. both 40.0) (Xcode 26 system prompts / conorluddy).
- Enable morphing with `glassEffectID(_:in:)` in a shared `@Namespace` — requires all four: same container, each view has a glassEffectID with the shared namespace, views are conditionally shown/hidden, and the toggle runs inside `withAnimation` (e.g. `.bouncy`) (Xcode 26 system prompts / conorluddy).
- Merge distant glass elements with `glassEffectUnion(id:namespace:)` to fuse separate views into one continuous glass shape even outside the container spacing distance (Xcode 26 system prompts / conorluddy).
- Use `.buttonStyle(.glass)` for standard and `.glassProminent` for the primary action (`.confirmationAction` toolbar items get `.glassProminent` automatically); set shape via `.buttonBorderShape(.capsule | .circle | .roundedRectangle(radius:))` (conorluddy / Xcode 26 system prompts).
- Add `.interactive()` (e.g. `.glassEffect(.regular.interactive())`) only to touch-responsive elements — it adds scaling/bouncing/shimmering and touch-point illumination (iOS only); don't add it to static/decorative glass (Xcode 26 system prompts / conorluddy).
- There are three glass variants: `.regular` (default, medium transparency, adapts to any content), `.clear` (only when content is media-rich, tolerates dimming, and foreground is bold/bright), and `.identity` (no effect, for conditional disable) (conorluddy).
- Toggle glass without layout cost using `.glassEffect(shouldShow ? .regular : .identity)` — preferred over conditionally inserting/removing the modifier (conorluddy).
- Tint only to convey meaning via `.tint(_:)` for primary actions or state — tinting everything destroys the signal (conorluddy / Apple HIG).
- Use `.rect(cornerRadius: .containerConcentric)` so glass corners stay concentric with the host container rather than a drifting hardcoded radius (conorluddy).
- Don't fight the system on bars/sheets/toolbars — they auto-adopt glass under Xcode 26; remove custom backgrounds (sheets: `.scrollContentBackground(.hidden)`, `.containerBackground(.clear, for: .navigation)`) and use `ToolbarSpacer(.fixed/.flexible)` for grouping (conorluddy).
- Let the system handle glass accessibility (Reduced Transparency → more frosting, Increased Contrast → stark colors + borders, Reduced Motion, iOS 26.1+ Tinted Mode); read environment values to verify, don't override, and still target legible text contrast (conorluddy).
- Treat glass as GPU-expensive (one report: ~13% vs ~1% battery on iPhone 16 Pro Max vs iOS 18): batch in `GlassEffectContainer`, avoid continuous animation on glass, and profile on ~3-year-old devices; min support iOS 26.0 / Xcode 26.0, iPhone 11 / SE 2nd-gen+ (older get frosted fallback) (conorluddy).

## Navigation Shell

- Use a bottom tab bar for 3–5 primary peer sections (`UITabBar`/`TabView`), each keeping its own `NavigationStack` state; never auto-select a tab without user action, keep it visible except under a modal, and avoid hamburger/drawer menus (measurably worse discoverability) (Frank Rausch / Apple HIG).
- Add the system search tab with `Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search)` — iOS 26 floats it bottom-right, separated by Liquid Glass, and expects a full-screen destination (Donny Wals / SwiftUISnippets).
- Minimize the tab bar on scroll with `.tabBarMinimizeBehavior(_:)` on the `TabView` (`.automatic`, `.never`, `.onScrollDown`); use `.onScrollDown` for content-forward screens (Donny Wals / SwiftUISnippets).
- Use `.tabViewBottomAccessory { … }` for a persistent above-tab-bar control (Now-Playing slot) — it renders for all tabs unless you branch on the active tab; reserve it for one global ongoing context, not per-screen actions (Donny Wals / Hacking with Swift / createwithswift).
- Adapt the accessory to placement via `@Environment(\.tabViewBottomAccessoryPlacement)` (`.expanded` = full strip, `.inline` = compacted into the collapsed bar): show full content expanded, a minimal glyph/label inline; test on device (early iOS 26 betas were flaky) (createwithswift).
- Choose presentation by intent: push (NavigationStack) for a child in the content hierarchy with a Back path; sheet for a single dismissible related task; `fullScreenCover` for complex multi-step focused tasks (onboarding, capture) — don't push something that is really a modal (Apple HIG Modality / Frank Rausch).
- Minimize modality and default to nonmodal — create a modal only to capture attention, force completion/abandonment, or save important data; people prefer nonlinear interaction (Apple HIG Modality).
- Always give a modal an obvious, safe exit (explicit Done/Send + Cancel); if Cancel would discard edits, confirm first via dialog, and keep modal tasks short — "don't build an app within your app" (Apple HIG Modality / Frank Rausch).
- Wrap linear step-by-step flows (onboarding, checkout, guided sequences) in a `fullScreenCover` or sheet so back/next read as sequential, not hierarchical (Frank Rausch).
- Set the back button to show the parent screen's title, not generic "Back"; chevrons on rows signal drill-down, rightward = deeper / leftward = up, and support the interactive cancelable edge-swipe back gesture, mirrored for RTL (Frank Rausch).
- Place primary search and frequent actions in the bottom thumb zone — iOS 26 moved search to the bottom across Messages, Mail, Notes, Music, Safari, Phone for one-handed reach; reserve the top bar for the title and low-frequency actions (AllThings.How / SavvyWithTech).
- Use a pyramid (sibling-swipe) pattern to move between peers without bouncing to the parent (photo viewer, detail pager), adding a `UIPageControl` for small collections to show count + position (Frank Rausch).
- Don't transition full-screen for in-place state changes (empty/loading/loaded) or view-format toggles (list vs grid) — swap content in the same view; reserve push/cover for genuine hierarchy or task changes (Frank Rausch).
- Reserve alerts for essential actionable information (avoid OK-only alerts; use inline text or a nonmodal notification instead) and close any open popover before presenting a modal — alerts are the only exception (Apple HIG Modality / Frank Rausch).
- Apply Liquid Glass only to floating chrome via `.glassEffect()` so custom floating controls match the bar material; the iOS 26 tab bar/accessory blur content beneath by default, and content scrolls under glass — not glass-on-cards (Donny Wals).

## Design Tokens & Design Systems

- Use exactly three token tiers: primitive (raw context-free values, `color.blue.500 = #3B82F6`), semantic (purpose mapping, `color.action.primary → {color.blue.500}`), and component (per-element scoping, `button.background.default → {color.action.primary}`); two or three tiers is enough — don't add more (Design System Problems — Token Tier System).
- Enforce one-directional references: components reference semantic or component tokens only, semantic references primitives or other semantics, primitives reference nothing higher — component tokens must never reference primitives directly, because the semantic indirection is what makes theming a token swap (Design System Problems / ProductRocket).
- Name primitives by appearance (`red-100`, `blue-500`) and semantics by intent (`color-text-primary`, `color-action-primary`); a semantic name must not leak its raw value (avoid `color-text-blue`) (EightShapes / Specify).
- Order token names broad→specific as category-property-variant-state in kebab-case (`--color-background-button-primary-active`) to prevent collisions (EightShapes / Style Dictionary CTI).
- Build names from EightShapes level groups: Base (Category + Property + Concept), Modifier (Variant + State + Scale + Mode), Object (Component + Element), Namespace (System/Theme/Domain prefix) — e.g. `color-action-text-secondary-focus` (EightShapes).
- Adopt Style Dictionary CTI nesting where the JSON path becomes the token name (`size.font.base → size_font_base`); any node with a `value` is a token, aliases use dot-path braces `{size.font.medium}`, and `type`/`comment` are optional metadata (Style Dictionary docs).
- Access SwiftUI tokens through a theme in the environment (`@Environment(\.theme)`), not scattered constants, so multiple themes (OrangeTheme, SoshTheme, WireframeTheme) swap the same token API without touching call sites (OUDS iOS).
- Theme by re-pointing semantic tokens at different primitives, not by editing components — light/dark and rebranding become token swaps; get the semantic layer right since most token architectures fail there, not at primitive or component (Design System Problems / design.dev).
- Structure a `DESIGN.md` into 9 canonical sections in order: 1 Visual Theme & Atmosphere, 2 Color Palette & Roles, 3 Typography Rules, 4 Component Stylings, 5 Layout Principles, 6 Depth & Elevation, 7 Do's and Don'ts, 8 Responsive Behavior, 9 Agent Prompt Guide — plain markdown so agents read it directly (awesome-ios-design-md).
- In Color Palette & Roles, give each semantic role a hex value plus the iOS system color it maps to, for both light and dark modes — not just raw hex; deliver via Color extensions and ViewModifier patterns (awesome-ios-design-md).
- Base layout tokens on a 4/8pt grid with explicit safe areas, insets, and 44×44pt touch targets, and cover Dynamic Type, landscape, and iPad in Responsive Behavior; use scale tokens (`space-1`, `space-2-x`), not magic numbers (awesome-ios-design-md / EightShapes).
- Keep Depth & Elevation as a named token scale (`shadow-elevation-high`) covering shadow values, SwiftUI materials, and blur tied to surface hierarchy — not per-view ad-hoc shadows (awesome-ios-design-md / alwaystwisted).
- Drive components from a token-powered foundation with a single theme engine (NormanDSKit is current/Liquid-Glass-ready; DSKit and SwiftUI-Design-System-Pro are alternatives; Orbit-swiftui was archived 2025-07 — prefer maintained references) (NormanDSKit / DSKit / Orbit-swiftui).
- Prefix tokens with a short product namespace when distributing a library (`esds-`, `slds-`, `$aads-ocean-color-primary`) to avoid collisions with host code (EightShapes).

## Visual Principles

- Establish hierarchy in order of power: size first (strongest), then weight, then color/saturation, then space/position — reach for size and weight before color, and stack redundant signals (size + weight) so the eye reads hierarchy faster (Toptal / Pimp my Type / Smashing).
- Use at most 3 distinct sizes and cap genuinely large elements at ~2; map them to built-in styles (e.g. `.largeTitle`, `.title2`/`.headline`, `.body`) rather than ad-hoc points (NN/g / IxDF).
- Aim for roughly a 3:1 size ratio between header and body text (e.g. `.largeTitle` 34pt over `.body` 17pt) and pair the size jump with a weight jump so size isn't doing all the work (IxDF / Toptal).
- Body text floor is 17pt; honor the Dynamic Type scale and use `Font.TextStyle` (`.body`, `.footnote`, `.caption`) instead of fixed sizes so text scales and gets accessibility sizes for free (Apple HIG / learnui.design).
- Limit to two type families and create variety with weight and size, not new fonts — a third family fragments hierarchy (a deliberate scoped 3-role system is the exception, with each role scoped, not freely mixed) (IxDF).
- Use weight for emphasis within a fixed size before changing size or color (`.fontWeight(.semibold)`) to preserve the size hierarchy while signaling importance (NN/g / Toptal).
- Hierarchy is driven by contrast in value/saturation against context, not raw color — cap to ~2 primary + 2 secondary colors and ≤3 contrast levels; one saturated CTA on a muted ground reads instantly while many bright colors flatten hierarchy (IxDF / NN/g).
- Never rely on color alone to convey importance or state — pair every color signal with a second cue (icon, weight, label, position) and keep text at WCAG AA (4.5:1 normal, 3:1 large ≥18pt regular / ≥14pt bold) (NN/g / Apple HIG).
- Encode grouping with proximity (Gestalt): related items close, unrelated apart — make a section title's gap to its content larger than gaps within the content, and adjust spacing before adding borders/containers (IxDF / NN/g).
- Treat whitespace as a primary tool — "let it breathe" rather than boxing things in; tune micro space (line spacing, label-to-field) and macro space (between sections) separately, and on small screens use whitespace, not dividers, to separate groups (IxDF / NN/g).
- Lay content along the scan path: F-pattern for text-dense views (key info top and left), Z-pattern for sparse/marketing screens (anchor logo, primary action, CTA at the corners) (IxDF).
- Write hierarchy into the copy: make the largest text a meaningful statement (e.g. "Tsuta — 11 min wait now" over a generic "Details") since the biggest element earns the most attention (IxDF).
- Apply the squint/blur test (5–20px): the elements still prominent are your real hierarchy and groups should hold together — if the intended primary disappears, fix size/weight/spacing, don't add color (NN/g).
- Balance by visual weight (area/density), not element count; distribute weight across the layout axis, using asymmetry for energy and symmetry for calm, and check one side isn't unintentionally heavier (NN/g).
- Protect hierarchy with consistency and repetition: reuse one heading treatment, one CTA style, one caption style via tokens/text styles defined once — unpredictable changes destroy hierarchy and trust faster than any other mistake (IxDF / NN/g).

## Anti-Slop

- Ban the reflex purple/violet gradient — never ship `LinearGradient(colors: [.purple, .blue], …)`; "VibeCode Purple" lavender and cyan-on-dark are the top AI tells. For a light-mode app pick one deliberate warm accent, use neutral grounds (`#FAFAF8`/`#F5F3EF`), and only whisper-subtle vertical gradients if any (Impeccable / wholiver).
- Kill the colored left/side-tab border on cards (a 3–4pt accent stripe) — don't pair a thick colored border with a rounded corner at all; differentiate cards with spacing, type weight, and dividers (Impeccable / developersdigest).
- Use glassmorphism for genuine layering only (floating chrome over content), never as a "modern" texture on cards or resting surfaces (Impeccable).
- Don't combine a 1px hairline with a wide diffuse shadow — pick one (a defined edge OR soft elevation); likewise never animate layout props (width/height/padding), animate transform/opacity instead (Impeccable).
- Cap card corner radius at 12–16px (24px+ on small cards reads as AI); reserve full-pill radius for tags/buttons only, and use a token (`DesignTokens.radiusM`), not magic numbers (Impeccable / wholiver).
- Enforce a real type scale with a ≥1.25 step ratio; body floor 16px (12px absolute min), line-height ≥1.3 (1.5–1.7 for body), body letter-spacing ≤0.05em — wide tracking only on short uppercase labels (Impeccable).
- Use SF Symbols, never emoji, for icons (`Image(systemName: "house.fill")` not `Text("🏠")`); avoid the "small rounded-square icon tile above every heading" feature-card template (wholiver / Impeccable / developersdigest).
- Avoid Inter/Roboto-everywhere (the #1 font tell, especially centered hero); default to SF Pro and pair one distinctive display face (e.g. `design: .serif`) with a refined body font — don't use one family for everything or sprinkle italic serif on single words (wholiver / developersdigest).
- No gradient-filled text and no all-caps body — use solid colors for all text (gradient text kills scannability) and reserve uppercase for short labels/headings (Impeccable).
- Drop the eyebrow-pill/badge-above-headline and big "01 02 03" section markers — numbers earn their place only in a real sequence; otherwise use stronger structure (Impeccable / developersdigest).
- Snap everything to an 8pt grid with 44pt tap targets — random values like `.padding(.horizontal, 13)` or `.frame(height: 43)` are tells; vary spacing intentionally (tight for related, generous between sections), not the same value everywhere (wholiver / Impeccable).
- Set a custom accent tint via `.tint(DesignTokens.accent)` at the WindowGroup — default system blue throughout signals no design decision; one warm signature accent beats a timid evenly-distributed palette (wholiver).
- No nested cards (cards-in-cards, 5+ levels flagged) — flatten with spacing, typography, and dividers; avoid symmetric 3-column grids and generic "Welcome to App" heroes in favor of content-driven asymmetric layouts of real data (Impeccable / wholiver).
- Use ease-out easing (quart/quint/expo) for UI chrome, not bounce/spring overshoot on dialogs/cards — reserve spring physics for genuinely draggable elements (Impeccable).
- Meet WCAG AA even on tinted/dark surfaces (body 4.5:1, large 3:1) — medium-grey body on dark and washed gray on colored backgrounds fail; use white/near-white or a darker shade of the same hue, and never skip heading levels (h1→h3) (Impeccable / developersdigest).
- Strip AI copy tics: em-dash spam (more than a couple is a tell), buzzwords ("streamline / empower / supercharge / world-class / enterprise-grade"), and manufactured aphorisms — use specific verb-noun phrases stating what the product literally does (Impeccable).

## Accessibility

- Label what an element IS or DOES, not its content; keep it short and never include the role word (`.accessibilityLabel("Save")` not "Save button" — VoiceOver appends the role) — image-only buttons require a label or VoiceOver speaks the asset filename (Mobile A11y / CVS Health / tanaschita).
- Hints describe the OUTCOME, start with a verb, and are added only when the result isn't obvious (`.accessibilityHint("Opens the book detail")` is read last after a pause); never repeat the label (Mobile A11y / freeCodeCamp).
- Custom tappable views (`onTapGesture`) get no traits automatically — add `.accessibilityAddTraits(.isButton)`; reserve `.isHeader`, `.isSelected`, `.isToggle`, `.isLink` for real roles, don't add traits to native controls, and strip wrong ones with `.accessibilityRemoveTraits()` (CVS Health / tanaschita / Mobile A11y).
- Mark headings with the `.isHeader` trait (not by appending "Heading" to a label) to enable Rotor navigation; `.accessibilityHeading(.h1)…(.h6)` sets level but only alongside `.isHeader`, and levels must be sequential (no h1→h3) (CVS Health Headings, WCAG 1.3.1).
- Collapse a multi-element row into one VoiceOver stop with `.accessibilityElement(children: .combine)`, or `children: .ignore` + a hand-written label for the most natural reading; use `children: .contain` to keep children focusable but grouped (Hacking with Swift / Deque / Mobile A11y).
- Hide purely decorative imagery (`Image(decorative:)` or `.accessibilityHidden(true)`) and give informative/functional images a real `.accessibilityLabel` — an unlabeled file-based Image speaks its filename (CVS Health Images, WCAG 1.1.1).
- Drive type from semantic text styles (`.font(.body)`/`.title`/`.footnote`), never fixed point sizes; body 17pt, footnote 13pt, minimum legible ~11pt — `.font(.system(size: 17))` defeats scaling (Apple HIG / UX Collective).
- Test at the five accessibility sizes (`.accessibility1`–`.accessibility5`) and clamp only where layout truly breaks via `.dynamicTypeSize(.large ... .accessibility3)` — clamp the minimum, not the whole range, and verify no truncation/overlap at the largest setting (Apple HIG / Hacking with Swift).
- Scale custom spacing, icon sizes, and frames with `@ScaledMetric(relativeTo: .body) var iconSize = 24` so they grow with text, pairing `relativeTo` with the adjacent text style (createwithswift / SwiftLee).
- Make every tap target at least 44×44pt including small secondary controls (`.frame(minWidth: 44, minHeight: 44)` or padding) — sub-44pt targets push tap-error rates to 25%+ while the visible icon can stay smaller (Apple HIG / LogRocket / freeCodeCamp).
- Meet 4.5:1 contrast for body and 3:1 for large text (18pt+ regular or 14pt+ bold); prefer system colors (`.primary`/`.secondary`) which pass AA in light mode, and measure custom ink-on-paper pairs before shipping (Apple HIG / David Auerbach).
- Honor Increase Contrast by reading `@Environment(\.colorSchemeContrast)`; when `.increased`, swap to higher-contrast tones (target 7:1) — the body re-renders automatically (Mobile A11y / SwiftUI accessibility env values).
- Never rely on color alone — pair accent-coded state (saved, now) with a glyph or label, and consider `accessibilityShowButtonShapes` to surface tap affordances (Apple HIG / SwiftUI env values).
- Respect Reduce Motion via `@Environment(\.accessibilityReduceMotion)`: apply the animated value only when false (or a `withOptionalAnimation` helper passing nil) and substitute a static/cross-fade alternative — don't just remove feedback (createwithswift / Hacking with Swift).
- Set focus order with `.accessibilitySortPriority` (higher = first, only inside a `children: .contain` container) and move focus programmatically with `@AccessibilityFocusState` (e.g. to a newly revealed detail); override default order only when it genuinely improves comprehension (Mobile A11y / Swift with Majid / Deque).
- Announce dynamic, non-focus-moving updates via `AccessibilityNotification.Announcement("…").post()` wrapped in `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` so VoiceOver reliably speaks status like "Added to your shelf" (WCAG 4.1.3) (CVS Health AccessibilityNotifications).
- Expose secondary affordances as VoiceOver custom actions (`.accessibilityAction(named:)`) instead of swipe-only gestures, use `.accessibilityRepresentation` to borrow a native control's accessibility for a custom toggle/slider, and chunk dense metadata with Accessibility Custom Content (Deque / CVS Health AccessibilityRepresentation).

## Craft Teardowns

- Anchor information density on a proven real-world reference with one primary line per item — Flighty modeled its Live Activities/Dynamic Island on airport split-flap boards ("one line per flight… 50 years of figuring out what's important"); pick the single most important datum per row and let the rest recede (Apple — Behind the Design: Flighty).
- Generate many concept variants before committing — Flighty produces ~20 design ideas per feature ("what fits on a sheet of paper") to escape default patterns; craft is a search-width problem, not first-draft polish (Apple — Behind the Design: Flighty).
- Build a single cohesive theme and carry it into every system surface (widgets, Live Activity, Dynamic Island, Lock Screen) — ADA winners are graded on cohesion across surfaces (Tide Guide's aqua palette adapts to the sky; Flighty's airport-signage language is identical across app and Dynamic Island) (Apple — 2026 ADA Winners / Behind the Design: Flighty).
- Treat accessibility as craft, not compliance — ADA winner Guitar Wiz was praised for robust VoiceOver plus Dynamic Type, Increase Contrast, and Differentiate Without Color; meet 44×44pt targets (incl. secondary actions) and 4.5:1/3:1 contrast, never encoding meaning in color alone (Apple — 2026 ADA Winners / Apple HIG).
- Establish hierarchy with weight and whitespace, not size escalation or chrome — Things 3 separates bold navigation from lighter project lists inside generous whitespace using "bold fonts, lovely icons, and thoughtful splashes of color" rather than dividers or boxes (MacStories — Things 3).
- Use accent color semantically and sparingly — Things 3 shows each calendar's events in that calendar's color and is otherwise minimalist; color is information, not decoration (mirrors reserving an accent like Persimmon for state — saved, now, hint — never button chrome or error fill) (MacStories — Things 3 / AITravel CLAUDE.md).
- Reserve springs for user-initiated motion and start from the default spring (response 0.55, dampingFraction 0.825, blendDuration 0) before tuning; on iOS 17+ prefer the duration/bounce spec (`.spring(duration: 0.3, bounce: 0.2)`) (Apple spring docs / GetStream).
- For a calm/utility aesthetic drive damping high so motion is critically damped, never bouncy — lowering dampingFraction below 0.825 increases overshoot; editorial/reference UIs read premium when motion settles without wobble (codified as ease-out `cubic-bezier(0.32,0.72,0,1)`) (Apple spring docs / AITravel CLAUDE.md).

## Sources

### Typography
- [Typography — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Typography — iOS HIG (mirror with full text-style metrics table)](https://codershigh.github.io/guidelines/ios/human-interface-guidelines/visual-design/typography/index.html)
- [The details of UI typography — WWDC20 session 10175](https://developer.apple.com/videos/play/wwdc2020/10175/)
- [Meet the expanded San Francisco font family — WWDC22 session 110381](https://developer.apple.com/videos/play/wwdc2022/110381/)
- [Fonts — Apple Developer](https://developer.apple.com/fonts/)
- [Scaling Custom SwiftUI Fonts With Dynamic Type — Use Your Loaf](https://useyourloaf.com/blog/scaling-custom-swiftui-fonts-with-dynamic-type/)
- [How to use @ScaledMetric in SwiftUI for Dynamic Type support — Antoine van der Lee](https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/)
- [How to use Dynamic Type with a custom font — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-dynamic-type-with-a-custom-font)
- [Using a Custom Font With Dynamic Type — Use Your Loaf](https://useyourloaf.com/blog/using-a-custom-font-with-dynamic-type/)
- [Scaling custom fonts automatically with Dynamic Type — Sarunw](https://sarunw.com/posts/scaling-custom-fonts-automatically-with-dynamic-type/)
- [A product designer's guide to Dynamic Type in iOS — Kamran Madatli (Bootcamp)](https://medium.com/design-bootcamp/a-product-designers-guide-to-dynamic-type-in-ios-a105dda39a95)
- [Dynamic Type — SwiftUI Field Guide](https://www.swiftuifieldguide.com/layout/dynamic-type/)
- [iPhone App Font Size & Typography Guidelines — learnui.design](https://www.learnui.design/blog/ios-font-size-guidelines.html)

### Color
- [Color | Apple Developer Documentation (SwiftUI)](https://developer.apple.com/documentation/swiftui/color)
- [Color — Human Interface Guidelines — Apple Developer](https://developer.apple.com/design/human-interface-guidelines/color)
- [secondarySystemBackground | Apple Developer Documentation](https://developer.apple.com/documentation/UIKit/UIColor/secondarySystemBackground)
- [The ins and outs of iOS system grouped background colors | contagious.dev](https://contagious.dev/blog/ins-and-outs-of-ios-system-grouped-background-colors/)
- [Dark color cheat sheet | Sarunw](https://sarunw.com/posts/dark-color-cheat-sheet/)
- [ColorTokensKit-Swift | GitHub (metasidd)](https://github.com/metasidd/ColorTokensKit-Swift)
- [OKLCH in CSS: Consistent, accessible color palettes | LogRocket Blog](https://blog.logrocket.com/oklch-css-consistent-accessible-color-palettes)
- [Supporting Color Contrast in Design Systems | Ethan Gardner](https://www.ethangardner.com/posts/supporting-color-contrast-accessibility/)
- [color-contrast-checker (OKLCH palettes, brand-tinted neutrals) | GitHub (incluud)](https://github.com/incluud/color-contrast-checker)
- [Specifying your app's color scheme | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/specifying-your-apps-color-scheme)
- [accentColor | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/color/accentcolor)
- [The Color Guide for App Design | Altamira](https://www.altamira.ai/blog/the-color-guide-for-app-design/)

### Layout & Spacing
- [Layout | Apple Developer Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Get to know the new design system — WWDC25 Session 356](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Build a SwiftUI app with the new design — WWDC25 Session 323](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Corner concentricity in SwiftUI on iOS 26 (Nil Coalescing)](https://nilcoalescing.com/blog/ConcentricRectangleInSwiftUI/)
- [Content margins in SwiftUI (Swift with Majid)](https://swiftwithmajid.com/2024/04/23/content-margins-in-swiftui/)
- [Spacing best practices: 8pt grid, internal <= external (Cieden)](https://cieden.com/book/sub-atomic/spacing/spacing-best-practices)
- [safeAreaInsets | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/safeareainsets)
- [Positioning content relative to the safe area | Apple Developer](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area)
- [layoutMargins | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/layoutmargins)
- [Spacing, grids, and layouts (designsystems.com)](https://www.designsystems.com/space-grids-and-layouts/)
- [How to control spacing using padding (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-control-spacing-around-individual-views-using-padding)
- [swiftui-layout-guides — layout margins & readable width (GitHub, tgrapperon)](https://github.com/tgrapperon/swiftui-layout-guides)

### Motion
- [Animate with springs — WWDC23 (10158)](https://developer.apple.com/videos/play/wwdc2023/10158/)
- [Explore SwiftUI animation — WWDC23 (10156)](https://developer.apple.com/videos/play/wwdc2023/10156/)
- [Wind your way through advanced animations in SwiftUI — WWDC23 (10157)](https://developer.apple.com/videos/play/wwdc2023/10157/)
- [Motion — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Animation.spring(response:dampingFraction:blendDuration:) — Apple Developer Documentation](https://developer.apple.com/documentation/SwiftUI/Animation/spring(response:dampingFraction:blendDuration:))
- [Animation.interactiveSpring(...) — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/animation/interactivespring(response:dampingfraction:blendduration:))
- [Supporting reduced motion preferences in SwiftUI — Create with Swift](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/)
- [Understanding Spring Animations in SwiftUI — Create with Swift](https://www.createwithswift.com/understanding-spring-animations-in-swiftui/)
- [GetStream/swiftui-spring-animations — GitHub reference](https://github.com/GetStream/swiftui-spring-animations)
- [Advanced SwiftUI Animations – Part 2: GeometryEffect — The SwiftUI Lab](https://swiftui-lab.com/swiftui-animations-part2/)
- [How Your Views Actually Move (transform vs layout) — SwiftDifferently](https://www.swiftdifferently.com/blog/swiftui/swiftui-animations-deep-dive)
- [Using Haptics in Mobile Apps — Newly](https://newly.app/articles/haptics-mobile-apps)

### Components
- [Buttons — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Sheets — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sheets)
- [Tab bars — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Toolbars — Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [iOS 26 Design Guidelines: Illustrated Patterns (+ free templates) — Learn UI Design](https://www.learnui.design/blog/ios-design-guidelines-templates.html)
- [Liquid Glass: Redefining design through Hierarchy, Harmony and Consistency — Create with Swift](https://www.createwithswift.com/liquid-glass-redefining-design-through-hierarchy-harmony-and-consistency/)
- [iOS 26 in detail: Liquid Glass UI between Usability and Accessibility — let's dev](https://letsdev.de/en/blog/ios-26-in-detail-liquid-glass-ui-between-usability-and-accessibility.php)
- [SwiftUI Button: Custom Styles, Variants, and Best Practices — SwiftLee (Antoine van der Lee)](https://www.avanderlee.com/swiftui/swiftui-button-styles/)
- [Glassifying toolbars in SwiftUI — Swift with Majid](https://swiftwithmajid.com/2025/07/01/glassifying-toolbars-in-swiftui/)
- [Don't Design Junk in the New iOS 26 Tab Bar — Dmytro Hanin, Bootcamp (Medium)](https://medium.com/design-bootcamp/dont-design-junk-in-the-new-ios-26-tab-bar-4de8e842da89)
- [Overview of resizable sheet APIs in SwiftUI — Nil Coalescing](https://nilcoalescing.com/blog/ResizableSheetInSwiftUI/)
- [glassProminent — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent)
- [presentationDetents(_:) — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:))
- [All accessible touch target sizes — LogRocket Blog](https://blog.logrocket.com/ux-design/all-accessible-touch-target-sizes/)
- [Apple's New Liquid Glass Design: Practical Guidance for Designers — Designed for Humans](https://designedforhumans.tech/blog/liquid-glass-smart-or-bad-for-accessibility)

### Liquid Glass (iOS 26)
- [conorluddy/LiquidGlassReference — iOS 26 Liquid Glass: Ultimate Swift/SwiftUI Reference (GitHub)](https://github.com/conorluddy/LiquidGlassReference)
- [iOS 26 Liquid Glass: Comprehensive Swift/SwiftUI Reference — Conor Luddy](https://www.conor.fyi/writing/liquid-glass-reference)
- [Xcode 26 System Prompts — SwiftUI: Implementing Liquid Glass Design (artemnovichkov)](https://github.com/artemnovichkov/xcode-26-system-prompts/blob/main/AdditionalDocumentation/SwiftUI-Implementing-Liquid-Glass-Design.md)
- [Liquid Glass | Apple Developer Documentation (Technology Overviews)](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass)
- [Materials | Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Understanding GlassEffectContainer in iOS 26 — DEV Community](https://dev.to/arshtechpro/understanding-glasseffectcontainer-in-ios-26-2n8p)
- [Liquid Glass in Swift: Official Best Practices for iOS 26 & macOS Tahoe — DEV Community](https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo)
- [The Anatomy of a LiquidGlass Button in iOS 26 — Natasha The Robot](https://www.natashatherobot.com/p/liquidglass-button-ios-26)
- [GonzaloFuentes28/LiquidGlassCheatsheet — iOS 26 SwiftUI cheatsheet (GitHub)](https://github.com/GonzaloFuentes28/LiquidGlassCheatsheet)
- [SwiftUI Liquid Glass: The Complete iOS 26 Guide — Atelier Socle](https://www.atelier-socle.com/en/articles/swiftui-liquid-glass-guide)
- [Adopting Apple's Liquid Glass: Examples and best practices — LogRocket Blog](https://blog.logrocket.com/ux-design/adopting-liquid-glass-examples-best-practices/)

### Navigation Shell
- [Modern iOS Navigation Patterns · Frank Rausch](https://frankrausch.com/ios-navigation/)
- [Exploring tab bars on iOS 26 with Liquid Glass — Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Enhancing the tab bar with a bottom accessory — Create with Swift](https://www.createwithswift.com/enhancing-the-tab-bar-with-a-bottom-accessory/)
- [Modality — iOS Human Interface Guidelines](https://codershigh.github.io/guidelines/ios/human-interface-guidelines/interaction/modality/index.html)
- [Tab Bar: Bottom Accessory Placement for iOS 26 — SwiftUISnippets](https://swiftuisnippets.wordpress.com/2025/07/15/tab-bar-bottom-accessory-placement-swiftui-for-ios-26/)
- [Tab Bar Customization in SwiftUI for iOS 26 — SwiftUISnippets](https://swiftuisnippets.wordpress.com/2025/07/15/tab-bar-customization-in-swiftui-for-ios-26/)
- [How to add a TabView accessory — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-tabview-accessory)
- [iOS 26: Move the search bar to the top (Phone app and Safari) — AllThings.How](https://allthings.how/ios-26-move-the-search-bar-to-the-top-phone-app-and-safari/)
- [iOS 26 Search Bar at the Bottom: Why It Makes Sense — SavvyWithTech](https://savvywithtech.com/ios-26-search-bar-bottom/)
- [My Beef with the iOS 26 Tab Bar — Ryan Ashcraft](https://ryanashcraft.com/ios-26-tab-bar-beef/)
- [When to Use Bottom Sheets vs. Full Screens — Sammi (Medium)](https://medium.com/@sammi121313/when-to-use-bottom-sheets-vs-full-screens-a5a2393878c5)
- [SwiftUI Sheets: Modal, Bottom, and full screen in iOS — SwiftyPlace](https://www.swiftyplace.com/blog/swiftui-sheets-modals-bottom-sheets-fullscreen-presentation-in-ios)

### Design Tokens & Design Systems
- [Naming Tokens in Design Systems — Nathan Curtis (EightShapes)](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676)
- [Design Tokens — Style Dictionary (CTI structure & references)](https://styledictionary.com/info/tokens/)
- [Token Tier System Architecture — Design System Problems](https://designsystemproblems.com/token-management/token-tier-system/)
- [awesome-ios-design-md (9-section DESIGN.md format) — Meliwat](https://github.com/Meliwat/awesome-ios-design-md)
- [OUDS iOS — Orange Unified Design System (SwiftUI)](https://github.com/Orange-OpenSource/ouds-ios)
- [NormanDSKit — token-driven SwiftUI design system](https://github.com/normansanchezn/NormanDSKit)
- [DSKit — modular SwiftUI design system (imodeveloperlab)](https://github.com/imodeveloperlab/dskit)
- [Orbit SwiftUI — Kiwi.com design system (archived 2025-07)](https://github.com/kiwicom/orbit-swiftui)
- [SwiftUI-Design-System-Pro — tokens, components, theming](https://github.com/muhittincamdali/SwiftUI-Design-System-Pro)
- [Design Token Naming Conventions: A Practical Guide — alwaystwisted](https://www.alwaystwisted.com/articles/design-token-naming-conventions)
- [Design tokens: the complete technical guide — Product Rocket](https://productrocket.ro/articles/design-tokens-guide/)
- [awesome-design-md (Apple DESIGN.md, original format) — VoltAgent](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/apple/DESIGN.md)

### Visual Principles
- [5 Principles of Visual Design in UX — NN/G](https://www.nngroup.com/articles/principles-visual-design/)
- [Visual Hierarchy in UX: Definition — NN/G](https://www.nngroup.com/articles/visual-hierarchy-ux-definition/)
- [What is Visual Hierarchy? — IxDF](https://ixdf.org/literature/topics/visual-hierarchy)
- [What is the Law of Proximity? — IxDF](https://ixdf.org/literature/topics/law-of-proximity)
- [The Power of White Space in Design — IxDF](https://ixdf.org/literature/article/the-power-of-white-space)
- [What are the Gestalt Principles? — IxDF](https://www.interaction-design.org/literature/topics/gestalt-principles)
- [How to Structure an Effective Typographic Hierarchy — Toptal](https://www.toptal.com/designers/typography/typographic-hierarchy)
- [Typographic Hierarchies — Smashing Magazine](https://www.smashingmagazine.com/2022/10/typographic-hierarchies/)
- [Typographic Hierarchy — Pimp my Type](https://pimpmytype.com/hierarchy/)

### Anti-Slop
- [Slop — Impeccable (46 AI-slop patterns)](https://impeccable.style/slop/)
- [Impeccable: Design skills for AI harnesses](https://impeccable.style/)
- [Anti-patterns — Impeccable](https://impeccable.style/anti-patterns/)
- [pbakaus/impeccable (GitHub)](https://github.com/pbakaus/impeccable)
- [wholiver/swiftui-design-skill — Six Ironclad Rules Against AI Sloppiness (GitHub)](https://github.com/wholiver/swiftui-design-skill)
- [wholiver/swiftui-design-skill — references/anti-ai-slop.md](https://github.com/wholiver/swiftui-design-skill/blob/main/references/anti-ai-slop.md)
- [AI Design Slop: 15 Patterns That Out Your App as Vibe-Coded — Developers Digest](https://www.developersdigest.tech/blog/ai-design-slop-and-how-to-spot-it)
- [Why Your AI Keeps Building the Same Purple Gradient Website — prg.sh](https://prg.sh/ramblings/Why-Your-AI-Keeps-Building-the-Same-Purple-Gradient-Website)
- [Fixing Visual AI Slop: Front-End Design Standards for AI Coding Agents — Trilogy AI](https://trilogyai.substack.com/p/fixing-visual-ai-slop)
- [Anthropic Skills Marketplace: The Anti AI-Slop UI Design Skill — Nick Porter (Medium)](https://medium.com/@porter.nicholas/anthropic-skills-marketplace-the-anti-ai-slop-ui-design-skill-a572d0cfef4f)
- [SwiftUI Agent Skill — Hacking with Swift](https://www.hackingwithswift.com/articles/282/swiftui-agent-skill-claude-codex-ai)
- [Claude Code UI Slop Is Killing Your Front-End Taste — Productive Tech Talk](https://productivetechtalk.com/2026/04/16/claude-code-ui-slop-is-killing-your-frontend-taste/)

### Accessibility
- [cvs-health/ios-swiftui-accessibility-techniques (GitHub)](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
- [CVS Health — AccessibilityTraits.md](https://raw.githubusercontent.com/cvs-health/ios-swiftui-accessibility-techniques/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityTraits.md)
- [CVS Health — Headings.md](https://raw.githubusercontent.com/cvs-health/ios-swiftui-accessibility-techniques/main/iOSswiftUIa11yTechniques/Documentation/Headings.md)
- [CVS Health — Images.md](https://raw.githubusercontent.com/cvs-health/ios-swiftui-accessibility-techniques/main/iOSswiftUIa11yTechniques/Documentation/Images.md)
- [CVS Health — AccessibilityNotifications.md](https://raw.githubusercontent.com/cvs-health/ios-swiftui-accessibility-techniques/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityNotifications.md)
- [Apple Developer — accessibilityReduceMotion environment value](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)
- [Mobile A11y — SwiftUI Accessibility: Traits](https://mobilea11y.com/guides/swiftui/swiftui-traits/)
- [Mobile A11y — SwiftUI Accessibility: Sort Priority](https://mobilea11y.com/guides/swiftui/swiftui-sort-priority/)
- [Hacking with Swift — Hiding and grouping accessibility data](https://www.hackingwithswift.com/books/ios-swiftui/hiding-and-grouping-accessibility-data)
- [Hacking with Swift — How to detect the Reduce Motion accessibility setting](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting)
- [Deque — SwiftUI & Accessibility: Goodies & Gotchas Part 1](https://www.deque.com/blog/swiftui-accessibility-goodies-gotchas-part-1/)
- [tanaschita — Beginners guide to supporting VoiceOver in SwiftUI](https://tanaschita.com/ios-accessibility-voiceover-swiftui-guide/)
- [Swift with Majid — Accessibility focus in SwiftUI](https://swiftwithmajid.com/2021/09/23/accessibility-focus-in-swiftui/)
- [freeCodeCamp — How to Address Common Accessibility Challenges in iOS Using SwiftUI](https://www.freecodecamp.org/news/how-to-address-ios-accessibility-challenges-using-swiftui/)
- [UX Collective — Designing for scalable Dynamic Type in iOS for accessibility](https://uxdesign.cc/designing-for-scalable-dynamic-type-in-ios-5d3e2ae554eb)

### Craft Teardowns
- [Human Interface Guidelines | Apple Developer Documentation](https://developer.apple.com/design/human-interface-guidelines/)
- [Behind the Design: Flighty | Apple Developer News](https://developer.apple.com/news/?id=970ncww4)
- [Animation and haptics | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/animation-and-haptics)
- [Things 3: Beauty and Delight in a Task Manager | MacStories](https://www.macstories.net/reviews/things-3-beauty-and-delight-in-a-task-manager/)
- [What's New in the all-new Things | Cultured Code](https://culturedcode.com/things/features/)
- [Meet the 2026 Apple Design Award Winners | App Store](https://apps.apple.com/us/iphone/story/id1896606452)
- [Apple reveals winners of the 2026 Apple Design Awards | Apple Newsroom](https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/)
- [Apple Design Awards — finalists & criteria | Apple Developer](https://developer.apple.com/design/awards/)
- [Flighty iOS App UI/UX animation | 60fps.design](https://60fps.design/apps/flighty)
