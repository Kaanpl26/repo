extends Node
## Automatic save/load, one save file per case. The game saves after every
## change to GameState, so the player can close the app at any moment.

const OLD_PATH := "user://save.json"   # single save used before version 2
const VERSION := 2

var _pending := false


func _ready() -> void:
	_migrate_v1()
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


func _queue_save() -> void:
	if _pending or not GameState.active:
		return
	_pending = true
	_flush.call_deferred()


func _flush() -> void:
	_pending = false
	save_game()


func save_game() -> void:
	if not GameState.active:
		return
	var f := FileAccess.open(path(GameState.case_id), FileAccess.WRITE)
	if f == null:
		push_error("Could not write save file")
		return
	f.store_string(JSON.stringify({"version": VERSION, "state": GameState.to_dict()}))
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
