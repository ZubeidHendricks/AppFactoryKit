import Foundation

/// A single funnel event, backend-agnostic. Map these into Mixpanel / Amplitude / RevenueCat etc.
public struct AnalyticsEvent: Sendable {
    public let name: String
    public let properties: [String: String]

    public init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }
}

/// The full conversion funnel for a utility app. This is the instrument panel that tells you,
/// across a 100-app portfolio, exactly where each app leaks and which ones to feed traffic.
public enum FunnelEvent {
    case appOpen
    case onboardingStart
    case onboardingSlide(index: Int)
    case onboardingComplete
    case paywallView(placement: String)
    case paywallDismiss(placement: String, secondsShown: Int)
    case paywallProductsFailed(reason: String)
    case planSelected(productID: String, placement: String)
    case purchaseStarted(productID: String, placement: String)
    case purchaseCompleted(productID: String, placement: String, freeTrial: Bool)
    case purchaseCancelled(productID: String, placement: String)
    case purchasePending(productID: String, placement: String)
    case purchaseFailed(productID: String, reason: String)
    case restoreStarted
    case restoreCompleted(entitled: Bool)
    case restoreFailed(reason: String)
    case premiumFeatureBlocked(feature: String)
    case premiumFeatureUsed(feature: String)

    public var event: AnalyticsEvent {
        switch self {
        case .appOpen: return .init(name: "app_open")
        case .onboardingStart: return .init(name: "onboarding_start")
        case .onboardingSlide(let i): return .init(name: "onboarding_slide", properties: ["index": "\(i)"])
        case .onboardingComplete: return .init(name: "onboarding_complete")
        case .paywallView(let p): return .init(name: "paywall_view", properties: ["placement": p])
        case .paywallDismiss(let p, let s):
            return .init(name: "paywall_dismiss", properties: ["placement": p, "seconds_shown": "\(s)"])
        case .paywallProductsFailed(let r): return .init(name: "paywall_products_failed", properties: ["reason": r])
        case .planSelected(let id, let p):
            return .init(name: "plan_selected", properties: ["product_id": id, "placement": p])
        case .purchaseStarted(let id, let p):
            return .init(name: "purchase_started", properties: ["product_id": id, "placement": p])
        case .purchaseCompleted(let id, let p, let trial):
            return .init(name: "purchase_completed",
                         properties: ["product_id": id, "placement": p, "free_trial": "\(trial)"])
        case .purchaseCancelled(let id, let p):
            return .init(name: "purchase_cancelled", properties: ["product_id": id, "placement": p])
        case .purchasePending(let id, let p):
            return .init(name: "purchase_pending", properties: ["product_id": id, "placement": p])
        case .purchaseFailed(let id, let r):
            return .init(name: "purchase_failed", properties: ["product_id": id, "reason": r])
        case .restoreStarted: return .init(name: "restore_started")
        case .restoreCompleted(let e): return .init(name: "restore_completed", properties: ["entitled": "\(e)"])
        case .restoreFailed(let r): return .init(name: "restore_failed", properties: ["reason": r])
        case .premiumFeatureBlocked(let f): return .init(name: "premium_feature_blocked", properties: ["feature": f])
        case .premiumFeatureUsed(let f): return .init(name: "premium_feature_used", properties: ["feature": f])
        }
    }
}

/// Implement once per analytics destination.
public protocol AnalyticsSink: Sendable {
    func record(_ event: AnalyticsEvent)
}

/// Fans a single event out to every configured sink. Thread-safe; safe to call from any actor.
public final class AnalyticsHub: @unchecked Sendable {
    private let sinks: [AnalyticsSink]
    public init(sinks: [AnalyticsSink]) { self.sinks = sinks }

    public func track(_ funnel: FunnelEvent) {
        let event = funnel.event
        for sink in sinks { sink.record(event) }
    }
}

/// Default sink that prints the funnel to the console — useful before wiring a real backend.
public struct ConsoleAnalyticsSink: AnalyticsSink {
    public init() {}
    public func record(_ event: AnalyticsEvent) {
        let props = event.properties.isEmpty ? "" : " " + event.properties.map { "\($0)=\($1)" }.joined(separator: " ")
        print("📊 \(event.name)\(props)")
    }
}
