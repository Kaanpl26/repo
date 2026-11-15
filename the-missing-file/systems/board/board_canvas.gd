class_name BoardCanvas
extends Control
## The evidence wall: a cork surface that can be panned and zoomed, with a
## note for every card and red thread from each conclusion to the two cards
## it came from.
##
## Touch: drag the cork to pan, pinch with two fingers to zoom, drag a note to
## move it, tap a note to select it. The + and - buttons zoom without a
## gesture, and Tidy puts every note back in its automatic place.

signal note_tapped(card_id: String)

const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.6
const PAN_SLOP := 22.0

var zoom := 1.0
var accepts_gestures: Callable = func(): return true

var _content: Control
var _threads: Control
var _notes := {}                # card id -> BoardNote
var _touches := {}              # finger index -> position (in this control)
var _gesture := false           # two fingers are down, or were a moment ago
var _pinch_distance := 0.0
var _pinch_zoom := 1.0
var _pinch_middle := Vector2.ZERO
var _down := false
var _panning := false
var _press := Vector2.ZERO
var _press_on_note := false
var _fitted := false


func _init() -> void:
	clip_contents = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cork := ColorRect.new()
	cork.color = Color("3a2a1c")
	cork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cork)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_content)
	_threads = Control.new()
	_threads.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_threads.draw.connect(_draw_threads)
	_content.add_child(_threads)

	var tools := HBoxContainer.new()
	tools.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tools.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tools.position = Vector2(-16, 12)
	tools.add_theme_constant_override("separation", 10)
	add_child(tools)
	for spec in [["−", func(): zoom_by(0.8)], ["+", func(): zoom_by(1.25)]]:
		var b := UI.button("")
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = spec[0]
		b.custom_minimum_size = Vector2(UI.MIN_TOUCH, 84)
		b.pressed.connect(spec[1])
		tools.add_child(b)
	var tidy := UI.button("BOARD_TIDY")
	tidy.custom_minimum_size = Vector2(0, 84)
	tidy.pressed.connect(func():
		GameState.clear_board_layout()
		build()
		fit())
	tools.add_child(tidy)
	resized.connect(func():
		if not _fitted and size.x > 10:
			fit())


# ---------------------------------------------------------------- content

## (Re)creates a note for every card the player holds.
func build() -> void:
	for id in _notes:
		_notes[id].queue_free()
	_notes.clear()
	var pos := BoardLayout.positions()
	_content.size = BoardLayout.canvas_size()
	_threads.size = _content.size
	for id in pos:
		var note := BoardNote.new(id)
		note.wall = self
		note.position = pos[id]
		note.tapped.connect(func(card): note_tapped.emit(card))
		note.moved.connect(_on_note_moved)
		_content.add_child(note)
		_notes[id] = note
	_threads.queue_redraw()


func has_note(card_id: String) -> bool:
	return _notes.has(card_id)


func note(card_id: String) -> BoardNote:
	return _notes[card_id]


func set_states(selected: Array) -> void:
	for id in _notes:
		_notes[id].set_state(id in selected, Hints.card_used_up(id))


func _draw_threads() -> void:
	for id in GameState.insights:
		if not _notes.has(id):
			continue
		var to: Vector2 = _notes[id].position + Vector2(_notes[id].size.x / 2.0, 12)
		for source in CaseDB.insights[id]["cards"]:
			if _notes.has(source):
				var from: Vector2 = _notes[source].position + Vector2(_notes[source].size.x / 2.0, 12)
				_threads.draw_line(from, to, Color(0, 0, 0, 0.3), 7.0, true)
				_threads.draw_line(from, to, Palette.RED, 4.0, true)


func note_dragged() -> void:
	_threads.queue_redraw()


func _on_note_moved(card_id: String) -> void:
	var n: BoardNote = _notes[card_id]
	var limit: Vector2 = _content.size - n.size
	n.position = Vector2(clampf(n.position.x, 0, maxf(0, limit.x)), clampf(n.position.y, 0, maxf(0, limit.y)))
	GameState.set_board_pos(card_id, n.position)
	_threads.queue_redraw()


# ---------------------------------------------------------------- view

## Shows the whole width of the wall, starting at the top.
func fit() -> void:
	if size.x <= 10:
		return
	_fitted = true
	zoom = clampf(size.x / _content.size.x, 0.6, 1.0)
	_content.position = Vector2((size.x - _content.size.x * zoom) / 2.0, 0)
	_apply()


func zoom_by(factor: float, around: Vector2 = Vector2(-1, -1)) -> void:
	if around.x < 0:
		around = size / 2.0
	var target := clampf(zoom * factor, ZOOM_MIN, ZOOM_MAX)
	_content.position = around - (around - _content.position) * (target / zoom)
	zoom = target
	_apply()


## Brings the given cards into view. If they all fit at a readable size the
## wall is framed around them; otherwise it stays readable and centres on the
## first one (the tray below always shows both in full).
const READABLE := 0.7


func show_cards(cards: Array) -> void:
	var rect := Rect2()
	var first_rect := Rect2()
	var first := true
	for id in cards:
		if not _notes.has(id):
			continue
		var r := Rect2(_notes[id].position, _notes[id].size)
		if first:
			first_rect = r
		rect = r if first else rect.merge(r)
		first = false
	if first:
		return
	rect = rect.grow(50)
	var fit_zoom := minf(size.x / rect.size.x, size.y / rect.size.y)
	if fit_zoom >= READABLE:
		zoom = clampf(fit_zoom, READABLE, 1.0)
		_content.position = size / 2.0 - rect.get_center() * zoom
	else:
		zoom = maxf(READABLE, minf(zoom, 1.0))
		_content.position = size / 2.0 - first_rect.get_center() * zoom
	_apply()


func _apply() -> void:
	_content.scale = Vector2(zoom, zoom)
	var shown: Vector2 = _content.size * zoom
	# keep at least part of the wall on screen
	_content.position.x = clampf(_content.position.x, minf(0.0, size.x - shown.x) - 200.0, maxf(0.0, size.x - shown.x) + 200.0)
	_content.position.y = clampf(_content.position.y, minf(0.0, size.y - shown.y) - 200.0, maxf(0.0, size.y - shown.y) + 200.0)


# ---------------------------------------------------------------- input

func note_pressed() -> void:
	_press_on_note = true


func in_gesture() -> bool:
	return _gesture


## Fingers are followed here, before the interface sees them, so that a pinch
## works even when one finger rests on a note.
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if not is_visible_in_tree() or not accepts_gestures.call():
		_touches.clear()
		_gesture = false
		return
	var local: Vector2 = make_input_local(event).position
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touches.is_empty():
				_gesture = false       # a new single touch ends the last pinch
			if Rect2(Vector2.ZERO, size).has_point(local):
				_touches[event.index] = local
			if _touches.size() == 2:
				_gesture = true
				_panning = false
				var p: Array = _touches.values()
				_pinch_distance = maxf(1.0, p[0].distance_to(p[1]))
				_pinch_zoom = zoom
				_pinch_middle = (p[0] + p[1]) / 2.0
		else:
			_touches.erase(event.index)
	elif _touches.has(event.index):
		_touches[event.index] = local
		if _touches.size() == 2:
			var p: Array = _touches.values()
			var middle: Vector2 = (p[0] + p[1]) / 2.0
			var target := clampf(_pinch_zoom * p[0].distance_to(p[1]) / _pinch_distance, ZOOM_MIN, ZOOM_MAX)
			_content.position = middle - (_pinch_middle - _content.position) * (target / zoom)
			zoom = target
			_pinch_middle = middle
			_apply()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_by(1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_by(0.9, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_down = true
				_panning = false
				_press = event.position
			else:
				_down = false
				_panning = false
				_press_on_note = false
	elif event is InputEventMouseMotion and _down and not _press_on_note and not _gesture:
		if not _panning and event.position.distance_to(_press) > PAN_SLOP:
			_panning = true
		if _panning:
			_content.position += event.relative
			_apply()
