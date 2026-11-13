extends Node
## Player preferences (language, text size). Stored in user://settings.json.

signal locale_changed
signal text_scale_changed

const PATH := "user://settings.json"
const LOCALES := ["en", "tr"]
const TEXT_SCALES := [0.85, 1.0, 1.2]

var locale := ""          # "" means the player has not chosen yet (first run)
var text_size := 1        # index into TEXT_SCALES


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	var loc := str(data.get("locale", ""))
	locale = loc if loc in LOCALES else ""
	text_size = clampi(int(data.get("text_size", 1)), 0, TEXT_SCALES.size() - 1)


func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"locale": locale, "text_size": text_size}))


func set_locale(value: String) -> void:
	if value not in LOCALES:
		return
	locale = value
	TranslationServer.set_locale(value)
	save_settings()
	locale_changed.emit()


func set_text_size(index: int) -> void:
	text_size = clampi(index, 0, TEXT_SCALES.size() - 1)
	save_settings()
	text_scale_changed.emit()


func text_scale_factor() -> float:
	return TEXT_SCALES[text_size]
