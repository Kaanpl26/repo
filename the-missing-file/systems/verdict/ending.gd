extends Control
## Verdict screen: what happened after the accusation, and how the
## investigation is rated.

signal return_requested
signal menu_requested

var ending_id := ""      # set before adding to the tree


func _ready() -> void:
	var def: Dictionary = CaseDB.endings["endings"][ending_id]
	add_child(UI.dim(1.0))
	var safe := UI.safe_container(self)
	add_child(safe)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(0, get_viewport_rect().size.y - 80)
	scroll.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(1400, 0)
	box.add_theme_constant_override("separation", 26)
	center.add_child(box)

	var kicker := UI.label("ENDING_CASE_CLOSED", "SmallLabel")
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := UI.label(def["title"], "TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Palette.JADE if def["solved"] else Palette.RED)
	box.add_child(title)
	var text := UI.label(def["text"], "", true)
	UI.scaled_font(text, 36)
	box.add_child(text)

	for key in Verdict.epilogue(ending_id):
		var extra := UI.label(key, "", true)
		UI.scaled_font(extra, 34)
		extra.add_theme_color_override("font_color", Palette.PAPER_DARK)
		box.add_child(extra)

	var r := Verdict.rating()
	var panel := PanelContainer.new()
	panel.theme_type_variation = "BarPanel"
	box.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel.add_child(row)
	row.add_child(UI.label("ENDING_RATING", "NameLabel"))
	var grade := UI.label("", "HeaderLabel")
	grade.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	grade.text = r["grade"] if def["solved"] else "—"
	row.add_child(grade)
	var stats := UI.label("", "SmallLabel")
	stats.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	stats.text = tr("ENDING_STATS") % [r["evidence"], r["evidence_total"], r["insights"], r["insights_total"], r["mistakes"], r["hints"]]
	row.add_child(stats)

	if not def["solved"]:
		var note := UI.label("ENDING_RETURN_NOTE", "SmallLabel", true)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	var menu := UI.button("PAUSE_MAIN_MENU")
	menu.pressed.connect(func(): menu_requested.emit())
	buttons.add_child(menu)
	if not def["solved"]:
		var back := UI.button("ENDING_RETURN", "AccentButton")
		back.pressed.connect(func():
			return_requested.emit()
			queue_free())
		buttons.add_child(back)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
