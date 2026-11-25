class_name MentorPortrait
extends Control
## Vatman Nuri: a retired tram driver who walks the player through the basics.
## Flat, hand-shaped portrait: driver's cap with a brass badge, grey moustache.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(s * 0.5, s * 0.5)
	var k := s / 100.0
	draw_circle(c, 50 * k, Palette.CREAM)
	draw_arc(c, 48 * k, 0.0, TAU, 48, Palette.ENAMEL_RED, 4 * k, true)
	# shoulders / uniform
	draw_circle(c + Vector2(0, 62 * k), 38 * k, Color("1d3566"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 26) * k, c + Vector2(6, 26) * k, c + Vector2(0, 40) * k]), Palette.CREAM)
	# face
	var skin := Color("e2b48c")
	draw_circle(c + Vector2(0, 6) * k, 24 * k, skin)
	draw_circle(c + Vector2(-24, 6) * k, 5 * k, skin.darkened(0.08))
	draw_circle(c + Vector2(24, 6) * k, 5 * k, skin.darkened(0.08))
	# eyes (blink every few seconds)
	var blink := fmod(_t, 4.0) > 3.85
	for x in [-9.0, 9.0]:
		if blink:
			draw_line(c + Vector2(x - 3, 2) * k, c + Vector2(x + 3, 2) * k, Color("3a2a20"), 2 * k)
		else:
			draw_circle(c + Vector2(x, 2) * k, 2.6 * k, Color("3a2a20"))
	# eyebrows
	draw_line(c + Vector2(-14, -4) * k, c + Vector2(-5, -6) * k, Color("8a8a8a"), 3 * k, true)
	draw_line(c + Vector2(14, -4) * k, c + Vector2(5, -6) * k, Color("8a8a8a"), 3 * k, true)
	# moustache
	var m := PackedVector2Array()
	for p in [Vector2(-16, 18), Vector2(-10, 12), Vector2(0, 13), Vector2(10, 12), Vector2(16, 18), Vector2(8, 16), Vector2(0, 17), Vector2(-8, 16)]:
		m.append(c + p * k)
	draw_colored_polygon(m, Color("b9b9b4"))
	draw_line(c + Vector2(-4, 22) * k, c + Vector2(4, 22) * k, Color("8b4b3b"), 2 * k, true)
	# driver's cap: crown, band, visor, brass badge
	draw_colored_polygon(PackedVector2Array([c + Vector2(-27, -10) * k, c + Vector2(27, -10) * k, c + Vector2(31, -26) * k, c + Vector2(-31, -26) * k]), Color("1d3566"))
	draw_rect(Rect2(c + Vector2(-27, -12) * k, Vector2(54, 6) * k), Color("0f1d3d"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-24, -7) * k, c + Vector2(24, -7) * k, c + Vector2(18, -1) * k, c + Vector2(-18, -1) * k]), Color("0b1020"))
	draw_circle(c + Vector2(0, -18) * k, 5.5 * k, Logo.BRASS_DARK)
	draw_circle(c + Vector2(0, -18) * k, 4.3 * k, Logo.BRASS)
