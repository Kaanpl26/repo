class_name DecisionTreeView
extends Control
## Pop-up: the decisions of one case from top to bottom. The route of the last
## verdict is highlighted, routes found earlier are shown plainly, and routes
## never taken stay hidden.

var case_id := ""


func _init(id: String = "") -> void:
	case_id = id


func _ready() -> void:
	UI.full_rect(self)
	var parts := UI.popup(1560.0)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	var seen: Array = Profile.tree.get(case_id, [])
	var last: Array = Profile.tree_last.get(case_id, [])
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UI.label("TREE_TITLE", "HeaderLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var count := UI.label("", "NameLabel")
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = tr("TREE_FOUND") % [seen.size(), DecisionTree.total(case_id)]
	head.add_child(count)
	box.add_child(UI.label("TREE_HELP", "SmallLabel", true))
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 600)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	var all := DecisionTree.nodes(case_id)
	for i in all.size():
		list.add_child(_point(all[i], seen, last))
		if i < all.size() - 1:
			var stem := ColorRect.new()
			stem.color = Palette.AMBER
			stem.custom_minimum_size = Vector2(6, 34)
			stem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			list.add_child(stem)
	var close := UI.button("COMMON_CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(queue_free)
	box.add_child(close)


func _point(node: Dictionary, seen: Array, last: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var title := UI.label(node["title"], "NameLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	for o in node["options"]:
		var id := "%s.%s" % [node["id"], o["id"]]
		var known := id in seen
		var current := id in last
		var card := PanelContainer.new()
		card.theme_type_variation = "BarPanel"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 96)
		var text := UI.label(o["text"] if known else "TREE_HIDDEN", "", true)
		UI.scaled_font(text, 28)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(text)
		if current:
			text.add_theme_color_override("font_color", Palette.AMBER)
		elif known:
			card.modulate = Color(1, 1, 1, 0.75)
		else:
			card.modulate = Color(1, 1, 1, 0.35)
		row.add_child(card)
	return col
