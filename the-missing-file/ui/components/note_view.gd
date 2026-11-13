class_name NoteView
extends Control
## Pop-up showing a statement or a conclusion in full.


func _init(card_id: String) -> void:
	UI.full_rect(self)
	var parts := UI.popup(1100.0)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	box.add_child(UI.label(CaseDB.card_title(card_id), "HeaderLabel", true))
	var text := UI.label(CaseDB.card_text(card_id), "", true)
	UI.scaled_font(text, 36)
	box.add_child(text)
	if CaseDB.card_kind(card_id) == "insight":
		var row := HBoxContainer.new()
		row.add_child(UI.label("BOARD_FROM", "SmallLabel"))
		for src in CaseDB.insights[card_id]["cards"]:
			var l := UI.label(CaseDB.card_title(src), "SmallLabel")
			l.add_theme_color_override("font_color", Palette.JADE)
			row.add_child(l)
		box.add_child(row)
	var close := UI.button("COMMON_CLOSE", "AccentButton")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(queue_free)
	box.add_child(close)
