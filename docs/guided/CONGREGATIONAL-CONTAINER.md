# The Congregational Container & Silent Mode — Next Build Arc

**Status: SPEC (not yet built).** This is the vision the whole observance-sequencer
refactor (Stages 0–6, `REFACTOR-PLAN.md`) was building the skeleton for. Captured
2026-06-26 from the design conversation where it crystallised. It **supersedes** the
"Muezzin recites the salah" hybrid sketched earlier and **largely dissolves** the parked
language refactor (`LANGUAGE-REFACTOR.md`) — see *Relationship to other tracks* below.

> Same discipline when we build it: **MD-first**, **golden-snapshot-protected**, small
> reversible stages. See `feedback_md_first`.

---

## 1. The core idea — the fiqh boundary *is* an architectural boundary

An automated Muezzin reciting the obligatory in-salah prayers is jurisprudentially
unsound: the recitation of the farḍ is the **worshipper's own act of worship** and cannot
be performed for them by a recording. The resolution is to relocate the Muezzin **out of
the prayer and into the frame around it**, and to encode that separation in software:

| Role | Voices | Never voices |
|---|---|---|
| **Muezzin / container** | The **call** (Ezan/adhān), the **commencement** (qad qāmat → Iqāma), **punctuation** at each prayer's completion, and **post-salah** devotions (dhikr, ṣalawāt, closing istighfār) | The in-salah recitation |
| **Worshipper** | The **salah itself** — recites every unit, silently, in their own heart | — |

The Muezzin calls, commences, marks boundaries, and leads the dhikr *after*. He never
recites the Fātiḥa, a sūrah, or the tashahhud **for** the worshipper. That single line is
the whole design, and it is enforceable in code (see §4, *Binding policy*).

This is what the id-keyed refactor was *for*: the `PrayerLibrary` (`P-ids`, in-salah) vs
`InstructionLibrary` (`I-ids`, guidance) seam is already the recitation/guidance split.
The container adds a **third namespace** for what the Muezzin legitimately voices.

---

## 2. The Congregational Container (structure)

The container is an **outer shell wrapping the observance we already build** (chained
units from Stages 3–4). No surgery inside the units — a wrapper around them.

```
┌─ CONGREGATIONAL CONTAINER ───────────────────────────────┐
│  [ Ezan / Adhān ]            ← Muezzin (optional; ties to │
│                                 prayer-times)             │
│  Iqāma (qad qāmat)           ← Muezzin — opens container  │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Unit 1  (worshipper prays; guided motion/structure)│  │
│  │     └─ completion → Muezzin: "Allāhumma anta-s-salām"│  │  (P-23 → Muezzin act)
│  │  Unit 2  (worshipper prays …)                        │  │
│  │     └─ completion → Muezzin boundary du'ā            │  │
│  │  … all units complete …                             │  │
│  └────────────────────────────────────────────────────┘  │
│  Closing sequence — Muezzin leads (voiced, auto-paced):   │
│     • Dhikr / tasbīḥāt (Subḥānallāh · Alḥamdulillāh · …)   │
│     • Ṣalawāt on the Prophet ﷺ                            │
│     • Closing du'ā — istighfār, asking forgiveness        │
└──────────────────────────────────────────────────────────┘
```

Maps to the worshipper's words: *Ezan → Iqāma opens the container → worshipper prays each
unit → Muezzin punctuates each completion → after all units, Muezzin leads dhikr +
ṣalawāt + closing du'ā.*

> **Worked references — `container-sets/`** (each maps this onto one prayer phase-by-phase,
> the way `prayer-sets/` anchors the inner units):
> - `fajr.md` — Sunnah→Farḍ; the carrier of *aṣ-ṣalātu khayrun mina-n-nawm*; degenerate tail.
> - `dhuhr.md` — Sunnah→Farḍ→Sunnah-after; sets the **two-anchor** tail rule.
> - `asr.md` — Sunnah(optional)→Farḍ; Fajr-degenerate at 4+4.
> - `maghrib.md` — Farḍ→Sunnah-after; **no sunnah-before** (Ezan→Iqāma directly); 3-rakʿah farḍ.
> - `isha.md` — Sunnah→Farḍ→Sunnah-after→**Witr**; seal **after** the Witr; flags the Isha
>   composition bug (missing sunnah-before).

---

## A. Container Call Library (`C-` ids)

The Muezzin's content namespace — the parallel to `docs/prayers/prayers.md` (`P-ids`). None
of these exist yet. When built, this graduates to its own `calls.md` (mirroring
`prayers.md`); kept inline here while in SPEC. **Binding policy:** a Muezzin recording binds
**only** to a `C-` id, never a `P-id` (see §4).

| id | name | text (transliteration) | meaning | shape |
|---|---|---|---|---|
| `C-1` | Adhān | Allāhu akbar ×4 · Ashhadu an lā ilāha illā-llāh ×2 · Ashhadu anna Muḥammadan rasūlu-llāh ×2 · Ḥayya ʿalā-ṣ-ṣalāh ×2 · Ḥayya ʿalā-l-falāḥ ×2 · Allāhu akbar ×2 · Lā ilāha illā-llāh ×1 | The call to prayer | call |
| `C-1F` | Adhān (Fajr) | …as `C-1`, **with** *Aṣ-ṣalātu khayrun mina-n-nawm* ×2 after *Ḥayya ʿalā-l-falāḥ* | "Prayer is better than sleep" — Fajr only | call |
| `C-2` | Iqāma | …as adhān phrases (Ḥanafī doubles them), **plus** *Qad qāmati-ṣ-ṣalāh* ×2 before the closing takbīr | The prayer has begun | call |
| `C-3` | Boundary du'ā | *Allāhumma anta-s-salām wa minka-s-salām, tabārakta yā dhā-l-jalāli wa-l-ikrām* — **= `P-23`** | O God, You are Peace… | boundary |
| `C-4` | Istighfār | *Astaghfirullāh* ×3 | I seek God's forgiveness | dhikr |
| `C-5` | Āyat al-Kursī | Qur'an 2:255 (*Allāhu lā ilāha illā huwa-l-Ḥayyu-l-Qayyūm…*) | The Throne Verse — *the best gem* | dhikr |
| `C-6` | Tasbīḥ | *Subḥānallāh* ×33 | Glory be to God | dhikr |
| `C-7` | Taḥmīd | *Alḥamdulillāh* ×33 | All praise to God | dhikr |
| `C-8` | Takbīr | *Allāhu akbar* ×33 | God is the Greatest | dhikr |
| `C-9` | Tahlīl | *Lā ilāha illā-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shay'in qadīr* | …completes 100 | dhikr |
| `C-10` | Ṣalawāt | *Allāhumma ṣalli ʿalā Muḥammad…* | Blessings upon the Prophet ﷺ | dhikr |
| `C-11` | Closing du'ā | Free supplication — istighfār, asking acceptance (hands raised) | — | closing |

`C-3` is the same text as the in-salah-adjacent `P-23`; it is a *post-salah* act, so it
lives honestly in the container. One source, re-voiced by the Muezzin — not duplicated.

## B. The dhikr count is **not** a madhab axis

The post-salah tasbīḥ counts come from **multiple authentic hadith**, not from the four
schools diverging. All four treat post-salah tasbīḥ as *mustaḥabb* from the same narrations;
picking a formula is choosing *which sunnah narration*, not which madhab.

**Locked default: 33 Subḥānallāh · 33 Alḥamdulillāh · 33 Allāhu akbar · + 1 tahlīl = 100**
(Muslim) — the most widely practiced, including the Turkish/Ḥanafī tradition this Muezzin
belongs to. (Alternative narrations: 33/33/34; 25×4; 10×3 — all valid; could be an optional
*formula* setting later, but it is **not** wired to the madhab toggle.)

What genuinely *is* madhab-driven nearby — and must not be conflated: **Qunūt** (Ḥanafī =
Witr only → Fajr carries none), and **unit composition** (already in `SalatType.units`).
Āyat al-Kursī after the farḍ is broadly recommended across schools — **included**.

---

## 3. Silent Mode — the timing model (the final stitch)

**You do not time the silent recitation. The worshipper's body times it.** Salah is
intrinsically a **motion-gated state machine**: every posture change is a deliberate
movement the worshipper makes precisely *when their recitation is complete*. The body is
the metronome; the machine already listens to it (`motion` mode, `motionTrigger`).

| Posture | Worshipper recites (silently) | Advances when they… |
|---|---|---|
| Qiyām | Fātiḥa + sūrah | **bow** → Rukūʿ |
| Rukūʿ | "Subḥāna Rabbiyal-ʿAẓīm" | **rise** → iʿtidāl |
| Iʿtidāl | "Rabbanā lakal-ḥamd" | **prostrate** → Sujūd |
| Sujūd | "Subḥāna Rabbiyal-Aʿlā" | **sit up** → Julūs |
| Julūs | "Rabbighfir lī" | **prostrate** → Sujūd |
| Final sitting | Tashahhud + ṣalawāt | **turn the head** → Taslīm |

No gap needs a timer. The recitation duration only ever filled the space *until the next
movement*; in Silent Mode the worshipper fills it themselves, then moves.

**So Silent Mode is almost subtractive:**
- In-salah `prayers[]` rows become **display-only** (Arabic script + meaning on the orb,
  so the worshipper can follow / check themselves). Their `.pace`/`.fixed` durations stop
  driving anything.
- Every posture is **`motion`-gated and patient**: enter → show text → wait, indefinitely,
  for the confirmed movement into the next posture → advance.
- It is essentially *motion mode everywhere, with the voice withdrawn.*

### The three craft details that make it humane
1. **Patience, not nagging.** Today motion states reprompt every `5s`. In Silent Mode that
   rushes someone mid-Fātiḥa. Reprompts go **silent and long — ideally none by default**;
   the worshipper isn't stuck, they're praying. The app must learn to wait in silence.
2. **An escape hatch.** Since only motion advances, a missed sensor read could strand
   someone. After a long, generous hold with no detected movement, offer a gentle
   **tap-to-advance** — always available, never intrusive. Never a hostage to the sensor.
3. **The Muezzin re-entry is where timing returns.** The silent, self-paced span is *only
   the salah itself*. The instant a unit's final Taslīm is confirmed, the worshipper hands
   the clock back and the **Muezzin takes it**: boundary du'ā, then the voiced closing
   container run on the Muezzin's **own recording length** (auto-paced). The timeline
   breathes between two clocks — **the body during the prayer, the Muezzin around it.**
   That handoff *is* the stitch.

### The honest dependency
With no timed fallback advancing anything, the whole experience rests on **motion
detection**. Silent Mode is only as smooth as calibration is accurate — the Rukūʿ/upright
overlap work is no longer a nicety, it's the foundation the silence rests on. The
tap-to-advance hatch is the safety net beneath it. See `[[project_calibration_bug]]`.

---

## 4. What this means in code

**Reused (already built):**
- Units, chaining, unit boundaries, the `unitTransition` ~2s hold — the Muezzin's boundary
  du'ā slots into that existing moment.
- `motion` mode + `motionTrigger` — already the self-pacing mechanism Silent Mode needs.
- `P-23` ("O Allah, You are peace…") — exists; rebind from a passive `exitSpeech` to a
  **Muezzin-voiced boundary act**.
- Id-keyed content; the `PrayerLibrary` / `InstructionLibrary` seam.

**New (additive; clean because everything is id-keyed):**
- A **container phase type** — auto-played, Muezzin-voiced, *listen/follow* states (no
  motion trigger, no rakat). Likely a small sibling to `PrayerState` or a new `PhaseMode`.
  The dhikr may want a **tasbīḥ counter** UI.
- A **third content namespace** (e.g. `C-…`) for what doesn't exist yet: Adhān, Iqāma, the
  post-salah tasbīḥāt, post-salah ṣalawāt, and the closing istighfār/du'ā. A distinct
  namespace makes it **structurally impossible** to confuse container content with salah
  recitation.
- **Binding policy (the fiqh boundary, in code):** a Muezzin voice/recording can bind
  **only** to container (`C-`) ids — never to an in-salah `P-id`. A Muezzin recording for
  `P-7` simply has nowhere to attach. This is configuration, not contradiction.
- A **Silent Mode flag/mode**: in-salah `prayers[]` rows render as text, not speech;
  advancement is purely `motionTrigger`-gated; reprompts patient/suppressed; tap-to-advance
  hatch enabled.
- **In-salah recitation voice = a setting (decision 1c, locked):** default
  **worshipper-recites** (Silent Mode — display only), with an optional **learner
  scaffold** (a neutral teaching voice, explicitly *not* the Muezzin) for those learning.

---

## 5. Relationship to the other tracks

- **Observance arc (`REFACTOR-PLAN.md`, COMPLETE):** built the id-keyed, unit/observance
  skeleton this inhabits. This arc is the *why*.
- **Language refactor (`LANGUAGE-REFACTOR.md`, PARKED):** **largely dissolves here.** With
  the Muezzin out of the salah and in-salah recitation shown as text (Arabic + meaning),
  there is no synthesizer pretending to recite. The axes land honestly: Adhān/Iqāma =
  Arabic (Muezzin); in-salah = displayed (Arabic + meaning, worshipper recites); dhikr /
  closing du'ā = Muezzin voice (Arabic, with the own-language latitude du'ās permit);
  guidance = TTS in the user's language.
- **Prayer-times (`[[project_prayer_times_state]]`, PARKED):** the **Adhān** at the top of
  the container is the same Muezzin who *calls* you to prayer there. One Muezzin identity
  across call-to-prayer and the post-salah frame — the reason "Muezzin" is the right spine,
  not just a voice picker.

---

## 6. Open questions (to resolve before / during build)

- **1c — settled:** in-salah recitation = setting, default worshipper-recites (silent),
  learner scaffold optional.
- **Adhān/Iqāma scope — SETTLED (via `container-sets/fajr.md`):** the **Iqāma opens the
  container between sunnah and farḍ** (sunnah-before is prayed before it, as in
  congregation); the **Ezan is a pre-roll** above the container, prayer-time-tied. Generalise
  to the other four when mapped.
- **Boundary du'ā + dhikr placement — SETTLED (general rule, via `container-sets/dhuhr.md`):**
  two acts, two anchors —
  1. **Boundary du'ā `C-3`** (*Allāhumma anta-s-salām*) fires **immediately after the FARḌ**
     unit (the du'ā of exiting the obligatory prayer; punctuates farḍ → sunnah-after).
  2. **Full dhikr `C-4…C-10` + closing `C-11`** **seal the whole observance** — after the
     **last** unit.
  Matches Turkish/Ḥanafī practice (*entesselâm* after the farz; **tesbîhât** after the
  son-sünnet). **Fajr is the degenerate case** (farḍ *is* last → both anchors coincide).
  Never after a sunnah-**before** (the Iqāma marks that). **Build implication:** `C-3` is a
  **new emission point** after the *farḍ* — today `P-23` fires only on the *last* unit; the
  container splits that single closing into *(boundary-after-farḍ)* + *(seal-at-end)*.
- **Dhikr formula — SETTLED:** 33/33/33 + tahlīl; Āyat al-Kursī included (see §B).
- **Witr placement — SETTLED (via `container-sets/isha.md`):** the seal falls **after the
  Witr**. Witr is the last unit, so the general "seal after the last unit" rule holds with
  **no special case**. The Muezzin is **silent through the Witr** — its Qunūt is in-salah
  recitation, which he never voices — then seals once it's complete.
- **Isha composition — BUG to fix in build:** full Ḥanafī Isha is **4→4→2→3** (13 rakʿah);
  the canonical table omits the 4-rakʿah ghayr-muʾakkad **sunnah-before** (`SalatType.units`
  `.isha`; `observances.md` 25 + §5; `prayer-sets/isha.md`). Add `isha_sb` mirroring Asr's
  optional sunnah-before; regen snapshot (Isha 65 → ~93). Container-sets already map the
  corrected composition. *(Code change — not done in the spec work.)*
- **Reprompt policy in Silent Mode:** none at all by default, or a single very-delayed
  gentle cue? Escape-hatch (tap-to-advance) hold-time threshold?
- **Opening:** does the first unit still get the I-1 intro (teaching), or a "begin when
  ready" hand-off straight into self-paced silence?
- **Container content authoring:** Adhān/Iqāma/tasbīḥāt/ṣalawāt/closing du'ā text + the
  `C-` namespace + recordings vs TTS for each.

---

## 7. Likely stages when un-parked (sketch)

1. **Silent Mode (inner):** add the mode — in-salah rows display-only, motion-gated,
   patient reprompts, tap-to-advance hatch. Snapshot-protected. No new content.
2. **The container shell (outer):** wrap the observance — container phase type, `C-`
   namespace, Iqāma open + closing sequence; rebind `P-23` as a Muezzin boundary act.
3. **Muezzin voice binding:** wire `muezzinId` → container audio (the binding policy);
   start TTS-persona, add recordings as a tier.
4. **Adhān + prayer-times join:** the Muezzin's call at the top, tied to prayer-times.

Each stage compiles, builds, and (where it touches the generator) shows a reviewed
golden-snapshot diff.
