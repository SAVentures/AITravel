/*
 Route value for the onboarding takeover. Payload-free — the accumulated draft lives on
 AppStore.onboarding, so this only names the destination. The flow is presented as a
 .fullScreenCover from RootView (driven by store.onboarding != nil), not pushed onto a tab path,
 so this route exists for catalog wiring / future deep linking.
*/
import Foundation

struct OnboardingRoute: Hashable {}
