# SalahMotion Design Theme

Single source of truth for colours, typography, and orb geometry across all prayer times.
Update this file first, then apply changes to `PrayerTimeTheme.swift`.

---

## Prayer Time Colour Themes

Each prayer time has four colour roles:

| Role | Purpose |
|---|---|
| `gradientTop` | Background gradient — top of screen |
| `gradientBottom` | Background gradient — bottom of screen |
| `orbGlow` | Orb haze, rings, orb body fill, accent dots |
| `accent` | Active tracker dot, progress bar (currently same as orbGlow) |
| `textPrimary` | Arabic text on the orb — dark tone that contrasts against orbGlow |

### Fajr (pre-dawn · ~04:00–05:59)

Visual mood: deep navy-purple fading to dusty mauve, soft rose orb.
The darkest and coolest of the five themes. Slight warmth creeps in at the bottom.

| Role | RGB (0–1) | Hex |
|---|---|---|
| gradientTop | (0.10, 0.08, 0.21) | #1A1535 |
| gradientBottom | (0.24, 0.13, 0.26) | #3D2142 |
| orbGlow | (0.78, 0.50, 0.56) | #C78090 |
| accent | (0.78, 0.50, 0.56) | #C78090 |

### Dhuhr (midday · ~06:00–14:59)

Visual mood: soft steel-blue sky fading to warm sandy cream, cream-gold orb.
The brightest and lightest of the five themes — full daylight. Notably lighter than all others.

| Role | RGB (0–1) | Hex |
|---|---|---|
| gradientTop | (0.48, 0.56, 0.68) | #7B8FAD |
| gradientBottom | (0.75, 0.66, 0.51) | #BFA882 |
| orbGlow | (0.91, 0.84, 0.66) | #E8D5A8 |
| accent | (0.91, 0.84, 0.66) | #E8D5A8 |

### Asr (afternoon · ~15:00–17:59)

Visual mood: warm sandy-tan top fading to deep amber-brown, golden orb.
Earthy and warm — the sun is lower, colours are richer and more saturated than Dhuhr.

| Role | RGB (0–1) | Hex |
|---|---|---|
| gradientTop | (0.66, 0.56, 0.38) | #A88F60 |
| gradientBottom | (0.54, 0.35, 0.13) | #895921 |
| orbGlow | (0.88, 0.63, 0.19) | #E0A030 |
| accent | (0.88, 0.63, 0.19) | #E0A030 |

### Maghrib (sunset · ~18:00–19:59)

Visual mood: near-black top with dramatic deep ember-orange bloom, vivid coral orb.
High contrast — the darkest top against the most saturated warm bottom.

| Role | RGB (0–1) | Hex |
|---|---|---|
| gradientTop | (0.04, 0.03, 0.06) | #0A0810 |
| gradientBottom | (0.29, 0.11, 0.03) | #4A1C08 |
| orbGlow | (0.88, 0.35, 0.16) | #E05928 |
| accent | (0.88, 0.35, 0.16) | #E05928 |

### Isha (night · ~20:00–03:59)

Visual mood: near-black fading to deep indigo, muted lavender orb.
Cool and still — the most subdued saturation of the dark themes.

| Role | RGB (0–1) | Hex |
|---|---|---|
| gradientTop | (0.03, 0.04, 0.09) | #080A18 |
| gradientBottom | (0.10, 0.06, 0.25) | #1A0F40 |
| orbGlow | (0.60, 0.47, 0.85) | #9978D9 |
| accent | (0.60, 0.47, 0.85) | #9978D9 |

---

## Typography

All text is white on the dark gradient background. Opacity is used to create hierarchy.

### Prayer Session Screen

| Element | Font | Size | Weight | Design | Opacity | Notes |
|---|---|---|---|---|---|---|
| Position name | System | 28pt | Semibold | Serif | 100% | e.g. "Sujood" |
| Position meaning | System | 28pt | Regular | Serif | 55% | e.g. "· Prostration" |
| Recitation text | System | 14pt | Regular | Serif | 65% | Italic |
| Instruction label | System | 11pt | Regular | Default | 38% | Kerning 0.4 |
| END PRAYER button | System | 10pt | Medium | Default | 28% | Kerning 2.0, all caps |

### Position Tracker (left rail)

| Element | Font | Size | Weight | Design | Opacity |
|---|---|---|---|---|---|
| Active label | System | 15pt | Semibold | Serif | 100% |
| Inactive label | System | 11pt | Regular | Serif | 45% (penultimate) / 25% (earlier) |
| Active Arabic | System | 11pt | Regular | Default | 65% of label opacity |
| Inactive Arabic | System | 9pt | Regular | Default | 65% of label opacity |

### Header

| Element | Font | Size | Weight | Opacity | Notes |
|---|---|---|---|---|---|
| Rak'ah counter | System | 11pt | Medium | 55% | e.g. "Rak'ah 1 / 2" |
| Silence toggle | System | 10pt | Medium | 60% | Kerning 1.2, all caps |

### Orb

| Element | Font | Size | Weight | Colour | Notes |
|---|---|---|---|---|---|
| Arabic text | System | 30pt | Regular | Black 80% | Sits on top of crescent highlight |

---

## Orb Geometry

| Layer | Shape | Size | Opacity / Fill |
|---|---|---|---|
| Dashed ring | Circle stroke | 240 × 240pt | orbGlow at 12%, dash [3, 6], 0.8pt |
| Faint ring | Circle stroke | 214 × 214pt | orbGlow at 18%, 0.8pt |
| Animated glow | Circle fill | 200 × 200pt | RadialGradient orbGlow 55%→50%, pulses scale 1.0↔1.08, opacity 0.65↔0.35, 2.5s ease |
| Orb body | Circle fill | 176 × 176pt | RadialGradient orbGlow 92%→50%→8%, startR 8, endR 88 |
| Crescent highlight | Circle fill | 176 × 176pt | RadialGradient white 88%→clear, center (0.5, 0.5), endR 90 |
| Arabic text | Text | 30pt | Black 80% |

---

## Colour Reference

Visual source: `docs/design-reference/prayersession-allprayers.png`

> Hex values are visual approximations derived from `prayersession-allprayers.png` — no Figma source exists yet.
> Key observations from the reference: Dhuhr is the only light/bright theme; Asr is warm and earthy (not dark); Maghrib has the highest contrast (near-black vs vivid ember).
> **Workflow:** edit this file first to agree on colours, then apply to `SalahMotion/DesignSystem/Tokens/PrayerTimeTheme.swift`.
