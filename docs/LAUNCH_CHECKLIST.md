# Wore — App Store submission checklist (v1.0.0)

Copy for App Store Connect is in [APP_STORE_METADATA.md](./APP_STORE_METADATA.md). The public pages are `docs/index.html`, `privacy.html`, `support.html`, and `terms.html`.

This checklist stops before you tap Submit. Screenshots, the final signed binary upload, and the Paid Apps Agreement completion remain manual.

---

## 1. Public Privacy Policy and Support pages

App Store Connect needs live HTTPS URLs before you can submit.

```sh
# From /Users/asvirts/Documents/Apps/wore
gh repo create asvirts/wore --public --source=. --remote=origin --push
gh api -X POST repos/asvirts/wore/pages \
  -f "build_type=legacy" \
  -f "source[branch]=main" \
  -f "source[path]=/docs"
```

Confirm these load in a browser:

- https://asvirts.github.io/wore/
- https://asvirts.github.io/wore/privacy.html
- https://asvirts.github.io/wore/support.html
- https://asvirts.github.io/wore/terms.html

Pages can take a minute after the API call. If the API rejects the request, turn Pages on by hand: repo **Settings → Pages → Deploy from branch `main` / `docs`**.

---

## 2. Apple Developer identifiers (already configured)

Team `H4ND8LAYMT` is set in `project.yml`.

- App Group: `group.com.asvirts.wore`
- App ID: `com.asvirts.wore` (App Groups + In-App Purchase)
- App ID: `com.asvirts.wore.widgets` (App Groups)

---

## 3. App Store Connect record (already created)

- App ID: `6832101584`
- Bundle ID: `com.asvirts.wore`
- Pro Product ID: `com.asvirts.wore.pro` ($7.99 once, Family Sharing)

### Next steps in App Store Connect:
1. Paste fields from [APP_STORE_METADATA.md](./APP_STORE_METADATA.md) into the Version 1.0 page:
   - Description
   - Keywords
   - Promotional text
   - Support URL: `https://asvirts.github.io/wore/support.html`
   - Marketing URL: `https://asvirts.github.io/wore/`
   - Copyright: `2026 Andrew Virts`
2. App Privacy page:
   - Add Privacy Policy URL: `https://asvirts.github.io/wore/privacy.html`
3. In-App Purchase (`Wore Pro`):
   - Upload review screenshot for `com.asvirts.wore.pro`
4. Attach `Wore Pro` to the version 1.0 submission.
5. Provide banking details and W-9 form under Agreements.
