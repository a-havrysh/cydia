# Havrysh iOS Tweaks — Cydia repo

A single Cydia source for MobileSubstrate tweaks that fix modern-backend
compatibility issues on jailbroken legacy iOS devices (iOS 6+). Each tweak
lives in its own folder under `src/`; all packages ship from this one repo.

## Add this source in Cydia

Sources → Edit → Add → `https://a-havrysh.github.io/cydia/`

## Tweaks

### Kindle Whispersync Fix (`space.havrysh.expectfix`)

**Problem:** the Amazon Kindle app's "Sync to Furthest Page" fails silently
("Retrieval failed, try again later") on iOS 6.

**Cause:** old CFNetwork attaches an empty `Expect:` header to the Kindle
app's sync POST request. Amazon's legacy logging endpoint tolerates it, but
the real Whispersync endpoint (`cde-ta-g7g.amazon.com/FionaCDEServiceEngine/sidecar`)
now rejects it outright with `417 Expectation Failed`, every single time.
Traced with mitmproxy + tcpdump to confirm the exact header and response.

**Fix:** the tweak hooks `-[NSMutableURLRequest setValue:forHTTPHeaderField:]`,
scoped only to the Kindle app (`com.amazon.Lassen`), and silently drops the
header when Kindle tries to set it with an empty value. Everything else about
the request is untouched.

Source: [`src/kindle-sync-fix/expectfix4.m`](src/kindle-sync-fix/expectfix4.m)

## Repo layout

```
Packages / Packages.gz   dpkg-scanpackages index (shared, all tweaks)
Release                  repo metadata
CydiaIcon.png            repo icon
debs/                    built .deb packages (shared, all tweaks)
src/<tweak-name>/        source + pkgroot for each tweak
```

## Adding a new tweak

1. `mkdir -p src/<name>/pkgroot/DEBIAN` and `pkgroot/Library/...` with the
   install paths for whatever the tweak needs.
2. Write `pkgroot/DEBIAN/control` (unique `Package:` id, human `Name:`, a
   `Description:` that states the problem, the cause, and the fix in plain
   English).
3. Build:
   ```
   SDK=<path to an iOS SDK with an armv7 slice>
   clang -arch armv7 -mthumb -O2 -isysroot "$SDK" -miphoneos-version-min=6.0 \
     -dynamiclib -framework Foundation -L. -lsubstrate \
     src/<name>/<source>.m -o src/<name>/pkgroot/Library/.../<name>.dylib
   ldid -S src/<name>/pkgroot/Library/.../<name>.dylib

   dpkg-deb --build --root-owner-group src/<name>/pkgroot \
     debs/<package-id>_<version>_iphoneos-arm.deb
   ```
4. Regenerate the shared index from the repo root:
   ```
   dpkg-scanpackages debs /dev/null > Packages
   gzip -k -f Packages
   ```
5. Commit and push — GitHub Pages serves the updated `Packages` automatically.
