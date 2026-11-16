extends Control
## Accusation flow: choose who is responsible, then back it up with proof.

signal resolved(ending_id: String, result: Dictionary)

var _suspect := ""
var _slots := {}
var _content: VBoxContainer
var _note: Label


func _ready() -> void:
	add_child(UI.dim(0.92))
	var safe := UI.safe_container(self)
	add_child(safe)
	var center := CenterContainer.new()
	safe.add_child(center)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 28)
	center.add_child(_content)
	_show_who()


func _clear() -> void:
	for c in _content.get_children():
		c.queue_free()


func _show_who() -> void:
	_clear()
	var title := UI.label(CaseDB.endings.get("question", "ACCUSE_TITLE"), "HeaderLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	_content.add_child(row)
	for id in CaseDB.endings["suspects"]:
		var ch: Dictionary = CaseDB.characters[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(330, 470)
		b.pressed.connect(_choose.bind(id))
		row.add_child(b)
		var v := VBoxContainer.new()
		UI.full_rect(v)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 6)
		b.add_child(v)
		var pic := TextureRect.new()
		pic.texture = load(ch["portrait"])
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.clip_contents = true
		v.add_child(pic)
		var name_label := UI.label(ch["name"], "NameLabel")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(name_label)
		v.add_child(UI.spacer(8))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(bottom)
	var back := UI.button("COMMON_BACK")
	back.custom_minimum_size = Vector2(260, UI.MIN_TOUCH)
	back.pressed.connect(queue_free)
	bottom.add_child(back)
	var accident := UI.button(CaseDB.endings.get("accident_label", "ACCUSE_ACCIDENT"))
	accident.pressed.connect(_choose.bind(Verdict.ACCIDENT))
	bottom.add_child(accident)


func _choose(id: String) -> void:
	_suspect = id
	_slots = {}
	_show_proof()


func _show_proof() -> void:
	_clear()
	var accident := _suspect == Verdict.ACCIDENT
	var title := UI.label("", "HeaderLabel")
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = tr(CaseDB.endings.get("accident_label", "ACCUSE_ACCIDENT")) if accident else tr("ACCUSE_PROOF_TITLE") % tr(CaseDB.characters[_suspect]["name"])
	_content.add_child(title)
	if not accident:
		for slot in CaseDB.endings["slots"]:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 24)
			_content.add_child(row)
			var l := UI.label("ACCUSE_SLOT_" + slot.to_upper())
			l.custom_minimum_size = Vector2(620, 0)
			row.add_child(l)
			var b: Control
			if _slots.get(slot, "") != "":
				b = UI.card_button(_slots[slot], 2)
			else:
				b = UI.button("ACCUSE_CHOOSE")
			b.custom_minimum_size = Vector2(980, 112)
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.pressed.connect(_pick.bind(slot))
			row.add_child(b)
	_note = UI.label("ACCUSE_ONLY_CONCLUSIONS", "SmallLabel", true)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.custom_minimum_size = Vector2(1200, 0)
	_note.add_theme_color_override("font_color", Palette.AMBER)
	_content.add_child(_note)
	var warn := UI.label("ACCUSE_WARNING", "SmallLabel", true)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.custom_minimum_size = Vector2(1200, 0)
	_content.add_child(warn)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(bottom)
	var back := UI.button("COMMON_BACK")
	back.custom_minimum_size = Vector2(260, UI.MIN_TOUCH)
	back.pressed.connect(_show_who)
	bottom.add_child(back)
	var go := UI.button(CaseDB.endings.get("accident_confirm", "ACCUSE_CONFIRM_ACCIDENT") if accident else "ACCUSE_CONFIRM", "DangerButton")
	go.custom_minimum_size = Vector2(360, UI.MIN_TOUCH)
	go.pressed.connect(_confirm)
	bottom.add_child(go)


func _pick(slot: String) -> void:
	# Proof is always a conclusion reached on the Board, so only those are offered.
	if GameState.insights.is_empty():
		_note.text = "ACCUSE_NO_CONCLUSIONS"
		return
	var picker := CardPicker.new("ACCUSE_PICK_TITLE", GameState.insights)
	picker.picked.connect(func(id: String):
		_slots[slot] = id
		_show_proof())
	add_child(picker)


func _confirm() -> void:
	var ending := Verdict.resolve(_suspect, _slots)
	GameState.add_ending(ending)
	var is_solved: bool = CaseDB.endings["endings"][ending]["solved"]
	if is_solved:
		GameState.set_flag("case_solved")
	var carried: Array = []
	for flag in CaseDB.endings.get("carry", []):
		if GameState.has_flag(flag):
			carried.append(flag)
	var result := Profile.record_verdict(GameState.case_id, ending, is_solved, Verdict.rating(), carried)
	DecisionTree.record(ending)
	result["achievements"] = Achievements.evaluate(ending)
	result["weak"] = Verdict.weak_points(_suspect, _slots)
	Audio.sfx("stamp")
	resolved.emit(ending, result)
	queue_free()
