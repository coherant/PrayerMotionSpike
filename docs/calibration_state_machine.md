# Calibration Mode

> **The master sequence is defined in [`master-prayer-state-machine.md`](master-prayer-state-machine.md).**
> Both the Calibration and Guided tabs use that sequence. Edit this file to change phases, timing, or speech.

## Source files

| File | Purpose |
|---|---|
| `PrayerMotionSpike/PrayerSequence.swift` | Phase model (`PhaseMode`, `PrayerState`, `MotionTrigger`) and the 15-phase sequence — **edit here** |
| `PrayerMotionSpike/PrayerStateMachine.swift` | Runtime engine (all four modes, session recording, TTS) |
| `PrayerMotionSpike/ContentView.swift` | `GuidedRecordingView` — Calibration tab UI |

## Purpose

Calibration records raw AirPods sensor data (pitch, roll, yaw) at each known prayer
position, so the data can be exported and used to validate or tune the motion
detection thresholds.

## How a phase runs

Each phase runs according to its `mode` — see the master state machine for the full
mode definitions. All 15 phases in the current sequence use `timed-motion`:

1. Entry speech is spoken via TTS
2. Transition buffer (3s) — user moves into position
3. Chime plays (system sound 1108 — "Tink") to signal start
4. Timer (4s) and motion detection race — whichever fires first advances the phase
5. Exit speech is spoken (if set)

## Session recording

- Uses `CMHeadphoneMotionManager` via `MotionManager` in `PrayerStateMachine`
- Records pitch, roll, yaw tagged with the current state ID at full sensor rate (~100 Hz)
- On natural completion: saved as `prayer_session_<timestamp>.csv` to the Documents directory
- Export: tap **Export** in the History list on the idle screen

## CSV format

```
timestamp_s,state_id,pitch_deg,roll_deg,yaw_deg
0.0100,qiyamStart,−4.21,−16.83,2.14
...
```

`state_id` maps directly to `PrayerStateID` values — use this to filter rows per position.
