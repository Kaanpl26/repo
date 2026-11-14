class_name CardPicker
extends Control
## Pop-up that lets the player choose one of the cards they hold. Cards are
## grouped by kind and show what each one says. An optional quote at the top
## repeats the statement being challenged, so both can be read side by side.

signal picked(card_id: String)

const SECTIONS := [["insight", "BOARD_CONCLUSIONS"], ["evidence", "CASEFILE_EVIDENCE"], ["testimony", "BOARD_STATEMENTS"]]


func _init(title_key: String, cards: Array, quote_speaker: String = "", quote_key: String = "") -> void:
	UI.full_rect(self)
	var parts := UI.popup(1760.0, 0.85)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	box.add_theme_constant_override("separation", 16)
	box.add_child(UI.label(title_key, "HeaderLabel"))
	if quote_key != "":
		var quote := PanelContainer.new()
		quote.theme_type_variation = "PaperPanel"
		box.add_child(quote)
		var qcol := VBoxContainer.new()
		qcol.add_theme_constant_override("separation", 2)
		quote.add_child(qcol)
		qcol.add_child(UI.label(quote_speaker, "PaperTitle"))
		var text := UI.label(quote_key, "PaperLabel", true)
		UI.scaled_font(text, 30)
		qcol.add_child(text)
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 470 if quote_key != "" else 600)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var kinds := {}
	for id in cards:
		kinds[CaseDB.card_kind(id)] = true
	for section in SECTIONS:
		var group: Array = cards.filter(func(id): return CaseDB.card_kind(id) == section[0])
		if group.is_empty():
			continue
		if kinds.size() > 1:
			list.add_child(UI.label(section[1], "SmallLabel"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		list.add_child(grid)
		for id in group:
			var b := UI.card_button(id)
			b.pressed.connect(func():
				picked.emit(id)
				queue_free())
			grid.add_child(b)
	var cancel := UI.button("COMMON_CANCEL")
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	cancel.pressed.connect(queue_free)
	box.add_child(cancel)
