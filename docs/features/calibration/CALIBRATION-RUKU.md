# Calibration — Rukūʿ Screen

The motion-calibration screen frozen at the **Rukūʿ (bowing)** capture step. Part
of the one-time guided pass through a 2-rakʿah cycle. Pairs with `THEME.md`.

Artboard **402 × 874** inside the iOS frame. Default theme **isha** (lavender accent).

---

## 1. What this screen is

Hātif instructs the user into each prayer posture and the app records its motion
signature. This frame is the **Rukūʿ** capture: instruction shown, posture figure
in the dial, the hold-to-capture arc partway round, motion bars sampling.

State that produces it: `phase = 'record'`, `index = 1` (Rukūʿ), `static = true`
(freezes the auto-run for display).

---

## 2. Anatomy (top → bottom)

1. **Header** — back chevron · eyebrow "CALIBRATION" (accent) · title "Tune your movements" (Cormorant) · step counter `2 / 6` (right).
2. **Hātif voice bar** — animated waveform + label "HĀTIF · GUIDING" (accent) + the spoken instruction: *"Bow forward with a level back. Hold the position."*
3. **Capture dial** (230 px) —
   - track ring `rgba(255,255,255,0.1)`, **progress arc** in accent (partway during recording),
   - faint **ground line**,
   - the **posture figure**: a side-profile line illustration of Rukūʿ (bent at the waist, hands to the knees), **tinted to the screen accent**, feet on the ground line.
4. **Posture label** — `ركوع` (Amiri) + `Rukūʿ` (Cormorant) + readout chip "Bowing · hands to the knees".
5. **Live motion sampling** — accelerometer-style bars animating + "SAMPLING MOTION".
6. **Stepper** — six positions (Qiyām · Rukūʿ · Iʿtidāl · Sujūd · Julūs · Tashahhud); captured ones check off, current is ringed.
7. **Bottom** — running status pill "Recording · hold still".

---

## 3. The posture figure (asset approach)

- The Rukūʿ figure is a **line-art PNG**, one per prayer accent, drawn as a plain `<img>` overlaid on the dial (not an SVG mask — those fail to render/capture).
- Files: `calib-ruku-fajr.png`, `calib-ruku-dhuhr.png`, `calib-ruku-asr.png`, `calib-ruku-maghrib.png`, `calib-ruku-isha.png` — same line art, lines pre-tinted to each accent on a transparent background.
- Selected by theme: `rukuImg = RUKU_IMGS[theme]`; overridable via the `rukuSrc` prop (used to embed a data-URI for the offline standalone).
- Placement: `position:absolute; height:118px; width:auto;` centered, feet aligned to the dial's ground line.
- The other five postures currently use accent-coloured stick figures — they should be replaced with matching line art for a cohesive set.

### Accent per theme (line tint)
| Theme | Accent |
|---|---|
| Fajr | `#e8a07e` |
| Dhuhr | `#d6a13a` |
| Asr | `#e6a85a` |
| Maghrib | `#f0a05a` |
| Isha | `#9a86c7` |

---

## 4. Tokens

| Token | Value |
|---|---|
| background | `radial-gradient(125% 76% at 50% 0%, rgba(accent,0.16), transparent 56%), linear-gradient(180deg,#181426,#131120 58%,#0f0d18)` |
| ink | `#f4f1fa` · muted `#b8b2c8` · faint `#847e98` |
| accent | per theme (above) |
| progress arc | accent, `stroke-width 4`, round cap, r 84 |
| dial track | `rgba(255,255,255,0.1)` |

---

## 5. Props (CalibrationScreen)

- `theme`: `fajr|dhuhr|asr|maghrib|isha` (default `isha`) — recolours screen + figure tint.
- `static`: freeze for display (no auto-run timers).
- `initialPhase`: `intro|instruct|record|captured|complete` — `record` for this screen.
- `initialIndex`: posture index — `1` for Rukūʿ.
- `rukuSrc`: optional explicit image source (data-URI) for offline embedding.

Live (non-static) flow: **Begin** → for each posture: instruct → record (hold arc fills, bars sample) → captured (check) → next → complete.
