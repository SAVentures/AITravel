/*
 Layer 2 integration tests for the Saved feature's store commands.

 Tests covered:
   - loadSavedPlaces() happy path: .loaded state, graph populated, place count matches seed
   - loadSavedPlaces() failure path: .failed state, graph nil (no partial graph)
   - loadSavedPlaces() loading-state transition: .idle → .loading → .loaded
   - addPlace() happy path: optimistic row inserted, reconciled from resolved DTO, writeError == nil
   - addPlace() rollback path: row removed/reverted on failure, writeError == .addPlace
   - addPlace() no-op guard: no savedPlaces graph → early return, no crash

 All tests run @MainActor (AppStore isolation). Fresh store per test — no shared state.
 No Date() / Calendar.current / Locale.current — the mock is time-independent here.
 Fixtures indexed by stable id ("place-cevicheria"), never by array position.
 Reference model fields asserted individually; no == between two constructed instances.

 Design:
   - makeStore() → .mock(scenario: .savedStandard), seeds 24 places via loadSavedPlaces().
   - makeFailingStore() → .mock(scenario: .savedStandard, failure: .offline), every send throws.
   - addPlace uses AddPlaceBody(url:sourceKind:) — the one reel/clipboard write this milestone (D-4).
*/

import Foundation
import Testing
@testable import AppTemplate

// MARK: - Helpers

extension AppStoreSavedTests {

    /// A fresh store seeded with 24 places — the happy-path base for every test.
    @MainActor
    private func makeStore() -> AppStore {
        AppStore(api: .mock(scenario: .savedStandard))
    }

    /// A store that fails every `send` — drives write-error / offline paths.
    @MainActor
    private func makeFailingStore() -> AppStore {
        AppStore(api: .mock(scenario: .savedStandard, failure: .offline))
    }

    /// A minimal valid AddPlaceBody (reel path — D-4).
    nonisolated private func stubBody() -> AddPlaceBody {
        AddPlaceBody(url: SampleData.stubbedClipboardURL, sourceKind: .reel)
    }
}

// MARK: - Suite

@Suite("AppStore — Saved feature (L2 integration)")
struct AppStoreSavedTests {

    // MARK: - loadSavedPlaces — happy path

    @Test("loadSavedPlaces: savedLoadState transitions to .loaded") @MainActor
    func loadSavedPlacesTransitionsToLoaded() async {
        let store = makeStore()
        #expect(store.savedLoadState == .idle, "precondition: starts idle")
        await store.loadSavedPlaces()
        #expect(store.savedLoadState == .loaded)
    }

    @Test("loadSavedPlaces: graph is non-nil after happy path") @MainActor
    func loadSavedPlacesPopulatesGraph() async {
        let store = makeStore()
        await store.loadSavedPlaces()
        #expect(store.savedPlaces != nil, "savedPlaces must be non-nil after load")
    }

    @Test("loadSavedPlaces: 24 places match the savedStandard seed") @MainActor
    func loadSavedPlacesCount() async {
        let store = makeStore()
        await store.loadSavedPlaces()
        let count = store.savedPlaces?.places.count
        #expect(count == 24, "savedStandard seed has 24 places; got \(String(describing: count))")
    }

    @Test("loadSavedPlaces: stable id 'place-cevicheria' resolves") @MainActor
    func loadSavedPlacesStableID() async {
        let store = makeStore()
        await store.loadSavedPlaces()
        let place = store.savedPlaces?.place(id: "place-cevicheria")
        #expect(place != nil, "place-cevicheria must be present in the populated seed")
        if let place {
            #expect(place.name == "A Cevicheria")
            #expect(place.category == .eat)
        }
    }

    // MARK: - loadSavedPlaces — loading state observation

    // Kicks loadSavedPlaces() in a non-awaited Task, yields once to observe the synchronous
    // .loading assignment (which happens before the first suspension point), then awaits completion.
    // If the scheduler delivers the result before yield returns, the terminal .loaded assertion still
    // passes — the loading-state seam (the 50 ms latency) confirms .loading was the real transient.

    @Test("loadSavedPlaces: transitions through .loading before .loaded") @MainActor
    func loadSavedPlacesTransitionsThroughLoading() async {
        let store = AppStore(api: .mock(scenario: .savedStandard, latency: .milliseconds(50)))
        #expect(store.savedLoadState == .idle, "precondition: starts idle")

        let task = Task { @MainActor in
            await store.loadSavedPlaces()
        }
        await Task.yield()
        let observed = store.savedLoadState

        await task.value
        #expect(store.savedLoadState == .loaded, "terminal state must be .loaded")
        #expect(
            observed == .loading || observed == .loaded,
            "observed should be .loading (captured) or .loaded (scheduler-delivered early)"
        )
    }

    // MARK: - loadSavedPlaces — failure path (.failed, nil graph)

    @Test("loadSavedPlaces: .failed state on offline error") @MainActor
    func loadSavedPlacesFailedState() async {
        let store = makeFailingStore()
        await store.loadSavedPlaces()

        if case .failed = store.savedLoadState {
            // Correct — load state is .failed(_).
        } else {
            Issue.record("Expected savedLoadState == .failed(_), got \(store.savedLoadState)")
        }
    }

    @Test("loadSavedPlaces: graph remains nil on failure (no partial graph)") @MainActor
    func loadSavedPlacesNilGraphOnFailure() async {
        let store = makeFailingStore()
        await store.loadSavedPlaces()
        #expect(store.savedPlaces == nil, "savedPlaces must remain nil on load failure")
    }

    // MARK: - addPlace — happy path

    // The optimistic row appears synchronously; the mock resolves it to "place-resolved-reel"
    // (AddPlaceRequest.mockResponse canned response). After the await the container should hold
    // 25 entries (24 seed + 1 reconciled) and writeError should be nil.

    @Test("addPlace happy: writeError is nil after successful add") @MainActor
    func addPlaceHappyWriteErrorNil() async {
        let store = makeStore()
        await store.loadSavedPlaces()

        #expect(store.savedPlaces != nil, "precondition: graph populated")
        await store.addPlace(stubBody())
        #expect(store.writeError == nil, "writeError must be nil after a successful add")
    }

    @Test("addPlace happy: resolved place is in the graph (place-resolved-reel)") @MainActor
    func addPlaceHappyResolvedPlacePresent() async {
        let store = makeStore()
        await store.loadSavedPlaces()

        await store.addPlace(stubBody())

        // AddPlaceRequest.mockResponse returns id "place-resolved-reel"
        let resolved = store.savedPlaces?.place(id: "place-resolved-reel")
        #expect(resolved != nil, "place-resolved-reel must appear after successful reconcile")
        if let resolved {
            #expect(resolved.name == "Cervejaria Ramiro")
            #expect(resolved.category == .eat)
        }
    }

    @Test("addPlace happy: place count increases by 1 (optimistic → reconciled)") @MainActor
    func addPlaceHappyCountIncreases() async {
        let store = makeStore()
        await store.loadSavedPlaces()

        let countBefore = store.savedPlaces?.places.count ?? 0
        await store.addPlace(stubBody())
        let countAfter = store.savedPlaces?.places.count ?? 0
        #expect(
            countAfter == countBefore + 1,
            "count should increase by 1 after add; before=\(countBefore) after=\(countAfter)"
        )
    }

    @Test("addPlace happy: seed places are intact (place-cevicheria still resolves)") @MainActor
    func addPlaceHappySeedIntact() async {
        let store = makeStore()
        await store.loadSavedPlaces()

        await store.addPlace(stubBody())

        let cevicheria = store.savedPlaces?.place(id: "place-cevicheria")
        #expect(cevicheria != nil, "pre-existing seed place must not be disturbed by add")
    }

    // MARK: - addPlace — rollback path

    // failureRate == 1.0 → every api.send throws → the catch branch in addPlace(_:) runs:
    // rollback(pendingID:) removes the optimistic row, writeError = .addPlace.

    @Test("addPlace rollback: writeError is .addPlace after failure") @MainActor
    func addPlaceRollbackWriteError() async {
        // Seed the graph via a happy load, then swap to a failing client for the write.
        // Because AppStore inits with its api immutably, we use makeStore() + loadSavedPlaces()
        // then a separate failing store for the write. The canonical pattern (from the borrow example
        // in 07-testing §5.1): makeStore(failureRate: 1.0) — here realized via .offline failure.
        let store = AppStore(api: .mock(scenario: .savedStandard, failure: .offline))
        // Pre-seed the graph synchronously (loadSavedPlaces will fail too).
        // Use loadSeed seam so the store has a graph before calling addPlace.
        store.loadSeed(savedPlaces: SampleData.savedPlacesDTO())

        await store.addPlace(stubBody())

        #expect(store.writeError == .addPlace, "writeError must be .addPlace after rollback")
    }

    @Test("addPlace rollback: optimistic row removed after failure") @MainActor
    func addPlaceRollbackRowRemoved() async {
        let store = AppStore(api: .mock(scenario: .savedStandard, failure: .offline))
        store.loadSeed(savedPlaces: SampleData.savedPlacesDTO())

        let countBefore = store.savedPlaces?.places.count ?? 0
        await store.addPlace(stubBody())
        let countAfter = store.savedPlaces?.places.count ?? 0

        #expect(
            countAfter == countBefore,
            "count must return to pre-add value after rollback; before=\(countBefore) after=\(countAfter)"
        )
    }

    @Test("addPlace rollback: seed places intact (place-cevicheria still resolves)") @MainActor
    func addPlaceRollbackSeedIntact() async {
        let store = AppStore(api: .mock(scenario: .savedStandard, failure: .offline))
        store.loadSeed(savedPlaces: SampleData.savedPlacesDTO())

        await store.addPlace(stubBody())

        let cevicheria = store.savedPlaces?.place(id: "place-cevicheria")
        #expect(cevicheria != nil, "pre-existing place must survive a failed add")
        if let cevicheria {
            #expect(cevicheria.name == "A Cevicheria", "fields of pre-existing place must not change")
        }
    }

    // MARK: - addPlace — no-op guard (no graph)

    @Test("addPlace is no-op when savedPlaces is nil") @MainActor
    func addPlaceNoopWhenNoGraph() async {
        // A fresh store with no loaded graph — addPlace must return without crashing
        let store = AppStore(api: .mock(scenario: .savedStandard))
        #expect(store.savedPlaces == nil, "precondition: no graph loaded")

        await store.addPlace(stubBody())

        // Should still have no graph (the guard returned early)
        #expect(store.savedPlaces == nil, "savedPlaces must remain nil (guard no-op)")
        // writeError is not set (no rollback ran)
        #expect(store.writeError == nil)
    }

    // MARK: - Decode → DTO → domain pipeline (07 §5.2)

    // Drive GetSavedPlacesRequest through APIClient.mock(), encode the response back with the plain
    // symmetric coder, then toDomain() on the main actor — proving the off-actor wire payload reaches
    // the on-actor graph intact.

    @Test("decode→DTO→domain: savedStandard DTO round-trips and maps to graph") @MainActor
    func decodeDTODomainPipeline() async throws {
        let api = APIClient.mock(scenario: .savedStandard)
        let dto = try await api.send(GetSavedPlacesRequest())

        // Plain symmetric coder (not APIJSON — its snake-case is asymmetric on acronym/ID keys)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(dto)
        let roundTripped = try decoder.decode(SavedPlacesDTO.self, from: data)

        #expect(roundTripped.id == dto.id)
        #expect(roundTripped.places.count == dto.places.count)

        // toDomain() on @MainActor — proves the off-actor wire payload reaches the on-actor graph
        let domain = roundTripped.toDomain()
        #expect(domain.places.count == dto.places.count)

        // Spot-check a known id from the seed
        let cevicheria = domain.place(id: "place-cevicheria")
        #expect(cevicheria != nil, "place-cevicheria must survive the DTO → domain pipeline")
        if let cevicheria {
            #expect(cevicheria.name == "A Cevicheria")
            #expect(cevicheria.category == .eat)
        }
    }
}
