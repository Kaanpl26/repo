class_name UI
## Small helpers for building touch-friendly UI in code.
## All text arguments are localization KEYS, never literal player-facing text.

const MIN_TOUCH := 96


static func button(key: String, variation: String = "") -> Button:
	var b := Button.new()
	b.text = key
	b.custom_minimum_size = Vector2(0, MIN_TOUCH)
	if variation != "":
		b.theme_type_variation = variation
	return b


static func label(key: String, variation: String = "", wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = key
	if variation != "":
		l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func dim(alpha: float = 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	full_rect(r)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## Margins (left, top, right, bottom) in viewport units that keep UI clear of
## notches, punch-hole cameras and rounded corners on phones.
static func safe_margins(node: Node) -> Array:
	var base := 28.0
	var m := [base, base, base, base]
	if not OS.has_feature("mobile"):
		return m
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var vp := node.get_viewport().get_visible_rect().size
	if win.x <= 0 or win.y <= 0:
		return m
	var s := vp.x / win.x
	m[0] = base + maxf(0.0, safe.position.x) * s
	m[1] = base + maxf(0.0, safe.position.y) * s
	m[2] = base + maxf(0.0, win.x - safe.end.x) * s
	m[3] = base + maxf(0.0, win.y - safe.end.y) * s
	return m


## A full-screen MarginContainer that respects the safe area.
static func safe_container(node: Node) -> MarginContainer:
	var mc := MarginContainer.new()
	full_rect(mc)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := safe_margins(node)
	mc.add_theme_constant_override("margin_left", int(m[0]))
	mc.add_theme_constant_override("margin_top", int(m[1]))
	mc.add_theme_constant_override("margin_right", int(m[2]))
	mc.add_theme_constant_override("margin_bottom", int(m[3]))
	return mc


static func scaled_font(control: Control, base_size: int) -> void:
	control.add_theme_font_size_override("font_size", int(round(base_size * Settings.text_scale_factor())))


## A button showing a card (evidence, statement or conclusion) with its icon.
static func card_button(card_id: String) -> Button:
	var b := button(CaseDB.card_title(card_id))
	b.icon = load(CaseDB.card_icon(card_id))
	b.add_theme_constant_override("icon_max_width", 72)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, 112)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if CaseDB.card_kind(card_id) == "insight":
		b.theme_type_variation = "InsightButton"
	return b


## Centered pop-up panel on a dimmed background. Returns [root, content VBox].
static func popup(min_width: float = 900.0, alpha: float = 0.75) -> Array:
	var root := dim(alpha)
	var center := CenterContainer.new()
	full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(min_width, 0)
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)
	return [root, box]


static func spacer(h: float = 16.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
