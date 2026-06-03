/*
 Layer 1 — Unit tests for the onboarding wire + model layer.

 Group 1: DTO round-trip (§4.2)
   - OnboardingContextDTO: pure Codable seed — decode(encode(ctx)) == ctx for each A/B/C fixture.
   - TripDraftDTO ↔ TripDraftModel: dto.toDomain().toDTO() == dto, confirming the mapping is
     lossless both ways. A field added to TripDraftModel without a TripDraftDTO mirror will break this.

 Group 2: TripDraftModel mutation methods (§4.1)
   - select(city:), clearDestination(), select(strategy:), setDays(_:), toggleInterest(_:),
     setPace(_:), select(base:), setBaseMode(_:), setPrimaryMode(_:), toggleAlsoOK(_:),
     advanceStep(), retreatStep() — each asserts the single field that changes; nothing else.

 Group 3: CityMeta + DiagramSpec associated-value Codable round-trips (§4.2)
   - CityMeta: parameterized over all four cases (savedCount, planStarted, neighborhood, medina).
   - DiagramSpec: parameterized over all three cases plus the all-nil-optional rankedBars path.

 Group 4: Wire decode — APIJSON snake_case path (§5.3)
   - Proves APIJSON.decoder() (convertFromSnakeCase + iso8601) correctly decodes the
     OnboardingContextDTO wire payload, i.e. saved_here → savedHere.
   - Distinct from Group 1 which uses the symmetric coder only.

 Determinism rules (§3):
   - No Date(), Calendar.current, or Locale.current.
   - All fixtures from SampleData; stable id literals only (e.g. "city-lisbon").
   - TripDraftModel is a reference type — assert on fields, never == between constructed instances.

 Coder rule (§4.2):
   - Plain symmetric JSONEncoder/JSONDecoder with .iso8601 date strategy for round-trip tests.
   - APIJSON is not used in symmetric round-trips — its snake-case key conversion is asymmetric
     on acronym/ID keys (bookID → book_id → bookId; the capitalized ID suffix is lost on decode).
   - APIJSON.decoder() IS used in the wire-decode suite (Group 4) — that is its entire purpose.
*/

import Testing
import Foundation
@testable import AppTemplate

// MARK: - OnboardingFixtureTag

/// Nonisolated discriminator used as @Test(arguments:) parameter so Swift Testing can evaluate the
/// collection in the nonisolated registration context. The actual context value is built INSIDE the
/// @MainActor test body via tag.context(), which is @MainActor-isolated and therefore legal there.
///
/// Using a nonisolated enum tag instead of placing SampleData.onboarding?Context() directly in the
/// arguments array avoids the "expression is async but not marked with await" build error that occurs
/// when a @MainActor builder is evaluated in the nonisolated @Test macro registration scope.
enum OnboardingFixtureTag: CaseIterable, CustomTestStringConvertible {
    case a, b, c

    var testDescription: String {
        switch self {
        case .a: return "state-A (returningWithLocalSaves)"
        case .b: return "state-B (savesElsewhere)"
        case .c: return "state-C (firstTrip)"
        }
    }

    @MainActor
    func context() -> OnboardingContextDTO {
        switch self {
        case .a: return SampleData.onboardingAContext()
        case .b: return SampleData.onboardingBContext()
        case .c: return SampleData.onboardingCContext()
        }
    }
}

// MARK: - Helpers

/// A plain symmetric encoder/decoder pair for round-trip tests (§4.2).
/// Uses .iso8601 for Date fields; no key strategy — symmetric encoding only.
private func symmetricEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    return enc
}

private func symmetricDecoder() -> JSONDecoder {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return dec
}

/// Encode then decode a Codable value using the plain symmetric coder pair.
private func codableRoundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try symmetricEncoder().encode(value)
    return try symmetricDecoder().decode(T.self, from: data)
}

// MARK: - OnboardingModelTests

@Suite("Onboarding model — DTO round-trips and TripDraftModel mutations")
struct OnboardingModelTests {

    // MARK: - Group 1: DTO round-trips

    @Suite("DTO round-trip — OnboardingContextDTO (Codable symmetry)")
    struct OnboardingContextDTORoundTripTests {

        // MARK: JSON round-trips (A4 — table-driven)

        /// All three A/B/C fixtures in one parameterized test.
        /// OnboardingContextDTO is a pure Codable seed with no domain-type twin —
        /// we assert JSON encode → decode recovers the exact value.
        ///
        /// State C-specific precondition: tasteDefaults is non-nil in state C and must
        /// survive encode/decode intact. This guard is asserted inside the body for the
        /// C fixture and is preserved from the original per-case test (plan A4).
        @Test(
            "OnboardingContextDTO: JSON round-trip is lossless",
            arguments: OnboardingFixtureTag.allCases
        )
        @MainActor
        func contextJSONRoundTrip(_ tag: OnboardingFixtureTag) throws {
            let ctx = tag.context()
            // State C carries a non-nil tasteDefaults — guard the fixture precondition.
            // Keyed on onboardingState == .firstTrip (the C-branch identifier).
            // Preserved from the original contextCJSONRoundTrip test (plan A4 — must not be dropped).
            if tag == .c {
                #expect(ctx.tasteDefaults != nil,
                        "fixture precondition: state C carries a seed tasteDefaults")
            }
            let recovered = try codableRoundTrip(ctx)
            #expect(recovered == ctx)
        }

        // MARK: onboardingState branch derivation (A4 — table-driven)

        /// All three A/B/C branch derivations in one parameterized test.
        /// onboardingState is a computed property on OnboardingContextDTO that drives
        /// the A/B/C branch from savedHere / savedAnywhere counts.
        ///
        /// A (savedHere: 23)              → .returningWithLocalSaves
        /// B (savedHere: 0, anywhere: 29) → .savesElsewhere
        /// C (savedHere: 0, anywhere: 0)  → .firstTrip
        ///
        /// Uses a single collection of tuples so Swift Testing pairs each tag with its
        /// expected state element-wise (one invocation per tuple), not as a Cartesian product.
        @Test(
            "OnboardingContextDTO.onboardingState derives the correct branch",
            arguments: [
                (OnboardingFixtureTag.a, OnboardingState.returningWithLocalSaves),
                (OnboardingFixtureTag.b, OnboardingState.savesElsewhere),
                (OnboardingFixtureTag.c, OnboardingState.firstTrip),
            ]
        )
        @MainActor
        func contextDerivesBranch(_ tag: OnboardingFixtureTag, _ expected: OnboardingState) {
            let ctx = tag.context()
            #expect(ctx.onboardingState == expected)
        }
    }

    @Suite("DTO round-trip — TripDraftDTO ↔ TripDraftModel (lossless mapping)")
    struct TripDraftDTORoundTripTests {

        // MARK: Mapping round-trips (A4 — table-driven)

        /// All three A/B/C mapping round-trips in one parameterized test.
        /// dto.toDomain() builds the reference model; .toDTO() snapshots it back.
        /// A field added to TripDraftModel without a TripDraftDTO mirror breaks this.
        ///
        /// Note: `toDomain()` is @MainActor, so the entire test body runs on the main actor.
        @Test(
            "TripDraftDTO: dto.toDomain().toDTO() == dto (mapping is lossless for all three branches)",
            arguments: OnboardingFixtureTag.allCases
        )
        @MainActor
        func tripDraftMappingRoundTrip(_ tag: OnboardingFixtureTag) {
            let ctx = tag.context()
            let draft = ctx.toDomain()
            let dto = draft.toDTO()
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto)
        }

        /// TripDraftDTO is Codable; verify the JSON representation is also symmetric
        /// (encoding + decoding the DTO value preserves equality before the domain mapping).
        @Test("TripDraftDTO A: JSON round-trip is lossless (Codable symmetry)")
        @MainActor
        func tripDraftAJSONRoundTrip() throws {
            let ctx = SampleData.onboardingAContext()
            let dto = ctx.toDomain().toDTO()
            let recovered = try codableRoundTrip(dto)
            #expect(recovered == dto)
        }

        /// FIX: Proves tripWhen and selectedNeighborhoodID survive the full dto.toDomain().toDTO()
        /// round-trip. The draft is mutated to exactDates and a non-nil neighborhoodID before
        /// snapshotting — the default seedDefault state would not exercise these two fields.
        @Test("TripDraftDTO: tripWhen (exactDates) and selectedNeighborhoodID survive the mapping round-trip")
        @MainActor
        func tripDraftTripWhenAndNeighborhoodRoundTrip() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()

            // Set a non-default tripWhen (exactDates) so the round-trip is non-trivial.
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)
            // Set a non-nil selectedNeighborhoodID.
            draft.selectNeighborhood("neighborhood-alfama")

            let dto = draft.toDTO()

            // Verify the DTO captured the mutations.
            #expect(dto.tripWhen.precision == .exactDates)
            #expect(dto.tripWhen.year == 2026)
            #expect(dto.tripWhen.month == 9)
            #expect(dto.tripWhen.startDate != nil)
            #expect(dto.tripWhen.endDate != nil)
            #expect(dto.selectedNeighborhoodID == "neighborhood-alfama")

            // Verify the full mapping round-trip is lossless.
            let recovered = dto.toDomain().toDTO()
            #expect(recovered == dto)
        }
    }

    // MARK: - Group 2: TripDraftModel mutation methods

    @Suite("TripDraftModel mutations — each method flips exactly one field")
    struct TripDraftModelMutationTests {

        // MARK: select(city:) / clearDestination()

        /// select(city:) sets destination to the chosen city.
        /// Index by stable id "city-kyoto", never by array position.
        @Test("select(city:) sets destination to the chosen city")
        @MainActor
        func selectCitySetsDestination() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()
            let kyoto = City(id: "city-kyoto", name: "Kyoto", country: "Japan", savedHere: 0, meta: .savedCount(0))
            draft.select(city: kyoto)
            #expect(draft.destination?.id == "city-kyoto")
        }

        /// clearDestination() sets destination to nil.
        @Test("clearDestination() clears the destination")
        @MainActor
        func clearDestinationSetsNil() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()
            // seed: context A starts with destination set from context.destination
            let lisbon = ctx.destination
            draft.select(city: lisbon)
            #expect(draft.destination != nil, "precondition: destination must be set before clearing")
            draft.clearDestination()
            #expect(draft.destination == nil)
        }

        // MARK: select(strategy:)

        /// select(strategy:) assigns the chosen shape strategy.
        @Test("select(strategy: .coverBucket) sets shapeStrategy")
        @MainActor
        func selectStrategySetsStrategy() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.select(strategy: .coverBucket)
            #expect(draft.shapeStrategy == .coverBucket)
        }

        @Test("select(strategy: .fixedDays) overwrites a previously set strategy")
        @MainActor
        func selectStrategyOverwrites() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.select(strategy: .highlights)
            draft.select(strategy: .fixedDays)
            #expect(draft.shapeStrategy == .fixedDays)
        }

        // MARK: setDays(_:)

        @Test("setDays(_:) updates tripDays to the given value")
        @MainActor
        func setDaysUpdatesTripDays() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setDays(7)
            #expect(draft.tripDays == 7)
        }

        @Test("setDays(_:) can reduce tripDays below the seed default")
        @MainActor
        func setDaysCanReduce() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setDays(2)
            #expect(draft.tripDays == 2)
        }

        // MARK: toggleInterest(_:)

        /// toggleInterest(_:) seeds an empty profile if none exists and adds the interest.
        @Test("toggleInterest(_:) adds an interest when tasteProfile is nil")
        @MainActor
        func toggleInterestAddsWhenNil() {
            let draft = SampleData.onboardingAContext().toDomain()
            // State A has no tasteDefaults — tasteProfile starts nil.
            #expect(draft.tasteProfile == nil, "precondition: state A starts with nil tasteProfile")
            draft.toggleInterest(.food)
            #expect(draft.tasteProfile?.interests.contains(.food) == true)
        }

        /// toggleInterest(_:) removes an interest that is already in the profile.
        @Test("toggleInterest(_:) removes an interest that is already set")
        @MainActor
        func toggleInterestRemovesExisting() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.toggleInterest(.history)
            #expect(draft.tasteProfile?.interests.contains(.history) == true,
                    "precondition: interest must be present before toggling off")
            draft.toggleInterest(.history)
            #expect(draft.tasteProfile?.interests.contains(.history) == false)
        }

        /// toggleInterest(_:) on state C draft (pre-seeded tasteDefaults) adds to the existing profile.
        @Test("toggleInterest(_:) adds to a pre-seeded profile in state C")
        @MainActor
        func toggleInterestAddsToExistingProfile() {
            let draft = SampleData.onboardingCContext().toDomain()
            // State C seeds tasteDefaults with food/history/coffee; architecture is not in it.
            #expect(draft.tasteProfile?.interests.contains(.architecture) == false,
                    "precondition: architecture is not in the state-C seed")
            draft.toggleInterest(.architecture)
            #expect(draft.tasteProfile?.interests.contains(.architecture) == true)
        }

        // MARK: setPace(_:)

        @Test("setPace(_:) sets the pace when tasteProfile is nil (seeds a profile)")
        @MainActor
        func setPaceSeesProfileWhenNil() {
            let draft = SampleData.onboardingAContext().toDomain()
            #expect(draft.tasteProfile == nil, "precondition: state A starts with nil tasteProfile")
            draft.setPace(.packed)
            #expect(draft.tasteProfile?.pace == .packed)
        }

        @Test("setPace(_:) updates the pace on an existing profile")
        @MainActor
        func setPaceUpdatesPaceOnExistingProfile() {
            let draft = SampleData.onboardingCContext().toDomain()
            // State C seeds .balanced; switch to .easy.
            #expect(draft.tasteProfile?.pace == .balanced,
                    "precondition: state C seed pace is .balanced")
            draft.setPace(.easy)
            #expect(draft.tasteProfile?.pace == .easy)
        }

        // MARK: select(base:)

        @Test("select(base:) assigns the chosen base location")
        @MainActor
        func selectBaseSetsBaseSelection() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()
            let alfama = ctx.recommendedBase   // stable fixture from seed
            draft.select(base: alfama)
            #expect(draft.baseSelection?.id == "base-alfama")
        }

        // MARK: setBaseMode(_:)

        @Test("setBaseMode(.manual) changes baseMode from the .smart default")
        @MainActor
        func setBaseModeChangesMode() {
            let draft = SampleData.onboardingAContext().toDomain()
            // toDomain() seeds baseMode: .smart
            #expect(draft.baseMode == .smart, "precondition: toDomain seeds .smart")
            draft.setBaseMode(.manual)
            #expect(draft.baseMode == .manual)
        }

        // MARK: setPrimaryMode(_:)

        @Test("setPrimaryMode(_:) updates transport.primary")
        @MainActor
        func setPrimaryModeUpdatesTransport() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setPrimaryMode(.walk)
            #expect(draft.transport.primary == .walk)
        }

        // MARK: toggleAlsoOK(_:)

        @Test("toggleAlsoOK(_:) adds a mode not yet in alsoOK")
        @MainActor
        func toggleAlsoOKAddsMode() {
            let draft = SampleData.onboardingAContext().toDomain()
            // toDomain() seeds alsoOK as [].
            #expect(draft.transport.alsoOK.isEmpty, "precondition: seeded alsoOK is empty")
            draft.toggleAlsoOK(.cycle)
            #expect(draft.transport.alsoOK.contains(.cycle))
        }

        @Test("toggleAlsoOK(_:) removes a mode that is already in alsoOK")
        @MainActor
        func toggleAlsoOKRemovesMode() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.toggleAlsoOK(.drive)
            #expect(draft.transport.alsoOK.contains(.drive),
                    "precondition: drive must be in alsoOK before toggling off")
            draft.toggleAlsoOK(.drive)
            #expect(!draft.transport.alsoOK.contains(.drive))
        }

        // MARK: advanceStep() / retreatStep()

        /// advanceStep() moves currentStep from .destination to .tripShape.
        @Test("advanceStep() advances from .destination to .tripShape")
        @MainActor
        func advanceStepFromDestination() {
            let draft = SampleData.onboardingAContext().toDomain()
            // toDomain() seeds currentStep: .destination
            #expect(draft.currentStep == .destination,
                    "precondition: toDomain seeds step .destination")
            draft.advanceStep()
            #expect(draft.currentStep == .tripShape)
        }

        /// advanceStep() is clamped: calling it on the last step (.generating) leaves step unchanged.
        @Test("advanceStep() is clamped at the last step (.generating)")
        @MainActor
        func advanceStepIsClampedAtEnd() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.currentStep = .generating  // fast-forward to the last step
            draft.advanceStep()
            #expect(draft.currentStep == .generating)
        }

        /// retreatStep() moves currentStep backward from .tripShape to .destination.
        @Test("retreatStep() retreats from .tripShape to .destination")
        @MainActor
        func retreatStepFromTripShape() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.currentStep = .tripShape
            draft.retreatStep()
            #expect(draft.currentStep == .destination)
        }

        /// retreatStep() is clamped: calling it on the first step (.destination) leaves step unchanged.
        @Test("retreatStep() is clamped at the first step (.destination)")
        @MainActor
        func retreatStepIsClampedAtStart() {
            let draft = SampleData.onboardingAContext().toDomain()
            // toDomain() seeds currentStep: .destination
            #expect(draft.currentStep == .destination,
                    "precondition: toDomain seeds step .destination")
            draft.retreatStep()
            #expect(draft.currentStep == .destination)
        }

        // MARK: restore(from:) — rollback seam

        /// restore(from:) reverts all mutable selection fields to the DTO snapshot.
        /// This mirrors the rollback path in the command suite (§5.1).
        @Test("restore(from:) reverts all mutable fields from a DTO snapshot")
        @MainActor
        func restoreReverts() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()
            let snapshot = draft.toDTO()   // capture the initial state

            // Mutate every field the restore seam covers.
            draft.select(city: ctx.cityOptions.first(where: { $0.id == "city-lisbon" })
                                 ?? ctx.destination)
            draft.select(strategy: .highlights)
            draft.setDays(6)
            draft.setTripMonth(year: 2027, month: 3)
            draft.setDatePrecision(.exactDates)
            draft.toggleInterest(.art)
            draft.setPace(.packed)
            draft.select(base: ctx.recommendedBase)
            draft.selectNeighborhood("neighborhood-alfama")
            draft.setBaseMode(.manual)
            draft.setPrimaryMode(.drive)
            draft.toggleAlsoOK(.rideshare)
            draft.advanceStep()

            // Restore from the snapshot taken before any mutation.
            draft.restore(from: snapshot)

            #expect(draft.destination == snapshot.destination)
            #expect(draft.shapeStrategy == snapshot.shapeStrategy)
            #expect(draft.tripDays == snapshot.tripDays)
            #expect(draft.tripWhen == snapshot.tripWhen)
            #expect(draft.tasteProfile == snapshot.tasteProfile)
            #expect(draft.baseSelection == snapshot.baseSelection)
            #expect(draft.selectedNeighborhoodID == snapshot.selectedNeighborhoodID)
            #expect(draft.baseMode == snapshot.baseMode)
            #expect(draft.transport == snapshot.transport)
            #expect(draft.currentStep == snapshot.currentStep)
            #expect(draft.generationPlan == snapshot.generationPlan)
            #expect(draft.onboardingState == snapshot.onboardingState)
        }

        // MARK: Derived properties from context catalog

        /// savedHere and savedAnywhere are pass-through reads of the immutable context.
        /// Confirms the derived properties surface the right values for fixture lookup.
        @Test("savedHere reflects context.savedHere for state A (stable id: city-lisbon)")
        @MainActor
        func savedHereDerivedFromContextA() {
            let draft = SampleData.onboardingAContext().toDomain()
            #expect(draft.savedHere == 23)
        }

        @Test("savedAnywhere is zero for state C (first trip)")
        @MainActor
        func savedAnywhereZeroForStateC() {
            let draft = SampleData.onboardingCContext().toDomain()
            #expect(draft.savedAnywhere == 0)
        }
    }

    // MARK: - Group 3: TripWhen + DatePrecision value tests

    @Suite("TripWhen and DatePrecision — value semantics and seedDefault")
    struct TripWhenAndDatePrecisionTests {

        /// seedDefault is a pure literal — verifiable without the live clock.
        @Test("TripWhen.seedDefault is (.justMonth, year 2026, month 6, no dates)")
        func tripWhenSeedDefault() {
            let w = TripWhen.seedDefault
            #expect(w.precision == .justMonth)
            #expect(w.year == 2026)
            #expect(w.month == 6)
            #expect(w.startDate == nil)
            #expect(w.endDate == nil)
        }

        /// A TripWhen with exactDates survives a Codable round-trip (including the Date fields).
        @Test("TripWhen with exactDates round-trips through JSON without data loss")
        func tripWhenExactDatesJSONRoundTrip() throws {
            let start = AppDate.make(y: 2026, m: 9, d: 15)
            let end   = AppDate.make(y: 2026, m: 9, d: 21)
            let original = TripWhen(
                precision: .exactDates,
                year: 2026,
                month: 9,
                startDate: start,
                endDate: end
            )
            let recovered = try codableRoundTrip(original)
            #expect(recovered == original)
            #expect(recovered.precision == .exactDates)
            #expect(recovered.startDate == start)
            #expect(recovered.endDate == end)
        }

        /// Label values are part of the UI contract — pin them explicitly.
        @Test("DatePrecision.justMonth.label == \"Just the month\"")
        func justMonthLabel() {
            #expect(DatePrecision.justMonth.label == "Just the month")
        }

        @Test("DatePrecision.exactDates.label == \"Exact dates\"")
        func exactDatesLabel() {
            #expect(DatePrecision.exactDates.label == "Exact dates")
        }

        /// CaseIterable must enumerate exactly the two live cases (no `flexible` case).
        @Test("DatePrecision.allCases contains exactly [.justMonth, .exactDates]")
        func allCasesContainsExactlyTwo() {
            let cases = DatePrecision.allCases
            #expect(cases.count == 2)
            #expect(cases.contains(.justMonth))
            #expect(cases.contains(.exactDates))
        }
    }

    // MARK: - Group 4: New TripDraftModel date and base methods

    @Suite("TripDraftModel — date and base-selection methods")
    struct TripDraftModelDateAndBaseTests {

        // MARK: setTripMonth(year:month:)

        @Test("setTripMonth(year:month:) updates tripWhen.year and .month")
        @MainActor
        func setTripMonthUpdatesYearAndMonth() {
            let draft = SampleData.onboardingAContext().toDomain()
            // Confirm the seed default before mutation.
            #expect(draft.tripWhen.year == 2026)
            #expect(draft.tripWhen.month == 6)

            draft.setTripMonth(year: 2027, month: 4)

            #expect(draft.tripWhen.year == 2027)
            #expect(draft.tripWhen.month == 4)
        }

        @Test("setTripMonth(year:month:) does not change precision or dates")
        @MainActor
        func setTripMonthPreservesPrecisionAndDates() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2027, month: 8)
            // precision and dates unchanged from seedDefault.
            #expect(draft.tripWhen.precision == .justMonth)
            #expect(draft.tripWhen.startDate == nil)
            #expect(draft.tripWhen.endDate == nil)
        }

        // MARK: setDatePrecision(.exactDates)

        /// When precision is switched to .exactDates, startDate is seeded to the 1st of the chosen
        /// month and endDate is start + (tripDays - 1) days.
        @Test("setDatePrecision(.exactDates) seeds startDate to first of chosen month and endDate to start+(tripDays-1)")
        @MainActor
        func setDatePrecisionExactDatesSeedsRange() {
            let draft = SampleData.onboardingAContext().toDomain()
            // Default tripDays == 4 (OnboardingContextDTO.defaultTripDays).
            #expect(draft.tripDays == 4, "precondition: toDomain seeds tripDays == 4")

            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)

            let expectedStart = AppDate.make(y: 2026, m: 9, d: 1)
            let expectedEnd   = AppDate.calendar.date(byAdding: .day, value: draft.tripDays - 1, to: expectedStart)!

            #expect(draft.tripWhen.precision == .exactDates)
            #expect(draft.tripWhen.startDate == expectedStart)
            #expect(draft.tripWhen.endDate   == expectedEnd)
        }

        /// Switching to .exactDates twice in a row (without clearing) must not re-seed the dates —
        /// the guard `if tripWhen.startDate == nil` in the implementation means calling it again
        /// when dates are already set is a no-op on the dates themselves.
        @Test("setDatePrecision(.exactDates) is idempotent when startDate is already set")
        @MainActor
        func setDatePrecisionExactDatesIdempotent() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)
            let firstStart = draft.tripWhen.startDate
            let firstEnd   = draft.tripWhen.endDate

            // Call again — dates must not change because startDate is already set.
            draft.setDatePrecision(.exactDates)
            #expect(draft.tripWhen.startDate == firstStart)
            #expect(draft.tripWhen.endDate   == firstEnd)
        }

        // MARK: setDatePrecision(.justMonth)

        @Test("setDatePrecision(.justMonth) clears startDate and endDate back to nil")
        @MainActor
        func setDatePrecisionJustMonthClearsDates() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 8)
            draft.setDatePrecision(.exactDates)
            #expect(draft.tripWhen.startDate != nil, "precondition: exactDates must seed a startDate")

            draft.setDatePrecision(.justMonth)

            #expect(draft.tripWhen.precision == .justMonth)
            #expect(draft.tripWhen.startDate == nil)
            #expect(draft.tripWhen.endDate   == nil)
        }

        // MARK: setExactStart(_:)

        /// If the new start is set so that the existing end is still >= start+(tripDays-1), the end
        /// must not be changed.  If the new start would make end too early, the end is floored up.
        @Test("setExactStart(_:) floors endDate when the new start pushes the minimum end past the old end")
        @MainActor
        func setExactStartFloorsEnd() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)   // start = Sep 1, end = Sep 4 (tripDays==4)

            // Move start to a later date so the old end (Sep 4) is now before start+(tripDays-1).
            let laterStart = AppDate.make(y: 2026, m: 9, d: 5)
            draft.setExactStart(laterStart)

            let minEnd = AppDate.calendar.date(byAdding: .day, value: draft.tripDays - 1, to: laterStart)!
            #expect(draft.tripWhen.startDate == laterStart)
            #expect(draft.tripWhen.endDate! >= minEnd)
        }

        @Test("setExactStart(_:) leaves endDate unchanged when the new start is early enough")
        @MainActor
        func setExactStartLeavesEndWhenSufficient() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)   // start = Sep 1, end = Sep 4

            // Move start earlier — end (Sep 4) is still >= start+(tripDays-1).
            // After setDatePrecision the end was seeded from Sep 1. Move start back to Sep 1 (same
            // day) — the end should not shift because it is already at the minimum.
            let sameStart = AppDate.make(y: 2026, m: 9, d: 1)
            let endBefore = draft.tripWhen.endDate!
            draft.setExactStart(sameStart)
            #expect(draft.tripWhen.endDate == endBefore)
        }

        // MARK: setExactEnd(_:)

        @Test("setExactEnd(_:) clamps a too-short end up to start+(tripDays-1)")
        @MainActor
        func setExactEndClampsShortEnd() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)   // start = Sep 1, end = Sep 4

            // Pass an end that is only 1 day after start — shorter than tripDays (4) requires.
            let tooEarlyEnd = AppDate.make(y: 2026, m: 9, d: 2)
            draft.setExactEnd(tooEarlyEnd)

            let start = draft.tripWhen.startDate!
            let minEnd = AppDate.calendar.date(byAdding: .day, value: draft.tripDays - 1, to: start)!
            #expect(draft.tripWhen.endDate == minEnd)
        }

        @Test("setExactEnd(_:) accepts a valid end that is at least tripDays from start")
        @MainActor
        func setExactEndAcceptsValidEnd() {
            let draft = SampleData.onboardingAContext().toDomain()
            draft.setTripMonth(year: 2026, month: 9)
            draft.setDatePrecision(.exactDates)

            // Pass an end that is comfortably beyond the minimum.
            let validEnd = AppDate.make(y: 2026, m: 9, d: 15)
            draft.setExactEnd(validEnd)

            #expect(draft.tripWhen.endDate == validEnd)
        }

        // MARK: selectNeighborhood(_:)

        /// selectNeighborhood sets selectedNeighborhoodID and clears baseSelection.
        @Test("selectNeighborhood(_:) sets selectedNeighborhoodID and clears baseSelection")
        @MainActor
        func selectNeighborhoodSetsIDAndClearsBase() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()

            // Pre-set a baseSelection so the clear is meaningful.
            draft.select(base: ctx.recommendedBase)
            #expect(draft.baseSelection != nil, "precondition: baseSelection must be set before selectNeighborhood")

            draft.selectNeighborhood("neighborhood-alfama")

            #expect(draft.selectedNeighborhoodID == "neighborhood-alfama")
            #expect(draft.baseSelection == nil)
        }

        // MARK: selectSpecificBase(_:)

        /// selectSpecificBase sets baseSelection and clears selectedNeighborhoodID.
        @Test("selectSpecificBase(_:) sets baseSelection and clears selectedNeighborhoodID")
        @MainActor
        func selectSpecificBaseSetsBaseAndClearsNeighborhood() {
            let ctx = SampleData.onboardingAContext()
            let draft = ctx.toDomain()

            // Pre-set a neighborhood pick so the clear is meaningful.
            draft.selectNeighborhood("neighborhood-alfama")
            #expect(draft.selectedNeighborhoodID != nil, "precondition: selectedNeighborhoodID must be set before selectSpecificBase")

            draft.selectSpecificBase(ctx.recommendedBase)

            #expect(draft.baseSelection?.id == ctx.recommendedBase.id)
            #expect(draft.selectedNeighborhoodID == nil)
        }
    }
}

// MARK: - A1: CityMeta + DiagramSpec associated-value Codable round-trips

/// Layer 1 — Unit: asserts the hand-written tag-keyed Codable implementations on CityMeta and
/// DiagramSpec are lossless. Uses the plain symmetric coder (never APIJSON).
///
/// Both types are leaf value types used directly on the wire; neither has a separate DTO.
/// Covering all cases guards against the hand-written Codable drifting when a case is added/renamed.
@Suite("CityMeta + DiagramSpec — associated-value Codable symmetry")
struct AssociatedValueCodableTests {

    // MARK: CityMeta (4 cases)

    /// All four CityMeta cases in one parameterized test.
    /// CityMeta uses manual tag-keyed Codable (City.swift:38-85); this guards every branch.
    @Test(
        "CityMeta: encode → decode is lossless for all cases",
        arguments: [
            CityMeta.savedCount(23),
            CityMeta.planStarted,
            CityMeta.neighborhood("Alfama"),
            CityMeta.medina,
        ]
    )
    func cityMetaRoundTrips(_ meta: CityMeta) throws {
        let recovered = try codableRoundTrip(meta)
        #expect(recovered == meta)
    }

    // MARK: DiagramSpec (3 cases + all-nil-optional rankedBars)

    /// All three DiagramSpec cases — including the encodeIfPresent/decodeIfPresent path for
    /// the optional pickIndex and dimIndex fields (TripShapeStrategy.swift:72-73 / :90-91).
    ///
    /// The fourth argument covers the nil-optional path:
    ///   .rankedBars(values: [0.5], pickIndex: nil, dimIndex: nil)
    /// This exercises decodeIfPresent returning nil, which is a separate code path from the
    /// non-nil case and has been zero-covered until this test.
    @Test(
        "DiagramSpec: encode → decode is lossless for all cases (incl. nil-optional rankedBars)",
        arguments: [
            DiagramSpec.fixedDays(filled: [0, 1, 2], dim: [3]),
            DiagramSpec.coverBucket(dayCounts: [2, 3, 1]),
            DiagramSpec.rankedBars(values: [0.8, 0.4, 0.2], pickIndex: 0, dimIndex: 2),
            DiagramSpec.rankedBars(values: [0.5], pickIndex: nil, dimIndex: nil),
        ]
    )
    func diagramSpecRoundTrips(_ spec: DiagramSpec) throws {
        let recovered = try codableRoundTrip(spec)
        #expect(recovered == spec)
    }
}

// MARK: - A2: Wire decode — APIJSON snake_case path

/// Layer 2 — Integration: proves the production APIJSON.decoder() (convertFromSnakeCase + iso8601)
/// correctly decodes the OnboardingContextDTO wire payload.
///
/// This is the wire-path analog to the symmetric round-trips in OnboardingContextDTORoundTripTests.
/// The symmetric tests (Group 1) use plain camelCase keys; this test uses the production decoder
/// on a payload that was encoded with the production encoder (convertToSnakeCase), proving that
/// the snake_case wire shape reaches the Swift model intact.
///
/// Key under test: `saved_here` → `savedHere` (a real production field the A-branch logic depends on).
///
/// Note on selectedNeighborhoodID: TripDraftDTO.selectedNeighborhoodID is a LOCAL-ONLY field —
/// it is never received from the backend (GetOnboardingContextRequest returns OnboardingContextDTO,
/// not TripDraftDTO). The acronym-suffix asymmetry (selected_neighborhood_id → selectedNeighborhoodId
/// via convertFromSnakeCase, not selectedNeighborhoodID) is therefore harmless in production and is
/// documented in the file header comment. The wire-path test targets the actual wire DTO.
@Suite("Wire decode — APIJSON snake_case")
struct APISNakeCaseDecodeTests {

    /// Encode a real OnboardingContextDTO fixture via APIJSON.encoder() (produces snake_case JSON),
    /// then decode via APIJSON.decoder() and assert the camelCase property `savedHere` was recovered.
    ///
    /// This test proves the full production encode → wire → decode cycle works for the key that
    /// drives the A/B/C onboarding branch. If APIJSON.decoder() failed to map `saved_here` →
    /// `savedHere`, the branch-selection logic would always see 0 and the B/C branch would fire.
    @Test("APIJSON: OnboardingContextDTO saved_here decodes to savedHere via convertFromSnakeCase")
    func savedHereDecodesViaAPICoder() throws {
        let ctx = SampleData.onboardingAContext()
        // State A fixture has savedHere == 23 (drives the returningWithLocalSaves branch).
        let expectedSavedHere = ctx.savedHere
        #expect(expectedSavedHere == 23, "fixture precondition: state A has savedHere == 23")

        // Encode with the production encoder (convertToSnakeCase) — mirrors the wire payload shape.
        let wireData = try APIJSON.encoder().encode(ctx)

        // Decode with the production decoder (convertFromSnakeCase + iso8601) — mirrors the client receive path.
        let decoded = try APIJSON.decoder().decode(OnboardingContextDTO.self, from: wireData)

        // The camelCase property must hold the original value after the snake_case round-trip.
        #expect(decoded.savedHere == expectedSavedHere)
        // savedAnywhere should also survive (no ID-suffix asymmetry here).
        #expect(decoded.savedAnywhere == ctx.savedAnywhere)
        // onboardingState is derived from savedHere — transitively proves the branch fires correctly.
        #expect(decoded.onboardingState == .returningWithLocalSaves)
    }
}
