class_name Icon
extends Control
## Resolution independent vector icons drawn with canvas primitives.

@export var kind := "play"
@export var color := Palette.TEXT
var line_w := 3.0


static func make(k: String, size: float = 36.0, c: Color = Palette.TEXT) -> Icon:
	var i := Icon.new()
	i.kind = k
	i.color = c
	i.custom_minimum_size = Vector2(size, size)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


func set_color(c: Color) -> void:
	color = c
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var lw := maxf(2.0, s * 0.085)
	var c := color
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	match kind:
		"play":
			draw_colored_polygon(PackedVector2Array([p.call(0.3, 0.2), p.call(0.8, 0.5), p.call(0.3, 0.8)]), c)
		"pause":
			draw_rect(Rect2(p.call(0.27, 0.2), Vector2(0.15, 0.6) * s), c)
			draw_rect(Rect2(p.call(0.58, 0.2), Vector2(0.15, 0.6) * s), c)
		"ff":
			draw_colored_polygon(PackedVector2Array([p.call(0.12, 0.22), p.call(0.5, 0.5), p.call(0.12, 0.78)]), c)
			draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.22), p.call(0.88, 0.5), p.call(0.5, 0.78)]), c)
		"fff":
			for k in 3:
				var x0 := 0.06 + k * 0.29
				draw_colored_polygon(PackedVector2Array([p.call(x0, 0.25), p.call(x0 + 0.3, 0.5), p.call(x0, 0.75)]), c)
		"menu":
			for k in 3:
				var y := 0.28 + k * 0.22
				draw_line(p.call(0.2, y), p.call(0.8, y), c, lw, true)
		"close":
			draw_line(p.call(0.25, 0.25), p.call(0.75, 0.75), c, lw, true)
			draw_line(p.call(0.75, 0.25), p.call(0.25, 0.75), c, lw, true)
		"plus":
			draw_line(p.call(0.2, 0.5), p.call(0.8, 0.5), c, lw * 1.2, true)
			draw_line(p.call(0.5, 0.2), p.call(0.5, 0.8), c, lw * 1.2, true)
		"minus":
			draw_line(p.call(0.2, 0.5), p.call(0.8, 0.5), c, lw * 1.2, true)
		"check":
			draw_polyline(PackedVector2Array([p.call(0.2, 0.52), p.call(0.42, 0.74), p.call(0.82, 0.3)]), c, lw * 1.2, true)
		"undo":
			var pts := PackedVector2Array()
			for k in 13:
				var a := lerpf(PI * 1.05, PI * 2.25, k / 12.0)
				pts.append(o + (Vector2(0.52, 0.55) + Vector2(cos(a), sin(a)) * 0.27) * s)
			draw_polyline(pts, c, lw, true)
			var tip := pts[0]
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.14, -0.02) * s, tip + Vector2(0.1, -0.04) * s, tip + Vector2(-0.03, 0.16) * s]), c)
		"build":
			# rail track with a plus
			draw_line(p.call(0.18, 0.82), p.call(0.5, 0.18), c, lw, true)
			draw_line(p.call(0.5, 0.18), p.call(0.82, 0.82), c, lw, true)
			for k in 3:
				var t := 0.3 + k * 0.2
				var y := lerpf(0.82, 0.18, t)
				var dx := lerpf(0.32, 0.0, t)
				draw_line(o + Vector2(0.5 - dx - 0.06, y) * s, o + Vector2(0.5 + dx + 0.06, y) * s, c, lw * 0.8, true)
		"lines":
			draw_line(p.call(0.15, 0.3), p.call(0.85, 0.3), c, lw, true)
			draw_line(p.call(0.15, 0.7), p.call(0.4, 0.7), c, lw, true)
			draw_line(p.call(0.4, 0.7), p.call(0.6, 0.45), c, lw, true)
			draw_line(p.call(0.6, 0.45), p.call(0.85, 0.45), c, lw, true)
			draw_circle(p.call(0.5, 0.3), s * 0.08, c)
			draw_circle(p.call(0.15, 0.7), s * 0.08, c)
			draw_circle(p.call(0.85, 0.45), s * 0.08, c)
		"layers":
			for k in 2:
				var dy := k * 0.2
				var poly := PackedVector2Array([p.call(0.5, 0.2 + dy), p.call(0.85, 0.38 + dy), p.call(0.5, 0.56 + dy), p.call(0.15, 0.38 + dy), p.call(0.5, 0.2 + dy)])
				if k == 0:
					draw_colored_polygon(poly, Color(c, 0.35))
				draw_polyline(poly, c, lw * 0.8, true)
		"target":
			draw_arc(p.call(0.5, 0.5), s * 0.34, 0, TAU, 32, c, lw * 0.8, true)
			draw_arc(p.call(0.5, 0.5), s * 0.19, 0, TAU, 24, c, lw * 0.8, true)
			draw_circle(p.call(0.5, 0.5), s * 0.06, c)
		"chart":
			draw_rect(Rect2(p.call(0.18, 0.55), Vector2(0.14, 0.27) * s), c)
			draw_rect(Rect2(p.call(0.43, 0.35), Vector2(0.14, 0.47) * s), c)
			draw_rect(Rect2(p.call(0.68, 0.18), Vector2(0.14, 0.64) * s), c)
		"gear":
			var cc: Vector2 = p.call(0.5, 0.5)
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(cc + Vector2(cos(a), sin(a)) * s * 0.22, cc + Vector2(cos(a), sin(a)) * s * 0.4, c, lw * 1.4, true)
			draw_circle(cc, s * 0.27, c)
			draw_circle(cc, s * 0.11, Palette.PANEL_2)
		"trash":
			draw_line(p.call(0.2, 0.28), p.call(0.8, 0.28), c, lw, true)
			draw_line(p.call(0.4, 0.18), p.call(0.6, 0.18), c, lw, true)
			draw_polyline(PackedVector2Array([p.call(0.28, 0.32), p.call(0.33, 0.82), p.call(0.67, 0.82), p.call(0.72, 0.32)]), c, lw, true)
		"profile":
			var pts := PackedVector2Array([p.call(0.1, 0.55), p.call(0.3, 0.35), p.call(0.45, 0.45), p.call(0.65, 0.25), p.call(0.9, 0.42)])
			draw_polyline(pts, c, lw, true)
			draw_dashed_line(p.call(0.1, 0.75), p.call(0.9, 0.75), c, lw * 0.8, s * 0.08)
		"extend":
			draw_line(p.call(0.15, 0.5), p.call(0.6, 0.5), c, lw, true)
			draw_circle(p.call(0.15, 0.5), s * 0.09, c)
			draw_colored_polygon(PackedVector2Array([p.call(0.58, 0.32), p.call(0.88, 0.5), p.call(0.58, 0.68)]), c)
		"star":
			draw_colored_polygon(_star(o + Vector2(0.5, 0.52) * s, s * 0.46, s * 0.2), c)
		"star_o":
			var st := _star(o + Vector2(0.5, 0.52) * s, s * 0.46, s * 0.2)
			st.append(st[0])
			draw_polyline(st, c, lw * 0.7, true)
		"lock":
			draw_rect(Rect2(p.call(0.25, 0.45), Vector2(0.5, 0.38) * s), c)
			draw_arc(p.call(0.5, 0.45), s * 0.17, PI, TAU, 16, c, lw, true)
		"coin":
			draw_circle(p.call(0.5, 0.5), s * 0.38, c)
			draw_string(ThemeBuilder.font(900), o + Vector2(0.29, 0.69) * s, "₺", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.55), Palette.BG)
		"people":
			draw_circle(p.call(0.36, 0.32), s * 0.13, c)
			draw_circle(p.call(0.68, 0.36), s * 0.11, Color(c, 0.75))
			draw_colored_polygon(_half_disc(o + Vector2(0.36, 0.82) * s, s * 0.25), c)
			draw_colored_polygon(_half_disc(o + Vector2(0.7, 0.82) * s, s * 0.2), Color(c, 0.75))
		"smile":
			draw_arc(p.call(0.5, 0.5), s * 0.38, 0, TAU, 32, c, lw * 0.8, true)
			draw_circle(p.call(0.37, 0.42), s * 0.05, c)
			draw_circle(p.call(0.63, 0.42), s * 0.05, c)
			draw_arc(p.call(0.5, 0.5), s * 0.2, 0.35, PI - 0.35, 12, c, lw * 0.8, true)
		"calendar":
			draw_rect(Rect2(p.call(0.17, 0.25), Vector2(0.66, 0.58) * s), c, false, lw * 0.8)
			draw_line(p.call(0.17, 0.4), p.call(0.83, 0.4), c, lw * 0.8)
			draw_line(p.call(0.35, 0.15), p.call(0.35, 0.3), c, lw * 0.8)
			draw_line(p.call(0.65, 0.15), p.call(0.65, 0.3), c, lw * 0.8)
		"info":
			draw_arc(p.call(0.5, 0.5), s * 0.38, 0, TAU, 32, c, lw * 0.8, true)
			draw_line(p.call(0.5, 0.45), p.call(0.5, 0.72), c, lw, true)
			draw_circle(p.call(0.5, 0.31), s * 0.05, c)
		"train":
			draw_rect(Rect2(p.call(0.25, 0.15), Vector2(0.5, 0.58) * s), c)
			draw_rect(Rect2(p.call(0.32, 0.24), Vector2(0.36, 0.18) * s), Palette.PANEL_2)
			draw_circle(p.call(0.36, 0.6), s * 0.05, Palette.PANEL_2)
			draw_circle(p.call(0.64, 0.6), s * 0.05, Palette.PANEL_2)
			draw_line(p.call(0.3, 0.88), p.call(0.4, 0.74), c, lw * 0.8, true)
			draw_line(p.call(0.7, 0.88), p.call(0.6, 0.74), c, lw * 0.8, true)
		"warning":
			draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.15), p.call(0.88, 0.82), p.call(0.12, 0.82)]), c)
			draw_line(p.call(0.5, 0.38), p.call(0.5, 0.6), Palette.BG, lw, true)
			draw_circle(p.call(0.5, 0.71), s * 0.045, Palette.BG)
		"home":
			draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.18), p.call(0.85, 0.5), p.call(0.15, 0.5)]), c)
			draw_rect(Rect2(p.call(0.25, 0.48), Vector2(0.5, 0.34) * s), c)
		"heart":
			var hp := PackedVector2Array()
			for k in 33:
				var a := TAU * k / 32.0
				var x := 16.0 * pow(sin(a), 3)
				var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
				hp.append(o + (Vector2(0.5, 0.48) + Vector2(x, y) / 38.0) * s)
			draw_colored_polygon(hp, c)
		"repost":
			draw_polyline(PackedVector2Array([p.call(0.2, 0.55), p.call(0.2, 0.3), p.call(0.72, 0.3)]), c, lw, true)
			draw_colored_polygon(PackedVector2Array([p.call(0.68, 0.18), p.call(0.85, 0.3), p.call(0.68, 0.42)]), c)
			draw_polyline(PackedVector2Array([p.call(0.8, 0.45), p.call(0.8, 0.7), p.call(0.28, 0.7)]), c, lw, true)
			draw_colored_polygon(PackedVector2Array([p.call(0.32, 0.58), p.call(0.15, 0.7), p.call(0.32, 0.82)]), c)
		"bird":
			var body := PackedVector2Array([p.call(0.12, 0.45), p.call(0.3, 0.62), p.call(0.55, 0.72), p.call(0.8, 0.55),
				p.call(0.9, 0.3), p.call(0.78, 0.35), p.call(0.7, 0.22), p.call(0.55, 0.3), p.call(0.5, 0.48), p.call(0.3, 0.5)])
			draw_colored_polygon(body, c)
			draw_circle(p.call(0.72, 0.34), s * 0.03, Palette.BG)
		"frown":
			draw_arc(p.call(0.5, 0.5), s * 0.38, 0, TAU, 32, c, lw * 0.8, true)
			draw_circle(p.call(0.37, 0.42), s * 0.05, c)
			draw_circle(p.call(0.63, 0.42), s * 0.05, c)
			draw_arc(p.call(0.5, 0.78), s * 0.2, PI + 0.5, TAU - 0.5, 12, c, lw * 0.8, true)
		"neutral":
			draw_arc(p.call(0.5, 0.5), s * 0.38, 0, TAU, 32, c, lw * 0.8, true)
			draw_circle(p.call(0.37, 0.42), s * 0.05, c)
			draw_circle(p.call(0.63, 0.42), s * 0.05, c)
			draw_line(p.call(0.36, 0.64), p.call(0.64, 0.64), c, lw * 0.8, true)
		"trophy":
			draw_colored_polygon(PackedVector2Array([p.call(0.28, 0.16), p.call(0.72, 0.16), p.call(0.68, 0.42), p.call(0.58, 0.55), p.call(0.42, 0.55), p.call(0.32, 0.42)]), c)
			draw_arc(p.call(0.26, 0.3), s * 0.1, PI * 0.5, PI * 1.5, 10, c, lw * 0.8, true)
			draw_arc(p.call(0.74, 0.3), s * 0.1, -PI * 0.5, PI * 0.5, 10, c, lw * 0.8, true)
			draw_rect(Rect2(p.call(0.46, 0.55), Vector2(0.08, 0.16) * s), c)
			draw_rect(Rect2(p.call(0.3, 0.71), Vector2(0.4, 0.12) * s), c)
		"flask":
			draw_colored_polygon(PackedVector2Array([p.call(0.4, 0.15), p.call(0.6, 0.15), p.call(0.6, 0.4), p.call(0.82, 0.82), p.call(0.18, 0.82), p.call(0.4, 0.4)]), Color(c, 0.35))
			draw_polyline(PackedVector2Array([p.call(0.4, 0.15), p.call(0.4, 0.4), p.call(0.18, 0.82), p.call(0.82, 0.82), p.call(0.6, 0.4), p.call(0.6, 0.15)]), c, lw * 0.8, true)
			draw_line(p.call(0.34, 0.15), p.call(0.66, 0.15), c, lw * 0.8, true)
			draw_colored_polygon(PackedVector2Array([p.call(0.29, 0.62), p.call(0.71, 0.62), p.call(0.82, 0.82), p.call(0.18, 0.82)]), c)
		"sun":
			var sc: Vector2 = p.call(0.5, 0.5)
			draw_circle(sc, s * 0.2, c)
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(sc + Vector2.from_angle(a) * s * 0.29, sc + Vector2.from_angle(a) * s * 0.4, c, lw * 0.8, true)
		"moon":
			draw_circle(p.call(0.5, 0.5), s * 0.32, c)
			draw_circle(p.call(0.64, 0.4), s * 0.27, Color(0.1, 0.13, 0.19))
		"megaphone":
			draw_colored_polygon(PackedVector2Array([p.call(0.15, 0.4), p.call(0.35, 0.4), p.call(0.8, 0.18), p.call(0.8, 0.82), p.call(0.35, 0.6), p.call(0.15, 0.6)]), c)
			draw_line(p.call(0.3, 0.6), p.call(0.38, 0.85), c, lw, true)
		_:
			draw_circle(p.call(0.5, 0.5), s * 0.3, c)


static func _star(center: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		var r := r_out if k % 2 == 0 else r_in
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


static func _half_disc(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts
