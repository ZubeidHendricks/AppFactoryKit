import SwiftUI

/// Paged value-prop onboarding that ends by completing onboarding (and, by default,
/// presenting the paywall). Keep it short — every extra slide leaks installs.
public struct OnboardingFlowView: View {
    @EnvironmentObject private var factory: AppFactory
    @State private var index = 0

    public init() {}

    private var onboarding: OnboardingConfiguration { factory.config.onboarding }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(onboarding.slides.enumerated()), id: \.element.id) { i, slide in
                    slideView(slide).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onChange(of: index) { _, new in
                factory.analytics.track(.onboardingSlide(index: new))
            }

            Button(action: advance) {
                Text(index == onboarding.slides.count - 1 ? onboarding.continueTitle : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(onboarding.accent)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .task { factory.analytics.track(.onboardingStart) }
    }

    private func slideView(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: slide.systemImage)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(onboarding.accent)
            Text(slide.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(slide.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private func advance() {
        if index < onboarding.slides.count - 1 {
            withAnimation { index += 1 }
        } else {
            factory.completeOnboarding()
        }
    }
}
