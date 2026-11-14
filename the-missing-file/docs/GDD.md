# The Missing File — Game Design Document

**Version:** 1.0 (matches game build 1.0.0)
**Platform:** Android (phones first) · **Engine:** Godot 4.x · **Language:** GDScript
**In-game languages:** English, Turkish

> Spoiler warning: section 5 contains the full solution of Case 1.

---

## 1. Vision

*The Missing File* is a 2D touch-driven detective game about observation and deduction.
The player never wins by guessing: every conclusion must be backed by evidence they found,
linked and presented themselves.

**Design pillars**

1. **Fair mystery** — every fact needed to solve the case is discoverable; no clue is random; red herrings are all explained by the end.
2. **Thinking over tapping** — finding objects is the easy part; the game is in linking evidence and catching lies.
3. **One-thumb clarity** — large touch targets, readable text, short sessions, save anywhere.
4. **Noir mood** — rain, lamp light, paper, ink.

**Session shape:** Case 1 is 45–75 minutes on a first play, split naturally into 5–10 minute chunks.

---

## 2. Universe and Overarching Mystery

**Setting:** Karaliman, a fictional rain-soaked Turkish port city. Present day, but the city runs on old paper.

**Player character:** Detective **Mira Kaya**, newly transferred to the Karaliman Major Crimes desk. (The name reads naturally in both Turkish and English.)

**Recurring contact:** Dr. **İdris Nur**, coroner — delivers lab results by phone message.

**The overarching mystery — "The Lighthouse Ledger":**
Across the city, specific official files have been quietly disappearing for years: fire reports, zoning rulings, an inquest. Each one, taken alone, looks like sloppy filing. Together they describe one hidden arrangement between city officials and an unnamed "client". Each case in the game revolves around one missing file. Case 1 hands the player the first thread: a routing slip listing six more file numbers, and one torn-out page.

---

## 3. Core Gameplay Loop

```
Explore scene → find evidence → examine it → interview people
      ↑                                             ↓
  new areas / new questions  ←  link evidence on the Board (insights)
                                                    ↓
                               present evidence to break a lie
                                                    ↓
                                  accuse → verdict → evaluation
```

### 3.1 Investigation (scenes)
- Each location is a wide illustrated scene; drag to pan, tap hotspots to inspect.
- Hotspot types: **evidence** (goes to the case file), **detail** (flavour/observation), **container** (opens a close-up sub-view: desk drawer, computer screen, logbook), **exit**.
- Some hotspots are **gated**: they appear only after an insight or testimony (e.g. shelf 74-B).
- A per-scene counter shows "evidence found 3/5" so the player is never pixel-hunting blind.
- **Hint system:** optional. In a scene, Hint points at evidence that can be picked up now; otherwise it explains how to unlock gated evidence, sends the player to the Board when cards can be connected, names the conversation they have not finished, or states the current objective. On the Board, Hint selects two cards that belong together (the player still has to choose what they mean). Hints lower the final rating slightly and never block progress.

### 3.2 Evidence and examination
- Each evidence item has: name, picture, short description, detailed examination text, source location, and tags (time, person, place).
- Documents open in a zoomable reader; key lines can be highlighted.

### 3.3 Evidence Board
- Corkboard with evidence cards, testimony cards and suspect cards.
- The player **selects two cards and taps Connect** (more reliable on a phone than dragging a thread), then picks what the link means when the pair is valid.
- A valid link creates an **Insight** card (a new fact) which can unlock hotspots, dialogue topics or accusation options.
- Invalid links give a neutral "no clear connection" response; repeated wrong links slightly lower the rating. No brute-force benefit: insights also require the right prerequisite evidence.

### 3.4 Dialogue and interrogation
- Topic-based conversations with branching replies; new topics unlock from evidence and insights.
- Each character has a **temperament** that reacts to the player's approach (Empathetic / Firm / Direct):
  the wrong approach closes off optional information, never essential information.
- **Present evidence:** on any statement the player can present an item. The right item exposes a contradiction and opens a new branch; the wrong one costs composure with that character (and rating).
- All statements are recorded as testimony cards.

### 3.5 Case management (the Case File)
Tabs: **Objectives · Evidence · Suspects · Timeline · Board**.
The timeline fills itself as time-tagged evidence is found, with conflicts marked in red.

### 3.6 Accusation and verdict
- Available at any time from the Case File (so a premature accusation is a real, bad choice).
- Three steps: **Who** → **Proof** (fill three slots: Motive, Opportunity, Physical link; only conclusions reached on the Board can be used as proof) → **Confirm**.
- Outcome depends on the suspect chosen, the strength of the proof, and earlier decisions.
- End-of-case evaluation: rating (S/A/B/C) from evidence found, insights made, contradictions exposed, mistakes and hints.

---

## 4. Screens and UI Structure

Orientation: **landscape**, base resolution 1920×1080, scaled with aspect "expand" so 16:9 through 21:9 phones and tablets all fill the screen; UI anchors respect display cut-outs (safe area).

```
Boot → Language select (first run only) → Main Menu
Main Menu: Continue · New Game · Cases · Settings · Credits
Game: Scene view
        ├─ top bar: location name, objectives button, pause
        ├─ bottom bar: Case File · Board · Map (travel) · Hint
        ├─ Close-up view (containers, documents)
        ├─ Dialogue view (portrait, text, choices, "Present" button)
        ├─ Case File (tabs)
        ├─ Evidence Board
        └─ Accusation flow → Ending → Evaluation
Settings: language, music/SFX volume, text size, text speed, vibration, reset save
```

UI rules: minimum touch target 96 px at base resolution; body text never under 28 px at base resolution; three text sizes; no gesture is required that has no button alternative.

---

## 5. Case 1 — "File 47-B" (full design, spoilers)

### 5.1 Premise
Ekrem Vural, senior archivist of the Karaliman Municipal Archive, is found dead at the foot of the spiral staircase in basement stack B2. It looks like a night-time fall. But the file he was working on — **47-B, the 1998 Pier 9 (9. İskele) warehouse fire inquiry** — is gone from its box.

### 5.2 The truth
In 1998, a young records clerk, **Selin Maden**, was paid by Aras Shipping to retype one witness statement in the fire inquiry, turning an insurance arson into an accident. She kept the secret, married, and rose to become **Dr. Selin Vardar, Director of the Archive**.

Digitising old files, Vural noticed that page 12 of 47-B was typed on a different machine and carried the clerk initials **S.M.** He worked out who that was. At 20:03 on Thursday he emailed Vardar: he would go to the prosecutor in the morning. Expecting trouble, he re-shelved the real file under a mirrored number, **74-B**, and left himself a note.

Vardar drove back (car park barrier: in 20:52), found him on the B1 landing at the top of the spiral staircase and pleaded with him. He refused. She grabbed his arms; he went backwards down the stairs (watch stopped 21:17). She lost a jade earring in the struggle; it fell through the open steel treads to the B2 floor. She rode the freight elevator up with her master key, forced his desk drawers looking for the file, found nothing, and left (barrier: out 21:34). Next morning she plays the grieving, helpful colleague — and badly wants to know whether the detective finds the file first.

### 5.3 Characters

| Character | Role | Temperament | What they hide | Truth |
|---|---|---|---|---|
| **Dr. Selin Vardar** (58) | Archive director | Composed, precise; yields only to hard evidence | Came back that night; is "S.M." | **Culprit** |
| **Demir Aras** (47) | Deputy mayor, heir of Aras Shipping | Charming, lawyered-up; reacts to Direct | Tried to buy the file that evening | Motive, but solid alibi; implicated in the 1998 bribe |
| **Leyla Aydın** (26) | Junior archivist, found the body | Anxious; opens up to Empathetic | Stayed late secretly copying zoning files for a journalist | Key ear-witness |
| **Veysel Erdem** (54) | Night guard | Gruff; respects Firm | Left his post for the betting shop and faked the patrol log | His absence gave the killer a free run |

### 5.4 True timeline (Thursday)

| Time | Event | Evidence |
|---|---|---|
| 18:32 | Vardar badges out | E02 |
| 18:40–19:05 | Aras visits Vural; argument | E01, E10 |
| 19:30 | Leyla *claims* she left | T-Leyla-1 |
| 20:00–23:00 | Aras at Liman Kulübü charity dinner | E15 |
| 20:03 | Vural emails Vardar | E07 |
| 20:45 | Erdem leaves for betting shop | E05 |
| 20:52 | Vardar's car enters staff car park | E06 |
| 21:00 | Patrol log: "B2 all clear" (false) | E04 |
| ~21:10 | Leyla hears Vural arguing with a woman | T-Leyla-2 |
| 21:17 | Vural falls; watch stops | E12, E16 |
| ~21:20 | Freight elevator runs | T-Leyla-2, E19 |
| 21:26 | Leyla leaves by side door | E02 |
| 21:34 | Vardar's car exits | E06 |
| 21:40 | Erdem returns | T-Erdem-2 |
| 07:10 Fri | Leyla finds the body | — |

### 5.5 Locations and evidence

**L1 Lobby & security desk**
- **E01 Visitor log** — D. Aras, in 18:40, out 19:05, "to see E. Vural".
- **E02 Keycard log** — Vardar out 18:32; Aydın out 21:26 (side door); no exit for Vural.
- **E03 Staff portrait board** — Director Vardar photographed wearing jade drop earrings.
- **E04 Patrol log** — "21:00 — B2 stacks — all clear. V.E."
- **E05 Betting slip** — Şanslı Çapa, across the street, stamped 21:07 (bin under Erdem's desk).
- **E06 Car park barrier log** — plate 82 KL 4471 (S. Vardar) in 20:52, out 21:34. *Gated: Erdem unlocks the terminal after his lie is exposed.*
- **E15 Morning newspaper** — photo of Aras speaking at the Liman Kulübü dinner, wall clock reading 21:05.

**L2 Vural's office**
- **E07 Sent email, 20:03** — to S. Vardar: "I know what was done to 47-B, and by whom. I go to the prosecutor tomorrow. I wanted you to hear it from me first."
- **E08 Digitisation notes** — "47-B p.12: retyped, different machine. Clerk initials S.M. Who was S.M. in '98?"
- **E09 Desk calendar note** — "If anything happens — the mirror tells the truth."
- **E10 Letter from Aras** — "Name your price for 47-B. Some history is better left in the box."
- **E11 Forced drawers** — locks levered with a letter opener; contents rifled.

**L3 Stack B2**
- **E12 Personal effects** — watch, glass cracked, stopped at 21:17; his full key ring still on his belt.
- **E13 Jade earring** — under the lowest shelf beside the foot of the staircase, dust-free, hook bent open.
- **E14 Box 47-B** — empty; checkout slip "E. Vural, Monday".
- **E17 The real file** — shelved at 74-B. Original and retyped page 12 side by side; a routing slip listing six other file numbers; one page torn out long ago. *Gated by insight D9.*

**L4 Director's office**
- **E18 Framed diploma, 1996** — awarded to "Selin Maden".
- **E19 Master key register** — two after-hours master keys exist: No.1 Vural, No.2 Vardar. The freight elevator runs after 19:00 only with a master key.

**Phone**
- **E16 Coroner's preliminary note** — death between 21:00 and 21:30; grip bruising on both forearms, inconsistent with a simple fall.

### 5.6 Insights (valid Board links)

On the Board the player picks two cards and taps **Connect**. A valid pair then asks *what the two mean together*, with one right conclusion and two plausible wrong ones, so connections cannot be brute-forced. Cards are evidence (E), recorded statements (T) or earlier conclusions (I).

**Implemented (lobby, Milestone 3)**

| ID | Link | Conclusion | Used for |
|---|---|---|---|
| I_UNGUARDED | E02 + T-Erdem-2 | Door log matches the confession: nobody watched the building 20:44–21:41 | Timeline; context for everything after |
| I_VARDAR_RETURNED | E02 + E06 | Vardar badged out 18:32 but her car was back 20:52–21:34 | Opportunity slot for Vardar |
| I_ARAS_ELSEWHERE | E01 + E15 | Aras signed out 19:05 and was on stage at 21:05 | Clears Aras |
| I_AYDIN_STAYED | E02 + T-Erdem-4 | Leyla did not go home at 19:30; she left at 21:26 | Confront Leyla (M4) |
| I_SIDE_DOOR | E02 + T-Erdem-3 | The unlocked side door was Leyla leaving, not a break-in | Closes a red herring |

**Planned (Milestone 4, with the remaining locations)**

| ID | Link | Conclusion | Used for |
|---|---|---|---|
| D3 | E12 + E16 | Death at 21:17, and he was gripped — not an accident | Objective: "Find who was with him" |
| D4 | E11 + E12 | Vural had his keys; someone else forced the desk after he fell | Topic "the search" for all suspects |
| D5 | E08 + E18 | S.M. is Selin Maden — Director Vardar | Motive slot for Vardar |
| D6 | E07 + I_VARDAR_RETURNED | She read the email and came back because of it | Strengthens opportunity |
| D7 | T-Leyla-2 + E19 | Vural was already dead when the elevator ran; only Vardar's key could run it | Supports opportunity |
| D8 | E13 + E03 | The earring is Vardar's | Physical-link slot for Vardar |
| D9 | E09 + E14 | "Mirror" — 47-B reversed is 74-B | Hotspot: shelf 74-B → E17 |

Every evidence item is used in at least one conclusion or contradiction. The solution has three independent legs (motive, opportunity, physical link), so missing one optional testimony never makes the case unsolvable.

### 5.7 Key decisions

1. **Vardar's question.** Early on, Vardar asks whether Ekrem left any notes. If the player shares the calendar note (E09) before recovering E17, Vardar reaches shelf 74-B first: the file is later found with the comparison pages removed.
2. **How to treat Leyla.** Empathetic → full testimony including the woman's voice. Pressure → she only admits staying late; the elevator detail must then come from confronting her with E02 later.
3. **Erdem's report.** After his confession the player may put his absence on record or let it go; changes his epilogue line and a later-case attitude flag.
4. **When to accuse.**

### 5.8 Endings

| # | Condition | Result |
|---|---|---|
| A — **The Mirror Tells the Truth** | Vardar accused, all three proof slots correct, file intact | Full confession. Aras faces the 1998 bribery charge. Routing slip opens the larger mystery. |
| B — **Reasonable Doubt** | Vardar accused, but weak proof or file compromised (decision 1) | Vardar admits only "an argument"; lesser charge; the 1998 link is unprovable. |
| C — **The Obvious Man** | Aras accused | Released in 48 hours on his alibi; Vardar quietly destroys the file; Mira reprimanded. |
| D — **The Easy Answer** | Leyla or Erdem accused | A scapegoat is charged; the real killer keeps her office. |
| E — **Misadventure** | Player closes the case as an accident | File never found. The bleakest epilogue. |

After any ending except A the player may replay from the last checkpoint before the accusation.

---

## 6. Visual and Audio Direction

**Style: "Ink & Lamplight".** Flat, layered vector illustration with strong silhouettes, lit in-engine.

- **Palette:** midnight navy `#0E1420`, charcoal `#1B2230`, paper cream `#E8DFC8`, lamp amber `#E3A446`, evidence red `#B8413A` (threads, alerts), jade `#4FA58A` (confirmed insights).
- **Scenes:** 3–4 parallax layers, Godot 2D lights for desk lamps and window light, rain on glass, dust motes, subtle film grain and vignette.
- **Characters:** stylised half-length portraits. Version 1.0 has one expression per character; alternative expressions (defensive, shaken) are a possible later addition.
- **UI:** case-file metaphor — manila folders, typed labels, stamps, pins and red thread.
- **Typography (open licence, full Turkish glyph coverage):** a typewriter face for documents, a clean sans for UI and dialogue, a serif for titles. Exact fonts are confirmed in Milestone 2 after checking ç ğ ı İ ö ş ü rendering.
- **Animation:** card flips, stamp thumps, thread drawing, lamp flicker, portrait cross-fades. Nothing longer than 0.4 s on core actions.
- **Audio:** rain and room-tone loops, one sparse noir music theme with a tension variant, paper/pin/stamp/pen UI sounds, a short "insight" sting. Sources are original/generated or CC0, each recorded in `CREDITS.md`.

**Honest note on art production:** all art will be authored as original vector assets inside this project. That guarantees a consistent, legally clean look, but it is stylised — not painted realism. The asset pipeline is file-swappable, so commissioned or owner-supplied art can replace any piece later without code changes.

---

## 7. Technical Architecture

### 7.1 Principles
- **Data-driven:** a case is a folder of JSON. Adding Case 2 needs no new code.
- **No player-facing text in scripts or scenes:** everything is a key resolved through Godot's `TranslationServer`.
- **Systems talk through signals** on a small set of autoload singletons.
- **Offline, no accounts, no network permission** in the Android manifest.

### 7.2 Folder structure

```
the-missing-file/
├── project.godot
├── export_presets.cfg
├── docs/                     GDD, checklist, build & install guides
├── autoload/
│   ├── loc.gd                loads the string tables into TranslationServer
│   ├── game_state.gd         flags, found evidence, insights, decisions
│   ├── case_db.gd            loads and validates case JSON
│   ├── save_manager.gd       versioned saves in user://
│   ├── settings.gd           language, audio, text size
│   ├── audio_manager.gd
│   └── scene_router.gd       transitions between screens
├── systems/
│   ├── investigation/        hotspot.gd, scene_view.gd, closeup_view.gd
│   ├── dialogue/             dialogue_runner.gd, dialogue_view.gd
│   ├── board/                board.gd, card.gd, thread.gd
│   ├── casefile/             tabs: objectives, evidence, suspects, timeline
│   └── verdict/              accusation.gd, ending.gd, evaluation.gd
├── ui/
│   ├── theme/                theme.tres, fonts/
│   ├── menus/                boot, language_select, main_menu, settings, credits
│   └── components/           buttons, panels, toasts, document reader
├── data/
│   └── cases/case_01/
│       ├── case.json         meta, intro, testimony
│       ├── locations.json    scenes and their hotspots
│       ├── characters.json   names, portraits, dialogue files
│       ├── evidence.json
│       ├── suspects.json     (M3) suspect profiles
│       ├── insights.json     valid links and what they unlock
│       ├── timeline.json
│       ├── endings.json
│       └── dialogue/         vardar.json, aras.json, aydin.json, erdem.json
├── localization/
│   ├── ui.json               {"KEY": {"en": "...", "tr": "..."}}
│   └── case_01.json
├── assets/
│   ├── scenes/ portraits/ evidence/ ui/ audio/
└── tests/                    data validation + automated playthrough
```

### 7.3 Key technical decisions
- **Localization:** JSON string tables (`{"KEY": {"en": "…", "tr": "…"}}`) loaded into Godot's `TranslationServer` at startup, so the standard `tr()` and automatic UI translation work everywhere. One file per case plus one for UI. A test fails the build if any key is missing in either language or any referenced key does not exist.
- **Dialogue format:** JSON nodes `{id, speaker, text_key, choices[], conditions[], effects[]}`. Conditions and effects use the same small vocabulary as insights and hotspots (`has_evidence`, `has_insight`, `flag`, `add_evidence`, `set_flag`, `unlock_topic`).
- **Save/load:** single auto-save slot per case plus settings, JSON in `user://`, with a save-format version number and migration hook. Auto-saves after every state change; resumes exactly where the player left off.
- **Rendering:** Compatibility renderer (OpenGL ES 3) for the widest Android device support; textures imported from SVG at fixed sizes; one scene loaded at a time.
- **Android:** min SDK 24 (Android 7.0), arm64-v8a + armeabi-v7a, landscape, immersive mode, no permissions requested.
- **Testing:** a headless validation script (all JSON references resolve, every evidence item is reachable, every ending is reachable) and a scripted playthrough of the critical path, run before every build.

---

## 8. Roadmap

Each milestone ends with something the owner can look at and approve.

| # | Milestone | Deliverable | Owner checks |
|---|---|---|---|
| 1 | **Design** | This document | Story, style, architecture |
| 2 | **Prototype + build pipeline** | Menu, language select, Lobby scene, evidence pickup, one Erdem conversation — **and a first debug APK** to prove the Android toolchain early | Install APK, feel of touch controls |
| 3 | **Core systems** | Case File, Evidence Board with insights, present-evidence interrogation, accusation flow, save/load | Board usability |
| 4 | **Case 1 content** | All 4 locations, 19 evidence items, 4 full interviews, 5 endings | Play the case end to end |
| 5 | **Localization & polish** | Complete EN + TR text, final art pass, animation, audio | Read the Turkish text as a native speaker |
| 6 | **Testing** | Automated checks, resolution matrix, save/load and language-switch tests, bug fixes | Bug list from play on a real phone |
| 7 | **Release** | Tested debug APK, signed release build guide, install and rebuild instructions | Final sign-off |

**Known risks, stated plainly**
- **APK build environment.** Building needs the Godot editor binary, Android export templates and the Android SDK. Milestone 2 tests this immediately. If the build cannot run in the development environment, the fallback is an automated GitHub Actions build that produces the APK on every push.
- **Device testing.** Automated tests and desktop runs cover logic and layouts; a real Android phone can only be tested by the owner. The APK is called "tested on device" only after the owner confirms it.
- **Turkish text quality.** Translations are written natively in Turkish (not machine-converted from English), but the owner's read-through in Milestone 5 is the final check.

---

## 9. Development Checklist

- [x] Development language chosen: English
- [x] M1 GDD drafted
- [x] M1 GDD approved by owner (Turkish names requested and applied)
- [x] M2 Prototype built: menu, language select, settings, lobby scene, 7 evidence items, Erdem interview with present-evidence, case file list, auto-save
- [x] M2 Automated tests passing; debug APK built and signature verified
- [x] M2 Debug APK installed and runs on the owner's phone (v0.2.0)
- [x] M2 Feedback fix (v0.2.1): Hint button, look-around tip, locked-terminal explanation
- [x] M3 Core systems (v0.3.0): evidence board with conclusions, case file tabs (objectives, evidence, suspects, timeline), accusation with proof slots, five verdicts, rating, travel between locations (code ready, one location so far)
- [x] M3 checked on the owner's phone ("goes well"); Board hint requested and added
- [x] M4 Case 1 content: 4 locations, 19 evidence items (plus the damaged-file variant), 4 interviews, 12 conclusions, 5 verdicts, 3 decisions with consequences
- [x] M5 Localization and polish: all text in English and Turkish, original sound effects, room ambience and music, volume settings, credits, Android back button
- [x] M6 Testing: 2,580 automated checks including a full playthrough to the true ending and the alternative branches; smoke test of the real game flow; screens checked at 16:9, 20:9, 22:9 and 4:3 in both languages
- [x] M7 Debug APK built and signature verified (v1.0.1: Board card titles wrap instead of being cut off); build, install and release-signing guides written
- [x] v1.0.1 played on the owner's phone; feedback: scrolling was hard, proof picker showed cards that can never be proof, no how-to-play guide
- [x] v1.0.2: lists scroll by dragging anywhere (buttons and panels no longer swallow the touch), thicker scroll bars, accusation offers Board conclusions only, How to Play screen (first game, main menu, pause menu)
- [ ] v1.0.2 checked on the owner's phone
- [ ] Release build signed with the owner's own key (owner action, see docs/BUILD.md)

## 10. Decisions Awaiting Owner Approval

1. Case 1 story and culprit as designed in section 5.
2. Setting: fictional Turkish port city Karaliman, detective Mira Kaya, all-Turkish cast (owner request).
3. Visual style "Ink & Lamplight" (stylised vector, in-engine lighting).
4. Landscape orientation.
5. Game project lives in the `the-missing-file/` subfolder, leaving the existing website files in the repository untouched.
