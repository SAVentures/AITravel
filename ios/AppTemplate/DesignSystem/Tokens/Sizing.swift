// Sizing.swift — the SEMANTIC component-dimension tier: element sizes by role, expressed as `Grid.x(n)`
// 4pt-grid multiples (NO bespoke size primitives; the grid unit is the only dimension atom). Convention:
// a FLAT member is a shared role used by ≥2 components; the nested `Component` enum holds single-component
// dimensions. Views reference these roles, never `Primitive.*`/`Grid` (J-0.2). Caseless enum per §1.x.
import SwiftUI

enum Sizing {

    /// 8 — status/indicator dot diameter (shared).
    static let dot = Grid.x(2)

    /// 44 — HIG minimum interactive target (shared).
    static let minTapTarget = Grid.x(11)

    /// Single-component dimensions — one consumer each, named by role.
    enum Component {
        /// 136 — horizontal-scroll card min width.
        static let cardMinWidth = Grid.x(34)
        /// 104 — adaptive-grid chip min column.
        static let chipColumn = Grid.x(26)
        /// 48 — EmptyStateView decorative glyph box.
        static let emptyStateGlyph = Grid.x(12)
        /// 4 — GenerationProgressView track height.
        static let progressTrack = Grid.x(1)
        /// 24 — GenerationProgressView step status glyph.
        static let stepGlyph = Grid.x(6)
        /// 4 — OnboardingProgressBar segment height.
        static let progressSegment = Grid.x(1)
        /// 24 — MapPin diameter.
        static let mapPin = Grid.x(6)
        /// 12 — TimelineRow stop dot.
        static let timelineDot = Grid.x(3)
        /// 16 — TransitConnector mode glyph box.
        static let timelineModeGlyph = Grid.x(4)
        /// 104 — TripShapeCard diagram column width.
        static let tripShapeDiagram = Grid.x(26)
        /// 4 — TripShapeCard mini-bar height.
        static let tripShapeBar = Grid.x(1)
        /// 184 — BaseMapCard map well height.
        static let baseMapHeight = Grid.x(46)
        /// 32 — BaseMapCard home marker diameter.
        static let baseMapHome = Grid.x(8)
        /// 168 — BaseMapCard zone placeholder width.
        static let baseMapZoneWidth = Grid.x(42)
        /// 128 — BaseMapCard zone placeholder height.
        static let baseMapZoneHeight = Grid.x(32)
        /// 120 — PlaceCard media-well height.
        static let placeCardWell = Grid.x(30)
        /// 12 — LoadingSkeleton primary placeholder bar height.
        static let skeletonPrimaryBar = Grid.x(3)
        /// 8 — LoadingSkeleton secondary placeholder bar height.
        static let skeletonSecondaryBar = Grid.x(2)
        /// 8 — BaseMapCard home-marker halo extent (a frame dimension).
        static let baseMapHomeRing = Grid.x(2)
        /// 48 — SearchWell min interaction height.
        static let searchWellHeight = Grid.x(12)
        /// 64 — PlaceRow square thumb well (mockup `.pl-thumb` 62px, snapped to the 4pt grid).
        static let placeRowThumb = Grid.x(16)
        /// 24 — PlaceRow provenance-stamp badge diameter (mockup `.src-badge` 23px, snapped to grid).
        static let placeRowBadge = Grid.x(6)
        /// 52 — SourceCard source-icon tile (mockup `.srccard-ico`, on-grid 52).
        static let sourceIconTile = Grid.x(13)
        /// 48 — SourcePlaceRow thumbnail (mockup `.src-place .pl-thumb` ~46, snapped on-grid).
        static let sourcePlaceThumb = Grid.x(12)
        /// 52 — ProvenanceCard source-thumb side (mockup `.prov-thumb`).
        static let provenanceThumb = Grid.x(13)
        /// 132 — MapSnippet static map canvas height (mockup `.map-snip .canvas`).
        static let mapSnippetCanvas = Grid.x(33)
        /// 28 — MapSnippet graph-paper grid pitch (mockup `.canvas` 26px, snapped to the 4pt grid).
        static let mapSnippetGridPitch = Grid.x(7)
        /// 40 — WayToSaveRow standard glyph tile (mockup `.way .wi` 38px, snapped to the 4pt grid).
        static let wayToSaveGlyph = Grid.x(10)
        /// 48 — WayToSaveRow prominent glyph tile (mockup `.method .mi` 46px, snapped to the 4pt grid).
        static let wayToSaveGlyphProminent = Grid.x(12)
        /// 288 — PlaceDetailView photo-hero height (mockup `.pd-hero`, the over-hero takeover banner).
        static let placeDetailHero = Grid.x(72)
    }
}
