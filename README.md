# Wore: Closet & Cost per Wear

**Your clothes. Pay once.**

Wore is a local-first closet for **iPhone and iPad** (iOS 26+). Photograph clothes you own, log what you wore, and see cost per wear. Photos stay on the device. There is no account, no shopping feed, and no ads.

The working name was Kept. That name is already on the App Store, so the app is **Wore** (`com.asvirts.wore`).

Free to download. **Wore Pro** ($7.99 once, Family Sharing) unlocks unlimited garments, cost per wear, the unworn list, trip lists, and a Home Screen widget of today's outfit.

See [docs/SPEC.md](docs/SPEC.md) for the product rules.

## Getting started

```sh
brew install xcodegen            # once
cd /Users/asvirts/Documents/Apps/wore
xcodegen generate                # generates Wore.xcodeproj from project.yml
open Wore.xcodeproj
```

The Xcode scheme uses `Wore/Resources/Wore.storekit` so the $7.99 non-consumable can be purchased in the simulator. Restore Purchases is on the paywall and in Settings.

### Tests and build

```sh
swift test --package-path Packages/WoreKit
xcodebuild -project Wore.xcodeproj -scheme Wore -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
swift scripts/generate_icons.swift
```

## Layout

| Path | What |
|---|---|
| `Wore/` | iPhone and iPad app |
| `WoreWidgets/` | Home Screen widget of today's outfit (Pro) |
| `Packages/WoreKit/` | `WoreCore` (closet math and SwiftData), `WoreVision` (on-device cutout), `WoreStore` (StoreKit 2) |
| `scripts/generate_icons.swift` | App icon |
| `project.yml` | XcodeGen spec |

## Status

- [x] Closet, one-screen add, on-device cutout with confirm / crop fallback
- [x] Daily outfit log, cost per wear, unworn list, trip checklists
- [x] Free cap of 40 garments and Wore Pro ($7.99, Family Sharing, Restore Purchases)
- [x] Home Screen widget of today's outfit
