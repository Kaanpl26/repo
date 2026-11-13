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
	if GameState.has_flag(e["spoiled_flag"]):
		return e["partial"]
	return e["full"]


static func rating() -> Dictionary:
	var ev_total := CaseDB.evidence.size()
	var in_total := CaseDB.insights.size()
	var ev := GameState.evidence.size()
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
		"grade": grade, "evidence": ev, "evidence_total": ev_total, "insights": ins,
		"insights_total": in_total, "mistakes": GameState.mistakes + GameState.bad_links, "hints": GameState.hints,
	}
