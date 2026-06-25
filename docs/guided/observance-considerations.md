# Observance Layer — Considerations (NOT YET IMPLEMENTED)

> **Status: parked / forward-looking.** Nothing in this document describes current
> behavior. The live spec (`README.md`, `master-prayer-state-machine.md`,
> `prayer-sets/*.md`, `rakats.md`) and the shipped code build **one self-contained
> unit** that ends at TASLEEM. This file collects the design for the *future*
> observance layer that will chain units together. It is the seed of the eventual
> `observances.md` (Stage 3 of `REFACTOR-PLAN.md`). Do not translate any of this
> into code until that stage.

Vocabulary: **phase → unit → observance → prayer-time (SalatType)**.
A `unit` is one niyet→TASLEEM prayer. An `observance` is the ordered chain of units
prayed at a given prayer-time.

---

## 1. Opener lifetime (parked from README invariant)

Today the code emits both openers **inside every unit's opening block**:
- `I-1` (the intro / "This is the instructional prayer…") as the timed block's
  `entrySpeech`.
- `I-24` ("Stand upright and put your hands by your side.") as a 5s prayer row,
  gated by `hasOpeningCue` (present for the 5 daily prayers, absent for Witr).

**Intended future behavior:** these are *observance-level* openers — they should fire
**once, at the start of the observance**, not be repeated at the head of every unit.
The niyet (`I-25`) is the exception: it is *unit-level* and renews per unit.

This relocation is part of the observance layer; it changes the emitted sequence and
must wait for Stage 3 + Stage 4.

## 2. Composition — which units make an observance

The master doc lists the units; the observance layer must define their ordered
composition and inclusion rules. Proposed table (Hanafi-flavoured — see decision 4):

| Prayer-time | Units (in order) |
|---|---|
| Fajr | `SunnahBefore-2` → `Fard-2` |
| Dhuhr | `SunnahBefore-4` → `Fard-4` → `SunnahAfter-2` |
| Asr | `SunnahBefore-4` (ghair mu'akkadah) → `Fard-4` |
| Maghrib | `Fard-3` → `SunnahAfter-2` |
| Isha | `Fard-4` → `SunnahAfter-2` → `Witr-3` |

Open: are Sunnah units always included, or user-toggleable (a Fard-only mode)?

## 3. Transition semantics — what happens at a unit boundary

To be specified precisely (each choice changes the emitted array):
- niyet (`I-25`) **replays** for each unit.
- `I-1` intro fires **once** (observance start).
- `I-24` stand-upright fires per the decision below.
- the `timed` pie-timer opening **restarts** each unit (each unit is its own
  niyet→TASLEEM).
- closing dua `P-23` placement (see §5).

## 4. Niyet identity

`I-25` is currently templated only on the prayer-*time* (`{prayer}` = "Fajr"). A
multi-unit observance needs the niyet to name the **unit** — "the Sunnah of Fajr"
vs "the Fard of Fajr". The template (or the unit model) must carry unit identity.

## 5. Closing dua `P-23` placement

Every unit's `tasleem-left` currently ends with `exit | P-23` (the closing dua).
When units chain, decide: does `P-23` fire at the end of **every** unit, or **once**
at the observance's final TASLEEM?

---

## Parked micro-enhancements

- **`I-1` 5s hold.** The prayer-sets originally gave the `I-1` intro a 5s duration,
  but `entrySpeech` has no duration slot, so the code speaks `I-1` without holding.
  Stage 0 neutralized the `5s` (→ `—`) to keep spec faithful to code. If we want the
  intro to actually hold 5s, add an entry-hold mechanism to `PrayerState` /
  `PrayerStateMachine` (small, snapshot-visible change).

---

## Open decisions (gate Stage 3)

1. **Sunnah inclusion** — always-on, or user-toggleable (Fard-only mode)?
2. **`I-24` home** — keep per-unit for now and hoist to observance-level in Stage 3,
   or hoist immediately?
3. **`P-23` closing dua** — end of every unit, or once at observance end?
4. **Madhab scope** — lock Hanafi-flavoured (3-rakat Witr, Asr sunnah ghair
   mu'akkadah), or make the unit model madhab-parameterised later?
