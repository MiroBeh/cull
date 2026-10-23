# Spec — Simplify Rummage to Design A ("One Button")

Status: ready for agent
Prototype: branch `prototype/simpler-app`, open `design/simple-prototype.html?variant=A`

## Problem Statement

Rummage makes you make decisions before it lets you do anything.

Open the app and the home screen asks you to choose: a Continue card for the
month you were last in, a Shuffle button, and a list of months — eight of them
by default, each with its own count, progress bar and bytes-freed figure, with
a disclosure control to show the rest. Choosing between "March 2026" and
"September 2025" is not a choice anyone has an opinion about, but you cannot
reach a single photo without making it.

Inside a session the density continues: a per-month title, a monospace
progress line, side rails, and a strip of coloured dots recording every
decision you have made. A session has no defined end — it is however many
unreviewed photos exist in the bucket you picked, up to 500 — so there is no
moment where you are finished, only a moment where you give up. The app then
asks you to confirm deletion on its own screen, before iOS asks you the same
question again.

And when the app does its best work — surfacing a photo you had completely
forgotten about — the only two things you can do with it are keep it and
delete it. The natural reaction, sending it to the person who is in it, is not
available.

## Solution

Rebuild the app as Design A, "One Button", validated in the prototype.

Home is a storage number and one button. There is no month list, no album
picker, no filter and no mode: pressing **Start cleaning** begins a session of
exactly **50 randomly chosen unreviewed photos** — about two minutes, with a
visible end.

Review is one photo and one question. Two large labelled Delete and Keep
buttons sit in the thumb zone; swiping the card still works and is now
visibly the same action as the buttons — as you drag, the card tilts, a
decision badge stamps onto it, the matching edge of the screen washes with
colour, and the matching button lights while the other dims. A thin progress
bar and a plain "12 of 50" replace the dot strip.

Under the photo, next to its date and size, sits a quiet **Share** button. It
opens the **standard iOS share sheet** — the system one, not a reimplementation
— so a forgotten photo can go to Messages, AirDrop, Mail or anywhere else the
system offers, without leaving the session.

When the 50 are done, a summary says how many were deleted and how much space
came back, and offers **Clean 50 more** or **Finish for today**.

Everything that made Rummage a browser of your library rather than a one-button
cleaner is removed, and the documentation is rewritten to describe only this
app.

## User Stories

**Starting**

1. As someone with a full phone, I want to see how much space I could free as the first thing on the screen, so that I know why I opened the app.
2. As someone with a full phone, I want a single button to start cleaning, so that I do not have to decide where to start.
3. As a returning user, I want to see how much space I have freed with the app so far, so that I feel the effort has added up.
4. As a user who presses Start, I want a session of exactly 50 photos, so that I know roughly how long this will take.
5. As a user who presses Start, I want to be told up front that a session is 50 photos and about two minutes, so that I can decide whether I have time now.
6. As a user with a large library, I want the 50 photos to be drawn at random from everything I have not reviewed, so that I keep running into photos I had forgotten about.
7. As a user with fewer than 50 unreviewed photos left, I want a shorter session rather than an error, so that I can still finish the library.
8. As a user who has reviewed everything, I want the home screen to tell me I am done instead of offering a Start button that does nothing, so that I am not confused.
9. As a first-time user, I want to be told what the app does and asked for photo access before anything else, so that I understand what I am agreeing to.
10. As a user who declined photo access, I want a clear way to grant it later, so that I am not stuck on a dead screen.
11. As a user who granted limited photo access, I want the app to work with the photos I did share, so that I am not forced into full access.

**Reviewing**

12. As a reviewer, I want to see one photo at a time filling most of the screen, so that I can judge it without squinting.
13. As a reviewer, I want to see where I am in the session ("12 of 50"), so that I know how much is left.
14. As a reviewer, I want to see how much space I have freed so far in this session, so that I get feedback while I work.
15. As a reviewer, I want two large labelled buttons for Delete and Keep, so that I can decide without learning a gesture first.
16. As a reviewer, I want to swipe the photo left or right as an alternative, so that I can go quickly once I know the app.
17. As a reviewer mid-swipe, I want the card to tilt and follow my finger, so that the app feels responsive.
18. As a reviewer mid-swipe, I want a Keep or Delete badge to stamp onto the card once I pass the commit point, so that I know what will happen if I let go.
19. As a reviewer mid-swipe, I want the edge of the screen I am dragging toward to wash with the matching colour, so that the target is obvious.
20. As a reviewer mid-swipe, I want the matching button to light up and the other to dim, so that I learn that the gesture and the buttons do the same thing.
21. As a reviewer who starts a swipe and changes their mind, I want the card to spring back if I let go before the commit point, so that I cannot delete something by twitching.
22. As a reviewer, I want a short haptic tap when a decision registers, so that I can keep my eyes on the photo.
23. As a reviewer, I want to see the photo's date and size under it, so that I have the context I need to decide.
24. As a reviewer who makes a mistake, I want to undo my last decision, so that one slip does not cost me a photo.
25. As a reviewer, I want undo to be available but visually quiet, so that it does not compete with the decision I am making.
26. As a reviewer, I want to leave a session part-way through, so that I am not trapped in 50 photos I do not have time for.
27. As a reviewer who leaves early, I want the photos I already deleted to still be deleted, so that the work is not wasted.

**Sharing**

28. As someone who finds a photo they had forgotten about, I want to share it without leaving the session, so that I can send it to a friend in the moment.
29. As a sharer, I want the normal iOS share sheet, so that every destination, person and app I already use is there.
30. As a sharer, I want the full-quality photo to be shared, so that the person receiving it does not get a thumbnail.
31. As a sharer, I want to land back on the same photo with no decision made when the sheet closes, so that sharing is not accidentally a vote to keep.
32. As a reviewer, I want the Share button to be quieter than Delete and Keep, so that the main decision stays obvious.

**Finishing**

33. As a user who finishes 50 photos, I want to be told how many I deleted and how much space I freed, so that the session feels worth it.
34. As a user who finishes, I want a button to clean 50 more, so that I can keep going when I am in the mood.
35. As a user who finishes, I want an equally easy way to stop, so that the app does not nag me.
36. As a user who deletes photos, I want iOS to ask me to confirm before anything is removed, so that I trust the app with my library.
37. As a user who deletes photos, I want them to go to Recently Deleted, so that I have 30 days to change my mind.
38. As a user who kept a photo, I do not want to be shown it again in a later session, so that I make progress.
39. As a user, I want my kept decisions to eventually expire, so that a photo I kept years ago can be reconsidered.

**Settings and housekeeping**

40. As a user, I want to see my lifetime photos deleted and space freed, so that I can see the long-run payoff.
41. As a user, I want to reset my review history, so that I can start over.
42. As a user, I want to turn haptics off, so that the app is usable when I need it silent.
43. As a user, I do not want settings for things the app no longer does, so that the settings screen stays short.

**Documentation**

44. As a new contributor, I want the README to describe the app as it is now, so that I do not build a feature that was removed.
45. As a new contributor, I want the design sources to show only Design A, so that I do not implement a screen from the old design.
46. As a contributor, I want `make test` to actually run tests, so that I can check my change.

## Implementation Decisions

### Session model

- A **session** is a fixed batch of 50 photos, chosen at random from the
  photos the user has not reviewed. Random was chosen over oldest-first and
  largest-first because the forgotten-photo moment — the thing the new Share
  button exists to serve — depends on the grab-bag feel.
- The batch size is one named constant, not a user-facing setting.
- Photo selection moves behind a single call on the photo-library service that
  takes a limit and the review history and returns the batch. The existing
  shuffle walk is the basis: it iterates a shuffled index list over a lazy
  fetch result and skips kept photos, so it never materialises the library.
- `SessionFilter` and `MonthBucket` are deleted outright, along with the
  month-bucket and album fetches on the photo-library service. Nothing
  parameterises a session any more, so navigation to the review screen no
  longer carries a value.
- If fewer than 50 unreviewed photos exist, the session is however many are
  left. If none are left, the home screen shows a finished state in place of
  the Start button.

### Review screen

- The decision surface is: thin progress bar with "N of 50" and session bytes
  freed; the photo; a metadata row with date and size on the left and the
  Share button on the right; the two large action buttons; a hint line
  carrying Undo.
- The dot-strip decision history, the side rails, the per-month title and the
  End button are removed.
- Drag states, taken from the prototype, bind the gesture and the buttons to
  the same model:

  | Drag state | Card | Screen edge | Buttons |
  |---|---|---|---|
  | At rest | centred | none | both normal |
  | Dragging, below commit | follows finger, tilts with distance | matching edge washes, strength tracks distance | matching button brightens |
  | Dragging, past commit | tilted, decision badge stamped on | wash at full strength | matching button lit, other dimmed |
  | Released past commit | flies off, decision recorded | clears | reset |
  | Released below commit | springs back, no decision | clears | reset |

- A minimal exit affordance stays on the review screen. The prototype's review
  artboard has no way out, which cannot ship — see Further Notes.

### Sharing

- Share uses the **system share sheet**. No custom sheet, no contact row, no
  app row, no favourite/album/copy list — the prototype's share artboard was a
  sketch of what iOS already provides, and is not to be built.
- Implemented with SwiftUI's first-party share control, which is available on
  the project's minimum iOS version. It is given the full-size image, which
  means requesting image data for the asset rather than the display thumbnail.
- Sharing records no decision. Dismissing the sheet returns to the same photo
  in the same state.

### Deletion

- The in-app confirmation screen is removed. PhotoKit presents its own system
  confirmation when an app deletes assets it did not create, so the current
  flow asks the same question twice. The system prompt plus Recently Deleted's
  30-day window is the safety net. (If device testing shows the system prompt
  is not presented in some path, restore a single confirmation rather than
  shipping a silent delete.)
- Deletion happens when the session ends, whether it ended by reaching the end
  of the batch or by the user leaving early.
- The two different storage estimates in the code today — a flat per-photo
  figure in one place and a pixel-count formula in another — are replaced by
  one estimator used everywhere, so the figure on the review screen, the done
  screen and the lifetime total agree.

### Home, done and settings

- Home is: wordmark and settings control; recoverable-storage figure with a
  one-line explanation; Start button; the session-length line; the lifetime
  freed line. The Continue card, the Shuffle call to action, the month list
  and its collapse control all go.
- The done screen replaces the current summary: count deleted, space freed,
  **Clean 50 more** as the primary action, **Finish for today** as the quiet
  one. Its per-month framing goes.
- Settings keeps lifetime stats, kept-count with reset, and the haptics
  toggle. The confirm-before-delete and show-metadata toggles are removed —
  the first no longer has anything to govern, the second describes a row that
  is now always shown.
- The review-history service is unchanged in behaviour: it still records kept
  photos with a 90-day expiry and accumulates lifetime totals.

### Typography and tone

- The palette is unchanged. The type system shifts with Design A: sentence-case
  sans for anything the user reads, monospace reserved for the large storage
  numeral and tabular figures. The small uppercase tracked labels used
  throughout the current screens are dropped.

### Documentation and dead code

- README is rewritten to describe this app: the one-button flow, 50-photo
  random sessions, swipe plus buttons, system sharing, and the real palette.
  The MVP checklist, and the planned-features list (swipe up/down, album
  moves, smart suggestions, date/album filters, batch mode, stats dashboard)
  are removed rather than left as promises the design has abandoned.
- `docs/WORKFLOW.md` is updated where it describes what the tests cover.
- The design sources are reduced to Design A. The prototype's B and C variants
  do not come across to this branch; they stay on `prototype/simpler-app`.
- The duplicate `Views/`, `Models/`, `ViewModels/` and `Services/` directories
  that sit one level above the real sources are deleted. They are leftovers
  from the first scaffold, are outside the Xcode project's synchronised root,
  and describe the old flow.

## Testing Decisions

A good test here states something a user would notice and would survive the
screens being rebuilt: after 50 decisions the session is complete; undo puts
the photo back; a kept photo does not come round again. Tests that assert
which method was called, or reach into view state, are not wanted.

- **One seam: the session view model.** The whole feature is driven through it
  with an in-memory fake standing in for the photo library, so no test touches
  PhotoKit. This requires introducing a protocol for the photo source and
  having the real service conform to it — the view model currently takes the
  concrete service.
- Covered through that seam: a session contains at most 50 photos; a shorter
  library yields a shorter session; keep and delete advance and sort correctly;
  undo restores the previous photo and reverses its effect, including the kept
  record; undo at the start does nothing; completion is reached exactly at the
  end of the batch; ending early preserves decisions already made; the storage
  estimate and lifetime counters add up across sessions; kept photos are
  excluded from later sessions and reappear after the 90-day expiry.
- **Not tested:** the review UI, the drag thresholds, the share sheet and the
  system delete prompt. These are verified by hand with the simulator loop.
- **Prior art: none — these are the project's first tests.** The harness is
  already waiting for them: the test script and `make test` look for a
  `RummageTests` unit-test bundle and currently stop with instructions to create
  one, and `docs/WORKFLOW.md` already documents the loop. Creating that target
  is part of this work.

## Out of Scope

- Any new way of choosing what to review. No albums, no date filters, no
  smart suggestions (duplicates, blurry, screenshots), no media-type picker.
  Removing these is the point of the spec; re-adding one in a different shape
  is a separate decision.
- The other prototype directions. B ("Daily Pile" — streaks, daily piles,
  plain-language collections) and C ("Grid Tap" — multi-select grid) are not
  being built. They remain on the prototype branch if the direction is
  revisited.
- Videos. The app reviews images only today and continues to.
- A true recoverable-storage figure. The home number stays an estimate derived
  from a per-photo average; computing real asset sizes across a library is a
  separate piece of work.
- iCloud, iPad, widgets, notifications and any reminder to come back — Design A
  deliberately has no nagging.
- Swipe up to favourite and swipe down to album. With Share taking the "this
  one is special" role, these have no obvious job left.
- Changing the app icon, the onboarding illustrations or the launch experience
  beyond the copy updates described above.

## Further Notes

**The prototype's review screen has no way out, and the real one needs one.**
Across five artboards, Design A never shows how to leave a session in progress.
This is a genuine gap in the prototype rather than a deliberate choice, and it
cannot ship that way — a user who starts 50 photos by accident must be able to
stop. The spec therefore keeps a minimal exit control on the review screen;
its exact form is the implementer's call, and the prototype offers no guidance
to follow.

**Sharing is the one genuinely new capability.** Everything else in this spec
is removal or rearrangement, so if the work needs to be staged, the removal
and the 50-photo session model stand on their own, and Share can follow.

**The random order has a known cost.** Unlike the old month list, a random
session gives no sense of working through the library in order, and a user
may see photos from the same era twice across sessions. This was chosen
knowingly in exchange for the forgotten-photo moment; the home screen's
unreviewed count and lifetime freed figure are the only progress signals left,
which makes them more important than they were.

**Deletion estimates are approximate and will visibly be so.** Until real
asset sizes are computed, the "freed" figures on the review and done screens
are estimates, and a user who checks iOS Settings afterwards will find they do
not match. Keeping one estimator everywhere at least makes the app
self-consistent.
