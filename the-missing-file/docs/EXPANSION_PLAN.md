# The Missing File — Expansion Plan

**Status:** approved by the owner. Decisions: order as proposed; four cases; Case 1 interviews reworked; authentic Turkish police ranks; monetization possibly later; generated vector art continues; 32-bit phones stay supported.

**Progress**

| Phase | State |
|---|---|
| 0 Foundation | Done in 1.1.0 |
| 1 Deeper interrogation (Case 1 reworked) | Done in 1.1.0 |
| 2 Career, ranking and achievements | Done in 1.1.0 |
| 3 Police database | Done in 1.2.0 (a Database tab in the Case File; lookups are chosen, not typed) |
| 4 Case 2, "Dosya 58-D" | Done in 1.2.0, with decisions carried from Case 1 and the first appearance of the chief and of Karaca |
| 5 Detective office and Ledger board | Done in 1.3.0 |
| 6 Advanced evidence board | Next |
| 7 and 8 | Not started |
**Baseline:** game build 1.0.2 (Case 1 complete, English and Turkish, Android debug APK).

Effort sizes used below, measured against work already done on this project:

| Size | Comparable to |
|---|---|
| **S** | The v1.0.2 update (scrolling fix, proof rule, How to Play) |
| **M** | Milestone 3 (board, case file tabs, accusation flow) |
| **L** | Milestones 4 to 7 together (three rooms, three interviews, all of Case 1's content) |

---

## 1. What the inspection found

The current project is about 3,000 lines of GDScript and is already data-driven. A case is a folder of JSON plus one text table. That is the main reason most of this expansion is cheaper than it sounds.

**Reusable as-is**

| Existing piece | Reused by |
|---|---|
| Condition and effect vocabulary (`GameState.check`, `GameState.apply`) | Achievements, database unlocks, branching, office props |
| `Deduction` (pair of cards, three candidate conclusions) | Advanced board, the cross-case "Ledger" board |
| `DialogueRunner` (`present` already accepts any card, including statements) | Statement-versus-statement contradictions |
| `Verdict.rating()` (already produces a score and a grade) | Career experience points |
| Scene system in `game.gd` (hotspots from JSON, pan, tap, hints) | The detective office is just another location |
| `TouchScroll`, `CardPicker`, `NoteView`, `UI` helpers, theme | Every new list screen |
| Test suite (2,628 checks, full-case playthrough, smoke test) | Each new case gets the same scripted playthrough |

**Things that assume a single case (must change first)**

| Where | Assumption |
|---|---|
| `autoload/case_db.gd:20` | Always loads `case_01` at start-up |
| `autoload/loc.gd:7` | Text tables are a fixed list: `ui`, `case_01` |
| `autoload/game_state.gd` | `new_game()` hard-codes `case_01` |
| `autoload/save_manager.gd` | One save file for the only case; nothing persists across cases |
| `ui/menus/main_menu.gd` | Continue / New Game with no case choice |

**Size budget**

| Item | Size in the APK |
|---|---|
| Godot engine, two phone architectures | about 53 MB of the 81 MB |
| One room background | about 2.8 MB |
| All text, data and code | under 1 MB |
| All audio | about 4 MB |

Each new case with four rooms adds roughly 12 MB at the current texture settings. Text and logic are free by comparison.

---

## 2. Priority order

Ranked by player engagement against development effort.

| Order | Work | Features covered | Engagement | Effort |
|---|---|---|---|---|
| 0 | **Foundation:** multi-case support, player profile, save format v2, case list | prerequisite for 3, 4, 7, 8, 9 | none by itself | S |
| 1 | **Deeper interrogation** | 2 | high | S to M |
| 2 | **Career, ranking and achievements** (built together, same profile) | 4, 7 | medium now, high once there are several cases | S |
| 3 | **Police database** | 6 | medium to high, if cases use it as a puzzle tool | M |
| 4 | **Case 2**, written to use 1 to 3, carrying the first antagonist thread and the first cross-case consequences | 8, 9, 3 | highest | L |
| 5 | **Detective office** hub with the cross-case "Ledger" board | 5, 9 | medium | S to M |
| 6 | **Advanced evidence board** (free canvas, threads, zoom) | 1 | medium | M to L |
| 7 | **Cases 3 and 4**, finale | 8, 9, 3 | highest | L each |
| 8 | **Monetization** | 10 | none for players | M, plus store setup only the owner can do |

**Why this order**

- Interrogation first: it is the core fantasy, the engine already supports most of it, and Case 2 should be written for the richer system rather than retrofitted.
- Career and achievements are cheap and only pay off once there is more than one case, so they go in just before Case 2.
- The database is worth building only if cases use it for deduction, so it is built immediately before the case that introduces it.
- The advanced board is the most expensive pure-interface item and the current board works. It is deliberately late.
- Monetization is last: it is the only item that forces network access, a different build pipeline and store accounts.

---

## 3. Phase 0 — Foundation (prerequisite)

- **Experience:** the player sees a case list; finished cases show their best grade.
- **Changes:**
  - `CaseDB.load_case(id)` is called when a case is opened instead of at start-up; `Loc` loads `ui` plus the open case's table.
  - New autoload `Profile` (`user://profile.json`): cases solved, best grades, endings seen, experience, carried story flags, achievements, statistics.
  - Saves become one file per case (`user://save_<case>.json`), save format version 2 with a migration for the existing v1 save.
  - New file `data/cases/index.json`: order, title key, unlock condition for each case.
  - Two new condition kinds, `profile_flag` and `case_solved`, added to the existing vocabulary.
- **Preserved:** Case 1 data, all screens, all tests. An existing save keeps working.
- **Effort:** S.
- **Android:** none new. Migration is tested with a copy of a real v1 save.

---

## 4. Feature evaluations

### 4.1 Advanced interactive evidence board

- **Experience:** a cork wall you pan and zoom. Cards are pinned notes you can move; red thread is drawn between connected cards; conclusions sit between their sources; filter chips show evidence, statements, conclusions, or everything about one person.
- **Connects to:** `Deduction` and `Hints.next_link()` unchanged. The current list board stays as a "list view" toggle, which is also the accessible fallback on small phones.
- **Effort:** M to L. It is almost entirely touch-interface work.
- **Needs:**
  - Scripts: `systems/board/board_canvas.gd` (pan, zoom, thread drawing), `board_note.gd` (draggable card).
  - Data: `GameState.board_layout` (card id to position), saved per case. `insights.json` unchanged; optional `tags` per card for filters.
- **Godot 4:** a `Control` that transforms a child canvas; pan from drag, zoom from two-finger distance (`InputEventScreenTouch` index 0 and 1); threads with `draw_polyline` in `_draw`; notes are `PanelContainer`s. Auto-layout for new cards so nothing overlaps.
- **Android risks:** two-finger gestures fight the mouse emulation the rest of the UI relies on, so the canvas must read raw touch events only; text becomes unreadable when zoomed out, so zoom needs a floor; edge drags collide with the system back gesture, so a margin is kept; drag-versus-tap thresholds need tuning on a real phone, which cannot be done in this environment.

### 4.2 Suspect interrogation and contradiction detection

- **Experience:** interviews become a contest. You can **Press** a statement to make the suspect elaborate, **Present** a card to break it, or confront them with *another person's statement*. Each suspect has patience: careless accusations make them clam up until you bring something new. Faces change when you hit a nerve.
- **Connects to:** `DialogueRunner` and `dialogue_view.gd`. Presenting statements already works in the engine; Case 1 simply uses it once.
- **Effort:** S to M (system S; rewriting Case 1's interviews to use it is the M part and is optional).
- **Needs:**
  - Data: per-line fields `press` (node to jump to) and `mood` (neutral, defensive, shaken); per-character `patience`; a statement-review list so earlier statements can be challenged later.
  - State: `GameState.patience` per character.
  - Art: two extra expressions per portrait. The portrait generator already has a brow parameter, so this is cheap.
- **Godot 4:** a second action button beside Present; a small meter in the dialogue panel; portrait texture swapped per line.
- **Android risks:** none significant. Rule to keep: patience never causes a dead end. It refills whenever the player gains a new card, and the tests assert the case stays solvable from the lowest patience.

### 4.3 Multiple endings and branching storylines

- **Experience:** choices follow you. Sparing the guard in Case 1 means he calls you with a tip in a later case; a weak verdict means the culprit's lawyer is better prepared next time. An endings gallery shows which outcomes you have seen.
- **Connects to:** flags, `endings.json`, epilogue lines, the `alt` evidence mechanism (already used for the damaged file).
- **Effort:** system S; content cost is the real price, because every branch is written twice and tested.
- **Needs:**
  - Data: `endings.json` gains `carry` (flags copied to the profile when a case ends); cases read them through `profile_flag` conditions.
  - Screen: endings gallery (reuses the case-file list layout).
- **Design rule:** branches reconverge inside a case, and each case exports at most two or three carried flags. Without that rule the number of paths to write and test grows out of control.
- **Android risks:** none technical. Save migration must keep carried flags when a case is replayed; the rule is "best outcome wins" or "latest wins", to be decided.

### 4.4 Detective career progression and ranking

- **Experience:** each verdict awards experience from evidence found, conclusions made, mistakes and hints. Ranks advance (for example Komiser Yardımcısı, Komiser, Başkomiser, Emniyet Amiri). Replaying a case for a better grade is worthwhile.
- **Connects to:** `Verdict.rating()` already computes the score; the ending screen already shows the numbers.
- **Effort:** S.
- **Needs:** `Profile` fields `xp`, `rank`, `best` per case; `data/career.json` (rank thresholds and name keys); a progress bar on the ending screen and the rank on the menu.
- **Design rule:** ranks unlock recognition and cosmetic office items, never an advantage in solving a case. Cases unlock by solving the previous one, not by rank, so nobody is locked out of story by a low grade.
- **Android risks:** none.

### 4.5 Personal detective office

- **Experience:** between cases you are in your own room: case folders on the desk, the database terminal, a wall with the cross-case "Ledger" board, a shelf that fills with mementos from solved cases.
- **Connects to:** the investigation scene system. The office is a location whose hotspots open screens.
- **Effort:** S to M, dominated by one new room illustration and the memento art.
- **Needs:**
  - One new hotspot type `action` (open case list, database, achievements, ledger board).
  - Location `props`: small images shown when a condition holds (a jade earring in a frame after Case 1).
  - `data/hub/office.json` and one text table.
- **Godot 4:** `game.gd` learns one hotspot type and conditional prop sprites; nothing else changes.
- **Android risks:** one more large texture in memory, but only one room is loaded at a time, as now.

### 4.6 Police database and suspect profiles

- **Experience:** a terminal where you look things up: a number plate, a person, a company, a file number. Records unlock as you learn what to ask about. A good lookup can be added to the case file as a card and used on the board.
- **Connects to:** conditions (for unlocking), evidence cards (a record becomes a card), `suspects.json` (profiles gain "known links" that open records).
- **Effort:** M.
- **Needs:**
  - Data: `data/database/records.json` and per-case additions: `id`, `type`, title and field keys, unlock conditions, optional `grants` (evidence id).
  - Screen: `systems/database/database.gd`, built from the existing tab and list components.
- **Design decision:** lookups are chosen from things the player has already seen, not typed. Typing on a phone covers half the screen, and case-insensitive search is unreliable for Turkish İ/ı and I/i.
- **Android risks:** avoided by the decision above. Long lists use `TouchScroll`.

### 4.7 Achievement and reward systems

- **Experience:** recognition for style: no hints, no mistakes, every ending seen, every optional statement obtained, a suspect cornered without a wrong presentation.
- **Connects to:** conditions plus the statistics already counted (`hints`, `mistakes`, `bad_links`, `endings_seen`).
- **Effort:** S.
- **Needs:** `data/achievements.json` (`id`, text keys, rule, `hidden`); `Profile.achievements`; a check after state changes and at each verdict; the existing toast; one list screen.
- **Rewards:** office mementos and a concept-art gallery. No gameplay advantages.
- **Android risks:** none while local. Google Play Games achievements would need a plugin, network access and a Play Console setup; deferred to the monetization phase.

### 4.8 Additional investigation cases

- **Experience:** new mysteries of the same length as Case 1 (45 to 75 minutes), each built around one missing file.
- **Connects to:** everything; the content pipeline is the existing one.
- **Effort:** L per case. This is the largest item in the plan.
- **Per case:** design document with full solution, about 80 KB of text in two languages, three or four rooms, three or four portraits with expressions, 15 to 20 evidence icons, a scripted test playthrough.
- **Size control:**
  - Store room art as lossy WebP: roughly 1 MB instead of 2.8 MB per room.
  - Optionally ship only the 64-bit build: saves about 28 MB but drops phones older than roughly 2017.
  - Google Play's limit only matters past about 150 MB, which is far away.
- **Android risks:** APK growth (managed above); nothing else, since only one room is in memory.

### 4.9 Recurring antagonist and overarching mystery

- **Experience:** Case 1 ended with a routing slip listing six more file numbers and a torn page reading "Payment authorised by —". Each case recovers one file and one piece of that name.
- **Proposed structure:**
  - A **visible** recurring opponent: a lawyer who appears for every culprit, always one step ahead.
  - A **hidden** one: the person who authorised the payments, revealed in the finale.
  - A season of four cases in total rather than seven: enough for an arc, realistic to finish.
- **Connects to:** carried flags (4.3), the database (file numbers are searchable), the office (4.5).
- **Mechanic:** the "Ledger" board in the office uses the same `Deduction` system with its own `data/meta/insights.json`, linking cards carried out of each case. No new deduction code.
- **Effort:** system S; story design M.
- **Android risks:** none.
- **Needs owner approval separately:** who the hidden antagonist is, and the outline of Cases 2 to 4.

### 4.10 Optional monetization

| Model | Fit | Technical cost | Recommendation |
|---|---|---|---|
| Paid app | Good; keeps the game fully offline with no permissions | None in the game | Simplest option |
| Case 1 free, one-time unlock of the rest | Best match for a story game | Play Billing plugin, different build pipeline, test purchases | Recommended, once there are at least three cases |
| Case packs sold separately | Workable | Same as above, more store items | Possible later |
| Adverts or paid hints | Poor; breaks the mood and the fair-play promise | Advert SDK, consent screens, privacy policy | Not recommended |

- **Connects to:** case unlock conditions (one more condition kind, `owned`).
- **Effort:** M in the game, plus work only the owner can do: a Google Play developer account, a privacy policy, store listings in both languages, test purchases on a real device.
- **Godot 4:** the Google Play Billing plugin requires Godot's Gradle build (the project currently uses the simpler prebuilt template), an Android App Bundle instead of an APK for the store, and a release key held by the owner.
- **Android and build risks:**
  - The game gains the billing permission and needs network access for purchases, ending the "no permissions, fully offline" property. Purchased cases must still play offline afterwards.
  - This cloud environment cannot run the Gradle build: Google's Android SDK host is blocked here. Store builds would have to come from the owner's computer or from an automated GitHub build.
  - Purchases cannot be tested without a Play Console test track.

---

## 5. Decisions needed from the owner

1. Is the priority order in section 2 approved, or should something move?
2. Season length: four cases in total (recommended), or more?
3. Should Case 1's interviews be reworked to use the deeper interrogation system, or should only new cases use it?
4. Rank names: Turkish police ranks as proposed, or invented titles?
5. Monetization intent. If the answer is "possibly later", nothing changes now. If "never", the game can promise to stay offline and permission-free.
6. Art: continue with the generated vector style for new rooms and portraits, or will art be supplied?
7. 32-bit phones: keep supporting them (larger download) or go 64-bit only?

The antagonist's identity and the outlines of Cases 2 to 4 will come as a separate story proposal once the order is approved.
