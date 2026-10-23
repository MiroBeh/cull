# Rummage — one button, fifty photos

**Rummage** is an iPhone app for clearing out the photos you do not want, and
finding the ones worth sending to a friend on the way. It opens on a storage
number and a single button. Pressing it starts a session of **50
photos drawn at random from everything you have not reviewed** — about two
minutes, with a visible end.

There is no month list, no album picker, no filter and no mode. Choosing between
"March 2026" and "September 2025" is not a decision anyone has an opinion about,
and the app does not make you make it.

---

## The flow

| Screen | What is on it |
|---|---|
| **Home** | How much storage your unreviewed photos could give back, and **Start cleaning**. Plus how much you have freed with Rummage so far. |
| **Review** | One photo, two large buttons — **Delete** and **Keep** — a thin "12 of 50" progress line, the photo's date and size, a quiet **Share** button, and Undo. |
| **Done** | How many you deleted and how much space came back, then **Clean 50 more** or **Finish for today**. |

**Deciding.** Tap Delete or Keep, or swipe the photo — left deletes, right
keeps. They are the same action: as you drag, the card tilts and follows your
finger, the decision stamps onto it past the commit point, the matching edge of
the screen washes with colour and the matching button lights while the other
dims. Let go short of the commit point and the card springs back, so a twitch
cannot delete anything. Each decision gives a short haptic tap.

**Sharing.** The Share button under the photo opens the **standard iOS share
sheet** with the full-quality image, so a photo you had forgotten about can go
to Messages, AirDrop, Mail or anywhere else — without leaving the session and
without counting as a decision.

**Deleting.** Nothing leaves the library until the session ends, however it
ends. Then iOS presents its own confirmation, and what you agreed to goes to
**Recently Deleted**, recoverable for 30 days. Rummage adds no confirmation screen
of its own — asking twice is not more careful, it is just slower.

**Remembering.** A photo you keep is left out of later sessions for 90 days,
then comes round again. Settings shows the lifetime totals, how many photos are
remembered, a reset, and a haptics toggle. Nothing else.

---

## Development

```
make doctor            # check the toolchain, signing and your phone
make sim PHOTOS=40     # run in a simulator with 40 generated photos to swipe
make test              # run the unit tests
make install           # build and install on your iPhone (backs up first)
```

The scripts behind those targets live in `scripts/`; `docs/WORKFLOW.md` explains
the loops, the signing setup and what the device backups do and do not cover.
`design/design-a.html` is the design source for the screens above.

---

## How it is put together

```
Rummage/Rummage/
├── RummageApp.swift         # wires the services and the session together
├── ContentView.swift        # onboarding gate, then Home
├── Models/
│   ├── Photo.swift          # id, date, pixel count — no PhotoKit in the logic
│   └── StorageEstimate.swift# the one place a photo's size is guessed at
├── Services/
│   ├── PhotoSource.swift    # what a session needs from the library
│   ├── PhotoLibraryService.swift
│   ├── ReviewHistoryService.swift
│   └── Haptics.swift
├── ViewModels/
│   └── SessionViewModel.swift  # the whole feature: batch, decisions, deletion
└── Views/                   # Home, Review, Done, Settings, Onboarding
Rummage/RummageTests/        # the session, driven through an in-memory library
```

`SessionViewModel` talks to the library only through `PhotoSource`, which is
what lets the tests run a whole session — 50 decisions, undo, deletion, the
90-day expiry — without PhotoKit, a simulator or a phone.

A photo's size on disk is not something PhotoKit will tell us without reading
the file, so every "freed" figure in the app is an estimate from
`StorageEstimate`. They are consistent with each other and will not match what
iOS Settings reports.

---

## Tech

- **Platform:** iPhone, portrait
- **Language:** Swift, SwiftUI
- **Photo access:** PhotoKit (`PHPhotoLibrary`), read-write
- **Permissions:** `NSPhotoLibraryUsageDescription` (read-write covers deleting)
- **Palette:** charcoal `#1A1B1F`, bone `#F4F3EF`, amber `#E3BF6F` for storage,
  green `#5FCF8A` for keep, red `#E47668` for delete. Sentence-case sans for
  anything you read; monospace for the big storage numeral and tabular figures.
