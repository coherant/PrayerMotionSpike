# Guided Motion — Detection & Guardrails SPEC

**Status:** analysis / design doc (no code yet). Captures the PhD-level assessment of why Silent
Mode "runs ahead" and what software guardrails can do about it without new hardware.

**Scope:** the head-motion sensing that drives posture transitions in Guided Prayer (all modes),
with emphasis on **Silent Mode**, where advancement is *purely* motion-gated.

**Today's code (the surfaces this spec touches):**
- `Core/MotionDetection/HeadphoneMotionDetector.swift` — `CMHeadphoneMotionManager`; currently
  publishes **smoothed `attitude` pitch/roll/yaw only** (degrees).
- `Core/MotionDetection/SensorReadings.swift` — moving-average smoothing over a window.
- `Core/MotionDetection/MotionThresholds.swift` — `isSatisfied(trigger, pitch, roll, yaw, yawBaseline)`
  against a per-user calibration `profile` (`rukuPitchLow/High`, `sujoodRollRadius`,
  `uprightPitchLow/High`, `tasleemYawOffset`).
- `Core/PrayerStateMachine/PrayerStateMachine.swift` — `confirmMotion()` (the wait loop:
  `holdWindow` dwell, reprompts + `maxReprompts` fallback, `escapeHatchDelay = 60` s),
  `waitForMotion()`, `requestManualAdvance()`.
- Calibration: `CalibrationSequenceGenerator` + the captured `profile`.

---

## 1. The problem (observability), stated precisely

Postures are distinguished by **head orientation**, which the AirPods sense well. But two postures
share an orientation:

> **Julus (sitting upright) and Qiyam (standing upright) are the same head orientation.** They
> differ only in **height** — the one axis AirPods cannot measure. (The code already says so:
> *"Upright — pitch alone cannot distinguish standing (Qiyam) from sitting (Julus)."*)

Consequences observed in Silent Mode:
- A static **"upright"** trigger fires whether you're sitting or standing → the machine can satisfy
  Qiyam **while you're still in Julus** → it **runs ahead**.
- **Rise triggers Rukūʿ:** rising from the 2nd sujood (sajda → julus → sajda → stand) sweeps the
  head **through the rukūʿ pitch band** on the way up; a threshold detector reads that transient as
  Rukūʿ. This is the reported bug.

Root cause is an **observability gap**, not a tuning error: head IMU gives orientation, not vertical
position.

## 2. What the sensors actually provide

`CMDeviceMotion` from AirPods exposes more than we currently use:

| Signal | Use | Caveat |
|---|---|---|
| `attitude` (pitch/roll/yaw) | what we use now | **yaw drifts** (not comparable across sessions → taslīm uses a captured yaw baseline) |
| **`gravity`** | drift-free **inclination** (pitch/roll vs "down") | the robust posture-angle source — we don't use it yet |
| **`userAcceleration`** | **transition events** (the *act* of moving) | double-integration to height **diverges** → no absolute height |
| **`rotationRate`** (gyro) | "is the head still vs moving" + transition dynamics | — |

**Key correction to "AirPods can't detect vertical movement":** they *do* give acceleration; what's
unrecoverable is **position/height** (integration drift). The **transient** of standing up is
detectable as an *event* even though static height is not.

## 3. The reframe that makes it tractable

We are not classifying free postures — we follow a **known, ordered script**. So don't ask
*"what pose is this?"*; ask *"did the one expected transition happen, for real?"* This removes the
need to ever resolve sit-vs-stand statically:

- After sujood-2 the only valid move is **rise → qiyam**; confirm a *rise event*, not a "standing pose".
- **Rukūʿ may only follow a confirmed, stable Qiyam** → a transient forward-lean *during a rise* is
  structurally ineligible to be Rukūʿ.

Principle: **confirm sequence-valid transitions with positive evidence; default to waiting when unsure.**

## 4. The guardrail stack (by impact ÷ effort)

**A. Gravity-referenced pitch + hysteresis (Schmitt bands).** Derive posture angle from `gravity`
(drift-free); classify upright / bowed / prostrate with **separate enter/exit thresholds** so it
doesn't chatter at a boundary. Stabilises everything downstream. *(Replaces relying on raw `attitude`.)*

**B. Departure-before-arrival (the core fix).** To advance A→B, require the head to have **left A**
(crossed back out of A's band) *and then* entered B — not merely "B is momentarily true". Kills
"satisfied-upright-while-never-leaving-sitting" and the through-rukūʿ-while-rising trigger.

**C. Dwell + stillness confirmation.** Confirm B only after it's **held for the dwell window with
low `rotationRate`** (head settled). A pass-through pose has high gyro + short dwell; an arrived pose
is still + sustained. *(Extends the existing `holdWindow` with a gyro gate.)*

**D. Refractory period.** Enforce a **minimum plausible time-in-posture** (you can't sujood→julus→
sujood in <~1.5 s). Reject confirmations inside the refractory window — they're the rise/settle transient.

**E. Transition-event detection.** Recover *some* of the lost axis: the **act of standing** has a
signature in `userAcceleration` + `rotationRate` (vertical push-up impulse + decel, gyro burst).
Detect it **as an event** (band-pass ~0.5–2 Hz energy/peak detector, or a small template/DTW or
logistic classifier on a windowed feature vector). Use as **corroboration** of julus→qiyam, not sole
trigger. Person-dependent → must be calibrated (§6).

**F. Sequence-constrained observer.** The principled framing: a **left-to-right HMM / constrained
Viterbi** — hidden posture, transitions restricted to the script, observations = gravity-band +
event likelihood. Impossible jumps (qiyam→rukūʿ with no confirmed qiyam) get ~zero probability;
transients get smoothed. A guarded finite-state automaton (B–E) captures ~90% of the benefit; the
HMM is the target for maximal robustness.

**G. Bias-to-wait in Silent Mode.** Make the default action **hold**, not advance — require positive
confirmation. The cost of a false-negative (briefly stuck) is one tap (§5); the cost of a
false-positive (run-ahead) is what breaks immersion today. Tune the operating point toward
**specificity** — aligned with the mode's philosophy ("the body is the clock; trust only confirmed motion").

## 5. The safety valve — the escape hatch (already built)

Biasing to wait is safe because a backstop exists:
- `confirmMotion()` waits; in Silent Mode, after **`escapeHatchDelay` = 60 s** with no confirmed
  motion it sets `escapeHatchVisible = true` (`PrayerStateMachine.swift:619`).
- The UI fades in a **"Tap to continue"** capsule (`GuidedPrayerView.swift:144`, `.ultraThinMaterial`,
  `hand.tap`); tapping calls `requestManualAdvance()` → the wait loop consumes the flag and advances.
- Container (Muezzin) rows expose the hatch **immediately**; **voiced** modes use reprompts +
  `maxReprompts` auto-advance instead.

So tightening for specificity (no run-ahead) trades only an occasional bounded over-wait → one tap.

**Enhancement — confidence-aware hatch.** Today the delay is a flat 60 s. With the guardrails we
*know when we're in the unobservable case* ("upright held but no rise event confirmed"). Surface the
hatch **sooner / with a gentler 'still here?' cue specifically then**, so the user isn't dead-waiting
60 s in exactly the julus→qiyam ambiguity. Best of both: no run-ahead **and** no long stall.

## 6. The specific bug fix (rise → Rukūʿ)

Compose B + C + D + G, **keyed on the prior confirmed state**:
1. **Rukūʿ requires a prior *confirmed, stable* Qiyam** (a held upright with low gyro), and a
   **downward** entry from upright into the rukūʿ band held past dwell. The rise from sujood is an
   *upward* sweep with no prior confirmed qiyam and no hold → ineligible.
2. **Qiyam (post-rakat) requires a confirmed rise** (departure from sujood/julus + stable upright
   hold), not an instantaneous upright reading.
3. **Refractory** blocks any confirmation during the rise transient.

Net: the head passing through the rukūʿ band *while rising* can no longer fire Rukūʿ.

## 7. Personalised calibration (extend the existing rig)

Generic thresholds are the main cross-body-type flakiness. The calibration sequence already walks the
postures; extend the captured `profile` to store, **per user**:
- gravity-pitch centroids/spread per posture (upright/bowed/prostrate),
- a few **reps of the rise and sit-down** → the transition-event template + realistic **refractory** timings,
- gyro "still" floor.
This is the highest-leverage *accuracy* investment after B–D.

## 8. Honest limits & the hardware ceiling

- The **static** sit-vs-stand ambiguity is unrecoverable from AirPods. The guardrails work by (i)
  never needing the static answer and (ii) detecting the *transition* — robust, not perfect (a very
  slow, smooth stand with no impulse can still be missed → caught by §5/§G).
- **Apple Watch is the real fix:** the wrist has a **barometric altimeter** — standing changes head/
  wrist height ~0.4–0.7 m ≈ a measurable pressure delta, i.e. it can *directly* sense sit↔stand; plus
  a 2nd IMU (hands-folded vs hands-on-ground). Future: fuse Watch barometer as the authoritative
  vertical channel; keep AirPods for head orientation + taslīm. (The **phone's** barometer is useless
  here — it's set aside, not on the body.)

## 9. Code mapping

| Guardrail | Where |
|---|---|
| Gravity-pitch + gyro exposure (A, C, E) | `HeadphoneMotionDetector` — also publish `gravity`-derived pitch/roll, `rotationRate` magnitude, `userAcceleration`; `SensorReadings` gains hysteresis + a short event buffer |
| Departure / dwell / refractory / prior-state (B, C, D, §6) | `MotionThresholds` + `confirmMotion()` — pass the **prior confirmed posture**; track left-A, held-B-with-low-gyro, refractory timer |
| Bias-to-wait + confidence-aware hatch (G, §5) | `confirmMotion()` (operating point) + `escapeHatchVisible` timing |
| Transition-event template + thresholds (E, §7) | calibration `profile` + a small detector in `MotionDetection` |
| HMM observer (F) | new component in `MotionDetection`, optional |

## 10. Phasing

- **P1 (cheap, big win):** A + B + C + D + G via gravity-pitch, keyed on prior confirmed state.
  Directly fixes "rise → Rukūʿ" and most run-ahead. No new hardware/ML. + confidence-aware hatch.
- **P2:** E (rise/sit transition-event detector) + extend calibration (§7) to personalise thresholds
  and the event template.
- **P3 (if warranted):** F (HMM/Viterbi) for maximal robustness; Apple Watch barometer as the proper
  vertical sensor.

## 11. Open questions

1. Acceptable to bias Silent Mode hard toward **wait** (specificity) with the confidence-aware hatch,
   accepting occasional taps? (Recommended.)
2. Confidence-aware hatch: how soon to surface it in the ambiguous case (e.g. 10–15 s vs 60 s)? Cue style?
3. Appetite for the **transition-event detector (E)** — heuristic energy/peak first, or go to a small
   trained classifier from calibration reps?
4. Is **Apple Watch** on the roadmap? If so, P3 vertical-sensing changes from "best-effort" to "solved".
5. How much to **personalise** vs ship robust generic defaults first?
