extends Control
## First screen: decides whether to show the language choice or the main menu.


func _ready() -> void:
	if Settings.locale == "":
		get_tree().change_scene_to_file.call_deferred(SceneRouter.LANGUAGE)
	else:
		get_tree().change_scene_to_file.call_deferred(SceneRouter.MAIN_MENU)
