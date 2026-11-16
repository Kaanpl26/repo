extends Control
## Shows one piece of evidence: picture, name, short description and the full
## examination text on a sheet of paper.

signal closed

var evidence_id := ""      # set before adding to the tree
var collect := false       # true when the player is finding it for the first time


func _ready() -> void:
	var def: Dictionary = CaseDB.evidence[evidence_id]
	add_child(UI.dim(0.72))
	var safe := UI.safe_container(self)
	add_child(safe)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	panel.add_child(col)

	if collect:
		var found := UI.label("EVIDENCE_NEW", "SmallLabel")
		found.add_theme_color_override("font_color", Palette.JADE)
		col.add_child(found)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(520, 0)
	row.add_child(left)
	var icon := TextureRect.new()
	icon.texture = load(def["icon"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(300, 300)
	left.add_child(icon)
	var name_label := UI.label(def["name"], "HeaderLabel", true)
	left.add_child(name_label)
	var desc := UI.label(def["desc"], "", true)
	UI.scaled_font(desc, 32)
	left.add_child(desc)

	var paper := PanelContainer.new()
	paper.theme_type_variation = "PaperPanel"
	paper.custom_minimum_size = Vector2(860, 560)
	row.add_child(paper)
	var scroll := TouchScroll.new()
	paper.add_child(scroll)
	var body := UI.label(def["body"], "PaperLabel", true)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.scaled_font(body, 30)
	scroll.add_child(body)

	var close := UI.button("EVIDENCE_ADD" if collect else "COMMON_CLOSE", "AccentButton")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(420, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	col.add_child(close)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _close() -> void:
	if collect:
		GameState.add_evidence(evidence_id)
	closed.emit()
	queue_free()
