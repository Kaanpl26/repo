class_name Deduction
## Rules of the evidence board, without any UI.
##
## insights.json:  "I_X": {"cards": ["E02", "E06"], "title": KEY, "text": KEY (the right conclusion),
##                         "wrong": [KEY, KEY], "effects": [...]}

const NONE := "none"      # the two cards have nothing to do with each other
const KNOWN := "known"    # the player already made this connection
const FOUND := "found"    # a new connection: the player must now pick the conclusion


static func find(a: String, b: String) -> String:
	for id in CaseDB.insights:
		var cards: Array = CaseDB.insights[id]["cards"]
		if (cards[0] == a and cards[1] == b) or (cards[0] == b and cards[1] == a):
			return id
	return ""


static func try_link(a: String, b: String) -> Dictionary:
	var id := find(a, b)
	if id == "":
		GameState.add_bad_link()
		return {"status": NONE}
	if GameState.has_insight(id):
		return {"status": KNOWN, "id": id}
	return {"status": FOUND, "id": id}


## The possible conclusions (text keys) in random order.
static func options(id: String) -> Array:
	var def: Dictionary = CaseDB.insights[id]
	var out: Array = [def["text"]]
	out.append_array(def["wrong"])
	out.shuffle()
	return out


static func confirm(id: String, chosen_key: String) -> bool:
	var def: Dictionary = CaseDB.insights[id]
	if chosen_key != def["text"]:
		GameState.add_mistake()
		return false
	GameState.add_insight(id)
	GameState.apply(def.get("effects", []))
	return true
