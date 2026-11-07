# Wore — Closet & Cost per Wear

**App Store name:** `Wore: Closet & Cost per Wear` (28/30)
**Subtitle:** `Your clothes. Pay once.` (23/30)
**Bundle id:** `com.asvirts.wore`
**Widget:** `com.asvirts.wore.widgets`
**App group:** `group.com.asvirts.wore`
**Pro product:** `com.asvirts.wore.pro` — non-consumable, Family Sharing, **$7.99 once**
**Platforms:** iPhone and iPad, iOS 26+

The working name was **Kept**. App Store search already has `Kept: Home Inventory`, `kept: save fashion & outfits`, Kept Notes, and others, so the app, the folder, and the bundle id are **Wore** / `com.asvirts.wore`.

Indyx charges about $75/year to see cost per wear. Acloset caps the free closet and shows ads. Stylebook proved a one-time closet works, and it is iOS-only with an old interface. Wore is the pay-once closet for iPhone and iPad.

---

## 1. Product principles

1. **A half-finished closet is useful.** Adding one garment is a single short screen. Logging today's outfit is a few taps on clothes already added.
2. **Photos stay on this device.** No account, no shopping feed, no "buy similar," no affiliate links.
3. **Cost per wear is price divided by wears, and only after the first wear.** Unworn pieces are their own list. They are not shown as a fake cost equal to the price.
4. **One wear per piece per calendar day.** Logging the same piece again today does not increment. Taking it off today gives the wear back.
5. **Private by design.** SwiftData on device. No analytics SDK. Privacy label: **Data Not Collected**.

---

## 2. Free vs Wore Pro

| Feature | Free forever | Pro ($7.99 once) |
|---|---|---|
| Garments | 40 | Unlimited |
| On-device background cutout | Yes | Yes |
| Daily outfit log | Yes | Yes |
| Cost per wear | — | Yes |
| Unworn list | — | Yes |
| Trip lists (checklist + packed) | — | Yes |
| Home Screen widget of today's outfit | — | Yes |

Restore Purchases is on the paywall and in Settings. Family Sharing is enabled on the non-consumable.

---

## 3. Screens

The app opens on the closet. There is no splash screen and no account wall.

| Screen | What you do |
|---|---|
| **Closet** | Grid of pieces. Search, category chips, add, settings. The Unworn chip opens the list when Pro, otherwise the paywall. |
| **Add garment** | One screen: camera or library, cutout confirmation (Cutout / Photo / Crop), name, category, color, optional price. Save works with or without a photo. |
| **Garment** | Photo, wears, and cost per wear when Pro and the piece has been worn and has a price. |
| **Today** | Tap pieces to log them. Tap again to remove. Grouped by category. |
| **Trips** | Pro. A named checklist. Each piece is packed or not. |
| **Settings** | Pro status, Restore Purchases, the on-device privacy note. |

If `VNGenerateForegroundInstanceMaskRequest` cannot separate a subject, the screen says so and offers the original photo or a crop. The person confirms a successful cutout by leaving **Cutout** selected and tapping **Save cutout**.

---

## 4. Tech decisions

| Area | Choice |
|---|---|
| OS | iOS / iPadOS 26 |
| Persistence | SwiftData, local only |
| Photos | App Group files (`group.com.asvirts.wore`) plus a `today-outfit.json` snapshot the widget reads |
| Cutout | `VNGenerateForegroundInstanceMaskRequest`, on device |
| Purchases | StoreKit 2. `Transaction.currentEntitlements` includes Family Sharing. |
| Project | XcodeGen (`project.yml`). Tests are Swift Testing in `Packages/WoreKit`. |
| Widget | WidgetKit, small / medium / large. Locked state links to `wore://paywall`. |

The free cap is enforced in `ClosetActions.addGarment`, not only by hiding the button. Cost per wear, the unworn filter, and same-day wear counting live in `WardrobeMath`.

---

## 5. Layout

```
wore/
├─ project.yml
├─ Wore/                         # iPhone + iPad app
├─ WoreWidgets/                  # Today's outfit widget
├─ Packages/WoreKit/
│  ├─ Sources/WoreCore/          # Models, WardrobeMath, ClosetActions, PhotoStore
│  ├─ Sources/WoreVision/        # GarmentCutout, ImageCropper
│  ├─ Sources/WoreStore/         # EntitlementManager
│  └─ Tests/WoreCoreTests/
└─ docs/SPEC.md
```
