/*
 The manual base picker (OPEN DECISION 5, now resolved): a map sheet with a place-search well. The user
 searches a hotel/address (MKLocalSearch over the destination region), taps a result to drop a pin, then
 confirms — the pinned place is handed back as a BaseLocation for the draft.

 Self-contained: MapKit lives here, not in the model. Layout uses semantic tokens; the one accent is the
 confirm button's tint + the map marker (state/emphasis only, J-2.4).
*/
import SwiftUI
import MapKit
import CoreLocation

struct ManualAddressPickerSheet: View {

    let initialRegion: MKCoordinateRegion
    let onUse: (BaseLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var results: [PlaceResult] = []
    @State private var pinned: PlaceResult?
    @State private var cameraPosition: MapCameraPosition
    @State private var searchRegion: MKCoordinateRegion
    @State private var searchTask: Task<Void, Never>?

    init(initialRegion: MKCoordinateRegion, onUse: @escaping (BaseLocation) -> Void) {
        self.initialRegion = initialRegion
        self.onUse = onUse
        _cameraPosition = State(initialValue: .region(initialRegion))
        _searchRegion = State(initialValue: initialRegion)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                map
                searchOverlay
            }
            .safeAreaInset(edge: .bottom) { useBar }
            .navigationTitle("Pick a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("addresspicker.cancel")
                }
            }
        }
    }

    // MARK: - Map

    private var map: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let pinned {
                    Marker(pinned.name, coordinate: pinned.coordinate)
                        .tint(ColorRole.actionPrimary)
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange { context in searchRegion = context.region }
            // Tap anywhere on the map to drop a pin there; the address back-fills the search field.
            .onTapGesture { screenPoint in
                if let coordinate = proxy.convert(screenPoint, from: .local) {
                    Task { await dropPin(at: coordinate) }
                }
            }
            .accessibilityIdentifier("addresspicker.map")
            // VoiceOver can't tap-on-map spatially; describe the map and expose the tap-to-pin behaviour
            // as a non-spatial action that drops a pin at the current search-region centre.
            .accessibilityLabel("Map — search a place above or tap a result to drop a pin")
            .accessibilityAction(named: "Drop pin at map center") {
                Task { await dropPin(at: searchRegion.center) }
            }
        }
    }

    // MARK: - Search well + results

    private var searchOverlay: some View {
        VStack(spacing: Spacing.sm) {
            SearchWell(
                text: $query,
                placeholder: "Search hotel or address",
                kbdHint: nil,
                showsClearButton: true,
                accessibilityID: "addresspicker.search",
                accessibilityLabel: "Search address",
                focused: $searchFocused
            )
            // Opaque paper backing + rest shadow so the well reads as a floating control over the map,
            // not the translucent fill it uses against an opaque screen.
            .background(ColorRole.surfacePage, in: .capsule)
            .shadowRest()
            // Search as you type (debounced) — no need to submit.
            .onChange(of: query) { _, value in scheduleSearch(value) }
            .onSubmit {
                searchTask?.cancel()
                Task { await runSearch() }
            }

            if !results.isEmpty {
                resultsList
                    // Slide down from under the well + fade, rather than popping in.
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(Spacing.lg)
        .animation(reduceMotion ? nil : Motion.standard(), value: results.isEmpty)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(results) { result in
                    resultRow(result)
                    if result.id != results.last?.id {
                        Divider().overlay(ColorRole.separator)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .frame(maxHeight: resultsMaxHeight)
        .background(ColorRole.surfacePage, in: .rect(cornerRadius: Radius.card))
        .scrollDismissesKeyboard(.immediately)
    }

    private func resultRow(_ result: PlaceResult) -> some View {
        Button {
            select(result)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "mappin.circle.fill")
                    .font(Typography.title)
                    .foregroundStyle(ColorRole.textTertiary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(result.name)
                        .font(Typography.name)
                        .foregroundStyle(ColorRole.textPrimary)
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(ColorRole.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: Spacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("addresspicker.result.\(result.id)")
    }

    // MARK: - Confirm bar

    private var useBar: some View {
        Button("Use this location") {
            guard let pinned else { return }
            onUse(pinned.asBaseLocation)
            dismiss()
        }
        .buttonStyle(.glassProminent)
        .tint(ColorRole.actionPrimary)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .frame(maxWidth: .infinity)
        .disabled(pinned == nil)
        .padding(.horizontal, Spacing.screenInset)
        .padding(.bottom, Spacing.sm)
        .accessibilityIdentifier("addresspicker.use")
    }

    // MARK: - Actions

    private func select(_ result: PlaceResult) {
        searchTask?.cancel()
        pinned = result
        query = result.name
        results = []
        searchFocused = false
        withAnimation(Motion.standard()) {
            cameraPosition = .region(
                MKCoordinateRegion(center: result.coordinate, span: Self.pinSpan)
            )
        }
    }

    // Tap-to-pin: place the pin immediately, then reverse-geocode the coordinate to label it + fill the field.
    private func dropPin(at coordinate: CLLocationCoordinate2D) async {
        searchTask?.cancel()
        let provisional = PlaceResult(
            id: "\(coordinate.latitude),\(coordinate.longitude)",
            name: "Dropped pin",
            subtitle: "",
            coordinate: coordinate
        )
        pinned = provisional
        results = []
        searchFocused = false

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        let name = placemark?.name ?? placemark?.thoroughfare ?? "Dropped pin"
        let subtitle = [placemark?.locality, placemark?.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")

        let resolved = PlaceResult(id: provisional.id, name: name, subtitle: subtitle, coordinate: coordinate)
        // Ignore a stale geocode if the user moved the pin again before it returned.
        guard pinned?.id == provisional.id else { return }
        pinned = resolved
        query = name
    }

    // Debounce keystrokes: cancel the in-flight search and run a fresh one ~300ms after typing settles.
    private func scheduleSearch(_ value: String) {
        searchTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { results = []; return }
        // Don't re-search the label we just wrote into the field from a selection / dropped pin.
        guard trimmed != pinned?.name else { return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await runSearch()
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { results = []; return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = searchRegion

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems.map { PlaceResult($0) }
        } catch {
            results = []   // a failed/empty search just clears the list; the map stays put
        }
    }

    // MARK: - Constants

    @ScaledMetric(relativeTo: .body) private var resultsMaxHeight: CGFloat = 280
    private static let pinSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
}

// MARK: - PlaceResult

/// A flattened MKMapItem — just what the picker needs (name, address line, coordinate), so MapKit's
/// reference type doesn't leak into the view's identity/diffing.
private struct PlaceResult: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    init(id: String, name: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    init(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        self.coordinate = coordinate
        self.name = item.name ?? "Dropped pin"
        self.subtitle = item.placemark.title ?? ""
        self.id = "\(coordinate.latitude),\(coordinate.longitude)-\(item.name ?? "")"
    }

    var asBaseLocation: BaseLocation {
        BaseLocation(
            id: "manual-\(id)",
            neighborhoodName: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            homeLatitude: coordinate.latitude,
            homeLongitude: coordinate.longitude,
            pins: [],
            zoneLabel: subtitle.isEmpty ? name : subtitle
        )
    }
}
