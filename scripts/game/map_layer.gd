class_name MapLayer
extends Node2D
## Static background map: land, sea, rivers, parks, hill shading. Drawn once.

const PX := 100.0 # pixels per km in world space
const HILL_STEP := 0.25

var city: CityMap
var hillshade: Sprite2D
var heat: Sprite2D
var _heat_cache := {}


func setup(c: CityMap) -> void:
	city = c
	_build_hillshade()
	heat = Sprite2D.new()
	heat.centered = false
	heat.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	heat.visible = false
	add_child(heat)
	queue_redraw()


func set_overlay(kind: String) -> void:
	if kind == "none" or city == null:
		heat.visible = false
		return
	if not _heat_cache.has(kind):
		var baked := "res://assets/maps/%s_%s.png" % [city.id, kind]
		if ResourceLoader.exists(baked):
			_heat_cache[kind] = load(baked)
		else:
			var img: Image
			if kind == "elev":
				img = elev_image(city)
			else:
				img = city.build_heat_image(kind)
			_heat_cache[kind] = ImageTexture.create_from_image(img)
	heat.texture = _heat_cache[kind]
	var step := CityMap.GRID_STEP if kind != "elev" else 0.4
	heat.scale = Vector2.ONE * step * PX
	heat.visible = true
	heat.modulate.a = 0.0
	create_tween().tween_property(heat, "modulate:a", 1.0, 0.25)


func invalidate_overlay() -> void:
	pass # shapes are growth-invariant (uniform growth), nothing to rebuild


static func elev_image(city: CityMap) -> Image:
	var step := 0.4
	var w := int(ceil(city.size_km.x / step))
	var h := int(ceil(city.size_km.y / step))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emin := INF
	var emax := -INF
	var vals := PackedFloat32Array()
	vals.resize(w * h)
	for y in h:
		for x in w:
			var p := Vector2((x + 0.5) * step, (y + 0.5) * step)
			var e := city.elevation(p)
			vals[y * w + x] = e
			if e > -1.0:
				emin = minf(emin, e)
				emax = maxf(emax, e)
	var stops := [Color(0.2, 0.6, 0.35, 0.55), Color(0.85, 0.8, 0.35, 0.55), Color(0.75, 0.45, 0.25, 0.6), Color(0.55, 0.3, 0.3, 0.65)]
	for y in h:
		for x in w:
			var e: float = vals[y * w + x]
			if e < -1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var t := clampf((e - emin) / maxf(1.0, emax - emin), 0.0, 1.0) * 2.999
			var i := int(t)
			img.set_pixel(x, y, (stops[i] as Color).lerp(stops[mini(i + 1, 3)], t - i))
	return img


func _build_hillshade() -> void:
	var step := HILL_STEP
	var tex: Texture2D
	var baked := "res://assets/maps/%s_hillshade.png" % city.id
	if ResourceLoader.exists(baked):
		tex = load(baked)
	else:
		tex = ImageTexture.create_from_image(hillshade_image(city))
	hillshade = Sprite2D.new()
	hillshade.centered = false
	hillshade.texture = tex
	hillshade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hillshade.scale = Vector2.ONE * step * PX
	add_child(hillshade)


static func hillshade_image(city: CityMap) -> Image:
	var step := HILL_STEP
	var w := int(ceil(city.size_km.x / step))
	var h := int(ceil(city.size_km.y / step))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var light := Vector3(-0.6, -0.6, 0.55).normalized()
	for y in h:
		for x in w:
			var p := Vector2((x + 0.5) * step, (y + 0.5) * step)
			if city.is_sea(p):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var e := city.elevation(p)
			var ex := city.elevation(p + Vector2(step, 0)) - e
			var ey := city.elevation(p + Vector2(0, step)) - e
			var n := Vector3(-ex, -ey, step * 1000.0 * 0.25).normalized()
			var d := n.dot(light)
			var shade := clampf((d - 0.55) * 2.2, -1.0, 1.0)
			if shade < 0.0:
				img.set_pixel(x, y, Color(0.35, 0.28, 0.2, -shade * 0.35))
			else:
				img.set_pixel(x, y, Color(1, 1, 0.95, shade * 0.25))
	return img


func _draw() -> void:
	if city == null:
		return
	var sz := city.size_km * PX
	draw_rect(Rect2(Vector2(-4000, -4000), sz + Vector2(8000, 8000)), Palette.LAND_DARK)
	draw_rect(Rect2(Vector2.ZERO, sz), Palette.LAND)
	# parks
	for pk in city.park_polys:
		var poly := _scaled(pk)
		draw_colored_polygon(poly, Palette.PARK)
		poly.append(poly[0])
		draw_polyline(poly, Palette.PARK_EDGE, 6.0, true)
	# shores (drawn under the water fill so only the land side shows)
	for wp in city.water_polys:
		var poly := _scaled(wp)
		poly.append(poly[0])
		draw_polyline(poly, Palette.SHORE, 26.0, true)
	for rv in city.river_polys:
		var poly := _scaled(rv)
		poly.append(poly[0])
		draw_polyline(poly, Palette.SHORE, 8.0, true)
	for wp in city.water_polys:
		var poly := _scaled(wp)
		_fill_polygon(poly, Palette.WATER)
	for rv in city.river_polys:
		_fill_polygon(_scaled(rv), Palette.WATER)
	for isl in city.island_polys:
		var poly := _scaled(isl)
		var ring := poly.duplicate()
		ring.append(ring[0])
		draw_polyline(ring, Palette.SHORE, 22.0, true)
		draw_colored_polygon(poly, Palette.LAND)
	# map frame
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.12), false, 6.0)


func _fill_polygon(poly: PackedVector2Array, c: Color) -> void:
	# Triangulate robustly; fall back to convex decomposition when needed.
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.size() >= 3:
		var cols := PackedColorArray()
		cols.resize(poly.size())
		cols.fill(c)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols)
	else:
		for part in Geometry2D.decompose_polygon_in_convex(poly):
			draw_colored_polygon(part, c)


func _scaled(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in poly.size():
		out[i] = poly[i] * PX
	return out
