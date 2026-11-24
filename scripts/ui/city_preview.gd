class_name CityPreview
extends Control
## Mini map silhouette of a city for the city-select cards.

var city_id := "istanbul"
var _city: CityMap


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_city = CityMap.new(city_id)
	resized.connect(queue_redraw)


func _draw() -> void:
	if _city == null:
		return
	clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.LAND
	sb.set_corner_radius_all(22)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var sz := _city.size_km
	var sc := maxf(size.x / sz.x, size.y / sz.y)
	var off := (size - sz * sc) * 0.5
	var xf := func(p: Vector2) -> Vector2: return off + p * sc
	var clip := Rect2(Vector2.ZERO, size)
	for pk in _city.park_polys:
		draw_colored_polygon(_tx(pk, xf, clip), Palette.PARK)
	for wp in _city.water_polys + _city.river_polys:
		var poly := _tx(wp, xf, clip)
		if poly.size() >= 3:
			var idx := Geometry2D.triangulate_polygon(poly)
			if idx.size() >= 3:
				var cols := PackedColorArray()
				cols.resize(poly.size())
				cols.fill(Palette.WATER)
				RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols)
	for isl in _city.island_polys:
		var poly := _tx(isl, xf, clip)
		if poly.size() >= 3:
			draw_colored_polygon(poly, Palette.LAND)
	# population dots
	for z in _city.zones:
		if z["pop"] <= 0:
			continue
		var p: Vector2 = xf.call(z["pos"])
		if clip.has_point(p):
			draw_circle(p, 2.0 + sqrt(z["pop"]) * 0.22, Color(0.85, 0.3, 0.25, 0.35))
	for poi in _city.pois:
		var p: Vector2 = xf.call(poi["pos"])
		if clip.has_point(p):
			draw_circle(p, 5.0, Color("5e60ce"))
	# frame
	var fr := StyleBoxFlat.new()
	fr.bg_color = Color(0, 0, 0, 0)
	fr.set_corner_radius_all(22)
	fr.set_border_width_all(6)
	fr.border_color = Color(0.1, 0.13, 0.2, 1)
	draw_style_box(fr, Rect2(Vector2(-3, -3), size + Vector2(6, 6)))


func _tx(poly: PackedVector2Array, xf: Callable, clip: Rect2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(xf.call(p))
	return out
