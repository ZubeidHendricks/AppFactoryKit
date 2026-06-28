import SwiftUI

/// A single onboarding slide. 2–3 slides is the sweet spot before the paywall.
public struct OnboardingSlide: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let systemImage: String
    public let title: String
    public let message: String

    public init(systemImage: String, title: String, message: String) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }
}

public struct OnboardingConfiguration: Sendable {
    public var slides: [OnboardingSlide]
    public var continueTitle: String
    /// Show the paywall automatically the moment onboarding finishes (standard utility-app funnel).
    public var presentsPaywallOnFinish: Bool
    public var accent: Color

    public init(
        slides: [OnboardingSlide],
        continueTitle: String = "Continue",
        presentsPaywallOnFinish: Bool = true,
        accent: Color = .accentColor
    ) {
        self.slides = slides
        self.continueTitle = continueTitle
        self.presentsPaywallOnFinish = presentsPaywallOnFinish
        self.accent = accent
    }
}
