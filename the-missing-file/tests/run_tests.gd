extends Node
## Automated checks. Run with:
##   godot --headless --path . res://tests/run_tests.tscn
## Exits with code 0 when everything passes, 1 otherwise.

var _fails := 0
var _checks := 0


func _ready() -> void:
	Profile.persist = false      # never touch the player's real profile
	Profile.reset()
	_test_scripts_load()
	_test_localization()
	_test_data_references()
	_test_dialogue_graph()
	_test_case_structure()
	_test_playthrough()
	_test_board_and_verdict()
	_test_interrogation()
	_test_career()
	_test_save_roundtrip()
	_test_save_migration()
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
		_check_effects(e.get("effects", []), "evidence " + id)
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
		_check_conditions(l.get("unlock", []), "location %s unlock" % id)
		if l.get("ambience", "") != "":
			ok(ResourceLoader.exists("res://assets/audio/%s.wav" % l["ambience"]), "location %s: ambience sound missing" % id)
		if l.has("on_enter"):
			_check_effects(l["on_enter"].get("effects", []), "location %s on_enter" % id)
			if l["on_enter"].has("caption"):
				_key(l["on_enter"]["caption"], "location %s on_enter" % id)
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
				_:
					ok(false, w + ": unknown type")
	for id in CaseDB.evidence:
		ok(placed.has(id), "evidence %s cannot be found anywhere" % id)


func _check_conditions(list: Array, where: String) -> void:
	for c in list:
		for k in c:
			ok(k in ["has_evidence", "no_evidence", "flag", "not_flag", "has_insight", "no_insight", "has_testimony", "profile_flag", "case_solved"], where + ": unknown condition " + k)
			if k == "case_solved":
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

	# every statement must be recorded by some dialogue
	var granted := {}
	for ch in CaseDB.dialogues:
		for id in CaseDB.dialogues[ch]["nodes"]:
			var n: Dictionary = CaseDB.dialogues[ch]["nodes"][id]
			var lists: Array = [n.get("effects", [])]
			for l in n.get("lines", []):
				lists.append(l.get("effects", []))
			for c in n.get("choices", []):
				lists.append(c.get("effects", []))
			for list in lists:
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
		_check_effects(d.get("effects", []), w)
		ok(CaseDB.card_title(id) != "" and ResourceLoader.exists(CaseDB.card_icon(id)), w + ": card info")

	var e: Dictionary = CaseDB.endings
	ok(e["culprit"] in e["suspects"], "culprit must be a suspect")
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
		for card in e["proof"][e["culprit"]].get(slot, []):
			ok(CaseDB.card_kind(card) != "", "proof uses unknown card " + card)
	_check_conditions(e.get("full_requires", []), "endings full_requires")
	for id in e["endings"]:
		for line in e["endings"][id].get("epilogue", []):
			_key(line["text"], "epilogue " + id)
			_check_conditions(line.get("conditions", []), "epilogue " + id)
	for id in [e["full"], e["partial"], e["accident"]] + e["wrong"].values():
		ok(e["endings"].has(id), "ending %s is not defined" % id)
	for id in e["endings"]:
		_key(e["endings"][id]["title"], "ending " + id)
		_key(e["endings"][id]["text"], "ending " + id)

	var rx := RegEx.new()
	rx.compile("^[0-2][0-9]:[0-5][0-9]$")
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
		GameState.apply(CaseDB.locations[location_id].get("on_enter", {}).get("effects", []))
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
	ok(opts.size() == 3 and CaseDB.insights["I_VARDAR_RETURNED"]["text"] in opts, "three possible conclusions offered")
	var m := GameState.mistakes
	ok(not Deduction.confirm("I_VARDAR_RETURNED", CaseDB.insights["I_VARDAR_RETURNED"]["wrong"][0]), "wrong conclusion rejected")
	ok(GameState.mistakes == m + 1 and not GameState.has_insight("I_VARDAR_RETURNED"), "wrong conclusion costs a mistake")
	ok(Deduction.confirm("I_VARDAR_RETURNED", CaseDB.insights["I_VARDAR_RETURNED"]["text"]), "right conclusion accepted")
	ok(Deduction.try_link("E02", "E06")["status"] == Deduction.KNOWN, "same connection is not offered twice")
	ok(Verdict.resolve("vardar", {"opportunity": "I_VARDAR_RETURNED"}) == "B", "culprit with only one proof -> ending B")

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
		_check_conditions(a.get("conditions", []), "achievement " + a["id"])
		if a.has("ending"):
			ok(CaseDB.endings["endings"].has(a["ending"]), "achievement %s: unknown ending" % a["id"])
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
	ok(not CaseDB.case_open("case_02"), "a case that is not in this build cannot be opened")
	for flag in CaseDB.endings.get("carry", []):
		ok(typeof(flag) == TYPE_STRING, "carried flags are names")

	# A wrong verdict earns nothing but is remembered.
	var res := Profile.record_verdict("case_01", "C", false, Verdict.rating(), [])
	ok(res["xp_gain"] == 0 and not Profile.is_solved("case_01"), "a wrong verdict gives no experience")
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
	var before := GameState.to_dict()
	var text := JSON.stringify({"version": 1, "state": before})
	GameState.new_game()
	GameState.active = false
	ok(GameState.evidence.is_empty(), "new game clears evidence")
	GameState.from_dict(JSON.parse_string(text)["state"])
	GameState.active = false
	var after := GameState.to_dict()
	ok(JSON.stringify(before) == JSON.stringify(after), "state survives save and load")
