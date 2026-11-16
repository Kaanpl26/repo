class_name Verdict
## Decides how an accusation ends and how the investigation is rated. No UI.
##
## endings.json:
##   "culprit": "vardar", "suspects": [...], "slots": ["motive", "opportunity", "link"],
##   "proof": {"vardar": {"motive": [card ids], "opportunity": [...], "link": [...]}},
##   "full": "A", "partial": "B", "accident": "E", "wrong": {"aras": "C", ...},
##   "spoiled_flag": flag that downgrades a full win, "endings": {"A": {"title", "text", "solved"}}

const ACCIDENT := "accident"


static func slot_ok(suspect: String, slot: String, card: String) -> bool:
	var proof: Dictionary = CaseDB.endings["proof"].get(suspect, {})
	return card != "" and card in proof.get(slot, [])


## suspect: a character id or ACCIDENT. slots: {"motive": card id or "", ...}
static func resolve(suspect: String, slots: Dictionary) -> String:
	var e: Dictionary = CaseDB.endings
	if suspect == ACCIDENT:
		return e["accident"]
	if suspect != e["culprit"]:
		return e["wrong"][suspect]
	for slot in e["slots"]:
		if not slot_ok(suspect, slot, slots.get(slot, "")):
			return e["partial"]
	if GameState.has_flag(e["spoiled_flag"]) or not GameState.check(e.get("full_requires", [])):
		return e["partial"]
	return e["full"]


## For an accusation against the right person that fell short: which parts of
## the case were weak. Returns text keys.
static func weak_points(suspect: String, slots: Dictionary) -> Array:
	var e: Dictionary = CaseDB.endings
	var out: Array = []
	if suspect != e["culprit"]:
		return out
	for slot in e["slots"]:
		if not slot_ok(suspect, slot, slots.get(slot, "")):
			out.append("WEAK_" + slot.to_upper())
	if GameState.has_flag(e["spoiled_flag"]):
		out.append("WEAK_FILE_DAMAGED")
	elif not GameState.check(e.get("full_requires", [])):
		out.append("WEAK_FILE_MISSING")
	return out


## Extra closing lines that depend on the player's earlier decisions.
static func epilogue(ending_id: String) -> Array:
	var out: Array = []
	for line in CaseDB.endings["endings"][ending_id].get("epilogue", []):
		if GameState.check(line.get("conditions", [])):
			out.append(line["text"])
	return out


static func rating() -> Dictionary:
	var ev_total := CaseDB.countable_evidence().size()
	var in_total := CaseDB.insights.size()
	var ev := mini(GameState.evidence.size(), ev_total)
	var ins := GameState.insights.size()
	var score := 50.0 * ev / maxi(1, ev_total) + 50.0 * ins / maxi(1, in_total)
	score -= 5.0 * GameState.mistakes + 4.0 * GameState.hints + 2.0 * mini(GameState.bad_links, 10)
	var grade := "C"
	if score >= 90.0:
		grade = "S"
	elif score >= 75.0:
		grade = "A"
	elif score >= 55.0:
		grade = "B"
	return {
		"score": int(clampf(round(score), 0.0, 100.0)), "grade": grade, "evidence": ev, "evidence_total": ev_total, "insights": ins,
		"insights_total": in_total, "mistakes": GameState.mistakes + GameState.bad_links, "hints": GameState.hints,
	}
