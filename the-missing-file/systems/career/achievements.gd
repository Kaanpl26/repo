class_name Achievements
## Checks which achievements the player has just earned. No UI.
##
## achievements.json: [{"id", "title", "desc", "hidden": bool, "case": case id (optional),
##   "conditions": [...]            ordinary game conditions, checked against the current case
##   "ending": "A"                  only when this verdict has just been reached
##   "max_hints": 0, "max_mistakes": 0, "grade": "S"   limits at the moment of the verdict
##   "all_endings": true            every ending of the case has been seen }]


## ending_id: the verdict just reached, or "" when checking during play.
## Returns the ids unlocked by this call.
static func evaluate(ending_id: String = "") -> Array:
	var unlocked: Array = []
	for a in CaseDB.achievements:
		if Profile.achievements.has(a["id"]):
			continue
		if _earned(a, ending_id) and Profile.unlock(a["id"]):
			unlocked.append(a["id"])
	return unlocked


static func _earned(a: Dictionary, ending_id: String) -> bool:
	if a.has("case") and a["case"] != GameState.case_id:
		return false
	if a.has("ending") and a["ending"] != ending_id:
		return false
	var at_verdict: bool = a.has("max_hints") or a.has("max_mistakes") or a.has("grade")
	if at_verdict and not a.has("ending"):
		return false
	if not GameState.check(a.get("conditions", [])):
		return false
	if a.has("max_hints") and GameState.hints > int(a["max_hints"]):
		return false
	if a.has("max_mistakes") and GameState.mistakes + GameState.bad_links > int(a["max_mistakes"]):
		return false
	if a.has("grade") and Verdict.rating()["grade"] != a["grade"]:
		return false
	if a.get("all_endings", false):
		var seen: Array = Profile.endings.get(GameState.case_id, [])
		for id in CaseDB.endings["endings"]:
			if id not in seen:
				return false
	return true


static func find(id: String) -> Dictionary:
	for a in CaseDB.achievements:
		if a["id"] == id:
			return a
	return {}
