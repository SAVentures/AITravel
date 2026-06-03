// OnboardingRoute.swift — the route value for the immersive onboarding flow (plan W4-00).
//
// A `Hashable` value type, one per file (`06-screens.md §5`). It carries NO payload: the draft the
// flow accumulates lives on `AppStore.onboarding`, so the route only names the destination. The flow
// is presented as a `.fullScreenCover` takeover from `RootView` (driven by `store.onboarding != nil`,
// plan W3-03), not pushed onto a tab path — so this route exists for catalog wiring / future deep
// linking, with the cover presentation owning the actual takeover (`06-screens.md §2.5`).
import Foundation

/// The route for the onboarding takeover. Payload-free — the active `TripDraftModel` lives on the store.
struct OnboardingRoute: Hashable {}
