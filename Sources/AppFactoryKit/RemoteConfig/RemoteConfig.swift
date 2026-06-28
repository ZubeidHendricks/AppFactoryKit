import Foundation

/// Read-only key/value source for runtime overrides. Back it with RevenueCat metadata,
/// Firebase Remote Config, or your own endpoint so you can retune paywalls — price emphasis,
/// headline, trial on/off — across the whole portfolio without an App Store resubmission.
public protocol RemoteConfigProviding: Sendable {
    func string(_ key: String) -> String?
    func bool(_ key: String) -> Bool?
    func int(_ key: String) -> Int?
}

public extension RemoteConfigProviding {
    func string(_ key: String, default fallback: String) -> String { string(key) ?? fallback }
    func bool(_ key: String, default fallback: Bool) -> Bool { bool(key) ?? fallback }
    func int(_ key: String, default fallback: Int) -> Int { int(key) ?? fallback }
}

/// Static config used before a live backend is wired. Seed it from a bundled JSON or literals.
public struct StaticRemoteConfig: RemoteConfigProviding {
    private let values: [String: String]
    public init(_ values: [String: String] = [:]) { self.values = values }

    public func string(_ key: String) -> String? { values[key] }
    public func bool(_ key: String) -> Bool? { values[key].map { ($0 as NSString).boolValue } }
    public func int(_ key: String) -> Int? { values[key].flatMap(Int.init) }
}
