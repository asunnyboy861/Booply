import SwiftUI
import StoreKit

struct PaywallView: View {
    var emphasizeFree = false
    var onContinueFree: (() -> Void)?

    @EnvironmentObject private var purchase: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.sageDeep)
                    Text("Booply Pro")
                        .font(.largeTitle.bold())
                    Text("Every feature, one honest price. Cancel in two taps, anytime.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    tierCards
                    if let error = purchase.loadError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    restoreButton

                    if emphasizeFree {
                        Button {
                            onContinueFree?()
                            dismiss()
                        } label: {
                            Text("Keep using Free")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                    }

                    legalBlock
                }
                .padding(20)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchase.refresh() }
        }
    }

    private var tierCards: some View {
        VStack(spacing: 14) {
            tierRow(
                title: "Free",
                price: "$0",
                detail: "2 worlds · 10 min/day · full cockpit",
                isHero: false,
                action: nil,
                actionLabel: nil
            )
            tierRow(
                title: "Pro Yearly",
                price: purchase.product(for: PurchaseManager.yearlyID)?.displayPrice ?? "$19.99",
                detail: "per year · 7-day free trial · Family Sharing",
                isHero: true,
                action: { await buy(PurchaseManager.yearlyID) },
                actionLabel: "Start 7-day free trial"
            )
            tierRow(
                title: "Pro Monthly",
                price: purchase.product(for: PurchaseManager.monthlyID)?.displayPrice ?? "$3.99",
                detail: "per month · 7-day free trial",
                isHero: false,
                action: { await buy(PurchaseManager.monthlyID) },
                actionLabel: "Subscribe monthly"
            )
            tierRow(
                title: "BYO Lifetime",
                price: purchase.product(for: PurchaseManager.lifetimeID)?.displayPrice ?? "$14.99",
                detail: "one-time · Pro features with your own Z.ai key",
                isHero: false,
                action: { await buy(PurchaseManager.lifetimeID) },
                actionLabel: "Buy once"
            )
        }
    }

    private func tierRow(title: String, price: String, detail: String, isHero: Bool, action: (() async -> Void)?, actionLabel: String?) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                if isHero {
                    Text("Best value")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.sage, in: Capsule())
                }
                Spacer()
                Text(price)
                    .font(.title3.bold())
            }
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionLabel, let action {
                Button {
                    Task { await action() }
                } label: {
                    Text(actionLabel)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(purchase.isLoading)
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner)
                .stroke(isHero ? Theme.sageDeep : Theme.separator, lineWidth: isHero ? 2 : 1)
        )
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await purchase.restorePurchases() }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var legalBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/Booply/privacy.html")!)
                Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/Booply/terms.html")!)
                Link("Support", destination: URL(string: "https://asunnyboy861.github.io/Booply/support.html")!)
            }
            .font(.caption)
            Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func buy(_ id: String) async {
        guard let product = purchase.product(for: id) else { return }
        _ = await purchase.purchase(product)
    }
}

extension PurchaseManager {
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
}

struct ManageSubscriptionHelper {
    @MainActor
    static func showManageSubscriptions() async {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first else { return }
        try? await AppStore.showManageSubscriptions(in: scene)
    }
}
