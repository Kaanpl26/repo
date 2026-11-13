extends Control
## The detective's case file. In this milestone it lists collected evidence and
## recorded testimony; objectives, suspects, timeline and the board come next.

signal closed
signal evidence_selected(id: String)


func _ready() -> void:
	add_child(UI.dim(0.75))
	var safe := UI.safe_container(self)
	add_child(safe)
	var panel := PanelContainer.new()
	safe.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := UI.label("CASEFILE_TITLE", "HeaderLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UI.button("COMMON_CLOSE")
	close.custom_minimum_size = Vector2(260, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	head.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	body.add_child(UI.label("CASEFILE_EVIDENCE", "NameLabel"))
	if GameState.evidence.is_empty():
		body.add_child(UI.label("CASEFILE_NO_EVIDENCE", "SmallLabel"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	body.add_child(grid)
	for id in GameState.evidence:
		var def: Dictionary = CaseDB.evidence[id]
		var b := UI.button(def["name"])
		b.icon = load(def["icon"])
		b.add_theme_constant_override("icon_max_width", 80)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 116)
		b.clip_text = true
		b.pressed.connect(func(): evidence_selected.emit(id))
		grid.add_child(b)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	body.add_child(gap)
	body.add_child(UI.label("CASEFILE_TESTIMONY", "NameLabel"))
	if GameState.testimony.is_empty():
		body.add_child(UI.label("CASEFILE_NO_TESTIMONY", "SmallLabel"))
	for id in GameState.testimony:
		var def: Dictionary = CaseDB.meta["testimony"][id]
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		body.add_child(row)
		var rc := VBoxContainer.new()
		rc.add_theme_constant_override("separation", 4)
		row.add_child(rc)
		rc.add_child(UI.label(CaseDB.characters[def["speaker"]]["name"], "SmallLabel"))
		var t := UI.label(def["text"], "", true)
		UI.scaled_font(t, 32)
		rc.add_child(t)


func _close() -> void:
	closed.emit()
	queue_free()
