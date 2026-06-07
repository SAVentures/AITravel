// BookingRowSnapshotTests.swift — Layer 3 render-snapshot lock for BookingRow.
//
// These tests are the lock on BookingRow at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — icon tile tint, status pill, time-emphasis, dim register,
// confirmation code, body typography — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   lodging-upcoming     — bed glyph, amber tint, "upcoming" pill, confirmation present.
//                          Confirms the standard register: icon tile, name, meta with
//                          time-emphasis slice, StatusPill, and confirmation code co-occur.
//   activity-now         — ticket glyph, the accent "now" pill + static live dot.
//                          The one live-moment row: confirms the accent fill + dot +
//                          label + confirmation all appear together (no unit test can
//                          confirm that co-occurrence).
//   transport-today      — airplane glyph, inverse-ground "today" pill.
//                          Confirms the dark-ground today pill is visually distinct from
//                          upcoming and now.
//   dining-upcoming      — fork.knife glyph, sage tint, "upcoming" pill.
//                          A second upcoming-register snapshot to lock the dining type-tint
//                          against the lodging tint (they differ via bookingMark).
//   past                 — dim register: faint ink-600 name, dimmed icon (opacity 0.55),
//                          quiet transparent "past" pill. Confirms the full past-register
//                          treatment locks together in one frame.
//   lodging-upcoming-ax5 — AX5 compensating snapshot (§7.4). Same fixture as lodging-upcoming
//                          at .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling
//                          of the @ScaledMetric icon tile, the display name, the meta line
//                          (including the emphasized time span), the StatusPill, and the mono
//                          confirmation code at the largest accessibility size category.
//                          Glass-free component — renders fully.
//
// Determinism (07-testing §6.4):
//   · No Date() — BookingRow is a pure display component with no clock dependency.
//     BookingStatus is seeded (OD-3: no live-clock derivation).
//   · No withAnimation — snapshot at rest. The now-dot is STATIC (OD-2 deferral).
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in BookingRow.swift exactly (stable ids).
//   · No SampleData required — BookingRowModel is a value type.
//
// Baselines land in __Snapshots__/BookingRowSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("BookingRow snapshots")
struct BookingRowSnapshotTests {

    // MARK: - lodging-upcoming

    /// BookingRow: lodging type, upcoming status — the standard register.
    /// Renders: amber-tinted bed-glyph icon tile + "Casa do Bairro" display name +
    /// "Check-in 15:00 · 2 nights · Alfama" meta (time-emphasis on "Check-in 15:00") +
    /// "Upcoming" pill (fillTertiary) + "CDB-2207" confirmation code.
    /// Confirms the icon, body, pill, and confirmation all co-occur in one frame.
    @Test("lodging-upcoming — bed tile + name/meta + upcoming pill + confirmation co-occur")
    @MainActor func lodgingUpcoming() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "casa-do-bairro",
                        title: "Casa do Bairro",
                        meta: "Check-in 15:00 · 2 nights · Alfama",
                        timeEmphasis: "Check-in 15:00",
                        type: .lodging,
                        systemImage: BookingType.lodging.systemImage,
                        status: .upcoming,
                        confirmation: "CDB-2207"
                    ),
                    accessibilityID: "bookingrow.casa-do-bairro"
                )
            },
            named: "lodging-upcoming"
        )
    }

    // MARK: - activity-now

    /// BookingRow: activity type, now status — the live-moment register.
    /// Renders: accent-tinted ticket-glyph icon tile + "Castelo de São Jorge" name +
    /// "Now · 10:00 · timed entry · 2 adults" meta (time-emphasis "Now · 10:00") +
    /// "Now" pill (stateNow accent fill + static live dot + textOnAccent label) +
    /// "CSJ-4419" confirmation code.
    /// Confirms the accent ground, static live dot, and confirmation all co-occur.
    @Test("activity-now — ticket tile + name/meta + accent now-pill (static dot) + confirmation")
    @MainActor func activityNow() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "castelo",
                        title: "Castelo de São Jorge",
                        meta: "Now · 10:00 · timed entry · 2 adults",
                        timeEmphasis: "Now · 10:00",
                        type: .activity,
                        systemImage: BookingType.activity.systemImage,
                        status: .now,
                        confirmation: "CSJ-4419"
                    ),
                    accessibilityID: "bookingrow.castelo"
                )
            },
            named: "activity-now"
        )
    }

    // MARK: - transport-today

    /// BookingRow: transport type, today status — the inverse-ground today register.
    /// Renders: slate-blue airplane-glyph icon tile + "Ferry to Cacilhas" name +
    /// "Departs 13:40 · Cais do Sodré" meta (time-emphasis "Departs 13:40") +
    /// "Today" pill (textPrimary/ink-900 fill, textOnAccent inverse label) +
    /// "FRC-0098" confirmation code.
    /// Confirms the dark-ground today pill is visually distinct from upcoming and now.
    @Test("transport-today — airplane tile + name/meta + dark today pill + confirmation co-occur")
    @MainActor func transportToday() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "ferry-cacilhas",
                        title: "Ferry to Cacilhas",
                        meta: "Departs 13:40 · Cais do Sodré",
                        timeEmphasis: "Departs 13:40",
                        type: .transport,
                        systemImage: BookingType.transport.systemImage,
                        status: .today,
                        confirmation: "FRC-0098"
                    ),
                    accessibilityID: "bookingrow.ferry-cacilhas"
                )
            },
            named: "transport-today"
        )
    }

    // MARK: - dining-upcoming

    /// BookingRow: dining type, upcoming status — the sage-tint upcoming register.
    /// Renders: sage-tinted fork-glyph icon tile + "Belcanto" name +
    /// "20:30 · tasting menu · 2 covers" meta (time-emphasis "20:30") +
    /// "Upcoming" pill + "BLC-7741" confirmation code.
    /// Locks the dining tint (bookingMark(.dining) = day2) vs the lodging tint (day1) — they differ.
    @Test("dining-upcoming — fork tile (sage tint) + name/meta + upcoming pill: type-tint distinct from lodging")
    @MainActor func diningUpcoming() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "belcanto",
                        title: "Belcanto",
                        meta: "20:30 · tasting menu · 2 covers",
                        timeEmphasis: "20:30",
                        type: .dining,
                        systemImage: BookingType.dining.systemImage,
                        status: .upcoming,
                        confirmation: "BLC-7741"
                    ),
                    accessibilityID: "bookingrow.belcanto"
                )
            },
            named: "dining-upcoming"
        )
    }

    // MARK: - past

    /// BookingRow: past register — the dimmed treatment.
    /// Renders: dimmed dining icon tile (opacity 0.55), faint ink-600 "Time Out Market" name,
    /// "Yesterday · 13:00 · lunch" meta (time-emphasis "Yesterday · 13:00"),
    /// quiet transparent "Past" pill (no fill, textTertiary), "TOM-1180" confirmation.
    /// Confirms the full past-register dim treatment co-occurs in one frame.
    @Test("past — dim register: faint name + dimmed icon + transparent past-pill + confirmation")
    @MainActor func past() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "time-out",
                        title: "Time Out Market",
                        meta: "Yesterday · 13:00 · lunch",
                        timeEmphasis: "Yesterday · 13:00",
                        type: .dining,
                        systemImage: BookingType.dining.systemImage,
                        status: .past,
                        confirmation: "TOM-1180",
                        isPast: true
                    ),
                    accessibilityID: "bookingrow.time-out"
                )
            },
            named: "past"
        )
    }

    // MARK: - lodging-upcoming-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as lodging-upcoming at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric icon
    /// tile (Sizing.Component.bookingRowIcon), the display name, the secondary meta line
    /// (including the time-emphasis span), the StatusPill caption label, and the mono
    /// confirmation code at the largest accessibility size category. Glass-free — renders fully.
    @Test("lodging-upcoming-ax5 — AX5: @ScaledMetric icon + name/meta + pill + confirmation at accessibilityXXXL")
    @MainActor func lodgingUpcomingAX5() {
        assertDesignSnapshot(
            rowCanvas {
                BookingRow(
                    model: BookingRowModel(
                        id: "casa-do-bairro",
                        title: "Casa do Bairro",
                        meta: "Check-in 15:00 · 2 nights · Alfama",
                        timeEmphasis: "Check-in 15:00",
                        type: .lodging,
                        systemImage: BookingType.lodging.systemImage,
                        status: .upcoming,
                        confirmation: "CDB-2207"
                    ),
                    accessibilityID: "bookingrow.casa-do-bairro"
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "lodging-upcoming-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a BookingRow in a surfacePage canvas matching the BookingRow #Preview padding.
@MainActor
private func rowCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
