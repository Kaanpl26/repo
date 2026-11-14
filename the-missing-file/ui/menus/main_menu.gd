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
	title.add_theme_font_size_override("font_size", 96)
	col.add_child(title)
	_rank = UI.label("", "NameLabel")
	_rank.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	col.add_child(_rank)
	col.add_child(UI.spacer(6))

	_continue = UI.button("MENU_CONTINUE", "AccentButton")
	_continue.pressed.connect(_on_continue)
	var cases := UI.button("MENU_CASES")
	cases.pressed.connect(_open_cases)
	var howto := UI.button("MENU_HOWTO")
	howto.pressed.connect(func(): add_child(HowToPlay.new()))
	var achievements := UI.button("MENU_ACHIEVEMENTS")
	achievements.pressed.connect(_open_achievements)
	var settings := UI.button("MENU_SETTINGS")
	settings.pressed.connect(func(): add_child(load("res://ui/menus/settings_panel.tscn").instantiate()))
	var credits := UI.button("MENU_CREDITS")
	credits.pressed.connect(_on_credits)
	for b in [_continue, cases, howto, achievements, settings, credits]:
		b.custom_minimum_size = Vector2(560, 84)
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


func _start(case_id: String) -> void:
	SaveManager.delete_save(case_id)
	GameState.new_game(case_id)
	SceneRouter.goto(SceneRouter.GAME)


func _resume(case_id: String) -> void:
	if SaveManager.load_game(case_id):
		SceneRouter.goto(SceneRouter.GAME)


# ---------------------------------------------------------------- case list

func _open_cases() -> void:
	var parts := UI.popup(1400.0)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	box.add_child(UI.label("CASES_TITLE", "HeaderLabel"))
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 600)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in CaseDB.index:
		list.add_child(_case_row(entry, root))
	var close := UI.button("COMMON_CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(root.queue_free)
	box.add_child(close)


func _case_row(entry: Dictionary, popup: Control) -> Control:
	var id: String = entry["id"]
	var open := CaseDB.case_open(id)
	var row := PanelContainer.new()
	row.theme_type_variation = "BarPanel"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	row.add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var name_label := UI.label("", "NameLabel")
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	name_label.text = tr("CASES_NUMBER") % [int(entry["number"]), tr(entry["title"])]
	v.add_child(name_label)
	var status := UI.label("", "SmallLabel")
	status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.add_child(status)
	if not entry.get("available", false):
		status.text = tr("CASES_NOT_IN_BUILD")
		row.modulate = Color(1, 1, 1, 0.5)
		return row
	if not open:
		status.text = tr("CASES_LOCKED")
		row.modulate = Color(1, 1, 1, 0.5)
		return row
	var has_save := SaveManager.has_save(id)
	if Profile.is_solved(id):
		status.text = tr("CASES_SOLVED") % Profile.best[id]["grade"]
		status.add_theme_color_override("font_color", Palette.JADE)
	elif has_save:
		status.text = tr("CASES_IN_PROGRESS")
	else:
		status.text = tr("CASES_NEW")
	if has_save:
		var cont := UI.button("MENU_CONTINUE", "AccentButton")
		cont.pressed.connect(_resume.bind(id))
		h.add_child(cont)
		var restart := UI.button("CASES_RESTART")
		restart.pressed.connect(_confirm_restart.bind(id))
		h.add_child(restart)
	else:
		var start := UI.button("CASES_START", "AccentButton")
		start.pressed.connect(_start.bind(id))
		h.add_child(start)
	return row


func _confirm_restart(case_id: String) -> void:
	var parts := UI.popup(820.0, 0.8)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	box.add_child(UI.label("MENU_OVERWRITE_WARNING", "", true))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var no := UI.button("COMMON_CANCEL")
	no.pressed.connect(root.queue_free)
	row.add_child(no)
	var yes := UI.button("MENU_OVERWRITE_CONFIRM", "DangerButton")
	yes.pressed.connect(_start.bind(case_id))
	row.add_child(yes)


# ---------------------------------------------------------------- achievements

func _open_achievements() -> void:
	var parts := UI.popup(1400.0)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UI.label("ACH_TITLE", "HeaderLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var count := UI.label("", "NameLabel")
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = "%d / %d" % [Profile.achievements.size(), CaseDB.achievements.size()]
	head.add_child(count)
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 620)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for a in CaseDB.achievements:
		var got := Profile.achievements.has(a["id"])
		var secret: bool = a.get("hidden", false) and not got
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		row.add_child(h)
		var mark := ColorRect.new()
		mark.color = Palette.JADE if got else Palette.SLATE
		mark.custom_minimum_size = Vector2(14, 64)
		h.add_child(mark)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("ACH_SECRET_TITLE" if secret else a["title"], "NameLabel"))
		var desc := UI.label("ACH_SECRET_DESC" if secret else a["desc"], "", true)
		UI.scaled_font(desc, 30)
		v.add_child(desc)
		if not got:
			row.modulate = Color(1, 1, 1, 0.6)
	var close := UI.button("COMMON_CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(root.queue_free)
	box.add_child(close)


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
