/*
 Saved-tab sample data — faithful to mockups/screens/saved/saved-populated.html (by-category)
 and saved-by-source.html (by-source).

 Hero counts: 24 places · 3 cities (Lisbon, Tokyo, Porto) · from 11 sources.
 By category: Eat × 7, Drink × 4, Stay × 5, Do × 6, Shop × 2.

 The reel @saltinmycoffee ("Lisbon in 48 hours") contains 3 places — the multi-child card
 the by-source view shows expanded: A Cevicheria (0:42), Park Bar (1:15),
 Time Out Market (2:03). @tokyo.eats ("Tokyo eats you can't miss") contains 4 places.

 Architecture:
 - `savedPlacesDTO()` / `emptySavedPlacesDTO()` are the primary builders (plain, not @MainActor)
   so they can be called from SampleData.seed(for:) without actor isolation.
 - `savedPlaces()` / `emptySavedPlaces()` build the live reference graph (@MainActor) by calling
   toDomain() on the DTO — one source, two representations, kept in lock-step (02-models §5).

 All ids are stable literals so previews/tests hard-link without UUID().
 simulatedNow is pinned to the mockup's "9:41" status-bar instant.
*/
import Foundation

extension SampleData {

    // MARK: - simulatedNow

    /// Fixed clock for all time-conditional state in the Saved seed.
    /// Pinned to 2025-07-15 09:41 UTC — matches the "9:41" status-bar in the mockups.
    static var savedSimulatedNow: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 7
        components.day = 15
        components.hour = 9
        components.minute = 41
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - DTO builders (plain — callable from seed(for:))

    /// Wire snapshot: 24-place populated set (Eat×7, Drink×4, Stay×5, Do×6, Shop×2).
    static func savedPlacesDTO() -> SavedPlacesDTO {
        SavedPlacesDTO(id: "saved-places-main", places: placeDTOList())
    }

    /// Wire snapshot: 0 places — drives the rich empty-state screen.
    static func emptySavedPlacesDTO() -> SavedPlacesDTO {
        SavedPlacesDTO(id: "saved-places-main", places: [])
    }

    // MARK: - Reference-graph builders (@MainActor — builds @Observable models)

    /// Builds the live `SavedPlacesModel` reference graph for previews and unit tests.
    @MainActor
    static func savedPlaces() -> SavedPlacesModel {
        savedPlacesDTO().toDomain()
    }

    /// Builds an empty `SavedPlacesModel` for the rich empty-state preview.
    @MainActor
    static func emptySavedPlaces() -> SavedPlacesModel {
        emptySavedPlacesDTO().toDomain()
    }
}

// MARK: - PlaceDTO list (24 entries)

extension SampleData {

    // swiftlint:disable function_body_length
    fileprivate static func placeDTOList() -> [PlaceDTO] {
        [
            // ── EAT (7) ────────────────────────────────────────────────────────────────────────

            // 1. A Cevicheria — reel @saltinmycoffee "Lisbon in 48 hours" @ 0:42
            PlaceDTO(
                id: "place-cevicheria",
                name: "A Cevicheria",
                category: .eat,
                location: PlaceLocation(neighborhood: "Príncipe Real", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours"),
                provenance: PlaceProvenance(
                    sourceHandle: "saltinmycoffee",
                    clipTitle: "Lisbon in 48 hours",
                    timestamp: "0:42",
                    quote: "The best ceviche in Lisbon — seriously, queue for it."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "12 pm – 11 pm", sub: "Closed Sundays"),
                    PlaceFacts(key: "Price", value: "€€"),
                    PlaceFacts(key: "Cuisine", value: "Peruvian · Seafood"),
                ],
                addressLine: "Rua Dom Pedro V 129, Príncipe Real",
                latitude: 38.7170,
                longitude: -9.1490,
                savedAtNote: "Bookmarked from reel"
            ),

            // 2. Time Out Market — reel @saltinmycoffee "Lisbon in 48 hours" @ 2:03
            PlaceDTO(
                id: "place-timeout-market",
                name: "Time Out Market",
                category: .eat,
                location: PlaceLocation(neighborhood: "Cais do Sodré", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours"),
                provenance: PlaceProvenance(
                    sourceHandle: "saltinmycoffee",
                    clipTitle: "Lisbon in 48 hours",
                    timestamp: "2:03",
                    quote: "Every stall worth a visit — go at noon before the crowds."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "10 am – 12 am"),
                    PlaceFacts(key: "Price", value: "€–€€"),
                    PlaceFacts(key: "Cuisine", value: "Market · Multi"),
                ],
                addressLine: "Av. 24 de Julho 49, Cais do Sodré",
                latitude: 38.7070,
                longitude: -9.1455
            ),

            // 3. Afuri Ramen — reel @tokyo.eats "Tokyo eats you can't miss"
            PlaceDTO(
                id: "place-afuri-ramen",
                name: "Afuri Ramen",
                category: .eat,
                location: PlaceLocation(neighborhood: "Ebisu", cityName: "Tokyo"),
                source: .reel(handle: "tokyo.eats", clipTitle: "Tokyo eats you can't miss"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyo.eats",
                    clipTitle: "Tokyo eats you can't miss",
                    timestamp: "1:10",
                    quote: "Yuzu shio ramen — bright, clean, nothing like the heavy tonkotsu."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "11 am – 11 pm"),
                    PlaceFacts(key: "Price", value: "¥¥"),
                    PlaceFacts(key: "Cuisine", value: "Ramen"),
                ],
                addressLine: "1-1-7 Ebisu, Shibuya-ku, Tokyo",
                latitude: 35.6480,
                longitude: 139.7100
            ),

            // 4. Tasca do Chico — reel @lisbonfinds "Fado dinner spots"
            PlaceDTO(
                id: "place-tasca-chico",
                name: "Tasca do Chico",
                category: .eat,
                location: PlaceLocation(neighborhood: "Bairro Alto", cityName: "Lisbon"),
                source: .reel(handle: "lisbonfinds", clipTitle: "Fado dinner spots"),
                provenance: PlaceProvenance(
                    sourceHandle: "lisbonfinds",
                    clipTitle: "Fado dinner spots",
                    timestamp: "0:55",
                    quote: "Tiny, no-reservation, authentic fado every night from 9 pm."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "7 pm – 1 am", sub: "Fado from 9 pm"),
                    PlaceFacts(key: "Price", value: "€€"),
                    PlaceFacts(key: "Cuisine", value: "Portuguese · Fado"),
                ],
                addressLine: "Rua do Diário de Notícias 39, Bairro Alto",
                latitude: 38.7131,
                longitude: -9.1429
            ),

            // 5. Pastéis de Belém — screenshot (Maps list)
            PlaceDTO(
                id: "place-pasteis-belem",
                name: "Pastéis de Belém",
                category: .eat,
                location: PlaceLocation(neighborhood: "Belém", cityName: "Lisbon"),
                source: .screenshot(savedNote: "Maps list · screenshot"),
                provenance: PlaceProvenance(
                    sourceHandle: "mapslist",
                    clipTitle: "Maps list · screenshot",
                    timestamp: "saved Jul 3",
                    quote: nil
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "8 am – 11 pm"),
                    PlaceFacts(key: "Price", value: "€"),
                    PlaceFacts(key: "Cuisine", value: "Bakery · Pastry"),
                ],
                addressLine: "Rua de Belém 84-92, Belém",
                latitude: 38.6978,
                longitude: -9.2035
            ),

            // 6. Sushi Saito — reel @tokyohidden "Tokyo hidden gems"
            PlaceDTO(
                id: "place-sushi-saito",
                name: "Sushi Saito",
                category: .eat,
                location: PlaceLocation(neighborhood: "Roppongi", cityName: "Tokyo"),
                source: .reel(handle: "tokyohidden", clipTitle: "Tokyo hidden gems"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyohidden",
                    clipTitle: "Tokyo hidden gems",
                    timestamp: "1:30",
                    quote: "Reserve 3 months out. Worth every email."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "12 pm – 2 pm, 6 pm – 9 pm", sub: "Reservation only"),
                    PlaceFacts(key: "Price", value: "¥¥¥¥"),
                    PlaceFacts(key: "Cuisine", value: "Omakase Sushi"),
                ],
                addressLine: "1-9-15 Roppongi, Minato-ku, Tokyo",
                latitude: 35.6628,
                longitude: 139.7320
            ),

            // 7. Cantinho do Avillez — search
            PlaceDTO(
                id: "place-cantinho-avillez",
                name: "Cantinho do Avillez",
                category: .eat,
                location: PlaceLocation(neighborhood: "Chiado", cityName: "Lisbon"),
                source: .search,
                facts: [
                    PlaceFacts(key: "Hours", value: "12 pm – 12 am"),
                    PlaceFacts(key: "Price", value: "€€€"),
                    PlaceFacts(key: "Cuisine", value: "Modern Portuguese"),
                ],
                addressLine: "Rua dos Duques de Bragança 7, Chiado",
                latitude: 38.7107,
                longitude: -9.1413
            ),

            // ── DRINK (4) ──────────────────────────────────────────────────────────────────────

            // 8. Park Bar — reel @saltinmycoffee "Lisbon in 48 hours" @ 1:15
            PlaceDTO(
                id: "place-park-bar",
                name: "Park Bar",
                category: .drink,
                location: PlaceLocation(neighborhood: "Bairro Alto", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon in 48 hours"),
                provenance: PlaceProvenance(
                    sourceHandle: "saltinmycoffee",
                    clipTitle: "Lisbon in 48 hours",
                    timestamp: "1:15",
                    quote: "Rooftop on the Bairro Alto car park — best sunset in Lisbon."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "12 pm – 2 am"),
                    PlaceFacts(key: "Price", value: "€€"),
                    PlaceFacts(key: "Cuisine", value: "Cocktail Bar · Rooftop"),
                ],
                addressLine: "Calçada do Combro 58, Bairro Alto",
                latitude: 38.7109,
                longitude: -9.1435
            ),

            // 9. Bar Trench — search
            PlaceDTO(
                id: "place-bar-trench",
                name: "Bar Trench",
                category: .drink,
                location: PlaceLocation(neighborhood: "Ebisu", cityName: "Tokyo"),
                source: .search,
                facts: [
                    PlaceFacts(key: "Hours", value: "6 pm – 2 am"),
                    PlaceFacts(key: "Price", value: "¥¥¥"),
                    PlaceFacts(key: "Cuisine", value: "Cocktail Bar"),
                ],
                addressLine: "1-5-8 Ebisu-Nishi, Shibuya-ku, Tokyo",
                latitude: 35.6489,
                longitude: 139.7060
            ),

            // 10. Solar dos Presuntos — reel @portofoodie "Porto underrated"
            PlaceDTO(
                id: "place-solar-presuntos",
                name: "Solar dos Presuntos",
                category: .drink,
                location: PlaceLocation(neighborhood: "Baixa", cityName: "Porto"),
                source: .reel(handle: "portofoodie", clipTitle: "Porto underrated"),
                provenance: PlaceProvenance(
                    sourceHandle: "portofoodie",
                    clipTitle: "Porto underrated",
                    timestamp: "2:18",
                    quote: "Old-school Portuguese wine bar — ask for the house bottle."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "5 pm – 12 am", sub: "Closed Tuesdays"),
                    PlaceFacts(key: "Price", value: "€€"),
                    PlaceFacts(key: "Cuisine", value: "Wine Bar · Portuguese"),
                ],
                addressLine: "Rua das Portas de Santo Antão 150, Baixa, Porto",
                latitude: 41.1470,
                longitude: -8.6110
            ),

            // 11. Gen Yamamoto — reel @tokyohidden "Tokyo hidden gems"
            PlaceDTO(
                id: "place-gen-yamamoto",
                name: "Gen Yamamoto",
                category: .drink,
                location: PlaceLocation(neighborhood: "Azabu-Juban", cityName: "Tokyo"),
                source: .reel(handle: "tokyohidden", clipTitle: "Tokyo hidden gems"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyohidden",
                    clipTitle: "Tokyo hidden gems",
                    timestamp: "0:28",
                    quote: "Seasonal cocktails paired like a tasting menu — one sitting, 4 drinks."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "6 pm – 11 pm", sub: "Reservation required"),
                    PlaceFacts(key: "Price", value: "¥¥¥¥"),
                    PlaceFacts(key: "Cuisine", value: "Cocktail Bar · Omakase"),
                ],
                addressLine: "3-17 Azabu-Juban, Minato-ku, Tokyo",
                latitude: 35.6565,
                longitude: 139.7330
            ),

            // ── STAY (5) ───────────────────────────────────────────────────────────────────────

            // 12. Hotel Hokori — screenshot (Maps list)
            PlaceDTO(
                id: "place-hotel-hokori",
                name: "Hotel Hokori",
                category: .stay,
                location: PlaceLocation(neighborhood: "Yanaka", cityName: "Tokyo"),
                source: .screenshot(savedNote: "Maps list · screenshot"),
                provenance: PlaceProvenance(
                    sourceHandle: "mapslist",
                    clipTitle: "Maps list · screenshot",
                    timestamp: "saved Jul 3",
                    quote: nil
                ),
                facts: [
                    PlaceFacts(key: "Price", value: "¥¥¥ / night"),
                    PlaceFacts(key: "Type", value: "Boutique Hotel"),
                    PlaceFacts(key: "Area", value: "Yanaka · quiet"),
                ],
                addressLine: "3-7-2 Yanaka, Taito-ku, Tokyo",
                latitude: 35.7264,
                longitude: 139.7684
            ),

            // 13. Memmo Alfama — reel @lisbonfinds "Fado dinner spots"
            PlaceDTO(
                id: "place-memmo-alfama",
                name: "Memmo Alfama",
                category: .stay,
                location: PlaceLocation(neighborhood: "Alfama", cityName: "Lisbon"),
                source: .reel(handle: "lisbonfinds", clipTitle: "Fado dinner spots"),
                provenance: PlaceProvenance(
                    sourceHandle: "lisbonfinds",
                    clipTitle: "Fado dinner spots",
                    timestamp: "3:02",
                    quote: "Pool overlooking the Tagus — the terrace alone is worth it."
                ),
                facts: [
                    PlaceFacts(key: "Price", value: "€€€ / night"),
                    PlaceFacts(key: "Type", value: "Design Hotel"),
                    PlaceFacts(key: "Area", value: "Alfama · central"),
                ],
                addressLine: "Travessa das Merceeiras 27, Alfama",
                latitude: 38.7132,
                longitude: -9.1267
            ),

            // 14. The Yeatman — reel @portofoodie "Porto underrated"
            PlaceDTO(
                id: "place-yeatman",
                name: "The Yeatman",
                category: .stay,
                location: PlaceLocation(neighborhood: "Vila Nova de Gaia", cityName: "Porto"),
                source: .reel(handle: "portofoodie", clipTitle: "Porto underrated"),
                provenance: PlaceProvenance(
                    sourceHandle: "portofoodie",
                    clipTitle: "Porto underrated",
                    timestamp: "0:45",
                    quote: "Wine-hotel over the Douro. The view at golden hour is extraordinary."
                ),
                facts: [
                    PlaceFacts(key: "Price", value: "€€€€ / night"),
                    PlaceFacts(key: "Type", value: "Wine Hotel · 5★"),
                    PlaceFacts(key: "Area", value: "Gaia · river view"),
                ],
                addressLine: "Rua do Choupelo 345, Vila Nova de Gaia",
                latitude: 41.1399,
                longitude: -8.6168
            ),

            // 15. Bairro Alto Hotel — search
            PlaceDTO(
                id: "place-bairro-alto-hotel",
                name: "Bairro Alto Hotel",
                category: .stay,
                location: PlaceLocation(neighborhood: "Chiado", cityName: "Lisbon"),
                source: .search,
                facts: [
                    PlaceFacts(key: "Price", value: "€€€€ / night"),
                    PlaceFacts(key: "Type", value: "Luxury Boutique"),
                    PlaceFacts(key: "Area", value: "Chiado · central"),
                ],
                addressLine: "Praça Luís de Camões 2, Chiado",
                latitude: 38.7112,
                longitude: -9.1420
            ),

            // 16. Trunk Hotel — reel @tokyo.eats "Tokyo eats you can't miss"
            PlaceDTO(
                id: "place-trunk-hotel",
                name: "Trunk Hotel",
                category: .stay,
                location: PlaceLocation(neighborhood: "Shibuya", cityName: "Tokyo"),
                source: .reel(handle: "tokyo.eats", clipTitle: "Tokyo eats you can't miss"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyo.eats",
                    clipTitle: "Tokyo eats you can't miss",
                    timestamp: "2:44",
                    quote: "The coffee bar alone makes it a destination — great Shibuya location."
                ),
                facts: [
                    PlaceFacts(key: "Price", value: "¥¥¥ / night"),
                    PlaceFacts(key: "Type", value: "Design Hotel"),
                    PlaceFacts(key: "Area", value: "Shibuya · walkable"),
                ],
                addressLine: "5-31 Jingumae, Shibuya-ku, Tokyo",
                latitude: 35.6694,
                longitude: 139.7050
            ),

            // ── DO (6) ─────────────────────────────────────────────────────────────────────────

            // 17. teamLab Planets — reel @tokyo.eats "Tokyo eats you can't miss"
            PlaceDTO(
                id: "place-teamlab-planets",
                name: "teamLab Planets",
                category: .do,
                location: PlaceLocation(neighborhood: "Toyosu", cityName: "Tokyo"),
                source: .reel(handle: "tokyo.eats", clipTitle: "Tokyo eats you can't miss"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyo.eats",
                    clipTitle: "Tokyo eats you can't miss",
                    timestamp: "1:58",
                    quote: "Completely immersive — book timed entry well in advance."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "9 am – 9 pm"),
                    PlaceFacts(key: "Price", value: "¥3,200"),
                    PlaceFacts(key: "Type", value: "Art · Immersive"),
                ],
                addressLine: "6-1-16 Toyosu, Koto-ku, Tokyo",
                latitude: 35.6526,
                longitude: 139.7860
            ),

            // 18. LX Factory — reel @saltinmycoffee "Lisbon market day" (second clip)
            PlaceDTO(
                id: "place-lx-factory",
                name: "LX Factory",
                category: .do,
                location: PlaceLocation(neighborhood: "Alcântara", cityName: "Lisbon"),
                source: .reel(handle: "saltinmycoffee", clipTitle: "Lisbon market day"),
                provenance: PlaceProvenance(
                    sourceHandle: "saltinmycoffee",
                    clipTitle: "Lisbon market day",
                    timestamp: "0:30",
                    quote: "The Sunday market is unmissable — get there by 11 before it gets packed."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "Market Sundays 10 am – 6 pm"),
                    PlaceFacts(key: "Price", value: "Free entry"),
                    PlaceFacts(key: "Type", value: "Market · Creative hub"),
                ],
                addressLine: "Rua Rodrigues de Faria 103, Alcântara",
                latitude: 38.7039,
                longitude: -9.1768
            ),

            // 19. Meiji Jingu — reel @tokyohidden "Tokyo hidden gems"
            PlaceDTO(
                id: "place-meiji-jingu",
                name: "Meiji Jingu",
                category: .do,
                location: PlaceLocation(neighborhood: "Harajuku", cityName: "Tokyo"),
                source: .reel(handle: "tokyohidden", clipTitle: "Tokyo hidden gems"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyohidden",
                    clipTitle: "Tokyo hidden gems",
                    timestamp: "2:05",
                    quote: "Go at sunrise — you'll have the forest walk almost to yourself."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "Sunrise – Sunset"),
                    PlaceFacts(key: "Price", value: "Free"),
                    PlaceFacts(key: "Type", value: "Shrine · Nature"),
                ],
                addressLine: "1-1 Yoyogikamizonocho, Shibuya-ku, Tokyo",
                latitude: 35.6762,
                longitude: 139.6993
            ),

            // 20. Museu Nacional do Azulejo — screenshot (standalone)
            PlaceDTO(
                id: "place-museu-azulejo",
                name: "Museu Nacional do Azulejo",
                category: .do,
                location: PlaceLocation(neighborhood: "Xabregas", cityName: "Lisbon"),
                source: .screenshot(savedNote: nil),
                provenance: PlaceProvenance(
                    sourceHandle: "screenshot",
                    clipTitle: nil,
                    timestamp: "saved Jun 28",
                    quote: nil
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "10 am – 6 pm", sub: "Closed Mondays"),
                    PlaceFacts(key: "Price", value: "€5"),
                    PlaceFacts(key: "Type", value: "Museum"),
                ],
                addressLine: "Rua da Madre de Deus 4, Xabregas",
                latitude: 38.7214,
                longitude: -9.1081
            ),

            // 21. Livraria Lello — reel @portofoodie "Porto underrated"
            PlaceDTO(
                id: "place-livraria-lello",
                name: "Livraria Lello",
                category: .do,
                location: PlaceLocation(neighborhood: "Cedofeita", cityName: "Porto"),
                source: .reel(handle: "portofoodie", clipTitle: "Porto underrated"),
                provenance: PlaceProvenance(
                    sourceHandle: "portofoodie",
                    clipTitle: "Porto underrated",
                    timestamp: "1:22",
                    quote: "Most beautiful bookshop in the world — arrive early or buy a timed ticket."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "10 am – 7:30 pm"),
                    PlaceFacts(key: "Price", value: "€8 (redeemable)"),
                    PlaceFacts(key: "Type", value: "Bookshop · Heritage"),
                ],
                addressLine: "Rua das Carmelitas 144, Cedofeita, Porto",
                latitude: 41.1473,
                longitude: -8.6154
            ),

            // 22. Sensoji Temple — reel @tokyo.eats "Tokyo eats you can't miss"
            PlaceDTO(
                id: "place-sensoji",
                name: "Sensoji Temple",
                category: .do,
                location: PlaceLocation(neighborhood: "Asakusa", cityName: "Tokyo"),
                source: .reel(handle: "tokyo.eats", clipTitle: "Tokyo eats you can't miss"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyo.eats",
                    clipTitle: "Tokyo eats you can't miss",
                    timestamp: "3:15",
                    quote: "Walk Nakamise-dori at dusk when the lanterns come on."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "Open 24 hrs", sub: "Main hall 6 am – 5 pm"),
                    PlaceFacts(key: "Price", value: "Free"),
                    PlaceFacts(key: "Type", value: "Temple · Cultural"),
                ],
                addressLine: "2-3-1 Asakusa, Taito-ku, Tokyo",
                latitude: 35.7148,
                longitude: 139.7967
            ),

            // ── SHOP (2) ───────────────────────────────────────────────────────────────────────

            // 23. Embaixada — reel @lisbonfinds "Fado dinner spots"
            PlaceDTO(
                id: "place-embaixada",
                name: "Embaixada",
                category: .shop,
                location: PlaceLocation(neighborhood: "Príncipe Real", cityName: "Lisbon"),
                source: .reel(handle: "lisbonfinds", clipTitle: "Fado dinner spots"),
                provenance: PlaceProvenance(
                    sourceHandle: "lisbonfinds",
                    clipTitle: "Fado dinner spots",
                    timestamp: "1:48",
                    quote: "Arabic palace turned Portuguese design concept store — the staircase alone."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "12 pm – 8 pm", sub: "Closed Mondays"),
                    PlaceFacts(key: "Price", value: "€€–€€€"),
                    PlaceFacts(key: "Type", value: "Concept Store"),
                ],
                addressLine: "Praça do Príncipe Real 26, Príncipe Real",
                latitude: 38.7173,
                longitude: -9.1501
            ),

            // 24. Dover Street Market Ginza — reel @tokyohidden "Tokyo hidden gems"
            PlaceDTO(
                id: "place-dover-street-ginza",
                name: "Dover Street Market Ginza",
                category: .shop,
                location: PlaceLocation(neighborhood: "Ginza", cityName: "Tokyo"),
                source: .reel(handle: "tokyohidden", clipTitle: "Tokyo hidden gems"),
                provenance: PlaceProvenance(
                    sourceHandle: "tokyohidden",
                    clipTitle: "Tokyo hidden gems",
                    timestamp: "2:50",
                    quote: "The most interesting retail space in the world, floor by floor."
                ),
                facts: [
                    PlaceFacts(key: "Hours", value: "11 am – 8 pm"),
                    PlaceFacts(key: "Price", value: "¥¥¥–¥¥¥¥"),
                    PlaceFacts(key: "Type", value: "Concept Store · Fashion"),
                ],
                addressLine: "6-9-5 Ginza, Chuo-ku, Tokyo",
                latitude: 35.6696,
                longitude: 139.7640
            ),
        ]
    }
    // swiftlint:enable function_body_length
}
