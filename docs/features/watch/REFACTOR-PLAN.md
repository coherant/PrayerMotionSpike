# Apple Watch — Consolidation & Core Extraction — Refactor Plan

Working document for the staged arc on branch `watch-core-extraction`
(baseline `ecb4f8c` off `main`). Goal: fold the standalone Apple-Watch prayer
tracker (today a separate spike repo) into this repo, then **extract a
`SalahMotionCore` package** that both the iPhone and Watch shells drive through
narrow seams — so the state machine, sequence logic, and guidance become a
sensor- and shell-agnostic core.

This doc is the shared source of truth for the arc. It outlives sessions; keep
it current. **DRAFT — awaiting red-pen. Nothing has moved yet.**

---

## Why (the product frame)

The **Apple Watch prayer tracker is the paid, standalone feature** — it must
eventually run a full guided/silent salah **without the phone in the loop**.
Everything below serves that: the core has to stop assuming an iPhone, an
`AudioManager`, or head-mounted AirPods, so a wrist-only watch app can host it.

Two repos exist today:

- **`SalahMotion`** (this repo): the shipping iPhone app. `.xcodeproj`. Owns the
  real guided/silent engine — `PrayerStateMachine`, `GuidedSequenceGenerator`,
  the `PrayerState` vocabulary, `AudioManager`, `HeadphoneMotionDetector`, the
  golden snapshot.
- **`WatchMotionSpike`** (sibling repo, `/Users/ohuseyin/src/WatchMotionSpike`):
  a throwaway-ish spike. XcodeGen (`project.yml`), watchOS 10 / iOS 17.
  Standalone watch app (`WKApplication`) with `CMMotionManager` deviceMotion
  @50Hz kept alive by an `HKWorkoutSession(.mindAndBody)`, a labeled-capture
  `MotionLogger`, WC file/stream export, and an iOS **Relay** app (WebSocket →
  Mac) for telemetry capture. Its `Shared/` already holds the posture vocabulary
  (`PrayerPosition`, `PositionReading`, `MotionSample`), but
  `PrayerPosition.classify(pitch:roll:)` is a **stub** — deriving it from real
  wrist data is the whole point of the spike.

---

## Locked decisions (agreed 2026-07-01)

These are settled. This section is the record; the stages below implement them.

1. **Watch = paid standalone.** Wrist-only is the product baseline; it must work
   with no phone.
2. **XcodeGen everywhere.** Migrate *this* repo from `.xcodeproj` to a single
   `project.yml` (iPhone app + watch app + `SalahMotionCore` package). The spike
   is already XcodeGen; this aligns them.
3. **Relay stays in the spike repo.** The WebSocket→Mac Relay is a telemetry
   tool, not product. It does not move here.
4. **Consolidate early.** Copy the watch *product* parts (motion, session,
   workout-keepalive, the watch UI shells) into a new **`SalahMotionWatch`**
   target in this repo. **Keep the spike repo alive** until telemetry is
   captured and `classify()` is derived — the spike is where that data work
   happens (Stage 2), not here.
5. **Guidance = Option A.** The core emits **semantic guidance events**
   (`.recite` / `.instruct` / `.call` …); the *shells* render and fan them out
   (iPhone = audio via `AudioManager`, watch = haptics + optional audio). Events
   are **awaitable** so guided-mode audio-completion timing survives (the caller
   can await "recitation finished"); a watch/silent shell that has nothing to
   play returns instantly — **the body is the clock**.
6. **The sensor seam = posture transitions.** The sensor layer emits *posture
   transitions* ("now in ruku"); the core consumes them. Sequence/phase logic is
   shared and lives in the core; **posture *detection* + calibration is
   sensor-specific** — wrist geometry ≠ head geometry (this is the fix for the
   ruku/upright head-pitch overlap in the guided-motion-guardrails work).
7. **AirPods = optional boost, not baseline.** `CMHeadphoneMotionManager` is
   available watchOS 7+, so wrist + AirPods fusion *can* run entirely on the
   watch — but that's an accuracy add-on. An **ablation (wrist vs head vs fused)**
   decides how much it buys us. Runtime AirPods→watch delivery is still an
   unverified device-only test.

---

## Principles

1. **MD-first.** Update this plan / the specs, then hand-translate Swift to
   match. Never the reverse.
2. **Golden snapshot is the safety net.** `GuidedSnapshotTests` freezes the
   emitted guided `[PrayerState]` arrays for every `SalatType` + Witr.
   **Consolidation and extraction are behavior-preserving: the snapshot must stay
   byte-identical through Stages 1 and 3.** Only a stage that deliberately
   changes guidance behavior may show a reviewed, intentional diff.
3. **No big-bang.** Each stage compiles, builds both platforms where relevant,
   and passes the snapshot. Every stage is independently reversible.
4. **Extract by need, not by neatness.** A file moves into `SalahMotionCore`
   only when a seam actually requires it there — not to tidy the tree.
5. **Wrist-only first.** Prove the standalone wrist path before adding the
   AirPods fusion boost.

---

## The seam architecture (target state)

`SalahMotionCore` is a Swift package with **no UIKit, no AVFoundation, no
CoreMotion, no HealthKit** — pure sequence + state logic. It talks to each shell
through two narrow seams:

```
            ┌──────────────── SalahMotionCore ────────────────┐
 sensors →  │  MotionSource (IN)                              │
 (wrist /   │     MotionTrigger.ruku ─────▶ PrayerStateMachine  │
  head /    │                                        │        │
  fused)    │                                        ▼        │
            │                              GuidanceEvent (OUT) │  ──▶ shell renders
            │                              .recite/.instruct/… │      (iPhone: audio,
            └────────────────────────────────────────────────-┘       watch: haptic)
```

- **IN — `MotionSource` protocol.** The core consumes a stream of `MotionTrigger`
  transitions (the existing seam vocab — `ruku / sujood / upright / headTurn*`) +
  raw pitch/roll/yaw for progress UI. Each source detects a sensor-specific
  `PrayerPosition` internally and translates the transition to a `MotionTrigger`.
  Implementations live in the *shells*: iPhone's `HeadphoneMotionDetector`, the
  watch's wrist `CMMotionManager` source, a fused source, and a **scripted test
  source** (so the snapshot and future logic tests can drive the machine
  deterministically).
- **OUT — `GuidanceEvent` (Option A).** The machine, instead of calling
  `AudioManager` directly, *emits* awaitable semantic events. The iPhone shell's
  renderer maps them to `AudioManager`; the watch shell maps them to
  haptics/audio. Silent mode = a renderer that returns instantly.

**Vocabulary — resolved to three layers, not a merge** (see Resolved Q#2). The
spike's `PrayerPosition` (`Qiyam/Ruku/Sujud/Jalsa/unknown`) is a sensor-side
**detection** label; the core's existing `MotionTrigger`
(`ruku/sujood/upright/headTurn*`, `PrayerSequence.swift:17`) is the **seam** — the
posture *transition* every `PrayerState` already waits on; `PrayerState` is the
**observance step**. They never merge: the `MotionSource` translates a detected
`PrayerPosition` transition → `MotionTrigger`; the core keeps `MotionTrigger`
canonical. **`PrayerPosition` stays out of the core.**

---

## Stages

### Stage 0 — Lock current truth + baseline snapshot  ← *this doc*
*Mostly writing. No code moves.*
- Write this `REFACTOR-PLAN.md` (source of truth for the arc).
- **Confirm the golden snapshot is green on `main`/baseline** — that green run is
  the safety net every later stage is measured against. (Result recorded in
  Status below.)
- **Exit:** plan red-penned and agreed; snapshot confirmed green at baseline.

### Stage 1 — Consolidate + XcodeGen migration ✅ DONE
*Behavior-preserving. Snapshot stayed byte-identical.*
- **1a (`9cf26ef`):** `.xcodeproj` → `project.yml` (xcodegen 2.45.4). Faithful —
  iOS 26.5, Swift 5.0, `MainActor` isolation, generated Info.plist, SwiftAA 3.0.1,
  test-host wiring all preserved; app builds; snapshot byte-identical green.
- **1b (`ee88b74`):** new single-target watchOS app `SalahMotionWatch`. Copied the
  product parts from the spike (`MotionManager`, `WorkoutSessionManager`, the
  `Shared` vocab, `StateMachineView` + `WorkoutSessionView`); trimmed app entry;
  **left the capture/export tooling** (`MotionLogger`, `MotionStreamer`,
  `ExportManager`, Relay, `PositionLabView`, `TelemetryView`) in the spike. Watch
  builds green (watchOS 26.5 sim); iPhone snapshot byte-identical; watch does not
  touch the core yet.
- **Original stage notes (for reference):**
- Migrate this repo `.xcodeproj` → `project.yml` (XcodeGen): iPhone app target +
  `SalahMotionTests` + a new **`SalahMotionWatch`** watchOS app target. Green
  build of the iPhone app + green snapshot **first**, before adding watch code —
  isolate the project-format change from the code move.
- Copy the watch **product** parts from the spike into `SalahMotionWatch`: the
  wrist `MotionManager`, `WorkoutSessionManager` (HK keepalive), and the watch
  UI shells. **Leave** the Relay, `MotionLogger` capture tooling, and export
  paths in the spike.
- The watch target does *not* touch the core yet — it stands alongside the app.
- **Exit:** both targets build; iPhone app unchanged; snapshot byte-identical;
  spike repo still intact for telemetry.

### Stage 2 — Telemetry + derive `classify()`  (in the spike repo)
*Happens in `WatchMotionSpike`, not here. Listed for arc completeness.*
- Use the spike's labeled-capture + Relay to record real wrist motion across the
  four postures; derive real thresholds for `PrayerPosition.classify(pitch:roll:)`
  (and whatever fused-signal variant the ablation favors).
- Ablation: wrist-only vs head-only vs fused — decides the baseline detector.
- **Exit:** a data-backed wrist `classify()` we trust enough to port; a decision
  on AirPods fusion. Nothing in *this* repo changes.

### Stage 3 — Extract `SalahMotionCore` + cut the seams
*The heart of the arc. Behavior-preserving — snapshot green each step.*
- Create the `SalahMotionCore` package (no platform frameworks). Move the pure
  logic in: `PrayerStateMachine`, `GuidedSequenceGenerator`, `PrayerState` and
  its libraries, the sequence/observance model.
- **Cut seam IN:** introduce `MotionSource`; `PrayerStateMachine` loses its
  hard-wired `HeadphoneMotionDetector` (today `PrayerStateMachine.swift:47`) and
  takes a `MotionSource` instead. iPhone shell injects the AirPods source.
- **Cut seam OUT (Option A):** `PrayerStateMachine` loses its hard-wired
  `AudioManager` (today `PrayerStateMachine.swift:46`) and instead emits
  awaitable `GuidanceEvent`s. iPhone shell adds the `AudioManager` renderer;
  behavior identical to today.
- **Keep `MotionTrigger` canonical at the seam** (resolved Q#2): the `MotionSource`
  translates its internal `PrayerPosition` detection → `MotionTrigger`;
  `PrayerPosition` never enters the core. `GuidanceEvent` is per-utterance
  (resolved Q#3), tagged with the `Utterance` role (instruct/recite/plain).
- Do each move behind a green snapshot; a scripted `MotionSource` + event-sink
  gives the snapshot/logic tests deterministic drive.
- **Add the `GuidanceEvent` golden snapshot** (resolved Q#5): a scripted
  `MotionSource` drives the machine through each `SalatType`; freeze the emitted
  awaitable `GuidanceEvent` stream to a checked-in fixture. This is the primary
  net that the OUT-seam cut is behavior-preserving — the `[PrayerState]` snapshot
  does not exercise runtime emission. Green before and after the `AudioManager`
  removal.
- **Exit:** iPhone app runs entirely on `SalahMotionCore`; *both* snapshots
  (`[PrayerState]` input + `GuidanceEvent` stream) green; core has zero
  platform-framework imports.

### Stage 4 — Watch on the core + guided watch calibration
*New behavior; snapshot may gain watch-specific rows but iPhone rows stay pinned.*
- Point `SalahMotionWatch` at `SalahMotionCore`: wrist `MotionSource` in, a
  haptic `GuidanceEvent` renderer out. Wrist-only first; AirPods fusion behind a
  flag if Stage 2 says it's worth it.
- Watch calibration flow (wrist geometry) — sensor-specific, per decision 6.
- **Exit:** a standalone wrist-only guided + silent salah on the watch, phone
  out of the loop.

---

## Resolved during red-pen (2026-07-01)

- **`SalahMotionWatch` = a single watchOS app target** (was open Q#1). No app +
  extension split; watchOS 10 single-target. Restated in Stage 1.
- **Seam type = the core's existing `MotionTrigger`; `PrayerPosition` is *not*
  promoted to the boundary** (was open Q#2). The app already owns the seam:
  `MotionTrigger` (`ruku / sujood / upright / headTurnRight / headTurnLeft`,
  `PrayerSequence.swift:17`) is what every `PrayerState.motionTrigger` waits on
  and what the golden snapshot serializes. The spike's `PrayerPosition`
  (`Qiyam/Ruku/Sujud/Jalsa/unknown`) is a *different axis* — a classifier label,
  not a transition. So the "`PrayerPosition` vs `PrayerState`" reconciliation
  resolves to **three layers that never merge**:

  | Layer | Type | Lives | Nature |
  |---|---|---|---|
  | Detection | `PrayerPosition` | *inside* each `MotionSource` (wrist/head/fused) | geometry-specific classifier output |
  | **Seam** | **`MotionTrigger`** | core boundary | the posture *transition* the machine consumes |
  | Observance | `PrayerState` | core | a step in the salah |

  The `MotionSource` translates a detected posture-transition → `MotionTrigger`.
  Why `MotionTrigger`, not `PrayerPosition`: (1) it already *is* the boundary —
  zero snapshot churn, no re-authoring every state; (2) it expresses head-turns
  (taslīm salām) that `PrayerPosition` can't; (3) `.upright` deliberately
  collapses standing/sitting, *disambiguated by sequence position* — core
  knowledge the sensor can't have, so promoting `PrayerPosition` (standing≠sitting)
  would wrongly push that down to the sensor; (4) `PrayerPosition` carries
  detection concerns (`.unknown`, thresholds, emoji) — wrong for a clean seam.
- **`GuidanceEvent` granularity = per-utterance** (was open Q#3). `Utterance`
  (`PrayerSequence.swift:118`) already encodes the semantic role Option A needs:
  `.guidance` → instruct, `.recitation` → recite, `.plain` → TTS. A
  `GuidanceEvent` is one event per `Utterance`, tagged with role + an awaitable
  handle. Per-*state* would be wrong: one `PrayerState` emits several utterances
  (`entrySpeech`, each `prayers` line, `repromptAudio`, `exitSpeech`), and
  bundling them destroys the per-line audio-completion await that guided pacing
  depends on. Caveat: structural signals (phase entry, motion-wait, reprompt
  tick) are *also* events in the same stream — non-utterance ones — so the event
  snapshot (resolved Q#5) captures the whole fine-grained stream.
- **XcodeGen migration lands in Stage 1** (was open Q#2, renumbered). The whole repo goes to
  a single `project.yml` up front; we pay the cost once, before any code moves,
  rather than deferring to Stage 3. Restated in Stage 1.
- **Second golden snapshot on the `GuidanceEvent` stream — YES, born in Stage 3**
  (was open Q#5). The existing `[PrayerState]` snapshot freezes the machine's
  *input* (the generated sequence); it never exercises runtime emission. Option A
  moves the audio decisions *into* runtime `GuidanceEvent` emission — the exact
  seam Stage 3 cuts — so without an event snapshot, Stage 3's "behavior-
  preserving" claim has **no automated net on the thing being changed**. Fix:
  drive the machine with a scripted `MotionSource` and freeze the emitted
  `GuidanceEvent` stream. This becomes the **primary** net for the extraction;
  the `[PrayerState]` snapshot is the secondary net on the input side. It can't
  exist before Stage 3 (the type doesn't exist yet), so it's authored the moment
  the OUT-seam is cut. Folded into Stage 3's exit.

## Open questions for red-pen

*All Stage-0 red-pen questions resolved (see "Resolved during red-pen" above).
The remaining unknowns are data-gated, not decisions: the wrist `classify()`
thresholds and the wrist-vs-head-vs-fused ablation — both answered by Stage 2
telemetry, not by planning.*

---

## Status

- Branch `watch-core-extraction` cut off `main` @ `ecb4f8c`. No code moved.
- **Stage 0 ✅** (`95d3e62`). Plan red-penned + agreed (four resolutions above).
  **Golden snapshot baseline GREEN** @ `ecb4f8c` — the byte-for-byte reference
  Stages 1 and 3 must reproduce.
- **Stage 1 ✅** (`9cf26ef` XcodeGen migration, `ee88b74` `SalahMotionWatch`
  target). Both behavior-preserving: iPhone app builds, watch app builds
  (watchOS 26.5 sim), golden snapshot byte-identical green throughout.
- **Stage 2 ✅** (in the `WatchMotionSpike` repo): wrist telemetry captured;
  `classify()` v2 derived — **`gravityZ` separates all four postures 100%** across
  sessions (Euler pitch/roll couldn't; altimeter was drift-dominated bust). Wrist-only
  baseline validated; AirPods fusion demoted to optional. (Takbīr + cross-user
  validation parked.)
- **Stage 3 ✅ COMPLETE** (`03b99c0`→`81b4609`): `SalahMotionCore` extracted (pure —
  Foundation + Observation only, zero platform frameworks). Both seams cut:
  **`MotionSource`** (IN) and **`GuidanceEvent`/`GuidanceRenderer`** (OUT, Option A);
  `PrayerStateMachine` moved into the core; the iPhone app is now a shell injecting
  `HeadphoneMotionDetector` + `AudioGuidanceRenderer`. Both nets green: `[PrayerState]`
  snapshot byte-identical throughout; new `GuidanceEvent` runtime snapshot added (3c).
- **Next → Stage 4:** point `SalahMotionWatch` at the core — wrist `MotionSource`
  (using `classify()` v2) + haptic `GuidanceRenderer`; standalone wrist-only salah.
