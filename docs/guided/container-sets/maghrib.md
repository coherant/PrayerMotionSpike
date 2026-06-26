# Maghrib Container Set

**Status: SPEC (not yet built).** The Muezzin's frame around the Maghrib observance. Fourth
container-set; Dhuhr-shaped tail, with its own opening twist. Model:
`../CONGREGATIONAL-CONTAINER.md`.

- **Inner observance:** `../prayer-sets/maghrib.md` + `../observances.md`. Untouched here.
- **Call content:** `../CONGREGATIONAL-CONTAINER.md` §A — *Container Call Library*.
- **Voice:** every row is the **Muezzin**; he never voices in-salah recitation.

Maghrib is **Farḍ (3) → Sunnah-after (2)** — **no sunnah-before**, no Qunūt (Ḥanafī). It is
the only prayer with no rawātib before the farḍ, so the container opens **straight into the
Iqāma → farḍ** (the Ezan pre-roll, then commence — no sunnah unit in between). The 3-rakʿah
farḍ is the odd-count one.

**Tail shape: Dhuhr-like** — boundary du'ā `C-3` after the farḍ, then the sunnah-after, then
the seal `C-4…C-11`.

Three voices — 🟢 **Muezzin** (this doc) · 🔵 **worshipper** (silent;
`prayer-sets/maghrib.md`) · ⚪ **guidance** (TTS).

---

## Timeline

| # | Voice | Phase | id |
|---|---|---|---|
| 0 | 🟢 | **Ezan / Adhān** *(optional; prayer-time-tied)* | `C-1` |
| 1 | 🟢 | **Iqāma** — opens the container (no sunnah-before to precede it) | `C-2` |
| 2 | ⚪ | Guidance: "Pray three rakʿah — the Farḍ of Maghrib." | — |
| 3 | 🔵 | **Farḍ unit** (3 rakʿah, silent) → `prayer-sets/maghrib.md` | — |
| 4 | 🟢 | **Boundary du'ā** (exits the farḍ) | `C-3` (= `P-23`) |
| 5 | ⚪ | Guidance: "Pray two rakʿah — the Sunnah of Maghrib." | — |
| 6 | 🔵 | **Sunnah-after unit** (2 rakʿah, silent) | — |
| 7 | 🟢 | **Post-prayer dhikr** (seals the observance) | `C-4 … C-10` |
| 8 | 🟢 | **Closing du'ā** | `C-11` |

Rhythm: **call → commence → (farḍ) → he marks the exit → (sunnah-after) → he seals it.**
No "you pray sunnah" before the commence — Maghrib steps straight to the Iqāma.

---

## C_ADHAN — Ezan
Mode: `listen` · Voice: Muezzin · **optional / ties to prayer-times**

| role | utterance | note |
|---|---|---|
| call | `C-1` | Standard call. |

> → No sunnah-before. The container proceeds directly to the Iqāma.

---

## C_IQAMA — Iqāma
Mode: `listen` · Voice: Muezzin

| role | utterance | note |
|---|---|---|
| call | `C-2` | *Qad qāmati-ṣ-ṣalāh.* The container's first interior act — here it follows the Ezan immediately. |

> → **Farḍ unit** — 3 rakʿah, silent and motion-gated.

---

## C_BOUNDARY — post-farḍ du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| boundary | `C-3` (= `P-23`) | *Allāhumma anta-s-salām…* — right after the farḍ taslīm, before the sunnah-after. |

> → **Sunnah-after unit** — 2 rakʿah, silent. The seal waits for the end.

---

## C_DHIKR — post-prayer remembrance (the seal)
Voice: Muezzin (worshipper follows on the tasbīḥ counter where marked). **After the last
unit (sunnah-after).**

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

## What Maghrib shows
No new tail rule (Dhuhr-shaped: boundary after farḍ, seal after sunnah-after). Its
distinctive is the **opening**: **no sunnah-before**, so the Ezan hands straight to the
Iqāma — the container has no opening sunnah unit. Confirms the open adapts to composition
just as the tail does.
