# Working on Cull

Three loops, in the order you reach for them:

| Loop | Command | What it is for |
|---|---|---|
| Simulator | `scripts/sim.sh` | Iterating on a screen. Seeds a fake camera roll to swipe through. |
| Tests | `scripts/test.sh` | The filtering and the counters. Seconds, no phone involved. |
| Phone | `scripts/device.sh install` | Living with it: your real library, your real storage. |

`scripts/doctor.sh` checks everything the three depend on and says what to do
about anything missing. Run it first when something stops working.

Every script has a `make` target with the same name — `make sim`, `make test`,
`make install`, `make doctor` — and flags become variables (`make sim
PHOTOS=40`). This document spells out the scripts, since they are what the
targets run and what the flags belong to.

The Xcode project lives in `Cull/Cull.xcodeproj`; the repo root holds the
scripts, the docs and the design sources. The scripts know that, so they work
from anywhere in the tree.

## One-time setup

1. **The iOS platform.** Xcode's SDK has to have a matching simulator runtime,
   or it rejects every destination — simulators *and* phones — with
   "iOS 27.0 is not installed", even though the project is fine. About 8 GB:

   ```
   xcodebuild -downloadPlatform iOS
   ```

2. **An Apple ID in Xcode, and an accepted agreement.** Add your Apple ID under
   **Xcode ▸ Settings ▸ Accounts**, and make sure
   [developer.apple.com/account](https://developer.apple.com/account) has no
   pending Program License Agreement. Either one missing stops Apple issuing a
   provisioning profile, and the last line of the build failure is always the
   unhelpful `No profiles for 'mirobehninger.Cull' were found` — the real reason
   is the line above it.

3. **Your team.** The device build has to be signed by a team. The scripts take
   it from `DEVELOPMENT_TEAM` in `scripts/local.env`, else from Xcode's
   signed-in teams, else from the certificate in the keychain:

   ```
   cp scripts/local.env.example scripts/local.env
   ```

   The team ID is the **OU** of the certificate, not the id in brackets after
   the name — that one is the individual developer, and passing it to xcodebuild
   fails with `No Account for Team`:

   ```
   CN=Apple Development: you@example.com (XQU95N3575), OU=MT23DRL63Z
                                          ^ developer      ^ team
   ```

   `scripts/local.env` is not in git — it is the one file with anything
   machine-specific in it.

4. **The first install.** Do this one from Xcode, with the phone connected and
   unlocked: select it in the toolbar and press ⌘R. Xcode registers the device
   and creates the provisioning profile, which is interactive the first time and
   scripted every time after. Then approve the developer certificate on the
   phone under **Settings ▸ General ▸ VPN & Device Management**.

   Keep the phone unlocked for device builds afterwards too: a locked phone
   fails with `needs to be unlocked to enable development services`, before any
   compiling happens.

## The simulator loop

```
scripts/sim.sh                     # build, install, launch
scripts/sim.sh --photos 40         # ...with 40 generated photos in the library
scripts/sim.sh --media ~/Pictures/testset
scripts/sim.sh --erase --photos 40 # wipe the device first: no photos, no
                                   # permissions, no counters
scripts/sim.sh --revoke            # ask for photo access again on next launch
scripts/sim.sh --grant             # skip the permission prompt
scripts/sim.sh --console           # keep the log attached
```

A fresh simulator has an empty photo library, and Cull with nothing to swipe
shows its empty state and nothing else — so `--photos N` generates N PNGs of
varying size and colour and adds them with `simctl addmedia`. They are gradients,
not photographs, which is enough for the card stack, the progress counter and
the deletion flow; `--media` takes real files when you need to look at something
truthful. Either way the images stay in the simulator's library until `--erase`,
so you only seed once.

`--grant` and `--revoke` exist because the permission prompt is part of the
product: Cull's first screen is about asking for the library, and the only way
to see that screen twice is to put the simulator back to "not yet asked".

The script reuses a booted simulator if there is one, and otherwise picks the
newest iPhone runtime installed. That keeps the seeded library around and saves
the ~20s cold boot.

## The phone loop

```
scripts/device.sh install          # backup, build, install, launch
scripts/device.sh install --no-backup
scripts/device.sh backup           # just the backup
scripts/device.sh restore backups/20261010T145800
scripts/device.sh logs             # relaunch with the console attached
scripts/device.sh files Library    # list what is in the app's container
```

This is the loop that matters for Cull: the simulator can tell you whether a
screen lays out, but only your own library tells you whether a session of a
thousand photos is actually pleasant, and only a real phone reports real
storage freed.

**Deleting is real here.** Cull removes photos through PhotoKit, so they land in
**Recently Deleted** and stay recoverable for 30 days — but after 30 days they
are gone, and a bug in a dev build deletes just as permanently as a shipped one.
Test destructive changes in the simulator first.

### Which iPhone it installs onto

With one phone connected, nothing to decide. With two — a new phone and the old
one still paired — `CULL_DEVICE` in `scripts/local.env` picks:

```
scripts/device.sh list        # the Identifier column is what goes in CULL_DEVICE
```

Use the **UDID** (`00008160-...`), not the name: a replacement phone restored
from a backup carries the old one's name, so both show up as "iPhone von Miro"
and a name matches neither uniquely. Unset, the scripts take the only connected
phone and refuse to guess between two.

A phone devicectl has not opened a tunnel to yet reports no model and no
`reality` in its JSON. The scripts therefore exclude simulators rather than
require `reality == "physical"` — the positive test drops a new phone silently,
and installs keep landing on the older one that happens to be fully described.

### What the backups cover

`install` copies the app's data container into `backups/<timestamp>/` before it
builds, and `--no-backup` skips that for the first install, when there is
nothing to copy.

What that container holds is small: Cull keeps the kept-photo marks, the
lifetime culled count and the storage-freed total in `UserDefaults`, which on
disk is `Library/Preferences/mirobehninger.Cull.plist`. `restore` puts exactly
that directory back, after stopping the app so it cannot write its in-memory
copy over the restore on the way out.

**Your photos are not in the backup.** They live in the system photo library,
which these scripts never touch. A backup here protects your review history —
which photos you have already said "keep" to, so a new session does not show
them again — and nothing more.

### Does the state survive an update?

**Yes.** Installing over the app already on the phone is an update, not a fresh
install: iOS keeps the container, so the marks and counters are still there. You
can rebuild and reinstall twenty times a day without resetting them.

Two things destroy them, and both are avoidable:

| What | Why | What protects you |
|---|---|---|
| Deleting the app from the home screen | iOS deletes the container with it | Don't. If you must, `scripts/device.sh backup` first. |
| Signing the next build as a different team | iOS refuses the update; the only way forward is to delete the app | `scripts/local.env` pins the team so it cannot drift |

## Tests

```
scripts/test.sh
scripts/test.sh --filter SessionFilterTests/lastSixMonths
```

There is no `CullTests` target in the project yet — the script says so and
stops. Add one in Xcode (**File ▸ New ▸ Target ▸ Unit Testing Bundle**, named
`CullTests`) and both the script and `make test` pick it up with no changes.
The pieces worth covering first are the ones with no UI in them:
`SessionFilter`, and `ReviewHistoryService`'s 90-day expiry of kept marks.

The simulator for a test run is resolved at run time rather than pinned, so the
same command works on a laptop and on a CI runner with different runtimes
installed.

## When something breaks

Run `scripts/doctor.sh`. It checks the toolchain, the iOS destinations, the
simulator UI app, the photo-library usage descriptions, signing, the phone, the
backups and the test target, and every failure line says what to do about it.

Three failures that read as project problems but are not:

| Message | What it actually is |
|---|---|
| `iOS NN.N is not installed` / no eligible destination | Xcode's SDK is newer than every installed runtime: `xcodebuild -downloadPlatform iOS` |
| `needs to be unlocked to enable development services` | The phone is locked. Unlock it; nothing else is wrong. |
| Installs land on the wrong phone | Two phones are paired. Set `CULL_DEVICE` to the right UDID (above). |
| `No profiles for 'mirobehninger.Cull' were found` | No Apple ID in Xcode, or an unaccepted agreement. The real reason is the line above it. |

One more that is silent rather than loud: Xcode 27 replaced Simulator.app with
DeviceHub.app, so a simulator can boot headlessly while the script reports
success and no window ever appears. `sim.sh` warns when it cannot open the UI,
and `doctor.sh` checks for the app.
