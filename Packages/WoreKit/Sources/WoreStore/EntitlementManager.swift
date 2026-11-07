import Foundation
import Observation
import StoreKit
import WoreCore

public enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case pending
    case userCancelled
    case failed(String)
}

/// StoreKit 2 manager for the one-time non-consumable (`com.asvirts.wore.pro`).
@MainActor @Observable
public final class EntitlementManager {
    public private(set) var isPro: Bool
    public private(set) var proProduct: Product?
    public private(set) var isBusy = false
    public private(set) var lastError: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    public init() {
        self.isPro = UserDefaults.wore.bool(forKey: SettingsKey.isProCached)
    }

    /// Price formatted by StoreKit. Falls back to "$7.99" before product metadata loads.
    public var displayPrice: String {
        proProduct?.displayPrice ?? "$7.99"
    }

    /// Call from `.task` after the first frame so cold launch stays on the closet.
    public func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await verification in Transaction.updates {
                    guard let self else { return }
                    if case .verified(let transaction) = verification {
                        if transaction.productID == WoreConfig.proProductID {
                            self.setPro(transaction.revocationDate == nil)
                        }
                        await transaction.finish()
                    }
                }
            }
        }
        await refreshEntitlements()
        await loadProductIfNeeded()
    }

    public func loadProductIfNeeded() async {
        guard proProduct == nil else { return }
        do {
            let products = try await Product.products(for: [WoreConfig.proProductID])
            proProduct = products.first
        } catch {
            // Leave the fallback price in place until StoreKit is reachable.
        }
    }

    public func refreshEntitlements() async {
        var unlocked = false
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification,
               transaction.productID == WoreConfig.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPro(unlocked)
    }

    @discardableResult
    public func purchase() async -> PurchaseOutcome {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        await loadProductIfNeeded()
        guard let product = proProduct else {
            let message = "Wore Pro isn't available from the App Store right now."
            lastError = message
            return .failed(message)
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    setPro(true)
                    await transaction.finish()
                    return .purchased
                case .unverified(_, let error):
                    let message = error.localizedDescription
                    lastError = message
                    return .failed(message)
                }
            case .pending:
                return .pending
            case .userCancelled:
                return .userCancelled
            @unknown default:
                return .userCancelled
            }
        } catch {
            let message = error.localizedDescription
            lastError = message
            return .failed(message)
        }
    }

    @discardableResult
    public func restore() async -> Bool {
        isBusy = true
        lastError = nil
        defer { isBusy = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return isPro
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func setPro(_ unlocked: Bool) {
        let changed = isPro != unlocked
        isPro = unlocked
        UserDefaults.wore.set(unlocked, forKey: SettingsKey.isProCached)
        if changed {
            WidgetSync.reloadAll()
        }
    }
}
