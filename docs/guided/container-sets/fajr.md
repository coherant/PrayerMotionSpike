# Fajr Container Set

**Status: SPEC (not yet built).** The congregational frame the Muezzin voices *around* the
Fajr observance — the worked reference the other four map against (as `observances.md §5`
anchored the surahs). See `../CONGREGATIONAL-CONTAINER.md` for the model.

- **Inner observance** (the units the worshipper prays, silently): `../prayer-sets/fajr.md`
  + `../observances.md`. **Nothing in this doc touches those** — the container is a wrapper.
- **Call content** (`C-id` text + meaning): `../CONGREGATIONAL-CONTAINER.md` §A — *Container
  Call Library*.
- **Voice:** every row here is the **Muezzin**. He never voices in-salah recitation; a
  `P-id` only appears below where it is, fiqh-wise, a *post-salah* act (the boundary du'ā).

Three voices run a session — 🟢 **Muezzin** (this doc) · 🔵 **worshipper** (silent,
motion-gated; `prayer-sets/fajr.md`) · ⚪ **guidance** (TTS, user's language). Fajr is
**Sunnah (2) → Farḍ (2)**, no sunnah-after, no Witr, and (Ḥanafī) **no Qunūt**.

## Mode key (container layer)
| Mode | Meaning |
|---|---|
| `listen` | Auto-paced — advances when the Muezzin's recitation completes (recording length, or TTS utterance). No motion trigger, no rakat. |
| `count` | A repeated dhikr — advances at the stated count via the **tasbīḥ counter**. |

Container rows are **not** subject to Silent Mode — the Muezzin is *meant* to be heard. Only
the inner units (the worshipper's salah) go silent/display-only.

---

## Timeline

| # | Voice | Phase | id |
|---|---|---|---|
| 0 | 🟢 | **Ezan / Adhān** *(optional; prayer-time-tied)* | `C-1F` |
| 1 | ⚪ | Guidance: "Pray two rakʿah — the Sunnah of Fajr." | — |
| 2 | 🔵 | **Sunnah unit** (2 rakʿah, silent) → `prayer-sets/fajr.md` | — |
| 3 | 🟢 | **Iqāma** — *opens the container proper* | `C-2` |
| 4 | ⚪ | Guidance: "Pray two rakʿah — the Farḍ of Fajr." | — |
| 5 | 🔵 | **Farḍ unit** (2 rakʿah, silent) → `prayer-sets/fajr.md` | — |
| 6 | 🟢 | **Boundary du'ā** (post-salām) | `C-3` (= `P-23`) |
| 7 | 🟢 | **Post-farḍ dhikr** | `C-4 … C-10` |
| 8 | 🟢 | **Closing du'ā** | `C-11` |

The rhythm: **call → (you pray sunnah) → commence → (you pray farḍ) → he seals it.**

---

## C_ADHAN — Ezan (Fajr)
Mode: `listen` · Voice: Muezzin · **optional / ties to prayer-times**

| role | utterance | note |
|---|---|---|
| call | `C-1F` | The Fajr call — includes *Aṣ-ṣalātu khayrun mina-n-nawm* (the line no other adhān carries). Plays as a ceremonial opening, or is skipped when the real adhān has already sounded. |

> → **Sunnah unit** — the worshipper now prays 2 rakʿah individually (as in congregation,
> the sunnah-before precedes the Iqāma). Voiced by no one. See `prayer-sets/fajr.md`.

---

## C_IQAMA — Iqāma
Mode: `listen` · Voice: Muezzin

| role | utterance | note |
|---|---|---|
| call | `C-2` | *Qad qāmati-ṣ-ṣalāh.* The container's true open — it stands **between** the sunnah and the farḍ, because the iqāma commences the *farḍ*. |

> → **Farḍ unit** — the worshipper prays 2 rakʿah, silent and motion-gated. See
> `prayer-sets/fajr.md`. Its final `tasleem-left` carries `P-23` as `exit` today; in the
> container that act is **handed to the Muezzin** as the boundary du'ā below (one source,
> re-voiced — not duplicated).

---

## C_BOUNDARY — post-salām du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| boundary | `C-3` (= `P-23`) | *Allāhumma anta-s-salām…* — O God, You are Peace and from You comes peace; blessed are You, Owner of Majesty and Honour. |

After the **farḍ only** — not after the sunnah. (The sunnah ends quietly into the Iqāma.)

---

## C_DHIKR — post-farḍ remembrance
Voice: Muezzin (leads; the worshipper follows on the tasbīḥ counter where marked)

| role | utterance | mode | meaning |
|---|---|---|---|
| dhikr | `C-4` | `count` ×3 | *Astaghfirullāh* — I seek God's forgiveness |
| dhikr | `C-5` | `listen` | **Āyat al-Kursī** (Qur'an 2:255) — *the best gem* (al-Ghazālī); the hadith: nothing stands between its reciter and Paradise but death |
| dhikr | `C-6` | `count` ×33 | *Subḥānallāh* — Glory be to God |
| dhikr | `C-7` | `count` ×33 | *Alḥamdulillāh* — All praise to God |
| dhikr | `C-8` | `count` ×33 | *Allāhu akbar* — God is the Greatest |
| dhikr | `C-9` | `listen` ×1 | *Lā ilāha illā-llāhu waḥdah…* — the tahlīl that **completes 100** |
| dhikr | `C-10` | `listen` | **Ṣalawāt** — *Allāhumma ṣalli ʿalā Muḥammad…* — blessings upon the Prophet ﷺ |

Order locked: **istighfār → Āyat al-Kursī → 33 · 33 · 33 → tahlīl → ṣalawāt.** Count formula
locked: **33 / 33 / 33 + 1 tahlīl = 100** (Muslim). Not a madhab axis — see
`../CONGREGATIONAL-CONTAINER.md` §B.

---

## C_CLOSING — closing du'ā
Mode: `listen` · Voice: Muezzin

| role | utterance | meaning |
|---|---|---|
| closing | `C-11` | Hands raised — istighfār and supplication, sealing the session asking God's forgiveness and acceptance. End of container. |

---

## What Fajr settles (carried up to the spec's open questions)
- **Iqāma scope:** the Iqāma sits **between sunnah and farḍ** (sunnah-before is outside the
  container open). Ezan is a pre-roll.
- **Boundary du'ā + dhikr placement:** **after the farḍ only.** The sunnah ends into the
  Iqāma with no `P-23` and no tasbīḥāt.
- **Āyat al-Kursī:** **included**, before the tasbīḥāt.
- **Count formula:** **33 / 33 / 33 + tahlīl**.
