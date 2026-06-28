import SwiftUI

/// Central runtime object. Owns subscription state, analytics, onboarding/paywall presentation.
/// Inject once at the app root via `.environmentObject(AppFactory(...))` or use `.appFactoryRoot`.
@MainActor
public final class AppFactory: ObservableObject {
    public let config: AppFactoryConfiguration
    public let analytics: AnalyticsHub
    public let subscriptions: SubscriptionManager

    /// Resolved paywall config (remote overrides applied). Recomputed on `start()`.
    @Published public private(set) var paywall: PaywallConfiguration

    /// True until the user has finished onboarding once (persisted).
    @Published public var needsOnboarding: Bool
    /// When non-nil, a paywall is presented with this placement tag (for funnel attribution).
    @Published public var presentedPaywallPlacement: String?

    private let defaults: UserDefaults
    private static let onboardingKey = "appfactory.onboarding.complete"

    public init(_ config: AppFactoryConfiguration, defaults: UserDefaults = .standard) {
        self.config = config
        self.defaults = defaults
        let hub = AnalyticsHub(sinks: config.analyticsSinks)
        self.analytics = hub
        self.subscriptions = SubscriptionManager(
            provider: config.purchaseProvider,
            productIDs: config.paywall.productIDs,
            analytics: hub
        )
        self.paywall = config.paywall.resolved(with: config.remoteConfig)
        self.needsOnboarding = !defaults.bool(forKey: Self.onboardingKey)
    }

    public var isSubscribed: Bool { subscriptions.isSubscribed }

    /// Call once when the root view appears.
    public func start() async {
        analytics.track(.appOpen)
        paywall = config.paywall.resolved(with: config.remoteConfig)
        await subscriptions.refresh()
    }

    public func completeOnboarding() {
        defaults.set(true, forKey: Self.onboardingKey)
        needsOnboarding = false
        analytics.track(.onboardingComplete)
        if config.onboarding.presentsPaywallOnFinish && !subscriptions.isSubscribed {
            presentPaywall(placement: "post_onboarding")
        }
    }

    /// Present the paywall from anywhere (feature gate, settings button, etc.).
    public func presentPaywall(placement: String) {
        presentedPaywallPlacement = placement
    }

    public func dismissPaywall() {
        presentedPaywallPlacement = nil
    }

    /// Run `action` if subscribed; otherwise present the paywall tagged with `feature`.
    /// Returns true when the action ran.
    @discardableResult
    public func requirePremium(feature: String, perform action: () -> Void) -> Bool {
        if subscriptions.isSubscribed {
            analytics.track(.premiumFeatureUsed(feature: feature))
            action()
            return true
        }
        analytics.track(.premiumFeatureBlocked(feature: feature))
        presentPaywall(placement: feature)
        return false
    }
}
