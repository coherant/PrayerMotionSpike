# SalahMotion — Watch Card v2
## Design Specification

---

## Overview

The Watch Card is the primary navigation surface of the SalahMotion watchOS app. A vertically scrolling list of large, tappable cards on a true-black OLED background. The whole menu re-skins to the current prayer's colour at transition time — colour is the meaning.

---

## Prayer Palette

| Prayer  | Card background | Orb / day-hue | Time        |
|---------|----------------|---------------|-------------|
| Fajr    | `#0d1430`      | `#6878c0`     | Pre-dawn    |
| Dhuhr   | `#8fb8df`      | `#8fb8df`     | Midday      |
| Asr     | `#14568f`      | `#c89030`     | Afternoon   |
| Maghrib | `#241640`      | `#c87030`     | Sunset      |
| Isha    | `#201b3a`      | `#4848a8`     | Night       |

**Card background** — the flat OLED surface the card floats on.  
**Orb / day-hue** — used for the sun/crescent orb, pip colours, and the switcher button accents. The orb palette is the original SalahMotion complication day-palette.

All five cards are **dark-surface with light ink** (`#f4f1fa`). Dhuhr is intentionally dark — this diverges from the iOS atmospheric version and is correct for the watch.

---

## Card Structure

### Dimensions
| Element          | Value                    |
|------------------|--------------------------|
| Screen           | 200 × 246 px             |
| Screen radius    | 42 px                    |
| Card side margin | 8 px each side           |
| Card width       | 184 px                   |
| Card height      | 122 px                   |
| Card radius      | 34 px (concentric)       |
| Card gap         | 5 px                     |

### Scroll position
The menu shows Prayer Times full (122 px) with Guided Prayer peeking below (~90 px visible). This communicates "scrollable list" without hiding key info.

---

## Typography

| Role             | Family              | Size   | Weight |
|------------------|---------------------|--------|--------|
| Card label       | Manrope             | 7.5 px | 700    |
| Prayer name (EN) | Cormorant Garamond  | 22 px  | 500    |
| Prayer name (AR) | Amiri               | 16 px  | 400    |
| Metadata         | Manrope             | 8 px   | 400    |
| Rail labels      | Manrope             | 5.5 px | 700    |
| Status time      | Manrope             | 13 px  | 700    |

**Name row layout:** Arabic name (`direction:rtl; unicode-bidi:isolate`) sits left of the English name in a `direction:ltr` flex row. Both baseline-aligned.

---

## Orb Motif

The orb is a 22 × 22 px element top-left of the card content, animated with a slow breathe (5 s ease-in-out, scale .93 → 1.08, opacity .76 → 1).

| Prayer       | Orb type  | Fill                                                      |
|--------------|-----------|-----------------------------------------------------------|
| Fajr, Isha   | Crescent  | Stroke-only SVG, stroke = day-hue, near-zero fill opacity |
| Dhuhr, Asr, Maghrib | Sun | Radial gradient: white → day-hue → dark                 |

---

## Five-Slot Day-Progress Rail

Sits at the bottom of the Prayer Times card. Five pips, Fajr (left) → Isha (right).

**Position is encoded by SIZE first, colour second** (three of the five hues are blues, so size must carry position).

| State  | Pip size | Colour      | Label opacity |
|--------|----------|-------------|---------------|
| Past   | 6 px     | Day-hue     | 35 %          |
| Active | 10 px    | `#f4f1fa`   | 82 %          |
| Future | 6 px     | Day-hue     | 20 %          |

**Active pip ping:** A 10 × 10 px ring behind the active pip, `rgba(244,241,250,.45)`, animates `ping` (scale 1 → 2.8, opacity .7 → 0) on a 1.8 s loop.

A 1 px connector line (`rgba(244,241,250,.16)`) spans the full rail width behind all pips.

---

## Cards

### Prayer Times
| Zone          | Content                                   |
|---------------|-------------------------------------------|
| Top row       | Orb · "PRAYER TIMES" label · name row · time / countdown |
| Bottom        | Five-slot day-progress rail               |

### Guided Prayer
| Zone          | Content                                   |
|---------------|-------------------------------------------|
| Top row       | Orb · "GUIDED PRAYER" label · name row · rakʿah count / session CTA |

### Calibration (chrome shell — not in this file)
Constant deep-indigo shell: `linear-gradient(180deg, #1a1730, #131120 60%, #100e1b)`. Borrows only the current prayer's orb hue for active crosshair strokes and position indicator bars.

---

## Watch Shell (Apple Watch Ultra 3 · 49 mm)

| Element        | Value                                      |
|----------------|--------------------------------------------|
| Outer bezel    | 230 × 276 px · radius 56 px                |
| Screen         | 200 × 246 px · radius 42 px                |
| Screen mount   | `display:flex; align-items:center; justify-content:center` (true centering) |
| Digital Crown  | Right · 5 × 50 px                          |
| Action Button  | Left upper · 4 × 26 px · `#c04200 → #ff6600` |
| Side Button    | Left lower · 4 × 20 px · silver            |
| Background     | `#000` (true OLED black)                   |

---

## Animations

| Name      | Target         | Keyframes                                      | Duration |
|-----------|----------------|------------------------------------------------|----------|
| `breathe` | `.orb`         | scale .93 → 1.08 · opacity .76 → 1            | 5 s ease-in-out infinite |
| `ping`    | `.pip-pulse`   | scale 1 → 2.8 · opacity .7 → 0                | 1.8 s ease-out infinite  |

---

## Files

| File                   | Description                              |
|------------------------|------------------------------------------|
| `Watch Card v2.dc.html` | Live DC (Design Component) — editable in the visual editor |
| `Watch Card v2.html`    | Raw standalone HTML — no DC runtime, pure HTML + CSS + JS |
| `Watch Menu Cards.dc.html` | Full canvas: five-prayer proof, card variations, DT + AOD states |

---

*SalahMotion · Watch Card v2 · July 2026*
