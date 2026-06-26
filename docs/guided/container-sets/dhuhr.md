# Dhuhr Container Set

**Status: SPEC (not yet built).** The Muezzin's frame around the Dhuhr observance. Second
container-set; maps against the Fajr reference (`fajr.md`) and resolves the **sunnah-after**
question Fajr couldn't reach. Model: `../CONGREGATIONAL-CONTAINER.md`.

- **Inner observance:** `../prayer-sets/dhuhr.md` + `../observances.md`. Untouched here.
- **Call content:** `../CONGREGATIONAL-CONTAINER.md` §A — *Container Call Library*.
- **Voice:** every row is the **Muezzin**; he never voices in-salah recitation.

Dhuhr is **Sunnah-before (4) → Farḍ (4) → Sunnah-after (2)** — three units, no Qunūt (Ḥanafī).
This is the first prayer with a **sunnah-after**, so it sets the rule the others inherit.

## The rule the sunnah-after forces (now general)
Two Muezzin acts, two different anchors:
- **Boundary du'ā `C-3`** (*Allāhumma anta-s-salām*) fires **immediately after the FARḌ**
  unit — it's the du'ā of exiting the obligatory prayer, and it punctuates the farḍ →
  sunnah-after transition.
- **Full dhikr `C-4…C-10` + closing `C-11`** **seal the whole observance** — after the
  **last** unit (here the sunnah-after).

This matches **Turkish/Ḥanafī practice**: *Allâhümme entesselâm* right after the farz, then
the son-sünnet, then the **tesbîhât** (33·33·33 + duâ) as the seal of the completed prayer.
For **Fajr** the two anchors coincide (the farḍ *is* the last unit) — Fajr is the degenerate
case of this same rule, not a different one.

Three voices — 🟢 **Muezzin** (this doc) · 🔵 **worshipper** (silent; `prayer-sets/dhuhr.md`)
· ⚪ **guidance** (TTS).

---

## Timeline

| # | Voice | Phase | id |
|---|---|---|---|
| 0 | 🟢 | **Ezan / Adhān** *(optional; prayer-time-tied)* | `C-1` |
| 1 | ⚪ | Guidance: "Pray four rakʿah — the Sunnah of Dhuhr." | — |
| 2 | 🔵 | **Sunnah-before unit** (4 rakʿah, silent) → `prayer-sets/dhuhr.md` | — |
| 3 | 🟢 | **Iqāma** — *opens the container proper* | `C-2` |
| 4 | ⚪ | Guidance: "Pray four rakʿah — the Farḍ of Dhuhr." | — |
| 5 | 🔵 | **Farḍ unit** (4 rakʿah, silent) | — |
| 6 | 🟢 | **Boundary du'ā** (exits the farḍ) | `C-3` (= `P-23`) |
| 7 | ⚪ | Guidance: "Pray two rakʿah — the Sunnah of Dhuhr." | — |
| 8 | 🔵 | **Sunnah-after unit** (2 rakʿah, silent) | — |
| 9 | 🟢 | **Post-prayer dhikr** (seals the observance) | `C-4 … C-10` |
| 10 | 🟢 | **Closing du'ā** | `C-11` |

Rhythm: **call → (sunnah) → commence → (farḍ) → he marks the exit → (sunnah-after) → he
seals it.**

---

## C_ADHAN — Ezan
Mode: `listen` · Voice: Muezzin · **optional / ties to prayer-times**

| role | utterance | note |
|---|---|---|
| call | `C-1` | The standard call (no Fajr "better than sleep" line). Ceremonial opening, or skipped when the real adhān already sounded. |

> → **Sunnah-before unit** — 4 rakʿah prayed individually before the Iqāma. See
> `prayer-sets/dhuhr.md`.

---

## C_IQAMA — Iqāma
Mode: `listen` · Voice: Muezzin

| role | utterance | note |
|---|---|---|
| call | `C-2` | *Qad qāmati-ṣ-ṣalāh.* Stands between the sunnah-before and the farḍ. |

> → **Farḍ unit** — 4 rakʿah, silent and motion-gated.

---

## C_BOUNDARY — post-farḍ du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| boundary | `C-3` (= `P-23`) | *Allāhumma anta-s-salām…* — fires **right after the farḍ taslīm**, before the sunnah-after. |

> → **Sunnah-after unit** — 2 rakʿah, silent. No dhikr yet; the seal waits for the end.

---

## C_DHIKR — post-prayer remembrance (the seal)
Voice: Muezzin (leads; worshipper follows on the tasbīḥ counter where marked). **After the
last unit (sunnah-after).**

| role | utterance | mode | meaning |
|---|---|---|---|
| dhikr | `C-4` | `count` ×3 | *Astaghfirullāh* — I seek God's forgiveness |
| dhikr | `C-5` | `listen` | **Āyat al-Kursī** (Qur'an 2:255) |
| dhikr | `C-6` | `count` ×33 | *Subḥānallāh* |
| dhikr | `C-7` | `count` ×33 | *Alḥamdulillāh* |
| dhikr | `C-8` | `count` ×33 | *Allāhu akbar* |
| dhikr | `C-9` | `listen` ×1 | tahlīl — *Lā ilāha illā-llāhu waḥdah…* (completes 100) |
| dhikr | `C-10` | `listen` | **Ṣalawāt** ﷺ |

Order + count locked identically to Fajr (`../CONGREGATIONAL-CONTAINER.md` §B).

---

## C_CLOSING — closing du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| closing | `C-11` | Hands raised — istighfār and supplication; seals the session. |

---

## What Dhuhr settles
- **Sunnah-after placement:** boundary du'ā `C-3` after the **farḍ**; full dhikr + closing
  after the **last unit** (the sunnah-after). General rule — inherited by **Asr** (no
  sunnah-after → seals after farḍ, like Fajr), **Maghrib** & **Isha** (sunnah-after → seal
  after it). Isha additionally tails into Witr — handled in `isha.md`.
- **Build implication:** `C-3` is a **new emission point** — it must fire after the *farḍ*
  unit, whereas today `P-23` is emitted only on the *last* unit. The container splits the
  current single closing into (boundary-after-farḍ) + (seal-at-end).
