class_name CaseList
extends Control
## Pop-up list of all cases: status, best grade, and Start / Continue / Start Over.
## Used from the main menu and from the case folders in the office.


func _init() -> void:
	UI.full_rect(self)
	var parts := UI.popup(1400.0)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	box.add_child(UI.label("CASES_TITLE", "HeaderLabel"))
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 600)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in CaseDB.index:
		list.add_child(_case_row(entry))
	var close := UI.button("COMMON_CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(queue_free)
	box.add_child(close)


func _case_row(entry: Dictionary) -> Control:
	var id: String = entry["id"]
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
	if not CaseDB.case_open(id):
		status.text = tr("CASES_LOCKED")
		row.modulate = Color(1, 1, 1, 0.5)
		return row
	var has_save := SaveManager.has_save(id)
	if Profile.is_solved(id):
		status.text = tr("CASES_SOLVED") % Profile.best[id]["grade"]
		status.add_theme_color_override("font_color", Palette.JADE)
	elif Profile.is_closed(id):
		status.text = tr("CASES_CLOSED_WRONG")
		status.add_theme_color_override("font_color", Palette.AMBER)
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


func _start(case_id: String) -> void:
	SaveManager.save_game()            # keep whatever is open now (the office)
	SaveManager.delete_save(case_id)
	GameState.new_game(case_id)
	SceneRouter.goto(SceneRouter.GAME)


func _resume(case_id: String) -> void:
	SaveManager.save_game()
	if SaveManager.load_game(case_id):
		SceneRouter.goto(SceneRouter.GAME)


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
