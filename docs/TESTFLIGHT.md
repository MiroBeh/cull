# Releasing Rummage to TestFlight

The goal: friends get an email invite, install Rummage through the TestFlight
app, and send feedback. They are **external testers**, so the first build has
to pass Apple's Beta App Review (usually under a day). Builds after that with
the same version often skip review.

Tick the boxes as we go.

## Where the project stands

| Item | Current value | Status |
|---|---|---|
| Bundle ID | `com.mirobehninger.rummage` | ok, must match the App Store Connect record |
| Team | `MT23DRL63Z`, automatic signing | check that it is the **paid** team (step 1) |
| Version / build | `MARKETING_VERSION = 0.1.0`, `CURRENT_PROJECT_VERSION = 1` | ok for the first upload; bump the build number on every upload |
| Devices | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) | ok |
| Minimum iOS | 26.2 | testers need iOS 26.2 or later |
| App icon | single 1024×1024 PNG | ok if it has no transparency (alpha channel) |
| Photo permission text | `NSPhotoLibraryUsageDescription` is set | ok |
| Encryption declaration | `ITSAppUsesNonExemptEncryption = NO` | done |
| Privacy manifest | `Rummage/Rummage/PrivacyInfo.xcprivacy` | done |

## 1. Apple Developer Program

- [x] Join the Apple Developer Program (99 USD/year) at
      <https://developer.apple.com/programs/>. A free account cannot use TestFlight.
- [x] Check that team `MT23DRL63Z` is the paid team: Xcode → Settings →
      Accounts. A free "Personal Team" also has an ID, so look for the team
      name and the "Agent" or "Admin" role, not "(Personal Team)".
- [x] Accept any pending agreements in App Store Connect → Business. Uploads
      fail until the latest Program License Agreement is accepted.

## 2. Create the app in App Store Connect

<https://appstoreconnect.apple.com> → Apps → **+** → New App.

- [x] Platform: iOS
- [x] Name: Rummage. The name has to be unique on the App Store. If it is
      taken, pick a variant; the name on the home screen can stay "Rummage".
- [x] Primary language
- [x] Bundle ID: `com.mirobehninger.rummage`. If it is not in the list, add it
      at developer.apple.com → Identifiers → + → App IDs (Explicit). A build
      does not register it: with no capabilities, Xcode signs with the
      wildcard team profile.
- [x] SKU: anything unique to you, e.g. `rummage-ios`
- [x] User access: Full Access

## 3. Project changes before the first upload

- [x] **Export compliance.** Rummage uses no encryption beyond what iOS
      provides, so add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` to
      the Rummage target's build settings (Debug and Release). Without it, App
      Store Connect asks the question again for every build and holds the
      build until you answer.
- [x] **Privacy manifest.** `UserDefaults` is a "required reason" API, so the
      upload gets a warning (and later a rejection) without one. Add
      `Rummage/Rummage/PrivacyInfo.xcprivacy` to the app target with:
      - `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1` (the app
        reads and writes its own settings)
      - `NSPrivacyTracking` = false, no tracking domains, no collected data
- [x] **App icon.** Check that the 1024 PNG has no alpha channel:
      `sips -g hasAlpha Rummage/Rummage/Assets.xcassets/AppIcon.appiconset/rummage-icon-1024.png`
- [x] **Release build check.** `make install RELEASE=1`, then go through the
      main flow on the phone once in the Release configuration.
- [x] `make test` passes.

## 4. Archive and upload

In Xcode:

1. [x] Scheme **Rummage**, destination **Any iOS Device (arm64)**.
2. [x] Product → **Archive**.
3. [x] In the Organizer window: **Distribute App** → **App Store Connect** →
       Upload. Leave automatic signing and "Upload your app's symbols" on.
4. [ ] Wait for the email saying the build has finished processing (5–30 min).
       It then shows up under the app's **TestFlight** tab.

For every later upload, raise `CURRENT_PROJECT_VERSION` (2, 3, …). App Store
Connect rejects a build number it has already seen for the same version.

## 5. Test information (needed for external testers)

App Store Connect → the app → TestFlight → **Test Information**:

- [ ] Beta app description: what Rummage does in two or three sentences
- [ ] Feedback email: the address testers' screenshots and comments go to
- [ ] Privacy policy URL. Apple asks for one when external testers are added.
      Use <https://github.com/MiroBeh/rummage/blob/main/docs/PRIVACY.md>
      (live once `docs/PRIVACY.md` is merged to `main`).
- [ ] Beta App Review information: contact name, phone, email. No sign-in, so
      no demo account.
- [ ] Review notes. Spell out the deletion, since that is what a reviewer
      will look at in a photo-deleting app: the app asks for photo library
      access, the user swipes to keep or delete, iOS shows its own
      confirmation before anything is deleted, and deleted photos go to the
      Recently Deleted album for 30 days.
- [ ] "What to Test" text for this build: the flows you want feedback on.

## 6. Invite friends by email

TestFlight tab → **External Testing** → **+** → new group, e.g. "Friends".

- [ ] Add the build to the group. The first build goes to Beta App Review
      here; the status changes to "Ready to Test" once it is approved.
- [ ] Add testers: **+** → Add New Testers → name and email of each friend
      (up to 10,000). The email has to be the one they will open the invite
      on; it does not have to be their Apple ID.
- [ ] Optional: turn on a **Public Link** for the group instead, and send the
      link in a chat. Nobody's email address needed, and you can cap the
      number of testers.

What your friends do:

1. Install **TestFlight** from the App Store on their iPhone (iOS 26.2 or later).
2. Open the invite email on the iPhone and tap **View in TestFlight**, or open
   the public link, then tap **Accept** and **Install**.
3. Send feedback with a screenshot (the TestFlight share sheet), or from the
   TestFlight app. It shows up under TestFlight → Feedback in App Store
   Connect, along with crash reports.

Each build expires after **90 days**. Upload a new one before that if testing
goes on longer.

## 7. Each new beta build

1. [ ] Raise `CURRENT_PROJECT_VERSION`
2. [ ] `make test`, then Archive → Distribute (step 4)
3. [ ] Add the build to the "Friends" group with a "What to Test" note.
       Testers with automatic updates on get it right away; the rest get a
       notification.

## Open questions

- Which email goes on the feedback address and the review contact?
- Lower the minimum iOS below 26.2 so friends on older iPhones can test?
