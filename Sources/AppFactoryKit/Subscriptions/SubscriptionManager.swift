import Foundation
import SwiftUI

/// Observable façade over a `PurchaseProvider`. Views bind to this; it never imports a store SDK.
@MainActor
public final class SubscriptionManager: ObservableObject {
    public enum LoadState: Equatable { case idle, loading, loaded, failed(String) }

    @Published public private(set) var isSubscribed: Bool = false
    @Published public private(set) var products: [SubscriptionProduct] = []
    @Published public private(set) var state: LoadState = .idle
    @Published public private(set) var isPurchasing = false

    private let provider: PurchaseProvider
    private let productIDs: [String]
    private let analytics: AnalyticsHub

    public init(provider: PurchaseProvider, productIDs: [String], analytics: AnalyticsHub) {
        self.provider = provider
        self.productIDs = productIDs
        self.analytics = analytics
    }

    /// Pull entitlement + products. Call on launch and on paywall appear.
    public func refresh() async {
        state = .loading
        isSubscribed = await provider.isSubscribed
        do {
            products = try await provider.fetchProducts(ids: productIDs)
            state = .loaded
        } catch {
            state = .failed(String(describing: error))
            analytics.track(.paywallProductsFailed(reason: String(describing: error)))
        }
    }

    /// Returns true if the user ended up entitled (purchase succeeded).
    @discardableResult
    public func purchase(_ product: SubscriptionProduct, placement: String) async -> Bool {
        guard !isPurchasing else { return isSubscribed }
        isPurchasing = true
        defer { isPurchasing = false }
        analytics.track(.purchaseStarted(productID: product.id, placement: placement))
        do {
            let result = try await provider.purchase(product)
            switch result {
            case .success:
                isSubscribed = await provider.isSubscribed
                analytics.track(.purchaseCompleted(
                    productID: product.id, placement: placement, freeTrial: product.hasFreeTrial))
                return isSubscribed
            case .cancelled:
                analytics.track(.purchaseCancelled(productID: product.id, placement: placement))
            case .pending:
                analytics.track(.purchasePending(productID: product.id, placement: placement))
            }
        } catch {
            analytics.track(.purchaseFailed(productID: product.id, reason: String(describing: error)))
        }
        return false
    }

    @discardableResult
    public func restore() async -> Bool {
        analytics.track(.restoreStarted)
        do {
            let entitled = try await provider.restorePurchases()
            isSubscribed = entitled
            analytics.track(.restoreCompleted(entitled: entitled))
            return entitled
        } catch {
            analytics.track(.restoreFailed(reason: String(describing: error)))
            return false
        }
    }
}
