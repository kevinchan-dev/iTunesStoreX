<div align="center">
<img src="icon.png" width=20% height=20%>
<h1>iTunes Store X</h1>
</div>

**Tested and verified: App Store sign-in on a jailbroken iPad 4 running iOS 8.4.1**, using iTunesStoreX `3.1+ios8.1`. Successful login was confirmed on 7 November 2026 after restarting `itunesstored` so it loaded the tweak. App downloads have not been verified.

This is an unofficial iOS 8 fork of [ObscureMosquito/iTunesStoreX](https://github.com/ObscureMosquito/iTunesStoreX). Credit for the original tweak belongs to Requis, Bag.xml, and the upstream contributors. The verification applies to this fork's build and the tested device configuration; other devices and iOS versions remain untested.

## Relationship to GSAPort

The test device also had [the iOS 8 GSAPort fork](https://github.com/kevinchan-dev/GSAPort) `2.4.2+ios8.4` installed:

| Tweak | Verified result on iPad 4 / iOS 8.4.1 |
| --- | --- |
| GSAPort | iCloud sign-in worked before iTunesStoreX was installed. |
| iTunesStoreX | App Store sign-in worked with GSAPort still installed. |

GSAPort handles iCloud authentication, while this fork repairs Store URLs and the App Store authentication endpoint. GSAPort alone did not restore App Store login on the test device. App Store login has not been tested with GSAPort removed, so it is **unknown whether iTunesStoreX needs GSAPort for that login**. Keep both installed to reproduce the verified setup. The device also had `tlsfix` and CheckmateStore installed; their necessity has not been isolated.

## iOS 8 build and installation

This checkout builds `src/packages/com.skyglow.itunesstorex_3.1+ios8.1_iphoneos-arm.deb`
for armv7 devices on iOS 8.x. App Store login was confirmed on an iPad 4 running
iOS 8.4.1 with this build and GSAPort `2.4.2+ios8.4` installed. Downloads remain
untested, and other devices and iOS versions have not been validated. The
upstream release above targeted iOS 7 and earlier. GSAPort handles a different
authentication path; successful iCloud login alone does not establish that
App Store login works.

Changes in this build:

- Include `itunesstored` in the injection filter.
- Use iOS 8's `_runRequestWithURL:dataConnectionServiceType:` operation hook
  and explicitly initialize the Logos hooks.
- Correct legacy URL bag hosts only for bag requests.
- Add the authentication endpoint trailing slash correction identified by Pod in
  [NewerStoreLoginFix](https://github.com/Epixx512/NewerStoreLoginFix). Preserve
  query strings and fragments and accept both string and URL bag values.
- Respect the URL protocol handled marker and restrict bootstrap rewrites to
  Apple Store hosts.
- Omit the expired replacement bag certificate and unconditional signature
  bypass. Normal signature and TLS checks still apply; a bag validation failure
  may need a separate, targeted fix after device diagnostics.
- Remove installer cache deletion and the hard-coded `/etc/hosts` redirects.
  Removal no longer restores an unrelated hosts backup.

Build from `src` using the temporary toolchain already prepared on this Mac:

```sh
make package FINALPACKAGE=1 \
  THEOS=/private/tmp/gsaport-build/theos \
  PREFIX=/Library/Developer/CommandLineTools/usr/bin/ \
  THEOS_PLATFORM_DEB_COMPRESSION_TYPE=gzip
```

The package uses gzip archives and root-owned entries for older Cydia/dpkg.
The temporary SDK/toolchain must still exist. The compiler needs access to its
module cache when running inside a sandbox.

To install, copy the package to the iPad and run as root:

```sh
dpkg -i com.skyglow.itunesstorex_3.1+ios8.1_iphoneos-arm.deb
```

Reboot after installation so both the Store apps and `itunesstored` load the
tweak. A respring alone may leave the existing Store daemon running. Keep
GSAPort installed. Do not sign out of a working iCloud account for this test. Avoid
combining other Store URL rewriting tweaks during diagnosis. Uninstall using
Cydia or `dpkg -r com.skyglow.itunesstorex`, then reboot.

Diagnostic messages use the `[iTunesStoreX]` prefix and record process loading
and rewrite events, without URLs, passwords, verification codes, or tokens.
`diagnostics/smoke.m` checks URL edge cases and protocol selection on iOS 8;
when supplied a dylib path, it also checks Store hook selectors and loads that
dylib in its own process. This does not test a real account login.

Validation on the connected iPad 4 / iOS 8.4.1: URL and protocol checks passed,
the signed armv7 dylib loaded, and all three method implementations changed
when the tweak initialized. Version `3.1+ios8.1` was installed over SSH. The
initial login attempts failed while the old `itunesstored` process remained
running. After restarting that daemon and confirming the tweak's load event
in its logs, the user confirmed successful App Store login on 7 November 2026.
The device also had `tlsfix` and CheckmateStore installed; their necessity was
not tested independently. Downloads remain unconfirmed.

`diagnostics/read-logs.m` reads recent Store and account log events, reporting
error domains/codes, known markers, and hostnames without full request URLs or
response bodies. It helped identify the daemon that had not loaded the tweak.

## Original project

The upstream project aims to repair legacy Store connections and storefront layout. Its original Cydia repository is <http://cydia.skyglow.es>; packages from that repository are separate from this fork's verified iOS 8 build.
