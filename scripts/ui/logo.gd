class_name Logo
extends Control
## Animated logo: the red "M" metro sign of the app icon, with two lines running
## into it and little trains travelling along them.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var s := minf(size.x / 560.0, size.y / 170.0)
	var grow := clampf(_t / 1.0, 0.0, 1.0)
	grow = 1.0 - pow(1.0 - grow, 3.0)
	var h := 70.0 * s
	# lines feeding the sign
	var specs := [[Color("1d72d8"), -1.0, -18.0], [Color("2a9d8f"), 1.0, 18.0], [Color("ffb703"), -1.0, 26.0], [Color("e63946"), 1.0, -26.0]]
	for sp in specs:
		var dir: float = sp[1]
		var y: float = c.y + float(sp[2]) * s
		var x0 := c.x + dir * (h + 6.0 * s)
		var x1 := c.x + dir * lerpf(h + 6.0 * s, 260.0 * s, grow)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.85), 15.0 * s, true)
		draw_line(Vector2(x0, y), Vector2(x1, y), sp[0], 9.0 * s, true)
		if grow >= 1.0:
			var ph := fmod(_t * 0.22 + float(sp[2]) * 0.01, 1.0)
			var x := lerpf(c.x + dir * 250.0 * s, c.x + dir * (h + 14.0 * s), ph)
			draw_circle(Vector2(x, y), 6.0 * s, Color.WHITE)
	# the sign, popping in
	var pop := clampf((_t - 0.15) / 0.5, 0.0, 1.0)
	pop = 1.0 + 0.12 * sin(pop * PI) if pop < 1.0 else 1.0
	var hh := h * minf(1.0, clampf(_t / 0.35, 0.0, 1.0)) * pop
	if hh <= 1.0:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(int(hh * 0.36))
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = int(8 * s)
	sb.shadow_offset = Vector2(0, 5 * s)
	draw_style_box(sb, Rect2(c - Vector2(hh, hh), Vector2(hh, hh) * 2.0))
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = Color("e63946")
	sb2.set_corner_radius_all(int(hh * 0.3))
	draw_style_box(sb2, Rect2(c - Vector2(hh, hh) * 0.9, Vector2(hh, hh) * 1.8))
	var pts := PackedVector2Array()
	for p in [Vector2(-0.5, 0.5), Vector2(-0.5, -0.46), Vector2(0.0, 0.16), Vector2(0.5, -0.46), Vector2(0.5, 0.5)]:
		pts.append(c + p * hh)
	var w := hh * 0.28
	draw_polyline(pts, Color.WHITE, w, true)
	for i in [0, 4]:
		draw_circle(pts[i], w * 0.5, Color.WHITE)
	for i in [1, 2, 3]:
		draw_circle(pts[i], w * 0.62, Color("14233d"))
		draw_circle(pts[i], w * 0.34, Color.WHITE)
