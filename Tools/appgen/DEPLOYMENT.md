# Shipping generated apps to TestFlight

Every app the generator produces ships with a Fastlane lane (`fastlane beta`) and
a GitHub Actions workflow (`.github/workflows/testflight.yml`). They archive the
app and upload it to TestFlight. This guide is the **one-time account setup** that
makes those pipelines work. Do it once; it then applies to every app in the
portfolio.

## Prerequisites (once per portfolio)

1. **Apple Developer Program** membership ($99/yr) — https://developer.apple.com/programs/
2. **App Store Connect API key** (Admin or App Manager):
   - App Store Connect → Users and Access → Integrations → App Store Connect API → **+**
   - Download the `.p8` (you can only download it once). Note the **Key ID** and **Issuer ID**.
3. **A `match` repo** for code signing (recommended for CI):
   - Create a **private** GitHub repo, e.g. `ios-certificates`.
   - From any generated app: `bundle exec fastlane match init`, then
     `bundle exec fastlane match appstore` to create + store the distribution
     cert and an App Store provisioning profile for that app's bundle id.
   - Re-run `match appstore` once per new app to add its provisioning profile.

## Per-app, before the first upload

- Register the bundle id and **create the app record** in App Store Connect
  (Apps → +). The bundle id must match `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`.
- Add subscription products `<id>_yearly` and `<id>_weekly`, wire them into a
  RevenueCat offering (entitlement `premium`), and put your RevenueCat key in
  `Sources/App.swift`.

## GitHub secrets (set on each app repo, or org-wide)

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_CONTENT` | **base64** of the `.p8` file: `base64 -i AuthKey_XXXX.p8 \| pbcopy` |
| `MATCH_GIT_URL` | SSH/HTTPS URL of your private `match` repo |
| `MATCH_PASSWORD` | Passphrase you set during `match init` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `user:personal_access_token` (only if `match` repo is HTTPS) |

Tip: set the `ASC_*` and `MATCH_*` secrets at the **GitHub org level** so all 100
app repos inherit them — you only paste them once.

## Ship

- **CI:** trigger the *TestFlight* workflow manually (Actions tab → Run workflow),
  or push a tag: `git tag v1.0.0 && git push --tags`.
- **Locally:**
  ```bash
  cd <App>
  bundle install
  export ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_CONTENT=... MATCH_GIT_URL=... MATCH_PASSWORD=...
  bundle exec fastlane beta
  ```

The lane runs `xcodegen generate` first, so you never commit the `.xcodeproj`.

## What this does NOT do

- It does not auto-create the App Store Connect app record or fill in metadata
  (screenshots, description, keywords) — that's a manual/`deliver` step per app.
- It uploads to **TestFlight**, not to public App Store review. Promote to
  production from App Store Connect when you're ready.
