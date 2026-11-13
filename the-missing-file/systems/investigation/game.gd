extends Control
## The investigation screen: a wide scene the player pans by dragging and
## searches by tapping. Hotspots come from the case's locations.json.

const TAP_SLOP := 26.0
const EVIDENCE_CARD := preload("res://systems/investigation/evidence_card.tscn")
const DIALOGUE_VIEW := preload("res://systems/dialogue/dialogue_view.tscn")
const CASE_FILE := preload("res://systems/casefile/case_file.tscn")
const SETTINGS_PANEL := preload("res://ui/menus/settings_panel.tscn")

var _loc: Dictionary
var _world: Node2D
var _fx: Node2D
var _img_size := Vector2(2880, 1080)
var _scale := 1.0
var _pan := 0.0
var _max_pan := 0.0
var _press_pos := Vector2.ZERO
var _pressed := false
var _dragging := false

var _hud: Control
var _counter: Label
var _caption_panel: PanelContainer
var _caption: Label
var _caption_timer: Timer
var _toast_panel: PanelContainer
var _toast: Label
var _overlays: Control


func _ready() -> void:
	_loc = CaseDB.locations[GameState.location]
	_img_size = Vector2(_loc["width"], _loc["height"])

	_world = Node2D.new()
	add_child(_world)
	var bg := Sprite2D.new()
	bg.texture = load(_loc["background"])
	bg.centered = false
	_world.add_child(bg)
	_fx = Node2D.new()
	_world.add_child(_fx)
	if "--show-hotspots" in OS.get_cmdline_user_args():
		_add_debug_rects()

	_build_hud()
	_overlays = Control.new()
	UI.full_rect(_overlays)
	_overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlays)

	_pan = -1.0
	resized.connect(_layout)
	_layout()
	GameState.evidence_added.connect(_on_evidence_added)
	_refresh_counter()

	if not GameState.has_flag("intro_seen"):
		_play_intro()


# ---------------------------------------------------------------- layout

func _layout() -> void:
	_scale = maxf(size.y / _img_size.y, size.x / _img_size.x)
	_max_pan = maxf(0.0, _img_size.x * _scale - size.x)
	if _pan < 0.0:
		_pan = float(_loc.get("start_x", _img_size.x / 2.0)) * _scale - size.x / 2.0
	_apply_pan()


func _apply_pan() -> void:
	_pan = clampf(_pan, 0.0, _max_pan)
	_world.scale = Vector2(_scale, _scale)
	_world.position = Vector2(-_pan, (size.y - _img_size.y * _scale) / 2.0)


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_dragging = false
			_press_pos = event.position
		elif _pressed:
			_pressed = false
			if not _dragging:
				_tap(event.position)
	elif event is InputEventMouseMotion and _pressed:
		if not _dragging and event.position.distance_to(_press_pos) > TAP_SLOP:
			_dragging = true
		if _dragging:
			_pan -= event.relative.x
			_apply_pan()


func _tap(screen_pos: Vector2) -> void:
	_hide_caption()
	var p: Vector2 = (screen_pos - _world.position) / _scale
	var hit := _hotspot_at(p)
	_fx.add_child(Ripple.new(p, Palette.AMBER if not hit.is_empty() else Color(Palette.PAPER, 0.5)))
	if hit.is_empty():
		return
	match hit["type"]:
		"evidence":
			_open_evidence(hit["evidence"])
		"detail":
			_show_caption(hit["text"])
		"talk":
			_open_dialogue(hit["character"])


func _hotspot_at(p: Vector2) -> Dictionary:
	var hotspots: Array = _loc["hotspots"]
	for i in range(hotspots.size() - 1, -1, -1):
		var h: Dictionary = hotspots[i]
		var r: Array = h["rect"]
		if Rect2(r[0], r[1], r[2], r[3]).has_point(p) and GameState.check(h.get("conditions", [])):
			return h
	return {}


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	_hud = UI.safe_container(self)
	add_child(_hud)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var loc_panel := PanelContainer.new()
	loc_panel.theme_type_variation = "BarPanel"
	loc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loc_panel.add_child(UI.label(_loc["name"], "NameLabel"))
	top.add_child(loc_panel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var count_panel := PanelContainer.new()
	count_panel.theme_type_variation = "BarPanel"
	count_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter = UI.label("")
	_counter.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count_panel.add_child(_counter)
	top.add_child(count_panel)
	var pause := UI.button("HUD_MENU")
	pause.pressed.connect(_open_pause)
	top.add_child(pause)

	_toast_panel = PanelContainer.new()
	_toast_panel.theme_type_variation = "BarPanel"
	_toast_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast = UI.label("")
	_toast.add_theme_color_override("font_color", Palette.JADE)
	_toast_panel.add_child(_toast)
	_toast_panel.modulate.a = 0.0
	col.add_child(_toast_panel)

	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(mid)

	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(bottom)
	_caption_panel = PanelContainer.new()
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption = UI.label("", "", true)
	UI.scaled_font(_caption, 34)
	_caption_panel.add_child(_caption)
	_caption_panel.modulate.a = 0.0
	bottom.add_child(_caption_panel)
	var file_btn := UI.button("HUD_CASE_FILE", "AccentButton")
	file_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	file_btn.custom_minimum_size = Vector2(320, 110)
	file_btn.pressed.connect(_open_case_file)
	bottom.add_child(file_btn)

	_caption_timer = Timer.new()
	_caption_timer.one_shot = true
	_caption_timer.timeout.connect(_hide_caption)
	add_child(_caption_timer)


func _refresh_counter() -> void:
	var all := CaseDB.location_evidence(GameState.location)
	var found := 0
	for id in all:
		if GameState.has_evidence(id):
			found += 1
	_counter.text = tr("HUD_EVIDENCE_COUNT") % [found, all.size()]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _counter:
		_refresh_counter()


func _show_caption(key: String) -> void:
	_caption.text = key
	_caption_panel.modulate.a = 1.0
	_caption_timer.start(6.0)


func _hide_caption() -> void:
	_caption_panel.modulate.a = 0.0


func _show_toast(key: String) -> void:
	_toast.text = key
	var t := create_tween()
	t.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	t.tween_interval(2.2)
	t.tween_property(_toast_panel, "modulate:a", 0.0, 0.5)


# ---------------------------------------------------------------- overlays

func _open_evidence(id: String) -> void:
	var card := EVIDENCE_CARD.instantiate()
	card.evidence_id = id
	card.collect = not GameState.has_evidence(id)
	card.closed.connect(_check_progress)
	_overlays.add_child(card)


func _on_evidence_added(_id: String) -> void:
	_refresh_counter()
	_show_toast("TOAST_EVIDENCE_ADDED")


func _open_dialogue(character: String) -> void:
	var view := DIALOGUE_VIEW.instantiate()
	view.character = character
	view.closed.connect(_check_progress)
	_overlays.add_child(view)


func _open_case_file() -> void:
	var cf := CASE_FILE.instantiate()
	cf.evidence_selected.connect(_open_evidence)
	_overlays.add_child(cf)


func _open_pause() -> void:
	var dim := UI.dim(0.7)
	_overlays.add_child(dim)
	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(620, 0)
	panel.add_child(box)
	box.add_child(UI.label("PAUSE_TITLE", "HeaderLabel"))
	var resume := UI.button("PAUSE_RESUME", "AccentButton")
	resume.pressed.connect(dim.queue_free)
	box.add_child(resume)
	var settings := UI.button("MENU_SETTINGS")
	settings.pressed.connect(func(): _overlays.add_child(SETTINGS_PANEL.instantiate()))
	box.add_child(settings)
	var quit := UI.button("PAUSE_MAIN_MENU")
	quit.pressed.connect(func():
		SaveManager.save_game()
		SceneRouter.goto(SceneRouter.MAIN_MENU))
	box.add_child(quit)
	box.add_child(UI.label("PAUSE_AUTOSAVE_NOTE", "SmallLabel"))


## Full-screen narration, one line at a time; tap to continue.
func _narrate(keys: Array, on_done: Callable) -> void:
	var bg := UI.dim(1.0)
	_overlays.add_child(bg)
	var safe := UI.safe_container(self)
	bg.add_child(safe)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(center)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)
	var text := UI.label(keys[0], "", true)
	text.custom_minimum_size = Vector2(1300, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.scaled_font(text, 44)
	box.add_child(text)
	var hint := UI.label("DLG_TAP_TO_CONTINUE", "SmallLabel")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var state := {"i": 0}
	bg.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			state["i"] += 1
			if state["i"] >= keys.size():
				on_done.call()
				var t := create_tween()
				t.tween_property(bg, "modulate:a", 0.0, 0.6)
				t.tween_callback(bg.queue_free)
			else:
				text.text = keys[state["i"]]
				text.modulate.a = 0.0
				create_tween().tween_property(text, "modulate:a", 1.0, 0.4))


func _play_intro() -> void:
	_narrate(CaseDB.meta["intro"], func(): GameState.set_flag("intro_seen"))


## Prototype only: tells the player when everything in this build has been found.
func _check_progress() -> void:
	if GameState.has_flag("prototype_done"):
		return
	for id in CaseDB.location_evidence(GameState.location):
		if not GameState.has_evidence(id):
			return
	if not GameState.has_flag("erdem_confessed"):
		return
	GameState.set_flag("prototype_done")
	_narrate(["PROTOTYPE_DONE"], func(): pass)


func _add_debug_rects() -> void:
	for h in _loc["hotspots"]:
		var r: Array = h["rect"]
		var box := ReferenceRect.new()
		box.editor_only = false
		box.border_color = Palette.RED
		box.border_width = 4.0
		box.position = Vector2(r[0], r[1])
		box.size = Vector2(r[2], r[3])
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_world.add_child(box)
