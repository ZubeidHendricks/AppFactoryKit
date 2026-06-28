import Foundation

/// In-memory provider for SwiftUI previews, unit tests, and pre-RevenueCat development.
/// Defaults to a realistic weekly + yearly pair modeled on top scanner-app paywalls.
public final class MockPurchaseProvider: PurchaseProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var _entitled: Bool
    private let catalog: [SubscriptionProduct]
    /// Set false to make `purchase` return `.cancelled` (to preview the "user bailed" path).
    public var simulatePurchaseSuccess = true

    public init(entitled: Bool = false, catalog: [SubscriptionProduct]? = nil) {
        self._entitled = entitled
        self.catalog = catalog ?? MockPurchaseProvider.defaultCatalog
    }

    public var isSubscribed: Bool {
        get async { lock.withLock { _entitled } }
    }

    public func fetchProducts(ids: [String]) async throws -> [SubscriptionProduct] {
        try await Task.sleep(nanoseconds: 250_000_000) // mimic store latency
        if ids.isEmpty { return catalog }
        return ids.compactMap { id in catalog.first { $0.id == id } }
    }

    public func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        try await Task.sleep(nanoseconds: 400_000_000)
        guard simulatePurchaseSuccess else { return .cancelled }
        lock.withLock { _entitled = true }
        return .success
    }

    public func restorePurchases() async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return lock.withLock { _entitled }
    }

    public static let defaultCatalog: [SubscriptionProduct] = [
        SubscriptionProduct(
            id: "pro_yearly",
            displayTitle: "Yearly",
            localizedPrice: "$29.99",
            priceValue: 29.99,
            currencyCode: "USD",
            period: .year,
            introOffer: IntroOffer(kind: .freeTrial, periodDays: 3)
        ),
        SubscriptionProduct(
            id: "pro_weekly",
            displayTitle: "Weekly",
            localizedPrice: "$4.99",
            priceValue: 4.99,
            currencyCode: "USD",
            period: .week
        ),
    ]
}
