// Reference wiring for ONE portfolio app: a QR scanner, modeled on the high-converting
// QR/scanner paywalls in ~/paywall-research. This is the entire "per-app" surface area —
// everything that earns money (onboarding, paywall, subscriptions, funnel) is inherited.
//
// To ship app N: copy this file, swap (1) the AppFactoryConfiguration, (2) the feature view,
// (3) the App Store name/keywords/icon. That's it.
//
// This file is illustrative (not built by the package). Drop it into a real iOS app target
// that depends on AppFactoryKit + AppFactoryKitRevenueCat.

import SwiftUI
import AppFactoryKit
import AppFactoryKitRevenueCat

// MARK: - 1. Describe the app (the only thing that changes between portfolio apps)

@MainActor
enum QRScannerFactory {
    static func make() -> AppFactory {
        let provider = RevenueCatPurchaseProvider(
            apiKey: "appl_YOUR_REVENUECAT_KEY",  // per-app key
            entitlementID: "premium"
        )

        let config = AppFactoryConfiguration(
            appName: "QR Scanner Pro",
            purchaseProvider: provider,
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "qrcode.viewfinder",
                          title: "Scan Anything",
                          message: "Point your camera at any QR code or barcode to open it instantly."),
                    .init(systemImage: "bolt.fill",
                          title: "Lightning Fast",
                          message: "Detects and opens links, Wi-Fi, contacts and more in a tap."),
                ],
                presentsPaywallOnFinish: true,
                accent: .blue
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock QR Scanner Pro",
                subheadline: "Unlimited scans, history, and batch mode.",
                benefits: [
                    .init(systemImage: "infinity", title: "Unlimited scans", subtitle: "No daily limits"),
                    .init(systemImage: "clock.arrow.circlepath", title: "Full scan history"),
                    .init(systemImage: "square.stack.3d.up", title: "Batch scanning"),
                    .init(systemImage: "nosign", title: "No ads, ever"),
                ],
                productIDs: ["qr_pro_yearly", "qr_pro_weekly"],
                highlightedProductID: "qr_pro_yearly",
                ctaTitle: "Continue",
                dismissButtonDelay: 4,        // hard paywall: X appears after 4s
                isDismissable: true,
                termsURL: URL(string: "https://example.com/terms"),
                privacyURL: URL(string: "https://example.com/privacy"),
                style: PaywallStyle(accent: .blue, heroSystemImage: "qrcode.viewfinder")
            )
            // analyticsSinks: [MixpanelSink(...), RevenueCatSink(...)]  // wire real backends here
            // remoteConfig: FirebaseRemoteConfig()                     // A/B paywall without resubmit
        )
        return AppFactory(config)
    }
}

// MARK: - 2. The app entry point (boilerplate, identical across the portfolio)

@main
struct QRScannerAppMain: App {
    @StateObject private var factory = QRScannerFactory.make()

    var body: some Scene {
        WindowGroup {
            ScannerHomeView()
                .appFactoryRoot(factory)   // onboarding → content → paywall, one line
                .tint(.blue)
        }
    }
}

// MARK: - 3. The actual feature (the only genuinely app-specific code — keeps you clear of 4.3)

struct ScannerHomeView: View {
    @EnvironmentObject private var factory: AppFactory

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 120))
                    .foregroundStyle(.blue)
                Text("Tap to scan").foregroundStyle(.secondary)

                // Free action — always allowed.
                Button("Scan a code") { /* present camera */ }
                    .buttonStyle(.borderedProminent)

                // Premium action — gated. Runs if subscribed, else opens the paywall,
                // tagged "batch_scan" so the funnel shows this feature's upgrade rate.
                Button("Batch scan (Pro)") {
                    factory.requirePremium(feature: "batch_scan") {
                        // run batch scanning
                    }
                }
                .buttonStyle(.bordered)

                // Manual upsell entry point.
                if !factory.subscriptions.isSubscribed {
                    Button("Upgrade to Pro") { factory.presentPaywall(placement: "home_upsell") }
                        .font(.footnote)
                }
            }
            .navigationTitle("QR Scanner")
        }
    }
}
