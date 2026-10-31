# SwimSet

**A swim practice maker for Debian, Android and Chromebooks.**

SwimSet is an offline-first web app for coaches and swimmers. Build a practice set
by set, let it calculate send-offs from your base pace, print a deck sheet, and run
the whole thing poolside as a rep-by-rep timer.

- No accounts, no server, no tracking — everything stays on the device.
- Installable PWA (ChromeOS, Android, desktop Chrome) and a Debian `.deb` package.
- Zero runtime dependencies and no build step: plain HTML, CSS and ES modules.

![SwimSet icon](icons/icon-192.png)

## Features

**Practice builder**
- Set types with colour accents: warm-up, pre-set, drill, kick, pull, main, sprint,
  IM, recovery, test and cool-down.
- Reps × distance, stroke, equipment, target pace, rest and notes per set.
- Automatic send-offs: target swim time + rest, rounded up to 1/5/10 seconds.
  Override with a custom send-off or mark a set as a continuous swim.
- Course support for SCY (25 yd), SCM (25 m) and LCM (50 m).
- Live totals: volume, estimated session time, reps, sets and volume by stroke.
- A "practice check" that warns about missing warm-ups/cool-downs and send-offs
  that are shorter than the target swim time.

**Pace tools**
- Send-off ladder for 25 → 500 at any base pace and rest.
- Approximate course converter (SCY ↔ SCM ↔ LCM).
- "Pace from a swim" calculator to turn a known time into a pace per 100.

**Poolside runner**
- Rep-by-rep timer with a progress ring, overall progress and elapsed time.
- Beeps at 3-2-1 and at the end of each send-off; muted with one tap.
- Optional auto-advance, previous/next/jump, fullscreen and screen wake lock.
- Big touch targets sized for a phone at the end of a lane.

**Library and sharing**
- Save, search, sort, duplicate and delete practices.
- Autosaved working draft, so a refresh never loses your session.
- Import/export JSON (single practice or the whole library), plain-text sheets,
  print-to-PDF deck sheets with tick boxes, and the native share sheet.

**Everywhere**
- Responsive phone/tablet/desktop layout, light and dark themes.
- Installable and fully offline after the first load (service worker).
- Keyboard shortcuts: `Ctrl/Cmd+S` save, `Ctrl/Cmd+P` print, `Space` start/pause
  the poolside timer, `←`/`→` previous/next rep, `?` help.

## Quick start

```bash
git clone https://github.com/mob5824m-wq/SwimSet.git
cd SwimSet
python3 -m http.server 8080     # or: make serve / npm start
# open http://localhost:8080
```

No install, no bundler. Serving over HTTP is required (rather than opening
`index.html` from disk) because the app uses ES modules and a service worker.

## Install

### Chromebook and Android (recommended)

1. Open the app in Chrome — either a hosted copy (see GitHub Pages below) or a
   local server (`http://localhost:8080`).
2. Chrome menu → **Install app** (Chromebook/desktop) or **Add to Home screen**
   (Android). The **Install** button in SwimSet's header appears when Chrome
   offers installation.
3. Launch it from the shelf/app drawer. It opens full screen and works offline.

> Service workers (and therefore offline mode) require HTTPS or `localhost`.
> Opening the files over plain HTTP from another machine will still run the app,
> but without the offline cache.

### GitHub Pages

A workflow is included at `.github/workflows/pages.yml`. In the repository,
enable **Settings → Pages → Build and deployment → Source: GitHub Actions**, then
push to `main`. The published URL can be installed as a PWA on Chromebooks,
Android and desktop Chrome.

### Debian / Ubuntu

Build and install the `.deb`:

```bash
make deb
sudo apt install ./build/swimset_1.0.0_all.deb
swimset
```

Or install the prebuilt package from `build/`. The package:

- installs the app to `/usr/share/swimset`;
- adds `/usr/bin/swimset` and an application-menu entry with icons;
- serves the app on a random `127.0.0.1` port with `python3 -m http.server` and
  opens it in a Chrome/Chromium app window (falls back to your default browser);
- depends on `python3` and recommends a Chromium-based browser.

Launch it from your applications menu or with `swimset`.

You can also use the PWA directly in desktop Chrome: serve the folder on localhost
or HTTPS, then use Chrome's install icon in the address bar.

## How send-offs are calculated

```
target swim time per rep = target pace per 100 × (distance ÷ 100)
auto send-off            = round_up(target swim time + rest, rounding step)
```

Example: 100 m at 1:40 base pace with 20 s rest → 100 + 20 = 120 s → **2:00**
send-off. A target pace on a set overrides the practice base pace for that set
only. Custom send-offs are used exactly as entered; continuous sets have no
interval, and the runner counts their estimated swim time.

Course conversions are **training estimates** (`SCY → SCM ×1.11`,
`SCY → LCM ×1.13`), not official conversions. They ignore pool depth, altitude
and timing differences.

## Data and privacy

- Practices live in this browser's `localStorage`. No network requests are made
  by the app and there is no analytics.
- Clearing site data, using private browsing, or switching browsers/devices will
  lose the library — export JSON backups from the library screen.
- Browser storage is typically capped around 5 MB, which is thousands of practices.

## Development

```
index.html               app shell
css/app.css              all styles, dark theme and print sheet
js/core.js               pure logic: model, pace maths, totals, validation, text export
js/store.js              localStorage persistence, draft, import/export
js/templates.js          built-in workouts
js/app.js                UI, routing, builder, library, pace tools, poolside runner
sw.js                    offline cache (bump CACHE_VERSION when assets change)
manifest.webmanifest     PWA metadata
icons/                   generated PNG/SVG icons
tests/                   Node tests (core, store) + jsdom UI smoke test
packaging/linux/         Debian packaging and launcher
tools/make-icons.py      icon generator (Pillow)
```

### Tests

```bash
npm install          # only needed for the jsdom UI test
npm test             # core maths, storage, templates
npm run test:ui      # boots the real app in jsdom and exercises the UI
```

The core and store tests have no dependencies; the UI test skips itself if jsdom
is not installed.

### Icons

```bash
npm run icons        # requires Pillow: python3 -m pip install Pillow
```

### Versioning

Update `version` in `package.json`, `CACHE_VERSION` in `sw.js` (when assets
change) and the version shown in the in-app help before cutting a release.

## Notes and limitations

- The app is a static client-side application; JavaScript is required.
- Send-offs assume one target pace per set. Per-lane or per-swimmer intervals are
  not modelled yet — duplicate the practice or use a custom send-off per set.
- The poolside timer counts down the estimated/send-off time. If auto-advance is
  off it stops at zero and waits for you.
- Course conversions are approximate by design.

## License

MIT — see [LICENSE](LICENSE).
