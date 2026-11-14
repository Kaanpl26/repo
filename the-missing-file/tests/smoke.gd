extends Node
## Drives the real game flow (menus, scene changes, taps, travel) to catch
## runtime errors that data tests cannot see.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/smoke.tscn


var runner := false


func _ready() -> void:
	if not runner:
		# The game replaces the current scene, so the test lives beside it.
		var copy: Node = load("res://tests/smoke.gd").new()
		copy.runner = true
		get_tree().root.add_child.call_deferred(copy)
		return
	GameState.active = false
	Profile.persist = false
	Profile.reset()
	await _run()
	print("SMOKE OK")
	get_tree().quit()


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
	menu._open_cases()
	menu._open_achievements()
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
		assert(GameState.location == target)
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
		assert(_game()._overlays.get_child_count() == 0, "back button closes " + opener)
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
	_game()._open_ending("B")
	await _wait(1.0)


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
	_game()._open_board()
	await _wait(0.5)
	var board: Node = _game()._overlays.get_child(0)
	var card: Button = board._buttons[GameState.evidence[4]]
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
	assert(board._scroll.scroll_vertical > 100, "dragging over buttons scrolls the list")
	assert(board._selected.is_empty(), "a drag must not select a card")
	card = board._buttons[GameState.evidence[6]]
	_touch(card.get_global_rect().get_center(), true)
	await _wait(0.05)
	_touch(card.get_global_rect().get_center(), false)
	await _wait(0.2)
	assert(board._selected.size() == 1, "a plain tap still selects a card")
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
	assert(GameState.case_id == "case_02" and GameState.location == "road")
	for target in ["newsroom", "site", "planning", "road"]:
		_game()._travel(target)
		await _wait(1.2)
		assert(GameState.location == target)
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
	assert(cf._tabs.size() == 5, "Case 2 has a Database tab")
	cf._show_tab(4)
	await _wait(0.3)
	await _close_overlays()
	_game()._open_evidence("E21")
	await _wait(0.4)
	await _close_overlays()
	print("case 2 walk OK")
