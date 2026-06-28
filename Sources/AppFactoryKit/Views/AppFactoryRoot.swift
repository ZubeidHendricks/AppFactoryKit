import SwiftUI

/// Wraps your app content with the full funnel: onboarding (first launch) → content,
/// with the paywall presented as a sheet on top whenever requested. Use one line at the root.
///
///     WindowGroup {
///         MyContentView().appFactoryRoot(factory)
///     }
public struct AppFactoryRoot<Content: View>: View {
    @ObservedObject private var factory: AppFactory
    private let content: () -> Content

    public init(_ factory: AppFactory, @ViewBuilder content: @escaping () -> Content) {
        self.factory = factory
        self.content = content
    }

    public var body: some View {
        Group {
            if factory.needsOnboarding {
                OnboardingFlowView()
            } else {
                content()
            }
        }
        .environmentObject(factory)
        .task { await factory.start() }
        .sheet(isPresented: paywallBinding) {
            if let placement = factory.presentedPaywallPlacement {
                HardPaywallView(placement: placement)
                    .environmentObject(factory)
            }
        }
    }

    private var paywallBinding: Binding<Bool> {
        Binding(
            get: { factory.presentedPaywallPlacement != nil },
            set: { if !$0 { factory.dismissPaywall() } }
        )
    }
}

public extension View {
    /// Attach the onboarding → content → paywall funnel around this view.
    func appFactoryRoot(_ factory: AppFactory) -> some View {
        AppFactoryRoot(factory) { self }
    }

    /// Gate a tap behind premium: runs `action` if subscribed, else opens the paywall.
    /// Tag with a `feature` name so the funnel shows which feature drives the most upgrades.
    func onPremiumTap(_ factory: AppFactory, feature: String, perform action: @escaping () -> Void) -> some View {
        onTapGesture { factory.requirePremium(feature: feature, perform: action) }
    }
}
