extends Control
## Conversation screen: portrait, speaker name, text with typewriter effect,
## reply choices and the "Present evidence" action.

signal closed

var character := ""          # set before adding to the tree

var _runner: DialogueRunner
var _portrait: TextureRect
var _name: Label
var _text: Label
var _hint: Label
var _choices: VBoxContainer
var _present: Button
var _press: Button
var _pips: HBoxContainer
var _portraits := {}
var _tween: Tween
var _state := ""


func _ready() -> void:
	add_child(UI.dim(0.55))

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)

	var tap := Control.new()
	UI.full_rect(tap)
	tap.gui_input.connect(_on_tap_input)
	add_child(tap)

	var safe := UI.safe_container(self)
	add_child(safe)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_END
	safe.add_child(col)

	_choices = VBoxContainer.new()
	_choices.size_flags_horizontal = Control.SIZE_SHRINK_END
	_choices.custom_minimum_size = Vector2(980, 0)
	_choices.add_theme_constant_override("separation", 14)
	col.add_child(_choices)

	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(actions)
	_press = UI.button("DLG_PRESS")
	_press.pressed.connect(func(): _show_state(_runner.press()))
	actions.add_child(_press)
	_present = UI.button("DLG_PRESENT", "AccentButton")
	_present.pressed.connect(_open_picker)
	actions.add_child(_present)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0, 280)
	col.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	_name = UI.label("", "NameLabel")
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_name)
	_pips = HBoxContainer.new()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.add_theme_constant_override("separation", 8)
	head.add_child(_pips)
	_text = UI.label("", "", true)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.scaled_font(_text, 36)
	box.add_child(_text)
	_hint = UI.label("DLG_TAP_TO_CONTINUE", "SmallLabel")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_hint)

	var ch: Dictionary = CaseDB.characters[character]
	var base: String = ch["portrait"]
	_portraits["neutral"] = load(base)
	for mood in ["defensive", "shaken"]:
		var path := base.replace(".png", "_%s.png" % mood)
		_portraits[mood] = load(path) if ResourceLoader.exists(path) else _portraits["neutral"]
	_portrait.texture = _portraits["neutral"]
	_layout_portrait()
	resized.connect(_layout_portrait)

	_runner = DialogueRunner.new(character)
	_show_state(_runner.start())


func _layout_portrait() -> void:
	var h := size.y * 0.92
	var w := h * 0.7
	_portrait.size = Vector2(w, h)
	_portrait.position = Vector2(UI.safe_margins(self)[0] + 20, size.y - h)


func _show_state(state: String) -> void:
	_state = state
	for c in _choices.get_children():
		c.queue_free()
	_present.visible = false
	_press.visible = false
	_refresh_patience()
	match state:
		DialogueRunner.LINE:
			_show_line()
		DialogueRunner.CHOICES:
			_hint.visible = false
			for choice in _runner.choices():
				var b := UI.button(choice["t"], "ChoiceButton")
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				if _runner.is_seen(choice):
					b.modulate = Color(1, 1, 1, 0.6)
				b.pressed.connect(_on_choice.bind(choice))
				_choices.add_child(b)
		DialogueRunner.END:
			closed.emit()
			queue_free()


func _show_line() -> void:
	var l := _runner.line()
	var speaker: String = l["s"]
	_name.text = CaseDB.characters[speaker]["name"]
	_portrait.modulate = Color.WHITE if speaker == character else Color(0.45, 0.45, 0.5)
	if speaker == character:
		_portrait.texture = _portraits[l.get("mood", "neutral")]
	_press.visible = _runner.can_press()
	_text.text = l["t"]
	_hint.visible = true
	_present.visible = _runner.can_present() and not GameState.all_cards().is_empty()
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.2, tr(l["t"]).length() / 70.0))


## Small pips beside the name: how many careless challenges this person will
## still put up with.
func _refresh_patience() -> void:
	for c in _pips.get_children():
		c.queue_free()
	if not _runner or not _runner.has_patience():
		return
	var label := UI.label("DLG_PATIENCE", "SmallLabel")
	_pips.add_child(label)
	var full := int(CaseDB.characters[character].get("patience", 3))
	var left := GameState.patience_left(character)
	for i in full:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(22, 22)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.color = Palette.AMBER if i < left else Palette.SLATE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips.add_child(pip)


func _on_tap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _state != DialogueRunner.LINE:
			return
		if _text.visible_ratio < 1.0:
			_tween.kill()
			_text.visible_ratio = 1.0
		else:
			_show_state(_runner.advance())


func _on_choice(choice: Dictionary) -> void:
	_show_state(_runner.choose(choice))


func _open_picker() -> void:
	var picker := CardPicker.new("DLG_PRESENT_TITLE", GameState.all_cards())
	picker.picked.connect(_on_present)
	add_child(picker)


func _on_present(evidence_id: String) -> void:
	Audio.sfx("found" if _runner.present(evidence_id) else "wrong")
	_show_state(DialogueRunner.LINE)
