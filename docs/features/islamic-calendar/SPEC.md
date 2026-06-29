# Islamic Calendar & Sacred Days — SPEC (draft / thinking doc)

**Status:** draft for discussion — not yet built.
**Purpose:** capture every recurring Islamic sacred day/night as data, and resolve each to a
**Gregorian date (and the exact night/day instant)** for a given location, so features
(theming, the nature/weather sky, reminders, "tonight is Laylat al-Qadr" banners, fasting
trackers) can be built against a single source of truth.

Companion reference (the human-readable catalogue this formalises): the table in
`docs/` chat notes / README. Existing engine to lean on: `PrayerTimesEngine` (already gives
`date(for: .maghrib)`, `sunrise`, `timeZone`, location).

---

## 1. Goals / non-goals

**Goals**
- One **catalogue** (JSON) of sacred days/nights, with school (Sunnī/Shīʿa) + "contested" flags.
- A **conversion engine**: Hijri (month, day) → the Gregorian date(s) in a given window, for a
  given location, **honouring that the Islamic day starts at sunset**.
- A small **query API**: "what's today / tonight?", "next occasion", "occasions in this
  Gregorian month/range".

**Non-goals (v1)**
- Predicting *actual local moon-sighting* (impossible to compute exactly — see §3).
- Being a full Hijri calendar UI. We compute dates to *drive features*, not to replace a calendar app.

---

## 2. Why this is hard (the constraints that shape the design)

1. **Lunar drift.** The Hijri year ≈ 354 days, so a fixed Hijri date moves **~10–11 days earlier**
   each Gregorian year. A given Hijri date can occur **0, 1, or 2 times** in one Gregorian year.
2. **The day starts at sunset.** 10 Muḥarram "begins" at **Maghrib of the preceding civil day**.
   So a **night** event (Laylat al-Qadr, Isrāʾ wal-Miʿrāj) is anchored to the **eve** — the
   evening *before* the civil date that carries the Hijri day number.
3. **Moon-sighting variance.** The real start of a month depends on **local sighting** (or an
   authority's), which differs by region and can be **±1 (sometimes ±2) days** from any computed
   calendar. We can compute the **astronomical new moon (conjunction)**, but *visibility* ≠ conjunction.
4. **Makkah vs local.** ʿArafah and the two ʿĪds are tied to the **Ḥajj / Saudi (Umm al-Qurā)**
   determination, **not** the user's local month — many communities follow Makkah for these even
   when local Ramaḍān differs. The model must let an event declare its **authority**.
5. **Ranges, not just days.** Laylat al-Qadr = a *set* of odd nights; first-10 of Dhul-Ḥijjah,
   Days of Tashrīq, six-of-Shawwāl, white days = *spans/recurrences*, not single dates.
6. **School differences.** Mawlid date differs (12 vs 17 Rabīʿ I); some events are observed by
   some communities and not others. Data must carry **flags**, features decide what to show.

---

## 3. The core decision — which Hijri basis? (`<>`)

This is the `<>` in "calculate the Gregorian date based on the `<>` Hijri date." Options:

| Option | Source | Pros | Cons |
|---|---|---|---|
| **A. Umm al-Qurā** | `Calendar(identifier: .islamicUmmAlQura)` (Foundation, built-in) | Saudi/Ḥajj standard; deterministic; zero deps; matches what most apps + Makkah use | Still ±1 day vs *local* sighting |
| **B. Tabular / Civil** | `.islamicTabular` / `.islamicCivil` | Pure arithmetic, fully offline | Can drift further from observed dates |
| **C. Astronomical** | new-moon conjunction via **SwiftAA** (already a dependency) | "True" lunar phase | Conjunction ≠ visibility; more work; still not "sighting" |
| **D. Sighting feed / manual** | external authority or user override | Matches a community exactly | Needs network/data + upkeep |

**Recommendation:** **A (Umm al-Qurā) as the computed baseline**, because it's built into iOS,
deterministic, offline, and is the de-facto reference for Ḥajj/ʿĪds — **plus**:
- a **per-event `authority`** (`makkah` vs `local`) so ʿArafah/ʿĪds always resolve via Umm al-Qurā
  even if we later add a local basis for Ramaḍān;
- a **global adjustment offset** (`−2…+2` days) the user/region can set to align with their masjid;
- a **manual override** hook for the dates that matter most (Ramaḍān start, the two ʿĪds), since
  those are announced.

We **document the ±1 day caveat everywhere** and never present a computed ʿĪd as gospel without
the override path. (C/SwiftAA can come later to *show* the moon phase in the nature sky, separate
from date resolution.)

---

## 4. Data model (the catalogue)

A master JSON (`Resources/islamic-events.json`), decoded by an `IslamicEventLibrary` — same
pattern as `prayers.json` / `calls.json`.

```jsonc
{
  "events": [
    {
      "id": "laylat-al-qadr",
      "name": "Laylat al-Qadr",
      "arabic": "ليلة القدر",
      "recurrence": "annual",          // annual | monthly | weekly
      "hijri": { "month": 9, "days": [21, 23, 25, 27, 29] }, // a set → range/odd nights
      "kind": "night",                 // night | festival | fast | observance | hajj | sacred-month
      "nightAnchored": true,           // begins at Maghrib of the eve
      "authority": "local",            // local | makkah
      "schools": ["sunni", "shia"],
      "contested": false,
      "emphasis": "27",                // optional: most-emphasised day in the set
      "notes": "Sought in the odd nights of the last ten of Ramaḍān."
    },
    {
      "id": "mawlid",
      "name": "Mawlid al-Nabī ﷺ",
      "arabic": "المولد النبوي",
      "recurrence": "annual",
      "hijri": { "month": 3, "day": 12 },
      "kind": "observance",
      "authority": "local",
      "schools": ["sunni"],
      "contested": true,               // scholarly difference on observance
      "variants": [ { "schools": ["shia"], "hijri": { "month": 3, "day": 17 } } ]
    },
    {
      "id": "arafah",
      "name": "Day of ʿArafah",
      "arabic": "يوم عرفة",
      "recurrence": "annual",
      "hijri": { "month": 12, "day": 9 },
      "kind": "fast",
      "authority": "makkah",           // follows Umm al-Qurā / Ḥajj, not local
      "schools": ["sunni", "shia"]
    },
    {
      "id": "ayyam-al-bid",
      "name": "Ayyām al-Bīḍ (White Days)",
      "arabic": "أيام البيض",
      "recurrence": "monthly",
      "hijri": { "days": [13, 14, 15] }, // every lunar month
      "kind": "fast",
      "schools": ["sunni", "shia"]
    },
    {
      "id": "jumuah",
      "name": "Jumuʿah",
      "recurrence": "weekly",
      "weekday": "friday",
      "kind": "observance"
    }
  ]
}
```

**Field notes**
- `recurrence`: `annual` (Hijri month+day/days), `monthly` (Hijri day(s) every month),
  `weekly` (Gregorian weekday).
- `hijri.day` (single) **or** `hijri.days` (set → multi-night/range).
- `kind`: drives styling/iconography + behaviour (e.g. `fast` → fasting tracker; `night` → eve banner).
- `nightAnchored`: if true, the occurrence's *start instant* is **Maghrib of the eve**.
- `authority`: `makkah` events always resolve via Umm al-Qurā; `local` may later use a local basis.
- `schools` / `contested` / `variants`: features filter by the user's tradition; contested ones
  can be opt-in. **Never assert a contested practice as universal.**
- A separate flag set marks the **Four Sacred Months** (Dhul-Qaʿdah, Dhul-Ḥijjah, Muḥarram, Rajab).

---

## 5. Time semantics (the night/day boundary)

For an occasion on Hijri (M, D):
1. Resolve the **civil (Gregorian) date** whose Hijri value is (M, D) via the chosen calendar.
2. Build a concrete **interval** in the location's timezone:
   - **Day events** (`nightAnchored: false`): `[Fajr(D) … Maghrib(D)]` (or full civil day, per feature).
   - **Night events** (`nightAnchored: true`): **starts at `Maghrib(D−1 civil)`** and runs to
     `Fajr(D)` (the worship night). i.e. "the 27th night" = sunset of the 26th → dawn of the 27th.
3. Maghrib/Fajr come from `PrayerTimesEngine` for the location — so the calendar is **location-aware**
   and ties into the same engine the rest of the app uses.

This is the subtle bit features care about: a "tonight is Laylat al-Qadr" banner must light up
**at Maghrib the evening before** the civil 27th, not at midnight.

---

## 6. Resolution algorithm (Hijri → Gregorian occurrences in a window)

Given a Gregorian window `[from, to]` and a location:
1. Determine the Hijri year(s) overlapping the window (usually 1–2).
2. For each event × each overlapping Hijri year × each `day` in its set:
   - `date(from: DateComponents(calendar: ummAlQura, year: hYear, month: M, day: D))`
   - apply the **adjustment offset** and any **manual override**;
   - compute the night/day **interval** (§5);
   - keep it if it intersects `[from, to]`.
3. Expand `monthly`/`weekly` recurrences across the window.
4. Return sorted occurrences (each: event id, school/contested flags, interval, "is now").

Handles the **0/1/2 occurrences per Gregorian year** case naturally (it's window-based, not year-based).

---

## 7. Engine API (sketch)

```swift
struct IslamicOccurrence {
    let event: IslamicEvent
    let interval: DateInterval   // location-aware; night events start at Maghrib of the eve
    let hijri: (year: Int, month: Int, day: Int)
}

enum IslamicCalendar {
    static var adjustmentDays: Int { get set }            // −2…+2, per region/masjid
    static func occurrences(in window: DateInterval, at: ObserverLocation) -> [IslamicOccurrence]
    static func today(at: ObserverLocation) -> [IslamicOccurrence]      // active now (incl. tonight)
    static func next(after: Date, at: ObserverLocation) -> IslamicOccurrence?
    static func hijriDate(for: Date) -> (year: Int, month: Int, day: Int)  // also drives a date badge
}
```

---

## 8. Feature hooks (why we're building it)

- **Theming / nature sky:** special-night sky treatment (e.g. Laylat al-Qadr glow), Ramaḍān motif,
  ʿĪd palette — driven by `today()` and `kind`. Pairs with the existing `DayTheme`/weather work.
- **Banners / reminders:** "Tonight is the 27th night", "Fast tomorrow — ʿArafah", ʿĪd greetings.
- **Fasting tracker:** `kind: fast` events (ʿĀshūrāʾ, ʿArafah, white days, Shawwāl six, Mon/Thu).
- **Hijri date badge** anywhere in the app.
- All location-aware via `PrayerTimesEngine`; all filterable by the user's school.

---

## 9. Phasing

- **P0 — catalogue + conversion:** `islamic-events.json` (annual events) + `IslamicEventLibrary` +
  Umm al-Qurā resolution + `hijriDate(for:)`. No UI. Unit tests on known dates.
- **P1 — night-accurate + query API:** Maghrib-anchored intervals via `PrayerTimesEngine`;
  `today()`/`next()`/`occurrences(in:)`; ranges + monthly/weekly recurrences.
- **P2 — alignment controls:** adjustment offset + manual overrides (Ramaḍān/ʿĪds) + `authority`
  (Makkah vs local); school filter in settings.
- **P3 — features:** theming, banners, fasting tracker, badge.

---

## 10. Open questions (for you)

1. **Hijri basis** — confirm **Umm al-Qurā** baseline + adjustment offset + overrides? Or do you
   want astronomical (SwiftAA) or a sighting feed from day one?
2. **School scope** — Sunnī-only first, or Sunnī + Shīʿa (with filter) from the start? How do we
   handle **contested** observances (hide / opt-in / show with a note)?
3. **Makkah-vs-local** — do ʿArafah/ʿĪds always follow Umm al-Qurā (recommended), or follow the
   user's local setting?
4. **Override UX** — who sets Ramaḍān/ʿĪd overrides (the user, or a future remote feed)?
5. **Scope of catalogue** — just the table we drafted, or also lesser-known days (Laylat al-Raghāʾib,
   Tāsūʿāʾ, regional observances)?
6. **Accuracy bar** — is "±1 day, adjustable" acceptable for v1 features, or must ʿĪds be exact
   (→ needs the override/feed)?

> Religious-content note: dates and observances here are general/computed aids, **not** a fatwa.
> Contested practices are flagged; ʿĪd/Ramaḍān should always defer to the user's authority.
> Recommend scholarly/community review of the catalogue before shipping date-driven claims.
