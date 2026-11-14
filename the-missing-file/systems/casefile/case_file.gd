extends Control
## The detective's case file: objectives, evidence and statements, suspect
## profiles and the timeline of the night.

signal closed
signal card_selected(id: String)
signal accuse_requested

var _tabs: Array = ["TAB_OBJECTIVES", "TAB_EVIDENCE", "TAB_SUSPECTS", "TAB_TIMELINE"]

var _tab := 0
var _tab_buttons: Array = []
var _body: VBoxContainer


func _ready() -> void:
	add_child(UI.dim(0.75))
	var safe := UI.safe_container(self)
	add_child(safe)
	var panel := PanelContainer.new()
	safe.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	if not CaseDB.records.is_empty():
		_tabs.append("TAB_RECORDS")
	for i in _tabs.size():
		var b := UI.button(_tabs[i], "TabButton")
		b.pressed.connect(_show_tab.bind(i))
		head.add_child(b)
		_tab_buttons.append(b)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	var close := UI.button("COMMON_CLOSE")
	close.custom_minimum_size = Vector2(240, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	head.add_child(close)

	var scroll := TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_show_tab(0)


func _show_tab(index: int) -> void:
	_tab = index
	for i in _tab_buttons.size():
		var active := i == index
		_tab_buttons[i].theme_type_variation = "AccentButton" if active else "TabButton"
	for c in _body.get_children():
		c.queue_free()
	match index:
		0: _build_objectives()
		1: _build_evidence()
		2: _build_suspects()
		3: _build_timeline()
		4: _build_records()


func _wrapped(key: String, size_px: int = 34) -> Label:
	var l := UI.label(key, "", true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.scaled_font(l, size_px)
	return l


# ---------------------------------------------------------------- objectives

func _build_objectives() -> void:
	_body.add_child(UI.label(CaseDB.meta["title"], "HeaderLabel"))
	for o in CaseDB.meta["objectives"]:
		if not GameState.check(o.get("show", [])):
			continue
		var done := GameState.check(o["done"])
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		_body.add_child(row)
		var h := HBoxContainer.new()
		row.add_child(h)
		var mark := ColorRect.new()
		mark.color = Palette.JADE if done else Palette.AMBER
		mark.custom_minimum_size = Vector2(12, 48)
		h.add_child(mark)
		var text := _wrapped(o["text"])
		if done:
			text.modulate = Color(1, 1, 1, 0.55)
		h.add_child(text)
		if done:
			var tag := UI.label("OBJ_DONE", "SmallLabel")
			tag.add_theme_color_override("font_color", Palette.JADE)
			h.add_child(tag)


# ---------------------------------------------------------------- evidence

func _card_grid(cards: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_body.add_child(grid)
	for id in cards:
		var b := UI.card_button(id)
		b.pressed.connect(func(): card_selected.emit(id))
		grid.add_child(b)


func _build_evidence() -> void:
	_body.add_child(UI.label("CASEFILE_EVIDENCE", "NameLabel"))
	if GameState.evidence.is_empty():
		_body.add_child(UI.label("CASEFILE_NO_EVIDENCE", "SmallLabel"))
	_card_grid(GameState.evidence)
	_body.add_child(UI.spacer())
	_body.add_child(UI.label("CASEFILE_TESTIMONY", "NameLabel"))
	if GameState.testimony.is_empty():
		_body.add_child(UI.label("CASEFILE_NO_TESTIMONY", "SmallLabel"))
	_card_grid(GameState.testimony)
	if not GameState.insights.is_empty():
		_body.add_child(UI.spacer())
		_body.add_child(UI.label("BOARD_CONCLUSIONS", "NameLabel"))
		_card_grid(GameState.insights)


# ---------------------------------------------------------------- suspects

func _build_suspects() -> void:
	for id in CaseDB.endings["suspects"]:
		var s: Dictionary = CaseDB.suspects[id]
		var ch: Dictionary = CaseDB.characters[id]
		var card := PanelContainer.new()
		card.theme_type_variation = "BarPanel"
		_body.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 28)
		card.add_child(h)
		var pic := TextureRect.new()
		pic.texture = load(ch["portrait"])
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(150, 190)
		pic.clip_contents = true
		h.add_child(pic)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(ch["name"], "NameLabel"))
		v.add_child(UI.label(s["role"], "SmallLabel"))
		v.add_child(_wrapped(s["bio"], 30))
		var any := false
		for n in s["notes"]:
			if GameState.check(n.get("conditions", [])):
				any = true
				var note := _wrapped(n["text"], 30)
				note.add_theme_color_override("font_color", Palette.AMBER)
				v.add_child(note)
		if not any:
			v.add_child(UI.label("SUSPECT_NO_NOTES", "SmallLabel"))
	_body.add_child(UI.spacer())
	var accuse := UI.button("SUSPECT_ACCUSE", "DangerButton")
	accuse.size_flags_horizontal = Control.SIZE_SHRINK_END
	accuse.custom_minimum_size = Vector2(520, 110)
	accuse.pressed.connect(func():
		accuse_requested.emit()
		queue_free())
	_body.add_child(accuse)


# ---------------------------------------------------------------- timeline

func _build_timeline() -> void:
	_body.add_child(UI.label(CaseDB.meta.get("timeline_title", "TIMELINE_DEFAULT"), "HeaderLabel"))
	var any := false
	for e in CaseDB.timeline:
		if not GameState.check(e.get("conditions", [])):
			continue
		any = true
		var disputed: bool = e.has("disputed") and GameState.check(e["disputed"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		_body.add_child(row)
		var time := UI.label("", "NameLabel")
		time.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		time.text = e["time"]
		time.custom_minimum_size = Vector2(120, 0)
		row.add_child(time)
		var text := _wrapped(e["text"], 32)
		if disputed:
			time.add_theme_color_override("font_color", Palette.RED)
			text.add_theme_color_override("font_color", Palette.RED)
			var tag := UI.label("TIMELINE_DISPUTED", "SmallLabel")
			tag.add_theme_color_override("font_color", Palette.RED)
			row.add_child(tag)
		row.add_child(text)
	if not any:
		_body.add_child(UI.label("TIMELINE_EMPTY", "SmallLabel"))


# ---------------------------------------------------------------- police database

## Things the detective can look up. A record appears once there is a reason
## to ask about it; reading it adds it to the case file as evidence.
func _build_records() -> void:
	_body.add_child(UI.label("RECORDS_TITLE", "HeaderLabel"))
	_body.add_child(UI.label("RECORDS_HELP", "SmallLabel"))
	var available := CaseDB.available_records()
	if available.is_empty():
		_body.add_child(UI.spacer())
		_body.add_child(UI.label("RECORDS_EMPTY", "SmallLabel"))
		return
	for r in available:
		var read: bool = GameState.has_evidence(r["evidence"])
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		_body.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 24)
		row.add_child(h)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("RECORD_TYPE_" + str(r["type"]).to_upper(), "SmallLabel"))
		v.add_child(UI.label(r["query"], "NameLabel", true))
		var b := UI.button("RECORDS_OPEN" if read else "RECORDS_LOOK_UP", "" if read else "AccentButton")
		b.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
		b.pressed.connect(func():
			card_selected.emit(r["evidence"])
			queue_free())
		h.add_child(b)


func _close() -> void:
	closed.emit()
	queue_free()
