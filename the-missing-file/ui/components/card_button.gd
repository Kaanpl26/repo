class_name CardButton
extends PanelContainer
## A card on the Board, in the Case File or in a picker: icon, title and a
## short line saying what the card actually shows, so that cards can be
## compared without opening each one. Grows to fit its text.

signal pressed

var card_id := ""
var _title: Label
var _gist: Label
var _down := false
var _selected := false
var _used := false


func _init(id: String, gist_lines: int = 3) -> void:
	card_id = id
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, UI.MIN_TOUCH + 20)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	var icon := TextureRect.new()
	icon.texture = load(CaseDB.card_icon(id))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(76, 76)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	_title = UI.label(CaseDB.card_title(id), "NameLabel", true)
	_title.add_theme_font_size_override("font_size", 31)
	col.add_child(_title)
	_gist = UI.label(CaseDB.card_gist(id), "", true)
	_gist.add_theme_constant_override("line_spacing", 2)
	_gist.max_lines_visible = gist_lines
	_gist.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.scaled_font(_gist, 28)
	col.add_child(_gist)


func _ready() -> void:
	_apply()


## selected: highlighted as chosen. used: every connection this card can make
## has been made, so it is shown faded.
func set_state(selected: bool, used: bool = false) -> void:
	_selected = selected
	_used = used
	_apply()


func _apply() -> void:
	if not is_inside_tree():
		return   # styles come from the scene's theme; _ready applies them
	var kind := CaseDB.card_kind(card_id)
	var variation := "AccentButton" if _selected else ("InsightButton" if kind == "insight" else "Button")
	add_theme_stylebox_override("panel", get_theme_stylebox("normal", variation))
	var dark := _selected
	_title.add_theme_color_override("font_color", Palette.NAVY if dark else (Palette.JADE.lightened(0.35) if kind == "insight" else Palette.AMBER))
	_gist.add_theme_color_override("font_color", Palette.INK if dark else Palette.PAPER)
	modulate.a = 0.5 if (_used and not _selected) else 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		_down = false   # the finger is scrolling the list, not tapping this card


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		elif _down:
			_down = false
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				Audio.sfx("click")
				pressed.emit()
