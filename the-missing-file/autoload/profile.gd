extends Node
## Everything that outlives a single case: solved cases, best grades, endings
## seen, experience and rank, achievements, and story flags carried from one
## case into the next. Stored in user://profile.json.

signal changed

const PATH := "user://profile.json"
const VERSION := 1

var persist := true            # tests switch this off so they never touch real data
var best: Dictionary = {}      # case id -> {"score": int, "grade": String}
var solved: Dictionary = {}    # case id -> true
var endings: Dictionary = {}   # case id -> [ending ids seen]
var flags: Dictionary = {}     # "case_id.flag" -> true (decisions carried forward)
var achievements: Dictionary = {}   # achievement id -> true
var last_case := ""            # the case the player was last in


func _ready() -> void:
	load_profile()


func reset() -> void:
	best = {}
	solved = {}
	endings = {}
	flags = {}
	achievements = {}
	last_case = ""


func load_profile() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	best = Dictionary(d.get("best", {}))
	solved = Dictionary(d.get("solved", {}))
	endings = Dictionary(d.get("endings", {}))
	flags = Dictionary(d.get("flags", {}))
	achievements = Dictionary(d.get("achievements", {}))
	last_case = str(d.get("last_case", ""))


func save_profile() -> void:
	changed.emit()
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"version": VERSION, "best": best, "solved": solved, "endings": endings,
			"flags": flags, "achievements": achievements, "last_case": last_case,
		}))


# ---------------------------------------------------------------- career

## Experience is the sum of the best score in each solved case, so replaying a
## case for a better grade helps, but repeating it does not add up.
func xp() -> int:
	var total := 0
	for id in best:
		total += int(best[id]["score"])
	return total


func rank_index() -> int:
	var ranks: Array = CaseDB.career["ranks"]
	var index := 0
	for i in ranks.size():
		if xp() >= int(ranks[i]["xp"]):
			index = i
	return index


func rank() -> Dictionary:
	return CaseDB.career["ranks"][rank_index()]


## The rank after the current one, or {} at the top.
func next_rank() -> Dictionary:
	var ranks: Array = CaseDB.career["ranks"]
	var i := rank_index() + 1
	return ranks[i] if i < ranks.size() else {}


## Records the outcome of an accusation. Returns what changed, for the verdict screen:
## {"xp_gain": int, "xp": int, "rank_up": bool}
func record_verdict(case_id: String, ending_id: String, is_solved: bool, rating: Dictionary, carried: Array) -> Dictionary:
	var before_xp := xp()
	var before_rank := rank_index()
	var seen: Array = endings.get(case_id, [])
	if ending_id not in seen:
		seen.append(ending_id)
	endings[case_id] = seen
	if is_solved:
		solved[case_id] = true
		var old: Dictionary = best.get(case_id, {"score": -1})
		if int(rating["score"]) > int(old["score"]):
			best[case_id] = {"score": int(rating["score"]), "grade": rating["grade"]}
		# Decisions carried into later cases: the latest solved run wins.
		for key in flags.keys():
			if key.begins_with(case_id + "."):
				flags.erase(key)
		for flag in carried:
			flags[case_id + "." + flag] = true
	save_profile()
	return {"xp_gain": xp() - before_xp, "xp": xp(), "rank_up": rank_index() > before_rank}


func has_flag(name: String) -> bool:
	return bool(flags.get(name, false))


func is_solved(case_id: String) -> bool:
	return bool(solved.get(case_id, false))


## True once any verdict has been reached in the case, right or wrong.
func is_closed(case_id: String) -> bool:
	return not Array(endings.get(case_id, [])).is_empty()


func unlock(achievement_id: String) -> bool:
	if achievements.has(achievement_id):
		return false
	achievements[achievement_id] = true
	save_profile()
	return true


func set_last_case(case_id: String) -> void:
	if last_case != case_id:
		last_case = case_id
		save_profile()
