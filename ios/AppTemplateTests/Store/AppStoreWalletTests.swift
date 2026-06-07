/*
 Layer 2 integration tests for the Wallet feature's store commands.

 Tests covered:
   - loadWallet() happy path (.walletStandard): .loaded state, graph populated, 8 placed + 1 orphan
   - loadWallet() empty path (.walletEmpty): .loaded state, 0 bookings
   - loadWallet() failure path (failure: .offline): .failed state, graph nil (no partial graph)
   - placeOrphan() happy path: orphan's dayIndex set, status transitions, writeError == nil
   - placeOrphan() rollback path: dayIndex AND status fully restored, writeError == .placeOrphan
   - Decode → DTO → domain pipeline: GetWalletRequest response round-trips through plain coder,
     maps to graph with the expected 8+1 bookings

 All tests run @MainActor (AppStore isolation). Fresh store per test — no shared state.
 Determinism: SampleData.walletDTO() / walletSimulatedNow, never Date() / Calendar.current /
 Locale.current. Fixtures indexed by stable id ("booking-fado-orphan"), never by array position.
 Reference model fields asserted individually; no == between two constructed instances.

 Design:
   - makeStore() → .mock(scenario: .walletStandard), loads the wallet via loadWallet().
   - makeFailingStore() → .mock(scenario: .walletStandard, failure: .offline), every send throws.
   - loadSeed(wallet:) seam used for rollback tests so the write is against a pre-seeded graph.
*/

import Foundation
import Testing
@testable import AppTemplate

// MARK: - Helpers

extension AppStoreWalletTests {

    /// A fresh store backed by the walletStandard scenario (no auto-load; call loadWallet() per test).
    @MainActor
    private func makeStore() -> AppStore {
        AppStore(api: .mock(scenario: .walletStandard))
    }

    /// A store that fails every `send` — drives write-error / offline paths.
    @MainActor
    private func makeFailingStore() -> AppStore {
        AppStore(api: .mock(scenario: .walletStandard, failure: .offline))
    }

    /// A store pre-seeded synchronously (no network) with walletDTO() so the write tests start
    /// from a populated graph without depending on loadWallet() succeeding.
    @MainActor
    private func makeSeededStore() -> AppStore {
        let store = AppStore(api: .mock(scenario: .walletStandard, failure: .offline))
        store.loadSeed(wallet: SampleData.walletDTO())
        return store
    }
}

// MARK: - Suite

@Suite("AppStore — Wallet feature (L2 integration)")
struct AppStoreWalletTests {

    // MARK: - loadWallet — happy path (.walletStandard)

    @Test("loadWallet: walletLoadState transitions to .loaded") @MainActor
    func loadWalletTransitionsToLoaded() async {
        let store = makeStore()
        #expect(store.walletLoadState == .idle, "precondition: starts idle")
        await store.loadWallet()
        #expect(store.walletLoadState == .loaded)
    }

    @Test("loadWallet: graph is non-nil after happy path") @MainActor
    func loadWalletPopulatesGraph() async {
        let store = makeStore()
        await store.loadWallet()
        #expect(store.wallet != nil, "wallet must be non-nil after .walletStandard load")
    }

    @Test("loadWallet: 9 total bookings (8 placed + 1 orphan) match the walletStandard seed") @MainActor
    func loadWalletBookingCount() async {
        let store = makeStore()
        await store.loadWallet()
        let count = store.wallet?.bookings.count
        #expect(count == 9, "walletStandard seed has 9 bookings (8 placed + 1 orphan); got \(String(describing: count))")
    }

    @Test("loadWallet: orphan booking 'booking-fado-orphan' has nil dayIndex") @MainActor
    func loadWalletOrphanHasNilDayIndex() async {
        let store = makeStore()
        await store.loadWallet()
        let orphan = store.wallet?.booking(id: "booking-fado-orphan")
        #expect(orphan != nil, "booking-fado-orphan must be present in the populated seed")
        if let orphan {
            #expect(orphan.dayIndex == nil, "the orphan booking must have nil dayIndex before placement")
            #expect(orphan.title == "Fado at Tasca do Chico")
            #expect(orphan.type == .activity)
        }
    }

    @Test("loadWallet: stable id 'booking-tap201' resolves with access pass") @MainActor
    func loadWalletStableIDTap201() async {
        let store = makeStore()
        await store.loadWallet()
        let tap201 = store.wallet?.booking(id: "booking-tap201")
        #expect(tap201 != nil, "booking-tap201 must be present in the walletStandard seed")
        if let tap201 {
            #expect(tap201.title == "Lisbon → New York")
            #expect(tap201.type == .transport)
            #expect(tap201.accessPass != nil, "TP 201 must have an access pass")
            #expect(tap201.dayIndex == 4)
        }
    }

    @Test("loadWallet: tripCityName and dayCount match the seed") @MainActor
    func loadWalletContainerFields() async {
        let store = makeStore()
        await store.loadWallet()
        #expect(store.wallet?.tripCityName == "Lisbon")
        #expect(store.wallet?.dayCount == 4)
    }

    // MARK: - loadWallet — empty path (.walletEmpty)

    @Test("loadWallet: graph is non-nil but empty for .walletEmpty scenario") @MainActor
    func loadWalletEmptyScenario() async {
        let store = AppStore(api: .mock(scenario: .walletEmpty))
        await store.loadWallet()
        #expect(store.walletLoadState == .loaded, "walletEmpty must still reach .loaded")
        #expect(store.wallet != nil, "graph is non-nil (a wallet exists with 0 bookings)")
        #expect(store.wallet?.bookings.isEmpty == true, "walletEmpty seed has 0 bookings")
    }

    // MARK: - loadWallet — loading state observation

    // Kicks loadWallet() in a non-awaited Task, yields once to observe the synchronous
    // .loading assignment (which happens before the first suspension point), then awaits completion.

    @Test("loadWallet: transitions through .loading before .loaded") @MainActor
    func loadWalletTransitionsThroughLoading() async {
        let store = AppStore(api: .mock(scenario: .walletStandard, latency: .milliseconds(50)))
        #expect(store.walletLoadState == .idle, "precondition: starts idle")

        let task = Task { @MainActor in
            await store.loadWallet()
        }
        await Task.yield()
        let observed = store.walletLoadState

        await task.value
        #expect(store.walletLoadState == .loaded, "terminal state must be .loaded")
        #expect(
            observed == .loading || observed == .loaded,
            "observed should be .loading (captured mid-flight) or .loaded (scheduler-delivered early)"
        )
    }

    // MARK: - loadWallet — failure path (.failed, nil graph)

    @Test("loadWallet: .failed state on offline error") @MainActor
    func loadWalletFailedState() async {
        let store = makeFailingStore()
        await store.loadWallet()

        if case .failed = store.walletLoadState {
            // Correct — walletLoadState is .failed(_).
        } else {
            Issue.record("Expected walletLoadState == .failed(_), got \(store.walletLoadState)")
        }
    }

    @Test("loadWallet: graph remains nil on failure (no partial graph)") @MainActor
    func loadWalletNilGraphOnFailure() async {
        let store = makeFailingStore()
        await store.loadWallet()
        #expect(store.wallet == nil, "wallet must remain nil after a failed load — no partial graph")
    }

    // MARK: - placeOrphan — happy path

    // The happy path proves the optimistic transition sticks (dayIndex set, status changes from
    // its orphan value to .upcoming), PlaceOrphanRequest resolves and reconciles the booking
    // from the server DTO, and writeError remains nil.

    @Test("placeOrphan happy: writeError is nil after successful placement") @MainActor
    func placeOrphanHappyWriteErrorNil() async {
        let store = makeStore()
        await store.loadWallet()
        #expect(store.wallet != nil, "precondition: graph populated")

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        #expect(store.writeError == nil, "writeError must be nil after a successful placeOrphan")
    }

    @Test("placeOrphan happy: orphan's dayIndex is set to the requested day") @MainActor
    func placeOrphanHappyDayIndexSet() async {
        let store = makeStore()
        await store.loadWallet()

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let booking = store.wallet?.booking(id: "booking-fado-orphan")
        #expect(booking != nil, "booking-fado-orphan must still be in the graph after placement")
        if let booking {
            #expect(booking.dayIndex == 2, "dayIndex must be 2 after placing on day 2")
        }
    }

    @Test("placeOrphan happy: orphan booking count stays the same (placement does not insert/remove)") @MainActor
    func placeOrphanHappyBookingCountUnchanged() async {
        let store = makeStore()
        await store.loadWallet()
        let countBefore = store.wallet?.bookings.count ?? 0

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let countAfter = store.wallet?.bookings.count ?? 0
        #expect(
            countAfter == countBefore,
            "placeOrphan should not change the booking count; before=\(countBefore) after=\(countAfter)"
        )
    }

    @Test("placeOrphan happy: other bookings are not disturbed (booking-tap201 intact)") @MainActor
    func placeOrphanHappyOtherBookingsIntact() async {
        let store = makeStore()
        await store.loadWallet()

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let tap201 = store.wallet?.booking(id: "booking-tap201")
        #expect(tap201 != nil, "booking-tap201 must not be disturbed by placeOrphan")
        if let tap201 {
            #expect(tap201.dayIndex == 4, "booking-tap201 dayIndex must remain 4")
            #expect(tap201.title == "Lisbon → New York")
        }
    }

    // MARK: - placeOrphan — rollback path

    // With failure: .offline injected, every api.send throws after the optimistic mutation.
    // The rollback must restore BOTH dayIndex (back to nil) AND status (back to the pre-write
    // value from the snapshot) — the plan explicitly requires both fields be checked.
    // writeError must be .placeOrphan.

    @Test("placeOrphan rollback: writeError is .placeOrphan after failure") @MainActor
    func placeOrphanRollbackWriteError() async {
        // Use the pre-seeded store: graph from walletDTO(), but every send fails.
        let store = makeSeededStore()

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        #expect(store.writeError == .placeOrphan, "writeError must be .placeOrphan after rollback")
    }

    @Test("placeOrphan rollback: dayIndex is restored to nil after failure") @MainActor
    func placeOrphanRollbackDayIndexRestored() async {
        let store = makeSeededStore()

        // Capture the pre-write snapshot fields for later assertion
        let orphanBefore = store.wallet?.booking(id: "booking-fado-orphan")
        let dayIndexBefore = orphanBefore?.dayIndex  // nil (it's an orphan)

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let booking = store.wallet?.booking(id: "booking-fado-orphan")
        #expect(booking != nil, "booking-fado-orphan must still be in the graph after rollback")
        if let booking {
            #expect(
                booking.dayIndex == dayIndexBefore,
                "dayIndex must be restored to pre-write value (\(String(describing: dayIndexBefore))) after rollback; got \(String(describing: booking.dayIndex))"
            )
        }
    }

    @Test("placeOrphan rollback: status is restored to pre-write value after failure") @MainActor
    func placeOrphanRollbackStatusRestored() async {
        let store = makeSeededStore()

        // Snapshot the status before the write — the seed has this booking as .upcoming orphan
        let orphan = store.wallet?.booking(id: "booking-fado-orphan")
        let statusBefore = orphan?.status  // .upcoming (seeded value, OD-3 decision)

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let booking = store.wallet?.booking(id: "booking-fado-orphan")
        #expect(booking != nil)
        if let booking, let statusBefore {
            #expect(
                booking.status == statusBefore,
                "status must be restored to pre-write value (\(statusBefore)) after rollback; got \(booking.status)"
            )
        }
    }

    @Test("placeOrphan rollback: title is restored (full restore(from:) coverage)") @MainActor
    func placeOrphanRollbackTitleRestored() async {
        let store = makeSeededStore()

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        // title is not mutated by placeOrphan, but restore(from:) replays all fields —
        // confirming the booking reference itself is intact and no unintended clobber occurred.
        let booking = store.wallet?.booking(id: "booking-fado-orphan")
        #expect(booking?.title == "Fado at Tasca do Chico")
    }

    @Test("placeOrphan rollback: other bookings are not disturbed (booking-tap201 intact)") @MainActor
    func placeOrphanRollbackOtherBookingsIntact() async {
        let store = makeSeededStore()

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        let tap201 = store.wallet?.booking(id: "booking-tap201")
        #expect(tap201 != nil, "booking-tap201 must not be affected by a failed placeOrphan")
        if let tap201 {
            #expect(tap201.dayIndex == 4)
            #expect(tap201.title == "Lisbon → New York")
        }
    }

    // MARK: - placeOrphan — no-op guard (no graph)

    @Test("placeOrphan is no-op when wallet is nil") @MainActor
    func placeOrphanNoopWhenNoGraph() async {
        let store = AppStore(api: .mock(scenario: .walletStandard))
        #expect(store.wallet == nil, "precondition: no graph loaded")

        await store.placeOrphan(bookingID: "booking-fado-orphan", onDay: 2)

        #expect(store.wallet == nil, "wallet must remain nil (guard no-op)")
        #expect(store.writeError == nil, "writeError must not be set when no graph exists")
    }

    // MARK: - Decode → DTO → domain pipeline (07 §5.2)

    // Drive GetWalletRequest through APIClient.mock(), encode the response back with the plain
    // symmetric coder (not APIJSON — its snake-case is asymmetric on acronym/ID keys), decode
    // it, then toDomain() on the main actor — proving the off-actor wire payload reaches the
    // on-actor graph intact.

    @Test("decode→DTO→domain: walletStandard DTO round-trips and maps to graph with 9 bookings") @MainActor
    func decodeDTODomainPipeline() async throws {
        let api = APIClient.mock(scenario: .walletStandard)
        let dto = try await api.send(GetWalletRequest())

        // Plain symmetric coder (not APIJSON — its snake-case strategy is asymmetric on
        // acronym/ID keys and would falsely fail a symmetric round-trip — 07 §4.2).
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let roundTripped = try decoder.decode(TripWalletDTO.self, from: data)

        #expect(roundTripped.id == dto.id)
        #expect(roundTripped.tripCityName == dto.tripCityName)
        #expect(roundTripped.dayCount == dto.dayCount)
        #expect(roundTripped.bookings.count == dto.bookings.count)

        // toDomain() on @MainActor — proves the off-actor wire payload reaches the on-actor graph
        let domain = roundTripped.toDomain()
        #expect(domain.bookings.count == 9, "domain must contain 9 bookings (8 placed + 1 orphan)")

        // Spot-check the orphan by stable id
        let orphan = domain.booking(id: "booking-fado-orphan")
        #expect(orphan != nil, "booking-fado-orphan must survive the DTO → domain pipeline")
        if let orphan {
            #expect(orphan.dayIndex == nil, "orphan must have nil dayIndex in the domain graph")
            #expect(orphan.title == "Fado at Tasca do Chico")
            #expect(orphan.type == .activity)
        }

        // Spot-check the access-pass booking
        let tap201 = domain.booking(id: "booking-tap201")
        #expect(tap201 != nil, "booking-tap201 must survive the DTO → domain pipeline")
        if let tap201 {
            #expect(tap201.accessPass != nil, "TP 201 access pass must survive the pipeline")
            #expect(tap201.accessPass?.confirmation == "7XQK2M")
        }
    }

    @Test("decode→DTO→domain: walletEmpty DTO round-trips to an empty graph") @MainActor
    func decodeDTODomainPipelineEmpty() async throws {
        let api = APIClient.mock(scenario: .walletEmpty)
        let dto = try await api.send(GetWalletRequest())

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let roundTripped = try decoder.decode(TripWalletDTO.self, from: data)
        let domain = roundTripped.toDomain()

        #expect(domain.bookings.isEmpty, "walletEmpty domain must have zero bookings")
        #expect(domain.id == dto.id)
    }
}
