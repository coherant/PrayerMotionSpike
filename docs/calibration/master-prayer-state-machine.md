# Master Prayer State Machine

This is the single source of truth for the prayer sequence used by both the
Guided and Calibration tabs. All other documentation and all source files
reference this document.

## Source files

| File | Purpose |
|---|---|
| `PrayerMotionSpike/PrayerSequence.swift` | `PhaseMode`, `PrayerState`, `MotionTrigger`, `SensorReadings`, `PrayerSequenceGenerator` — **edit this file to change the sequence** |
| `PrayerMotionSpike/PrayerStateMachine.swift` | Runtime engine — handles all four modes, session recording, TTS, idle timer |
| `PrayerMotionSpike/ReactivePrayerView.swift` | Guided tab UI |
| `PrayerMotionSpike/ContentView.swift` | Calibration tab UI (`GuidedRecordingView`) and Manual tab |

## Phase modes

| Mode | Behaviour |
|---|---|
| `auto` | Plays entry speech, plays exit speech, advances immediately — no timer, no motion gate |
| `timed` | Plays entry speech, plays prayer rows in sequence, plays exit speech |
| `motion` | Plays entry speech, plays prayer rows in sequence, waits indefinitely for confirmed motion (reprompts every reprompt interval), plays exit speech |
| `timed-motion` | Plays entry speech, plays prayer rows in sequence (each followed by its duration pause), plays exit speech — motion detection runs throughout; reprompts fire every reprompt interval if position not yet confirmed |

## Timing ownership

Defines which file or constant controls each timing parameter.

| Timer | Controlled by | Location |
|---|---|---|
| Phase duration (how long each position lasts) | Prayer row `duration` values | `prayers-for-each-state-in-state-machine.md` |
| Motion confirmation hold window | Fixed code constant | `PrayerStateMachine.swift` — 1.5s |
| Reprompt interval | Master sequence table | `master-prayer-state-machine.md` — `Reprompt Interval` column |
| Reprompt utterance | Prayer role row | `prayers-for-each-state-in-state-machine.md` — `reprompt` role |

## Master phase sequence

| position-id | Label | Mode | Motion Trigger | Reprompt Interval |
|---|---|---|---|---|
| 1 | Standing (Qiyam) - Start | `auto` | — | — |
| 2 | Bowing (Ruku) - First | `timed-motion` | pitch (ruku) | 8s |
| 3 | Standing (Qiyam) - After Ruku (Rakat 1) | `timed-motion` | pitch (upright) | 8s |
| 4 | Prostration (Sujood) - First | `timed-motion` | roll (sujood) | 8s |
| 5 | Sitting (Julus) - Between Prostrations (Rakat 1) | `timed-motion` | pitch (upright) | 8s |
| 6 | Prostration (Sujood) - Second | `timed-motion` | roll (sujood) | 8s |
| 7 | Standing (Qiyam) - Rakat 2 | `timed-motion` | pitch (upright) | 8s |
| 8 | Bowing (Ruku) - Second | `timed-motion` | pitch (ruku) | 8s |
| 9 | Standing (Qiyam) - After Ruku (Rakat 2) | `timed-motion` | pitch (upright) | 8s |
| 10 | Prostration (Sujood) - Third | `timed-motion` | roll (sujood) | 8s |
| 11 | Sitting (Julus) - Between Prostrations (Rakat 2) | `timed-motion` | pitch (upright) | 8s |
| 12 | Prostration (Sujood) - Fourth | `timed-motion` | roll (sujood) | 8s |
| 13 | Sitting (Julus) - Tashahhud | `timed-motion` | pitch (upright) | 8s |
| 14 | Tasleem - Look Right | `timed-motion` | yaw delta (right) | 8s |
| 15 | Tasleem - Look Left | `timed-motion` | yaw delta (left) | 8s |

## Parameter definitions

| Parameter | Applies to | Meaning |
|---|---|---|
| `Motion Trigger` | `motion`, `timed-motion` | Sensor condition that must be satisfied to confirm the position |
| `Reprompt Interval` | `motion`, `timed-motion` | How often the reprompt fires while waiting for motion confirmation |

## Motion detection thresholds

Threshold values are updated by calibration runs. The `Initial` column records the
hand-tuned starting point; `Calibrated` records the value derived from data.
The Swift implementation in `PrayerStateMachine.swift` always uses the calibrated value.

| Position | Signal | Initial | Calibrated | Source |
|---|---|---|---|---|
| Ruku | Pitch | [-80°, -65°] | [-82°, -48°] | 3 participants, Jun 2026 |
| Sujood | Roll | angDist(roll, 162.5°) ≤ 12.5° | angDist(roll, 180°) ≤ 30° | 3 participants, Jun 2026 |
| Upright (standing or sitting) | Pitch | [-30°, +25°] | [-40°, +6°] | 3 participants, Jun 2026 |
| Tasleem right | Yaw delta | yaw − baseline ≥ +30° | baseline − yaw ≥ 30° | 3 participants, Jun 2026 |
| Tasleem left | Yaw delta | baseline − yaw ≥ 30° | yaw − baseline ≥ 30° | 3 participants, Jun 2026 |

Notes:
- Upright: sequence position disambiguates standing vs sitting — roll is NOT a hard gate
- Sujood: angular distance handles the ±180° Euler-angle wraparound
- Tasleem: yaw is session-relative; baseline captured at phase 9. Right/left directions confirmed by calibration data (right turn = negative yaw delta)

## Sensor smoothing
7-sample moving average applied to pitch, roll, yaw before threshold evaluation.
Reduces sensor jitter without masking real transitions.

## Yaw baseline
Captured at phase 9 (Standing — After Ruku, Rakat 2) — the most recent confirmed
standing position before Tasleem. Yaw is session-relative so must be captured within
the same session.
