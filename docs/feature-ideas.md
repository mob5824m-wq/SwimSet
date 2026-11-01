# SwimSet — 30 feature ideas

A backlog of things worth building next, kept in the app's own language (practices,
heats, send-offs, deck sheets). Effort is for one developer with the current CI in
place: **S** ≈ a day, **M** ≈ a few days, **L** ≈ a week or more.

---

## Building practices

**1. Set blocks / rounds.** ✅ *Shipped — group neighbouring sets and pick the round count.* Group sets into a block and repeat it ("3 × [4×50 kick + 200 pull]"). Blocks nest inside the practice and get their own volume and time, so 5-round sets stop being copy-paste. `M`

**2. Drag to reorder, move between practices.** Reorder sets by dragging on desktop/tablet, and a clipboard so a set can be copied from one practice to another. `S`

**3. Drill & set bank.** A searchable library of common drills, kicks and pre-sets (catch-up, 6-kick switch, descend 4×100…) that drops into the draft with sensible strokes and distances. `M`

**4. Parametric templates.** Instead of fixed 2,800 m templates: "Distance Base, target 3,500 m, 50 m pool" and the template scales its reps/distance while keeping the shape. `M`

**5. Volume balance with targets.** A small stacked bar of warm-up / drill / kick / main / cool-down against targets you set per practice, plus a nudge when the main set is 85 % of the session. `S`

**6. Per-heat manual send-offs.** ✅ *Shipped — each set has a send-off row per heat.* Heats currently get automatic send-offs from their pace. Let a heat override a specific set ("Heat 3 starts this set on 2:15") without changing its base pace. `S`

**7. Mixed-course practices.** A session that is half SCM and half LCM (or a 25 yd warm-up and a 50 m main set), with the send-off maths converting per set rather than per practice. `M`

**8. Session length targets.** "Make this fit 75 minutes" — the builder suggests rep/set changes and shows what to trim, instead of you re-adding numbers by hand. `M`

## Squad and heats

**9. Lane assignments.** Give each heat lanes ("Heat 2: lanes 3–5, 6 swimmers") and print the assignment on the deck sheet and the poolside strip. `S`

**10. Swimmer roster and attendance.** A local roster, tap-to-attend before the session, and attendance history per practice. `M`

**11. Per-swimmer pace benchmarks.** Store a 100 time or CSS per swimmer; heats can then be built from benchmarks ("fast / middle / base") and send-offs follow the group's pace automatically. `M`

**12. Arbitrary per-heat start offsets.** ✅ *Shipped — every heat has a "Starts at" field.* Today heats stagger by a fixed interval. Allow "Heat 1 at 0:00, Heat 2 at 1:10, Heat 3 at 3:00" for sessions where the send times are not evenly spaced. `S`

**13. Race-day mode.** Start lists per heat, lane and name, with a results entry screen (time, place, DQ) and a results export — the poolside timer becomes a meet sheet. `L`

**14. Auto heat builder.** "24 swimmers, 6 lanes, 3 heats" → proposes heat and lane splits by pace and lets you drag names between heats. `M`

## Poolside and timing

**15. Split timer with capture.** Tap to record each rep's actual time alongside the send-off; the session summary shows fastest/slowest/average per set and exports as CSV. `M`

**16. Voice callouts.** Spoken cues on top of the beeps: "Heat 2, 4 × 100 free on 1:55 — go", "last rep", "30 seconds". Uses the platform text-to-speech, fully offline. `M`

**17. Background timer with notification controls.** ✅ *Shipped (Android foreground service); notification play/pause/next is still to come.* On Android, keep the timer and beeps running when the screen is locked or the app is backgrounded, with play/pause/next in the notification. `M`

**18. Distinct sounds per event.** Separate, chooseable tones for 3-2-1, the send-off, a heat send and the end of the session; import your own whistle or beep. `S`

**19. Big-clock session mode.** A full-screen running clock plus the send-off table for the whole session — useful on a poolside tablet where one heat matters less than the clock. `S`

**20. Coach remote.** The deck tablet shows the clock; the coach's phone connects over local Wi-Fi (no cloud) to pause, start heats and jump reps. `L`

**21. Watch companion.** Wear OS app or tile that mirrors the current heat's countdown and can pause/send, with the phone as the source of truth. `L`

## Library and data

**22. Undo / redo.** An in-memory history stack for the draft (set deleted, heat removed, practice replaced) with Ctrl/Cmd+Z, instead of relying on the one-step snackbar undo. `S`

**23. Folders, tags and favourites.** Group practices by squad/season, pin favourites, and filter the library by tag plus the existing search. `S`

**24. Import existing practices.** Paste a plain-text practice ("4x100 free on 2:00, 8x50 kick on 1:15…") and parse it into sets, with a review screen before it replaces the draft. `M`

**25. Automatic backups.** Write a dated JSON backup to a chosen folder on every save (or daily), keep the last N, and restore from the library screen without a file picker. `M`

**26. Encrypted export.** Passphrase-protected JSON so a practice can be shared or stored on a shared device; same import path with a passphrase prompt. `S`

**27. Device-to-device handoff by QR.** Show a QR code containing a compressed practice; the other phone scans it in-app and opens the practice — no files, no network. `M`

## Print and share

**28. More print layouts.** Beyond the A4 deck sheet: lane cards (one per heat, large type), a one-page session summary for the club noticeboard, and a large-font poolside sheet. `M`

**29. Android share sheet.** Send the PDF or JSON to Drive, mail or chat via the system share intent instead of saving into app storage first. `S`

**30. Accessibility and keyboard pass.** Screen-reader labels on the builder controls and timer, larger text scaling without overflow, a colorblind-safe set-type palette, and desktop shortcuts (Ctrl/Cmd+S save, Space start/pause, ←/→ rep, H heat). `S`

---

## Shipped from this list

- **#1 set blocks** — grouped sets repeat through the totals, deck sheet and
  poolside plan.
- **#6 per-heat manual send-offs** and **#12 arbitrary heat start offsets** — the
  heats feature is complete without leaving the builder.
- **#17 background timer** — on Android a foreground service keeps the countdown
  and its beeps running with the screen off. Play/pause from the notification is
  the remaining piece.

The next three worth building: **#2 drag to reorder**, **#9 lane assignments** and
**#5 volume balance with targets**.

## Platform ideas beyond the 30

- **iOS build** from the same Flutter code (no new UI, just the runner and signing).
- **French (fr-CA) localisation** — Montréal-first, all strings already live in one
  place in Dart.
- **Android home-screen widget** showing the next practice and a one-tap "Start
  poolside" quick action.
- **Season planner**: a calendar of practices with weekly volume targets and an
  attendance log per session.

---

## Why the download is being flagged

Two separate warnings get confused here:

1. **The Actions artifact is a ZIP.** GitHub wraps every workflow artifact in a zip;
   browsers and Windows Defender/SmartScreen treat archives containing an `.apk`
   or an unknown binary as suspicious. The **Release assets are not zipped** — use
   those links directly:
   - `…/releases/download/v2.0.0/swimset-2.0.0-universal.apk`
   - `…/releases/download/v2.0.0/swimset_2.0.0_amd64.deb`
2. **The APK is debug-signed.** CI signs with the Flutter debug key because no
   release keystore is stored in the repository, so Android Play Protect shows
   "unsafe app blocked" / "unknown developer" until you allow it. The `.deb` is not
   flagged by Debian tooling.

Ways to make downloads boring again, in order of value:

- publish a `SHA256SUMS` file next to the binaries (CI can generate it in seconds);
- sign the APK with a real release keystore kept in a CI secret (`key.properties` +
  `apksigner`), so the same key signs every build and Play Protect stays quiet;
- sign the `.deb` with `debsigs`/`dpkg-sig` and ship the public key;
- keep zip archives for source only, never for installers.
