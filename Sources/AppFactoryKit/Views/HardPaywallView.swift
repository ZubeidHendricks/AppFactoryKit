import SwiftUI

/// The money screen. Hero + benefits + plan selector + big CTA + delayed dismiss.
/// Modeled on the highest-converting scanner/QR paywalls (iScanner, QR-genre).
public struct HardPaywallView: View {
    @EnvironmentObject private var factory: AppFactory
    @Environment(\.openURL) private var openURL

    let placement: String

    @State private var selectedProductID: String?
    @State private var canDismiss = false
    @State private var shownAt = Date()

    public init(placement: String) { self.placement = placement }

    private var config: PaywallConfiguration { factory.paywall }
    private var products: [SubscriptionProduct] { factory.subscriptions.products }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    benefits
                    plans
                    cta
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 32)
            }
            if config.isDismissable { dismissButton }
        }
        .interactiveDismissDisabled(!config.isDismissable)
        .task {
            shownAt = Date()
            factory.analytics.track(.paywallView(placement: placement))
            await factory.subscriptions.refresh()
            if selectedProductID == nil {
                selectedProductID = config.highlightedProductID ?? products.first?.id
            }
            if config.dismissButtonDelay <= 0 {
                canDismiss = true
            } else {
                try? await Task.sleep(nanoseconds: UInt64(config.dismissButtonDelay * 1_000_000_000))
                withAnimation { canDismiss = true }
            }
        }
        .onChange(of: factory.subscriptions.isSubscribed) { _, subscribed in
            if subscribed { close() }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: config.style.heroSystemImage)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(config.style.accent)
            Text(config.headline)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(config.subheadline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(config.benefits) { benefit in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: benefit.systemImage)
                        .foregroundStyle(config.style.accent)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title).font(.callout.weight(.semibold))
                        if let s = benefit.subtitle {
                            Text(s).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(products) { product in
                PlanRow(
                    product: product,
                    isSelected: product.id == selectedProductID,
                    accent: config.style.accent,
                    cornerRadius: config.style.cornerRadius
                )
                .onTapGesture {
                    selectedProductID = product.id
                    factory.analytics.track(.planSelected(productID: product.id, placement: placement))
                }
            }
        }
    }

    private var cta: some View {
        let selected = products.first { $0.id == selectedProductID }
        return VStack(spacing: 6) {
            Button {
                guard let selected else { return }
                Task { await factory.subscriptions.purchase(selected, placement: placement) }
            } label: {
                Group {
                    if factory.subscriptions.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaLabel(for: selected))
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(config.style.accent)
            .clipShape(RoundedRectangle(cornerRadius: config.style.cornerRadius))
            .disabled(selected == nil || factory.subscriptions.isPurchasing)

            if let selected, selected.hasFreeTrial {
                Text("No payment now — cancel anytime before the trial ends.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ctaLabel(for product: SubscriptionProduct?) -> String {
        if let product, product.hasFreeTrial,
           let days = product.introOffer?.periodDays {
            return "Start \(days)-Day Free Trial"
        }
        return config.ctaTitle
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task { await factory.subscriptions.restore() }
            }
            .font(.footnote)
            HStack(spacing: 16) {
                if let terms = config.termsURL {
                    Button("Terms") { openURL(terms) }
                }
                if let privacy = config.privacyURL {
                    Button("Privacy") { openURL(privacy) }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var dismissButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.top, 12)
        .padding(.trailing, 16)
        .opacity(canDismiss ? 1 : 0)
        .allowsHitTesting(canDismiss)
    }

    private func close() {
        let seconds = Int(Date().timeIntervalSince(shownAt))
        factory.analytics.track(.paywallDismiss(placement: placement, secondsShown: seconds))
        factory.dismissPaywall()
    }
}

/// One selectable plan card with a "BEST VALUE" badge and per-week price anchor.
private struct PlanRow: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let accent: Color
    let cornerRadius: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(isSelected ? accent : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(product.period.displayName).font(.callout.weight(.semibold))
                    if product.period == .year {
                        Text("BEST VALUE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(accent)
                    }
                }
                if let perWeek = product.pricePerWeekText, product.period != .week {
                    Text("\(perWeek) / week").font(.caption).foregroundStyle(.secondary)
                } else if product.hasFreeTrial, let days = product.introOffer?.periodDays {
                    Text("\(days)-day free trial").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Text(product.localizedPrice).font(.callout.weight(.semibold))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(isSelected ? accent : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
        )
    }
}
