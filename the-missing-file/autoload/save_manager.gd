extends Node
## Automatic save/load, one save file per case. The game saves after every
## change to GameState, so the player can close the app at any moment.

const OLD_PATH := "user://save.json"   # single save used before version 2
const VERSION := 2

var _pending := false
var enabled := true     # tests switch this off so they never write save files


func _ready() -> void:
	_migrate_v1()
	_backfill_profile()
	_refresh_carried()
	GameState.changed.connect(_queue_save)


static func path(case_id: String) -> String:
	return "user://save_%s.json" % case_id


## Version 1 kept one save for the only case. Move it to the per-case file.
func _migrate_v1() -> void:
	if not FileAccess.file_exists(OLD_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(OLD_PATH))
	if typeof(data) == TYPE_DICTIONARY and typeof(data.get("state")) == TYPE_DICTIONARY:
		var id := str(data["state"].get("case_id", "case_01"))
		if not FileAccess.file_exists(path(id)):
			var f := FileAccess.open(path(id), FileAccess.WRITE)
			if f:
				f.store_string(JSON.stringify({"version": VERSION, "state": data["state"]}))
				f.close()
		if Profile.last_case == "":
			Profile.set_last_case(id)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OLD_PATH))


## Saves made before version 1.1 know which verdicts were reached, but the
## profile did not exist yet. Copy that across once, so finished cases count.
func _backfill_profile() -> void:
	for entry in CaseDB.index:
		var id: String = entry["id"]
		if Profile.endings.has(id):
			continue
		var data = _read(id)
		if data == null:
			continue
		var seen: Array = Array(data["state"].get("endings_seen", []))
		if seen.is_empty():
			continue
		GameState.from_dict(data["state"])
		GameState.active = false
		var rating := Verdict.rating()
		var carried: Array = []
		for flag in CaseDB.endings.get("carry", []):
			if GameState.has_flag(flag):
				carried.append(flag)
		for ending in seen:
			var is_solved: bool = CaseDB.endings["endings"].get(ending, {}).get("solved", false)
			Profile.record_verdict(id, ending, is_solved, rating, carried)
	CaseDB.load_case(CaseDB.index[0]["id"])


## Newer versions carry more decisions out of a case than older ones did.
## For every case that has a verdict and still has its save, read them again.
func _refresh_carried() -> void:
	for entry in CaseDB.index:
		var id: String = entry["id"]
		if not Profile.is_closed(id):
			continue
		var data = _read(id)
		if data == null or Array(data["state"].get("endings_seen", [])).is_empty():
			continue
		CaseDB.load_case(id)
		var flags: Dictionary = Dictionary(data["state"].get("flags", {}))
		var carried: Array = []
		for flag in CaseDB.endings.get("carry", []):
			if bool(flags.get(flag, false)):
				carried.append(flag)
		Profile.set_carried(id, carried)
	CaseDB.load_case(CaseDB.index[0]["id"])


func _queue_save() -> void:
	if _pending or not GameState.active:
		return
	_pending = true
	_flush.call_deferred()


func _flush() -> void:
	_pending = false
	save_game()


func save_game() -> void:
	if not GameState.active or not enabled:
		return
	var f := FileAccess.open(path(GameState.case_id), FileAccess.WRITE)
	if f == null:
		push_error("Could not write save file")
		return
	f.store_string(JSON.stringify({"version": VERSION, "state": GameState.to_dict()}))
	if not CaseDB.case_entry(GameState.case_id).is_empty():
		Profile.set_last_case(GameState.case_id)


func has_save(case_id: String) -> bool:
	return case_id != "" and _read(case_id) != null


func load_game(case_id: String) -> bool:
	var data = _read(case_id)
	if data == null:
		return false
	GameState.from_dict(data["state"])
	return true


func delete_save(case_id: String) -> void:
	if FileAccess.file_exists(path(case_id)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(case_id)))


func _read(case_id: String) -> Variant:
	if not FileAccess.file_exists(path(case_id)):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path(case_id)))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("state")) != TYPE_DICTIONARY:
		return null
	if int(data.get("version", 0)) > VERSION:
		return null
	return data


func _notification(what: int) -> void:
	# Android may kill the app in the background: save when we are paused or closed.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
