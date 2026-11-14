extends Node
## Changes between screens with a short fade.

const BOOT := "res://ui/menus/boot.tscn"
const LANGUAGE := "res://ui/menus/language_select.tscn"
const MAIN_MENU := "res://ui/menus/main_menu.tscn"
const GAME := "res://systems/investigation/game.tscn"

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	get_tree().root.theme = ThemeBuilder.build()
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)


func goto(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.3)
	await t2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## The detective's office: the place between cases. It is stored like a case
## of its own (cards, conclusions and layout are saved), but it is not in the
## case list and never has a verdict.
const OFFICE_ID := "office"


func open_office() -> void:
	SaveManager.save_game()
	if not SaveManager.load_game(OFFICE_ID):
		GameState.new_game(OFFICE_ID)
	goto(GAME)
