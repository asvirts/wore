# Wore — Copy-Paste App Store Connect Metadata (v1.0.0)

Character counts below were checked against App Store Connect limits. Keywords do not repeat words already in the title or subtitle.

---

## 1. Core App Listing (en-US)

- **App Name (28 / 30):** `Wore: Closet & Cost per Wear`
- **Subtitle (23 / 30):** `Your clothes. Pay once.`
- **Primary Category:** Lifestyle
- **Secondary Category:** Utilities
- **Content Rights:** Does not contain, show, or access third-party content
- **Age Rating:** 4+. Answer None on every content question. Unrestricted Web Access: No.
- **Copyright:** `2026 Andrew Virts`
- **SKU:** `wore-ios-001`
- **Bundle ID:** `com.asvirts.wore`
- **Primary Language:** English (U.S.)

---

## 2. Required URLs

Live from the public repo `asvirts/wore`, GitHub Pages, branch `main`, folder `/docs`:

- **Privacy Policy URL:** `https://asvirts.github.io/wore/privacy.html`
- **Support URL:** `https://asvirts.github.io/wore/support.html`
- **Marketing URL:** `https://asvirts.github.io/wore/`
- **Terms of Use:** `https://asvirts.github.io/wore/terms.html`

The in-app constants live in `Packages/WoreKit/Sources/WoreCore/WoreConfig.swift`.

---

## 3. Keywords (100 / 100)

Apple indexes Wore, Closet, Cost, per, Wear, Your, clothes, Pay, and once from the title and subtitle. Paste this string with no spaces after the commas:

```text
wardrobe,outfit,planner,style,lookbook,capsule,fashion,packing,trip,unworn,pieces,hanger,organizer,log
```

---

## 4. Promotional Text (133 / 170)

```text
Add clothes with on-device background removal. Log today's outfit in a few taps and see honest cost per wear. No ads. No subscription.
```

---

## 5. Description

```text
Wore opens directly on your closet. No splash screen, no account setup, and no subscription.

Add a garment in seconds: snap a photo or pick from your library. On-device Vision automatically lifts the piece off the background so your closet looks clean and unified. If lighting makes cutout tricky, save the original and crop it right away. Set a category, color, and optional price.

TWO-TAP OUTFIT LOGGING
Tap pieces you wore today to log them. Wore counts at most one wear per piece per calendar day, so your stats reflect what you actually wore.

HONEST COST PER WEAR
Cost per wear is price divided by wears, calculated only after the first wear. Unworn items are never masked with a fake number—they live in their own Unworn list so you can see what is sitting in your closet and decide what to keep.

TRIP PACKING LISTS
Create packing checklists for upcoming trips and check off pieces as you pack them.

FREE FOREVER
- Up to 40 garments
- Fast on-device background removal and cropping
- Daily outfit logging
- Zero ads and zero tracking

WORE PRO ($7.99 ONCE)
- Unlimited garments
- Cost per wear calculations
- Dedicated Unworn pieces list
- Trip packing checklists
- Home Screen outfit widget
- Family Sharing included

PRIVATE BY DESIGN
All photos and wardrobe logs stay on your device. Wore does not use cloud vision APIs, analytics SDKs, or advertising networks. App Store privacy label: Data Not Collected.
```

---

## 6. App Review Information

- **Sign-in required:** No (uncheck)
- **Review Notes:**
```text
Wore has no user account or login wall. All garment photos and SwiftData models are stored locally on the device. Background removal runs entirely on-device via Apple's Vision framework.
```
