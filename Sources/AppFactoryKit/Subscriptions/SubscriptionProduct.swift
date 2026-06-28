import Foundation

/// Billing cadence of a subscription product, independent of any store SDK.
public enum SubscriptionPeriod: String, Sendable, Hashable {
    case week, month, year, lifetime

    public var displayName: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    /// Approximate number of weeks in the period, used for "$x.xx / week" math.
    var weeks: Double? {
        switch self {
        case .week: return 1
        case .month: return 52.0 / 12.0
        case .year: return 52
        case .lifetime: return nil
        }
    }
}

/// An introductory offer attached to a product (free trial or discounted intro price).
public struct IntroOffer: Sendable, Hashable {
    public enum Kind: Sendable, Hashable { case freeTrial, payAsYouGo, payUpFront }

    public let kind: Kind
    public let periodDays: Int
    /// Localized price string for the intro phase (nil for a free trial).
    public let priceText: String?

    public init(kind: Kind, periodDays: Int, priceText: String? = nil) {
        self.kind = kind
        self.periodDays = periodDays
        self.priceText = priceText
    }

    public var isFreeTrial: Bool { kind == .freeTrial }
}

/// A purchasable subscription, normalized so the UI never touches a store SDK type.
public struct SubscriptionProduct: Identifiable, Sendable, Hashable {
    /// Store product identifier (App Store Connect product id).
    public let id: String
    public let displayTitle: String
    /// Localized recurring price, e.g. "$29.99".
    public let localizedPrice: String
    /// Raw decimal price for per-week math and sorting.
    public let priceValue: Decimal
    public let currencyCode: String
    public let period: SubscriptionPeriod
    public let introOffer: IntroOffer?

    public init(
        id: String,
        displayTitle: String,
        localizedPrice: String,
        priceValue: Decimal,
        currencyCode: String,
        period: SubscriptionPeriod,
        introOffer: IntroOffer? = nil
    ) {
        self.id = id
        self.displayTitle = displayTitle
        self.localizedPrice = localizedPrice
        self.priceValue = priceValue
        self.currencyCode = currencyCode
        self.period = period
        self.introOffer = introOffer
    }

    public var hasFreeTrial: Bool { introOffer?.isFreeTrial ?? false }

    /// Localized "≈ $x.xx / week" string, the highest-converting price anchor on a paywall.
    public var pricePerWeekText: String? {
        guard let weeks = period.weeks, weeks > 0 else { return nil }
        let perWeek = priceValue / Decimal(weeks)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: perWeek as NSDecimalNumber)
    }
}

/// Outcome of a purchase attempt.
public enum PurchaseResult: Sendable {
    case success
    case cancelled
    case pending
}
