class_name HowToPlay
extends Control
## Short illustrated guide to the game. Shown once at the start of a new game
## and available from the main menu and the pause menu.

signal closed

const STEPS := ["LOOK", "TALK", "BOARD", "DATABASE", "MAP", "ACCUSE", "OFFICE", "HINT"]


func _init() -> void:
	UI.full_rect(self)
	var parts := UI.popup(1500.0, 0.85)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	box.add_child(UI.label("HOWTO_TITLE", "HeaderLabel"))
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 620)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for i in STEPS.size():
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 26)
		row.add_child(h)
		var number := UI.label("", "HeaderLabel")
		number.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		number.text = str(i + 1)
		number.custom_minimum_size = Vector2(50, 0)
		h.add_child(number)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("HOWTO_%s_TITLE" % STEPS[i], "NameLabel"))
		var text := UI.label("HOWTO_%s_TEXT" % STEPS[i], "", true)
		UI.scaled_font(text, 31)
		v.add_child(text)
	var ok := UI.button("HOWTO_START", "AccentButton")
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.custom_minimum_size = Vector2(380, UI.MIN_TOUCH)
	ok.pressed.connect(func():
		closed.emit()
		queue_free())
	box.add_child(ok)
