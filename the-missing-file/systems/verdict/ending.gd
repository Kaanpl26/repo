extends Control
## Verdict screen: what happened after the accusation, and how the
## investigation is rated.

signal return_requested
signal menu_requested

var ending_id := ""      # set before adding to the tree
var result: Dictionary = {}   # from Profile.record_verdict, plus "achievements"


func _ready() -> void:
	var def: Dictionary = CaseDB.endings["endings"][ending_id]
	add_child(UI.dim(1.0))
	var safe := UI.safe_container(self)
	add_child(safe)
	var scroll := TouchScroll.new()
	safe.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fit := func(): center.custom_minimum_size = Vector2(0, scroll.size.y)
	scroll.resized.connect(fit)
	fit.call_deferred()
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

	if def["solved"]:
		box.add_child(_career_panel())
	for id in result.get("achievements", []):
		var a := Achievements.find(id)
		var got := PanelContainer.new()
		got.theme_type_variation = "BarPanel"
		box.add_child(got)
		var line := HBoxContainer.new()
		got.add_child(line)
		var tag := UI.label("ACH_UNLOCKED", "SmallLabel")
		tag.add_theme_color_override("font_color", Palette.JADE)
		line.add_child(tag)
		line.add_child(UI.label(a["title"], "NameLabel"))

	var weak: Array = result.get("weak", [])
	if not weak.is_empty():
		var wp := PanelContainer.new()
		wp.theme_type_variation = "BarPanel"
		box.add_child(wp)
		var wc := VBoxContainer.new()
		wc.add_theme_constant_override("separation", 4)
		wp.add_child(wc)
		var head := UI.label("ENDING_WEAK", "NameLabel")
		wc.add_child(head)
		for key in weak:
			var line := UI.label(key, "", true)
			UI.scaled_font(line, 31)
			wc.add_child(line)

	if not def["solved"]:
		var note := UI.label("ENDING_RETURN_NOTE", "SmallLabel", true)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	var menu := UI.button("ENDING_TO_OFFICE")
	menu.pressed.connect(func(): menu_requested.emit())
	buttons.add_child(menu)
	var tree := UI.button("TREE_BUTTON")
	tree.pressed.connect(func(): add_child(DecisionTreeView.new(GameState.case_id)))
	buttons.add_child(tree)
	if not def["solved"]:
		var back := UI.button("ENDING_RETURN", "AccentButton")
		back.pressed.connect(func():
			return_requested.emit()
			queue_free())
		buttons.add_child(back)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


## Experience gained, current rank and progress to the next one.
func _career_panel() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "BarPanel"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	row.add_child(UI.label(Profile.rank()["name"], "NameLabel"))
	var xp := UI.label("", "SmallLabel")
	xp.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	xp.text = tr("CAREER_XP_GAIN") % [int(result.get("xp_gain", 0)), Profile.xp()]
	row.add_child(xp)
	if result.get("rank_up", false):
		var up := UI.label("CAREER_RANK_UP", "SmallLabel")
		up.add_theme_color_override("font_color", Palette.JADE)
		row.add_child(up)
	var next := Profile.next_rank()
	if not next.is_empty():
		var bar := ProgressBar.new()
		bar.min_value = float(Profile.rank()["xp"])
		bar.max_value = float(next["xp"])
		bar.value = float(Profile.xp())
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 18)
		col.add_child(bar)
		var to_next := UI.label("", "SmallLabel")
		to_next.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		to_next.text = tr("CAREER_NEXT") % [tr(next["name"]), int(next["xp"]) - Profile.xp()]
		col.add_child(to_next)
	return panel
