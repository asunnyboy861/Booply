import SwiftData
import SwiftUI

@main
struct BooplyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: BabyProfile.self, PlaySession.self, Milestone.self)
        } catch {
            let fallback = try? ModelContainer(
                for: BabyProfile.self, PlaySession.self, Milestone.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            guard let fallback else {
                fatalError("Failed to create ModelContainer: \(error)")
            }
            container = fallback
        }
        PurchaseManager.shared.warmUp()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.sage)
                .modelContainer(container)
                .environmentObject(SettingsStore.shared)
                .environmentObject(PurchaseManager.shared)
        }
    }
}
