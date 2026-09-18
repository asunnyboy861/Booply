import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: BabyProfile

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var purchase: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        CockpitView(profile: profile)
                    } label: {
                        Label("Parent Cockpit", systemImage: "slider.horizontal.3")
                    }
                    NavigationLink {
                        MilestoneAlbumView()
                    } label: {
                        Label("Milestone Album", systemImage: "star.circle")
                    }
                } header: {
                    Text("Play & Growth")
                }

                Section("Booply Pro") {
                    tierRow
                    if !purchase.isPro {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            Label("Upgrade to Pro", systemImage: "crown.fill")
                                .foregroundStyle(Theme.sageDeep)
                        }
                    } else {
                        Button {
                            Task { await ManageSubscriptionHelper.showManageSubscriptions() }
                        } label: {
                            Label("Manage Subscription", systemImage: "creditcard")
                        }
                        .accessibilityHint("Opens the system subscription manager")
                    }
                    Button {
                        Task { await purchase.restorePurchases() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    NavigationLink {
                        BYOKeyView()
                    } label: {
                        Label("AI Configuration", systemImage: "key.fill")
                    }
                } footer: {
                    Text("Apple Intelligence writes receipt lines on device when available. Add your own key to power photo tagging and the weekly report.")
                }

                Section {
                    NavigationLink {
                        GuidedAccessHelpView()
                    } label: {
                        Label("Guided Access Help", systemImage: "lock.shield")
                    }
                } header: {
                    Text("Safety")
                } footer: {
                    Text("Booply has a built-in child lock — no Guided Access needed. The help page is here for parents who want a second layer.")
                }

                Section {
                    Link(destination: URL(string: "https://asunnyboy861.github.io/Booply/privacy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://asunnyboy861.github.io/Booply/terms.html")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "https://asunnyboy861.github.io/Booply/support.html")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                    NavigationLink {
                        ContactSupportView()
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }
                } header: {
                    Text("Legal & Help")
                }

                Section {
                    HStack {
                        Spacer()
                        Label("Zero data collected", systemImage: "checkmark.shield.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.sageDeep)
                        Spacer()
                    }
                    Text(appVersion)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var tierRow: some View {
        HStack {
            Label("Current plan", systemImage: "person.crop.circle")
            Spacer()
            switch purchase.tier {
            case .free: Text("Free").foregroundStyle(.secondary)
            case .pro: Text("Pro").foregroundStyle(Theme.sageDeep).bold()
            case .lifetimeBYO: Text("BYO Lifetime").foregroundStyle(Theme.sageDeep).bold()
            }
        }
    }
}

struct GuidedAccessHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.sageDeep)
                Text("System Guided Access (optional)")
                    .font(.title2.bold())
                step("1", "Open the Settings app, then Accessibility → Guided Access, and turn it on.")
                step("2", "Set a passcode you'll remember.")
                step("3", "Open Booply, triple-click the side button, then tap Start.")
                step("4", "To leave, triple-click the side button again and enter your passcode.")
                Text("Booply already includes a built-in child lock: during play, press and hold the top-right corner for 1.5 seconds, then answer two math questions. Guided Access is only for parents who want an extra layer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Guided Access")
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Theme.sage, in: Circle())
            Text(text)
        }
    }
}
