# PrivacyLens 🔎🛡️

Native macOS SwiftUI app that shows which privacy permissions every installed
app holds, with one-click deep links into the matching
System Settings → Privacy & Security pane.

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-black) ![license](https://img.shields.io/badge/license-MIT-green)

![PrivacyLens showing every app's privacy permissions in one searchable list](images/privacyLens%20app.png)

## Everything under your nose 👀

Every app you install quietly asks for access — your camera, microphone, screen,
files, even your whole disk. Approve a prompt once and it's easy to forget what
you handed over. PrivacyLens shows you **which apps are taking which
permission**, all in one list, so nothing happens under your nose.

One honest catch: to read macOS's privacy records, an app must be granted
**Full Disk Access** itself. That's Apple's rule, not a PrivacyLens choice —
every permission inspector works this way. Grant it once (the app walks you
through it) and PrivacyLens runs smoothly from then on. It uses that access for
exactly one thing: a single read-only database query. No writes, no network, no
telemetry.

## Why PrivacyLens?

macOS apps ask for powerful permissions — your camera, microphone, screen,
entire disk, accessibility controls. But macOS gives you **no single place to
see the whole picture**: to check which apps can watch or listen to you, you
have to open a dozen different System Settings panes, scroll through them one
by one, and try to remember what you find.

**The problem:** privacy settings on macOS are scattered, opaque, and easy to
forget. An app you granted Accessibility access two years ago may still have
full control of your Mac — and you'd never know without hunting for it.

**PrivacyLens solves this:**

- 🪟 **One view, every app** — all installed apps with all their privacy
  permissions in a single searchable list
- ⚡ **Instant answers** — "which apps can see my screen?", "who has camera
  access?" — one click on a filter chip instead of a scavenger hunt
- ⏰ **Transparency over time** — see *when* each permission was last changed,
  so long-forgotten grants stand out
- 🚨 **Risk awareness** — flags dangerous combinations like Accessibility +
  Screen Recording (full remote-control capability)
- 👀 **Live monitoring** — notices when an app gains a new permission while you
  work
- 🔗 **One-click fixes** — click any permission to jump straight to its exact
  System Settings pane and revoke what you don't trust

Everything runs **100% locally**: no network access, no accounts, no analytics.
Your privacy audit tool should never be a privacy risk itself.

## Install

**Option A — build from source (most trusted, ~2 min):**

```bash
git clone <repo-url> && cd privacyLens
xcodebuild -project PrivacyLens.xcodeproj -target PrivacyLens -configuration Release build
open build.noindex/Release/PrivacyLens.app
```

**Option B — download the release:**

1. Grab `PrivacyLens.zip` from [Releases](../../releases) and unzip
2. Right-click `PrivacyLens.app` → **Open** (macOS warns because the app is
   self-signed, not notarized — expected for open-source apps without an
   Apple Developer account). On newer macOS: if double-click is blocked, go to
   **System Settings → Privacy & Security** and click **Open Anyway**

## First launch: Full Disk Access

Apple stores every app's permissions in its TCC database (`TCC.db`), which is
protected behind **Full Disk Access**. On first launch PrivacyLens explains this
and deep-links you to the right pane. Enable the PrivacyLens toggle there (or add
the app with **+**) — the window refreshes automatically once granted.

PrivacyLens never modifies the database and never sends data anywhere. To audit
that claim, read `PrivacyLens/Helpers/TCCDatabase.swift` — it's one read-only
SQL query.

## Features

- 🔍 **Searchable list** of installed apps with glanceable permission chips
- 🛡️ **15 permission types**: Full Disk Access, Camera, Microphone, Screen
  Recording, Accessibility, Location, Contacts, Calendars, Reminders, Photos,
  Desktop/Documents/Downloads/Network/Removable folders
- ⚡ **Filter chips** — "show me every app with Camera access"
- 🕐 **Timestamps** — when each permission was last changed
- ⚠️ **Risk badges** — flags dangerous combos (Accessibility + Screen Recording)
- 📡 **Live monitoring** — detects permission changes within 15 s (one file
  `stat`; rescans only when the database actually changed)
- 🖱️ **Right-click** → Reveal in Finder / Open App
- 🔗 **Deep links** — click any permission to open its exact System Settings pane

## How it works

- **App list** — scans `/Applications`, `/System/Applications` (+ Utilities),
  and `~/Applications` via `FileManager`/`Bundle` (official APIs).
- **Permissions** — read-only SQLite queries against the system and user
  `TCC.db`. Apple's public permission APIs (`AVCaptureDevice.authorizationStatus`,
  `AXIsProcessTrusted`, …) only report the *calling* app's own state, so the
  TCC database is the only way to see other apps' permissions. Rows are
  matched by each app's **declared bundle identifier** (falling back to the
  executable path inside the app's bundle for services that record one).
  This means an app whose Info.plist claims another app's bundle ID could,
  in edge cases, be shown that app's statuses — a display limitation of how
  TCC records identities, not a data leak. Cross-check anything sensitive in
  System Settings itself.
- **Location** — stored in locationd's registry
  (`/var/db/locationd/clients.plist`), not TCC. It's world-readable, so location
  statuses work even without Full Disk Access.
- **Deep links** — `x-apple.systempreferences:com.apple.preference.security?Privacy_<Service>`
  URLs. Apple provides no API to pre-select a specific app's row inside the
  pane, so clicking a permission opens the correct pane and you pick the app
  there.

## Building & signing

Requires Xcode 16+ (macOS 14+ SDK). The project signs with a local
self-signed certificate named **`PrivacyLens Dev`** — create your own
(Certificate Assistant or Keychain Access, code-signing type) and either use
the same name or change `CODE_SIGN_IDENTITY` in the project settings. Ad-hoc
signing (`CODE_SIGN_IDENTITY = -`) also works, but macOS then forgets
Full Disk Access grants after every rebuild.

## Contributing

PRs welcome! The loop:

```bash
git clone <repo-url> && cd privacyLens
swift test                                    # unit tests (pure logic, ~1 s)
./Scripts/install_dev.sh                      # build, install, launch
# …edit…
./Scripts/install_dev.sh                      # re-run to rebuild + relaunch
```

- `swift test` covers the permission-matching and timestamp logic and needs
  no signing — run it before every commit.
- First dev install: create a self-signed code-signing certificate named
  **`PrivacyLens Dev`** (see *Building & signing* below) so macOS remembers
  Full Disk Access grants between rebuilds.
- Please include your macOS version and the affected service in bug reports.

## Project layout

```
PrivacyLens/
├── PrivacyLensApp.swift      entry point, menu commands, debug self-check
├── Models/                   InstalledApp / PermissionService / PermissionStatus
├── Helpers/                  TCCDatabase, PermissionResolver, AppScanner, SystemSettingsLink
├── ViewModels/               AppListViewModel (search, filters, FDA polling, change monitor)
└── Views/                    ContentView, AppRowView, PermissionDetailView, FDARequiredView
```
