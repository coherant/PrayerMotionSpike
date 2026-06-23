# SalahMotion — App Launch (Splash) Screen

The first screen shown when the app opens. An animated, reverent splash themed
to the current prayer hour. Pairs with `THEME.md` (day-colour system),
`SPEC.md`, `SETUP-THEMED.md`, `COMPOSER.md`.

Artboard **402 × 874** inside the iOS frame. Default theme **isha** (primary night sky).

---

## 1. Anatomy (top → bottom)

1. **Starfield** — twinkling stars + a few 4-point sparkles across the upper ~60%. Count scales by theme (none at Dhuhr daytime → 48 at Isha).
2. **Descending light line** — a 1px hairline from above, fading into accent, growing in (`lineGrow`). Echoes the in-prayer "qiyām" track.
3. **Invocation** — `أَقِمِ الصَّلَاةَ` (Amiri, accent, glow) above the orb.
4. **Orb of first light** — breathing core + aura, an expanding pulse halo, and a soft **blurred** stable outer ring.
5. **Wordmark** — `Salah`(ink) `Motion`(muted), Cormorant 41/500.
6. **Separator** — hairline · accent diamond · hairline.
7. **Qur'an ayah block** (see §4) — the emphasized scripture.
8. **Day-arc loader** (see §5) — bottom, with "Preparing your space".
9. **Horizon glow** — soft accent radial at the bottom edge.

---

## 2. Background & text (per theme)

`accent` drives ornaments, glow, ring, halo, loader-less accents. `rgba(accent,α)` = accent at alpha α.

| Theme | Background (radial) | ink | muted | faint | accent | orb A→B | stars |
|---|---|---|---|---|---|---|---|
| **Fajr** | `radial-gradient(125% 82% at 50% 28%, #1c2147, #141a36 44%, #0c1024)` | `#f7eef0` | `#d8a9b4` | `#b78996` | `#eaa9b2` | `#fce8ec`→`#eaa9b2` | 30 + 4 |
| **Dhuhr** *(light)* | `radial-gradient(125% 82% at 50% 24%, #a9cbe8, #c9deef 46%, #eef2f1)` | `#22323f` | `#4f6473` | `#6f8593` | `#d99a2a` | `#fff6df`→`#f0c24e` | 0 |
| **Asr** | `radial-gradient(125% 82% at 50% 26%, #3a4d72, #5f5872 48%, #8a684f)` | `#f7ede1` | `#d9b48f` | `#b3906f` | `#e8b87e` | `#fbeeda`→`#e8b87e` | 10 + 2 |
| **Maghrib** | `radial-gradient(125% 82% at 50% 24%, #3a1f54, #6a2c54 42%, #a23f44)` | `#fbeede` | `#e6b095` | `#bd8771` | `#f4a86a` | `#ffe9d4`→`#f4a86a` | 16 + 3 |
| **Isha** *(default)* | `radial-gradient(125% 80% at 50% 30%, #251f40, #16142a 50%, #0b0a14)` | `#f4f1fa` | `#a39db6` | `#7d7790` | `#9a86c7` | `#d6c9ee`→`#9a86c7` | 48 + 7 |

`glow` = accent at ~0.9 alpha (rgba). Star colour: `rgba(244,241,250,0.95)` on dark, `rgba(34,50,63,0.6)` on Dhuhr.

---

## 3. The orb (centerpiece)

`orbWrap` 196×196, intro `orbIn 1.3s cubic-bezier(.2,.7,.2,1) both .1s`.
- **Stable outer ring:** `inset:-22px; border-radius:50%; border:1px solid rgba(accent,0.22); filter: blur(2.5px)`. *(soft, not crisp)*
- **Pulse halo:** `inset:-2px; border:1px solid rgba(accent,0.4); animation: pulseRing 4.5s ease-out infinite`.
- **Aura:** `inset:16px; radial-gradient(circle at 50% 42%, glow, rgba(255,255,255,.05) 60%, transparent 72%); filter: blur(4px); animation: breathe 7s`.
- **Core:** `inset:52px; radial-gradient(circle at 42% 36%, orbA, orbB 72%); box-shadow:0 0 64px glow; animation: breathe 7s`.

---

## 4. Qur'an ayah treatment (IMPORTANT)

Presented as scripture, NOT a slogan — the Arabic revelation is the emphasized hero, the English a secondary gloss.

```
﴿ أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ ﴾      ← Amiri 17px, color ink; ﴿ ﴾ ornaments 19px in accent
“…in the remembrance of Allah do hearts find rest.”  ← Cormorant italic 15px, muted (translation)
SŪRAT AR-RAʿD · 13:28                                 ← 10.5px, ls 1.8px, uppercase, faint (citation)
```

- The **﴿ ﴾ ornamental verse brackets** (U+FD3F / U+FD3E) signal Qur'anic text and are coloured `accent`.
- English is in quotes + italic so it reads as a humble translation.
- Citation anchors authenticity.

---

## 5. Day-arc loader (signature)

A thin bar that fills through the five prayer colours — "loading" is the day passing.
- **Track:** `width:156px; height:3px; border-radius:3px; overflow:hidden; background: rgba(255,255,255,0.1)` (dark) / `rgba(34,50,63,0.16)` (Dhuhr).
- **Fill:** `linear-gradient(90deg, #eaa9b2, #d99a2a, #e8b87e, #f4a86a, #9a86c7); transform-origin:left; animation: loadFill 2.3s cubic-bezier(.4,0,.2,1) both .55s` (scaleX 0→1).
- **Status above:** "Preparing your space" — 11px, ls 2px, uppercase, faint.

---

## 6. Animation timeline (intro, plays once; ambient loops)

| Element | Keyframe | Delay |
|---|---|---|
| Horizon glow | fadeIn 1.6s | .3s |
| Light line | lineGrow 1.4s | .2s |
| Loader track | fadeIn .8s | .45s |
| Loader fill | loadFill 2.3s | .55s |
| Invocation | fadeIn 1s | .35s |
| Orb | orbIn 1.3s | .1s |
| Wordmark | riseIn .95s | .75s |
| Separator | fadeIn .9s | 1.05s |
| Ayah (Arabic) | fadeIn .9s | 1.2s |
| Translation | fadeIn .9s | 1.36s |
| Citation | fadeIn .9s | 1.48s |
| Status | fadeIn 1s | 1.5s |

Ambient (loop forever): `breathe` (orb aura+core, 7s), `pulseRing` (halo, 4.5s), `twinkle` (stars), `sparkle` (sparkles).

Keyframes: `breathe, pulseRing, twinkle, sparkle, orbIn, riseIn, fadeIn, loadFill, lineGrow`.

---

## 7. Fonts
- **Cormorant Garamond** — wordmark, translation (italic).
- **Manrope** — tagline/status/citation.
- **Amiri** — invocation + ayah (RTL).

---

## 8. Prop
- `theme`: `fajr | dhuhr | asr | maghrib | isha` (default `isha`). Recolours sky, orb, glow, starfield, ornaments, line, horizon.
