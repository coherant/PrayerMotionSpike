# Prayer Times — Timing & Behaviour

Configuration for time-sensitive behaviour on the Prayer Times screen.
Code owner: `Features/PrayerTimes/PrayerTimesViewModel.swift`

---

## Prayer window

The period immediately after a prayer's scheduled time during which the
screen enters an active state.

| Parameter | Value | Notes |
|---|---|---|
| Window duration | 15 minutes | From `scheduledDate` to `scheduledDate + 900s` |
| Computed by | `isInPrayerWindow: Bool` | On `PrayerTimesViewModel` |
| Refresh cadence | Every 60 seconds | Driven by existing timer |

---

## CTA button states

| Condition | Label | Pulse |
|---|---|---|
| Inside prayer window | `Pray {Prayer}` | Active |
| Outside prayer window | `Pray {Prayer}` | None |
| 15 mins before next prayer  | `Prepare for {Prayer}` | None |

---

## CTA pulse

Applies only during the prayer window.

| Parameter | Value |
|---|---|
| Shape | Capsule (matches button outline) |
| Fill | `theme.accent` |
| Starting opacity | 0.35 |
| Ending opacity | 0 |
| Scale X | 1.0 → 1.12 |
| Scale Y | 1.0 → 1.50 |
| Duration | 3.6s |
| Easing | easeOut |
| Repeats | Forever, no reverse |

---

## Day-progress rail

| Parameter | Value | Notes |
|---|---|---|
| Fill calculation | Continuous interpolation | Between prayer node positions based on clock time |
| Node positions (%) | 5, 38, 56, 72, 90 | Fajr → Isha |
| Fill anchors (%) | 0→5, 5→38, 38→56, 56→72, 72→90, 90→100 | Midnight segments |
| Pulse marker | Same as CTA — scale 0.85→1.5, opacity 0.55→0, 3.6s easeOut | `PulseMarker` struct |
| Refresh cadence | Every 60 seconds | |
