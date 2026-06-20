# Task: Build Reactive Prayer State Machine (Multi-Rakat) — Replace Guided Timing with Real Motion Detection

> **Sequence superseded.** The master 15-phase 2-rakat sequence is now defined in
> [`master-prayer-state-machine.md`](master-prayer-state-machine.md). Both Guided and
> Calibration tabs share that sequence. The architecture and detection notes below remain valid.

## Source files
| File | Purpose |
|---|---|
| `PrayerMotionSpike/PrayerSequence.swift` | `PhaseMode`, `PrayerState`, `MotionTrigger`, `SensorReadings`, 15-phase master sequence — **edit here** |
| `PrayerMotionSpike/PrayerStateMachine.swift` | Runtime engine: four-mode phase runner, motion detection, reprompt, TTS, session recording |
| `PrayerMotionSpike/ReactivePrayerView.swift` | Guided tab UI |
| `PrayerMotionSpike/ContentView.swift` | Calibration tab UI (`GuidedRecordingView`) |

## Context
We've validated, via guided recording sessions, that CMHeadphoneMotionManager
produces reliable, repeatable signals for prayer positions:

- **Ruku**: pitch consistently -73° to -75°. Highly distinct from all other
  positions. Use pitch as primary signal.
- **Sujood**: roll consistently ~160-164°, a ~180° gap from every other
  position's roll value (which cluster between -15° and -23°). Use ROLL as
  the primary signal for sujood, not pitch (pitch is a secondary confirming
  signal, sujood pitch sits around -58° to -64°).
- **Standing (Qiyam) vs Sitting (Julus)**: NOT reliably distinguishable by
  pitch alone (both cluster roughly -4° to -16° depending on the person/
  session). Roll shows a small, not-yet-fully-confirmed gap (standing
  ~-15° to -18°, sitting ~-19° to -22.5°). Because this gap is thin and
  unconfirmed, standing vs sitting detection MUST rely primarily on
  SEQUENCE CONTEXT (i.e. which position logically follows the position we
  just confirmed), with roll as a secondary tiebreaker only, not a hard
  threshold.
- **Yaw is session-relative, not absolute.** CMHeadphoneMotionManager's
  reference frame resets each time tracking starts, so yaw drifted between
  recording sessions. Any yaw-based detection (e.g. for Tasleem head turns)
  must compare against a baseline captured earlier IN THE SAME SESSION
  (e.g. the yaw value during the most recent confirmed Qiyam), not a fixed
  absolute value.

This task replaces the previous guided/timed flow (where the app dictated
timing via TTS regardless of the user's actual movement) with a REACTIVE
state machine: the app waits for the user's actual confirmed motion before
advancing, and gently re-prompts if nothing is detected within a timeout.

## Core architecture: Prayer State Machine

### State definition
Each state represents a position the app is currently waiting to detect,
or an audio-cue-only transitional state. A state has:
- `id`: identifier (e.g. `.qiyamStart`, `.ruku`, `.qiyamAfterRuku`,
  `.sujoodFirst`, `.julusBetween`, `.sujoodSecond`, `.qiyamNextRakat`,
  `.julusTashahhudMid`, `.julusTashahhudFinal`, `.tasleemRight`,
  `.tasleemLeft`)
- `expectedPosition`: which physical position should trigger advancement
  out of this state (Ruku / Sujood / Standing / Sitting / HeadTurnRight /
  HeadTurnLeft / none — for the initial Takbir announcement which has no
  prior motion requirement)
- `onEnterAudio`: what to say/play when this state begins (e.g. entering
  `.ruku` state plays "Subhana Rabbiyal A'la" — wait, confirm phrasing/cue
  order against the structure below, this is illustrative)
- `confirmationHoldSeconds`: how long the expected position's thresholds
  must be continuously satisfied before we confirm and advance (start with
  1.0-1.5 seconds — long enough to reject brief/passing motion, short
  enough not to feel laggy)
- `timeoutSeconds`: how long to wait before re-prompting if the expected
  position hasn't been confirmed (8 seconds, flat across all states/
  position types — confirmed value, not a placeholder).
- `repromptAudio`: what to say if the timeout fires (repeats the prompt,
  does NOT advance the state). REPROMPT BEHAVIOR IS REPEATING: if
  `timeoutSeconds` elapses again after a reprompt with still no motion
  detected, play `repromptAudio` again, and keep repeating every 8 seconds
  indefinitely until the expected motion is confirmed. There is no maximum
  reprompt count/give-up behavior in this version — the app should wait as
  long as it takes, reprompting every 8s, rather than timing out into a
  different fallback state. (If a max-retry/escalation behavior is wanted
  later, that's a future decision, not in scope now.)

### Reprompt audio per state (fill in for every motion-triggered state, not just Ruku)
| State | Reprompt audio |
|---|---|
| `ruku` / `ruku2` | "Please bow into Ruku" |
| `qiyamAfterRuku` / `qiyamAfterRuku2` | "Please return to standing" |
| `sujoodFirst` / `sujoodThird` | "Please lower into Sujood" |
| `julusBetween` / `julusBetween2` | "Please sit up" |
| `sujoodSecond` / `sujoodFourth` | "Please lower into Sujood again" |
| `qiyamRakat2` | "Please stand for the next rakat" |
| `julusTashahhudFinal` | "Please sit for Tashahhud" |
| `tasleemRight` | "Please turn your head to the right" |
| `tasleemLeft` | "Please turn your head to the left" |

Note: reprompt text above is functional/placeholder phrasing for
development — fine to ship as-is for testing, but flag for review later
alongside the other recitation content, since tone/wording for these
instructional cues should probably feel calm and unobtrusive rather than
like an error message, given the context (mid-prayer).

### Detection logic per expected position
- **Ruku**: pitch within [-80°, -65°] sustained for `confirmationHoldSeconds`.
- **Sujood**: roll within [150°, 175°] (handle wraparound near ±180°
  carefully — see note below) sustained for `confirmationHoldSeconds`.
  Use pitch in range [-70°, -45°] as a secondary confirming check, not a
  blocking requirement.
- **Standing/Sitting (near-upright positions)**: pitch within roughly
  [-20°, 10°] AND roll within roughly [-25°, -10°] indicates "near upright"
  generically. To decide WHICH near-upright position this is (standing vs
  sitting), do NOT re-derive from thresholds — instead trust the state
  machine's sequence position. E.g. the state immediately following
  `.ruku` is ALWAYS `.qiyamAfterRuku` (standing), regardless of roll
  nuance; the state immediately following `.sujoodSecond` in the middle of
  a rakat is ALWAYS `.julusBetween` or a sitting-type state, never
  standing. Roll's small gap can be logged/used as a confidence weight but
  should not override sequence logic in this version.
- **Head turn right / left (Tasleem)**: capture yaw baseline from the most
  recent confirmed Qiyam state in this session. Look for yaw delta of
  roughly +/-30° or more from that baseline (exact threshold needs
  validation from real data once this is testable — flag this as a TODO
  to tune after first real test).

### Handling ANGLE WRAPAROUND for roll near ±180°
Roll values near sujood can flip between +179° and -179° due to how
Euler angles wrap. When comparing against the [150°, 175°] sujood range,
normalize/compare using absolute angular distance (e.g. convert to a
0-360 representation or use `min(abs(a-b), 360-abs(a-b))`) rather than a
naive numeric range check, to avoid missing valid sujood readings that
happen to read as e.g. -178° instead of +178°.

### Smoothing
Apply a simple moving average or low-pass filter (e.g. average the last
5-10 samples) to pitch/roll/yaw before evaluating against thresholds, to
reduce false triggers from sensor jitter. Don't smooth so aggressively
that real, fast transitions get missed — this needs empirical tuning,
start conservative (small window) and adjust based on testing.

## Full multi-rakat sequence structure

Build this as a configurable sequence generator, since rakat count and
tashahhud placement vary (e.g. standard 2-rakat prayer vs 3 or 4-rakat
prayer, with a mid-prayer tashahhud after the 2nd rakat in 3/4-rakat
prayers, and a final tashahhud + tasleem at the very end regardless of
total rakat count).

This section also defines the validated CONTENT for a 2-rakat prayer
(e.g. Fajr), confirmed with the user. Use this as the reference
implementation; the structure should still be built generically/
configurably so other rakat counts can be added later, but don't guess at
content for those yet — implement the 2-rakat version below precisely,
and leave clear extension points for 3/4-rakat variants to be filled in
separately.

### Trigger types (apply to every step below)
- **App-initiated (auto)**: audio plays automatically, not gated on motion.
- **Motion-triggered**: app waits for confirmed motion detection (per the
  detection logic defined earlier in this doc) before playing this audio
  and advancing state.
- **User-paced (silent)**: app does not prompt or recite during this step;
  user recites silently/aloud at their own pace. App simply waits here
  before issuing the next auto-cue. NOTE: there is currently no detection
  mechanism for "user has finished reciting" — see TODO below.

### RAKAT 1

| # | State id | Trigger | Audio |
|---|---|---|---|
| 1 | `qiyamStart` | Auto | "Allahu Akbar" (Takbiratul Ihram — opens the prayer) |
| 2 | `qiyamIstiftah` | Silent/user-paced (optional, see TODO) | "Subhanaka Allahumma wa bihamdika..." |
| 3 | `qiyamFatihah` | Silent/user-paced | Al-Fatihah (full recitation, user-paced) |
| 4 | `qiyamSurah` | Silent/user-paced | Additional short surah (full recitation, user-paced) |
| 5 | `qiyamCueBow` | Auto | "Allahu Akbar" (cue to bow) |
| 6 | `ruku` | **Motion** (pitch ~-73° to -75°) | "Subhana Rabbiyal A'la" ×3 |
| 7 | `qiyamAfterRuku` | **Motion** (return to upright; sequence-inferred standing) | "Sami Allahu liman hamidah" then "Rabbana lakal hamd" |
| 8 | `cueProstrate1` | Auto | "Allahu Akbar" (cue to prostrate) |
| 9 | `sujoodFirst` | **Motion** (roll ~160-164°) | "Subhana Rabbiyal A'la" ×3 |
| 10 | `cueSit1` | Auto | "Allahu Akbar" (cue to sit) |
| 11 | `julusBetween` | **Motion** (near-upright; sequence-inferred sitting) | "Rabbi ighfir li, Rabbi ighfir li" |
| 12 | `cueProstrate2` | Auto | "Allahu Akbar" (cue to prostrate again) |
| 13 | `sujoodSecond` | **Motion** (roll ~160-164°) | "Subhana Rabbiyal A'la" ×3 |
| 14 | `cueStand` | Auto | "Allahu Akbar" (cue to stand for next rakat) |

End of Rakat 1 → not the final rakat (in a 2-rakat prayer) → proceed to
Rakat 2 at `qiyamStart`-equivalent, but WITHOUT repeating Takbiratul Ihram
(see Rakat 2 row 16 below — this is a structurally different state from
`qiyamStart`, since it's motion-triggered rather than auto, and has no
opening Takbir).

### RAKAT 2

| # | State id | Trigger | Audio |
|---|---|---|---|
| 16 | `qiyamRakat2` | **Motion** (return to standing; sequence-inferred) | none — silence, proceed directly to recitation |
| 17 | `qiyamFatihah2` | Silent/user-paced | Al-Fatihah |
| 18 | `qiyamSurah2` | Silent/user-paced | Additional short surah |
| 19 | `qiyamCueBow2` | Auto | "Allahu Akbar" |
| 20 | `ruku2` | **Motion** | "Subhana Rabbiyal A'la" ×3 |
| 21 | `qiyamAfterRuku2` | **Motion** | "Sami Allahu liman hamidah" then "Rabbana lakal hamd" |
| 22 | `cueProstrate3` | Auto | "Allahu Akbar" |
| 23 | `sujoodThird` | **Motion** | "Subhana Rabbiyal A'la" ×3 |
| 24 | `cueSit2` | Auto | "Allahu Akbar" |
| 25 | `julusBetween2` | **Motion** | "Rabbi ighfir li, Rabbi ighfir li" |
| 26 | `cueProstrate4` | Auto | "Allahu Akbar" |
| 27 | `sujoodFourth` | **Motion** | "Subhana Rabbiyal A'la" ×3 |

End of Rakat 2 → this IS the final rakat of a 2-rakat prayer → transition
to Tashahhud/closing instead of standing again.

### CLOSING (final rakat only)

| # | State id | Trigger | Audio |
|---|---|---|---|
| 28 | `cueSitTashahhud` | Auto | "Allahu Akbar" (cue to sit for tashahhud) |
| 29 | `julusTashahhudFinal` | **Motion** (sequence-inferred sitting) | Full Tashahhud: "At-tahiyyatu lillahi wa salawatu wat-tayyibat..." followed by Salawat (salutations on the Prophet) and closing supplications |
| 30 | `tasleemRight` | **Motion** (yaw delta right from baseline) | "Assalamu Alaikum wa Rahmatullah" |
| 31 | `tasleemLeft` | **Motion** (yaw delta left from baseline) | "Assalamu Alaikum wa Rahmatullah" |
| 32 | `prayerComplete` | Auto | Completion message/sound |

### TODOs flagged by the user — do not silently resolve these, surface
### them back for a decision:
- **Istiftah (state 2)** is optional/varies by tradition. Confirm with the
  user whether to include it by default, make it a toggle, or omit it.
- **Silent/user-paced states (Fatihah, Surah recitation)** currently have
  no detection mechanism for "the user has finished reciting" — the state
  machine needs SOME way to know when to move on from these states. Likely
  options to discuss with the user: (a) a fixed/configurable wait duration,
  (b) a manual "tap or tap-equivalent" cue (conflicts with the hands-free
  goal), (c) detect the NEXT motion (bowing into Ruku) as the implicit
  "user has finished Fatihah/Surah" signal, treating qiyamFatihah/
  qiyamSurah as a single combined state that simply waits for Ruku motion
  rather than needing its own advancement trigger. Option (c) is likely
  the cleanest fit with the hands-free, motion-driven design philosophy —
  implement it this way unless told otherwise, but flag this assumption
  clearly in code comments since it's a design decision, not just an
  implementation detail.
- **Exact wording/transliteration/translation** of all recitations above
  should be verified against a source the user trusts before shipping —
  treat current text as a structurally-correct placeholder for development/
  testing, not final content.
- **3 and 4-rakat prayer variants** (with mid-prayer tashahhud) are NOT
  defined in this task — only 2-rakat. Build the sequence generator to be
  extensible for this, but don't invent the 3/4-rakat content yet.

### Configuration
Make total rakat count and tashahhud placement a simple configurable
parameter (e.g. an array defining which rakat indices require a
mid-prayer tashahhud, since this varies by which prayer is being performed
— don't hardcode a single prayer's structure, build it so we can configure
different prayers later). The 2-rakat table above should be expressible as
one configuration of this generator, not a special-cased hardcoded path.

## What NOT to do in this pass
- The full 2-rakat recitation content IS specified above (RAKAT 1, RAKAT 2,
  CLOSING tables) — implement that content precisely, do NOT substitute
  placeholder strings for it. (Note: an earlier draft of this task said to
  use placeholders like `[RUKU_DHIKR]` — that instruction is SUPERSEDED by
  the content tables above and should be disregarded.)
- Do not implement background-mode operation yet — foreground only for
  this build, same as previous spikes.
- Do not throw away the existing guided-recording mode — keep it
  accessible separately (useful for future data collection/calibration),
  but the new reactive mode is the primary flow going forward.

## Testing plan after implementation
Build to physical iPhone with AirPods. Run through a full prayer (your
choice of rakat count) letting the app react to real movement rather than
following fixed timing. Pay attention to:
- Does it correctly wait for Ruku before advancing (not advance from a
  partial bow)?
- Does Sujood get detected reliably via the roll signal?
- Does standing-after-ruku vs sitting-between-sujood get correctly
  inferred from sequence (since sensor data alone can't tell them apart)?
- Does the timeout/re-prompt fire sensibly if you pause mid-prayer or
  move slowly?
- Does Tasleem (head turn) get detected, and does the yaw-delta-from-
  baseline approach work as expected?

Report back with what worked, what mis-detected or had false triggers,
and we'll tune thresholds and hold/timeout durations from there.

## Additional small fix to include in this same pass: disable screen auto-lock during active sessions

Separately from the state machine work above, also fix this: the screen
currently turns off via the standard iOS idle timeout while a session
(guided OR reactive) is actively running. Since sessions are meant to run
hands-free, this isn't functionally critical, but the screen should stay
awake while a session is active in case the user glances at it.

- Set `UIApplication.shared.isIdleTimerDisabled = true` when a session
  starts (both guided recording mode and the new reactive mode).
- Set it back to `false` on every exit path: natural completion, manual
  cancel, error, and the view disappearing/app backgrounding. Do not leave
  it permanently `true` after a session ends — that would stop the user's
  phone from ever auto-locking system-wide, not just within this app.
- Double check every code path that can end a session actually resets this
  flag — this is an easy thing to miss and has an annoying side effect if
  missed.
