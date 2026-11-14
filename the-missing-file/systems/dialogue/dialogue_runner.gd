class_name DialogueRunner
extends RefCounted
## Walks through a dialogue tree loaded from JSON. Contains no UI code,
## so conversations can be tested automatically.
##
## A dialogue file looks like:
## {
##   "start": [ {"node": "intro", "conditions": [...]}, {"node": "hub"} ],
##   "nodes": {
##     "intro": {
##       "lines": [ {"s": "erdem", "t": "TEXT_KEY", "effects": [...],
##                   "mood": "defensive" | "shaken"   (portrait expression, optional)
##                   "press": "node"                  (the player may press this statement for more)
##                   "present": {"accept": "E05" (or a list of card ids), "next": "confess", "wrong": "wrong"}} ],
##       "choices": [ {"id": "c1", "t": "TEXT_KEY", "next": "node", "conditions": [...], "effects": [...]} ],
##       "next": "hub"            (used when there are no choices)
##     }
##   },
##   "closed": "node"   (optional) what the person says when they have run out of patience
## }
##
## Pressing a statement plays the "press" node and then carries on with
## whatever followed the statement. The statement itself is not repeated.
## If the statement could be challenged with evidence, it can still be
## challenged on the last line of the follow-up.

const LINE := "line"
const CHOICES := "choices"
const END := "end"

var character := ""
var data: Dictionary = {}
var node_id := ""
var line_index := -1
var _resume: Array = []      # [node id, line index] to return to after a pressed node


func _init(character_id: String) -> void:
	character = character_id
	data = CaseDB.dialogues[character_id]


func has_patience() -> bool:
	return data.has("closed")


func start() -> String:
	_resume = []
	if has_patience() and GameState.patience_left(character) <= 0:
		return _enter(data["closed"])
	for entry in data["start"]:
		if GameState.check(entry.get("conditions", [])):
			return _enter(entry["node"])
	return END


func node() -> Dictionary:
	return data["nodes"][node_id]


func line() -> Dictionary:
	var lines: Array = node().get("lines", [])
	if line_index < 0 or line_index >= lines.size():
		return {}
	return lines[line_index]


func advance() -> String:
	var lines: Array = node().get("lines", [])
	if line_index < lines.size() - 1:
		line_index += 1
		GameState.apply(line().get("effects", []))
		return LINE
	return _after_lines()


func choices() -> Array:
	var out: Array = []
	for c in node().get("choices", []):
		if GameState.check(c.get("conditions", [])):
			out.append(c)
	return out


func is_seen(choice: Dictionary) -> bool:
	return GameState.seen.has(character + "." + choice["id"])


func choose(choice: Dictionary) -> String:
	GameState.mark_seen(character + "." + choice["id"])
	GameState.apply(choice.get("effects", []))
	if choice.get("end", false):
		return END
	return _enter(choice["next"])


func can_press() -> bool:
	return line().has("press")


## Asks the person to say more about the current statement.
func press() -> String:
	var target: String = line()["press"]
	_resume = [node_id, line_index]
	GameState.mark_seen("%s.press.%s" % [character, target])
	var pressed := 0
	for key in GameState.seen:
		if ".press." in key:
			pressed += 1
	if pressed >= 5:
		GameState.set_flag("pressed_five")
	return _enter(target)


func can_present() -> bool:
	return not _present_rule().is_empty()


## The challenge that applies right now: the current line's own, or, on the
## last line of a pressed follow-up, the one of the statement that was pressed.
func _present_rule() -> Dictionary:
	if line().has("present"):
		return line()["present"]
	if not _resume.is_empty() and line_index == node().get("lines", []).size() - 1:
		var pressed: Dictionary = data["nodes"][_resume[0]]["lines"][_resume[1]]
		return pressed.get("present", {})
	return {}


## Returns true when the evidence exposes the contradiction in the current line.
func present(evidence_id: String) -> bool:
	var p: Dictionary = _present_rule()
	var accept: Variant = p["accept"]
	var accepted: Array = accept if accept is Array else [accept]
	if evidence_id in accepted:
		_resume = []
		_enter(p["next"])
		return true
	GameState.add_mistake()
	_resume = []
	if has_patience():
		GameState.lose_patience(character)
		if GameState.patience_left(character) <= 0:
			_enter(data["closed"])
			return false
	_enter(p["wrong"])
	return false


func _enter(id: String) -> String:
	node_id = id
	GameState.apply(node().get("effects", []))
	var lines: Array = node().get("lines", [])
	if lines.is_empty():
		line_index = -1
		return _after_lines()
	line_index = 0
	GameState.apply(line().get("effects", []))
	return LINE


func _after_lines() -> String:
	var n := node()
	if not choices().is_empty():
		return CHOICES
	if n.has("next"):
		return _enter(n["next"])
	if not _resume.is_empty():
		# Back to where the pressed statement was, and straight on past it.
		node_id = _resume[0]
		line_index = _resume[1]
		_resume = []
		return advance()
	return END
