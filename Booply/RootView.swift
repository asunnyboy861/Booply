import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [BabyProfile]

    var body: some View {
        if let profile = profiles.first {
            HomeView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}
