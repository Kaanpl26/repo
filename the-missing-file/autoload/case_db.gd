extends Node
## Loads a case's structured data (JSON) and gives read-only access to it.

var case_id := ""
var meta: Dictionary = {}
var evidence: Dictionary = {}     # id -> evidence definition
var locations: Dictionary = {}    # id -> location definition
var characters: Dictionary = {}   # id -> character definition
var dialogues: Dictionary = {}    # character id -> dialogue tree
var insights: Dictionary = {}     # id -> conclusion the player can reach on the board
var suspects: Dictionary = {}     # character id -> profile
var timeline: Array = []          # entries that appear as evidence is found
var endings: Dictionary = {}      # accusation rules and verdict texts

const ICON_TESTIMONY := "res://assets/ui/card_testimony.png"
const ICON_INSIGHT := "res://assets/ui/card_insight.png"


func _ready() -> void:
	load_case("case_01")


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: " + path)
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Invalid JSON: " + path)
	return parsed


func load_case(id: String) -> bool:
	var dir := "res://data/cases/%s/" % id
	var m = read_json(dir + "case.json")
	var e = read_json(dir + "evidence.json")
	var l = read_json(dir + "locations.json")
	var c = read_json(dir + "characters.json")
	var i = read_json(dir + "insights.json")
	var s = read_json(dir + "suspects.json")
	var t = read_json(dir + "timeline.json")
	var v = read_json(dir + "endings.json")
	if m == null or e == null or l == null or c == null or i == null or s == null or t == null or v == null:
		return false
	insights = i
	suspects = s
	timeline = t
	endings = v
	case_id = id
	meta = m
	evidence = e
	locations = l
	characters = c
	dialogues = {}
	for ch in characters:
		if characters[ch].has("dialogue"):
			var d = read_json(dir + "dialogue/" + characters[ch]["dialogue"])
			if d != null:
				dialogues[ch] = d
	return true


func location_evidence(location_id: String) -> Array:
	var out: Array = []
	for h in locations[location_id]["hotspots"]:
		if h.get("type", "") == "evidence" and h["evidence"] not in out:
			out.append(h["evidence"])
	return out


## A "card" is anything the player can put on the board or use as proof:
## evidence (E..), a recorded statement (T_..) or a conclusion (I_..).
func card_kind(id: String) -> String:
	if evidence.has(id):
		return "evidence"
	if meta["testimony"].has(id):
		return "testimony"
	if insights.has(id):
		return "insight"
	return ""


func card_title(id: String) -> String:
	match card_kind(id):
		"evidence":
			return evidence[id]["name"]
		"testimony":
			return meta["testimony"][id]["title"]
		"insight":
			return insights[id]["title"]
	return ""


func card_text(id: String) -> String:
	match card_kind(id):
		"evidence":
			return evidence[id]["desc"]
		"testimony":
			return meta["testimony"][id]["text"]
		"insight":
			return insights[id]["text"]
	return ""


func card_icon(id: String) -> String:
	match card_kind(id):
		"evidence":
			return evidence[id]["icon"]
		"testimony":
			return ICON_TESTIMONY
	return ICON_INSIGHT
