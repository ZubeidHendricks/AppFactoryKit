import XCTest
@testable import AppFactoryKit

final class AppFactoryKitTests: XCTestCase {

    func testPricePerWeekForYearly() {
        let yearly = SubscriptionProduct(
            id: "y", displayTitle: "Yearly", localizedPrice: "$52.00",
            priceValue: 52, currencyCode: "USD", period: .year)
        // 52 / 52 weeks ≈ 1.00 / week. Formatting is locale-dependent (currency symbol,
        // decimal separator), so assert on the numeric content rather than an exact glyph.
        let perWeek = yearly.pricePerWeekText
        XCTAssertNotNil(perWeek)
        XCTAssertTrue(perWeek?.contains("1") == true, "got \(perWeek ?? "nil")")
    }

    func testLifetimeHasNoPerWeekPrice() {
        let lifetime = SubscriptionProduct(
            id: "l", displayTitle: "Lifetime", localizedPrice: "$99.99",
            priceValue: 99.99, currencyCode: "USD", period: .lifetime)
        XCTAssertNil(lifetime.pricePerWeekText)
    }

    func testFreeTrialFlag() {
        let p = SubscriptionProduct(
            id: "y", displayTitle: "Yearly", localizedPrice: "$29.99",
            priceValue: 29.99, currencyCode: "USD", period: .year,
            introOffer: IntroOffer(kind: .freeTrial, periodDays: 3))
        XCTAssertTrue(p.hasFreeTrial)
    }

    func testRemoteConfigOverridesPaywall() {
        let base = PaywallConfiguration(
            headline: "Original", subheadline: "sub",
            benefits: [], productIDs: ["a"], ctaTitle: "Go")
        let remote = StaticRemoteConfig([
            "paywall_headline": "Overridden",
            "paywall_dismissable": "false",
            "paywall_dismiss_delay": "5",
        ])
        let resolved = base.resolved(with: remote)
        XCTAssertEqual(resolved.headline, "Overridden")
        XCTAssertFalse(resolved.isDismissable)
        XCTAssertEqual(resolved.dismissButtonDelay, 5)
        XCTAssertEqual(resolved.ctaTitle, "Go") // untouched
    }

    func testMockPurchaseFlow() async {
        let provider = MockPurchaseProvider()
        let entitledBefore = await provider.isSubscribed
        XCTAssertFalse(entitledBefore)
        let products = try? await provider.fetchProducts(ids: [])
        XCTAssertEqual(products?.count, 2)
        let result = try? await provider.purchase(products![0])
        XCTAssertEqual(result, .success)
        let entitledAfter = await provider.isSubscribed
        XCTAssertTrue(entitledAfter)
    }

    func testAnalyticsHubFansOut() {
        final class Capture: AnalyticsSink, @unchecked Sendable {
            var names: [String] = []
            func record(_ event: AnalyticsEvent) { names.append(event.name) }
        }
        let sink = Capture()
        let hub = AnalyticsHub(sinks: [sink])
        hub.track(.appOpen)
        hub.track(.paywallView(placement: "post_onboarding"))
        XCTAssertEqual(sink.names, ["app_open", "paywall_view"])
    }
}
