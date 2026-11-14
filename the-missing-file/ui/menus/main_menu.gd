extends Control
## Main menu: continue the last case, choose a case, guide, achievements,
## settings and credits. Shows the detective's current rank.

var _continue: Button
var _rank: Label


func _ready() -> void:
	add_child(Backdrop.new("res://assets/ui/menu_bg.png"))
	var safe := UI.safe_container(self)
	add_child(safe)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 10)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 90)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)
	safe.add_child(pad)

	var title := UI.label("GAME_TITLE", "TitleLabel")
	title.add_theme_font_size_override("font_size", 88)
	col.add_child(title)
	_rank = UI.label("", "NameLabel")
	_rank.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	col.add_child(_rank)
	col.add_child(UI.spacer(6))

	_continue = UI.button("MENU_CONTINUE", "AccentButton")
	_continue.pressed.connect(_on_continue)
	var cases := UI.button("MENU_CASES")
	cases.pressed.connect(func(): add_child(CaseList.new()))
	var office := UI.button("MENU_OFFICE")
	office.pressed.connect(_open_office)
	var howto := UI.button("MENU_HOWTO")
	howto.pressed.connect(func(): add_child(HowToPlay.new()))
	var achievements := UI.button("MENU_ACHIEVEMENTS")
	achievements.pressed.connect(func(): add_child(AchievementsList.new()))
	var settings := UI.button("MENU_SETTINGS")
	settings.pressed.connect(func(): add_child(load("res://ui/menus/settings_panel.tscn").instantiate()))
	var credits := UI.button("MENU_CREDITS")
	credits.pressed.connect(_on_credits)
	for b in [_continue, office, cases, howto, achievements, settings, credits]:
		b.custom_minimum_size = Vector2(560, 76)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(b)

	var ver := UI.label("", "SmallLabel")
	ver.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ver.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	ver.size_flags_horizontal = Control.SIZE_SHRINK_END
	ver.size_flags_vertical = Control.SIZE_SHRINK_END
	safe.add_child(ver)
	_refresh()


func _refresh() -> void:
	_continue.visible = SaveManager.has_save(Profile.last_case)
	_rank.text = "%s  ·  %d XP" % [tr(Profile.rank()["name"]), Profile.xp()]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _rank:
		_refresh()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _on_continue() -> void:
	if SaveManager.load_game(Profile.last_case):
		SceneRouter.goto(SceneRouter.GAME)


func _open_office() -> void:
	SceneRouter.open_office()


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
