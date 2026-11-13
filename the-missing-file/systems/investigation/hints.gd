class_name Hints
## Decides what the Hint button shows. Kept free of UI code so it can be tested.
##
## 1. If a piece of evidence in this location can be picked up right now,
##    point at it.
## 2. Otherwise show the first location hint whose conditions hold
##    (these explain how to unlock gated evidence).
## 3. Otherwise return {} (nothing left to find here).


static func next(location_id: String) -> Dictionary:
	var loc: Dictionary = CaseDB.locations[location_id]
	for h in loc["hotspots"]:
		if h["type"] == "evidence" and not GameState.has_evidence(h["evidence"]) \
				and GameState.check(h.get("conditions", [])):
			return {"type": "point", "hotspot": h}
	for hint in loc.get("hints", []):
		if GameState.check(hint.get("conditions", [])):
			return {"type": "text", "text": hint["text"]}
	return {}
