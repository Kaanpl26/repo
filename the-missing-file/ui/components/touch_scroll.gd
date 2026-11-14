class_name TouchScroll
extends ScrollContainer
## A vertical scroll area that can be dragged with a finger anywhere inside it.
##
## Buttons and panels normally swallow touch events, so a list made of buttons
## cannot be dragged. Everything placed inside this container is switched to
## pass touches on, which lets the list scroll; Godot then cancels the button
## press automatically when a drag turns into a scroll.


var _down := false
var _dragging := false
var _press_y := 0.0


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone = 18


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Control and not node is ScrollBar and is_ancestor_of(node):
		if node.mouse_filter == Control.MOUSE_FILTER_STOP:
			node.mouse_filter = Control.MOUSE_FILTER_PASS


## On phones the engine turns a finger drag into scrolling by itself once the
## touch reaches this container. Without a touch screen (desktop testing) the
## same drag is handled here, so the behaviour can be tested with a mouse.
func _gui_input(event: InputEvent) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_down = event.pressed
		if event.pressed:
			_press_y = event.global_position.y
			_dragging = false
	elif event is InputEventMouseMotion and _down:
		if not _dragging and absf(event.global_position.y - _press_y) > scroll_deadzone:
			_dragging = true
			# Tells buttons under the finger that this is a scroll, not a tap.
			propagate_notification(NOTIFICATION_SCROLL_BEGIN)
		if _dragging:
			scroll_vertical -= int(event.relative.y)
