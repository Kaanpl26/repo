extends Control
## Developer tool: renders the main screens to PNG files for visual checking.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 res://tests/screenshots.tscn -- <output dir>

var _out := "user://shots"
var _current: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if not a.begins_with("--"):
			_out = a
	DirAccess.make_dir_recursive_absolute(_out)
	GameState.active = false
	await _run()
	get_tree().quit()


func _show(path: String, setup: Callable = Callable()) -> Node:
	if _current:
		_current.queue_free()
		await get_tree().process_frame
	_current = load(path).instantiate()
	if setup.is_valid():
		setup.call(_current)
	add_child(_current)
	return _current


func _snap(name: String, wait: float = 0.9) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("saved ", name)


func _run() -> void:
	TranslationServer.set_locale("en")
	await _show("res://ui/menus/language_select.tscn")
	await _snap("01_language")
	Settings.locale = "tr"
	TranslationServer.set_locale("tr")
	await _show("res://ui/menus/main_menu.tscn")
	await _snap("02_menu_tr")
	var s: Node = load("res://ui/menus/settings_panel.tscn").instantiate()
	_current.add_child(s)
	await _snap("03_settings_tr")

	GameState.new_game()
	GameState.active = false
	TranslationServer.set_locale("en")
	var game := await _show("res://systems/investigation/game.tscn")
	await _snap("04_intro_en")
	GameState.set_flag("intro_seen")
	for id in ["E01", "E04", "E05"]:
		GameState.add_evidence(id)
	game = await _show("res://systems/investigation/game.tscn")
	await _snap("05_lobby_en")
	game._open_evidence("E02")
	await _snap("06_evidence_en")
	TranslationServer.set_locale("tr")
	game = await _show("res://systems/investigation/game.tscn")
	game._open_evidence("E05")
	await _snap("07_evidence_tr")
	game = await _show("res://systems/investigation/game.tscn")
	game._open_dialogue("erdem")
	await _snap("08_dialogue_tr", 2.5)
	var view: Node = game._overlays.get_child(0)
	view._show_state(view._runner.advance())
	view._show_state(view._runner.advance())
	view._show_state(view._runner.advance())
	await _snap("09_choices_tr")
	view._on_choice(view._runner.choices()[1])
	view._show_state(view._runner.advance())
	await _snap("10_present_tr", 3.0)
	view._open_picker()
	await _snap("11_picker_tr")
	TranslationServer.set_locale("en")
	game = await _show("res://systems/investigation/game.tscn")
	game._open_case_file()
	await _snap("12_casefile_en")
