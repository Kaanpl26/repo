class_name DecisionTree
## The decisions of a case as a list of branching points. Each point has two or
## more outcomes; an outcome the player has never reached stays hidden.
## Data: data/cases/<case>/tree.json =
##   [{"id": "guard", "title": KEY, "options": [{"id": "spared", "text": KEY, "conditions": [...]}]}]
## The verdict is added automatically as the last point, one outcome per ending.

const VERDICT := "verdict"


static func nodes(case_id: String) -> Array:
	var out: Array = []
	var path := "res://data/cases/%s/tree.json" % case_id
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(d) == TYPE_ARRAY:
			out = d
	var endings = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/%s/endings.json" % case_id))
	var options: Array = []
	var ids: Array = endings["endings"].keys()
	ids.sort()
	for id in ids:
		options.append({"id": id, "text": endings["endings"][id]["title"], "conditions": []})
	out.append({"id": VERDICT, "title": "TREE_VERDICT", "options": options})
	return out


## The outcomes of the investigation in progress, as "point.outcome" ids.
static func taken(ending_id: String) -> Array:
	var out: Array = []
	for n in nodes(GameState.case_id):
		if n["id"] == VERDICT:
			out.append(VERDICT + "." + ending_id)
			continue
		for o in n["options"]:
			if GameState.check(o["conditions"]):
				out.append("%s.%s" % [n["id"], o["id"]])
				break
	return out


## Called when a verdict is given: remembers this route and everything found so far.
static func record(ending_id: String) -> void:
	var route := taken(ending_id)
	var seen: Array = Profile.tree.get(GameState.case_id, [])
	for id in route:
		if id not in seen:
			seen.append(id)
	Profile.tree[GameState.case_id] = seen
	Profile.tree_last[GameState.case_id] = route
	Profile.save_profile()


static func total(case_id: String) -> int:
	var n := 0
	for node in nodes(case_id):
		n += node["options"].size()
	return n
