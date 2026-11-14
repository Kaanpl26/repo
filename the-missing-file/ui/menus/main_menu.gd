extends Control

var _continue: Button
var _confirm: Control


func _ready() -> void:
	add_child(Backdrop.new("res://assets/ui/menu_bg.png"))
	var safe := UI.safe_container(self)
	add_child(safe)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 12)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 90)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)
	safe.add_child(pad)

	col.add_child(UI.label("GAME_TITLE", "TitleLabel"))
	var sub := UI.label("GAME_SUBTITLE", "SmallLabel")
	col.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	col.add_child(gap)

	_continue = UI.button("MENU_CONTINUE", "AccentButton")
	_continue.pressed.connect(_on_continue)
	var new_game := UI.button("MENU_NEW_GAME")
	new_game.pressed.connect(_on_new_game)
	var settings := UI.button("MENU_SETTINGS")
	settings.pressed.connect(_on_settings)
	var credits := UI.button("MENU_CREDITS")
	credits.pressed.connect(_on_credits)
	var howto := UI.button("MENU_HOWTO")
	howto.pressed.connect(func(): add_child(HowToPlay.new()))
	for b in [_continue, new_game, howto, settings, credits]:
		b.custom_minimum_size = Vector2(560, 88)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(b)
	_continue.visible = SaveManager.has_save()

	var ver := UI.label("", "SmallLabel")
	ver.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ver.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	ver.size_flags_horizontal = Control.SIZE_SHRINK_END
	ver.size_flags_vertical = Control.SIZE_SHRINK_END
	safe.add_child(ver)


func _on_continue() -> void:
	if SaveManager.load_game():
		SceneRouter.goto(SceneRouter.GAME)


func _on_new_game() -> void:
	if SaveManager.has_save():
		_ask_overwrite()
	else:
		_start_new()


func _start_new() -> void:
	GameState.new_game()
	SceneRouter.goto(SceneRouter.GAME)


func _ask_overwrite() -> void:
	_confirm = UI.dim(0.7)
	add_child(_confirm)
	var center := CenterContainer.new()
	UI.full_rect(center)
	_confirm.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	panel.add_child(box)
	var msg := UI.label("MENU_OVERWRITE_WARNING", "", true)
	msg.custom_minimum_size = Vector2(820, 0)
	box.add_child(msg)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var no := UI.button("COMMON_CANCEL")
	no.pressed.connect(_confirm.queue_free)
	var yes := UI.button("MENU_OVERWRITE_CONFIRM", "AccentButton")
	yes.pressed.connect(_start_new)
	row.add_child(no)
	row.add_child(yes)


func _on_settings() -> void:
	var s: Control = load("res://ui/menus/settings_panel.tscn").instantiate()
	add_child(s)
	s.closed.connect(func(): _continue.visible = SaveManager.has_save())


func _on_credits() -> void:
	var parts := UI.popup(1100.0)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	box.add_child(UI.label("CREDITS_TITLE", "HeaderLabel"))
	var text := UI.label("CREDITS_BODY", "", true)
	UI.scaled_font(text, 32)
	box.add_child(text)
	var close := UI.button("COMMON_CLOSE", "AccentButton")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(root.queue_free)
	box.add_child(close)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
