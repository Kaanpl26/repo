extends Control
## Settings overlay. Used from the main menu and from the pause menu.

signal closed

var _lang_buttons := {}
var _size_buttons: Array = []
var _voice_buttons: Array = []   # [on, off]


func _ready() -> void:
	add_child(UI.dim(0.7))
	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	box.custom_minimum_size = Vector2(900, 0)
	panel.add_child(box)

	box.add_child(UI.label("SETTINGS_TITLE", "HeaderLabel"))

	box.add_child(UI.label("SETTINGS_LANGUAGE", "SmallLabel"))
	var langs := HBoxContainer.new()
	box.add_child(langs)
	for code in Settings.LOCALES:
		var b := UI.button("")
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = TranslationServer.get_translation_object(code).get_message("LANG_NAME_" + code.to_upper())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_locale.bind(code))
		langs.add_child(b)
		_lang_buttons[code] = b

	box.add_child(UI.label("SETTINGS_TEXT_SIZE", "SmallLabel"))
	var sizes := HBoxContainer.new()
	box.add_child(sizes)
	var keys := ["SETTINGS_TEXT_SMALL", "SETTINGS_TEXT_NORMAL", "SETTINGS_TEXT_LARGE"]
	for i in keys.size():
		var b := UI.button(keys[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_text_size.bind(i))
		sizes.add_child(b)
		_size_buttons.append(b)

	for spec in [["SETTINGS_MUSIC", Settings.music_volume, true], ["SETTINGS_SFX", Settings.sfx_volume, false]]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var name_label := UI.label(spec[0], "SmallLabel")
		name_label.custom_minimum_size = Vector2(260, 0)
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = spec[1]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size = Vector2(0, 72)
		var is_music: bool = spec[2]
		slider.value_changed.connect(func(v: float):
			if is_music:
				Settings.set_volumes(v, Settings.sfx_volume)
			else:
				Settings.set_volumes(Settings.music_volume, v)
				Audio.sfx("click"))
		row.add_child(slider)

	var speech := HBoxContainer.new()
	box.add_child(speech)
	var speech_label := UI.label("SETTINGS_VOICES", "SmallLabel")
	speech_label.custom_minimum_size = Vector2(260, 0)
	speech.add_child(speech_label)
	for on in [true, false]:
		var b := UI.button("SETTINGS_ON" if on else "SETTINGS_OFF")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 80)
		b.pressed.connect(func():
			Settings.set_voices(on)
			if on:
				Audio.voice(1.0)
			_refresh())
		speech.add_child(b)
		_voice_buttons.append(b)

	var close := UI.button("COMMON_CLOSE", "AccentButton")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size = Vector2(300, UI.MIN_TOUCH)
	close.pressed.connect(_close)
	box.add_child(close)
	_refresh()


func _set_locale(code: String) -> void:
	Settings.set_locale(code)
	_refresh()


func _set_text_size(i: int) -> void:
	Settings.set_text_size(i)
	_refresh()


func _refresh() -> void:
	for code in _lang_buttons:
		_lang_buttons[code].theme_type_variation = "AccentButton" if code == Settings.locale else ""
	for i in _voice_buttons.size():
		_voice_buttons[i].theme_type_variation = "AccentButton" if (i == 0) == Settings.voices else ""
	for i in _size_buttons.size():
		_size_buttons[i].theme_type_variation = "AccentButton" if i == Settings.text_size else ""


func _close() -> void:
	closed.emit()
	queue_free()
