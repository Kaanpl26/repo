class_name BoardNote
extends PanelContainer
## One pinned note on the evidence wall. Tap to select it; drag to move it.

signal tapped(card_id: String)
signal moved(card_id: String)

const DRAG_SLOP := 22.0

var card_id := ""
var wall: Control             # the BoardCanvas this note is on
var _style: StyleBoxFlat
var _down := false
var _dragging := false
var _travel := 0.0
var _pending := Vector2.ZERO
var _pin := Color.WHITE


func _init(id: String) -> void:
	card_id = id
	var kind := CaseDB.card_kind(id)
	var small := kind == "insight"
	custom_minimum_size = Vector2(BoardLayout.SMALL.x if small else BoardLayout.NOTE.x, 0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_style = StyleBoxFlat.new()
	_style.bg_color = {"evidence": Palette.PAPER, "testimony": Color("d9e2ec"), "insight": Color("cfe8dc")}[kind]
	_style.set_corner_radius_all(3)
	_style.content_margin_left = 20
	_style.content_margin_right = 20
	_style.content_margin_top = 26
	_style.content_margin_bottom = 16
	_style.shadow_color = Color(0, 0, 0, 0.45)
	_style.shadow_size = 10
	_style.shadow_offset = Vector2(3, 5)
	add_theme_stylebox_override("panel", _style)
	_pin = {"evidence": Palette.RED, "testimony": Color("3f6fb0"), "insight": Palette.JADE.darkened(0.2)}[kind]
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	var title := UI.label(CaseDB.card_title(id), "PaperTitle", true)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_constant_override("line_spacing", 0)
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(title)
	if not small:
		var gist := UI.label(CaseDB.card_gist(id), "PaperLabel", true)
		gist.add_theme_font_size_override("font_size", 23)
		gist.add_theme_constant_override("line_spacing", 0)
		gist.max_lines_visible = 4
		gist.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(gist)
	set_state(false, false)


func set_state(selected: bool, used: bool) -> void:
	_style.set_border_width_all(7 if selected else 0)
	_style.border_color = Palette.AMBER
	modulate.a = 0.55 if (used and not selected) else 1.0
	z_index = 1 if selected else 0


func _draw() -> void:
	draw_circle(Vector2(size.x / 2.0, 14), 9, Color(0, 0, 0, 0.35))
	draw_circle(Vector2(size.x / 2.0, 12), 9, _pin)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
			_dragging = false
			_travel = 0.0
			_pending = Vector2.ZERO
			wall.note_pressed()
		elif _down:
			_down = false
			if _dragging:
				_dragging = false
				moved.emit(card_id)
			elif not wall.in_gesture():
				Audio.sfx("click")
				tapped.emit(card_id)
	elif event is InputEventMouseMotion and _down:
		if wall.in_gesture():       # a second finger arrived: this is a pinch, not a drag
			_down = false
			_dragging = false
			return
		# event.relative is already in this note's own (zoomed) coordinates
		_travel += event.relative.length() * wall.zoom
		_pending += event.relative
		if not _dragging and _travel > DRAG_SLOP:
			_dragging = true
			move_to_front()
		if _dragging:
			# includes the small movement made before the drag was recognised,
			# so the note stays exactly under the finger
			position += _pending
			_pending = Vector2.ZERO
			wall.note_dragged()
			accept_event()
