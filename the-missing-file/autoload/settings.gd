extends Node
## Player preferences (language, text size). Stored in user://settings.json.

signal locale_changed
signal text_scale_changed
signal volume_changed

const PATH := "user://settings.json"
const LOCALES := ["en", "tr"]
const TEXT_SCALES := [0.85, 1.0, 1.2]

var persist := true        # tests switch this off so they never write the settings file
var locale := ""          # "" means the player has not chosen yet (first run)
var text_size := 1        # index into TEXT_SCALES
var music_volume := 0.7   # 0..1
var sfx_volume := 0.9     # 0..1
var board_view := "wall"  # "wall" (free canvas) or "list"


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
	music_volume = clampf(float(data.get("music_volume", 0.7)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", 0.9)), 0.0, 1.0)
	board_view = "list" if str(data.get("board_view", "wall")) == "list" else "wall"


func save_settings() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"locale": locale, "text_size": text_size,
			"music_volume": music_volume, "sfx_volume": sfx_volume, "board_view": board_view,
		}))


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


func set_board_view(view: String) -> void:
	board_view = "list" if view == "list" else "wall"
	save_settings()


func set_volumes(music: float, sfx: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	save_settings()
	volume_changed.emit()


func text_scale_factor() -> float:
	return TEXT_SCALES[text_size]
