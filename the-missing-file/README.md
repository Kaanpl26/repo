# The Missing File / Kayıp Dosya

A 2D detective mystery for Android phones, in English and Turkish, built with Godot 4.6 and GDScript.

Case 1, "File 47-B": a senior archivist is found dead at the foot of a staircase and the file he was working on has vanished. Search four locations, question four people, connect the evidence on the Board and make an accusation you can prove.

- **Play:** install the APK (see [docs/BUILD.md](docs/BUILD.md)).
- **Design:** [docs/GDD.md](docs/GDD.md) (contains the full solution).
- **Stuck while testing:** [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) (spoilers).
- **Licences:** [CREDITS.md](CREDITS.md).

## Project layout

| Folder | What it holds |
|---|---|
| `autoload/` | Game-wide singletons: settings, localization, case data, game state, saving, scene changes, audio |
| `systems/` | Investigation scene, dialogue, evidence board, case file, accusation and verdict |
| `ui/` | Menus, shared UI helpers, theme and fonts |
| `data/cases/case_01/` | The whole case as JSON: locations, evidence, dialogue, conclusions, suspects, timeline, endings |
| `localization/` | All player-facing text, English and Turkish |
| `assets/` | Rendered art and generated audio |
| `art_src/`, `tools/` | Art and audio generators, build and test scripts |
| `tests/` | Automated tests, smoke test, screenshot tool |

No player-facing text lives in scripts: every string is a key in `localization/*.json`.
