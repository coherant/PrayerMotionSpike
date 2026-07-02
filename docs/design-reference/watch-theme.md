# SalahMotion — Watch Theme
**The complication day-palette system · Apple Watch · LOCKED 2026-07-02**

Companion to `theme.md`. Where the two disagree, **this document wins on
watchOS**. `theme.md` remains authoritative for iOS.

---

## 0. The core decision (locked)

On the watch, the **complication day-palette is the single source of
per-prayer identity**. Every prayer-tinted surface — rail, ring gauge, orb,
accents, active states, and the card's dominant colour — is generated from it.

The iOS **atmospheric gradients do NOT carry to the watch.** They are authored
to fill a phone screen top-to-bottom; compressed into a ~40mm card their five
stops sit a few pixels apart and average into a single muddy tone, and the
three warm prayers (Dhuhr/Asr/Maghrib) collapse toward the same amber. The
gradient's job — telling the day's story in colour — fails at this scale.

**Rationale:** the watch is the glance device; glanceability beats atmosphere,
and one honest small-device palette shared with the complications is worth more
than preserving a gradient that was already losing its story at this size.

---

## 1. The day palette (CANONICAL — watch per-prayer identity)

The day's arc of light, told in five punchy hues that survive small scale.

| Prayer | `dayColor` | The sign (āyah) |
|---|---|---|
| Fajr | `#6878c0` | cool blue-violet — the first light |
| Dhuhr | `#8fb8df` | soft sky blue — the sun at its zenith |
| Asr | `#c89030` | warm gold — the painted world |
| Maghrib | `#c87030` | sunset amber — the day closes |
| Isha | `#4848a8` | deep indigo — night, stillness |

Laid in order Fajr → Isha, these read as a night→day→night progression. Three
are blues (Isha, Fajr, Dhuhr) — see §6 on why **size, not hue**, carries
position.

---

## 2. Maghrib reconciliation (resolve the duplicate)

The complication spec lists Maghrib twice. Lock both uses, delete neither:

| Use | Value | Where |
|---|---|---|
| Solid pip / accent | `#c87030` | rail active pip, orb core, filled controls, eyebrow |
| Day-arc gauge terminal | `#e09830` | the 100% stop of the continuous ring/timeline gauge only |

Rule: **discrete elements use the tint (`#c87030`); the continuous day-arc
gauge uses its own stops (ending `#e09830`).** Do not use `#e09830` for a pip.

---

## 3. The day-arc gauge gradient (ring / filled timeline only)

For any element that fills continuously across the whole prayer day (the
circular ring gauge, the rectangular timeline fill). Clockwise from 12 o'clock,
Isha → Maghrib:

| Stop | Prayer | Value |
|---|---|---|
| 0% | Isha | `#4848a8` |
| 25% | Fajr | `#6878c0` |
| 50% | Dhuhr | `#8fb8df` |
| 75% | Asr | `#c89030` |
| 100% | Maghrib | `#e09830` |

Discrete pips do **not** use this gradient — they use the flat `dayColor`.

---

## 4. The card colour model (2-stop, legibility-guaranteed)

Cards are unmistakably coloured by the day-hue, but engineered so **light ink
always clears contrast** — borrowing the iOS Asr principle ("make the gradient
and the text agree"), reduced to a watch-safe 2 stops:

- **`cardTop`** = the flat `dayColor` — the hue blooms at the top of the card.
- **`cardDeep`** = `dayColor` deepened toward night (`mix(dayColor, #0b0a14, ~0.70)`)
  — occupies the lower/text zone, guaranteeing contrast for light ink.
- Maximum **two stops**. Never the 5-stop atmospheric gradient.

This keeps every card reading as its true hue (gold at Asr, indigo at Isha,
sky-blue at Dhuhr) while the title + metadata always sit on a dark-enough band.

### Intentional divergence from iOS
On iOS, **Dhuhr is the only light theme** (dark ink on light sky). **This does
NOT carry to the watch.** On a true-black OLED display a light card is jarring
and battery-costly, so on the watch **all five prayers are dark-surface cards
with light ink** — no per-theme light/dark branching. Dhuhr becomes sky-blue
blooming to deep blue, light ink like the rest.

---

## 5. Two-layer system → the three menu cards (preserved)

`theme.md`'s atmospheric-vs-chrome split maps directly onto the menu and is the
reason cards differ for a real, theme-faithful purpose (not "all the same slate"):

| Card | Layer | Treatment |
|---|---|---|
| Prayer Times | **Atmospheric** | Full day-colour card (§4), re-skins with the current prayer |
| Guided Prayer | **Atmospheric** | Full day-colour card (§4), re-skins with the current prayer |
| Calibration | **Chrome** | Constant deep-indigo shell (§7); borrows current prayer **accent** only |

The two prayer cards carry the hour's colour; Calibration stays the calm
utility shell. At a glance you can feel which cards belong to *this hour*.

---

## 6. Encoding discipline (from the complication spec)

Position in the day is encoded by **size first, colour second** — carried over
from the complication rail so face and app agree.

- Active (current) pip: larger + full `dayColor`.
- Past pips: smaller, deepened/dim.
- Future pips: smaller, faint.

This matters because three of the five day-colours are blues; three adjacent
blues at ~5pt are a coin-flip to tell apart by hue alone. Order + size do the
real work; colour makes it sing.

Rail order on the card: **Fajr (left) → Isha (right)**, matching the
rectangular complication timeline. (The circular ring uses the cyclical
Isha→…→Maghrib order per the complication spec.)

---

## 7. Chrome shell & neutrals (utility surfaces)

### Chrome background (Calibration, and any future utility screen)
`linear-gradient(180deg, #1a1730 0%, #131120 60%, #100e1b 100%)` — borrows the
**current prayer accent** for its active elements only.

### Ink ramp (watch — always light)
| Token | Value | Use |
|---|---|---|
| ink | `#f4f1fa` | primary text |
| muted | `#b8b2c8` | secondary |
| faint | `#847e98` | labels, tertiary |
| dark-on-accent | `#16142a` | text/icons sitting on a filled accent chip |

### Neutral helpers (dark surfaces)
- neutralFill: `rgba(255,255,255,0.16)`
- neutralBorder: `rgba(255,255,255,0.28)`

---

## 8. Accent application (single palette, from `dayColor`)

Supersedes `theme.md` §3's three-column A/B/C accent inconsistency — the watch
uses **one** palette: the `dayColor`. Generate states from it, don't hardcode:

- **Selected states** (cards, rows): bg `rgba(dayColor, 0.12–0.18)`, border `rgba(dayColor, 0.32–0.45)`.
- **Filled controls** (Start, badges, chips-selected): solid `dayColor`, text/icon `#16142a`.
- **Glows** (orb halo, active pulse): `rgba(dayColor, 0.55–0.9)`.
- **Eyebrows / active labels**: text colour = `dayColor`.

---

## 9. Typography (watch)

| Face | Role |
|---|---|
| **Cormorant Garamond** | Card TITLES, prayer names, numerals ONLY |
| **Manrope** | All metadata, labels, countdowns — **tabular figures** for digits |
| **Amiri** | Arabic prayer names (الفجر …), RTL, where shown |

Serif turns muddy small — never use it for metadata. Register all three in the
watch target; fall back to a serif system font if Cormorant isn't available and
flag it.

---

## 10. Shared motifs (continuity with complications)

Draw these so the menu reads as the full-colour sibling of the tinted face mark:

- **Crescent** — custom Path/Shape, stroke-only, no fill, no facial features.
  Deliver as PDF vector, Template Image render mode. Shared with all
  complication families.
- **Orb (sun/moon)** — `dayColor` core + `rgba(dayColor, 0.55)` glow; the
  full-colour sibling of the complication's tinted orb.
- **Five-slot day tracker** — the rail (§6); the card counterpart of the ring
  gauge.

---

## 11. Animation (restrained)

`theme.md`'s full keyframe set does NOT carry to the watch. Keep **one** move:
a slow **breathe/glow** on the orb (scale ~0.96↔1.04, opacity ~0.85↔1, ~7s).
An `active-pip pulse` once on prayer transition is permitted. Everything else
(drift, twinkle, haloSpin, ringDraw, wavePulse) is dropped for battery and
watch animation throttling.

---

## 12. Constraints (non-negotiable)

- True-black OLED background; cards float as rounded rects, near full-bleed with
  small side margins; the black frames the colour.
- **Max 2-stop gradients** anywhere. No 5-stop atmospheric gradients.
- Concentric corner radius matching the display's curved corners.
- Light ink on all cards; no per-theme light/dark branching (§4).
- One large tap target per card.
- Full **Dynamic Type** support — cards reflow, never clip, at large sizes.
- Design an **Always-On Display** dimmed state for any glanceable surface.

---

## 13. Token shape (for code)

```ts
type WatchPrayerTheme = {
  key: 'fajr' | 'dhuhr' | 'asr' | 'maghrib' | 'isha';
  dayColor: string;   // canonical identity — the complication day-palette (§1)
  cardTop: string;    // = dayColor (hue blooms at top)
  cardDeep: string;   // = mix(dayColor, '#0b0a14', 0.70) — text zone (§4)
  accent: string;     // = dayColor (full saturation) — rail/gauge/orb/filled
  glow: string;       // = rgba(dayColor, 0.55) — orb halo, active pulse
};
```

Resolved `dayColor`: Fajr `#6878c0` · Dhuhr `#8fb8df` · Asr `#c89030` ·
Maghrib `#c87030` · Isha `#4848a8`. Generate `cardDeep`, selected, and glow
surfaces from `dayColor` via a mix/alpha helper — do not hardcode tints.

---

## 14. What did NOT carry from `theme.md` (superseded on watch)

- The 5-stop atmospheric gradients (§0 — too gradual at watch scale).
- Dhuhr's light theme (§4 — watch is all dark-surface).
- The three-column accent inconsistency (§8 — watch uses one `dayColor`).
- The full animation keyframe set (§11 — breathe only).