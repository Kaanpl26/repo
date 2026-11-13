class_name Hints
## Decides what the Hint buttons show. Kept free of UI code so it can be tested.


## Hint in a scene:
## 1. If a piece of evidence in this location can be picked up right now, point at it.
## 2. Otherwise show the first location hint whose conditions hold
##    (these explain how to unlock gated evidence).
## 3. Otherwise, if cards can be connected, send the player to the Board.
## 4. Otherwise show the first case-wide hint that applies (usually a
##    conversation the player has not finished).
## 5. Otherwise name the current objective.
static func next(location_id: String) -> Dictionary:
	var loc: Dictionary = CaseDB.locations[location_id]
	for h in loc["hotspots"]:
		if h["type"] == "evidence" and not GameState.has_evidence(h["evidence"]) \
				and GameState.check(h.get("conditions", [])):
			return {"type": "point", "hotspot": h}
	for hint in loc.get("hints", []):
		if GameState.check(hint.get("conditions", [])):
			return {"type": "text", "text": hint["text"]}
	if next_link() != "":
		return {"type": "text", "text": "HINT_BOARD"}
	for hint in CaseDB.meta.get("hints", []):
		if GameState.check(hint.get("conditions", [])):
			return {"type": "text", "text": hint["text"]}
	var o := current_objective()
	if not o.is_empty():
		return {"type": "objective", "text": o["text"]}
	return {}


## The first objective that is visible and not yet done.
static func current_objective() -> Dictionary:
	for o in CaseDB.meta["objectives"]:
		if GameState.check(o.get("show", [])) and not GameState.check(o["done"]):
			return o
	return {}


## Hint on the board: a conclusion the player can reach with the cards they
## already hold. Returns the insight id, or "" when nothing can be connected yet.
static func next_link() -> String:
	for id in CaseDB.insights:
		if GameState.has_insight(id):
			continue
		var cards: Array = CaseDB.insights[id]["cards"]
		if GameState.has_card(cards[0]) and GameState.has_card(cards[1]):
			return id
	return ""
