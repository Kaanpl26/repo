extends Node
## Automated checks. Run with:
##   godot --headless --path . res://tests/run_tests.tscn
## Exits with code 0 when everything passes, 1 otherwise.

var _fails := 0
var _checks := 0


func _ready() -> void:
	_test_scripts_load()
	_test_localization()
	_test_data_references()
	_test_dialogue_graph()
	_test_playthrough()
	_test_save_roundtrip()
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("FAIL: " + msg)


# Every script and scene must load without errors.
func _test_scripts_load() -> void:
	print("- scripts and scenes load")
	for ext in [".gd", ".tscn"]:
		for path in _files("res://", ext):
			ok(load(path) != null, "cannot load " + path)


# Every key must have non-empty English and Turkish text.
func _test_localization() -> void:
	print("- localization tables")
	for table in Loc.TABLES:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Loc.DIR + table + ".json"))
		for key in data:
			for code in Settings.LOCALES:
				ok(str(data[key].get(code, "")) != "", "%s is missing '%s' text" % [key, code])
	# Every key-looking literal in the scripts must exist.
	var rx := RegEx.new()
	rx.compile("\"([A-Z][A-Z0-9]*_[A-Z0-9_]+)\"")
	for path in _files("res://", ".gd"):
		if path.begins_with("res://tests/"):
			continue
		for code_line in FileAccess.get_file_as_string(path).split("\n"):
			if code_line.strip_edges().begins_with("#"):
				continue
			for m in rx.search_all(code_line):
				var key := m.get_string(1)
				if key.ends_with("_"):
					continue   # prefix used to build a key, e.g. "LANG_NAME_"
				ok(Loc.has_key(key), "%s uses unknown text key %s" % [path, key])


func _files(dir: String, ext: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		if not sub.begins_with("."):
			out.append_array(_files(dir.path_join(sub), ext))
	for f in d.get_files():
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	return out


func _key(value: Variant, where: String) -> void:
	ok(typeof(value) == TYPE_STRING and Loc.has_key(value), "%s: unknown text key %s" % [where, str(value)])


func _test_data_references() -> void:
	print("- case data references")
	_key(CaseDB.meta["title"], "case.json title")
	for k in CaseDB.meta["intro"]:
		_key(k, "case.json intro")
	for id in CaseDB.meta["testimony"]:
		var t: Dictionary = CaseDB.meta["testimony"][id]
		_key(t["text"], "testimony " + id)
		ok(CaseDB.characters.has(t["speaker"]), "testimony %s: unknown speaker" % id)
	for id in CaseDB.evidence:
		var e: Dictionary = CaseDB.evidence[id]
		for field in ["name", "desc", "body"]:
			_key(e[field], "evidence %s.%s" % [id, field])
		ok(ResourceLoader.exists(e["icon"]), "evidence %s: icon missing" % id)
	for id in CaseDB.characters:
		var c: Dictionary = CaseDB.characters[id]
		_key(c["name"], "character " + id)
		if c.has("portrait"):
			ok(ResourceLoader.exists(c["portrait"]), "character %s: portrait missing" % id)
		if c.has("dialogue"):
			ok(CaseDB.dialogues.has(id), "character %s: dialogue failed to load" % id)
	var placed := {}
	for id in CaseDB.locations:
		var l: Dictionary = CaseDB.locations[id]
		_key(l["name"], "location " + id)
		ok(ResourceLoader.exists(l["background"]), "location %s: background missing" % id)
		for h in l["hotspots"]:
			var w := "hotspot %s.%s" % [id, h["id"]]
			var r: Array = h["rect"]
			ok(r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= l["width"] and r[1] + r[3] <= l["height"], w + " is outside the picture")
			ok(r[2] >= 70 and r[3] >= 70, w + " is too small to tap comfortably")
			_check_conditions(h.get("conditions", []), w)
			match h["type"]:
				"evidence":
					ok(CaseDB.evidence.has(h["evidence"]), w + ": unknown evidence")
					placed[h["evidence"]] = true
				"detail":
					_key(h["text"], w)
				"talk":
					ok(CaseDB.dialogues.has(h["character"]), w + ": character has no dialogue")
				_:
					ok(false, w + ": unknown type")
	for id in CaseDB.evidence:
		ok(placed.has(id), "evidence %s cannot be found anywhere" % id)


func _check_conditions(list: Array, where: String) -> void:
	for c in list:
		for k in c:
			ok(k in ["has_evidence", "no_evidence", "flag", "not_flag"], where + ": unknown condition " + k)
			if k in ["has_evidence", "no_evidence"]:
				ok(CaseDB.evidence.has(c[k]), where + ": condition uses unknown evidence")


func _check_effects(list: Array, where: String) -> void:
	for e in list:
		for k in e:
			ok(k in ["set_flag", "add_evidence", "add_testimony"], where + ": unknown effect " + k)
			if k == "add_evidence":
				ok(CaseDB.evidence.has(e[k]), where + ": effect uses unknown evidence")
			if k == "add_testimony":
				ok(CaseDB.meta["testimony"].has(e[k]), where + ": effect uses unknown testimony")


func _test_dialogue_graph() -> void:
	print("- dialogue trees")
	for ch in CaseDB.dialogues:
		var d: Dictionary = CaseDB.dialogues[ch]
		var nodes: Dictionary = d["nodes"]
		var reached := {}
		var queue: Array = []
		for s in d["start"]:
			ok(nodes.has(s["node"]), "%s: start node missing" % ch)
			_check_conditions(s.get("conditions", []), ch + " start")
			queue.append(s["node"])
		ok(not d["start"][-1].has("conditions"), "%s: last start entry must be unconditional" % ch)
		while not queue.is_empty():
			var id: String = queue.pop_back()
			if reached.has(id) or not nodes.has(id):
				continue
			reached[id] = true
			var n: Dictionary = nodes[id]
			var w := "%s.%s" % [ch, id]
			_check_effects(n.get("effects", []), w)
			ok(n.has("choices") or n.has("next") or not n.get("lines", []).is_empty(), w + " is empty")
			for l in n.get("lines", []):
				_key(l["t"], w)
				ok(CaseDB.characters.has(l["s"]), w + ": unknown speaker")
				_check_effects(l.get("effects", []), w)
				if l.has("present"):
					var p: Dictionary = l["present"]
					ok(CaseDB.evidence.has(p["accept"]), w + ": present uses unknown evidence")
					for target in [p["next"], p["wrong"]]:
						ok(nodes.has(target), w + ": present target missing: " + target)
						queue.append(target)
			if n.has("next"):
				ok(nodes.has(n["next"]), w + ": next node missing: " + n["next"])
				queue.append(n["next"])
			var ids := {}
			for c in n.get("choices", []):
				_key(c["t"], w + " choice")
				ok(not ids.has(c["id"]), w + ": duplicate choice id " + c["id"])
				ids[c["id"]] = true
				_check_conditions(c.get("conditions", []), w + " choice")
				_check_effects(c.get("effects", []), w + " choice")
				if not c.get("end", false):
					ok(nodes.has(c.get("next", "")), w + ": choice target missing")
					queue.append(c.get("next", ""))
		for id in nodes:
			ok(reached.has(id), "%s.%s can never be reached" % [ch, id])


func _advance_to_choices(r: DialogueRunner, state: String) -> String:
	var guard := 0
	while state == DialogueRunner.LINE and guard < 100:
		state = r.advance()
		guard += 1
	return state


func _pick(r: DialogueRunner, id: String) -> String:
	for c in r.choices():
		if c["id"] == id:
			return r.choose(c)
	ok(false, "choice not offered: " + id)
	return DialogueRunner.END


func _hotspot(id: String) -> Dictionary:
	for h in CaseDB.locations["lobby"]["hotspots"]:
		if h["id"] == id:
			return h
	return {}


# Plays the prototype's critical path without any UI.
func _test_playthrough() -> void:
	print("- scripted playthrough")
	GameState.active = false   # keep tests from writing a save file
	GameState.new_game()
	GameState.active = false
	ok(not GameState.check(_hotspot("terminal")["conditions"]), "terminal must start locked")

	var r := DialogueRunner.new("erdem")
	var s := _advance_to_choices(r, r.start())
	ok(s == DialogueRunner.CHOICES, "intro should end at the topic list")
	var offered := r.choices().map(func(c): return c["id"])
	ok("patrol" not in offered, "patrol topic must need the patrol log")

	for id in ["E01", "E02", "E03", "E04", "E05", "E15"]:
		GameState.add_evidence(id)
	s = _pick(r, "patrol")
	while not r.can_present() and s == DialogueRunner.LINE:
		s = r.advance()
	ok(r.can_present(), "patrol statement should be presentable")
	ok(not r.present("E01"), "wrong evidence must be rejected")
	ok(GameState.mistakes == 1, "wrong presentation counts as a mistake")
	ok(not GameState.has_flag("erdem_confessed"), "no confession after wrong evidence")
	s = _advance_to_choices(r, DialogueRunner.LINE)

	s = _pick(r, "patrol")
	while not r.can_present() and s == DialogueRunner.LINE:
		s = r.advance()
	ok(r.present("E05"), "betting slip must break the patrol statement")
	ok(GameState.has_flag("erdem_confessed"), "confession flag set")
	s = _advance_to_choices(r, DialogueRunner.LINE)
	s = _advance_to_choices(r, _pick(r, "confess_firm"))
	ok("T_ERDEM_2" in GameState.testimony and "T_ERDEM_3" in GameState.testimony, "confession testimony recorded")
	offered = r.choices().map(func(c): return c["id"])
	ok("patrol" not in offered and "absence" in offered, "topics update after confession")
	ok(_pick(r, "bye") == DialogueRunner.END, "conversation can be ended")

	ok(GameState.check(_hotspot("terminal")["conditions"]), "terminal unlocks after confession")
	ok(not GameState.check(_hotspot("terminal_locked")["conditions"]), "locked terminal text goes away")
	GameState.add_evidence("E06")
	ok(CaseDB.location_evidence("lobby").size() == 7, "lobby has 7 pieces of evidence")

	var r2 := DialogueRunner.new("erdem")
	r2.start()
	ok(r2.node_id == "return", "second conversation uses the return greeting")


func _test_save_roundtrip() -> void:
	print("- save / load")
	var before := GameState.to_dict()
	var text := JSON.stringify({"version": 1, "state": before})
	GameState.new_game()
	GameState.active = false
	ok(GameState.evidence.is_empty(), "new game clears evidence")
	GameState.from_dict(JSON.parse_string(text)["state"])
	GameState.active = false
	var after := GameState.to_dict()
	ok(JSON.stringify(before) == JSON.stringify(after), "state survives save and load")
