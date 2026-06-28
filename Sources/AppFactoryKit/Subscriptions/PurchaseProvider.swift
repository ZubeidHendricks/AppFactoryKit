import Foundation

/// The single seam between the factory and any billing backend (RevenueCat, StoreKit 2, a mock).
///
/// Implement this once per backend. The core ships `MockPurchaseProvider`; the
/// `AppFactoryKitRevenueCat` target ships a RevenueCat-backed implementation.
public protocol PurchaseProvider: AnyObject, Sendable {
    /// Whether the user currently holds the premium entitlement.
    var isSubscribed: Bool { get async }

    /// Fetch the configured offering's products, ordered for display.
    func fetchProducts(ids: [String]) async throws -> [SubscriptionProduct]

    /// Attempt to purchase a product.
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult

    /// Restore prior purchases. Returns whether the user is entitled afterwards.
    func restorePurchases() async throws -> Bool
}

public enum PurchaseError: Error, Sendable {
    case productNotFound(String)
    case notConfigured
    case underlying(String)
}
