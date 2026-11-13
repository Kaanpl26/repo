extends Node
## Automatic save/load. The game saves after every change to GameState,
## so the player can close the app at any moment and continue later.

const PATH := "user://save.json"
const VERSION := 1

var _pending := false


func _ready() -> void:
	GameState.changed.connect(_queue_save)


func _queue_save() -> void:
	if _pending or not GameState.active:
		return
	_pending = true
	_flush.call_deferred()


func _flush() -> void:
	_pending = false
	save_game()


func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save file")
		return
	f.store_string(JSON.stringify({"version": VERSION, "state": GameState.to_dict()}))


func has_save() -> bool:
	return _read() != null


func load_game() -> bool:
	var data = _read()
	if data == null:
		return false
	GameState.from_dict(data["state"])
	return true


func delete_save() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	GameState.active = false


func _read() -> Variant:
	if not FileAccess.file_exists(PATH):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("state")) != TYPE_DICTIONARY:
		return null
	if int(data.get("version", 0)) > VERSION:
		return null
	return data


func _notification(what: int) -> void:
	# Android may kill the app in the background: save when we are paused or closed.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if GameState.active:
			save_game()
