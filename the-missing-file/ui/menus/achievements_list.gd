class_name AchievementsList
extends Control
## Pop-up showing the detective's rank and every achievement, earned or not.


func _init() -> void:
	UI.full_rect(self)
	var parts := UI.popup(1400.0)
	add_child(parts[0])
	var box: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UI.label("ACH_TITLE", "HeaderLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var count := UI.label("", "NameLabel")
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = "%d / %d" % [Profile.achievements.size(), CaseDB.achievements.size()]
	head.add_child(count)
	var rank := UI.label("", "SmallLabel")
	rank.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	rank.text = "%s  ·  %d XP" % [tr(Profile.rank()["name"]), Profile.xp()]
	box.add_child(rank)
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(0, 580)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for a in CaseDB.achievements:
		var got := Profile.achievements.has(a["id"])
		var secret: bool = a.get("hidden", false) and not got
		var row := PanelContainer.new()
		row.theme_type_variation = "BarPanel"
		list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		row.add_child(h)
		var mark := ColorRect.new()
		mark.color = Palette.JADE if got else Palette.SLATE
		mark.custom_minimum_size = Vector2(14, 64)
		h.add_child(mark)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("ACH_SECRET_TITLE" if secret else a["title"], "NameLabel"))
		var desc := UI.label("ACH_SECRET_DESC" if secret else a["desc"], "", true)
		UI.scaled_font(desc, 30)
		v.add_child(desc)
		if not got:
			row.modulate = Color(1, 1, 1, 0.6)
	var close := UI.button("COMMON_CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(queue_free)
	box.add_child(close)
