class_name Ripple
extends Node2D
## Short expanding ring shown where the player taps.

var _r := 10.0
var _a := 0.8
var _color := Palette.AMBER
var _max_r := 70.0
var _dur := 0.4


func _init(pos: Vector2, color: Color = Palette.AMBER, max_radius: float = 70.0, duration: float = 0.4) -> void:
	position = pos
	_color = color
	_max_r = max_radius
	_dur = duration


func _ready() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "_r", _max_r, _dur).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_a", 0.0, _dur)
	t.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, _r, 0.0, TAU, 48, Color(_color, _a), 5.0, true)
