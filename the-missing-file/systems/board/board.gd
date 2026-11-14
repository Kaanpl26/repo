extends Control
## The evidence board. The player chooses two cards and connects them; a valid
## pair asks what the two mean together, and the right answer becomes a
## conclusion card that the rest of the game can build on.

signal closed
signal view_requested(card_id: String)

var _selected: Array = []        # up to two card ids
var _buttons := {}               # card id -> Button
var _body: VBoxContainer
var _slot_labels: Array = []
var _slot_gists: Array = []
var _possible: Label
var _connect: Button
var _view: Button
var _message: Label
var _scroll: TouchScroll


func _ready() -> void:
	add_child(UI.dim(0.8))
	var safe := UI.safe_container(self)
	add_child(safe)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "BoardPanel"
	safe.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UI.label("BOARD_TITLE", "HeaderLabel"))
	titles.add_child(UI.label("BOARD_HELP", "SmallLabel"))
	_possible = UI.label("", "SmallLabel")
	_possible.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	titles.add_child(_possible)
	head.add_child(titles)
	var hint := UI.button("HUD_HINT")
	hint.custom_minimum_size = Vector2(220, UI.MIN_TOUCH)
	hint.pressed.connect(_on_hint)
	head.add_child(hint)
	var close := UI.button("COMMON_CLOSE")
	close.custom_minimum_size = Vector2(260, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	head.add_child(close)

	var scroll := TouchScroll.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)

	# connection tray
	var tray := PanelContainer.new()
	tray.theme_type_variation = "BarPanel"
	col.add_child(tray)
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", 10)
	tray.add_child(tcol)
	var row := HBoxContainer.new()
	tcol.add_child(row)
	for i in 2:
		var slot := PanelContainer.new()
		slot.theme_type_variation = "PaperPanel"
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = 3.0
		var sc := VBoxContainer.new()
		sc.add_theme_constant_override("separation", 2)
		slot.add_child(sc)
		var l := UI.label("BOARD_SLOT_EMPTY", "PaperTitle", true)
		l.add_theme_font_size_override("font_size", 30)
		sc.add_child(l)
		var g := UI.label("", "PaperLabel", true)
		g.add_theme_constant_override("line_spacing", 2)
		UI.scaled_font(g, 26)
		sc.add_child(g)
		_slot_labels.append(l)
		_slot_gists.append(g)
		row.add_child(slot)
		if i == 0:
			var thread := ColorRect.new()
			thread.color = Palette.RED
			thread.custom_minimum_size = Vector2(40, 6)
			thread.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(thread)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	row.add_child(actions)
	_view = UI.button("BOARD_VIEW")
	_view.pressed.connect(func(): view_requested.emit(_selected[-1]))
	_view.custom_minimum_size = Vector2(150, 76)
	var clear := UI.button("BOARD_CLEAR")
	clear.pressed.connect(func():
		_selected.clear()
		_refresh_selection())
	clear.custom_minimum_size = Vector2(150, 76)
	var small := HBoxContainer.new()
	small.add_theme_constant_override("separation", 10)
	small.add_child(_view)
	small.add_child(clear)
	_connect = UI.button("BOARD_CONNECT", "AccentButton")
	_connect.custom_minimum_size = Vector2(310, UI.MIN_TOUCH)
	_connect.pressed.connect(_on_connect)
	actions.add_child(_connect)
	actions.add_child(small)
	_message = UI.label("", "SmallLabel", true)
	tcol.add_child(_message)

	_rebuild()


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	_buttons.clear()
	_section("BOARD_CONCLUSIONS", GameState.insights, "BOARD_NO_CONCLUSIONS")
	_section("CASEFILE_EVIDENCE", GameState.evidence, "CASEFILE_NO_EVIDENCE")
	_section("BOARD_STATEMENTS", GameState.testimony, "CASEFILE_NO_TESTIMONY")
	_refresh_selection()


func _section(title_key: String, cards: Array, empty_key: String) -> void:
	_body.add_child(UI.label(title_key, "NameLabel"))
	if cards.is_empty():
		_body.add_child(UI.label(empty_key, "SmallLabel"))
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_body.add_child(grid)
	for id in cards:
		var b := UI.card_button(id)
		b.pressed.connect(_on_card.bind(id))
		grid.add_child(b)
		_buttons[id] = b
	_body.add_child(UI.spacer(6))


func _on_card(id: String) -> void:
	if id in _selected:
		_selected.erase(id)
	else:
		if _selected.size() == 2:
			_selected.pop_front()
		_selected.append(id)
	_message.text = ""
	_refresh_selection()


func _refresh_selection() -> void:
	for id in _buttons:
		_buttons[id].set_state(id in _selected, Hints.card_used_up(id))
	for i in 2:
		var chosen: bool = i < _selected.size()
		_slot_labels[i].text = CaseDB.card_title(_selected[i]) if chosen else "BOARD_SLOT_EMPTY"
		_slot_gists[i].text = CaseDB.card_gist(_selected[i]) if chosen else ""
		_slot_gists[i].visible = chosen
	_connect.disabled = _selected.size() < 2
	_view.disabled = _selected.is_empty()
	# Tells the player whether the Board has anything left to give right now,
	# without saying which cards.
	var n := Hints.link_count()
	_possible.text = tr("BOARD_POSSIBLE") % n if n > 0 else tr("BOARD_POSSIBLE_NONE")
	_possible.add_theme_color_override("font_color", Palette.AMBER if n > 0 else Palette.MUTED)


func _on_connect() -> void:
	var result := Deduction.try_link(_selected[0], _selected[1])
	match result["status"]:
		Deduction.NONE:
			_say("BOARD_NO_LINK", Palette.RED)
		Deduction.KNOWN:
			_say("BOARD_KNOWN", Palette.MUTED)
		Deduction.FOUND:
			_ask(result["id"])


## Selects two cards that can be connected. The player still has to work out
## what they mean together.
func _on_hint() -> void:
	var id := Hints.next_link()
	if id == "":
		_say("BOARD_HINT_NONE", Palette.MUTED)
		return
	GameState.use_hint()
	_selected = CaseDB.insights[id]["cards"].duplicate()
	_refresh_selection()
	_say("BOARD_HINT_PAIR", Palette.AMBER)
	for card in _selected:
		_scroll.ensure_control_visible.call_deferred(_buttons[card])


func _say(key: String, color: Color) -> void:
	_message.text = key
	_message.add_theme_color_override("font_color", color)


## Asks what the two cards mean together.
func _ask(insight_id: String) -> void:
	var parts := UI.popup(1400.0, 0.8)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	box.add_child(UI.label("BOARD_QUESTION", "HeaderLabel", true))
	for key in Deduction.options(insight_id):
		var b := UI.button(key, "ChoiceButton")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func():
			root.queue_free()
			if Deduction.confirm(insight_id, key):
				Audio.sfx("insight")
				_selected.clear()
				_rebuild()
				_say("BOARD_RIGHT", Palette.JADE)
			else:
				Audio.sfx("wrong")
				_say("BOARD_WRONG", Palette.RED))
		box.add_child(b)
	var cancel := UI.button("COMMON_CANCEL")
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	cancel.pressed.connect(root.queue_free)
	box.add_child(cancel)


func _close() -> void:
	closed.emit()
	queue_free()
