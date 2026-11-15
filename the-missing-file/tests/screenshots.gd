extends Control
## Developer tool: renders screens to PNG files for visual checking.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 \
##       res://tests/screenshots.tscn -- <output dir> [scenes|ui] [--show-hotspots]

var _out := "user://shots"
var _mode := "ui"
var _case := "case_01"
var _current: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["scenes", "ui"]:
			_mode = a
		elif a.begins_with("case_"):
			_case = a
		elif not a.begins_with("--"):
			_out = a
	DirAccess.make_dir_recursive_absolute(_out)
	GameState.active = false
	SaveManager.enabled = false
	Settings.persist = false
	Profile.persist = false
	Profile.reset()
	if _case == "case_office":
		await _office_shots()
		get_tree().quit()
		return
	if _case != "case_01":
		await _other_case()
		get_tree().quit()
		return
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
	_current.add_child(CaseList.new())
	await _snap("02c_cases_tr")
	Profile.unlock("CONFESSION")
	Profile.unlock("GENTLE")
	await _show("res://ui/menus/main_menu.tscn")
	_current.add_child(AchievementsList.new())
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
	Settings.board_view = "wall"
	game._open_board()
	var board: Node = game._overlays.get_child(0)
	await _snap("07_wall_en")
	board._on_hint()
	await _snap("07_wall_hint_en")
	board._wall.zoom_by(1.5)
	await _snap("07_wall_zoom_en")
	board._set_view("list")
	await _snap("07_board_hint_en")
	game = await _game("director")
	game._open_dialogue("vardar")
	var v2: Node = game._overlays.get_child(0)
	while v2._state != DialogueRunner.CHOICES:
		v2._show_state(v2._runner.advance())
	v2._on_choice(v2._runner.choices()[0])
	v2._show_state(v2._runner.advance())
	v2._finish_typing()
	await _snap("07b_present_glow_en", 1.2)
	v2._open_picker()
	await _snap("07c_present_picker_en")
	game = await _game("lobby")
	await _snap("07d_hud_guidance_en")
	game._open_map()
	await _snap("07e_map_en")
	game = await _game("lobby")
	game._open_ending("B", {"weak": ["WEAK_MOTIVE", "WEAK_FILE_DAMAGED"]})
	await _snap("07f_weak_en", 1.4)
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


## Late-game state for any other case: everything found, everyone met.
func _other_case() -> void:
	GameState.new_game(_case)
	GameState.active = false
	GameState.set_flag("intro_seen")
	for id in CaseDB.locations:
		GameState.set_flag("visited_" + id)
	for ch in CaseDB.characters:
		GameState.set_flag(ch + "_met")
	for id in CaseDB.countable_evidence():
		GameState.add_evidence(id)
	for id in CaseDB.meta["testimony"]:
		GameState.add_testimony(id)
	var n := 0
	for id in CaseDB.insights:
		if n % 2 == 0:
			GameState.add_insight(id)
		n += 1
	TranslationServer.set_locale("en")
	if _mode == "scenes":
		await _scenes()
		return
	TranslationServer.set_locale("tr")
	var game := await _game(CaseDB.meta["start_location"])
	await _snap("c_01_start_tr")
	game._open_map()
	await _snap("c_02_map_tr")
	game = await _game(CaseDB.meta["start_location"])
	game._open_case_file()
	var cf: Node = game._overlays.get_child(0)
	cf._show_tab(4)
	await _snap("c_03_records_tr")
	cf._show_tab(2)
	await _snap("c_04_suspects_tr")
	cf._show_tab(3)
	await _snap("c_05_timeline_tr")
	cf._show_tab(0)
	await _snap("c_06_objectives_tr")
	game = await _game(CaseDB.meta["start_location"])
	game._open_evidence("E21")
	await _snap("c_07_record_card_tr")
	game = await _game(CaseDB.meta["start_location"])
	game._open_dialogue("soykan")
	await _snap("c_08_chief_tr", 2.0)
	TranslationServer.set_locale("en")
	game = await _game(CaseDB.meta["start_location"])
	game._open_accusation()
	await _snap("c_09_accuse_en")
	await _show("res://ui/menus/main_menu.tscn")
	_current.add_child(CaseList.new())
	await _snap("c_10_cases_en")


func _office_shots() -> void:
	Profile.record_verdict("case_01", "B", false, {"score": 40, "grade": "C"}, ["file_found"])
	Profile.record_verdict("case_02", "A", true, {"score": 90, "grade": "S"}, ["file_found", "registry_seen", "guven_source", "soykan_remark"])
	GameState.new_game("office")
	GameState.active = false
	GameState.set_flag("intro_seen")
	TranslationServer.set_locale("tr")
	Settings.locale = "tr"
	var game := await _game("office")
	await _snap("o_01_office_tr")
	Settings.board_view = "wall"
	game._open_board()
	var board: Node = game._overlays.get_child(0)
	for id in ["LI_SAME_HAND", "LI_FENER", "LI_KARACA"]:
		GameState.add_insight(id)
	board._rebuild()
	await _snap("o_02_ledger_tr")
	game = await _game("office")
	game._do_action("cases")
	await _snap("o_03_cases_tr")
	game = await _game("office")
	game._open_case_file()
	var cf: Node = game._overlays.get_child(0)
	await _snap("o_04_objectives_tr")
	cf._show_tab(3)
	await _snap("o_05_timeline_tr")
	TranslationServer.set_locale("en")
	game = await _game("office")
	game._do_action("achievements")
	await _snap("o_06_achievements_en")
	await _show("res://ui/menus/main_menu.tscn")
	await _snap("o_07_menu_en")
	if "--show-hotspots" in OS.get_cmdline_user_args():
		game = await _game("office")
		await _snap("o_08_hotspots")
