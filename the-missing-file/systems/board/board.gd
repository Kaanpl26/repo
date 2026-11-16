extends Control
## The evidence board. The player chooses two cards and connects them; a valid
## pair asks what the two mean together, and the right answer becomes a
## conclusion card that the rest of the game can build on.
##
## Two views share the same selection and rules: the wall (a free canvas with
## notes and red thread, see BoardCanvas) and the list.

signal closed
signal view_requested(card_id: String)

var _selected: Array = []        # up to two card ids
var _buttons := {}               # card id -> Button
var _body: VBoxContainer
var _slot_labels: Array = []
var _slot_gists: Array = []
var _possible: Label
var _help_key := "BOARD_HELP"
var _connect: Button
var _view: Button
var _message: Label
var _scroll: TouchScroll
var _wall: BoardCanvas
var _view_toggle: Button
var _popups := 0                # pop-ups of this board that are open
var _focus := ""                # the question being looked at (an insight id)
var _show_all := false          # the drawer is open
var _fresh: Array = []          # conclusions made while the board is open stay on the wall
var _questions: HBoxContainer
var _progress: HBoxContainer
var _drawer: Button


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
	titles.add_child(UI.label(CaseDB.meta.get("board_title", "BOARD_TITLE"), "HeaderLabel"))
	titles.add_theme_constant_override("separation", 0)
	_progress = HBoxContainer.new()
	_progress.add_theme_constant_override("separation", 18)
	titles.add_child(_progress)
	_possible = UI.label("", "SmallLabel")
	_possible.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	titles.add_child(_possible)
	head.add_child(titles)
	_drawer = UI.button("")
	_drawer.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_drawer.custom_minimum_size = Vector2(180, UI.MIN_TOUCH)
	_drawer.pressed.connect(func():
		_show_all = not _show_all
		_rebuild())
	head.add_child(_drawer)
	_view_toggle = UI.button("")
	_view_toggle.custom_minimum_size = Vector2(160, UI.MIN_TOUCH)
	_view_toggle.pressed.connect(func(): _set_view("list" if Settings.board_view == "wall" else "wall"))
	head.add_child(_view_toggle)
	var hint := UI.button("HUD_HINT")
	hint.custom_minimum_size = Vector2(160, UI.MIN_TOUCH)
	hint.pressed.connect(_on_hint)
	head.add_child(hint)
	var close := UI.button("COMMON_CLOSE")
	close.custom_minimum_size = Vector2(220, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	head.add_child(close)

	var qscroll := ScrollContainer.new()
	qscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	qscroll.custom_minimum_size = Vector2(0, UI.MIN_TOUCH + 8)
	col.add_child(qscroll)
	_questions = HBoxContainer.new()
	_questions.add_theme_constant_override("separation", 12)
	qscroll.add_child(_questions)

	_wall = BoardCanvas.new()
	_wall.note_tapped.connect(_on_card)
	_wall.string_tied.connect(_on_string)
	_wall.accepts_gestures = _is_front
	col.add_child(_wall)

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
	# one row of actions, so the tray stays low and the cards keep the room
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)
	_view = UI.button("BOARD_VIEW")
	_view.pressed.connect(func(): view_requested.emit(_selected[-1]))
	_view.custom_minimum_size = Vector2(150, UI.MIN_TOUCH)
	var clear := UI.button("BOARD_CLEAR")
	clear.pressed.connect(func():
		_selected.clear()
		_say(_help_key, Palette.MUTED)
		_refresh_selection())
	clear.custom_minimum_size = Vector2(150, UI.MIN_TOUCH)
	actions.add_child(_view)
	actions.add_child(clear)
	_connect = UI.button("BOARD_CONNECT", "AccentButton")
	_connect.custom_minimum_size = Vector2(260, UI.MIN_TOUCH)
	_connect.pressed.connect(_on_connect)
	actions.add_child(_connect)
	_message = UI.label("", "SmallLabel", true)
	tcol.add_child(_message)

	_rebuild()
	_set_view(Settings.board_view)


func _set_view(view: String) -> void:
	Settings.set_board_view(view)
	var wall := Settings.board_view == "wall"
	_wall.visible = wall
	_scroll.visible = not wall
	_help_key = "BOARD_HELP_WALL" if wall else "BOARD_HELP"
	if _selected.is_empty():
		_say(_help_key, Palette.MUTED)
	# the button names the view you would switch to
	_view_toggle.text = "BOARD_VIEW_LIST" if wall else "BOARD_VIEW_WALL"


## The wall only follows fingers while the board is the front-most window.
func _is_front() -> bool:
	var p := get_parent()
	return _popups == 0 and p != null and p.get_child(p.get_child_count() - 1) == self


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	_buttons.clear()
	if _focus != "" and GameState.has_insight(_focus):
		_focus = ""
	_section("BOARD_CONCLUSIONS", GameState.insights.filter(_shown), "BOARD_NO_CONCLUSIONS")
	_section("CASEFILE_EVIDENCE", GameState.evidence.filter(_shown), "CASEFILE_NO_EVIDENCE")
	if not CaseDB.meta["testimony"].is_empty():      # the office has no statements
		_section("BOARD_STATEMENTS", GameState.testimony.filter(_shown), "CASEFILE_NO_TESTIMONY")
	_wall.show_all = _show_all
	_wall.extra = _fresh
	_wall.build()
	var hidden := GameState.all_cards().filter(func(c): return not _shown(c)).size()
	_drawer.text = tr("BOARD_DRAWER_CLOSE") if _show_all else tr("BOARD_DRAWER") % hidden
	_drawer.disabled = hidden == 0 and not _show_all
	_build_progress()
	_build_questions()
	_refresh_selection()


## Whether a card is on the Board right now (the rest wait in the drawer).
func _shown(id: String) -> bool:
	return _show_all or id in _fresh or Hints.card_live(id)


func _build_progress() -> void:
	for c in _progress.get_children():
		c.queue_free()
	var parts := Hints.proof_progress()
	if parts.is_empty():
		_progress.visible = false
		return
	_progress.add_child(UI.label("BOARD_PROGRESS", "SmallLabel"))
	for p in parts:
		var l := UI.label("", "SmallLabel")
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.text = ("● " if p["done"] else "○ ") + tr("BOARD_SLOT_" + str(p["slot"]).to_upper())
		l.add_theme_color_override("font_color", Palette.JADE if p["done"] else Palette.MUTED)
		_progress.add_child(l)


func _build_questions() -> void:
	for c in _questions.get_children():
		c.queue_free()
	var open := Hints.open_questions()
	if open.is_empty():
		_questions.add_child(UI.label("BOARD_QUESTIONS_NONE", "SmallLabel"))
		return
	_questions.add_child(UI.label("BOARD_QUESTIONS", "NameLabel"))
	if _focus != "":
		var all := UI.button("BOARD_QUESTION_ALL")
		all.custom_minimum_size = Vector2(140, UI.MIN_TOUCH)
		all.pressed.connect(func(): _set_focus(""))
		_questions.add_child(all)
	for id in open:
		var b := UI.button(CaseDB.insights[id].get("question", "BOARD_QUESTION"), "AccentButton" if id == _focus else "")
		b.custom_minimum_size = Vector2(0, UI.MIN_TOUCH)
		b.pressed.connect(_set_focus.bind("" if id == _focus else id))
		_questions.add_child(b)


## Looks at one question: only its cards stay bright.
func _set_focus(id: String) -> void:
	_focus = id
	_selected.clear()
	_build_questions()
	_refresh_selection()
	if id != "":
		_say("BOARD_QUESTION_FOCUS", Palette.AMBER)
		_wall.show_cards(Hints.focus_cards(id))
	else:
		_say(_help_key, Palette.MUTED)


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
	_say(_help_key if _selected.is_empty() else "", Palette.MUTED)
	_refresh_selection()


func _refresh_selection() -> void:
	var focus: Array = Hints.focus_cards(_focus) if _focus != "" else []
	for id in _buttons:
		_buttons[id].set_state(id in _selected, Hints.card_used_up(id))
		_buttons[id].visible = focus.is_empty() or id in focus
	_wall.set_states(_selected, focus)
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
			Audio.sfx("wrong")
			_say(Deduction.nudge(_selected[0], _selected[1]), Palette.AMBER)
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
	_wall.show_cards(_selected)


func _say(key: String, color: Color) -> void:
	_message.text = key
	_message.add_theme_color_override("font_color", color)


## Asks what the two cards mean together.
func _ask(insight_id: String) -> void:
	var parts := UI.popup(1400.0, 0.8)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	_popups += 1
	root.tree_exited.connect(func(): _popups -= 1)
	box.add_child(UI.label("BOARD_QUESTION", "HeaderLabel", true))
	for key in Deduction.options(insight_id):
		var b := UI.button(key, "ChoiceButton")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func():
			root.queue_free()
			if Deduction.confirm(insight_id, key):
				Audio.sfx("stamp")
				Audio.sfx("insight")
				_selected.clear()
				_fresh.append(insight_id)
				_rebuild()
				_wall.drop_in(insight_id)
				_say("BOARD_RIGHT", Palette.JADE)
				_show_result(insight_id)
			else:
				Audio.sfx("wrong")
				_say("BOARD_WRONG", Palette.RED))
		box.add_child(b)
	var cancel := UI.button("COMMON_CANCEL")
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	cancel.pressed.connect(root.queue_free)
	box.add_child(cancel)


## A string was tied between two notes on the wall.
func _on_string(a: String, b: String) -> void:
	_selected = [a, b]
	_refresh_selection()
	_on_connect()


## The full conclusion, once the player has picked the right short answer.
func _show_result(insight_id: String) -> void:
	var parts := UI.popup(1300.0, 0.6)
	var root: Control = parts[0]
	var box: VBoxContainer = parts[1]
	add_child(root)
	_popups += 1
	root.tree_exited.connect(func(): _popups -= 1)
	var kicker := UI.label("BOARD_RIGHT_TITLE", "SmallLabel")
	kicker.add_theme_color_override("font_color", Palette.JADE)
	box.add_child(kicker)
	box.add_child(UI.label(CaseDB.insights[insight_id]["title"], "HeaderLabel", true))
	var text := UI.label(CaseDB.insights[insight_id]["text"], "", true)
	UI.scaled_font(text, 32)
	box.add_child(text)
	var mira := UI.label("BOARD_MIRA_%d" % (1 + GameState.insights.size() % 4), "SmallLabel", true)
	mira.add_theme_color_override("font_color", Palette.AMBER)
	box.add_child(mira)
	var ok := UI.button("BOARD_CONTINUE", "AccentButton")
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	ok.pressed.connect(root.queue_free)
	box.add_child(ok)


func _close() -> void:
	closed.emit()
	queue_free()
