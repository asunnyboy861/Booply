import SwiftUI
import SwiftData
import StoreKit

struct HomeView: View {
    let profile: BabyProfile

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var purchase: PurchaseManager
    @Query private var sessions: [PlaySession]

    @State private var showSession = false
    @State private var showGate = false
    @State private var showSettings = false
    @State private var showPricing = false
    @Environment(\.requestReview) private var requestReview

    private var stage: Stage { Stage.current(birthdate: profile.birthdate) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                Spacer()
                startButton
                freeCaption
                Spacer()
            }
            .padding(24)
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGate = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Parent settings")
                }
            }
            .fullScreenCover(isPresented: $showSession) {
                KidSessionView(profile: profile, duration: allowedDuration()) {
                    sessionFinished()
                }
            }
            .fullScreenCover(isPresented: $showPricing) {
                PaywallView(emphasizeFree: true) {
                    showPricing = false
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(profile: profile)
            }
            .sheet(isPresented: $showGate) {
                ParentGateView { showSettings = true }
                    .presentationDetents([.large])
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Booply")
                .font(.largeTitle.bold())
            Text("\(profile.companionName) · \(stage.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var startButton: some View {
        Button {
            SoundBank.configure()
            showSession = true
        } label: {
            Label("Start Quiet Time", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canStart)
        .padding(.horizontal, 12)
        .accessibilityHint("Opens the calm play session")
    }

    private var freeCaption: some View {
        Group {
            if !settings.isWithinWindow() {
                Text("Quiet time opens \(settings.windowText())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !purchase.isPro && freeRemainingSeconds <= 0 {
                Text("Today's free quiet time is used up")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text(purchase.isPro ? "Pro · unlimited quiet time" : "\(Int(freeRemainingSeconds / 60)) free minutes left today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var canStart: Bool {
        settings.isWithinWindow() && allowedDuration() >= 60
    }

    private var freeRemainingSeconds: Double {
        let used = playedToday()
        return max(0, 600 - used)
    }

    private func playedToday() -> Double {
        let calendar = Calendar.current
        return sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.endedAt.timeIntervalSince($1.startedAt) }
    }

    private func allowedDuration() -> TimeInterval {
        let base = Double(settings.sessionMinutes * 60)
        guard !purchase.isPro else { return base }
        return min(base, freeRemainingSeconds)
    }

    private func sessionFinished() {
        settings.receiptCount += 1
        if !settings.pricingShown {
            settings.pricingShown = true
            showPricing = true
        } else if settings.receiptCount >= 3 {
            requestReview()
        }
    }
}
