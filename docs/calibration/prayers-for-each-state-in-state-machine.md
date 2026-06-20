# Prayers for Each State in the State Machine

Utterances for each position-id in the master sequence. Multiple rows with the
same `position-id` and `role` are concatenated in order to form the full spoken
text for that role. Position-ids correspond to the `position-id` column in
`master-prayer-state-machine.md`.

Roles:
- **entry** — spoken when the state begins (instruction to move into position)
- **prayer** — spoken during the position after the user has moved into place; `duration` is the pause held after the prayer finishes before the exit is spoken
- **exit** — spoken when the state ends (after motion confirmed or timer fires)
- **reprompt** — spoken if motion is not confirmed within the reprompt interval (repeats every 8s)

---

## Prayer Library

See [`docs/prayers/prayers.md`](../../prayers/prayers.md) for the full prayer library.
Add prayers there and reference them here by `prayer-id` (e.g. `P-1`).

---

## How Claude should build from this file

When reading this file to generate Swift code or utterance arrays:

1. **Resolve prayer-id references** — if an `utterance` cell contains a `prayer-id` (e.g. `P-1`), look up the matching row in the **Prayer Library** table above and substitute the `prayer` column text as the utterance string.
2. **Use inline text verbatim** — if the `utterance` cell contains a plain string (not a `prayer-id`), use it exactly as written.
3. **Empty utterance cells** — treat as an empty string `""`. The `duration` still applies (silent hold with no speech).
4. **Multiple prayer rows per position** — play each in order. The `duration` on a prayer row is the pause held *after* that prayer finishes, before moving to the next prayer row or the exit.
5. **Duration format** — strip the `s` suffix and parse as `Double` seconds (e.g. `5s` → `5.0`). An empty duration cell = `0.0`.
6. **Roles summary** — each position must have exactly one `entry` row, zero or more `prayer` rows, at most one `exit` row, and at most one `reprompt` row. Any other rows are an error.

---

## Position 1 — Standing (Qiyam) - Start

| role | utterance | duration |
|---|---|---|
| entry | Stand upright for Qiyam. | |
| prayer |  | 4s |
| exit |  | |

---

## Position 2 — Bowing (Ruku) - First

| role | utterance | duration |
|---|---|---|
| entry | Bow forward into Ruku. | |
| prayer |  | 4s |
| exit |  | |
| reprompt | Please bow into Ruku | |

---

## Position 3 — Standing (Qiyam) - After Ruku (Rakat 1)

| role | utterance | duration |
|---|---|---|
| entry | Return to standing. | |
| prayer |  | 5s |
| exit |  | |
| reprompt | Please return to standing | |

---

## Position 4 — Prostration (Sujood) - First

| role | utterance | duration |
|---|---|---|
| entry | Prostrate into Sujood. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please lower into Sujood | |

---

## Position 5 — Sitting (Julus) - Between Prostrations (Rakat 1)

| role | utterance | duration |
|---|---|---|
| entry | Sit upright. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please sit up | |

---

## Position 6 — Prostration (Sujood) - Second

| role | utterance | duration |
|---|---|---|
| entry | Prostrate into Sujood again. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please lower into Sujood again | |

---

## Position 7 — Standing (Qiyam) - Rakat 2

| role | utterance | duration |
|---|---|---|
| entry | Stand for the second rakat. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please stand for the next rakat | |

---

## Position 8 — Bowing (Ruku) - Second

| role | utterance | duration |
|---|---|---|
| entry | Bow forward into Ruku. | |
| prayer |  | 5s |
| exit | Sami Allahu liman hamidah | |
| reprompt | Please bow into Ruku | |

---

## Position 9 — Standing (Qiyam) - After Ruku (Rakat 2)

> Yaw baseline is captured at this position for Tasleem detection.

| role | utterance | duration |
|---|---|---|
| entry | Return to standing. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please return to standing | |

---

## Position 10 — Prostration (Sujood) - Third

| role | utterance | duration |
|---|---|---|
| entry | Prostrate into Sujood. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please lower into Sujood | |

---

## Position 11 — Sitting (Julus) - Between Prostrations (Rakat 2)

| role | utterance | duration |
|---|---|---|
| entry | Sit upright. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please sit up | |

---

## Position 12 — Prostration (Sujood) - Fourth

| role | utterance | duration |
|---|---|---|
| entry | Prostrate into Sujood again. | |
| prayer |  | 5s |
| exit | Allahu Akbar | |
| reprompt | Please lower into Sujood again | |

---

## Position 13 — Sitting (Julus) - Tashahhud

| role | utterance | duration |
|---|---|---|
| entry | Sit for Tashahhud. | |
| prayer |  | 5s |
| exit |  | |
| reprompt | Please sit for Tashahhud | |

---

## Position 14 — Tasleem - Look Right

| role | utterance | duration |
|---|---|---|
| entry | Turn your head to the right. | |
| prayer |  | 4s |
| exit |  | |
| reprompt | Please turn your head to the right | |

---

## Position 15 — Tasleem - Look Left

| role | utterance | duration |
|---|---|---|
| entry | Turn your head to the left. | |
| prayer |  | 4s |
| exit |  | |
| reprompt | Please turn your head to the left | |
