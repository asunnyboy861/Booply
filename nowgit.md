# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | Booply |
| **Git URL** | git@github.com:asunnyboy861/Booply.git |
| **Repo URL** | https://github.com/asunnyboy861/Booply |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/Booply/ | ✅ Active |
| Support | https://asunnyboy861.github.io/Booply/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/Booply/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/Booply/terms.html | ✅ Active |

## Repository Structure

```
Booply/
├── Booply.xcodeproj/              # Xcode Project (Vortex SPM, iOS 17)
├── Booply/                        # Swift Source Files
│   ├── BooplyApp.swift            # Entry + SwiftData container
│   ├── RootView.swift             # Onboarding/Home routing
│   ├── Theme.swift                # Sage/Cream design system
│   ├── SettingsStore.swift        # Cockpit persistence
│   ├── GrowWithMeEngine.swift     # Stage + worlds + daily rotation (+ unit tested)
│   ├── Models.swift               # BabyProfile/PlaySession/Milestone
│   ├── SessionInteractions.swift  # Anonymous local telemetry
│   ├── KidSessionView.swift       # Kid feed + wind-down + asleep + gate
│   ├── KidSupport.swift           # Haptics/SoundBank/Speech/Vortex bursts
│   ├── Worlds.swift               # 8 content worlds
│   ├── ParentGateView.swift       # Math gate (2 consecutive correct)
│   ├── OnboardingView.swift       # 2-question setup
│   ├── HomeView.swift             # Single big button
│   ├── ReceiptView.swift          # Guilt-free receipt card
│   ├── ReceiptComposer.swift      # Template + Apple Intelligence
│   ├── MilestoneAlbumView.swift   # Album + photos + PDF export
│   ├── PurchaseManager.swift      # StoreKit 2 (3 products)
│   ├── PaywallView.swift          # Transparent pricing + legal links
│   ├── CockpitView.swift          # Parent controls + weekly report
│   ├── SettingsView.swift         # Links, restore, version
│   ├── ContactSupportView.swift   # Feedback backend integration
│   ├── AIServices.swift           # Keychain + GLM vision/weekly + BYO
│   ├── BYOKeyView.swift           # Key management UI
│   └── Assets.xcassets            # App icon (Agnes generated)
├── BooplyTests/                   # 15 unit tests (engine/rules/tier)
├── docs/                          # Policy pages (added in PHASE 7)
├── .github/workflows/             # Pages deploy (added in PHASE 7)
├── app_review_info.md             # Reviewer notes
├── nowgit.md
├── us.md / capabilities.md / icon.md / price.md
└── keytext*.md                    # ⚠️ EXCLUDED (.gitignore — confidential ASO strategy)
```

## Build Verification Log

| Check | Result |
|-------|--------|
| iPhone 17 build | ✅ BUILD SUCCEEDED |
| iPhone 17 run | ✅ Onboarding renders, launch clean |
| iPad Pro 13" (M5) build | ✅ BUILD SUCCEEDED |
| iPad Pro 13" (M5) run | ✅ Centered layout, no sidebar issues |
| Unit tests (BooplyTests) | ✅ 15 passed / 0 failed |
| Secret leak scan | ✅ Clean |
