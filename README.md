# Kindle Whispersync Fix — Cydia repo

MobileSubstrate tweak for jailbroken iOS 6 (armv7). Fixes Amazon Kindle app
sync ("Sync to Furthest Page") failing with a silent "Retrieval failed" error.

## Root cause

CFNetwork on iOS 6 sends an outgoing HTTP POST for the Kindle app's
`Content-Type: application/x-octet-stream` request that includes an empty
`Expect:` header. Amazon's legacy `det-ta-g7g.amazon.com` logging endpoint
tolerates it; the actual Whispersync endpoint
(`cde-ta-g7g.amazon.com/FionaCDEServiceEngine/sidecar`) rejects it with
`417 Expectation Failed` every time.

The empty header turned out to be set by the Kindle app itself via the
standard `-[NSMutableURLRequest setValue:forHTTPHeaderField:]` call — not by
CFNetwork internals. `expectfix4.dylib` swizzles that method scoped to the
Kindle app (`com.amazon.Lassen`) and drops the header when its value is
empty.

Source: `expectfix4.m`.

## Package layout

```
debs/space.havrysh.expectfix_1.0.0_iphoneos-arm.deb
Packages / Packages.gz   (dpkg-scanpackages index)
Release
```

## Hosting

Cydia sources need to be served over plain HTTP(S) from a URL that has
`Packages`/`Packages.gz` at its root. Any static file host works:

- Push this whole folder to GitHub Pages / any static host, or
- Serve it locally on the same Wi-Fi as the device:
  `python3 -m http.server 8080` from this directory, then add
  `http://<your-mac-ip>:8080/` as a source in Cydia.

## Installing on device

Cydia → Sources → Edit → Add → paste the repo URL → search "Kindle
Whispersync Fix" → Install → respring (or just relaunch Kindle).

## Rebuilding the .deb after editing expectfix4.m

```
SDK=<path to an iOS SDK with an armv7 slice>
clang -arch armv7 -mthumb -O2 -isysroot "$SDK" -miphoneos-version-min=6.0 \
  -dynamiclib -framework Foundation -L. -lsubstrate \
  expectfix4.m -o pkgroot/Library/MobileSubstrate/DynamicLibraries/expectfix4.dylib
ldid -S pkgroot/Library/MobileSubstrate/DynamicLibraries/expectfix4.dylib

dpkg-deb --build --root-owner-group pkgroot \
  debs/space.havrysh.expectfix_1.0.0_iphoneos-arm.deb

dpkg-scanpackages debs /dev/null > Packages
gzip -k -f Packages
```
