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
	TranslationServer.set_locale("tr")
	_game()._open_ending("B")
	await _wait(1.0)
