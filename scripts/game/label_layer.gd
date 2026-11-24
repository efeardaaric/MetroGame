class_name LabelLayer
extends Node2D
## District names & points of interest; constant on-screen size, zoom dependent density.

const PX := MapLayer.PX

var city: CityMap
var zoom := 1.0
var dim := false


func setup(c: CityMap) -> void:
	city = c
	queue_redraw()


func set_zoom(z: float) -> void:
	if absf(z - zoom) / zoom > 0.04:
		zoom = z
		queue_redraw()


func _draw() -> void:
	if city == null:
		return
	var inv := 1.0 / zoom
	var f := ThemeBuilder.font(800)
	var f2 := ThemeBuilder.font(700)
	var a := 0.45 if dim else 1.0
	# Districts: larger ones visible earlier
	var min_pop := 0.0
	if zoom < 0.12:
		min_pop = 500.0
	elif zoom < 0.2:
		min_pop = 250.0
	elif zoom < 0.35:
		min_pop = 60.0
	var fs := 22.0
	for z in city.zones:
		if z["poi_id"] != "":
			continue
		if z["base_pop"] < min_pop:
			continue
		var pos: Vector2 = z["pos"] * PX
		var txt: String = z["name"].to_upper()
		var size := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
		draw_set_transform(pos, 0.0, Vector2(inv, inv))
		draw_string_outline(f, Vector2(-size.x * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), 6, Color(Palette.LAND, 0.85 * a))
		draw_string(f, Vector2(-size.x * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), Color(Palette.LABEL, 0.85 * a))
	# POIs
	if zoom >= 0.09:
		for poi in city.pois:
			var pos: Vector2 = poi["pos"] * PX
			draw_set_transform(pos, 0.0, Vector2(inv, inv))
			_draw_poi_icon(poi["kind"], a)
			if zoom >= 0.16:
				var txt := I18n.t(poi["name_key"])
				var s2 := f2.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
				draw_string_outline(f2, Vector2(-s2.x * 0.5, 42), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color(Palette.LAND, 0.9 * a))
				draw_string(f2, Vector2(-s2.x * 0.5, 42), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3b4252", a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_poi_icon(kind: String, a: float) -> void:
	var col: Color
	match kind:
		"airport": col = Color("5e60ce")
		"university": col = Color("2a9d8f")
		"landmark": col = Color("e76f51")
		"terminal": col = Color("6d597a")
		_: col = Color("457b9d")
	col.a = a
	draw_circle(Vector2.ZERO, 17.0, Color(1, 1, 1, a))
	draw_circle(Vector2.ZERO, 14.0, col)
	var w := Color(1, 1, 1, a)
	match kind:
		"airport":
			draw_line(Vector2(0, -9), Vector2(0, 9), w, 3.0, true)
			draw_line(Vector2(-9, 1), Vector2(9, 1), w, 3.0, true)
			draw_line(Vector2(-4, 8), Vector2(4, 8), w, 2.5, true)
		"university":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(10, -2), Vector2(0, 4), Vector2(-10, -2)]), w)
			draw_line(Vector2(-6, 1), Vector2(-6, 7), w, 2.5)
			draw_line(Vector2(6, 1), Vector2(6, 7), w, 2.5)
		"landmark":
			draw_colored_polygon(Icon._star(Vector2(0, 1), 10.0, 4.5), w)
		"terminal":
			draw_rect(Rect2(-7, -8, 14, 13), w)
			draw_circle(Vector2(-4, 8), 2.5, w)
			draw_circle(Vector2(4, 8), 2.5, w)
		_:
			draw_rect(Rect2(-7, -8, 5, 16), w)
			draw_rect(Rect2(0, -4, 7, 12), w)
