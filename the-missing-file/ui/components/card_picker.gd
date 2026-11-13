class_name CardPicker
extends Control
## Pop-up that lets the player choose one of the cards they hold.

signal picked(card_id: String)


func _init(title_key: String, cards: Array) -> void:
	UI.full_rect(self)
	var parts := UI.popup(1500.0, 0.8)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	box.add_child(UI.label(title_key, "HeaderLabel"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 560)
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	for id in cards:
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
