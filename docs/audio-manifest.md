# Audio Manifest

Phrase keys used across the prayer state machine. Each row is a phrase key; columns
are reciters (Arabic audio) or English narration files. Run `node scripts/generate-manifests.js`
to regenerate `Resources/Audio/Reciters/*/manifest.json` and `Resources/Audio/Narration/en/manifest.json`.

---

## Reciters

| phrase_key         | alafasy             |
|--------------------|---------------------|
| takbir             | takbir.mp3          |
| fatiha             | fatiha.mp3          |
| ruku_dhikr         | ruku.mp3            |
| sujood_dhikr_1     | sujood_1.mp3        |
| sujood_dhikr_2     | sujood_2.mp3        |
| tashahhud          | tashahhud.mp3       |
| tasleem_right      | tasleem_right.mp3   |
| tasleem_left       | tasleem_left.mp3    |

---

## English Narration

| phrase_key         | file                        |
|--------------------|-----------------------------|
| takbir             | takbir.mp3                  |
| fatiha             | fatiha.mp3                  |
| ruku_dhikr         | ruku.mp3                    |
| sujood_dhikr_1     | sujood_1.mp3                |
| sujood_dhikr_2     | sujood_2.mp3                |
| tashahhud          | tashahhud.mp3               |
| tasleem_right      | tasleem_right.mp3           |
| tasleem_left       | tasleem_left.mp3            |
