# AGENTS.md — Wore (`/Users/asvirts/Documents/Apps/wore`)

Inherits portfolio-wide rules from [`../AGENTS.md`](../AGENTS.md).

---

## App Identity

- **Customer-facing name:** Wore. The working name Kept is already used on the App Store (`Kept: Home Inventory`, `kept: save fashion & outfits`, and others).
- **App Store title:** `Wore: Closet & Cost per Wear` (28 / 30)
- **Subtitle:** `Your clothes. Pay once.` (23 / 30)
- **Bundle id:** `com.asvirts.wore`. **Widget:** `com.asvirts.wore.widgets`. **App group:** `group.com.asvirts.wore`. **Pro product:** `com.asvirts.wore.pro` (non-consumable, Family Sharing, $7.99 once).
- **Platforms:** iPhone and iPad, iOS 26+. No account, no ads, no analytics SDK, no shopping feed, no affiliate links. Privacy label: **Data Not Collected**.
- **Photos stay on device.** Background removal uses `VNGenerateForegroundInstanceMaskRequest`. If it fails, save the original and let the person crop.

---

## Commands

```sh
xcodegen generate
swift test --package-path Packages/WoreKit
xcodebuild -project Wore.xcodeproj -scheme Wore -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
swift scripts/generate_icons.swift
```

---

## Architecture Guardrails

1. **Swift 6 strict concurrency.** Vision and image work that does not touch UIKit stays off the main actor, in `WoreVision`. Pass `Data`, not `UIImage`, into `GarmentCutout`.
2. **Cost per wear and the free cap live in `WardrobeMath` / `ClosetActions`.** The UI must not invent a cost for an unworn piece or bypass the 40-garment free limit.
3. **One wear per piece per calendar day.** Adding a piece to today increments. Removing it decrements, and never below zero. Saving the same outfit again does not count twice.
4. **Widget reads the app-group snapshot** (`today-outfit.json`) and the cached Pro flag. It shows today's outfit only when Pro is unlocked and the snapshot day matches today.
5. **Do not add** a browser, a social feed, "buy similar," affiliate links, an account wall, or a paid cloud vision API.
