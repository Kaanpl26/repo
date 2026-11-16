extends Control
## Shown on first launch only. Both languages are written in their own language,
## so this screen is readable whatever the device language is.


func _ready() -> void:
	add_child(Backdrop.new("res://assets/ui/menu_bg.png", 0.45))
	var center := CenterContainer.new()
	UI.full_rect(center)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 36)
	center.add_child(box)

	var title := UI.label("", "HeaderLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.text = "Language  ·  Dil"
	box.add_child(title)

	for code in Settings.LOCALES:
		var b := UI.button("LANG_NAME_" + code.to_upper())
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = TranslationServer.get_translation_object(code).get_message("LANG_NAME_" + code.to_upper())
		b.custom_minimum_size = Vector2(620, 130)
		b.pressed.connect(_choose.bind(code))
		box.add_child(b)


func _choose(code: String) -> void:
	Settings.set_locale(code)
	SceneRouter.goto(SceneRouter.MAIN_MENU)
