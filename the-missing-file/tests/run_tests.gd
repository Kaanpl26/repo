extends Node
## Automated checks. Run with:
##   godot --headless --path . res://tests/run_tests.tscn
## Exits with code 0 when everything passes, 1 otherwise.

var _fails := 0
var _checks := 0


func _ready() -> void:
	Profile.persist = false      # never touch the player's real profile
	SaveManager.enabled = false  # and never write save files, except where a test says so
	Settings.persist = false
	Profile.reset()
	_test_scripts_load()
	_test_build_folder_is_ignored()
	_test_localization()
	for entry in CaseDB.index:
		if entry.get("available", false):
			print("== data checks: ", entry["id"])
			_open_case(entry["id"])
			_test_data_references()
			_test_dialogue_graph()
			_test_case_structure()
	print("== data checks: office")
	_open_case("office")
	_test_data_references()
	_test_dialogue_graph()
	_test_case_structure()
	print("== Case 1")
	_open_case("case_01")
	_test_playthrough()
	_test_board_and_verdict()
	_test_interrogation()
	_test_career()
	_test_save_roundtrip()
	_test_save_migration()
	print("== Case 2")
	_test_case_02()
	print("== Case 3")
	_test_case_03()
	print("== Case 4")
	_test_case_04()
	print("== Decision tree")
	_test_decision_tree()
	print("== Office")
	_test_office()
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _open_case(id: String) -> void:
	GameState.new_game(id)
	GameState.active = false
	ok(CaseDB.case_id == id and GameState.case_id == id, "case %s loads" % id)


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


# Nothing from the build folder (APKs, screenshots) may be part of the project.
func _test_build_folder_is_ignored() -> void:
	print("- build folder is not part of the project")
	ok(_files("res://build", ".png").is_empty() or FileAccess.file_exists("res://build/.gdignore"), "build/ must contain .gdignore so its files are never packed into the game")
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	ok("build/*" in preset, "the export preset must exclude build/")


# Every key must have non-empty English and Turkish text.
func _test_localization() -> void:
	print("- localization tables")
	for table in Loc.tables:
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
		_key(t["title"], "testimony title " + id)
		ok(CaseDB.characters.has(t["speaker"]), "testimony %s: unknown speaker" % id)
	for name in Audio.SFX + ["music"]:
		ok(ResourceLoader.exists("res://assets/audio/%s.wav" % name), "sound missing: " + name)
	for id in CaseDB.evidence:
		var e: Dictionary = CaseDB.evidence[id]
		ok(e.has("gist"), "evidence %s has no one-line summary" % id)
		_key(e.get("gist", ""), "evidence %s.gist" % id)
		ok(tr(e.get("gist", "")).length() <= 170, "evidence %s: summary too long for a card" % id)
		ok(CaseDB.card_gist(id) == e.get("gist", ""), "card summary for %s" % id)
		_check_effects(e.get("effects", []), "evidence " + id)
		for field in ["name", "desc", "body"]:
			_key(e[field], "evidence %s.%s" % [id, field])
		ok(ResourceLoader.exists(e["icon"]), "evidence %s: icon missing" % id)
	for i in Audio.VOICE_SYLLABLES:
		ok(ResourceLoader.exists("res://assets/audio/voice_%d.wav" % i), "speech syllable %d missing" % i)
	for id in CaseDB.characters:
		var c: Dictionary = CaseDB.characters[id]
		_key(c["name"], "character " + id)
		ok(c.has("voice") and float(c["voice"]) >= 0.5 and float(c["voice"]) <= 1.8, "character %s needs a voice pitch between 0.5 and 1.8" % id)
		if c.has("portrait"):
			ok(ResourceLoader.exists(c["portrait"]), "character %s: portrait missing" % id)
		if c.has("dialogue"):
			ok(CaseDB.dialogues.has(id), "character %s: dialogue failed to load" % id)
	var placed := {}
	for id in CaseDB.locations:
		var l: Dictionary = CaseDB.locations[id]
		_key(l["name"], "location " + id)
		ok(ResourceLoader.exists(l["background"]), "location %s: background missing" % id)
		_check_conditions(l.get("unlock", []), "location %s unlock" % id)
		if l.get("ambience", "") != "":
			ok(ResourceLoader.exists("res://assets/audio/%s.wav" % l["ambience"]), "location %s: ambience sound missing" % id)
		for prop in l.get("props", []):
			ok(ResourceLoader.exists(prop["image"]), "location %s: prop image missing" % id)
			ok(prop["pos"].size() == 2, "location %s: prop needs a position" % id)
			_check_conditions(prop.get("conditions", []), "location %s prop" % id)
		for always in l.get("always", []):
			_check_conditions(always.get("conditions", []), "location %s always" % id)
			_check_effects(always.get("effects", []), "location %s always" % id)
		for enter in _enter_entries(l):
			_check_conditions(enter.get("conditions", []), "location %s on_enter" % id)
			_check_effects(enter.get("effects", []), "location %s on_enter" % id)
			if enter.has("caption"):
				_key(enter["caption"], "location %s on_enter" % id)
		for hint in l.get("hints", []):
			_key(hint["text"], "location %s hint" % id)
			_check_conditions(hint.get("conditions", []), "location %s hint" % id)
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
				"exit":
					ok(CaseDB.locations.has(h["target"]), w + ": unknown target location")
				"action":
					ok(h["action"] in ["cases", "achievements", "board", "howto"], w + ": unknown action")
				_:
					ok(false, w + ": unknown type")
	var record_ids := {}
	for r in CaseDB.records:
		var w := "record " + str(r.get("id", "?"))
		ok(not record_ids.has(r["id"]), w + ": duplicate id")
		record_ids[r["id"]] = true
		ok(CaseDB.evidence.has(r["evidence"]), w + ": unknown evidence")
		ok(not placed.has(r["evidence"]), w + ": its evidence is also lying in a scene")
		placed[r["evidence"]] = true
		_key(r["query"], w)
		ok(Loc.has_key("RECORD_TYPE_" + str(r["type"]).to_upper()), w + ": no label for type " + str(r["type"]))
		_check_conditions(r.get("conditions", []), w)
		ok(not r.get("conditions", []).is_empty(), w + ": a lookup needs a reason (conditions)")
	for effects in _all_effect_lists():
		for e in effects:
			if e.has("add_evidence"):
				placed[e["add_evidence"]] = true
	for id in CaseDB.evidence:
		ok(placed.has(id), "evidence %s cannot be found anywhere" % id)


func _enter_entries(location: Dictionary) -> Array:
	var enter: Variant = location.get("on_enter", [])
	return enter if enter is Array else [enter]


## Every list of effects in the open case: dialogue nodes, lines and choices,
## location entry events, evidence pick-ups and conclusions.
func _all_effect_lists() -> Array:
	var lists: Array = []
	for ch in CaseDB.dialogues:
		for id in CaseDB.dialogues[ch]["nodes"]:
			var n: Dictionary = CaseDB.dialogues[ch]["nodes"][id]
			lists.append(n.get("effects", []))
			for l in n.get("lines", []):
				lists.append(l.get("effects", []))
			for c in n.get("choices", []):
				lists.append(c.get("effects", []))
	for id in CaseDB.locations:
		for enter in _enter_entries(CaseDB.locations[id]):
			lists.append(enter.get("effects", []))
		for always in CaseDB.locations[id].get("always", []):
			lists.append(always.get("effects", []))
	for id in CaseDB.evidence:
		lists.append(CaseDB.evidence[id].get("effects", []))
	for id in CaseDB.insights:
		lists.append(CaseDB.insights[id].get("effects", []))
	return lists


func _check_conditions(list: Array, where: String) -> void:
	for c in list:
		for k in c:
			ok(k in ["has_evidence", "no_evidence", "flag", "not_flag", "has_insight", "no_insight", "has_testimony", "profile_flag", "case_solved", "case_closed", "rank_at_least"], where + ": unknown condition " + k)
			if k in ["case_solved", "case_closed"]:
				ok(not CaseDB.case_entry(c[k]).is_empty(), where + ": condition uses unknown case")
			if k in ["has_insight", "no_insight"]:
				ok(CaseDB.insights.has(c[k]), where + ": condition uses unknown insight")
			if k == "has_testimony":
				ok(CaseDB.meta["testimony"].has(c[k]), where + ": condition uses unknown testimony")
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
		if d.has("closed"):
			ok(nodes.has(d["closed"]), "%s: closed node missing" % ch)
			queue.append(d["closed"])
			ok(not nodes[d["closed"]].has("next") and not nodes[d["closed"]].has("choices"), "%s: closed node must end the conversation" % ch)
			ok(int(CaseDB.characters[ch].get("patience", 0)) >= 2, "%s: needs a patience of at least 2" % ch)
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
				if l.has("mood"):
					ok(l["mood"] in ["defensive", "shaken"], w + ": unknown mood")
					if CaseDB.characters[l["s"]].has("portrait"):
						ok(ResourceLoader.exists(CaseDB.characters[l["s"]]["portrait"].replace(".png", "_%s.png" % l["mood"])), w + ": portrait for mood missing")
				if l.has("press"):
					ok(nodes.has(l["press"]), w + ": press target missing")
					queue.append(l["press"])
					if nodes.has(l["press"]):
						ok(not nodes[l["press"]].has("next") and not nodes[l["press"]].has("choices"), w + ": a pressed node must return to the statement")
				_check_effects(l.get("effects", []), w)
				if l.has("present"):
					var p: Dictionary = l["present"]
					var accepted: Array = p["accept"] if p["accept"] is Array else [p["accept"]]
					for card in accepted:
						ok(CaseDB.card_kind(card) != "", w + ": present uses unknown card " + str(card))
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


# Objectives, insights, suspects, timeline and endings must be consistent.
func _test_case_structure() -> void:
	print("- objectives, insights, suspects, timeline, endings")
	for hint in CaseDB.meta.get("hints", []):
		_key(hint["text"], "case hint")
		_check_conditions(hint.get("conditions", []), "case hint")
	for o in CaseDB.meta["objectives"]:
		_key(o["text"], "objective " + o["id"])
		_check_conditions(o.get("show", []), "objective " + o["id"])
		_check_conditions(o["done"], "objective " + o["id"])
		ok(not o["done"].is_empty(), "objective %s can never be completed" % o["id"])

	# every statement must be recorded somewhere
	var granted := {}
	for list in _all_effect_lists():
		for e in list:
			if e.has("add_testimony"):
				granted[e["add_testimony"]] = true
	for id in CaseDB.meta["testimony"]:
		ok(granted.has(id), "statement %s is never recorded" % id)

	var pairs := {}
	for id in CaseDB.insights:
		var d: Dictionary = CaseDB.insights[id]
		var w: String = "insight " + id
		ok(d["cards"].size() == 2 and d["cards"][0] != d["cards"][1], w + " needs two different cards")
		for c in d["cards"]:
			ok(CaseDB.card_kind(c) != "", w + ": unknown card " + str(c))
		var pair := [d["cards"][0], d["cards"][1]]
		pair.sort()
		ok(not pairs.has(str(pair)), w + ": same pair as another insight")
		pairs[str(pair)] = true
		_key(d["title"], w)
		_key(d["text"], w)
		ok(d["wrong"].size() >= 2, w + " needs at least two wrong answers")
		for k in d["wrong"]:
			_key(k, w)
		_key(d.get("question", ""), w + ".question")
		_key(d.get("key", ""), w + ".key")
		ok(d.get("wrong_short", []).size() == 2, w + " needs two short wrong answers")
		for k in d.get("wrong_short", []):
			_key(k, w + ".wrong_short")
			for lang in ["en", "tr"]:
				TranslationServer.set_locale(lang)
				ok(tr(k).length() <= 42, "%s: short answer too long (%s)" % [w, lang])
		for lang in ["en", "tr"]:
			TranslationServer.set_locale(lang)
			ok(tr(d.get("key", "")).length() <= 26, "%s: key fact too long (%s)" % [w, lang])
			ok(tr(d["title"]).length() <= 48, "%s: title too long to be an answer (%s)" % [w, lang])
		TranslationServer.set_locale("en")
		_check_effects(d.get("effects", []), w)
		ok(CaseDB.card_title(id) != "" and ResourceLoader.exists(CaseDB.card_icon(id)), w + ": card info")

	var e: Dictionary = CaseDB.endings
	var has_verdict: bool = not e["suspects"].is_empty()    # the office has nobody to accuse
	ok(not has_verdict or e["culprit"] in e["suspects"], "culprit must be a suspect")
	for s in e["suspects"]:
		ok(CaseDB.characters.has(s) and CaseDB.characters[s].has("portrait"), "suspect %s needs a portrait" % s)
		ok(CaseDB.suspects.has(s), "suspect %s has no profile" % s)
		if s != e["culprit"]:
			ok(e["wrong"].has(s), "no ending for accusing " + s)
	for s in CaseDB.suspects:
		var p: Dictionary = CaseDB.suspects[s]
		_key(p["role"], "suspect " + s)
		_key(p["bio"], "suspect " + s)
		for n in p["notes"]:
			_key(n["text"], "suspect note " + s)
			_check_conditions(n.get("conditions", []), "suspect note " + s)
	for slot in e["slots"]:
		ok(Loc.has_key("ACCUSE_SLOT_" + slot.to_upper()), "no label for proof slot " + slot)
		ok(not e["proof"][e["culprit"]].get(slot, []).is_empty(), "no valid proof exists for slot " + slot)
		ok(Loc.has_key("WEAK_" + slot.to_upper()), "no weak-point text for slot " + slot)
		for card in e["proof"][e["culprit"]].get(slot, []):
			ok(CaseDB.card_kind(card) != "", "proof uses unknown card " + card)
	_check_conditions(e.get("full_requires", []), "endings full_requires")
	for id in e["endings"]:
		for line in e["endings"][id].get("epilogue", []):
			_key(line["text"], "epilogue " + id)
			_check_conditions(line.get("conditions", []), "epilogue " + id)
	if has_verdict:
		for id in [e["full"], e["partial"], e["accident"]] + e["wrong"].values():
			ok(e["endings"].has(id), "ending %s is not defined" % id)
	for id in e["endings"]:
		_key(e["endings"][id]["title"], "ending " + id)
		_key(e["endings"][id]["text"], "ending " + id)

	_key(e["question"], "accusation question")
	_key(CaseDB.meta["timeline_title"], "timeline title")
	for optional in ["board_title", "board_button", "evidence_toast"]:
		if CaseDB.meta.has(optional):
			_key(CaseDB.meta[optional], "case " + optional)
	for a in CaseDB.achievements:
		if a.get("case", "") != CaseDB.case_id:
			continue
		_check_conditions(a.get("conditions", []), "achievement " + a["id"])
		if a.has("ending"):
			ok(e["endings"].has(a["ending"]), "achievement %s: unknown ending" % a["id"])
	for flag in e.get("carry", []):
		ok(typeof(flag) == TYPE_STRING, "carried flags are names")

	var rx := RegEx.new()
	rx.compile("^([0-2][0-9]:[0-5][0-9]|[12][0-9]{3})$")   # a time of day, or a year
	for t in CaseDB.timeline:
		ok(rx.search(t["time"]) != null, "timeline: bad time " + str(t["time"]))
		_key(t["text"], "timeline " + t["time"])
		_check_conditions(t.get("conditions", []), "timeline " + t["time"])
		_check_conditions(t.get("disputed", []), "timeline " + t["time"])


# ---------------------------------------------------------------- helpers

## Walks into a location the way the game does and picks up everything that
## can be picked up there right now.
func _visit(location_id: String) -> void:
	ok(CaseDB.location_unlocked(location_id), "location %s should be unlocked by now" % location_id)
	GameState.location = location_id
	if not GameState.has_flag("visited_" + location_id):
		GameState.set_flag("visited_" + location_id)
		for enter in _enter_entries(CaseDB.locations[location_id]):
			if GameState.check(enter.get("conditions", [])):
				GameState.apply(enter.get("effects", []))
	for always in CaseDB.locations[location_id].get("always", []):
		if GameState.check(always.get("conditions", [])):
			GameState.apply(always.get("effects", []))
	for h in CaseDB.locations[location_id]["hotspots"]:
		if h["type"] == "evidence" and GameState.check(h.get("conditions", [])):
			GameState.add_evidence(h["evidence"])


## Opens a conversation and stops at the first list of choices.
func _talk(character: String) -> DialogueRunner:
	var r := DialogueRunner.new(character)
	_advance_to_choices(r, r.start())
	return r


## Picks a topic, presents a card on the first presentable line, and returns
## to the topic list. Returns whether the card was accepted.
func _confront(r: DialogueRunner, topic: String, card: String) -> bool:
	var s := _pick(r, topic)
	while not r.can_present() and s == DialogueRunner.LINE:
		s = r.advance()
	ok(r.can_present(), "%s.%s should have a statement to challenge" % [r.character, topic])
	if not r.can_present():
		return false
	var accepted := r.present(card)
	_advance_to_choices(r, DialogueRunner.LINE)
	return accepted


func _ask(r: DialogueRunner, topic: String) -> void:
	_advance_to_choices(r, _pick(r, topic))


## Makes every conclusion the player's cards allow, using the Board hint the
## way a player would. Returns how many were made.
func _connect_all() -> int:
	var made := 0
	var id := Hints.next_link()
	while id != "":
		var cards: Array = CaseDB.insights[id]["cards"]
		var res := Deduction.try_link(cards[0], cards[1])
		ok(res["status"] == Deduction.FOUND and res["id"] == id, "board accepts the hinted pair for " + id)
		ok(Deduction.confirm(id, CaseDB.insights[id]["text"]), "right conclusion accepted for " + id)
		made += 1
		id = Hints.next_link()
	return made


# Board rules, then the whole case from the lobby to the true ending.
func _test_board_and_verdict() -> void:
	print("- board rules")
	var links := GameState.bad_links
	ok(Deduction.try_link("E03", "E05")["status"] == Deduction.NONE, "unrelated cards do not connect")
	ok(GameState.bad_links == links + 1, "a dead-end connection is counted")
	var res := Deduction.try_link("E06", "E02")
	ok(res["status"] == Deduction.FOUND and res["id"] == "I_VARDAR_RETURNED", "card order does not matter")
	var opts := Deduction.options("I_VARDAR_RETURNED")
	ok(opts.size() == 3 and CaseDB.insights["I_VARDAR_RETURNED"]["title"] in opts, "three short possible conclusions offered")
	var m := GameState.mistakes
	ok(not Deduction.confirm("I_VARDAR_RETURNED", CaseDB.insights["I_VARDAR_RETURNED"]["wrong"][0]), "wrong conclusion rejected")
	ok(GameState.mistakes == m + 1 and not GameState.has_insight("I_VARDAR_RETURNED"), "wrong conclusion costs a mistake")
	ok(Deduction.confirm("I_VARDAR_RETURNED", CaseDB.insights["I_VARDAR_RETURNED"]["text"]), "right conclusion accepted")
	ok(Deduction.try_link("E02", "E06")["status"] == Deduction.KNOWN, "same connection is not offered twice")
	_test_board2()
	ok(Verdict.resolve("vardar", {"opportunity": "I_VARDAR_RETURNED"}) == "B", "culprit with only one proof -> ending B")
	ok(Verdict.weak_points("vardar", {"opportunity": "I_VARDAR_RETURNED"}) == ["WEAK_MOTIVE", "WEAK_LINK", "WEAK_FILE_MISSING"], "a weak verdict says what was missing")
	ok(Verdict.weak_points("aras", {}).is_empty(), "no weak points are listed for the wrong person")
	ok(Hints.link_count() > 0, "the Board knows more connections are possible")
	ok(not Hints.card_used_up("E02") and not Hints.card_used_up("E03"), "cards with connections left are not faded")
	ok(Hints.card_used_up("E06"), "a card whose only connection is made is faded")

	print("- full case playthrough")
	_connect_all()
	ok(not CaseDB.location_unlocked("stacks"), "stacks stay closed until the office has been visited")
	_visit("office")
	for id in ["E07", "E08", "E09", "E10", "E11"]:
		ok(GameState.has_evidence(id), "office evidence %s collected" % id)
	ok(Hints.next("lobby").get("type") in ["text", "objective"], "lobby hint still works later in the case")

	var leyla := _talk("aydin")
	ok(Hints.next("lobby").get("text") == "HINT_BOARD", "new evidence makes the hint point at the Board again")
	_connect_all()
	ok(Hints.next("lobby").get("text") == "C1_HINT_AYDIN", "hint explains how to challenge Leyla")
	ok(not _confront(leyla, "left", "E05"), "Leyla: unrelated evidence is rejected")
	ok(_confront(leyla, "left", "E02"), "Leyla: the door log breaks her story")
	_ask(leyla, "kind")
	ok("T_AYDIN_2" in GameState.testimony, "Leyla tells everything when treated kindly")
	_ask(leyla, "work")
	_ask(leyla, "visit")
	ok(_pick(leyla, "bye") == DialogueRunner.END, "Leyla: conversation ends")

	_visit("director")
	ok(GameState.has_evidence("E18") and GameState.has_evidence("E19"), "director's office evidence collected")
	var vardar := _talk("vardar")
	ok(vardar.node_id == "hub", "first meeting with Vardar reaches the topic list")
	ok(_confront(vardar, "night", "E06"), "Vardar: the barrier log breaks her alibi")
	ok(_confront(vardar, "email", "E07"), "Vardar: caught knowing about the retyped page")
	ok(_confront(vardar, "y1998", "E18"), "Vardar: the certificate proves she was S. Maden")
	_pick(vardar, "bye")
	vardar = DialogueRunner.new("vardar")
	vardar.start()
	ok(vardar.node_id == "ask", "Vardar asks whether Vural left a note")
	_advance_to_choices(vardar, DialogueRunner.LINE)
	_ask(vardar, "keep")
	ok(not GameState.has_flag("file_compromised"), "keeping the note back protects the file")

	_visit("stacks")
	for id in ["E12", "E13", "E14", "E16"]:
		ok(GameState.has_evidence(id), "stacks evidence %s collected" % id)
	ok(not GameState.has_evidence("E17"), "the file stays hidden until the mirror note is understood")
	ok(Hints.next("stacks").get("type") == "text", "stacks hint explains how to find the file")
	_connect_all()
	for id in CaseDB.insights:
		ok(GameState.has_insight(id), "conclusion %s can be reached" % id)
	_visit("stacks")
	ok(GameState.has_evidence("E17") and GameState.has_flag("file_found"), "file 47-B found at 74-B, intact")
	ok(not GameState.has_evidence("E17X"), "the damaged file is not offered on this path")

	ok(_confront(vardar, "stacks", "I_ELEVATOR"), "Vardar: the elevator conclusion corners her")
	var s2 := _pick(vardar, "earrings")
	while not vardar.can_press() and s2 == DialogueRunner.LINE:
		s2 = vardar.advance()
	ok(vardar.can_press(), "Vardar: the earring statement can be pressed")
	_advance_to_choices(vardar, vardar.press())
	ok("T_VARDAR_5" in GameState.testimony, "Vardar: pressing gets the admission that one earring is lost")
	ok(GameState.has_flag("vardar_cornered"), "Vardar asks for a lawyer")
	var aras := _talk("aras")
	ok(_confront(aras, "visit", "E10"), "Aras: his own letter breaks the courtesy-call story")
	_ask(aras, "direct")
	ok("T_ARAS_3" in GameState.testimony, "Aras: the direct approach earns the page-twelve remark")
	_ask(aras, "nine")
	_ask(aras, "today")
	var erdem := _talk("erdem")
	_ask(erdem, "report")
	_ask(erdem, "report_no")
	ok(GameState.has_flag("erdem_spared"), "decision about Erdem's report is recorded")

	for id in CaseDB.countable_evidence():
		ok(GameState.has_evidence(id), "evidence %s was found on the main path" % id)
	for id in CaseDB.meta["testimony"]:
		if id != "T_AYDIN_3":
			ok(id in GameState.testimony, "statement %s was recorded on the main path" % id)

	print("- verdicts")
	var proof := {"motive": "I_SM", "opportunity": "I_ELEVATOR", "link": "I_EARRING"}
	ok(Verdict.resolve(Verdict.ACCIDENT, {}) == "E", "accident -> ending E")
	ok(Verdict.resolve("aras", proof) == "C", "accusing Aras -> ending C")
	ok(Verdict.resolve("erdem", proof) == "D" and Verdict.resolve("aydin", proof) == "D", "scapegoat -> ending D")
	ok(Verdict.resolve("vardar", {}) == "B", "culprit without proof -> ending B")
	ok(Verdict.resolve("vardar", {"motive": "I_EARRING", "opportunity": "I_SM", "link": "I_ELEVATOR"}) == "B", "proof in the wrong slots -> ending B")
	ok(Verdict.resolve("vardar", {"motive": "I_SM", "opportunity": "I_EMAIL", "link": "I_EARRING"}) == "A", "any of the opportunity conclusions counts")
	ok(Verdict.resolve("vardar", {"motive": "I_SM", "opportunity": "E06", "link": "E13"}) == "B", "raw evidence is not proof; it must be a conclusion")
	for slot in CaseDB.endings["slots"]:
		for card in CaseDB.endings["proof"]["vardar"][slot]:
			ok(CaseDB.card_kind(card) == "insight", "proof for %s must be a Board conclusion" % slot)
	ok(Verdict.resolve("vardar", proof) == "A", "culprit with full proof and the file -> ending A")
	ok(Verdict.weak_points("vardar", proof).is_empty(), "a complete case has no weak points")
	_test_wall_layout("Case 1")
	ok(Hints.link_count() == 0, "no connections remain at the end")
	ok(Hints.card_used_up("E02") and Hints.card_used_up("I_VARDAR_RETURNED"), "cards with nothing left to give are faded")
	ok(not Hints.card_used_up("E10"), "a card that connects to nothing is never marked as used up")
	ok(not Verdict.epilogue("A").is_empty(), "true ending has epilogue lines for the player's decisions")
	GameState.set_flag("case_solved")
	for o in CaseDB.meta["objectives"]:
		ok(GameState.check(o.get("show", [])) and GameState.check(o["done"]), "objective %s is complete at the end" % o["id"])
	ok(Hints.next(GameState.location).is_empty(), "no hints remain when the case is solved")
	var r := Verdict.rating()
	ok(r["evidence"] == r["evidence_total"] and r["insights"] == r["insights_total"], "rating counts everything found")
	ok(r["grade"] in ["S", "A", "B", "C"], "rating has a grade")
	var solved_state := GameState.to_dict().duplicate(true)

	print("- alternative branches")
	# Telling Vardar about the note before finding the file lets her reach it first.
	GameState.new_game()
	GameState.active = false
	for flag in ["intro_seen", "erdem_met", "visited_office", "vardar_met"]:
		GameState.set_flag(flag)
	for id in ["E02", "E03", "E06", "E08", "E09", "E13", "E14", "E18"]:
		GameState.add_evidence(id)
	var v2 := DialogueRunner.new("vardar")
	v2.start()
	_advance_to_choices(v2, DialogueRunner.LINE)
	_ask(v2, "tell_early")
	ok(GameState.has_flag("file_compromised"), "telling Vardar about the note compromises the file")
	_connect_all()
	_visit("stacks")
	ok(GameState.has_evidence("E17X") and not GameState.has_evidence("E17"), "the file is found with pages removed")
	ok(Verdict.resolve("vardar", {"motive": "I_SM", "opportunity": "I_VARDAR_RETURNED", "link": "I_EARRING"}) == "B", "compromised file -> ending B even with full proof")
	ok(Verdict.weak_points("vardar", {"motive": "I_SM", "opportunity": "I_VARDAR_RETURNED", "link": "I_EARRING"}) == ["WEAK_FILE_DAMAGED"], "the verdict explains that the file was spoiled")
	ok(Verdict.rating()["evidence"] <= Verdict.rating()["evidence_total"], "damaged file is not double counted")

	# Pressuring Leyla loses the detail at first; the stopped watch gets it later.
	GameState.new_game()
	GameState.active = false
	GameState.set_flag("erdem_met")
	GameState.add_evidence("E02")
	var l2 := _talk("aydin")
	_confront(l2, "left", "E02")
	_ask(l2, "hard")
	ok("T_AYDIN_3" in GameState.testimony and "T_AYDIN_2" not in GameState.testimony, "pressure only gets a partial statement")
	ok("heard" not in l2.choices().map(func(c): return c["id"]), "follow-up question needs the stopped watch")
	GameState.add_evidence("E12")
	_ask(l2, "heard")
	ok("T_AYDIN_2" in GameState.testimony, "the full statement can still be obtained, so the case stays solvable")

	GameState.from_dict(solved_state)
	GameState.active = false


## Reads every database record that can be looked up right now.
func _look_up_all() -> int:
	var n := 0
	for r in CaseDB.available_records():
		if not GameState.has_evidence(r["evidence"]):
			GameState.add_evidence(r["evidence"])
			n += 1
	return n


## Presses the first pressable statement of a topic and returns to the topic list.
func _press(r: DialogueRunner, topic: String) -> void:
	var s := _pick(r, topic)
	while not r.can_press() and s == DialogueRunner.LINE:
		s = r.advance()
	ok(r.can_press(), "%s.%s should have a statement to press" % [r.character, topic])
	if r.can_press():
		_advance_to_choices(r, r.press())


# The whole of Case 2, its database, its decisions and what Case 1 carries into it.
func _test_case_02() -> void:
	Profile.reset()
	_open_case("case_02")
	print("- database and full playthrough")
	ok(CaseDB.records.size() == 4, "Case 2 has four database records")
	ok(CaseDB.available_records().is_empty(), "nothing can be looked up before there is a reason to")
	ok(Hints.next("road").get("type") == "point", "hint points at evidence at the start")
	ok(not CaseDB.location_unlocked("newsroom"), "other places open after reporting to the chief")

	var chief := _talk("soykan")
	_ask(chief, "what")
	_press(chief, "why")
	ok("T_SOYKAN_2" in GameState.testimony, "the chief's remark about the appointment is recorded")
	_advance_to_choices(chief, _pick(chief, "who"))
	_ask(chief, "wait")
	ok(GameState.has_flag("kaplan_free") and not GameState.has_flag("kaplan_held"), "decision: the site manager is not brought in")
	_advance_to_choices(chief, _pick(chief, "who"))
	ok("hold" not in chief.choices().map(func(c): return c["id"]), "the decision is only offered once")
	_ask(chief, "back")
	_pick(chief, "bye")

	_visit("road")
	for id in ["E01", "E02", "E03", "E04", "E05", "E06"]:
		ok(GameState.has_evidence(id), "road evidence %s collected" % id)
	ok(Hints.next("road").get("text") == "HINT_DATABASE", "hint sends the player to the database")
	ok(Hints.lookup_count() == 3, "three records are waiting to be read")
	ok(Hints.evidence_waiting("road") == 0, "nothing left to pick up on the road")
	ok(_look_up_all() == 3, "phone, company and person can be looked up after the road")
	ok(not GameState.has_evidence("E21"), "the plate cannot be looked up before the camera still is found")
	_connect_all()
	ok(GameState.has_insight("I_NOT_ACCIDENT") and GameState.has_insight("I_CALLER"), "road conclusions reached")

	_visit("newsroom")
	for id in ["E07", "E08", "E09", "E10", "E11"]:
		ok(GameState.has_evidence(id), "newsroom evidence %s collected" % id)
	ok(not GameState.has_evidence("E13"), "drawer 117 stays shut until the key is understood")
	ok(not ("T_AYDIN_TIP" in GameState.testimony), "no call from Leyla without the Case 1 decision")
	var deniz := _talk("aktas")
	ok(not _confront(deniz, "morning", "E08"), "Deniz: unrelated card rejected")
	ok(_confront(deniz, "morning", "E09"), "Deniz: the sign-in sheet breaks her story")
	_ask(deniz, "spare")
	ok(GameState.has_evidence("E12") and "T_AKTAS_2" in GameState.testimony, "sparing Deniz gets the laptop and what she saw")
	_ask(deniz, "story")
	_press(deniz, "editor")
	_pick(deniz, "bye")

	_visit("site")
	for id in ["E14", "E15", "E16", "E17", "E18"]:
		ok(GameState.has_evidence(id), "site evidence %s collected" % id)
	ok(_look_up_all() == 1 and GameState.has_evidence("E21"), "the plate can be looked up after the camera still")
	var kaplan := _talk("kaplan")
	ok(kaplan.node_id == "hub", "Kaplan talks freely when he was not brought in")
	_press(kaplan, "where")
	_ask(kaplan, "truck")
	_ask(kaplan, "seen")
	ok("T_KAPLAN_2" in GameState.testimony, "Kaplan describes the woman in the red car")
	_ask(kaplan, "owner")
	_pick(kaplan, "bye")

	_visit("planning")
	ok(GameState.has_evidence("E19") and GameState.has_evidence("E20"), "planning office evidence collected")
	var guven := _talk("guven")
	ok(Hints.next("planning").get("text") in ["HINT_BOARD", "C2_HINT_GUVEN"], "hint works in the planning office")
	ok(_confront(guven, "knew", "E20"), "Güven: his own calendar makes him admit he was the source")
	_press(guven, "meet")
	_ask(guven, "told")
	_advance_to_choices(guven, _pick(guven, "now"))
	_ask(guven, "protect")
	ok(GameState.has_flag("guven_protected"), "decision about Güven recorded")
	_pick(guven, "bye")

	_connect_all()
	ok(GameState.has_insight("I_DRAWER"), "the key and the index give the drawer")
	_visit("newsroom")
	ok(GameState.has_evidence("E13") and GameState.has_flag("file_found"), "file 58-D found in drawer 117")
	_connect_all()
	for id in CaseDB.insights:
		ok(GameState.has_insight(id), "conclusion %s can be reached" % id)

	var soylu := _talk("soylu")
	_press(soylu, "call")
	ok(_confront(soylu, "call", "I_LURE"), "Soylu: the two calls break her story")
	ok(_confront(soylu, "home", "I_CAR"), "Soylu: her car at the gate breaks her alibi")
	_press(soylu, "damage")
	ok(_confront(soylu, "damage", "I_PAINT"), "Soylu: the paint corners her")
	ok(GameState.has_flag("soylu_cornered"), "Soylu asks for Karaca")
	_press(soylu, "spiked")
	_pick(soylu, "bye")

	for id in CaseDB.countable_evidence():
		ok(GameState.has_evidence(id), "evidence %s was found on the main path" % id)
	for id in CaseDB.meta["testimony"]:
		if id not in ["T_ERDEM_TIP", "T_AYDIN_TIP"]:
			ok(id in GameState.testimony, "statement %s was recorded on the main path" % id)

	print("- verdicts")
	var proof := {"motive": "I_MOTIVE", "opportunity": "I_CAR", "link": "I_PAINT"}
	ok(Verdict.resolve(Verdict.ACCIDENT, {}) == "E", "accident -> ending E")
	ok(Verdict.resolve("kaplan", proof) == "C", "accusing the chief's suspect -> ending C")
	ok(Verdict.resolve("guven", proof) == "D" and Verdict.resolve("aktas", proof) == "D", "scapegoat -> ending D")
	ok(Verdict.resolve("soylu", {"motive": "I_MOTIVE", "opportunity": "I_CAR"}) == "B", "one proof missing -> ending B")
	ok(Verdict.resolve("soylu", {"motive": "I_MOTIVE", "opportunity": "I_LURE", "link": "I_PAINT"}) == "A", "either opportunity conclusion counts")
	ok(Verdict.resolve("soylu", proof) == "A", "full proof and the file -> ending A")
	ok(Verdict.epilogue("A").size() == 3, "true ending has an epilogue line for each of the three decisions")
	_test_wall_layout("Case 2")
	GameState.set_flag("case_solved")
	for o in CaseDB.meta["objectives"]:
		ok(GameState.check(o.get("show", [])) and GameState.check(o["done"]), "objective %s is complete at the end" % o["id"])
	ok(Hints.next(GameState.location).is_empty(), "no hints remain when the case is solved")
	var rating := Verdict.rating()
	ok(rating["evidence"] == rating["evidence_total"] and rating["insights"] == rating["insights_total"], "rating counts everything found")
	var carried: Array = []
	for flag in CaseDB.endings["carry"]:
		if GameState.has_flag(flag):
			carried.append(flag)
	Profile.record_verdict("case_02", "A", true, rating, carried)
	var earned := Achievements.evaluate("A")
	for id in ["C2_SOLVED", "C2_CORNERED", "C2_FENER", "C2_LOOKUP", "C2_NOT_OBVIOUS"]:
		ok(id in earned or Profile.achievements.has(id), "achievement %s earned on the main path" % id)
	ok(not Profile.achievements.has("FIRST_CASE"), "Case 1 achievements are not awarded in Case 2")
	ok(Profile.has_flag("case_02.guven_protected") and Profile.has_flag("case_02.kaplan_free"), "Case 2 decisions are carried forward")

	print("- alternative branches")
	# The file is required for the true ending.
	_open_case("case_02")
	for id in CaseDB.insights:
		GameState.insights.append(id)
	ok(Verdict.resolve("soylu", proof) == "B", "without file 58-D the best verdict is ending B")

	# Having the site manager brought in costs his statement, not the case.
	_open_case("case_02")
	chief = _talk("soykan")
	_advance_to_choices(chief, _pick(chief, "who"))
	_ask(chief, "hold")
	ok(GameState.has_flag("kaplan_held"), "decision: the site manager is brought in")
	_visit("site")
	kaplan = DialogueRunner.new("kaplan")
	kaplan.start()
	ok(kaplan.node_id == "intro_held" and kaplan.line()["s"] == "karaca", "Karaca speaks for Kaplan when he was brought in")
	_advance_to_choices(kaplan, DialogueRunner.LINE)
	_ask(kaplan, "seen_held")
	ok("T_KAPLAN_2" not in GameState.testimony, "the red-car statement is lost when he was brought in")
	_look_up_all()
	_connect_all()
	ok(GameState.has_insight("I_CAR"), "the case stays solvable: the camera and the plate still identify the car")

	# Charging Deniz: she still tells what she saw, when asked.
	_open_case("case_02")
	GameState.set_flag("soykan_met")
	_visit("newsroom")
	deniz = _talk("aktas")
	_confront(deniz, "morning", "I_LAPTOP" if GameState.has_insight("I_LAPTOP") else "E09")
	_ask(deniz, "charge")
	ok(GameState.has_evidence("E12") and "T_AKTAS_2" not in GameState.testimony, "charging Deniz gets the laptop but not what she saw")
	_ask(deniz, "desk")
	ok("T_AKTAS_2" in GameState.testimony, "she tells it when asked directly, so the conclusion stays reachable")

	# Decisions from Case 1 change who helps.
	_open_case("case_02")
	GameState.set_flag("soykan_met")
	Profile.flags["case_01.erdem_spared"] = true
	Profile.flags["case_01.aydin_told"] = true
	_visit("site")
	_visit("newsroom")
	ok("T_ERDEM_TIP" in GameState.testimony, "sparing the guard in Case 1 earns his call in Case 2")
	ok("T_AYDIN_TIP" in GameState.testimony, "kindness to Leyla in Case 1 earns her call in Case 2")
	Profile.reset()
	_open_case("case_01")


# The whole of Case 3: the visitors, the poison, the three decisions.
func _test_case_03() -> void:
	Profile.reset()
	_open_case("case_03")
	print("- full playthrough")
	ok(not CaseDB.location_unlocked("institute"), "other places open after speaking to Hatice")
	ok(Hints.next("house").get("type") == "point", "hint points at evidence at the start")
	var hatice := _talk("hatice")
	_press(hatice, "found")
	_pick(hatice, "bye")
	_visit("house")
	for i in range(1, 9):
		ok(GameState.has_evidence("E0%d" % i), "house evidence E0%d collected" % i)
	ok(not ("T_GUVEN_TIP" in GameState.testimony), "no tip from Güven without the Case 2 decision")
	ok(_look_up_all() == 2, "the caller and the parking ticket can be looked up after the house")
	ok(_look_up_all() == 1 and GameState.has_evidence("E24"), "Bulut's calls can be looked up once the caller is known")
	ok(not GameState.has_evidence("E22"), "the pharmacy cannot be searched before the cause of death is known")
	hatice = _talk("hatice")
	_press(hatice, "call")
	ok(not _confront(hatice, "monday", "E07"), "Hatice: unrelated card rejected")
	ok(_confront(hatice, "monday", "E24"), "Hatice: the call record makes her say whom she told")
	_ask(hatice, "comfort")
	ok(GameState.has_flag("hatice_comforted") and "T_HATICE_4" in GameState.testimony, "decision about Hatice recorded")
	ok("monday" not in hatice.choices().map(func(c): return c["id"]), "the question is not offered again")
	_ask(hatice, "cem")
	_pick(hatice, "bye")
	var cem := _talk("cem")
	_press(cem, "where")
	ok(_confront(cem, "where", "E23"), "Cem: the parking ticket breaks his alibi")
	_press(cem, "money")
	_ask(cem, "father")
	_pick(cem, "bye")

	_visit("institute")
	for id in ["E09", "E10", "E11", "E12"]:
		ok(GameState.has_evidence(id), "institute evidence %s collected" % id)
	ok(not GameState.has_evidence("E13"), "file 12-C is not lying about")
	ok(_look_up_all() == 1 and GameState.has_evidence("E22"), "the pharmacy can be searched after the autopsy")
	var nur := _talk("nur")
	_ask(nur, "cause")
	_press(nur, "saw")
	ok(_confront(nur, "saw", "E06"), "Nur: the diary makes him admit the visit")
	ok(GameState.has_evidence("E13") and GameState.has_flag("file_found"), "Nur hands over his copy of 12-C")
	_ask(nur, "trust")
	ok(GameState.has_flag("nur_trusted") and "T_NUR_3" in GameState.testimony and not GameState.has_flag("file_compromised"), "trusting Nur keeps the file safe")
	_press(nur, "ampoule")
	_ask(nur, "y1999")
	_pick(nur, "bye")
	hatice = _talk("hatice")
	_press(hatice, "y1999")
	_pick(hatice, "bye")

	_visit("records")
	ok(GameState.has_evidence("E18") and GameState.has_evidence("E19"), "records room evidence collected")
	var chief := _talk("soykan")
	_press(chief, "report")
	ok(_confront(chief, "report", "E18"), "the chief: the register answers the flood")
	_ask(chief, "notes")
	_ask(chief, "hold")
	ok(GameState.has_flag("chief_kept_out"), "decision: the chief does not get the notes")
	ok("notes" not in chief.choices().map(func(c): return c["id"]), "the decision is only offered once")
	_press(chief, "nur")
	_pick(chief, "bye")

	_visit("harbour")
	for id in ["E14", "E15", "E16", "E17"]:
		ok(GameState.has_evidence(id), "harbour evidence %s collected" % id)
	ok(not GameState.has_evidence("E16X"), "the stove was not cleaned out")
	_connect_all()
	for id in CaseDB.insights:
		ok(GameState.has_insight(id), "conclusion %s can be reached" % id)
	var bulut := _talk("bulut")
	_press(bulut, "evening")
	ok(not _confront(bulut, "evening", "E14"), "Bulut: the slate alone is not enough")
	ok(_confront(bulut, "evening", "I_VISIT"), "Bulut: slate and mast together break his alibi")
	_press(bulut, "door")
	ok(_confront(bulut, "door", "I_CALLER"), "Bulut: the call corners him")
	ok(GameState.has_flag("bulut_cornered"), "Bulut asks for Karaca")
	_press(bulut, "tablets")
	ok(_confront(bulut, "tablets", "I_DEAD_WIFE"), "Bulut: the prescription")
	_press(bulut, "payments")
	_ask(bulut, "y1999")
	_pick(bulut, "bye")

	for id in CaseDB.countable_evidence():
		ok(GameState.has_evidence(id), "evidence %s was found on the main path" % id)
	for id in CaseDB.meta["testimony"]:
		if id != "T_GUVEN_TIP":
			ok(id in GameState.testimony, "statement %s was recorded on the main path" % id)

	print("- verdicts")
	var proof := {"motive": "I_MOTIVE", "opportunity": "I_VISIT", "link": "I_POISON"}
	ok(Verdict.resolve(Verdict.ACCIDENT, {}) == "E", "natural causes -> ending E")
	ok(Verdict.resolve("nur", proof) == "C", "accusing Dr. Nur -> ending C")
	ok(Verdict.resolve("cem", proof) == "D" and Verdict.resolve("hatice", proof) == "D", "family -> ending D")
	ok(Verdict.resolve("bulut", {"motive": "I_MOTIVE", "link": "I_POISON"}) == "B", "one proof missing -> ending B")
	ok(Verdict.resolve("bulut", {"motive": "I_MOTIVE", "opportunity": "I_FISH", "link": "I_BLISTER"}) == "A", "the alternative conclusions count")
	ok(Verdict.resolve("bulut", proof) == "A", "full proof and the file -> ending A")
	ok(Verdict.epilogue("A").size() == 4, "true ending has an epilogue line for each decision and the signature")
	_test_wall_layout("Case 3")
	GameState.set_flag("case_solved")
	for o in CaseDB.meta["objectives"]:
		ok(GameState.check(o.get("show", [])) and GameState.check(o["done"]), "objective %s is complete at the end" % o["id"])
	ok(Hints.next(GameState.location).is_empty(), "no hints remain when the case is solved")
	var rating := Verdict.rating()
	ok(rating["evidence"] == rating["evidence_total"] and rating["insights"] == rating["insights_total"], "rating counts everything found")
	var carried: Array = []
	for flag in CaseDB.endings["carry"]:
		if GameState.has_flag(flag):
			carried.append(flag)
	Profile.record_verdict("case_03", "A", true, rating, carried)
	var earned := Achievements.evaluate("A")
	for id in ["C3_SOLVED", "C3_CORNERED", "C3_NUR_CLEAR", "C3_SIGNATURE", "C3_QUIET"]:
		ok(id in earned or Profile.achievements.has(id), "achievement %s earned on the main path" % id)
	ok(Profile.has_flag("case_03.nur_trusted") and Profile.has_flag("case_03.chief_kept_out"), "Case 3 decisions are carried forward")

	print("- alternative branches")
	# Reporting Nur sends the copy through the chief's office.
	_open_case("case_03")
	GameState.set_flag("hatice_met")
	_visit("house")
	_visit("institute")
	nur = _talk("nur")
	_confront(nur, "saw", "E06")
	_ask(nur, "report")
	ok(GameState.has_flag("file_compromised") and "T_NUR_3" not in GameState.testimony, "reporting Nur costs the file its safety")
	for id in CaseDB.insights:
		GameState.insights.append(id)
	ok(Verdict.resolve("bulut", proof) == "B", "with the file compromised the best verdict is ending B")

	# Sending the chief the notes gets the stove cleaned out, but the case stays solvable.
	_open_case("case_03")
	GameState.set_flag("hatice_met")
	_visit("house")
	_visit("institute")
	_visit("records")
	chief = _talk("soykan")
	_ask(chief, "notes")
	_ask(chief, "inform")
	_visit("harbour")
	ok(GameState.has_evidence("E16X") and not GameState.has_evidence("E16"), "the blister packs are ash when the chief was told")
	nur = _talk("nur")
	_confront(nur, "saw", "E06")
	_ask(nur, "trust")
	_look_up_all()
	_look_up_all()
	_connect_all()
	ok(not GameState.has_insight("I_BLISTER") and GameState.has_insight("I_POISON"), "the pharmacy record still links the tablets")
	ok(Verdict.resolve("bulut", proof) == "A", "the case stays fully solvable")

	# The Case 2 decision about Güven brings a name.
	_open_case("case_03")
	Profile.flags["case_02.guven_protected"] = true
	_visit("house")
	ok("T_GUVEN_TIP" in GameState.testimony, "protecting Güven in Case 2 earns his statement in Case 3")
	Profile.reset()
	_open_case("case_01")


# The whole of Case 4, the finale.
func _test_case_04() -> void:
	Profile.reset()
	_open_case("case_04")
	print("- full playthrough")
	ok(not CaseDB.location_unlocked("lawoffice"), "other places open after speaking to the prosecutor")
	var arikan := _talk("arikan")
	_press(arikan, "knew")
	_ask(arikan, "report")
	_ask(arikan, "her")
	_pick(arikan, "bye")
	_visit("prison")
	for i in range(1, 7):
		ok(GameState.has_evidence("E0%d" % i), "prison evidence E0%d collected" % i)
	ok(not ("T_NUR_TIP" in GameState.testimony), "no message from Dr. Nur without the Case 3 decision")
	ok(_look_up_all() == 3, "three searches open after the visiting block")
	ok(not CaseDB.location_unlocked("lighthouse"), "the lighthouse is not on the map yet")
	_connect_all()
	var yildiz := _talk("yildiz")
	_press(yildiz, "fall")
	ok(_confront(yildiz, "fall", "I_NOT_FALL"), "Yıldız: the injuries break his report")
	_press(yildiz, "alone")
	ok(_confront(yildiz, "alone", "I_ALONE"), "Yıldız: the call breaks him")
	_ask(yildiz, "deal")
	ok("T_YILDIZ_3" in GameState.testimony and GameState.has_flag("yildiz_deal"), "the deal gets the voice on the telephone")
	_press(yildiz, "camera")
	_pick(yildiz, "bye")

	_visit("lawoffice")
	for id in ["E07", "E08", "E09", "E10"]:
		ok(GameState.has_evidence(id), "law office evidence %s collected" % id)
	ok(_look_up_all() == 1 and GameState.has_evidence("E23"), "the bank can be searched after the agreement")
	_connect_all()
	ok(CaseDB.location_unlocked("lighthouse"), "letter and key board put the lighthouse on the map")
	_visit("chief")
	for id in ["E11", "E12", "E13"]:
		ok(GameState.has_evidence(id), "chief's office evidence %s collected" % id)
	_connect_all()
	var chief := _talk("soykan")
	_press(chief, "where")
	ok(_confront(chief, "where", "I_PRESENT"), "the chief: the visitors' book breaks his alibi")
	_ask(chief, "notes")
	_ask(chief, "hold")
	ok(GameState.has_flag("chief_kept_out"), "decision: the chief is told nothing")
	_press(chief, "order")
	_pick(chief, "bye")
	_visit("lawoffice")
	var karaca := _talk("karaca")
	_press(karaca, "visit")
	_press(karaca, "fener")
	ok(_confront(karaca, "fener", "I_COMMITTEE"), "Karaca: the committee")
	_press(karaca, "evening")
	_pick(karaca, "bye")
	var aras := _talk("aras")
	_press(aras, "fener")
	ok(_confront(aras, "fener", "E12"), "Aras: the photograph")
	_ask(aras, "hold")
	ok(GameState.has_flag("aras_held"), "decision about Aras recorded")
	_pick(aras, "bye")

	_visit("lighthouse")
	for id in ["E14", "E15", "E16", "E17"]:
		ok(GameState.has_evidence(id), "lighthouse evidence %s collected" % id)
	ok(GameState.has_flag("file_found") and not GameState.has_evidence("E14X"), "the ledger is intact")
	_connect_all()
	for id in CaseDB.insights:
		ok(GameState.has_insight(id), "conclusion %s can be reached" % id)
	for id in CaseDB.countable_evidence():
		ok(GameState.has_evidence(id), "evidence %s was found on the main path" % id)
	for id in CaseDB.meta["testimony"]:
		if id != "T_NUR_TIP":
			ok(id in GameState.testimony, "statement %s was recorded on the main path" % id)

	print("- verdicts")
	var proof := {"motive": "I_MOTIVE", "opportunity": "I_PRESENT", "link": "I_BLIND"}
	ok(Verdict.resolve(Verdict.ACCIDENT, {}) == "E", "she fell -> ending E")
	ok(Verdict.resolve("karaca", proof) == "C", "Karaca takes the fall -> ending C")
	ok(Verdict.resolve("yildiz", proof) == "D" and Verdict.resolve("aras", proof) == "D", "the hand or the payer -> ending D")
	ok(Verdict.resolve("soykan", {"motive": "I_MOTIVE", "link": "I_BLIND"}) == "B", "one proof missing -> ending B")
	ok(Verdict.resolve("soykan", {"motive": "I_AUTHORISED", "opportunity": "I_PRESENT", "link": "I_ALONE"}) == "A", "the alternative conclusions count")
	ok(Verdict.resolve("soykan", proof) == "A", "full proof and the ledger -> ending A")
	ok(Verdict.epilogue("A").size() == 3, "the true ending has a line for each decision")
	_test_wall_layout("Case 4")
	GameState.set_flag("case_solved")
	for o in CaseDB.meta["objectives"]:
		ok(GameState.check(o.get("show", [])) and GameState.check(o["done"]), "objective %s is complete at the end" % o["id"])
	ok(Hints.next(GameState.location).is_empty(), "no hints remain when the case is solved")
	var rating := Verdict.rating()
	ok(rating["evidence"] == rating["evidence_total"] and rating["insights"] == rating["insights_total"], "rating counts everything found")
	Profile.flags["case_01.file_found"] = true
	Profile.flags["case_02.file_found"] = true
	Profile.flags["case_03.file_found"] = true
	Profile.record_verdict("case_04", "A", true, rating, ["file_found"])
	var earned := Achievements.evaluate("A")
	for id in ["C4_SOLVED", "C4_DEAL", "C4_GREEN", "SEASON"]:
		ok(id in earned or Profile.achievements.has(id), "achievement %s earned on the main path" % id)

	print("- alternative branches")
	# Telling the chief where you are going costs the ledger, not the case.
	_open_case("case_04")
	GameState.set_flag("arikan_met")
	_visit("prison")
	_visit("lawoffice")
	_visit("chief")
	chief = _talk("soykan")
	_ask(chief, "notes")
	_ask(chief, "inform")
	_look_up_all()
	_connect_all()
	_visit("lighthouse")
	ok(GameState.has_evidence("E14X") and not GameState.has_evidence("E14") and GameState.has_flag("ledger_burnt"), "the ledger is ash when the chief was told")
	ok(GameState.has_evidence("E15"), "the torn page survives in the lamp housing")
	_connect_all()
	ok(GameState.has_insight("I_MOTIVE") and not GameState.has_insight("I_AUTHORISED"), "the motive can still be shown")
	ok(Verdict.resolve("soykan", proof) == "B", "with the ledger burnt the best verdict is ending B")

	# Threatening Yıldız loses his statement only.
	_open_case("case_04")
	GameState.set_flag("arikan_met")
	_visit("prison")
	_look_up_all()
	_connect_all()
	yildiz = _talk("yildiz")
	_confront(yildiz, "fall", "E02")
	_confront(yildiz, "alone", "E21")
	_ask(yildiz, "threat")
	ok(GameState.has_flag("yildiz_threatened") and "T_YILDIZ_3" not in GameState.testimony, "threatening Yıldız loses the voice on the telephone")

	# The Case 3 decision about Dr. Nur brings his message.
	_open_case("case_04")
	Profile.flags["case_03.nur_trusted"] = true
	_visit("prison")
	ok("T_NUR_TIP" in GameState.testimony, "trusting Dr. Nur in Case 3 earns his message in Case 4")
	Profile.reset()
	_open_case("case_01")


# Board 2.0: questions, the drawer, key facts, nudges and the proof bar.
func _test_board2() -> void:
	print("- board 2.0")
	var open := Hints.open_questions()
	ok(open.size() == Hints.link_count(), "one open question for every connection that can be made")
	for id in open:
		var f := Hints.focus_cards(id)
		ok(f.size() >= 2 and f.size() <= 5, "a question lights up between two and five cards")
		for c in CaseDB.insights[id]["cards"]:
			ok(c in f, "the question %s lights up its own cards" % id)
			ok(Hints.card_live(c), "cards of an open question stay on the wall")
		var a: String = CaseDB.insights[id]["cards"][0]
		var b: String = CaseDB.insights[id]["cards"][1]
		ok(b in Hints.key_matches(a), "the two cards of %s share a key fact" % id)
	ok(not Hints.card_live("E06"), "a card with nothing left to connect goes into the drawer")
	ok(not BoardLayout.positions(false).has("E06") and BoardLayout.positions(true).has("E06"), "the drawer hides it from the wall until opened")
	ok(BoardLayout.positions(false, ["E06"]).has("E06"), "a card can be kept on the wall")
	TranslationServer.set_locale("en")
	var n := Deduction.nudge("E06", "E03")
	ok(n.begins_with("The") or n.begins_with("Close"), "a finished card with one still open: not cold (%s)" % n)
	ok(Deduction.nudge("E06", "I_VARDAR_RETURNED") != "" , "nudge always says something")
	var warm := Deduction.nudge("E02", "E03")
	ok(warm.begins_with("Close") or warm.begins_with("The"), "a card with a connection left: warm (%s)" % warm)
	var parts := Hints.proof_progress()
	ok(parts.size() == 3, "the proof bar has three parts")


# Decision trees: every case has one, texts exist, and a verdict records a route.
func _test_decision_tree() -> void:
	Profile.reset()
	for entry in CaseDB.index:
		if not entry.get("available", false):
			continue
		_open_case(entry["id"])
		var all := DecisionTree.nodes(entry["id"])
		ok(all.size() >= 4, "%s has decision points" % entry["id"])
		for n in all:
			_key(n["title"], "tree title")
			ok(n["options"].size() >= 2, "decision %s has at least two outcomes" % n["id"])
			for o in n["options"]:
				_key(o["text"], "tree outcome")
		var route := DecisionTree.taken("E")
		ok(route.size() == all.size(), "%s: exactly one outcome per decision at the start" % entry["id"])
		DecisionTree.record("E")
		ok(Profile.tree[entry["id"]].size() == all.size() and Profile.tree_last[entry["id"]] == route, "the route is remembered")
	_open_case("case_03")
	GameState.set_flag("nur_trusted")
	DecisionTree.record("A")
	ok("nur.trusted" in Profile.tree["case_03"] and "nur.open" in Profile.tree["case_03"], "routes found in earlier attempts stay revealed")
	ok("nur.reported" not in Profile.tree["case_03"], "a route never taken stays hidden")
	ok("nur.trusted" in Profile.tree_last["case_03"] and "nur.open" not in Profile.tree_last["case_03"], "only the last route is highlighted")
	Profile.reset()
	_open_case("case_01")


## The automatic layout of the evidence wall for the cards held right now:
## every card has a place, nothing overlaps, everything is on the wall, and a
## note the player has moved stays where they put it.
func _test_wall_layout(label: String) -> void:
	GameState.board_layout = {}
	var pos := BoardLayout.positions()
	var size := BoardLayout.canvas_size()
	var held := GameState.all_cards()
	ok(pos.size() == held.size(), "%s wall: every card has a note (%d of %d)" % [label, pos.size(), held.size()])
	var rects := {}
	for id in pos:
		rects[id] = Rect2(pos[id], BoardLayout.note_size(id))
		ok(Rect2(Vector2.ZERO, size).encloses(rects[id]), "%s wall: note %s is on the wall" % [label, id])
	var ids: Array = rects.keys()
	var overlaps := 0
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if rects[ids[i]].intersects(rects[ids[j]]):
				overlaps += 1
	ok(overlaps == 0, "%s wall: no notes overlap (%d overlaps)" % [label, overlaps])
	var moved: String = held[0]
	GameState.board_layout = {moved: [777.0, 555.0]}
	ok(BoardLayout.positions()[moved] == Vector2(777, 555), "%s wall: a moved note keeps its place" % label)
	GameState.board_layout = {}


# The office: what is carried out of the cases, the Ledger wall, the mementos.
func _test_office() -> void:
	Profile.reset()
	_open_case("office")
	print("- carried cards and the Ledger wall")
	ok(CaseDB.case_entry("office").is_empty(), "the office is not in the case list")
	ok(CaseDB.endings["suspects"].is_empty(), "nobody can be accused from the office")
	_visit("office")
	ok(GameState.evidence.is_empty(), "the wall is empty before any case has been closed")
	ok(Hints.current_objective().get("id") == "O_C1", "the office points at the first case")
	var props: Array = CaseDB.locations["office"]["props"]
	ok(props.filter(func(p): return GameState.check(p["conditions"])).is_empty(), "the shelf is empty at the start")

	# Case 1 closed with the file found (any verdict).
	Profile.record_verdict("case_01", "B", false, {"score": 40, "grade": "C"}, ["file_found", "erdem_spared"])
	ok(Profile.has_flag("case_01.file_found"), "what was found is carried out of a case even after a weak verdict")
	_visit("office")
	ok(GameState.has_evidence("L01") and GameState.has_evidence("L02"), "the routing slip and the torn page arrive from File 47-B")
	ok(not GameState.has_evidence("L03"), "nothing from File 58-D yet")
	ok(Hints.link_count() == 0, "one case alone connects to nothing")
	ok(props.filter(func(p): return GameState.check(p["conditions"])).size() == 1, "one memento after the first case")

	# Case 2 solved with everything.
	Profile.record_verdict("case_02", "A", true, {"score": 90, "grade": "S"}, ["file_found", "registry_seen", "guven_source", "soykan_remark", "kaplan_free"])
	Profile.record_verdict("case_03", "A", true, {"score": 90, "grade": "S"}, ["file_found", "register_seen", "nur_trusted"])
	_visit("office")
	for id in CaseDB.evidence:
		ok(GameState.has_evidence(id), "card %s arrives on the wall" % id)
	ok(Hints.link_count() == CaseDB.insights.size(), "every Ledger connection is possible with both cases closed")
	ok(_connect_all() == CaseDB.insights.size(), "all Ledger conclusions can be reached")
	ok("LEDGER_WALL" in Achievements.evaluate() or Profile.achievements.has("LEDGER_WALL"), "Ledger achievement earned")
	_test_wall_layout("Ledger")
	ok(Profile.achievements.has("LEDGER_CHIEF"), "hidden achievement for noticing the chief")
	ok(Hints.current_objective().get("id") == "O_C4", "the office points at the last case")
	ok(props.filter(func(p): return GameState.check(p["conditions"])).size() == 4, "four mementos: both cases, the front page and the promotion")

	# Missing pieces stay missing: no file in Case 1, so no slip on the wall.
	Profile.reset()
	Profile.record_verdict("case_01", "B", false, {"score": 20, "grade": "C"}, [])
	_open_case("office")
	_visit("office")
	ok(not GameState.has_evidence("L01"), "without the file there is no routing slip to carry")

	# A later verdict replaces what an earlier one carried.
	Profile.set_carried("case_01", ["file_found"])
	ok(Profile.has_flag("case_01.file_found"), "carried decisions can be refreshed from a save")
	Profile.set_carried("case_01", [])
	ok(not Profile.has_flag("case_01.file_found"), "and cleared")
	Profile.reset()
	_open_case("case_01")


# Pressing statements and running out of patience.
func _test_interrogation() -> void:
	print("- interrogation: press and patience")
	var keep := GameState.to_dict().duplicate(true)
	GameState.new_game()
	GameState.active = false
	GameState.set_flag("erdem_met")
	GameState.add_evidence("E04")
	GameState.add_evidence("E01")
	var r := _talk("erdem")
	var s := _pick(r, "patrol")
	while not r.can_present() and s == DialogueRunner.LINE:
		s = r.advance()
	ok(r.can_press() and r.can_present(), "the patrol statement can be pressed and challenged")
	ok(not r.holds_answer(), "Present does not glow when the player holds nothing that fits")
	ok(r.challenged_line()["t"] == r.line()["t"], "the picker quotes the statement on screen")
	var statement: String = r.line()["t"]
	s = r.press()
	ok(s == DialogueRunner.LINE and r.line()["t"] != statement, "pressing plays the follow-up")
	var shown: Array = []
	var last_follow_up := false
	while s == DialogueRunner.LINE and r.node_id == "press_patrol":
		shown.append(r.line()["t"])
		last_follow_up = r.can_present()
		s = r.advance()
	ok(last_follow_up, "the statement can still be challenged on the last line of the follow-up")
	ok(statement not in shown, "the pressed statement is not repeated")
	ok(s == DialogueRunner.CHOICES and r.node_id == "hub", "after the follow-up the conversation carries on")
	s = _pick(r, "patrol")
	while not r.can_present() and s == DialogueRunner.LINE:
		s = r.advance()

	var full := GameState.patience_left("erdem")
	ok(full == 3, "Erdem starts with full patience")
	ok(not r.present("E01"), "unrelated card rejected")
	ok(GameState.patience_left("erdem") == full - 1, "a careless challenge costs patience")
	for i in full - 1:
		_advance_to_choices(r, DialogueRunner.LINE)
		_confront(r, "patrol", "E01")
	ok(GameState.patience_left("erdem") == 0, "patience can run out")
	ok(r.node_id == "closed", "out of patience: the person ends the conversation")
	var r2 := DialogueRunner.new("erdem")
	r2.start()
	ok(r2.node_id == "closed" and r2.advance() == DialogueRunner.END, "they refuse to talk until something changes")
	GameState.add_evidence("E05")
	ok(GameState.patience_left("erdem") == full, "learning something new restores patience")
	var glow := _talk("erdem")
	var gs := _pick(glow, "patrol")
	while not glow.can_present() and gs == DialogueRunner.LINE:
		gs = glow.advance()
	ok(glow.holds_answer(), "Present glows once the player holds the card that fits")
	var said: String = glow.line()["t"]
	glow.press()
	while glow.line_index != glow.node().get("lines", []).size() - 1:
		glow.advance()
	ok(glow.challenged_line()["t"] == said, "after pressing, the picker still quotes the original statement")
	r2 = _talk("erdem")
	s = _pick(r2, "patrol")
	while not r2.can_press() and s == DialogueRunner.LINE:
		s = r2.advance()
	r2.press()
	while r2.line_index != r2.node().get("lines", []).size() - 1:
		r2.advance()
	ok(r2.present("E05") and GameState.has_flag("erdem_confessed"), "challenging from the follow-up works, and the case stays solvable after running out of patience")
	for ch in CaseDB.dialogues:
		ok(CaseDB.dialogues[ch].has("closed"), "%s has a line for when patience runs out" % ch)

	for i in 5:
		GameState.mark_seen("x.press.%d" % i)
	var r3 := _talk("erdem")
	_ask(r3, "vural")
	s = _pick(r3, "vural")
	while not r3.can_press() and s == DialogueRunner.LINE:
		s = r3.advance()
	r3.press()
	ok(GameState.has_flag("pressed_five"), "pressing five statements is recorded")
	GameState.from_dict(keep)
	GameState.active = false


# Ranks, experience, achievements and decisions carried between cases.
func _test_career() -> void:
	print("- career, achievements, case list")
	Profile.reset()
	var ranks: Array = CaseDB.career["ranks"]
	ok(ranks.size() >= 4 and int(ranks[0]["xp"]) == 0, "career has ranks starting at 0 XP")
	for i in ranks.size():
		_key(ranks[i]["name"], "rank")
		if i > 0:
			ok(int(ranks[i]["xp"]) > int(ranks[i - 1]["xp"]), "rank thresholds increase")
	ok(Profile.rank()["id"] == ranks[0]["id"] and Profile.xp() == 0, "a new detective starts at the first rank")

	var ids := {}
	for a in CaseDB.achievements:
		ok(not ids.has(a["id"]), "duplicate achievement " + a["id"])
		ids[a["id"]] = true
		_key(a["title"], "achievement " + a["id"])
		_key(a["desc"], "achievement " + a["id"])
		ok(FileAccess.file_exists("res://data/cases/%s/case.json" % a.get("case", "")), "achievement %s: unknown case" % a["id"])
	for key in ["ACH_SECRET_TITLE", "ACH_SECRET_DESC", "CASES_NUMBER"]:
		ok(Loc.has_key(key), "missing text " + key)

	ok(CaseDB.index.size() >= 4, "the season lists four cases")
	for entry in CaseDB.index:
		_key(entry["title"], "case index " + entry["id"])
		_check_conditions(entry.get("unlock", []), "case index " + entry["id"])
		if entry.get("available", false):
			ok(FileAccess.file_exists("res://data/cases/%s/case.json" % entry["id"]), "case data missing for " + entry["id"])
			ok(entry["id"] in Loc.tables, "text table not loaded for " + entry["id"])
	ok(CaseDB.case_open("case_01"), "the first case is open from the start")
	ok(not CaseDB.case_open("case_02"), "Case 2 stays closed until Case 1 has a verdict")
	ok(not CaseDB.case_open("case_03"), "a case that is not in this build cannot be opened")

	# A wrong verdict earns nothing but is remembered.
	var res := Profile.record_verdict("case_01", "C", false, Verdict.rating(), [])
	ok(res["xp_gain"] == 0 and not Profile.is_solved("case_01"), "a wrong verdict gives no experience")
	ok(CaseDB.case_open("case_02"), "any verdict in Case 1, even a wrong one, opens Case 2")
	ok("OBVIOUS_MAN" in Achievements.evaluate("C"), "hidden achievement for arresting the deputy mayor")
	ok(Achievements.evaluate("C").is_empty(), "an achievement is only awarded once")

	# The solved state left by the full playthrough: true ending.
	var rating := Verdict.rating()
	ok(rating["score"] >= 0 and rating["score"] <= 100, "rating has a score from 0 to 100")
	res = Profile.record_verdict("case_01", "A", true, rating, ["erdem_spared", "aydin_told"])
	ok(res["xp_gain"] == rating["score"] and Profile.xp() == rating["score"], "solving a case awards its score as experience")
	ok(Profile.is_solved("case_01") and Profile.best["case_01"]["grade"] == rating["grade"], "best grade is stored")
	ok(GameState.check([{"case_solved": "case_01"}, {"profile_flag": "case_01.erdem_spared"}]), "decisions are carried forward for later cases")
	ok(not GameState.check([{"profile_flag": "case_01.erdem_reported"}]), "decisions not taken are not carried")
	var unlocked := Achievements.evaluate("A")
	for id in ["FIRST_CASE", "MIRROR", "CORNERED", "GENTLE", "CONFESSION", "MERCY"]:
		ok(id in unlocked or Profile.achievements.has(id), "achievement %s earned on the main path" % id)
	ok(not Profile.achievements.has("NO_HINTS") or GameState.hints == 0, "no-hint achievement respects hints used")
	ok(not Profile.achievements.has("EVERY_ENDING"), "all-endings achievement needs all five endings")
	for e in ["B", "D", "E"]:
		Profile.record_verdict("case_01", e, false, rating, [])
	ok("EVERY_ENDING" in Achievements.evaluate(""), "all-endings achievement after seeing every ending")

	# Replaying: a worse run does not lower the best, a different decision replaces the old one.
	var worse := rating.duplicate()
	worse["score"] = 10
	worse["grade"] = "C"
	res = Profile.record_verdict("case_01", "A", true, worse, ["erdem_reported"])
	ok(res["xp_gain"] == 0 and Profile.best["case_01"]["score"] == rating["score"], "a worse replay keeps the best score")
	ok(Profile.has_flag("case_01.erdem_reported") and not Profile.has_flag("case_01.erdem_spared"), "the latest solved run decides what is carried")
	var top := {"score": 100, "grade": "S"}
	Profile.best = {"case_01": top, "case_02": top, "case_03": top, "case_04": top}
	ok(Profile.rank()["id"] == ranks[-1]["id"] and Profile.next_rank().is_empty(), "four excellent cases reach the top rank")
	Profile.best = {"case_01": top}
	ok(Profile.rank_index() == 1, "one excellent case earns the first promotion")
	Profile.reset()


# A save made by version 1 (single file) must still open.
func _test_save_migration() -> void:
	print("- save migration from version 1")
	var old := SaveManager.OLD_PATH
	var target := SaveManager.path("case_01")
	if FileAccess.file_exists(old) or FileAccess.file_exists(target):
		print("  (skipped: real save files present)")
		return
	var state := GameState.to_dict()
	state.erase("patience")
	var f := FileAccess.open(old, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "state": state}))
	f.close()
	SaveManager.enabled = true
	SaveManager._migrate_v1()
	ok(not FileAccess.file_exists(old), "old save file is removed after migration")
	ok(SaveManager.has_save("case_01"), "old save is available as the Case 1 save")
	ok(Profile.last_case == "case_01", "Continue points at the migrated case")
	var evidence_before: int = GameState.evidence.size()
	GameState.new_game()
	GameState.active = false
	ok(SaveManager.load_game("case_01") and GameState.evidence.size() == evidence_before, "migrated save loads with its progress")
	GameState.active = false
	SaveManager.delete_save("case_01")
	ok(not SaveManager.has_save("case_01"), "test save cleaned up")
	SaveManager.enabled = false
	Profile.reset()


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
	ok(Hints.next("lobby").get("type") == "point", "hint points at evidence at the start")

	var r := DialogueRunner.new("erdem")
	var s := _advance_to_choices(r, r.start())
	ok(s == DialogueRunner.CHOICES, "intro should end at the topic list")
	var offered := r.choices().map(func(c): return c["id"])
	ok("patrol" not in offered, "patrol topic must need the patrol log")

	s = _advance_to_choices(r, _pick(r, "night"))
	s = _advance_to_choices(r, _pick(r, "night_firm"))
	ok("T_ERDEM_4" in GameState.testimony, "firm question records who was in the building")
	for id in ["E01", "E02", "E03", "E04", "E05", "E15"]:
		GameState.add_evidence(id)
	var h := Hints.next("lobby")
	ok(h.get("type") == "text" and Loc.has_key(h.get("text", "")), "hint explains the locked terminal")
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
	h = Hints.next("lobby")
	ok(h.get("type") == "point" and h["hotspot"]["id"] == "terminal", "hint points at the unlocked terminal")
	GameState.add_evidence("E06")
	ok(Hints.next("lobby").get("text") == "HINT_BOARD", "hint sends the player to the Board when cards can be connected")
	ok(CaseDB.location_evidence("lobby").size() == 7, "lobby has 7 pieces of evidence")

	var r2 := DialogueRunner.new("erdem")
	r2.start()
	ok(r2.node_id == "return", "second conversation uses the return greeting")


func _test_save_roundtrip() -> void:
	print("- save / load")
	GameState.board_layout = {"E01": [120.0, 340.0]}
	var before := GameState.to_dict()
	var text := JSON.stringify({"version": 1, "state": before})
	GameState.new_game()
	GameState.active = false
	ok(GameState.evidence.is_empty(), "new game clears evidence")
	GameState.from_dict(JSON.parse_string(text)["state"])
	GameState.active = false
	var after := GameState.to_dict()
	ok(JSON.stringify(before) == JSON.stringify(after), "state survives save and load")
