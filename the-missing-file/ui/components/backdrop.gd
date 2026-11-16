class_name Backdrop
extends TextureRect
## Full-screen background picture that always covers the screen.


func _init(path: String, darken: float = 0.0) -> void:
	texture = load(path)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if darken > 0.0:
		modulate = Color(1.0 - darken, 1.0 - darken, 1.0 - darken)
