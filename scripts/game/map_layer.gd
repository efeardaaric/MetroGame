class_name MapLayer
extends Node2D
## Background map, built for crisp rendering at every zoom level:
##   1. land + parks (vector)
##   2. hill shading and optional heat map (high-res mipmapped rasters, never masked)
##   3. WaterLayer on top: sea, rivers, shores and islands as anti-aliased vectors,
##      so coastlines stay sharp no matter how far you zoom in.

const PX := 100.0 # pixels per km in world space
const HILL_STEP := 0.1
const ELEV_STEP := 0.15

var city: CityMap
var hillshade: Sprite2D
var heat: Sprite2D
var water: WaterLayer
var _heat_cache := {}


func setup(c: CityMap) -> void:
	city = c
	_build_hillshade()
	heat = Sprite2D.new()
	heat.centered = false
	heat.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	heat.visible = false
	add_child(heat)
	water = WaterLayer.new()
	water.city = c
	add_child(water)
	queue_redraw()


func set_zoom(z: float) -> void:
	if water:
		water.set_zoom(z)


## Loads a baked raster (or builds it) and returns a mipmapped, linearly filtered texture.
static func smooth_texture(path: String, fallback: Callable) -> Texture2D:
	var img: Image
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		img = t.get_image()
	else:
		img = fallback.call()
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func set_overlay(kind: String) -> void:
	if kind == "none" or city == null:
		heat.visible = false
		return
	if not _heat_cache.has(kind):
		var baked := "res://assets/maps/%s_%s.png" % [city.id, kind]
		var c := city
		var fb := func() -> Image: return elev_image(c) if kind == "elev" else c.build_heat_image(kind)
		_heat_cache[kind] = smooth_texture(baked, fb)
	heat.texture = _heat_cache[kind]
	var tex: Texture2D = heat.texture
	# scale so the raster exactly covers the map regardless of its resolution
	heat.scale = city.size_km * PX / Vector2(tex.get_width(), tex.get_height())
	heat.visible = true
	heat.modulate.a = 0.0
	create_tween().tween_property(heat, "modulate:a", 1.0, 0.25)


func invalidate_overlay() -> void:
	pass # shapes are growth-invariant (uniform growth), nothing to rebuild


static func elev_image(city: CityMap) -> Image:
	var step := ELEV_STEP
	var w := int(ceil(city.size_km.x / step))
	var h := int(ceil(city.size_km.y / step))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emin := INF
	var emax := -INF
	var vals := PackedFloat32Array()
	vals.resize(w * h)
	for y in h:
		for x in w:
			var e := city.elevation_land(Vector2((x + 0.5) * step, (y + 0.5) * step))
			vals[y * w + x] = e
			emin = minf(emin, e)
			emax = maxf(emax, e)
	var stops := [Color(0.2, 0.6, 0.35, 0.55), Color(0.85, 0.8, 0.35, 0.55), Color(0.75, 0.45, 0.25, 0.6), Color(0.55, 0.3, 0.3, 0.65)]
	for y in h:
		for x in w:
			var t := clampf((vals[y * w + x] - emin) / maxf(1.0, emax - emin), 0.0, 1.0) * 2.999
			var i := int(t)
			img.set_pixel(x, y, (stops[i] as Color).lerp(stops[mini(i + 1, 3)], t - i))
	return img


func _build_hillshade() -> void:
	var baked := "res://assets/maps/%s_hillshade.png" % city.id
	var c := city
	var tex := smooth_texture(baked, func() -> Image: return hillshade_image(c))
	hillshade = Sprite2D.new()
	hillshade.centered = false
	hillshade.texture = tex
	hillshade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hillshade.scale = city.size_km * PX / Vector2(tex.get_width(), tex.get_height())
	add_child(hillshade)


static func hillshade_image(city: CityMap) -> Image:
	var step := HILL_STEP
	var w := int(ceil(city.size_km.x / step))
	var h := int(ceil(city.size_km.y / step))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var light := Vector3(-0.6, -0.6, 0.55).normalized()
	# sample heights once on a (w+1)x(h+1) grid, then shade from finite differences
	var ew := w + 1
	var hs := PackedFloat32Array()
	hs.resize(ew * (h + 1))
	for y in h + 1:
		for x in ew:
			hs[y * ew + x] = city.elevation_land(Vector2((x + 0.5) * step, (y + 0.5) * step))
	var zf := step * 1000.0 * 0.25 * (HILL_STEP / 0.25) * 2.5
	for y in h:
		for x in w:
			var e := hs[y * ew + x]
			var ex := hs[y * ew + x + 1] - e
			var ey := hs[(y + 1) * ew + x] - e
			var n := Vector3(-ex, -ey, zf).normalized()
			var shade := clampf((n.dot(light) - 0.55) * 2.2, -1.0, 1.0)
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
	for pk in city.park_polys:
		var poly := scaled(pk)
		draw_colored_polygon(poly, Palette.PARK)
		poly.append(poly[0])
		draw_polyline(poly, Palette.PARK_EDGE, 6.0, true)


static func scaled(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in poly.size():
		out[i] = poly[i] * PX
	return out
