class_name MentorPortrait
extends Control
## Vatman Nuri, the retired tram driver who walks the player through the basics.

var _t := 0.0
var _look := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look = Face.cast_look("nuri")


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := Vector2(r, r)
	Face.draw(self, c, r, _look, fmod(_t, 4.0) > 3.86)
	draw_arc(c, r - 2.0, 0.0, TAU, 48, Palette.ENAMEL_RED, 4.0, true)
