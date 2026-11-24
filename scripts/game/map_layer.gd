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
var roads: RoadNet
var edge: EdgeFade
var _heat_cache := {}
var _glow: Texture2D


## Arterial roads, redrawn so they keep a readable width at every zoom level.
class RoadNet:
	extends Node2D
	var layer: MapLayer
	var zoom := 0.2
	func set_zoom(z: float) -> void:
		if absf(z - zoom) / zoom > 0.1:
			zoom = z
			queue_redraw()
	func _draw() -> void:
		var inv := 1.0 / clampf(zoom, 0.03, 3.0)
		for r in layer._roads:
			draw_polyline(r[0], Color("d9ccb2"), maxf(26.0 if r[1] else 18.0, (4.2 if r[1] else 3.0) * inv), true)
		for r in layer._roads:
			draw_polyline(r[0], Color("fbf6ea"), maxf(16.0 if r[1] else 10.0, (2.6 if r[1] else 1.7) * inv), true)


## Soft cartographic vignette around the playable area, drawn above the sea,
## so zooming out shows the city fading into its surroundings, not a hard frame.
class EdgeFade:
	extends Node2D
	var size_px := Vector2.ONE
	func _draw() -> void:
		var d := 9.0 * MapLayer.PX
		var far := 45.0 * MapLayer.PX
		var c0 := Color(0.87, 0.83, 0.75, 0.0)
		var c1 := Color(0.87, 0.83, 0.75, 0.82)
		var w := size_px.x
		var h := size_px.y
		var cols := PackedColorArray([c0, c0, c1, c1])
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w + d, -d), Vector2(-d, -d)]), cols)
		draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, h), Vector2(w + d, h + d), Vector2(w + d, -d)]), cols)
		draw_polygon(PackedVector2Array([Vector2(w, h), Vector2(0, h), Vector2(-d, h + d), Vector2(w + d, h + d)]), cols)
		draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(0, 0), Vector2(-d, -d), Vector2(-d, h + d)]), cols)
		draw_rect(Rect2(-far, -far, w + 2 * far, far - d), c1)
		draw_rect(Rect2(-far, h + d, w + 2 * far, far - d), c1)
		draw_rect(Rect2(-far, -d, far - d, h + 2 * d), c1)
		draw_rect(Rect2(w + d, -d, far - d, h + 2 * d), c1)
		# hairline neatline, like a printed map sheet
		draw_rect(Rect2(Vector2(-d * 0.35, -d * 0.35), size_px + Vector2(d, d) * 0.7), Color(0.45, 0.38, 0.28, 0.35), false, 10.0)


func setup(c: CityMap) -> void:
	city = c
	var t0 := Time.get_ticks_msec()
	_add_grain()
	_build_land_deco()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	_glow = gt
	roads = RoadNet.new()
	roads.layer = self
	add_child(roads)
	print_verbose("map deco ms ", Time.get_ticks_msec() - t0)
	_build_hillshade()
	heat = Sprite2D.new()
	heat.centered = false
	heat.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	heat.visible = false
	add_child(heat)
	water = WaterLayer.new()
	water.city = c
	add_child(water)
	edge = EdgeFade.new()
	edge.size_px = c.size_km * PX
	add_child(edge)
	queue_redraw()


func set_zoom(z: float) -> void:
	if water:
		water.set_zoom(z)
	if roads:
		roads.set_zoom(z)


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


var _blocks: Array = []      # [PackedVector2Array(px), Color]
var _roads: Array = []       # [PackedVector2Array(px), major:bool]
var _trees: PackedVector2Array = PackedVector2Array()




## Urban fabric, arterial roads and forest dots, generated deterministically per city.
func _build_land_deco() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(city.id + "_land")
	# --- city blocks
	for z in city.zones:
		var pop: float = z["base_pop"]
		var jobs: float = z["base_jobs"]
		if pop + jobs <= 0.0:
			continue
		var is_poi: bool = z["poi_id"] != ""
		var n := clampi(int((pop / 7.0 + jobs / 9.0) * (0.5 if is_poi else 1.0)), 8, 150)
		var r: float = maxf(0.5, z["r"]) * (1.15 if not is_poi else 0.9)
		var ang := rng.randf() * PI
		var biz := jobs > pop * 1.3
		var col := Color("d6cbb4") if not biz else Color("cbbfa8")
		col.a = 0.75
		# blocks laid out on a street grid rotated to the district's orientation
		var step := 0.27 if not biz else 0.33
		var cells := int(ceil(r * 1.25 / step))
		var dens := clampf(float(n) / 90.0, 0.25, 1.0)
		var axis := Vector2.from_angle(ang)
		var perp := axis.orthogonal()
		for gx in range(-cells, cells + 1):
			for gy in range(-cells, cells + 1):
				var c: Vector2 = z["pos"] + axis * gx * step + perp * gy * step
				var d: float = c.distance_to(z["pos"]) / (r * 1.25)
				if d > 1.0 or rng.randf() > dens * pow(1.0 - d, 0.6):
					continue
				if not city.in_bounds(c) or city.is_water(c) or city.is_park(c) >= 0:
					continue
				var sz := Vector2(step * rng.randf_range(0.55, 0.78), step * rng.randf_range(0.45, 0.7))
				if rng.randf() < 0.18:
					sz.x = step * 1.6 # merged long block
				var pts := PackedVector2Array()
				for k in 4:
					var corner := Vector2(sz.x * (1 if k == 1 or k == 2 else -1), sz.y * (1 if k >= 2 else -1)) * 0.5
					pts.append((c + corner.rotated(ang)) * PX)
				_blocks.append([pts, col.darkened(rng.randf_range(0.0, 0.07) + (1.0 - d) * 0.05)])
	# --- arterial roads: minimum spanning tree over district centres + nearest links
	var nodes: Array = []
	for z in city.zones:
		if z["poi_id"] == "" and city.in_bounds(z["pos"]):
			nodes.append(z["pos"])
	for p in city.pois:
		nodes.append(p["pos"])
	var edges := {}
	var in_tree := {0: true}
	while in_tree.size() < nodes.size():
		var best := Vector2i(-1, -1)
		var bd := INF
		for i in in_tree.keys():
			for j in nodes.size():
				if in_tree.has(j):
					continue
				var d: float = nodes[i].distance_to(nodes[j])
				if d < bd and _road_ok(nodes[i], nodes[j]):
					bd = d
					best = Vector2i(i, j)
		if best.x < 0:
			# isolated component (across water): start a new tree there
			for j in nodes.size():
				if not in_tree.has(j):
					in_tree[j] = true
					break
			continue
		in_tree[best.y] = true
		edges[Vector2i(mini(best.x, best.y), maxi(best.x, best.y))] = true
	for i in nodes.size():
		var near: Array = []
		for j in nodes.size():
			if i != j:
				near.append([nodes[i].distance_to(nodes[j]), j])
		near.sort_custom(func(x, y): return x[0] < y[0])
		for k in mini(2, near.size()):
			var j: int = near[k][1]
			if near[k][0] < 7.0 and _road_ok(nodes[i], nodes[j]):
				edges[Vector2i(mini(i, j), maxi(i, j))] = true
	for e in edges.keys():
		var a: Vector2 = nodes[e.x]
		var b: Vector2 = nodes[e.y]
		# gentle curve
		var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * a.distance_to(b) * rng.randf_range(-0.08, 0.08)
		var pts := PackedVector2Array()
		for k in 9:
			var t := k / 8.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t) * PX)
		_roads.append([pts, a.distance_to(b) > 3.0])
	# --- forest dots
	for pk in city.park_polys:
		var bb := Rect2(pk[0], Vector2.ZERO)
		for q in pk:
			bb = bb.expand(q)
		var count := int(bb.get_area() * 9.0)
		for i in mini(count, 900):
			var q := bb.position + Vector2(rng.randf() * bb.size.x, rng.randf() * bb.size.y)
			if Geometry2D.is_point_in_polygon(q, pk) and not city.is_water(q):
				_trees.append(q * PX)


func _road_ok(a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) / 0.25) + 1
	for k in n + 1:
		if city.is_sea(a.lerp(b, float(k) / n)):
			return false
	return true


## Subtle paper grain over the land (tileable noise texture).
func _add_grain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.35
	noise.fractal_octaves = 2
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			# seamless: blend four offsets
			var v := noise.get_noise_2d(x, y) * (size - x) * (size - y)
			v += noise.get_noise_2d(x - size, y) * x * (size - y)
			v += noise.get_noise_2d(x, y - size) * (size - x) * y
			v += noise.get_noise_2d(x - size, y - size) * x * y
			v /= size * size
			img.set_pixel(x, y, Color(0.35, 0.28, 0.18, clampf(0.035 + v * 0.09, 0.0, 0.12)))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.region_enabled = true
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var world := city.size_km * PX
	spr.scale = Vector2(6, 6)
	spr.region_rect = Rect2(Vector2.ZERO, world / 6.0)
	add_child(spr)
	move_child(spr, 0)


func _draw() -> void:
	if city == null:
		return
	var sz := city.size_km * PX
	draw_rect(Rect2(Vector2(-5000, -5000), sz + Vector2(10000, 10000)), Palette.LAND)
	# built-up area: a warm wash under every district, so the city reads as a
	# continuous urban mass when zoomed out
	for z in city.zones:
		var amount: float = z["base_pop"] + z["base_jobs"]
		if amount <= 0.0 or z["poi_id"] != "":
			continue
		var r: float = maxf(0.8, float(z["r"])) * 1.9 * PX
		var a := clampf(0.18 + amount / 900.0, 0.18, 0.5)
		draw_texture_rect(_glow, Rect2(z["pos"] * PX - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(0.83, 0.74, 0.6, a))
	# forests
	for pk in city.park_polys:
		var poly := scaled(pk)
		draw_colored_polygon(poly, Palette.PARK)
		poly.append(poly[0])
		draw_polyline(poly, Palette.PARK_EDGE, 8.0, true)
	for t in _trees:
		draw_circle(t + Vector2(4, 5), 11.0, Color(0.3, 0.45, 0.25, 0.18))
		draw_circle(t, 10.0, Color("a9cc93"))
		draw_circle(t + Vector2(-3, -3), 4.0, Color("c4ddb0"))
	# urban blocks
	for b in _blocks:
		draw_colored_polygon(b[0], b[1])


static func scaled(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in poly.size():
		out[i] = poly[i] * PX
	return out
