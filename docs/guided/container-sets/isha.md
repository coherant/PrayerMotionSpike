# Isha Container Set

**Status: SPEC (not yet built).** The Muezzin's frame around the Isha observance. Fifth and
last container-set; the only one that tails into **Witr**. Model:
`../CONGREGATIONAL-CONTAINER.md`.

- **Inner observance:** `../prayer-sets/isha.md` + `../observances.md`. Untouched here.
- **Call content:** `../CONGREGATIONAL-CONTAINER.md` §A — *Container Call Library*.
- **Voice:** every row is the **Muezzin**; he never voices in-salah recitation — Witr's
  Qunūt **included**.

> **⚠️ Composition correction (code gap).** Full Ḥanafī/Turkish Isha (Yatsı) is **13 rakʿah:
> Sunnah-before (4, ghayr muʾakkadah) → Farḍ (4) → Sunnah-after (2) → Witr (3, wājib).** The
> canonical table currently **omits the 4-rakʿah sunnah-before** (`SalatType.units` case
> `.isha`; `observances.md` line 25 + §5; `prayer-sets/isha.md`) — modelling only 9 rakʿah.
> This is a pre-existing bug, not a container concern (Asr's ghayr-muʾakkad sunnah-before
> *is* modelled, so the table already admits the kind). **This doc maps the corrected
> 4→4→2→3.** Code fix tracked as a build to-do — see *What Isha settles*.

## Where the seal falls — **after the Witr**
The post-prayer dhikr + closing (`C-4…C-11`) **seal after the Witr** — the Witr is the
**last unit**, so Isha obeys the *same* general rule as every other prayer ("seal after the
last unit"), no special case. The boundary du'ā `C-3` still fires after the **farḍ**. The
Muezzin stays **silent through the Witr** (he voices no in-salah recitation, and Witr's
Qunūt is exactly that), then seals once it's complete.

Isha is **Sunnah-before (4, optional) → Farḍ (4) → Sunnah-after (2) → Witr (3)** — Qunūt
**only** in Witr rakʿah 3 (Ḥanafī).

Three voices — 🟢 **Muezzin** (this doc) · 🔵 **worshipper** (silent; `prayer-sets/isha.md`
+ `witr.md`) · ⚪ **guidance** (TTS).

---

## Timeline

| # | Voice | Phase | id |
|---|---|---|---|
| 0 | 🟢 | **Ezan / Adhān** *(optional; prayer-time-tied)* | `C-1` |
| 1 | ⚪ | Guidance: "Pray four rakʿah — the Sunnah of Isha." *(omitted if untoggled)* | — |
| 2 | 🔵 | **Sunnah-before unit** (4 rakʿah, silent) *(optional, ghayr muʾakkadah)* | — |
| 3 | 🟢 | **Iqāma** — opens the container | `C-2` |
| 4 | ⚪ | Guidance: "Pray four rakʿah — the Farḍ of Isha." | — |
| 5 | 🔵 | **Farḍ unit** (4 rakʿah, silent) | — |
| 6 | 🟢 | **Boundary du'ā** (exits the farḍ) | `C-3` (= `P-23`) |
| 7 | ⚪ | Guidance: "Pray two rakʿah — the Sunnah of Isha." | — |
| 8 | 🔵 | **Sunnah-after unit** (2 rakʿah, silent) | — |
| 9 | ⚪ | Guidance: "Pray three rakʿah — Witr." | — |
| 10 | 🔵 | **Witr unit** (3 rakʿah, silent — **Qunūt** in rakʿah 3; Muezzin silent throughout) | — |
| 11 | 🟢 | **Post-prayer dhikr** (seals the observance — *after* the Witr) | `C-4 … C-10` |
| 12 | 🟢 | **Closing du'ā** | `C-11` |

Rhythm: **call → (sunnah) → commence → (farḍ) → he marks the exit → (sunnah-after) → (Witr)
→ he seals it.** The Muezzin's longest silence is across the Witr — then he closes the night.

---

## C_ADHAN — Ezan
Mode: `listen` · Voice: Muezzin · **optional / ties to prayer-times**

| role | utterance | note |
|---|---|---|
| call | `C-1` | Standard call. |

> → **Sunnah-before unit** *(optional)* — 4 rakʿah before the Iqāma. See `prayer-sets/isha.md`.

---

## C_IQAMA — Iqāma
Mode: `listen` · Voice: Muezzin

| role | utterance | note |
|---|---|---|
| call | `C-2` | *Qad qāmati-ṣ-ṣalāh.* |

> → **Farḍ unit** — 4 rakʿah, silent and motion-gated.

---

## C_BOUNDARY — post-farḍ du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| boundary | `C-3` (= `P-23`) | *Allāhumma anta-s-salām…* — right after the farḍ taslīm, before the sunnah-after. |

> → **Sunnah-after unit** (2 rakʿah) → **Witr unit** (3 rakʿah, Qunūt). Both silent; the
> Muezzin voices nothing until the Witr is complete.

---

## C_DHIKR — post-prayer remembrance (the seal — **after the Witr**)
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
| closing | `C-11` | Hands raised; seals the night. |

---

## What Isha settles
- **Witr placement — SETTLED:** the seal falls **after the Witr**. Witr is the last unit, so
  the general rule ("seal after the last unit") holds with **no special case**. Boundary du'ā
  `C-3` after the farḍ as always. The Muezzin is **silent through the Witr** — its Qunūt is
  in-salah recitation, which he never voices.
- **Composition fix (build to-do):** add `isha_sb` — `PrayerUnit(id: "isha_sb", kind:
  .sunnahBefore(emphasised: false), rakats: 4)` as the first unit in `SalatType.units` case
  `.isha`; add its row to `observances.md` (line 25 composition + §5 surah table) and rebuild
  `prayer-sets/isha.md`; regenerate the golden snapshot (Isha 65 → ~93 states). Mirror Asr's
  optional ghayr-muʾakkad sunnah-before. **Code change — not done here; tracked for the build.**
