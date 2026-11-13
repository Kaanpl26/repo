extends Node
## Loads a case's structured data (JSON) and gives read-only access to it.

var case_id := ""
var meta: Dictionary = {}
var evidence: Dictionary = {}     # id -> evidence definition
var locations: Dictionary = {}    # id -> location definition
var characters: Dictionary = {}   # id -> character definition
var dialogues: Dictionary = {}    # character id -> dialogue tree


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
	if m == null or e == null or l == null or c == null:
		return false
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
