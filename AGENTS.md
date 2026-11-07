# Repository guidance

## Purpose and verified scope

This is the unofficial iOS 8 fork of iTunesStoreX. Read `README.md` before
changing behavior or documenting compatibility.

- App Store sign-in was verified on a jailbroken iPad 4 running iOS 8.4.1
  on 7 November 2026. The tested tweak binary is now distributed in package
  `3.1+ios8.4.1-1`; the naming correction changed only package metadata.
- The tested device also had GSAPort `2.4.2+ios8.4`, tlsfix, and CheckmateStore.
  Their necessity for App Store login has not been isolated.
- GSAPort restored iCloud login before iTunesStoreX was installed. The projects
  address different authentication paths; do not claim they require each other.
- Downloads and other devices or iOS versions remain unverified. Compilation
  or a passing smoke check does not establish successful account login.

## Source map

- `src/Tweak.x`: Logos hooks and explicit `%init` in the constructor.
- `src/StoreURLs.h`: scoped Store URL and authentication URL corrections.
- `src/CustomURLProtocol.m`: legacy storefront bootstrap interception.
- `src/iTunesStoreX.plist`: Substrate injection filter, including `itunesstored`.
- `src/Makefile`, `src/control`: build target and Debian package metadata.
- `src/layout/`: package resources and maintainer scripts.
- `diagnostics/smoke.m`: URL/protocol checks and optional device hook checks.
- `diagnostics/read-logs.m`: filtered Store/account log inspection.

## Implementation constraints

Keep changes compatible with iOS 8 and 32-bit ARM (`armv7`). The current
Theos target uses the iOS 9.3 SDK and an iOS 8.0 deployment minimum; package
dependencies restrict installation to iOS 8.x and require Cydia Substrate.

Preserve the iOS 8 `_runRequestWithURL:dataConnectionServiceType:` signature
and verify private selectors on the target OS before changing hooks. Keep
explicit hook initialization. Use Objective-C with ARC as configured.

URL rewrites must be restricted by host and path, preserve queries/fragments,
and tolerate nil or unexpected bag values. Keep the URL protocol handled-marker
check to prevent recursive interception. iOS 8 URL normalization differs from
modern Foundation; use the existing trailing-slash regression cases.

Do not reintroduce hard-coded IP redirects, broad signature/TLS bypasses,
expired replacement certificates, or unrelated account/cache deletion. Keep
diagnostics free of passwords, verification codes, tokens, response bodies,
and full authentication URLs. Preserve upstream attribution and the license.

## Build

Run packaging from `src`, not the repository root. With a configured Theos
toolchain supporting armv7 and the iOS 9.3 SDK:

```sh
cd src
make package FINALPACKAGE=1 THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
```

The toolchain used on the original test Mac was invoked with:

```sh
make package FINALPACKAGE=1 \
  THEOS=/private/tmp/gsaport-build/theos \
  PREFIX=/Library/Developer/CommandLineTools/usr/bin/ \
  THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
```

That temporary directory is machine-specific and may no longer exist. Do not
assume an unmodified SDK reproduces the build: the tested SDK and packager
needed local repairs described in the related GSAPort fork's README.
No SDK or system libraries belong in the package. Generated `.theos/` and
`packages/` directories are ignored; distribute `.deb` files as release assets.

## Validation and device testing

For documentation-only edits, review accuracy and run `git diff --check`.
For source/package changes, also build and run checks relevant to the change.
Validate armv7 output, the iOS deployment minimum, dependencies, gzip archives,
root-owned archive entries, and executable maintainer scripts.

Compile `diagnostics/smoke.m` together with `src/CustomURLProtocol.m` for the
device. Rename its protocol class during compilation with
`-DCustomURLProtocol=ITXSmokeURLProtocol` to avoid duplicating the tweak's
class when loading its dylib. Sign the executable with ldid. With a dylib path
argument, the helper checks that all three Store hook implementations change
after loading it; without an argument, it only runs URL/protocol checks.
These checks run in the helper process, not the real Store daemon.

The original development device was reachable through `ssh ipad4`; verify
the target and current authorization before device work. Preserve its working
iCloud account and let the user enter credentials. Do not publish device logs
or account data.

After installation, restart both the Store apps and `itunesstored`, or reboot.
A respring alone may leave the daemon running. A previous graceful restart did
not take effect: verify a new PID and the `[iTunesStoreX]` load event in daemon
logs before asking the user to retry login. Do not reuse historical PIDs.
When replacing signed test executables, use fresh filenames if iOS caches the
old code signature.

## Git and releases

`origin` is `kevinchan-dev/iTunesStoreX`; `upstream` is
`ObscureMosquito/iTunesStoreX`. Preserve that distinction.

Commit only changes belonging to the requested task. Honor any request to keep
commits local for review. Push or publish only when authorized by the current
task; do not infer permission from unrelated earlier pushes or releases.

For future releases, obtain publication authorization, use a pre-release while
compatibility remains limited, and attach the built `.deb` plus `SHA256SUMS`.
Verify the source commit, package version, uploaded asset digest, and release
status. State the exact tested configuration and remaining uncertainties.
Never replace a published artifact with a different binary under the same
version; use a new version for changed packages. The corrected iOS 8 pre-release
is `v3.1-ios8.4.1-1` with package version `3.1+ios8.4.1-1`. Use the full
verified OS version in release/package names, followed by a package revision;
do not abbreviate it to a name that looks like a different iOS version.
