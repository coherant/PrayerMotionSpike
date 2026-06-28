# SalahMotion — "Colours Throughout the Day" Theme System

The app re-skins itself to the **light of each prayer's hour**. This document is
the authoritative colour + theme spec across ALL screens so Claude Code can
reproduce it identically.

There are two layers:
1. **Atmospheric themes** — full-bleed per-prayer gradients used on all
   prayer-facing screens (welcome/entry, **Prayer Times**, dashboard, in-prayer
   motion, and **Guided Prayer Setup**). These screens re-skin entirely to the
   current prayer's gradient — background, text, and accent all shift.
   At app launch, the gradient matches the current time-of-day prayer.
2. **Chrome theme** — a constant calm dark-indigo shell used on true utility
   screens only (Qibla, Path, Settings), which only borrows each
   prayer's **accent** colour.

---

## 0. Global neutrals & chrome

### Chrome (utility screens) background
`linear-gradient(180deg, #1a1730 0%, #131120 60%, #100e1b 100%)`

> **Note:** Guided Prayer Setup is NOT a chrome screen. It uses the full
> atmospheric per-prayer gradient, updating in real time as the user
> selects a prayer. Text tokens also switch (Dhuhr uses dark ink on its
> light sky gradient). Only Qibla, Path, and Settings use chrome.

### Chrome text ramp (on the dark shell)
| Token | Value | Use |
|---|---|---|
| ink | `#f4f1fa` | primary text |
| muted | `#b8b2c8` | secondary |
| faint | `#847e98` | labels, tertiary |
| dark-on-accent | `#16142a` | text/icons on accent fills |
| card bg | `rgba(255,255,255,0.035)` | resting card |
| card border | `rgba(255,255,255,0.07)` | resting card border |

### Gallery / artboard background (the showcase page only, not in-app)
`#e7e5df`; section captions `#8a8499`, ls 2.5px uppercase.

---

## 1. Per-prayer theme tokens (CANONICAL — full ramp)

These are the complete token sets (from the In-Prayer motion screen, the richest
source). **Recommend treating this table as the single source of truth** and
generating every prayer-tinted surface from it.

### Fajr — الفجر (dark)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #0d1430 0%, #1c2147 36%, #46324f 64%, #8a5560 84%, #d18d6c 100%)` |
| ink | `#f7eef0` |
| muted | `#d8a9b4` |
| faint | `#b78996` |
| faintest | `#7e5f6b` |
| accent | `#eaa9b2` |
| glow | `rgba(234,169,178,0.85)` |
| orb light→dark | `#fce8ec` → `#eaa9b2` |
| orb ink | `rgba(58,30,40,0.55)` |
| light theme? | no |

### Dhuhr — الظهر (LIGHT)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #8fb8df 0%, #bcd6ec 42%, #e6eef4 78%, #f4efe6 100%)` |
| ink | `#22323f` |
| muted | `#4f6473` |
| faint | `#6f8593` |
| faintest | `#9aaeba` |
| accent | `#d99a2a` |
| glow | `rgba(217,154,42,0.7)` |
| orb light→dark | `#fff6df` → `#f0c24e` |
| orb ink | `rgba(70,48,8,0.5)` |
| light theme? | **YES** (dark text on light bg) |

### Asr — العصر (dark)
> **Intent (the painted world):** Asr is the *most chromatic* of the five. The
> other four render the **sky**; Asr renders what the low, warm afternoon light
> does to the **world** — peak saturation, everything pops. Deep, saturated azure
> **holds through the upper sky and the text zone** (so light text stays readable
> at ~5:1 with no overlay); the warm gold **blooms low, as a horizon glow** in the
> bottom third. This is both truer to a late-afternoon sky and *more* vibrant than
> a pale mid-band — the washed haze was the least-saturated stop. Never muted, and
> never scrimmed: the gradient and the text are made to agree. See §10.

| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #14568f 0%, #1763a3 45%, #1f6cab 66%, #dcc189 86%, #ea9c45 100%)` |
| ink | `#f7ede1` |
| muted | `#d9b48f` |
| faint | `#b3906f` |
| faintest | `#806750` |
| accent | `#f3b24c` |
| glow | `rgba(243,178,76,0.85)` |
| orb light→dark | `#fbeeda` → `#f3b24c` |
| orb ink | `rgba(60,40,22,0.5)` |
| light theme? | no |

### Maghrib — المغرب (dark)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #241640 0%, #6a2c54 36%, #b34440 60%, #db6e3a 80%, #f2a85a 100%)` |
| ink | `#fbeede` |
| muted | `#e6b095` |
| faint | `#bd8771` |
| faintest | `#8a6253` |
| accent | `#f4a86a` |
| glow | `rgba(244,168,106,0.9)` |
| orb light→dark | `#ffe9d4` → `#f4a86a` |
| orb ink | `rgba(64,28,30,0.5)` |
| light theme? | no |

### Isha — العشاء (dark)
| Token | Value |
|---|---|
| background | `radial-gradient(115% 60% at 50% 42%, #201b3a 0%, #141224 50%, #0b0a14 100%)` |
| ink | `#f4f1fa` |
| muted | `#a39db6` |
| faint | `#7d7790` |
| faintest | `#4f4a63` |
| accent | `#9a86c7` |
| glow | `rgba(154,134,199,0.9)` |
| orb light→dark | `#d6c9ee` → `#9a86c7` |
| orb ink | `rgba(22,20,42,0.6)` |
| light theme? | no |

### Dusk blue hour — (transitional keyframe, NOT a prayer · dark)
> **Fajr's mirror on the dusk side.** The sky after the sunset fire fades:
> deep indigo above, dropping through blue-violet to a dusky mauve, with a last
> warm ember at the horizon — the *blue hour*. Sits between Maghrib and Isha on
> the day timeline (§10); labels/icons read as Maghrib (still Maghrib's window).
> Reuses Isha's text ramp (heading into night).

| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #1a1836 0%, #36325f 45%, #6a4a6e 75%, #9a5e63 100%)` |
| ink | `#f4f1fa` |
| muted | `#a39db6` |
| faint | `#7d7790` |
| faintest | `#4f4a63` |
| accent | `#cf9a86` |
| glow | `rgba(207,154,134,0.85)` |
| orb light→dark | `#e8d2dc` → `#cf9a86` |
| orb ink | `rgba(22,20,42,0.6)` |
| light theme? | no |

**Neutral helpers per theme** (derive from `light` flag):
- neutralFill: light → `rgba(36,50,63,0.12)`, dark → `rgba(255,255,255,0.16)`
- neutralBorder: light → `rgba(36,50,63,0.30)`, dark → `rgba(255,255,255,0.28)`
- haloColor: light → `rgba(120,90,30,0.18)`, dark → `rgba(255,255,255,0.16)`

---

## 2. Background gradients by context

Some immersive screens use a slightly different background than the canonical
in-prayer one. Match per context:

### Welcome / Entry & Isha-night (deep indigo radial)
`radial-gradient(125% 75% at 50% 6-8%, #251f40 0%, #16142a 46%, #0d0c18 100%)`

### Per-prayer ENTRY screens (standalone "Enter prayer")
- Fajr: `linear-gradient(180deg, #0d1430 0%, #1c2147 36%, #46324f 64%, #8a5560 84%, #d18d6c 100%)`
- Dhuhr: `linear-gradient(180deg, #8fb8df 0%, #bcd6ec 42%, #e6eef4 78%, #f4efe6 100%)`
- Asr: `linear-gradient(180deg, #14568f 0%, #1763a3 45%, #1f6cab 66%, #dcc189 86%, #ea9c45 100%)`
- Maghrib: `linear-gradient(180deg, #241640 0%, #6a2c54 36%, #b34440 60%, #db6e3a 80%, #f2a85a 100%)`
- Isha: `radial-gradient(125% 75% at 50% 8%, #251f40 0%, #16142a 46%, #0d0c18 100%)`

(These match §1 except Isha entry uses the indigo radial.)

### In-prayer motion screen
Uses §1 canonical backgrounds (Isha = `radial-gradient(115% 60% at 50% 42%, …)`).

---

## 3. Accent variants — IMPORTANT (existing inconsistency)

The current build uses **three slightly different accent hues per prayer**
depending on the screen. To "make it identical," match the column for the screen
you're building; to unify, pick ONE column (recommend **A — In-Prayer canonical**).

| Prayer | A · In-Prayer (canonical) | B · Guided Setup | C · Today/Tab button |
|---|---|---|---|
| Fajr | `#eaa9b2` (rose) | `#e8a07e` (peach) | `#e8a07e` |
| Dhuhr | `#d99a2a` | `#d6a13a` | `#c08326` (tab) / `#e7b23e` (btn) |
| Asr | `#f3b24c` | `#e6a85a` | `#ecb877` (tab) / `#e6a85a` (btn) |
| Maghrib | `#f4a86a` | `#f0a05a` | `#f6b079` (tab) / `#f0a05a` (btn) |
| Isha | `#9a86c7` | `#9a86c7` | `#9a86c7` |

> Recommendation: standardise on **Column A** everywhere and delete B/C. Only
> Isha (`#9a86c7`) is already consistent across all three.

### How accent is applied
- **Selected states** (segmented controls, cards, rows): bg `rgba(accent,0.10–0.18)`, border `rgba(accent,0.32–0.45)`.
- **Filled controls** (Start button, number badge, toggles, chips-selected): solid `accent` with `#16142a` text/icon.
- **Glows**: `box-shadow: 0 0 Npx rgba(accent, 0.5–0.9)`.
- **Eyebrows / active labels**: text colour = accent.

---

## 4. Prayer metadata

| Prayer | Arabic | Time (London) | Farḍ rakʿahs | Eyebrow / phase |
|---|---|---|---|---|
| Fajr | الفجر | 4:52 AM | 2 | Before sunrise / The first light |
| Dhuhr | الظهر | 12:21 PM | 4 | Midday / Sun at its zenith |
| Asr | العصر | 3:47 PM | 4 | Afternoon / Lengthening light |
| Maghrib | المغرب | 6:58 PM | 3 | Sunset / The day closes |
| Isha | العشاء | 8:24 PM | 4 | Night / Stillness |

Shared context strings: location **London**; Hijri **5 Muḥarram 1448**;
Gregorian **Thursday, 21 June**.

### Full rakʿah composition (farḍ + sunnah/witr)
- Fajr: 2 sunnah (emph) + 2 farḍ
- Dhuhr: 4 sunnah (emph) + 4 farḍ + 2 sunnah (emph)
- Asr: 4 sunnah (optional) + 4 farḍ
- Maghrib: 3 farḍ + 2 sunnah (emph)
- Isha: 4 farḍ + 2 sunnah (emph) + Witr (3)

---

## 5. Light vs dark handling

- **Dhuhr is the only LIGHT theme** — text becomes dark (`#22323f` ramp), card
  fills/borders flip to dark-alpha (`rgba(36,50,63,…)`), tab bar uses a white
  glass pill. Every other prayer is dark (white-alpha neutrals, light text).
- Drive this off a single `light` boolean per theme.

---

## 6. Fonts (theme-wide)
- **Cormorant Garamond** (500/600) — display, prayer Latin names, numerals.
- **Manrope** (400–700) — all UI/body/labels.
- **Amiri** (400/700) — all Arabic, `direction: rtl`.
```
https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600&family=Manrope:wght@400;500;600;700&family=Amiri:wght@400;700&display=swap
```

---

## 7. Signature animations (keyframes)
| Name | Effect | Typical use |
|---|---|---|
| `breathe` | scale 0.93↔1.06, opacity 0.82↔1, ~7s | orbs, glows |
| `drift` | translateY 0↔-4px | floating sun/moon |
| `twinkle` | opacity 0.2↔0.85 | stars (Fajr/Isha) |
| `pulseRing` | scale 0.85→1.5, opacity 0.55→0 | active markers |
| `glowSoft` | box-shadow soft↔strong | welcome moon |
| `haloSpin` | rotate 360°, 60s linear | prayer orb halo |
| `ringDraw` | stroke-dashoffset 207→40 | streak ring |
| `moonPhase` | translateX shift | crescent terminator |
| `wavePulse` | scaleY 0.5↔1 | muezzin waveform |

---

## 8. Suggested token shape (for code)
```ts
type PrayerTheme = {
  key: 'fajr'|'dhuhr'|'asr'|'maghrib'|'isha';
  name: string; ar: string; time: string; rakah: number; eyebrow: string;
  bg: string;            // full-bleed gradient
  ink: string; muted: string; faint: string; faintest: string;
  accent: string; glow: string;
  orbA: string; orbB: string; orbInk: string;
  light: boolean;
};
```
Generate selected/hover/glow surfaces from `accent` via an alpha helper
`rgba(accent, α)` rather than hardcoding tints.

---

## 9. Time-based theme transitions (LOCKED 2026-06-27)

The atmospheric theme no longer snaps between prayers — it **cross-fades** from
one period's theme to the next over a window anchored to the **real** prayer /
sunrise times (so it auto-adjusts across season & location). Outside a window the
theme is the solid period color; inside, every theme token (gradient stops + ink/
muted/faint/accent/glow/orb) is linearly interpolated `0→1` across the window.

**Inputs:** the engine's actual `Fajr`, `Sunrise`, `Asr`, `Maghrib` instants.
(Dhuhr and Isha prayer instants are intentionally NOT anchors — the day→night
feel is driven by sunrise and the Maghrib/sunset window instead.)

### Locked windows

| Transition | Change starts | Change ends |
|---|---|---|
| Isha → Fajr | Fajr | Fajr + 15m |
| Fajr → Dhuhr | Sunrise | Sunrise + 15m |
| Dhuhr → Asr | Asr − 30m | Asr |
| Asr → Maghrib | Maghrib − 30m | Maghrib |
| Maghrib → Isha | Maghrib + 30m | Maghrib + 1h |

Before the first window of the day (midnight → Fajr) the theme is solid **Isha**.

### Worked example — Melbourne, 27 Jun (Fajr 6:03a · Sunrise 7:36a · Asr 2:51p · Maghrib 5:09p)

| Transition | Change starts | Change ends | Duration |
|---|---|---|---|
| Isha → Fajr | 6:03a | 6:18a | 15 min |
| Fajr → Dhuhr | 7:36a | 7:51a | 15 min |
| Dhuhr → Asr | 2:21p | 2:51p | 30 min |
| Asr → Maghrib | 4:39p | 5:09p | 30 min |
| Maghrib → Isha | 5:39p | 6:09p | 30 min |

### Scope
- **Applies to:** Prayer Times. (Guided Prayer — pending decision on whether it
  follows clock time or stays locked to the prayed prayer.)
- **Does NOT apply to:** Calibration & Prayer Setup — these move to a **fixed**
  palette like Settings (pending palette decision); they no longer theme by
  time-of-day. (Supersedes the older note that Guided Prayer Setup uses the
  atmospheric gradient.)

### Edge handling
If two windows ever overlap (prayers closer than a window at extreme latitudes),
clamp each window to the midpoint between neighbours so colors never double-blend.

---

## 10. The day's miracle of light — refactor brief (2026-06-28)

The atmospheric screen is not "five backgrounds." It is the **day's miracle of
light told in colour** — each prayer a sign (āyah), the transitions carrying the
most weight. This is the north star for the colour + transition refactor.

### The five signs (the "why" behind each palette)
- **Maghrib** — the *clearest* sign: in ~30 min the world goes light → dark.
- **Isha** — total darkness, the time for rest; the stars reveal the unfathomable
  scale of the universe, and greater still, of its Lord. (This is why the night
  sky / starfield matters — it is the sign, not decoration.)
- **Dhuhr** — the sun at its zenith; the peak of the day, the light by which we
  seek provision.
- **Fajr** — the mirror of Maghrib: dark → light.
- **Asr** — the *mysterious* one. Where the others render the **sky**, Asr renders
  what the low warm light does to the **world**: peak saturation, every plant,
  flower and surface popping — the world *as painted* by its Lord. Asr is the
  most chromatic of the five. (Palette: §1 Asr.)

### Objectives
1. **The two hard transitions must feel like the real sky.** Day→night
   (Maghrib→Isha) and night→day (Isha→Fajr→Dhuhr) are the emotional core and are
   currently the weakest — too short, snapped, and skipping the blue/golden hours.
2. **Drive the transitions off solar/twilight geometry**, not fixed ±minute
   windows — sunrise and the civil/nautical/astronomical twilight steps — so the
   ramps are *physically paced*. Fajr ≈ dawn twilight and Isha ≈ dusk twilight
   already, so the prayer instants are roughly the right boundaries; the gain is
   adding sunrise + the twilight phases as anchors. (Supersedes the fixed windows
   in §9 as those are reworked — keep §9 as the record of the prior model until
   the geometry model lands.)
3. **Asr = the painted world** (done — §1). Vibrancy over atmosphere.

### The keyframe timeline (IMPLEMENTED — supersedes §9 fixed windows)

The atmospheric theme is a **keyframe timeline anchored to the sun's altitude**,
not adjacent-prayer blends. Anchors come from `PrayerTimesEngine.twilightAnchors(for:)`
(pure; built on `SolarTime.timeForSolarAngle`). The clock (`now`) is only the
cursor reading position along the curve → auto-correct across season & location.
Between two keyframes every token interpolates; the background cross-fades by
opacity stack (handles linear↔radial, e.g. dusk→Isha brings the starfield in).

| Anchor (sun angle / event) | Keyframe | Ramp into it |
|---|---|---|
| Astronomical dawn (−18°) | Isha | (night holds) |
| Nautical dawn (−12°) | Fajr | Isha → Fajr — deep-blue first light |
| Sunrise (0°) | Fajr | Fajr holds — the dawn blue hour |
| Morning gold (+6°) | Dhuhr | Fajr → Dhuhr — sunrise ignites the day |
| Asr (instant) | Asr | Dhuhr → Asr — the long afternoon warm |
| Evening gold (+6°) | Asr | Asr holds — the painted world |
| Sunset (0°) | Maghrib | Asr → Maghrib — golden hour into fire |
| Civil dusk (−6°) | Dusk blue hour | Maghrib → dusk blue hour |
| Nautical dusk (−12°) | Dusk blue hour | the blue hour holds |
| Astronomical dusk (−18°) | Isha | dusk blue hour → night |

Before the first anchor (after midnight) and after the last, the theme is solid
**Isha**. Night→day start anchors on **true astronomical dawn (−18°)**, NOT the
app's Fajr instant (which is overridden to sunrise−90m). Fajr's gradient already
*is* the dawn blue hour, so only its dusk mirror (the dusk blue-hour keyframe, §1)
is newly authored.

> Known edge: at high latitude an angle may not occur (no −18° in summer); the
> accessor returns nil and the theme falls back to solid Isha. To refine later.

### Status
- [x] Asr palette — luminous golden-hour (§1).
- [x] Dusk blue-hour keyframe — Fajr's dusk mirror (§1).
- [x] Asr text contrast — fixed by **re-weighting the gradient** (azure holds
      through the text zone, gold blooms low) + a filled CTA pill. No overlay/blur.
- [x] Solar/twilight-geometry transition engine (this section).
- [x] Night→day ramp (deep-blue first light → dawn blue hour → sunrise ignition).
- [x] Day→night ramp (golden hour → sunset fire → blue hour → night).
- [ ] Live tuning pass (colours of the dusk blue hour; ramp durations) on device.
- [ ] High-latitude fallback (polar day/night).
