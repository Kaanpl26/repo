class_name Ripple
extends Node2D
## Short expanding ring shown where the player taps.

var _r := 10.0
var _a := 0.8
var _color := Palette.AMBER


func _init(pos: Vector2, color: Color = Palette.AMBER) -> void:
	position = pos
	_color = color


func _ready() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "_r", 70.0, 0.4).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_a", 0.0, 0.4)
	t.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, _r, 0.0, TAU, 48, Color(_color, _a), 5.0, true)
