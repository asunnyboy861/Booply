import SwiftUI
import SwiftData

struct CockpitView: View {
    let profile: BabyProfile

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var purchase: PurchaseManager
    @Query private var sessions: [PlaySession]
    @State private var weeklyInsight: String?

    private let durations = [5, 10, 15, 20, 30]
    private let worldNames = Dictionary(uniqueKeysWithValues: WorldCatalog.all.map { ($0.id, $0.displayName) })

    var body: some View {
        Form {
            Section {
                Picker("Session length", selection: $settings.sessionMinutes) {
                    ForEach(durations, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                Toggle("Time window", isOn: $settings.windowEnabled)
                if settings.windowEnabled {
                    Picker("Opens", selection: $settings.windowStartHour) {
                        ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) }
                    }
                    Picker("Closes", selection: $settings.windowEndHour) {
                        ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)).tag($0) }
                    }
                }
            } header: {
                Text("Session")
            } footer: {
                Text("Outside the window, the Start button stays locked.")
            }

            Section("Sound & Touch") {
                Slider(value: $settings.volume, in: 0.1...1.0) {
                    Text("Volume")
                }
                .accessibilityLabel("Volume")
                Toggle("Soft haptics", isOn: $settings.hapticsOn)
                Toggle("Gentle chime at wind-down", isOn: $settings.windDownChime)
            }

            Section {
                ForEach(WorldCatalog.all) { world in
                    Toggle(world.displayName, isOn: Binding(
                        get: { !settings.disabledWorlds.contains(world.id) },
                        set: { on in
                            if on {
                                settings.disabledWorlds.remove(world.id)
                            } else {
                                settings.disabledWorlds.insert(world.id)
                            }
                        }
                    ))
                }
            } header: {
                Text("Worlds")
            } footer: {
                Text(purchase.isPro ? "All worlds included with Pro." : "Free play uses 2 worlds per day. Pro unlocks every world.")
            }

            Section {
                Label("Baby stage: \(Stage.current(birthdate: profile.birthdate).displayName)", systemImage: "figure.and.child.holdinghands")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !purchase.isPro {
                    Text("Unlock weekly reports with Pro")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    weeklyCard
                }
            } header: {
                Text("This Week")
            }

            Section {
                Toggle("iCloud Sync (optional)", isOn: $settings.iCloudSyncPreferred)
                if settings.iCloudSyncPreferred && FileManager.default.ubiquityIdentityToken == nil {
                    Text("iCloud isn't available on this device or account yet. The app keeps working with local storage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("Data lives on this device. Pro can sync across your devices through your own private iCloud.")
            }
        }
        .navigationTitle("Parent Cockpit")
        .task { await loadWeekly() }
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if weeklyInsight == nil {
                ProgressView()
            } else {
                Label("Weekly insight", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.sageDeep)
                Text(weeklyInsight ?? "")
                    .font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }

    private var recentSessions: [PlaySession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.startedAt >= weekAgo }
    }

    private func loadWeekly() async {
        guard purchase.isPro else { return }
        let summary = WeeklyReportService.buildSummary(sessions: recentSessions, worldNames: worldNames)
        weeklyInsight = await WeeklyReportService.insight(summary: summary, babyName: profile.companionName)
    }
}
