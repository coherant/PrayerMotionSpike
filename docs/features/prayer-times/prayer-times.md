# SalahMotion — Prayer Times

The **Prayer Times** screen re-skinned to each prayer's hour. It is one screen in
five states — the layout never changes, only the atmosphere (background gradient
+ accent) and the *progress* (which prayers are already prayed). At Fajr nothing
is behind you; by Isha, four are gently complete.

File: `PrayersTimesAcrosstheDay.dc.html` (depends on sibling `ios-frame.jsx` and
`SukunTabBar.dc.html`).

---

## 1. Anatomy (top → bottom)

| Block | Contents |
|---|---|
| **Header** | Hijri + phase eyebrow (accent), Gregorian date (`Thursday, 21 June`), London location pill |
| **Up-next card** | "UP NEXT", next prayer name (Arabic + Latin), countdown + clock time, day-progress rail with sun/moon marker on the active node |
| **Prayer list** | Five rows — Fajr → Isha — each with a status dot, name (Latin + Arabic), and time. Past = filled check, current = ringed + boxed highlight, future = hollow |
| **Primary action** | Full-width accent button — "Prepare for …" (or "Begin Isha" on the last) |
| **Tab bar** | `SukunTabBar`, `active="prayer-times"`, tinted to the prayer accent |

---

## 2. The five states

| State | Phase eyebrow | Up next | Countdown | Rail fill | Prayed (checks) | Highlighted row | Button |
|---|---|---|---|---|---|---|---|
| **Fajr** | Dawn | Fajr 4:52 AM | in 14m | 2% | none | Fajr (ringed) | Prepare for Fajr |
| **Dhuhr** | Midday | Dhuhr 12:21 PM | in 31m | 32% | Fajr | Dhuhr (ringed) | Prepare for Dhuhr |
| **Asr** | Afternoon | Asr 3:47 PM | in 27m | 52% | Fajr, Dhuhr | Asr (ringed) | Prepare for Asr |
| **Maghrib** | Evening | Maghrib 6:58 PM | in 1h 02m | 66% | Fajr, Dhuhr, Asr | Maghrib (ringed) | Prepare for Maghrib |
| **Isha** | Night | Isha 8:24 PM | in 19m | 84% | Fajr, Dhuhr, Asr, Maghrib | Isha (ringed) | Begin Isha |

The currently-due prayer is always shown as the highlighted "up next" row, never
yet checked — the screen captures the moment *just before* each prayer.

---

## 3. Theme per state

Backgrounds and accents follow `THEME.md`. Each state uses its prayer's full-bleed
atmospheric gradient; **Dhuhr is the only light theme** (dark text, white-glass
chrome + tab pill). Accents here use the Today/Tab column (C):

| Prayer | Background | Accent (tab/eyebrow) | Button fill | Theme |
|---|---|---|---|---|
| Fajr | `linear-gradient(180deg,#0d1430,#1c2147 36%,#46324f 64%,#8a5560 84%,#d18d6c)` | `#e8a07e` | `#e8a07e` | dark |
| Dhuhr | `linear-gradient(180deg,#8fb8df,#bcd6ec 42%,#e6eef4 78%,#f4efe6)` | `#c08326` | `#e7b23e` | **light** |
| Asr | `linear-gradient(180deg,#2c3f63,#5b5570 42%,#9c7158 74%,#d59a5c)` | `#ecb877` | `#e6a85a` | dark |
| Maghrib | `linear-gradient(180deg,#241640,#6a2c54 36%,#b34440 60%,#db6e3a 80%,#f2a85a)` | `#f6b079` | `#f0a05a` | dark |
| Isha | `radial-gradient(125% 75% at 50% 8%,#251f40,#16142a 46%,#0d0c18)` | `#9a86c7` | `#9a86c7` | dark |

Accent is applied as: selected-row bg `rgba(accent,0.04–0.05)` + border
`rgba(accent,0.18–0.28)`; ringed status dot border + glow; eyebrow / time / countdown
text colour; solid button fill with dark (`#16142a`-family) text.

---

## 4. Row status vocabulary

| Status | Dot | Text colour |
|---|---|---|
| Prayed (past) | filled circle, accent-tinted bg + accent check ✓ | muted |
| Current (up next) | 2px accent ring + glow, in a highlighted boxed row | full ink, semibold |
| Future | 1.5px hollow neutral ring | faint |

(Light theme flips neutral alphas to `rgba(43,58,74,…)` and ink to `#243648`.)

---

## 5. Shared metadata

Location **London** · Hijri **5 Muḥarram 1448** · Gregorian **Thursday, 21 June**.

| Prayer | Arabic | Time |
|---|---|---|
| Fajr | الفجر | 4:52 AM |
| Dhuhr | الظهر | 12:21 PM |
| Asr | العصر | 3:47 PM |
| Maghrib | المغرب | 6:58 PM |
| Isha | العشاء | 8:24 PM |

## 6. Fonts
- **Cormorant Garamond** (500) — date, prayer Latin names
- **Manrope** (400–700) — UI, labels, times
- **Amiri** (400/700) — Arabic, `direction: rtl`

## 7. Animation
- `pulseRing` — the only motion here: the active up-next marker on the day rail pulses (scale 0.85→1.5, fade out, 3.6s).
