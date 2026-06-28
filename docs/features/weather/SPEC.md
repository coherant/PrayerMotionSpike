# Weather — the nature-fusion layer

**Status: SPEC (building behind a flag).** A fusion of a weather app and the prayer
app: live, location-specific weather painted *into* the same living sky that already
renders time-of-day colour (`DayTheme`), the celestial arc (sun/moon), and birds —
plus the day's temperature alongside the prayer times. This completes the
"connected with nature" vision: one screen that agrees with the sky out the window.

Everything ships **behind `FeatureFlags.weather`** — OFF means the app is
byte-for-byte today's behaviour (no UI, no network, no cost).

---

## 1. Decisions (locked)

| Decision | Value |
|---|---|
| Data provider (first wire-up) | **Apple WeatherKit** (swappable; Open-Meteo is a drop-in behind the protocol) |
| Visual style | **Simulated / native** — SpriteKit `SKEmitterNode` + SwiftUI `Canvas` + Metal `Shader` |
| Cache window | **6h** (one constant; tunable) |
| DEBUG / Previews default | **MockWeatherProvider** (zero real calls during development) |
| Cache | **persisted to disk**, keyed `(gridCell, timeWindow)` |
| Go-to-market (free/paid/price) | **PARKED** — pricing/packaging decision, not engineering |

---

## 2. Architecture (mirrors `SolarEphemeris → SkyState → CelestialArcView`)

```
WeatherProvider  →  WeatherState (core, canonical)  →  view layers (render only)
```

### WeatherState (core value type)
- `condition: WeatherCondition`
- `intensity: Double`        // 0…1, drives particle density / opacity
- `cloudCover: Double`       // 0…1
- `precipChance: Double`     // 0…1
- `tempNowC, tempHighC, tempLowC` — **canonical °C** (core is unit-agnostic; the
  display unit is a user preference `TemperatureUnit`, converted at render time)
- `isDaylight: Bool`
- `asOf: Date`               // for staleness / display

### WeatherCondition (enum)
`clear · partlyCloudy · cloudy · fog · drizzle · rain · heavyRain · thunderstorm ·
snow · sleet · hail · wind` — provider conditions map onto this; the visual system
keys off it (never off a provider's raw type).

### WeatherProvider (boundary — the swap point)
```
protocol WeatherProvider {
    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState
}
```
Implementations: `WeatherKitProvider`, `MockWeatherProvider` (deterministic, dev),
later `OpenMeteoProvider` / `ProxyWeatherProvider` — all interchangeable.

### Caching (the cost lever — in from day one)
`CachedWeatherProvider` wraps any provider:
- Key: `(gridCell, timeWindow)` — `gridCell` = coordinates coarsened to a ~10km
  grid; `timeWindow` = `floor(now / 6h)`.
- **Persisted to disk** so dev relaunches (and app restarts) reuse within the window.
- Decouples calls from headcount the day a server proxy is introduced — no rewrite.
- **Dual-window hook (future):** daily high/low is stable for ~24h while current
  temp drifts; the key may later split into a 24h forecast window + a 6h current
  window to cut calls further. One-line change; not done now.

---

## 3. Cost / scale (engineering notes; pricing PARKED)

- WeatherKit free tier = **500,000 calls/month** (call ≠ user). At 6h cache, a
  device makes up to **~4 calls/day**.
- Caching-only scales calls with **users**; a future **server proxy** scales calls
  with **distinct locations × refresh rate**, independent of headcount (~30–60×
  cheaper at millions of users). The provider protocol makes this a later swap.
- **Development burn:** Mock-by-default in DEBUG/Previews → **0 real calls** while
  iterating; the live provider is reached only via an explicit dev switch, and the
  persisted cache caps even that at ~4/day. 500k/mo makes dev usage negligible.

---

## 4. Visual layer system (Stage 3)

`WeatherLayerView` composites, driven by `WeatherState`:
- **Precipitation** — SpriteKit `SKEmitterNode` via `SpriteView` (rain / heavyRain /
  snow / sleet / hail), density & speed scaled by `intensity`.
- **Clouds / fog / light** — SwiftUI `Canvas` (stylised, matches the painterly sky).
- **Accents** — iOS-17 Metal `Shader` (rain-on-glass, lightning flash for storms).
- **Performance:** animate only when the tab is foreground + active (mirror
  `isCelestialActive`); pause offscreen.

Built against `MockWeatherProvider` first (previews cycle every condition).

---

## 5. Fusion (Stage 4 — the product idea)

Weather is a native member of the sky stack, not a separate widget.

### Z-order (Prayer Times screen)
```
Prayer content (header · up-next · list · CTA)   ← focus, always on top
Weather effects (rain / snow / clouds / lightning)
Birds (wildlife)
Celestial arc (real sun / moon)
DayTheme sky gradient (time-of-day colour)        ← base
```

### Cross-domain reactivity (makes it feel alive)
- Overcast lowers the sky gradient luminance + dims celestial bodies.
- Rain thins the birds; clear night → full starfield; storm → lightning shader.
- Temperature + condition sit in the chrome (placement = a Stage-4 design call),
  glanceable, never competing with prayer info.
- Rides on `DayTheme.blend` — weather **tints over** the time-of-day sky, never
  replaces it.

---

## 6. Stages

- **Stage 0 — Toggle.** ✅ `FeatureFlags.weather` (off). Guards all entry points.
- **Stage 1 — Domain + provider boundary.** ✅ `WeatherState`, `WeatherCondition`,
  `WeatherProvider`, `MockWeatherProvider`, `CachedWeatherProvider` (persisted,
  6h). Unit tests (cache hit/miss, window, grid, Codable, temp conversion).
- **Stage 2 — WeatherKitProvider.** ✅ Live fetch (`.current` + `.daily`),
  WeatherKit→`WeatherCondition` mapping (+ tests), `WeatherProviderFactory`
  (Mock-by-default in DEBUG; `ff.weatherLive` switch to test live).
  ⚠️ **PENDING (your hands, before live/release):** enable the **WeatherKit
  capability** in the Apple Developer portal + target Signing & Capabilities, and
  add the mandatory **attribution** link. Dev works without it (mock default).
- **Stage 3 — Visual layer system.** ✅ `WeatherLayerView` against the mock:
  SpriteKit `SKEmitterNode` precipitation (rain/snow/hail, intensity-scaled,
  generated textures), Canvas clouds + fog veil (blurred, drifting), SwiftUI
  lightning flash for thunderstorms. `isActive` gates all animators; `tint` for
  light/dark skies; preview cycles every condition.
  ⤷ *Tier 2 applied:* **parallax depth cloud layers** only (3 bands, per-band
  blur/speed/opacity). Wind-leaned precipitation and cloud-illuminating lightning
  were trialled and **reverted** — precipitation & lightning stay at baseline.
  ⤷ *Deferred to Stage 5:* Metal `Shader` accents — FBM-noise volumetric-ish clouds
  and rain-on-glass distortion (need a `.metal` file) — as a top overlay.
- **Stage 4 — Fusion into Prayer Times.** 🟡 In progress.
  - ✅ **Weather chip** — icon + condition label + temperature in a themed capsule,
    bottom-right under the last prayer row (theme ink/muted/accent). The capsule is
    a **button: each tap cycles to the next condition**, starting at **sunny**
    (`WeatherStore.cycleManual`, `allCases` order from `.clear`) — a dev/demo so all
    conditions (and later the sky effects) can be reviewed live. All behind
    `FeatureFlags.weather`.
  - [ ] Wire the chip to **real** data — `WeatherStore.state` / `refresh` (factory +
    6h cache) already exist; swap `displayState` → `state` and fetch on
    location-change for production (tap-cycle stays a DEBUG aid).
  - ✅ Sky-effects layer — `WeatherLayerView` in the sky z-stack (above birds,
    behind content), driven by the same `displayState` the pill cycles, `tint: ink`,
    gated by `isCelestialActive`. (Clear/sunny stays a clean sky: clouds only above
    cloudCover 0.15.)
  - [ ] Cross-domain reactivity (overcast dims sky/celestial, rain thins birds…).
  - [ ] Settings — enable toggle + units (°C/°F); chip defaults to °C for now.
- **Stage 5 — Polish + cost guards.** Refresh on foreground / significant location
  change only; attribution; cache-window tuning.

---

## 7. Open decisions (don't block)
- Fusion layout — where temperature/condition live (Stage 4 design talk).
- Dual-window cache split (Stage 5+, if cost warrants).
- Provider beyond WeatherKit (Open-Meteo / proxy) — when go-to-market is decided.
