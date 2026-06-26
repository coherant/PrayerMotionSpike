# Asr Container Set

**Status: SPEC (not yet built).** The Muezzin's frame around the Asr observance. Third
container-set; inherits the rule from `dhuhr.md`. Model: `../CONGREGATIONAL-CONTAINER.md`.

- **Inner observance:** `../prayer-sets/asr.md` + `../observances.md`. Untouched here.
- **Call content:** `../CONGREGATIONAL-CONTAINER.md` §A — *Container Call Library*.
- **Voice:** every row is the **Muezzin**; he never voices in-salah recitation.

Asr is **Sunnah-before (4) → Farḍ (4)** — no sunnah-after, no Qunūt (Ḥanafī). The
sunnah-before is *ghayr muʾakkadah* (non-emphasised, toggleable); if the worshipper omits
it, the observance opens straight at the Iqāma → farḍ.

**Shape: Fajr-degenerate.** The farḍ *is* the last unit, so the boundary du'ā `C-3` and the
seal (`C-4…C-11`) coincide after the farḍ — exactly like Fajr, only with 4-rakʿah units.

Three voices — 🟢 **Muezzin** (this doc) · 🔵 **worshipper** (silent; `prayer-sets/asr.md`)
· ⚪ **guidance** (TTS).

---

## Timeline

| # | Voice | Phase | id |
|---|---|---|---|
| 0 | 🟢 | **Ezan / Adhān** *(optional; prayer-time-tied)* | `C-1` |
| 1 | ⚪ | Guidance: "Pray four rakʿah — the Sunnah of Asr." *(omitted if untoggled)* | — |
| 2 | 🔵 | **Sunnah-before unit** (4 rakʿah, silent) → `prayer-sets/asr.md` *(optional)* | — |
| 3 | 🟢 | **Iqāma** — opens the container | `C-2` |
| 4 | ⚪ | Guidance: "Pray four rakʿah — the Farḍ of Asr." | — |
| 5 | 🔵 | **Farḍ unit** (4 rakʿah, silent) | — |
| 6 | 🟢 | **Boundary du'ā** (= seal anchor; farḍ is last) | `C-3` (= `P-23`) |
| 7 | 🟢 | **Post-prayer dhikr** | `C-4 … C-10` |
| 8 | 🟢 | **Closing du'ā** | `C-11` |

Rhythm: **call → (sunnah) → commence → (farḍ) → he seals it** — Fajr's rhythm at Asr's
weight.

---

## C_ADHAN — Ezan
Mode: `listen` · Voice: Muezzin · **optional / ties to prayer-times**

| role | utterance | note |
|---|---|---|
| call | `C-1` | Standard call. |

> → **Sunnah-before unit** *(optional)* — 4 rakʿah before the Iqāma. See `prayer-sets/asr.md`.

---

## C_IQAMA — Iqāma
Mode: `listen` · Voice: Muezzin

| role | utterance | note |
|---|---|---|
| call | `C-2` | *Qad qāmati-ṣ-ṣalāh.* |

> → **Farḍ unit** — 4 rakʿah, silent and motion-gated. The last unit.

---

## C_BOUNDARY — post-farḍ du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| boundary | `C-3` (= `P-23`) | *Allāhumma anta-s-salām…* — after the farḍ; here it flows straight into the seal (no sunnah-after between). |

---

## C_DHIKR — post-prayer remembrance (the seal)
Voice: Muezzin (worshipper follows on the tasbīḥ counter where marked).

| role | utterance | mode | meaning |
|---|---|---|---|
| dhikr | `C-4` | `count` ×3 | *Astaghfirullāh* |
| dhikr | `C-5` | `listen` | **Āyat al-Kursī** (Qur'an 2:255) |
| dhikr | `C-6` | `count` ×33 | *Subḥānallāh* |
| dhikr | `C-7` | `count` ×33 | *Alḥamdulillāh* |
| dhikr | `C-8` | `count` ×33 | *Allāhu akbar* |
| dhikr | `C-9` | `listen` ×1 | tahlīl (completes 100) |
| dhikr | `C-10` | `listen` | **Ṣalawāt** ﷺ |

Order + count locked (`../CONGREGATIONAL-CONTAINER.md` §B).

---

## C_CLOSING — closing du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| closing | `C-11` | Hands raised; seals the session. |

---

## What Asr confirms
No new rule — Asr is the **Fajr-degenerate** case at 4+4. Confirms that "no sunnah-after"
collapses boundary-du'ā and seal into one tail after the farḍ. The optional sunnah-before
shows the container adapting to unit inclusion (untoggled → opens at the Iqāma).
