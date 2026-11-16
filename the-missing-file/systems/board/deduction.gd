class_name Deduction
## Rules of the evidence board, without any UI.
##
## insights.json:  "I_X": {"cards": ["E02", "E06"], "title": KEY, "text": KEY (the right conclusion),
##                         "wrong": [KEY, KEY], "effects": [...],
##                         "question": KEY, "key": KEY (the fact both cards share),
##                         "wrong_short": [KEY, KEY] (short wrong answers shown on the Board)}
## On the Board the right answer is shown as the conclusion's short title.

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
	var out: Array = [def["title"]]
	out.append_array(def.get("wrong_short", def["wrong"]))
	out.shuffle()
	return out


static func confirm(id: String, chosen_key: String) -> bool:
	var def: Dictionary = CaseDB.insights[id]
	if chosen_key != def["text"] and chosen_key != def["title"]:
		GameState.add_mistake()
		return false
	GameState.add_insight(id)
	GameState.apply(def.get("effects", []))
	return true


## What Mira says when two cards do not connect: warm when one of them belongs
## with another card the player already holds (and says roughly where that card
## came from), lukewarm when its partner has not been found yet, cold otherwise.
## Returns translated text.
static func nudge(a: String, b: String) -> String:
	var later := ""
	for card in [a, b]:
		for id in CaseDB.insights:
			var cards: Array = CaseDB.insights[id]["cards"]
			if card not in cards or GameState.has_insight(id):
				continue
			var partner: String = cards[1] if cards[0] == card else cards[0]
			if GameState.has_card(partner):
				return TranslationServer.translate("BOARD_WARM") % [TranslationServer.translate(CaseDB.card_title(card)), source(partner)]
			if later == "":
				later = card
	if later != "":
		return TranslationServer.translate("BOARD_WARM_LATER") % TranslationServer.translate(CaseDB.card_title(later))
	return TranslationServer.translate("BOARD_COLD")


## Roughly where a card came from, without naming it.
static func source(card: String) -> String:
	var t := TranslationServer
	match CaseDB.card_kind(card):
		"insight":
			return t.translate("BOARD_FROM_CONCLUSION")
		"testimony":
			var who: String = CaseDB.meta["testimony"][card]["speaker"]
			if who != "mira" and CaseDB.characters.has(who):
				return t.translate("BOARD_FROM_PERSON") % t.translate(CaseDB.characters[who]["name"])
		"evidence":
			for r in CaseDB.records:
				if r["evidence"] == card:
					return t.translate("BOARD_FROM_DATABASE")
			for loc in CaseDB.locations:
				for h in CaseDB.locations[loc]["hotspots"]:
					if h.get("evidence", "") == card:
						return t.translate("BOARD_FROM_PLACE") % t.translate(CaseDB.locations[loc]["name"])
	return t.translate("BOARD_FROM_CARD")
