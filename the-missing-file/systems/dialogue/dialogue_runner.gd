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
##                   "present": {"accept": "E05", "next": "confess", "wrong": "wrong"}} ],
##       "choices": [ {"id": "c1", "t": "TEXT_KEY", "next": "node", "conditions": [...], "effects": [...]} ],
##       "next": "hub"            (used when there are no choices)
##     }
##   }
## }

const LINE := "line"
const CHOICES := "choices"
const END := "end"

var character := ""
var data: Dictionary = {}
var node_id := ""
var line_index := -1


func _init(character_id: String) -> void:
	character = character_id
	data = CaseDB.dialogues[character_id]


func start() -> String:
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


func can_present() -> bool:
	return line().has("present")


## Returns true when the evidence exposes the contradiction in the current line.
func present(evidence_id: String) -> bool:
	var p: Dictionary = line()["present"]
	if evidence_id == p["accept"]:
		_enter(p["next"])
		return true
	GameState.add_mistake()
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
	return END
