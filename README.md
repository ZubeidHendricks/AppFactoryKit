# AppFactoryKit

The shared core for a portfolio of iOS utility apps. Build the funnel **once**; every new app
inherits onboarding, a hard paywall, subscriptions, and a full conversion funnel. Per app you
write only the one feature + App Store metadata.

> Strategy context: a 100-app portfolio pays out on a **power law** — most apps trickle, a few
> carry everything. The kit exists to make shipping app #50 nearly free so the market can find
> your winners. The existential risk is **App Store Guideline 4.3 (spam/duplicate apps)**, which
> can terminate your whole account at once. So the kit shares *internal plumbing* while each app
> stays *genuinely differentiated on the surface* (different function, UI, niche, keywords).

## What's in the box

| Layer | Type | What it does |
|---|---|---|
| Subscriptions | `PurchaseProvider` | One seam to any billing backend. `MockPurchaseProvider` (previews/tests) + `RevenueCatPurchaseProvider` (production). |
| State | `SubscriptionManager` | Observable entitlement + products + purchase/restore. Never imports a store SDK. |
| Onboarding | `OnboardingFlowView` | Paged value props → completes → presents paywall. |
| Paywall | `HardPaywallView` | Hero + benefits + plan selector (per-week anchor, "BEST VALUE") + big CTA + **delayed dismiss**. Modeled on top scanner/QR paywalls. |
| Funnel | `AnalyticsHub` / `FunnelEvent` | Every step instrumented (`paywall_view`, `purchase_completed`, `premium_feature_blocked`, …). This is how you know which apps to kill vs. feed. |
| Remote config | `RemoteConfigProviding` | A/B paywall copy, pricing emphasis, trial on/off, dismiss delay — **without an App Store resubmit**. |
| Orchestration | `AppFactory` + `.appFactoryRoot` | Wires it all into an app with one modifier. |

## Verified

- `AppFactoryKit` (core, zero third-party deps) — builds for iOS ✅
- `AppFactoryKitRevenueCat` (RevenueCat adapter) — builds for iOS ✅
- 6 unit tests (pricing math, remote-config overrides, mock purchase flow, analytics fan-out) — pass on iOS Simulator ✅

## Integrate a new app (the whole per-app surface)

See `Examples/QRScannerApp.swift` for a complete reference. The three things you change:

1. **`AppFactoryConfiguration`** — app name, RevenueCat key, onboarding slides, paywall copy/benefits, product ids.
2. **One feature view** — the actual utility. Gate premium actions with `factory.requirePremium(feature:)`.
3. **App Store metadata** — name, keywords, icon. (ASO keyword in the name > any feature.)

```swift
ContentView().appFactoryRoot(factory)   // onboarding → content → paywall
```

## Production setup checklist (per app)

- [ ] RevenueCat account → public SDK key → entitlement id `premium`
- [ ] App Store Connect: create the subscription products, map them into a RevenueCat offering
- [ ] Set `productIDs` in the paywall config to match
- [ ] Add real `AnalyticsSink`s (Mixpanel/Amplitude) alongside `ConsoleAnalyticsSink`
- [ ] Point `RemoteConfigProviding` at a live backend for paywall A/B tests
- [ ] Terms + Privacy URLs (Apple requires them on subscription paywalls)
- [ ] Differentiate hard for **Guideline 4.3**: distinct function, UI, screenshots, keywords

## The $1k/app math (why the funnel matters more than the feature)

At $29.99/yr or $4.99/wk, **$1,000/mo ≈ 40–80 active paying subs**, fed by ~30–60 installs/day
at a 3–8% paywall conversion. The build is 20% of the work; ASO + install funnel is 80%. The
`FunnelEvent` instrumentation is there so each app tells you exactly where it leaks.

## Roadmap (next factory pieces)

- Portfolio tracker: one dashboard of installs/conversion/MRR across all apps (kill vs. feed)
- App generator: scaffold a new app target from a config file
- StoreKit 2 provider (drop the RevenueCat dependency if desired)
- Paywall variants (multi-page, video hero) selectable by remote config
