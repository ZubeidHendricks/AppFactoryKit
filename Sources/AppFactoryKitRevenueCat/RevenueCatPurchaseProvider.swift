import Foundation
import AppFactoryKit
import RevenueCat

/// Production `PurchaseProvider` backed by RevenueCat. This is the only place the Purchases SDK
/// is touched — swap it for StoreKit 2 by writing one more provider, nothing else changes.
///
/// Setup (once per app):
///   1. Add your RevenueCat public SDK key.
///   2. Create an entitlement (default id "premium") in the RevenueCat dashboard.
///   3. Map your App Store Connect products into an offering.
public final class RevenueCatPurchaseProvider: PurchaseProvider, @unchecked Sendable {
    private let entitlementID: String

    /// - Parameters:
    ///   - apiKey: RevenueCat public SDK key (appl_...).
    ///   - appUserID: optional stable user id; nil lets RevenueCat manage an anonymous id.
    ///   - entitlementID: the entitlement that represents "premium".
    public init(apiKey: String, appUserID: String? = nil, entitlementID: String = "premium") {
        self.entitlementID = entitlementID
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
    }

    public var isSubscribed: Bool {
        get async {
            do {
                let info = try await Purchases.shared.customerInfo()
                return info.entitlements[entitlementID]?.isActive == true
            } catch {
                return false
            }
        }
    }

    public func fetchProducts(ids: [String]) async throws -> [SubscriptionProduct] {
        let offerings = try await Purchases.shared.offerings()
        // Prefer the configured current offering; fall back to any offering containing the ids.
        let packages = offerings.current?.availablePackages ?? offerings.all.values.flatMap(\.availablePackages)
        let mapped = packages.map { Self.map($0.storeProduct) }
        if ids.isEmpty { return mapped }
        let wanted = Set(ids)
        let filtered = mapped.filter { wanted.contains($0.id) }
        return filtered.isEmpty ? mapped : filtered
    }

    public func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        let offerings = try await Purchases.shared.offerings()
        let packages = offerings.current?.availablePackages ?? offerings.all.values.flatMap(\.availablePackages)
        guard let package = packages.first(where: { $0.storeProduct.productIdentifier == product.id }) else {
            throw PurchaseError.productNotFound(product.id)
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { return .cancelled }
        return result.customerInfo.entitlements[entitlementID]?.isActive == true ? .success : .pending
    }

    public func restorePurchases() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements[entitlementID]?.isActive == true
    }

    // MARK: - Mapping

    private static func map(_ p: StoreProduct) -> SubscriptionProduct {
        SubscriptionProduct(
            id: p.productIdentifier,
            displayTitle: p.localizedTitle,
            localizedPrice: p.localizedPriceString,
            priceValue: p.price,
            currencyCode: p.currencyCode ?? "USD",
            period: mapPeriod(p.subscriptionPeriod),
            introOffer: mapIntro(p.introductoryDiscount)
        )
    }

    private static func mapPeriod(_ period: RevenueCat.SubscriptionPeriod?) -> AppFactoryKit.SubscriptionPeriod {
        guard let period else { return .lifetime }
        switch period.unit {
        case .day, .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .month
        }
    }

    private static func mapIntro(_ discount: StoreProductDiscount?) -> IntroOffer? {
        guard let discount else { return nil }
        let days = approxDays(discount.subscriptionPeriod)
        switch discount.paymentMode {
        case .freeTrial:
            return IntroOffer(kind: .freeTrial, periodDays: days)
        case .payAsYouGo:
            return IntroOffer(kind: .payAsYouGo, periodDays: days, priceText: discount.localizedPriceString)
        case .payUpFront:
            return IntroOffer(kind: .payUpFront, periodDays: days, priceText: discount.localizedPriceString)
        @unknown default:
            return nil
        }
    }

    private static func approxDays(_ period: RevenueCat.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return period.value
        }
    }
}
