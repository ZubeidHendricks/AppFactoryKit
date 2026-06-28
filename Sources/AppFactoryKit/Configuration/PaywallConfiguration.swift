import SwiftUI

/// One benefit row on the paywall. Keep to 3–4 concrete, outcome-focused lines.
public struct PaywallBenefit: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let systemImage: String
    public let title: String
    public let subtitle: String?

    public init(systemImage: String, title: String, subtitle: String? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
    }
}

/// Visual theming for the paywall. Per-app brand color is usually the only thing you change.
public struct PaywallStyle: Sendable {
    public var accent: Color
    public var heroSystemImage: String
    public var cornerRadius: CGFloat

    public init(accent: Color = .accentColor, heroSystemImage: String = "sparkles", cornerRadius: CGFloat = 18) {
        self.accent = accent
        self.heroSystemImage = heroSystemImage
        self.cornerRadius = cornerRadius
    }
}

/// Everything that draws and tunes a hard paywall. Every field is remote-config overridable
/// (see `resolved(with:)`) so you can A/B copy and pricing emphasis without resubmitting.
public struct PaywallConfiguration: Sendable {
    public var headline: String
    public var subheadline: String
    public var benefits: [PaywallBenefit]
    /// Product ids to show, in display order. First is highlighted unless `highlightedProductID` set.
    public var productIDs: [String]
    public var highlightedProductID: String?
    public var ctaTitle: String
    /// "Hard" paywall lever: seconds before the dismiss (X) button appears. 0 = immediate.
    public var dismissButtonDelay: TimeInterval
    /// If false, the paywall cannot be dismissed at all (gate the whole app behind it).
    public var isDismissable: Bool
    public var termsURL: URL?
    public var privacyURL: URL?
    public var style: PaywallStyle

    public init(
        headline: String,
        subheadline: String,
        benefits: [PaywallBenefit],
        productIDs: [String],
        highlightedProductID: String? = nil,
        ctaTitle: String = "Continue",
        dismissButtonDelay: TimeInterval = 3,
        isDismissable: Bool = true,
        termsURL: URL? = nil,
        privacyURL: URL? = nil,
        style: PaywallStyle = PaywallStyle()
    ) {
        self.headline = headline
        self.subheadline = subheadline
        self.benefits = benefits
        self.productIDs = productIDs
        self.highlightedProductID = highlightedProductID
        self.ctaTitle = ctaTitle
        self.dismissButtonDelay = dismissButtonDelay
        self.isDismissable = isDismissable
        self.termsURL = termsURL
        self.privacyURL = privacyURL
        self.style = style
    }

    /// Apply remote-config overrides. Keys: paywall_headline, paywall_subheadline,
    /// paywall_cta, paywall_dismiss_delay, paywall_dismissable, paywall_highlight_product.
    public func resolved(with config: RemoteConfigProviding) -> PaywallConfiguration {
        var copy = self
        copy.headline = config.string("paywall_headline", default: headline)
        copy.subheadline = config.string("paywall_subheadline", default: subheadline)
        copy.ctaTitle = config.string("paywall_cta", default: ctaTitle)
        copy.dismissButtonDelay = TimeInterval(config.int("paywall_dismiss_delay", default: Int(dismissButtonDelay)))
        copy.isDismissable = config.bool("paywall_dismissable", default: isDismissable)
        if let hi = config.string("paywall_highlight_product") { copy.highlightedProductID = hi }
        return copy
    }
}
