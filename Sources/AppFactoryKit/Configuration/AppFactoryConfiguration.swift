import SwiftUI

/// The full per-app description. Building a new app in the portfolio = filling this in
/// (plus the one feature view). Everything that earns money is inherited from the kit.
public struct AppFactoryConfiguration {
    public var appName: String
    public var purchaseProvider: PurchaseProvider
    public var onboarding: OnboardingConfiguration
    public var paywall: PaywallConfiguration
    public var analyticsSinks: [AnalyticsSink]
    public var remoteConfig: RemoteConfigProviding

    public init(
        appName: String,
        purchaseProvider: PurchaseProvider,
        onboarding: OnboardingConfiguration,
        paywall: PaywallConfiguration,
        analyticsSinks: [AnalyticsSink] = [ConsoleAnalyticsSink()],
        remoteConfig: RemoteConfigProviding = StaticRemoteConfig()
    ) {
        self.appName = appName
        self.purchaseProvider = purchaseProvider
        self.onboarding = onboarding
        self.paywall = paywall
        self.analyticsSinks = analyticsSinks
        self.remoteConfig = remoteConfig
    }
}
