import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    enum Tier { case free, pro, lifetimeBYO }

    @Published var tier: Tier = .free
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    static let monthlyID = "booply.pro.monthly"
    static let yearlyID = "booply.pro.yearly"
    static let lifetimeID = "booply.lifetime.byo"
    private let allIDs = [monthlyID, yearlyID, lifetimeID]

    private var updates: Task<Void, Never>?
    private var started = false

    var isPro: Bool { tier != .free }

    private init() {}

    func warmUp() {
        guard !started else { return }
        started = true
        updates = listenForTransactions()
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        do {
            products = try await Product.products(for: allIDs)
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        var newTier = Tier.free
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                switch transaction.productID {
                case Self.monthlyID, Self.yearlyID: newTier = .pro
                case Self.lifetimeID: newTier = .lifetimeBYO
                default: break
                }
            }
        }
        tier = newTier
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.refresh()
                    }
                }
            }
        }
    }

    nonisolated deinit {
        updates?.cancel()
    }
}
