# SalahMotion — Complication Specification
**Handoff · WidgetKit · Build-Ready**
Apple Watch 45mm · Four accessory families · July 2026

---

## Summary

| Family | Slot (45mm) | Primary Content | Gauge | Symbol | Mono-Legible |
|---|---|---|---|---|---|
| `accessoryInline` | ~171 × 18 pt | 5-pip position · name · countdown | None | None | Pip size |
| `accessoryCircular` | 44.5 pt dia. | Ring gauge · crescent · countdown · name | Prayer-day cycle | Crescent (custom) | Arc + shape |
| `accessoryCorner` | Corner wedge | 90° day arc · 5 markers · crescent | Prayer-day cycle | Crescent (custom) | Arc + dots |
| `accessoryRectangular` | 169 × 54 pt | Crescent · name · countdown · timeline | Horizontal timeline | Crescent (custom) | Dot pos. + size |

---

## 01 · accessoryInline — Winner: Variation B

**Slot:** `accessoryInline` · ~171 × 18 pt · 45mm face

### Content & Layout

| | |
|---|---|
| **Content** | 5 pips (prayer order) · next prayer name · live countdown |
| **Pips** | 5 × 5 pt inactive · 6 × 6 pt active (current/next prayer). Monochrome: size only differentiates position |
| **Hierarchy** | **Countdown** primary · Name secondary · Pips tertiary |
| **Symbol** | None at this scale — crescent omitted for legibility |
| **Truncation** | Name ≤ 7 chars: full · > 7 chars: 4-char code (MGHB, DHUHR, FAJR, ASR, ISH) |
| **Countdown** | ≥ 10 min: `"41m"` · < 10 min: `"9:23"` · < 1 min: `"Now"` |

### Tint Behaviour
Pip **size** (not color) encodes day position. Name + countdown carry meaning in any single tint color. All elements are rendered in the face's selected tint — no color dependency.

### States

| State | Display |
|---|---|
| Countdown | `●●●●○  Maghrib  41m` |
| At prayer | `●●●●●  Maghrib  Now` |
| AOD | Same layout, system-dimmed luminance |

---

## 02 · accessoryCircular — Winner: Variation B

**Slot:** `accessoryCircular` · 44.5 pt diameter · 45mm face

### Content & Layout

| | |
|---|---|
| **Ring** | r = 38 pt · stroke = 4.5 pt · clockwise from 12 o'clock · open gap at trailing end |
| **Gauge logic** | Represents prayer day cycle: Isha → Fajr → Dhuhr → Asr → Maghrib → Isha. Fills clockwise. 5 milestones at 72° intervals. |
| **Milestone dots** | r = 2.9 pt inactive · r = 3.4 pt active. Positions: 0°, 72°, 144°, 216°, 288° from 12 o'clock. Color = prayer palette hue (full color); tint color (mono). |
| **Crescent** | Custom Path asset · 30 pt · centred. SF Symbol fallback: `moon.fill` (reduced fidelity) |
| **Hierarchy** | **Ring arc position** primary · Countdown 17 pt (DM Mono) secondary · Name 7 pt tertiary |
| **Countdown** | ≥ 10 min: `"41m"` · < 10 min: `"9:23"` · < 1 min: `"Now"` |

### Gauge: Full Color Gradient (Smart Stack)
Ring gradient clockwise from 12 o'clock:
- **0% (Isha):** `#4848a8`
- **25% (Fajr):** `#6878c0`
- **50% (Dhuhr):** `#8fb8df`
- **75% (Asr):** `#c89030`
- **100% (Maghrib):** `#e09830`

### Tint Behaviour
Ring arc + crescent silhouette readable in any single tint. Milestone dot **sizes** (not colors) encode position in the prayer cycle.

### States

| State | Behaviour |
|---|---|
| Countdown | Ring fills to current milestone; countdown decrements |
| At prayer | Active dot pulses once on prayer entry; countdown shows "Now" → counts up (elapsed) |
| AOD | Ring arc + crescent visible; number simplified |

---

## 03 · accessoryCorner — Winner: Variation B

**Slot:** `accessoryCorner` · curved corner wedge

### Content & Layout

| | |
|---|---|
| **Arc** | 90° gauge · r = 76 pt from corner · stroke = 5 pt · sweeps from outer top edge to outer side edge |
| **Gauge logic** | Same prayer-day cycle as Circular. 5 dots spaced along 90° arc (~18° apart). |
| **Milestone dots** | r = 3 pt inactive · r = 3.8 pt active. On arc path. Full color: prayer palette hue. Mono: same tint. |
| **Crescent** | Custom Path asset · ~18 pt · inner corner area. No text — insufficient space at corner scale. |

### Tint Behaviour
Arc position on 90° sweep encodes prayer cycle. Dot positions encode which prayer is current. Crescent silhouette readable at any tint.

### States

| State | Behaviour |
|---|---|
| Countdown | Arc fills; dot at current prayer is active (larger) |
| At prayer | Active dot pulses once on prayer entry |
| AOD | Arc outline + crescent remain visible |

---

## 04 · accessoryRectangular — Winner: Variation A

**Slot:** `accessoryRectangular` · 169 × 54 pt · 45mm face

### Content & Layout

| | |
|---|---|
| **Row 1** | Crescent (11 pt) · Prayer name (16 pt, weight 500) · Countdown (26 pt DM Mono, right-aligned) |
| **Row 2** | Prayer timeline — horizontal line full width · 5 dots · prayer name labels 7 pt |
| **Timeline positions** | Fajr, Dhuhr, Asr, Maghrib, Isha (proportional to actual prayer times) |
| **Gauge logic** | Horizontal line filled from Fajr (left) to current prayer position. Progress dot r = 4 pt active, r = 2.5 pt inactive. |
| **Hierarchy** | **Countdown (26 pt)** primary · Name (16 pt) co-primary · Crescent tertiary · Timeline labels quaternary |
| **Truncation** | All 5 prayer names fit at 16 pt medium. Countdown: ≥ 10 m = `"41m"` · < 10 m = `"9:23"` · < 1 m = `"Now"` |

### Timeline Dot Opacities
- Past prayers: r = 2.5 pt, 30% opacity
- Current prayer: r = 4 pt, 100%
- Future prayers: r = 2.5 pt, 15% opacity

### Tint Behaviour
Crescent shape, name weight, countdown size, and timeline dot position + size all survive monochrome stripping.

### States

| State | Behaviour |
|---|---|
| Countdown | Timeline fills to current dot; countdown decrements |
| At prayer | "Now" replaces countdown; active dot pulses once |
| AOD | Crescent + name + timeline visible; countdown simplified |

---

## 05 · Curated Onboarding Face — Sentinel

**Face:** Infograph Modular (native Apple Watch face)
**Delivered via:** "Add Watch Face" button in first-run onboarding — pre-places all 4 families in correct slots.

### Slot Assignments

| Slot | Family | Content |
|---|---|---|
| **A** — Top bar | `accessoryInline` (Var B) | `●●●●○  Maghrib · 41m` — pips + name + countdown |
| **B** — Upper left circular | `accessoryCircular` (Var B) | Day-cycle gauge ring + crescent + `"41m"` + name |
| **C** — Upper right circular | `accessoryCircular` (simpler) | Crescent motif only |
| **D** — Lower full-width | `accessoryRectangular` (Var A) | Crescent + prayer name + countdown + full timeline |

### Tint Behaviour

The app pushes a new `CLKComplicationTemplate` tint on each prayer transition:

| Prayer | Tint | Description |
|---|---|---|
| Fajr | `#6878c0` | Cool blue-violet |
| Dhuhr | `#8fb8df` | Soft sky blue |
| Asr | `#c89030` | Warm gold |
| Maghrib | `#c87030` | Sunset amber |
| Isha | `#4848a8` | Deep indigo |

**Trigger:** App schedules `CLKComplicationServer.reloadTimeline()` at each prayer start time. New tint delivered via `getComplicationDescriptors` / `getCurrentTimelineEntry`.

---

## Assets Required

| Asset | Description | Usage |
|---|---|---|
| `crescent-path` | Custom Path/Shape asset (NOT SF Symbol) — a crescent moon with the characteristic Islamic crescent form. Stroke-only, no fill, no facial features. | accessoryCircular, accessoryCorner, accessoryRectangular |
| Prayer time data | Calculated locally from coordinates + date using adhan library or equivalent | All complications — countdown, timeline positions |

## Implementation Notes

- All complications must implement `TimelineEntry` with `relevantDate` for live countdown updates
- `accessoryCircular` gauge: use `SwiftUI.Gauge` with `gaugeStyle(.accessoryCircular)` — do not render the ring manually
- `accessoryCorner` gauge: use `gaugeStyle(.accessoryLinearCapacity)` is insufficient; use `accessoryCircular` style clipped to corner wedge, or `widgetLabel` + gauge combination
- Tint updates: schedule one timeline entry per prayer time per day; system will interpolate
- Crescent asset: deliver as PDF vector in asset catalog, set render mode to Template Image so system tint is applied
- Prayer name truncation: handle in `widgetBundle` entry point, not at render time
