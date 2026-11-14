extends Control
## Developer tool: renders screens to PNG files for visual checking.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 \
##       res://tests/screenshots.tscn -- <output dir> [scenes|ui] [--show-hotspots]

var _out := "user://shots"
var _mode := "ui"
var _current: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["scenes", "ui"]:
			_mode = a
		elif not a.begins_with("--"):
			_out = a
	DirAccess.make_dir_recursive_absolute(_out)
	GameState.active = false
	Profile.persist = false
	Profile.reset()
	_fill_state()
	if _mode == "scenes":
		await _scenes()
	else:
		await _ui()
	get_tree().quit()


## A late-game state so that every screen has content.
func _fill_state() -> void:
	GameState.new_game()
	GameState.active = false
	for f in ["intro_seen", "erdem_met", "erdem_confessed", "aydin_met", "vardar_met", "aras_met", "vardar_asked",
			"visited_lobby", "visited_office", "visited_stacks", "visited_director"]:
		GameState.set_flag(f)
	for id in CaseDB.countable_evidence():
		if id != "E17":
			GameState.add_evidence(id)
	for id in CaseDB.meta["testimony"]:
		if id != "T_AYDIN_3":
			GameState.add_testimony(id)
	for id in ["I_UNGUARDED", "I_ARAS_ELSEWHERE", "I_NOT_ACCIDENT", "I_SM", "I_VARDAR_RETURNED"]:
		GameState.add_insight(id)


func _show(path: String) -> Node:
	if _current:
		_current.queue_free()
		await get_tree().process_frame
	_current = load(path).instantiate()
	add_child(_current)
	return _current


func _snap(name: String, wait: float = 0.8) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("saved ", name)


func _game(location: String) -> Node:
	GameState.location = location
	return await _show("res://systems/investigation/game.tscn")


func _scenes() -> void:
	TranslationServer.set_locale("en")
	for id in CaseDB.locations:
		var game := await _game(id)
		for pan in [0.0, 99999.0]:
			game._pan = pan
			game._apply_pan()
			await _snap("%s_%s" % [id, "left" if pan == 0.0 else "right"], 0.4)


func _ui() -> void:
	TranslationServer.set_locale("tr")
	Settings.locale = "tr"
	await _show("res://ui/menus/main_menu.tscn")
	await _snap("01_menu_tr")
	_current.add_child(load("res://ui/menus/settings_panel.tscn").instantiate())
	await _snap("02_settings_tr")
	await _show("res://ui/menus/main_menu.tscn")
	_current._open_cases()
	await _snap("02c_cases_tr")
	Profile.unlock("CONFESSION")
	Profile.unlock("GENTLE")
	await _show("res://ui/menus/main_menu.tscn")
	_current._open_achievements()
	await _snap("02d_achievements_tr")
	var game := await _game("office")
	await _snap("03_office_tr")
	game._open_map()
	await _snap("04_map_tr")
	game = await _game("director")
	game._open_dialogue("vardar")
	var view: Node = game._overlays.get_child(0)
	GameState.lose_patience("vardar")
	while view._state != DialogueRunner.CHOICES:
		view._show_state(view._runner.advance())
	view._on_choice(view._runner.choices()[0])
	await _snap("05_dialogue_tr", 2.0)
	view._show_state(view._runner.press())
	view._show_state(view._runner.advance())
	await _snap("05b_pressed_tr", 2.0)
	TranslationServer.set_locale("en")
	game = await _game("stacks")
	game._open_evidence("E16")
	await _snap("06_evidence_en")
	game = await _game("stacks")
	game._open_board()
	var board: Node = game._overlays.get_child(0)
	board._on_hint()
	await _snap("07_board_hint_en")
	game = await _game("lobby")
	game._open_case_file()
	var cf: Node = game._overlays.get_child(0)
	await _snap("08_objectives_en")
	cf._show_tab(2)
	await _snap("09_suspects_en")
	cf._show_tab(3)
	await _snap("10_timeline_en")
	game = await _game("lobby")
	game._open_accusation()
	var acc: Node = game._overlays.get_child(0)
	acc._choose("vardar")
	acc._slots = {"motive": "I_SM", "opportunity": "I_VARDAR_RETURNED"}
	acc._show_proof()
	await _snap("11_proof_en")
	GameState.add_evidence("E17")
	GameState.set_flag("erdem_spared")
	game = await _game("lobby")
	var result := Profile.record_verdict("case_01", "A", true, {"score": 86, "grade": "A"}, [])
	result["achievements"] = ["FIRST_CASE", "MIRROR"]
	game._open_ending("A", result)
	await _snap("12_ending_a_en", 1.4)
	TranslationServer.set_locale("tr")
	game = await _game("lobby")
	game._open_ending("A")
	await _snap("13_ending_a_tr", 1.4)
