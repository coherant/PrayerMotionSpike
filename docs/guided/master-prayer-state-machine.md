# Master Prayer State Machine

Single source of truth for all guided prayer sequences.
Block definitions: `rakats.md`
Prayer content: `prayer-sets/{prayer}.md`
Prayer text library: `../prayers/prayers.md`

## Notes
- A guided sequence is an **observance** — a chain of units (see `observances.md`). The notes below describe one unit; boundary behaviour between units is in `observances.md`.
- The **first** unit of an observance opens `timed` — entry `I-1`, then `I-24` (when hasOpeningCue), the niyet, then Al-Fatiha + surah
- A **subsequent** unit opens `motion` (stand to begin) — `I-24` cue + renewed niyet, **no** `I-1` intro; opening rows are `.pace`
- All other Qiyams within a unit are `motion`
- Yaw baseline is captured at runtime at each unit's **final sitting**, the instant before its first TASLEEM head-turn (after the unit's sujoods, so the AirPods heading hasn't drifted) — it is **not** a sequence flag
- The `I-1` intro fires **once** per observance; the `P-23` closing dua sounds **once** at the observance's final TASLEEM

## Unit identity

A **unit** is one complete prayer from niyet to Tasleem. It is the atom the
generator builds; the **observance** layer that chains multiple units per
prayer-time is specified in `observances.md`.

The unit model is **canonical, not guided-specific**: it is `PrayerUnit` in
`SalatType.swift`, and `SalatType.units` already lists each prayer-time's full
composition in order (built for prayer-setup). The guided generator consumes that
same model — it does not define its own.

A unit's *structural* identity:

| Field | Meaning | Values today |
|---|---|---|
| `kind` | role within its observance | `fard` · `sunnahBefore(emphasised)` · `sunnahAfter(emphasised)` · `witr` |
| `rakats` | number of rakats | 2 · 3 · 4 |

Whether a unit recites the **Qunut** dua in its final standing is *derived* from
`kind == .witr` — not a stored field. The unit's *content* (niyet name, the two
surahs, whether it opens with the `I-24` stand-upright cue) is carried separately
— see `prayer-sets/{prayer}.md`.

A guided sequence is the **observance** — the selected units of `SalatType.units`
chained in order (`observances.md`). Each unit's shape is fully determined by
`rakats` and the derived Qunut flag:

- `rakat1` RAKAT_FULL · `rakat2` RAKAT_FULL
- if `rakats >= 3`: SHORT_TASHAHHUD, then RAKAT_FATIHA_ONLY rakats up to `rakats`
  — Qunut folded into rakat 3 for Witr
- FULL_TASHAHHUD then TASLEEM at `rakats` — the yaw baseline is captured at the final
  sitting just before TASLEEM (runtime, in the phase runner)

---

## Fajr

### Fajr Sunnah (2 rakats — before Fard)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | FULL_TASHAHHUD | 2 |
| 4 | TASLEEM | 2 |

Content: `prayer-sets/fajr.md` · Phase count: 15

---

### Fajr Fard (2 rakats)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | FULL_TASHAHHUD | 2 |
| 4 | TASLEEM | 2 |

Content: `prayer-sets/fajr.md` · Phase count: 15

---

## Dhuhr

### Dhuhr Sunnah Before (4 rakats — before Fard)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 |
| 5 | RAKAT_FATIHA_ONLY | 4 |
| 6 | FULL_TASHAHHUD | 4 |
| 7 | TASLEEM | 4 |

Content: `prayer-sets/dhuhr.md` · Phase count: 28

---

### Dhuhr Fard (4 rakats)

Same block sequence as Dhuhr Sunnah Before.
Content: `prayer-sets/dhuhr.md` · Phase count: 28

---

### Dhuhr Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/dhuhr.md` · Phase count: 15

---

## Asr

### Asr Sunnah (4 rakats — before Fard · Ghair Mu'akkadah)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/asr.md` · Phase count: 28

---

### Asr Fard (4 rakats)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/asr.md` · Phase count: 28

---

## Maghrib

### Maghrib Fard (3 rakats)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 |
| 5 | FULL_TASHAHHUD | 3 |
| 6 | TASLEEM | 3 |

Content: `prayer-sets/maghrib.md` · Phase count: 22

---

### Maghrib Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/maghrib.md` · Phase count: 15

---

## Isha

### Isha Fard (4 rakats)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/isha.md` · Phase count: 28

---

### Isha Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/isha.md` · Phase count: 15

---

### Witr (3 rakats — after Isha Sunnah)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 |
| 5 | FULL_TASHAHHUD | 3 |
| 6 | TASLEEM | 3 |

Content: `prayer-sets/witr.md` · Phase count: 22

Note: Witr includes Qunut dua in the final Qiyam — unique to this prayer set.

---

## Phase mode definitions

| Mode | Behaviour |
|---|---|
| `timed` | Plays entry speech, plays prayer rows in sequence, plays exit speech |
| `motion` | Waits indefinitely for confirmed motion (reprompts every reprompt interval), plays entry speech, plays prayer rows in sequence, plays exit speech |
| `listen` | **Container (Muezzin) row.** A single call/recitation (`callID`, no `motionTrigger`, no rakat) — auto-paced, advances when the recitation completes; tap-to-advance hatch. See `CONGREGATIONAL-CONTAINER.md` §4. |
| `count` | **Container (Muezzin) row.** A counted dhikr (`callID`, `count` from `calls.json`) — the worshipper repeats to the count via the tasbīḥ counter; tap-to-advance hatch. |

**Container rows are exempt from Silent Mode.** Silent Mode withdraws the voice *inside* the
salah (the body is the clock); the Muezzin's frame *around* it is meant to be heard, so
`listen`/`count` rows always run their own runner even when `guidanceLevel == .silent`.

## Recitation audio (clip identity)

Each prayer line in a state carries an optional **clip identity** alongside its rendered text:

`PrayerLine = (clipID: PrayerID?, utterance: String, duration: PrayerDuration)`

- `clipID` — the recitation's canonical id (a `P-` id, e.g. `P-7` Al-Fātiḥa, `P-11` Al-Ikhlāṣ).
  Present for Qur'an/prayer recitations; `nil` for coaching cues, niyet, and calibration prompts
  (those are **guidance** — voiced via the separate guidance-audio path below, not `clipID`).
- `utterance` — the rendered, translated text (used for display, the golden snapshot, and TTS).
- `duration` — a **pause after** the utterance, not a budget the audio must fit inside.

At runtime the speaker resolves `clipID` → a recorded file named
**`<reciterId>-<language>-<P-id>.m4a`** (e.g. `muallim-ai-ar-P-7.m4a`) — a reciter can be
multilingual, so the selected **Language** picks the track. Files are **flat and uniquely
named** in `Resources/recitations/`, so the synced-folder bundle resolves them by name (the
resolver also checks a `recitations/` subfolder); `.m4a` or `.caf` are accepted. If a clip is
installed it is **played and awaited to completion** (the teacher leads), otherwise it **falls
back to TTS** of `utterance`.
A missing clip is expected, not an error — so recordings can be dropped in incrementally and
partial sets work. The await-to-completion contract is what keeps recitation from being
truncated by the `.pace` pause regardless of clip length.

**Guidance audio (entry / exit / reprompt).** The coaching instructions (`I-` ids) are voiced
the same way, by the guider **Murshid AI**: at runtime `speakGuidance(text)` recovers the `I-`
id from the rendered text (via `InstructionLibrary.instructionID(matching:_:)` — a reverse map
built from the same `InstructionLibrary.text` source, so it is drift-free) and resolves a file
named **`<guiderId>-<language>-<I-id>.m4a`** (e.g. `murshid-ai-en-I-15.m4a`), played-and-awaited
else TTS. The id is recovered from text rather than threaded through `PrayerState`, so the
sequence structure and the golden snapshot are unchanged. Templated guidance (e.g. `I-25`
"…for {prayer}") won't round-trip after substitution → TTS (it can't be a single recording).
Guidance language is independent of recitation (`UserPreferences.guidanceLanguage`).

The golden snapshot serialises `clip=<P-id>` only when non-nil, so adding clip identity is a
behaviour-preserving enrichment of the existing sequence (no timing/structure change).

## Motion detection thresholds

See `../calibration/master-prayer-state-machine.md` for calibrated threshold values.
