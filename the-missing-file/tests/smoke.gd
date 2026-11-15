extends Node
## Drives the real game flow (menus, scene changes, taps, travel) to catch
## runtime errors that data tests cannot see.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/smoke.tscn


var runner := false
var _finished := false
var _failed := false


func _ready() -> void:
	if not runner:
		# The game replaces the current scene, so the test lives beside it.
		var copy: Node = load("res://tests/smoke.gd").new()
		copy.runner = true
		get_tree().root.add_child.call_deferred(copy)
		return
	GameState.active = false
	SaveManager.enabled = false
	Settings.persist = false
	Profile.persist = false
	Profile.reset()
	await _run()
	# A script error ends _run early, so only report success if it reached its last line.
	if _failed:
		print("SMOKE FAILED: a check failed")
	else:
		print("SMOKE OK" if _finished else "SMOKE FAILED: the run stopped early")
	get_tree().quit()


func _check(condition: bool, message: String = "") -> void:
	if not condition:
		_failed = true
		print("SMOKE CHECK FAILED: ", message)
		push_error("smoke check failed: " + message)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _game() -> Node:
	return get_tree().current_scene


func _tap_hotspot(id: String) -> void:
	var game := _game()
	for h in game._loc["hotspots"]:
		if h["id"] == id:
			var r: Array = h["rect"]
			var world := Vector2(r[0] + r[2] / 2.0, r[1] + r[3] / 2.0)
			game._pan = world.x * game._scale - game.size.x / 2.0
			game._apply_pan()
			game._tap(world * game._scale + game._world.position)
			return
	push_error("smoke: no hotspot " + id)


func _close_overlays() -> void:
	for c in _game()._overlays.get_children():
		c.queue_free()
	await _wait(0.2)


func _run() -> void:
	Settings.locale = "en"
	TranslationServer.set_locale("en")
	get_tree().change_scene_to_file(SceneRouter.MAIN_MENU)
	await _wait(0.5)
	var menu := get_tree().current_scene
	menu.add_child(CaseList.new())
	menu.add_child(AchievementsList.new())
	await _wait(0.4)
	GameState.new_game()
	GameState.active = false
	GameState.set_flag("intro_seen")
	SceneRouter.goto(SceneRouter.GAME)
	await _wait(1.2)
	for id in ["door", "newspaper", "erdem", "bin"]:
		_tap_hotspot(id)
		await _wait(0.4)
		await _close_overlays()
	_game()._on_hint()
	await _wait(1.5)
	for f in ["erdem_met", "visited_office"]:
		GameState.set_flag(f)
	for target in ["office", "stacks", "director", "lobby"]:
		_game()._open_map()
		await _wait(0.2)
		_game()._travel(target)
		await _wait(1.2)
		_check(GameState.location == target)
		_game()._on_hint()
		for h in _game()._loc["hotspots"]:
			if GameState.check(h.get("conditions", [])) and h["type"] != "exit":
				_tap_hotspot(h["id"])
				await _wait(0.15)
				await _close_overlays()
	for opener in ["_open_board", "_open_case_file", "_open_accusation", "_open_pause"]:
		_game().call(opener)
		await _wait(0.3)
		_game()._notification_back()
		await _wait(0.3)
		_check(_game()._overlays.get_child_count() == 0, "back button closes " + opener)
	await _test_finger_scroll()
	_game().add_child(HowToPlay.new())
	await _wait(0.4)
	# a conversation with press, a wrong challenge and the verdict screen with career data
	_game()._open_dialogue("erdem")
	await _wait(0.4)
	var view: Node = _game()._overlays.get_child(0)
	for i in 8:
		if view._runner.can_press():
			view._show_state(view._runner.press())
			break
		if view._state == DialogueRunner.CHOICES:
			view._on_choice(view._runner.choices()[0])
		else:
			view._show_state(view._runner.advance())
		await _wait(0.1)
	await _wait(0.3)
	await _close_overlays()
	var result := Profile.record_verdict("case_01", "A", true, Verdict.rating(), [])
	result["achievements"] = Achievements.evaluate("A")
	_game()._open_ending("A", result)
	await _wait(1.0)
	await _close_overlays()
	await _case_two()
	TranslationServer.set_locale("tr")
	_game()._open_ending("B", {"weak": ["WEAK_LINK", "WEAK_FILE_MISSING"]})
	await _wait(1.0)
	await _close_overlays()
	TranslationServer.set_locale("en")
	await _office()
	_finished = true


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


## Drags a finger up the Board's card list, starting on a card button.
## The list must scroll and the card must not be selected.
func _test_finger_scroll() -> void:
	for id in CaseDB.countable_evidence():
		GameState.add_evidence(id)
	for id in CaseDB.meta["testimony"]:
		GameState.add_testimony(id)
	Settings.board_view = "wall"
	_game()._open_board()
	await _wait(0.6)
	var board: Node = _game()._overlays.get_child(0)
	await _test_wall(board)
	board._set_view("list")
	await _wait(0.3)
	var card: Control = _visible_card(board, 1)
	var start: Vector2 = card.get_global_rect().get_center()
	_touch(start, true)
	await _wait(0.05)
	for i in 12:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.relative = Vector2(0, -30)
		d.position = start + Vector2(0, -30 * (i + 1))
		Input.parse_input_event(d)
		await get_tree().process_frame
	_touch(start + Vector2(0, -360), false)
	await _wait(0.3)
	print("finger scroll moved list by ", board._scroll.scroll_vertical, " px; cards selected: ", board._selected.size())
	_check(board._scroll.scroll_vertical > 100, "dragging over buttons scrolls the list")
	_check(board._selected.is_empty(), "a drag must not select a card")
	card = _visible_card(board, 0)
	_touch(card.get_global_rect().get_center(), true)
	await _wait(0.05)
	_touch(card.get_global_rect().get_center(), false)
	await _wait(0.2)
	_check(board._selected.size() == 1, "a plain tap still selects a card")
	print("tap still selects: ", board._selected.size())
	await _close_overlays()


## Walks through every location of Case 2, taps everything, opens the database.
func _case_two() -> void:
	GameState.new_game("case_02")
	GameState.active = false
	GameState.set_flag("intro_seen")
	GameState.set_flag("soykan_met")
	SceneRouter.goto(SceneRouter.GAME)
	await _wait(1.3)
	_check(GameState.case_id == "case_02" and GameState.location == "road")
	for target in ["newsroom", "site", "planning", "road"]:
		_game()._travel(target)
		await _wait(1.2)
		_check(GameState.location == target)
		for h in _game()._loc["hotspots"]:
			if GameState.check(h.get("conditions", [])) and h["type"] != "exit":
				_tap_hotspot(h["id"])
				await _wait(0.15)
				await _close_overlays()
		_game()._on_hint()
	for id in ["E03", "E05", "E15"]:
		GameState.add_evidence(id)
	_game()._open_case_file()
	await _wait(0.3)
	var cf: Node = _game()._overlays.get_child(0)
	_check(cf._tabs.size() == 5, "Case 2 has a Database tab")
	cf._show_tab(4)
	await _wait(0.3)
	await _close_overlays()
	_game()._open_evidence("E21")
	await _wait(0.4)
	await _close_overlays()
	print("case 2 walk OK")


## The n-th card whose centre is inside the visible part of the Board's list.
func _visible_card(board: Node, n: int) -> Control:
	var area: Rect2 = board._scroll.get_global_rect().grow(-40)
	var found: Array = []
	for id in board._buttons:
		var c: Control = board._buttons[id]
		if area.has_point(c.get_global_rect().get_center()):
			found.append(c)
	_check(found.size() > n, "the Board shows at least %d cards without scrolling" % (n + 1))
	return found[n]


## The office between cases: cards arrive, the wall opens, the folders list the cases.
func _office() -> void:
	Profile.record_verdict("case_01", "B", false, {"score": 40, "grade": "C"}, ["file_found"])
	Profile.record_verdict("case_02", "A", true, {"score": 90, "grade": "S"}, ["file_found", "registry_seen", "guven_source", "soykan_remark"])
	SceneRouter.open_office()
	await _wait(1.4)
	_check(GameState.case_id == "office" and GameState.location == "office")
	GameState.set_flag("intro_seen")
	await _close_overlays()
	_check(GameState.evidence.size() == CaseDB.evidence.size(), "carried cards arrive on entering the office")
	for id in ["ledger", "folders", "frame", "shelf", "window"]:
		_tap_hotspot(id)
		await _wait(0.4)
		_check(_game()._overlays.get_child_count() <= 1)
		await _close_overlays()
	_game()._on_hint()
	_game()._open_case_file()
	await _wait(0.3)
	await _close_overlays()
	print("office OK")


func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.global_position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _mouse_drag(from: Vector2, delta: Vector2, steps: int = 10) -> void:
	_mouse(from, true)
	await _wait(0.05)
	for i in steps:
		var m := InputEventMouseMotion.new()
		m.position = from + delta * float(i + 1) / steps
		m.global_position = m.position
		m.relative = delta / steps
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
		await get_tree().process_frame
	_mouse(from + delta, false)
	await _wait(0.15)


func _finger(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _finger_move(index: int, pos: Vector2, relative: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = pos
	d.relative = relative
	Input.parse_input_event(d)


## The evidence wall: tap selects, dragging a note moves it and is remembered,
## dragging the cork pans, two fingers zoom, the buttons zoom, Tidy resets.
func _test_wall(board: Node) -> void:
	var wall: BoardCanvas = board._wall
	_check(wall.visible and not board._scroll.visible, "the board opens on the wall")
	_check(wall._notes.size() == GameState.all_cards().size(), "one note per card")
	var id: String = GameState.evidence[0]
	var n: BoardNote = wall.note(id)
	var at: Vector2 = n.get_global_rect().get_center()

	_mouse(at, true)
	await _wait(0.05)
	_mouse(at, false)
	await _wait(0.2)
	_check(board._selected == [id], "tapping a note selects it")
	board._selected.clear()
	board._refresh_selection()

	var before: Vector2 = n.position
	await _mouse_drag(at, Vector2(160, 90))
	_check(n.position.distance_to(before) > 100, "dragging a note moves it")
	_check(board._selected.is_empty(), "dragging a note does not select it")
	_check(GameState.board_layout.has(id), "the new place is remembered")
	var moved_by: Vector2 = (n.position - before) * wall.zoom
	_check(moved_by.distance_to(Vector2(160, 90)) < 12, "the note follows the finger exactly at any zoom (moved %s)" % moved_by)

	var pan_from: Vector2 = wall.get_global_rect().position + Vector2(wall.size.x - 60, wall.size.y - 40)
	var content_before: Vector2 = wall._content.position
	await _mouse_drag(pan_from, Vector2(-40, -220))
	_check(wall._content.position.distance_to(content_before) > 100, "dragging the cork pans the wall")

	var z := wall.zoom
	var c: Vector2 = wall.get_global_rect().get_center()
	_finger(0, c + Vector2(-150, 0), true)
	_finger(1, c + Vector2(150, 0), true)
	await get_tree().process_frame
	for i in 8:
		_finger_move(0, c + Vector2(-150 - 20 * (i + 1), 0), Vector2(-20, 0))
		_finger_move(1, c + Vector2(150 + 20 * (i + 1), 0), Vector2(20, 0))
		await get_tree().process_frame
	_finger(0, c + Vector2(-310, 0), false)
	_finger(1, c + Vector2(310, 0), false)
	await _wait(0.15)
	_check(wall.zoom > z * 1.3, "spreading two fingers zooms in (%.2f -> %.2f)" % [z, wall.zoom])
	_check(board._selected.is_empty(), "a pinch selects nothing")
	z = wall.zoom
	wall.zoom_by(0.8)
	_check(wall.zoom < z, "the minus button zooms out")

	GameState.clear_board_layout()
	wall.build()
	wall.fit()
	await _wait(0.2)
	_check(wall.note(id).position == BoardLayout.positions()[id], "Tidy puts notes back")
	board._on_hint()
	await _wait(0.3)
	_check(board._selected.size() == 2, "Hint selects a pair on the wall")
	var view := Rect2(Vector2.ZERO, wall.size)
	var first_note: BoardNote = wall.note(board._selected[0])
	var r: Rect2 = Rect2(wall._content.position + first_note.position * wall.zoom, first_note.size * wall.zoom)
	_check(view.encloses(r), "Hint brings the first note fully into view")
	_check(wall.zoom >= BoardCanvas.READABLE - 0.01, "Hint never zooms out too far to read (zoom %.2f)" % wall.zoom)
	board._selected.clear()
	board._refresh_selection()
	print("wall OK: zoom %.2f, %d notes" % [wall.zoom, wall._notes.size()])
