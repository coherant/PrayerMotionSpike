# Ambient Sky Birds — distant birds crossing the Prayer Times sky

> Status: **BUILT — compiles, pending on-device tuning (2026-06-28).** *Mixed*
> (lone wanderers with depth + a rare flock skein), *day-only* (fading with the
> real sun), a **reusable** `SkyBirdsView` mounted **behind Prayer Times only**.
> Lives in `SalahMotion/DesignSystem/Components/SkyBirdsView.swift`
> (`BirdSkyConfig` / `BirdShape` / `BirdFlight` / `SkyBirdsView`), mounted in
> `PrayerTimesView` with a sun-driven `birdDaylight`. The §6 numbers are starting
> points — gull shape, density, opacity, and the fade band still want a device pass.

A few birds drift across the **far distance** of the Prayer Times sky — entering
from any edge, gliding to the other side, faint but unmistakably birds. The point
is *ambient life*: the background already **is** the sky (the time-of-day theme
cross-fade, the real Sun/Moon arc in the Up Next card, the night starfield), and
a quiet bird or two makes that sky feel inhabited rather than painted.

Purely cosmetic — a **view** concern, never Core / state-machine. It reads the
clock and the sun; it owns no canonical state.

---

## 1. Concept

- **Subtle but legible as birds.** At tiny size + low opacity a literal bird
  symbol becomes a speck. The shape that universally reads as "far bird" is the
  shallow double-arc **gull silhouette** (`⌒`). That is the atom; everything else
  is how many, how they move, and depth.
- **A regular day, not a flock show.** Usually **0–3** birds on screen with long
  quiet gaps; a small **V-skein of 3–5** passes only **rarely**. Never a swarm.
- **Far away.** Small, slow, faint, tinted from the theme — they sit *behind* the
  content and are glimpsed through the open sky around the header and between the
  cards. Distance is sold by size + speed + opacity, not detail.
- **Of the daytime.** Birds belong to daylight; they thin through Maghrib and are
  gone by Isha, leaving the night to the starfield (see §5).

---

## 2. Placement & layering

`SkyBirdsView` is a full-screen layer in the Prayer Times `ZStack`, **above** the
gradient background and **below** the content:

```
ZStack {
    blend.background.ignoresSafeArea()   // the sky
    SkyBirdsView(...)                    // ← birds, here
    VStack { header; upNextCard; prayerList; ctaButton }   // content (opaque-ish)
}
```

- Birds therefore pass **behind** the Up Next card / list (occluded there) and
  show only in genuine sky — which is exactly the "far back" read we want. No clip
  of their own; they simply live behind the fixtures.
- **Never above content.** They must not cross over text or compete for legibility.
- Independent of the Up Next card's celestial clip authority (that is the Sun/Moon
  complication — see [celestial-complications.md](celestial-complications.md)).
- **Feature flag.** When `BirdSkyConfig.isEnabled` is `false`, `SkyBirdsView`
  short-circuits to `EmptyView` (no `TimelineView`, no scheduler, zero cost) — the
  mount stays in place so re-enabling is a one-line flip.

---

## 3. Motion model — a pure function of time

Same discipline as the celestial arc: **position is `f(now)`**, never an
implicit/explicit tween. This is what kept the sun from stuttering — see
celestial-complications.md §8 — and it means leaving and returning to the tab is
always instantly correct.

Each bird is a **`BirdFlight`** value:

| field | meaning |
|---|---|
| `spawn` | absolute `Date` it appears |
| `cross` | seconds to traverse (far birds slower) |
| `start` / `end` | off-screen entry & exit points (any edge → across) |
| `layer` | depth 0 (far) … 2 (near) → size / opacity / speed |
| `bobAmp`, `bobPeriod`, `bobPhase` | gentle sine drift perpendicular to travel |
| `flapPeriod`, `flapPhase` | wing-flap cycle |
| `flock` | nil for a lone bird, else its slot in a skein |

Render at time `t`:
- `p = (t − spawn) / cross`, clamped; **cull** when `p > 1`.
- Base point = `lerp(start, end, easeInOutVeryGentle(p))` (near-linear; a hair of
  ease so entries/exits don't feel mechanical).
- Add bob: offset perpendicular to travel by `bobAmp · sin(2π·t/bobPeriod + bobPhase)`.
- **Wing-flap** = 2-pose silhouette lerp (wings level ↔ wings up) by
  `0.5 + 0.5·sin(2π·t/flapPeriod + flapPhase)`; small amplitude. Far layer may
  skip the flap (a static `⌒`) since the motion isn't perceptible at that size.

**Spawning** (kept off the render path): a lightweight scheduler on the existing
1 Hz tick culls finished flights and, when `now ≥ nextSpawn`, appends a randomized
lone bird (and, with a small probability, a flock), then rolls `nextSpawn` forward
by a randomized gap. Respects `maxConcurrent`. Flights live in `@State`; the
`TimelineView` only **reads** them.

**Frame source:** `TimelineView(.animation(paused: !isActive))`, with
`isActive = (router.selectedTab == .prayerTimes) && (scenePhase == .active)` —
identical gating to the celestial view, so off-tab / backgrounded it stops
requesting frames.

---

## 4. Composition — depth & the rare flock

- **Lone wanderers (the staple).** Most of the time, single birds across 3 depth
  layers. Layered size/opacity/speed gives real parallax from a handful of shapes.
- **Flock (the treat).** Rarely, a loose **V of 3–5** sharing one path with small
  per-bird position + flap-phase offsets, so it ripples rather than marching in
  lockstep. Passes as one event, then quiet again.
- A bird picks its **edge** at random (any side) and exits roughly opposite, with
  enough vertical spread that they don't all run the same line.

---

## 5. Day-fade — tied to the real sun

Birds' **overall opacity scales with a daylight factor** so they and the sky stay
in lockstep:

- Source the factor from the **same `SolarEphemeris`** the arc uses — drive it off
  the sun's altitude / `dayPhase`: full strength while the sun is well up, easing
  down through Maghrib, **zero at night**. (`smoothstep` over the horizon band so
  it fades rather than snaps.)
- Because it's the *real* sun, the fade is automatically correct for date,
  location, and hemisphere — no separate clock.
- **Spawning also tapers**: as daylight → 0, new birds stop being scheduled, so the
  sky empties naturally instead of freezing a few faint birds in place.

**Egg interaction:** birds keep their **own** clock — they're weather, not the
timepiece. The time-machine rewind sweeps the sun + theme + Up Next, but birds
keep flying forward. (Flip to swept later if it feels disjoint.)

---

## 6. Tunables (`BirdSkyConfig`)

One enum of starting points, à la `TimeMachineConfig` (only ratios/feel matter;
tune on device). The first knob is a **master feature flag** — a plain static
`Bool` in code (not a user-facing setting) so the whole feature can be muted
without unwiring it:

| knob | start |
|---|---|
| `isEnabled` | `true` — flip to `false` to disable the feature entirely |
| `maxConcurrent` | 3 |
| `wingspan` by layer | 6 / 9 / 13 pt |
| `opacity` by layer | 0.10 / 0.14 / 0.18 (× daylight factor) |
| `crossDuration` | 18–40 s (far → near) |
| `bobAmplitude` / `bobPeriod` | 4–10 pt / 3–6 s |
| `flapPeriod` | 0.5–0.9 s |
| `loneSpawnGap` (mean) | ~14 s (randomized) |
| `flockChance` | rare (~1 per few min) |
| `tint` | theme `ink` |

---

## 7. Build order

1. **`BirdShape`** — the gull `Path` (a `flap: Double` parameter morphs the two
   wing strokes). Static preview first; verify it reads as a bird at 6–13 pt.
2. **`BirdFlight`** value + pure `point(at:in:)` / `flap(at:)` — the `f(now)` math.
   Pure, trivially testable (cull boundary, perpendicular bob).
3. **`SkyBirdsView`** — `GeometryReader` → `TimelineView(.animation(paused:))`,
   renders the current `[BirdFlight]`; takes `isActive`, `tint`, `daylight`.
4. **Scheduler** — 1 Hz cull + randomized spawn (lone, rare flock), `maxConcurrent`,
   daylight taper.
5. **Daylight factor** — derive from `SolarEphemeris` (sun altitude / `dayPhase`).
6. **Mount** behind Prayer Times content (gated by `BirdSkyConfig.isEnabled`);
   confirm it never overlaps text and is occluded by the cards as intended.
7. **Tune on device** (iPhone 11 — not the simulator, per the header-layout
   lesson): density, opacity, speed, the gull shape, and the fade band.

---

## 8. Open decisions

- Exact gull silhouette (wing sweep, flap amplitude) — a quick visual pass.
- Does the rare flock ever appear at dawn/dusk specifically, or any daylight hour?
- Whether birds should also sit behind Calibration / Prayer Setup later (built
  reusable so it's a one-line mount).
- Egg: keep birds on their own clock (default) vs. sweep them with the rewind.

---

## Related
- [celestial-complications.md](celestial-complications.md) — the Sun & Moon arc in
  the Up Next card (the §8 "position = f(now)" discipline this reuses; the shared
  `SolarEphemeris` the day-fade reads).
- [../../design-reference/theme.md](../../design-reference/theme.md) — the
  time-of-day theme blend the tint and fade live alongside.
- `SalahMotion/Features/PrayerTimes/PrayerTimesView.swift` — mount point (the
  background `ZStack`).
- `SalahMotion/Core/Celestial/SolarEphemeris.swift` — daylight source.
