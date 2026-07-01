# SalahMotion Watch — Direction B v2
## Celestial Frost · Design Specification

---

## Concept

Every prayer has a sky. The watch face shows the actual sky for the hour — a pre-dawn crescent for Fajr, a blazing sun for Dhuhr, a sunset horizon for Maghrib, a night sky with moon for Isha. A permanent frosted glass layer sits over the entire face: the prayer UI is always readable, but the colour of the sky bleeds through the frost, tinting every interaction with the light of that hour.

---

## Layer Stack (bottom → top)

| Z | Layer | Description |
|---|---|---|
| 0 | Sky gradient | `background: var(--watch-bg)` — the prayer's characteristic sky |
| 0 | Celestial glow | Large radial gradient (`--ra40` accent) centered on the face, animated `celestialGlow` — bleeds into frost above |
| 1 | Celestial object | Moon (Fajr / Isha) or Sun (Dhuhr / Asr / Maghrib), 92 × 92 pt, centered |
| 1 | Stars | Two glowing dots for night prayers (Fajr, Isha) |
| 2 | Frosted glass | `position: absolute; inset: 0` — `backdrop-filter: blur(20px)` + `background: rgba(4,4,14,0.20)` — covers entire face |
| 3 | Watch UI | Status bar, prayer content, CTAs — all rendered inside the frost div |

---

## Watch Specs

- **Device:** Apple Watch Ultra 3 · 49 mm
- **Canvas (outer bezel):** 230 × 276 pt · border-radius: 56 pt
- **Inner screen:** 200 × 246 pt · border-radius: 42 pt · overflow: hidden
- **Frost opacity:** `rgba(4, 4, 14, 0.20)` — 20 % dark overlay
- **Blur radius:** 20 px
- **Side buttons:** Digital Crown (right, 50 pt tall) + Action Button (left, 26 pt, #c04200→#ff6600) + Side button (left, 20 pt)

---

## Prayer Themes

| Prayer | Time | Sky | Accent | Ink | Celestial |
|---|---|---|---|---|---|
| **Fajr** | 4:52 AM | `#0d1430 → #1c2147 → #8a5560 → #d18d6c` | `#eaa9b2` | `#f7eef0` | Crescent moon · stars |
| **Dhuhr** | 12:21 PM | `#8fb8df → #bcd6ec → #f4efe6` | `#d99a2a` | `#22323f` | Sun (high) |
| **Asr** | 3:47 PM | `#2c3f63 → #5b5570 → #d59a5c` | `#e8b87e` | `#f7ede1` | Sun (mid) |
| **Maghrib** | 6:58 PM | `#241640 → #b34440 → #db6e3a → #f2a85a` | `#f4a86a` | `#fbeede` | Sun at horizon |
| **Isha** | 8:24 PM | `radial #201b3a → #141224 → #0b0a14` | `#9a86c7` | `#f4f1fa` | Crescent moon · stars |

**Accent variants** (used throughout the UI):
- `--ra18` / `--ra25` / `--ra30` / `--ra40` / `--ra50` — accent at 18 / 25 / 30 / 40 / 50 % opacity

---

## Screen States

### 1 · Glance
The resting face. Celestial object centred and glowing through the full-screen frost. Content:
- `NEXT PRAYER` label (7.5 px, Manrope, caps, faint)
- Prayer name (38 px, Cormorant Garamond 500)
- Arabic name (14 px, Amiri, RTL, muted)
- Countdown `2h 14m` (28 px, Cormorant)
- Qibla arrow + `until · [time]` (8 px, Manrope, faint)

### 2 · Active Prayer
Triggered when prayer begins. Rakah count in status bar area.
- Movement name English dominant: `Ruku'` (50 px, Cormorant)
- Arabic subtitle: `الركوع` (20 px, Amiri, muted)
- Arc progress ring (28 pt diameter) + guided live indicator

### 3 · Muezzin Mode
Prayer time has entered. Live Adhan broadcast indicator.
- Prayer name (40 px, Cormorant)
- `الأذان` (18 px, Amiri, muted)
- Red live dot + `Now · [time]`
- 7-bar waveform animation (`wavePulse` 1.4 s, staggered)

### 4 · In Prayer Window
Within the prayer's valid window. Action Button shortcut.
- `WINDOW` indicator in status bar area (pulsing live dot)
- Prayer name (32 px, Cormorant)
- Arabic name (14 px, Amiri)
- Progress ring (56 pt) — `11:42 remaining`
- **BEGIN PRAYER** CTA (full-width, accent fill)

### 5 · Setup · Qibla
Action Button outside window. Compass calibration.
- `ALIGN QIBLA` label (7 px, caps)
- Animated compass (82 pt) — needle settles to 45° NE via `compassSettle` keyframe
- Qibla dot pulse at NE position
- Bearing: `42° NE · Qibla`
- **START PRAYER** CTA (full-width, accent fill)

---

## Typography

| Role | Family | Size | Weight | Notes |
|---|---|---|---|---|
| Prayer name (hero) | Cormorant Garamond | 38–50 px | 500 | Main display type |
| Movement name | Cormorant Garamond | 50 px | 500 | Active prayer screen |
| Arabic subtitle | Amiri | 14–20 px | 400 | RTL, `direction: rtl` |
| UI labels | Manrope | 7–10 px | 600–700 | Caps, letter-spacing: 1.5–2 px |
| Countdown | Cormorant Garamond | 26–28 px | 500 | Numeric |
| Time / status | Manrope | 13 px | 700 | Top-left |

---

## Animations

| Name | Duration | Usage |
|---|---|---|
| `celestialGlow` | 4 s ease-in-out infinite | Celestial object glow blob |
| `wavePulse` | 1.4 s ease-in-out infinite | Muezzin waveform bars (7, staggered +0.14 s) |
| `breathe` | varies | Radial pulse rings |
| `pulseLive` | 1.2–2 s ease-in-out infinite | Red live dot, window indicator |
| `celestialPulse` | 2.4 s ease-out infinite | Arc ring expanding halos |
| `coreDot` | 2.4 s ease-in-out infinite | Arc centre dot |
| `compassSettle` | 4.2 s ease-in-out, 0.5 s delay, fill both | Compass needle settling to Qibla bearing |
| `qiblaDot` | 2.4 s ease-in-out infinite | Qibla point pulse |

---

## Implementation Notes

- **Frosted glass:** `backdrop-filter: blur(20px)` + `-webkit-backdrop-filter: blur(20px)` required for Safari / watchOS WebKit.
- **Celestial bleed:** The glow blob (215 × 215 pt, `radial-gradient(circle, var(--ra40) 0%, transparent 60%)`, centered, `z-index: 0`) sits behind the frost. Its saturated accent colour bleeds into the frosted layer — this is the primary visual effect.
- **Color tokens:** All theme-sensitive values are CSS custom properties (`--ink`, `--accent`, `--ra18–50`, `--watch-bg`). Switching prayers updates the root properties via JavaScript; no DOM rebuild required.
- **Celestial visibility:** `.cond-moon`, `.cond-sun`, `.cond-maghrib-sun`, `.cond-stars` classes are toggled via JS on prayer change.
- **RTL text:** Arabic elements carry `direction: rtl`; they are presentational subtitles only, not interactive.
- **Action Button:** Maps to In-Window (within window) → immediate Begin Prayer, or Out-of-Window → Qibla compass setup.

---

*SalahMotion · Watch Direction B v2 · Celestial Frost · July 2026*
