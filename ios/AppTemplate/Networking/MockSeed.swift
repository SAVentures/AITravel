import Foundation

/*
 The immutable DTO snapshot MockProvider serves — a Sendable value computed purely by each
 request's mockResponse(from:). Starts empty; each feature adds its top-level entity as a field
 via an extension so parallel scaffolders don't collide on this file.
*/
struct MockSeed: Sendable {

    // nil for the `.empty` scenario → GetOnboardingContextRequest yields a 404.
    var onboardingContext: OnboardingContextDTO?

    // nil for scenarios that don't populate saved places → GetSavedPlacesRequest yields a 404.
    var savedPlaces: SavedPlacesDTO?

    // All fields default so MockSeed() for `.empty` survives features adding fields by extension.
    init(onboardingContext: OnboardingContextDTO? = nil,
         savedPlaces: SavedPlacesDTO? = nil) {
        self.onboardingContext = onboardingContext
        self.savedPlaces = savedPlaces
    }
}
