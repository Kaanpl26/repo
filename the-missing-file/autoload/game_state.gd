extends Node
## The player's progress in the current case.
## Everything that must survive a save/load lives here.

signal changed
signal evidence_added(id: String)
signal testimony_added(id: String)
signal insight_added(id: String)

var case_id := "case_01"
var location := "lobby"
var evidence: Array = []        # collected evidence ids, in order found
var testimony: Array = []       # recorded testimony ids
var insights: Array = []        # conclusions made on the board
var flags: Dictionary = {}      # story flags
var seen: Dictionary = {}       # dialogue choices already used
var mistakes := 0               # wrong evidence presentations (affects final rating later)
var hints := 0                  # hints used (affects final rating later)
var bad_links := 0              # board connections that led nowhere
var endings_seen: Array = []    # verdicts the player has reached
var active := false             # true while a game is in progress


func new_game() -> void:
	case_id = "case_01"
	location = CaseDB.meta.get("start_location", "lobby")
	evidence = []
	testimony = []
	insights = []
	bad_links = 0
	endings_seen = []
	flags = {}
	seen = {}
	mistakes = 0
	hints = 0
	active = true
	changed.emit()


func to_dict() -> Dictionary:
	return {
		"case_id": case_id, "location": location, "evidence": evidence,
		"testimony": testimony, "flags": flags, "seen": seen, "mistakes": mistakes, "hints": hints,
		"insights": insights, "bad_links": bad_links, "endings_seen": endings_seen,
	}


func from_dict(d: Dictionary) -> void:
	case_id = str(d.get("case_id", "case_01"))
	location = str(d.get("location", "lobby"))
	evidence = Array(d.get("evidence", []))
	testimony = Array(d.get("testimony", []))
	flags = Dictionary(d.get("flags", {}))
	seen = Dictionary(d.get("seen", {}))
	mistakes = int(d.get("mistakes", 0))
	hints = int(d.get("hints", 0))
	insights = Array(d.get("insights", []))
	bad_links = int(d.get("bad_links", 0))
	endings_seen = Array(d.get("endings_seen", []))
	active = true


func has_evidence(id: String) -> bool:
	return id in evidence


func add_evidence(id: String) -> void:
	if id in evidence:
		return
	evidence.append(id)
	evidence_added.emit(id)
	changed.emit()


func add_testimony(id: String) -> void:
	if id in testimony:
		return
	testimony.append(id)
	testimony_added.emit(id)
	changed.emit()


func has_insight(id: String) -> bool:
	return id in insights


func add_insight(id: String) -> void:
	if id in insights:
		return
	insights.append(id)
	insight_added.emit(id)
	changed.emit()


func add_bad_link() -> void:
	bad_links += 1
	changed.emit()


func add_ending(id: String) -> void:
	if id not in endings_seen:
		endings_seen.append(id)
		changed.emit()


## True when the player holds this card (evidence, statement or conclusion).
func has_card(id: String) -> bool:
	return id in evidence or id in testimony or id in insights


func has_flag(name: String) -> bool:
	return bool(flags.get(name, false))


func set_flag(name: String) -> void:
	if has_flag(name):
		return
	flags[name] = true
	changed.emit()


func mark_seen(id: String) -> void:
	if not seen.has(id):
		seen[id] = true
		changed.emit()


func use_hint() -> void:
	hints += 1
	changed.emit()


func add_mistake() -> void:
	mistakes += 1
	changed.emit()


## Conditions: an array of single-key dictionaries, all of which must hold.
##   {"has_evidence": "E05"}  {"no_evidence": "E06"}  {"flag": "x"}  {"not_flag": "x"}
##   {"has_insight": "I_X"}  {"no_insight": "I_X"}  {"has_testimony": "T_X"}
func check(conditions: Array) -> bool:
	for c in conditions:
		if c.has("has_evidence") and not has_evidence(c["has_evidence"]):
			return false
		if c.has("no_evidence") and has_evidence(c["no_evidence"]):
			return false
		if c.has("has_insight") and not has_insight(c["has_insight"]):
			return false
		if c.has("no_insight") and has_insight(c["no_insight"]):
			return false
		if c.has("has_testimony") and c["has_testimony"] not in testimony:
			return false
		if c.has("flag") and not has_flag(c["flag"]):
			return false
		if c.has("not_flag") and has_flag(c["not_flag"]):
			return false
	return true


## Effects: {"set_flag": "x"}  {"add_evidence": "E06"}  {"add_testimony": "T_ERDEM_1"}
func apply(effects: Array) -> void:
	for e in effects:
		if e.has("set_flag"):
			set_flag(e["set_flag"])
		if e.has("add_evidence"):
			add_evidence(e["add_evidence"])
		if e.has("add_testimony"):
			add_testimony(e["add_testimony"])
