# Observance Sequencer — Refactor Plan

Working document for the staged refactor on branch `observance-sequencer`
(baseline `ab7ae2e`). Goal: make the guided prayer state machine an
**idempotent function of the spec**, then add the **observance layer** that
chains multiple units (e.g. Fajr = Sunnah → Fard) instead of running one unit
that stops at TASLEEM.

This doc is the shared source of truth for the arc. It outlives sessions; keep
it current.

---

## Principles

1. **MD-first.** Update spec docs, then hand-translate Swift to match. Never the reverse.
2. **Golden snapshot is the spine.** Freeze today's emitted `[PrayerState]` arrays
   in a checked-in fixture. Behavior-preserving stages must reproduce it byte-for-byte;
   behavior-changing stages must show a reviewed, intentional diff.
3. **Park the future, sharpen the present.** The *live* spec describes only what the
   code does today — self-consistent, no forward references. All forward-looking
   design lives in `observance-considerations.md` until the stage that implements it.
4. **Make the unit deterministic before composing units.** No observance layer on a
   unit whose spec→build isn't already a pure function.
5. **Small, reversible stages.** Each compiles, builds, passes the snapshot.

---

## The two buckets

| Park (→ `observance-considerations.md`, "not yet implemented") | Sharpen in the live spec (current-truth) |
|---|---|
| I-1 / I-24 *lifetime* (observance-level / once) | Entry-row `5s` durations have no data-model slot — make the live spec match code (code ignores them) |
| Unit selection / order / inclusion | FATIHA_ONLY inheritance — state that its motion sub-phases reuse RAKAT_FULL's utterances |
| Unit-boundary transition semantics | |
| Unit-scoped niyet identity (Sunnah vs Fard) | |
| P-23 closing-dua placement across units | |

The contradiction we currently carry (README invariant #2 says I-1/I-24 are
observance-level "once" + a ⚠ gap note, while the prayer-set tables list them
per-unit) gets resolved by **moving the aspiration out** and reverting the live
invariant to describe current behavior plainly. `observance-considerations.md`
is not throwaway — it is the **seed of the Stage 3 `observances.md` spec**.

---

## Stages

### Stage 0 — Lock the current truth (spec) + golden snapshot
*Collapses the old Stage 0 + Stage 1. Mostly spec; one new test; no behavior change.*
- Create `observance-considerations.md`; move the I-1/I-24 lifetime + all
  composition design into it, clearly marked *not yet implemented*.
- Revert the live invariant (README §5 #2) to describe current behavior: opening
  is I-1 (entry) + I-24 (per-unit, gated by `hasOpeningCue`) + niyet + P-0 +
  Fatiha + surah + P-0. Remove the ⚠ spec↔code gap note.
- Sharpen #2: make the live spec honest about entry-row `5s` (code ignores it —
  remove it from the tables or annotate as non-timed).
- Sharpen #3: add the FATIHA_ONLY inheritance rule to `rakats.md`.
- Build the **golden snapshot test**: emit every `SalatType` + Witr, assert the
  array (id, mode, utterances, durations, motionTrigger, capturesYaw, rakatNumber)
  against a checked-in fixture.
- **Exit:** live spec self-consistent and faithful to code; snapshot green; a
  from-spec reader of one unit has zero legal forks.

### Stage 1 — (folded into Stage 0)

### Stage 2 — Introduce unit identity (model, no composition)
- Spec: formalize `Unit` identity `{ kind: sunnahBefore | fard | sunnahAfter | witr,
  rakatCount, hasQunut }`.
- Code: `PrayerUnit` value type; refactor generator to
  `generateUnit(_:isFirst:isLast:) -> [PrayerState]`. Keep `generate(salat:)` as a
  thin shim returning the single Fard unit.
- Retire the runtime `session` word in favor of `unit`/`observance`.
- **Exit:** snapshot green; model exists, nothing chains yet; fully reversible.

### Stage 3 — The observance layer (new)
- Promote `observance-considerations.md` → `observances.md`: the composition table
  (Fajr `[SunnahBefore-2, Fard-2]`, Dhuhr `[SunnahBefore-4, Fard-4, SunnahAfter-2]`,
  Asr `[SunnahBefore-4, Fard-4]`, Maghrib `[Fard-3, SunnahAfter-2]`,
  Isha `[Fard-4, SunnahAfter-2, Witr-3]`) + inclusion rules.
- Write the transition semantics: niyet replays per unit; I-1 fires once
  (observance start); I-24 per the parked decision; timed pie-opening restarts each
  unit; P-23 placement fixed.
- Code: `generate(observance:) = units.map { generateUnit($0, isFirst:, isLast:) }.flatMap`,
  with boundary handling.
- **Exit:** observance snapshot fixtures; the Stage-0 single-unit snapshot reproduced
  as the first unit of each observance.

### Stage 4 — Runtime + UI chaining (highest risk; device-tested)
- `PrayerStateMachine` iterates the chained array; per-unit rakat numbering + unit
  index; observance-spanning progress.
- `GuidedPrayerView` advances unit→unit at TASLEEM instead of completing; unit-boundary
  affordance ("Sunnah complete → begin Fard"); History records the observance.
- **No snapshot net here** — needs real-device iteration. Expect a round or two.

### Stage 5 — Content correctness
- Unit-scoped niyet (names Sunnah vs Fard); surah verification per unit; Witr opener
  decision; P-23 placement confirmed; P-23 Arabic/Turkish verification (outstanding).

### Stage 6 — Validation & cleanup
- Phase counts re-derived as observance totals (checksums, not generators).
- Re-verify every README invariant; final MD↔code↔JSON sync sweep.

---

## Ambiguity → stage

| # | Ambiguity | Stage |
|---|---|---|
| 1 | Opener-lifetime (per-unit vs once) | parked Stage 0 → implemented Stage 3 |
| 2 | Entry-row durations unrepresentable | Stage 0 |
| 3 | FATIHA_ONLY implicit row inheritance | Stage 0 |
| 6 | Niyet has no unit identity | parked Stage 0 → Stage 2/3/5 |
| 4 | Unit selection / order / inclusion | parked Stage 0 → Stage 3 |
| 5 | Unit-boundary transitions | parked Stage 0 → Stage 3 |
| 7 | P-23 repetition across units | parked Stage 0 → Stage 3 |

---

## Decisions owed by the user before Stage 3

- **Sunnah inclusion:** always-on, or user-toggleable (Fard-only mode)?
- **I-24 home:** keep per-unit then hoist in Stage 3, or hoist immediately?
- **P-23 closing dua:** end of every unit, or once at observance end?
- **Madhab scope:** lock Hanafi-flavoured (3-rakat Witr, Asr sunnah ghair
  mu'akkadah), or design the unit model to be madhab-parameterised later?

---

## Status

- Baseline committed `ab7ae2e`; on branch `observance-sequencer`.
- **Stage 0 ✅ complete** (uncommitted): live spec locked to current truth (parked
  forward content to `observance-considerations.md`); golden snapshot test
  (`SalahMotionTests/GuidedSnapshotTests.swift` + `__Snapshots__/guided-sequences.txt`,
  583 lines) green. State counts match master phase counts (fajr 15, dhuhr/asr/isha 28,
  maghrib 22, witr 22); exactly one yaw-capture per sequence.
- **Next action:** Stage 2 — unit identity (`PrayerUnit` model, `generateUnit`,
  `generate(salat:)` shim), snapshot must stay green.
