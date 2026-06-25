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

### Dhuhr, Asr, Maghrib, Isha

| State | Condition | Label | Pulse |
|---|---|---|---|
| Waiting | Before prayer time | `Waiting for {Prayer}` | None |
| Active | 0–15 mins after prayer | `Pray {Prayer}` | Active |
| Waiting | After window, before next | `Pray {Prayer}` | None |
| Prepare | 15 mins before next prayer | `Prepare for {Next Prayer}` | None |

### Fajr (exception)

| State | Condition | Label | Pulse |
|---|---|---|---|
| Waiting | Overnight / pre-dawn | `Waiting for sunrise` | None |
| Active | 0–15 mins after Fajr | `Pray Fajr` | Active |
| Waiting | After window, before Dhuhr | `Waiting for Dhuhr` | None |
| Prepare | 15 mins before Dhuhr | `Prepare for Dhuhr` | None |

---

## Sunrise time

Sunrise is not a prayer but is required for the Fajr waiting label.

| Parameter | Value | Notes |
|---|---|---|
| Sunrise time | TBD | To be filled in by user |
| Source | Hardcoded for now | Replace with Adhan library calculation later |
| Location | `PrayerTimeTheme.swift` — static property, not a prayer case | |

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

State is derived from the **real engine prayer times** (`PrayerTime.scheduledDate`),
not a fixed hour map — so nodes, row checks, and fill all stay consistent and reset
together at the day rollover.

| Parameter | Value | Notes |
|---|---|---|
| Current prayer | First prayer whose time is still in the future ("up next") | `PrayerTimesViewModel.currentPrayerIndex`. Prayers before it = prayed (filled), after it = future (hollow). Once Isha has passed it stays current through the night; the new day's Fajr resets it. |
| Fill calculation | Continuous interpolation | Anchored to the actual prayer instants, not clock percentages — `continuousRailFill` |
| Node positions (%) | 5, 38, 56, 72, 90 | Fajr → Isha (`railNodeFractions`) |
| Fill anchors | startOfDay→0, then each prayer's real time → its node %, midnight → 100% | Interpolated between anchors so fill + marker line up with the nodes |
| Reset | At the day rollover | Pre-dawn (before Fajr) reads as a fresh day: nothing prayed, Fajr up-next, fill near 0% (matches the spec's Fajr state sampled at 4:38 AM) |
| Pulse marker | Scale 0.85→1.5, opacity 0.55→0, 3.6s easeOut | `PulseMarker` struct, rides the fill's leading edge |
| Refresh cadence | Countdown every 1s; prayer period + day-rollover recompute every 60s | |
