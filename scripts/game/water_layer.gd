class_name WaterLayer
extends Node2D
## Stylised vector sea drawn above the terrain rasters:
##   sand shore band → depth-tinted water (shallow turquoise → deep blue) →
##   offshore contour lines → crisp coastline → islands → drifting wave marks.
## Everything except the depth tint is vector, so it stays sharp at any zoom.

const PX := MapLayer.PX
const CONTOURS := [[0.14, 0.42], [0.34, 0.26], [0.7, 0.15], [1.25, 0.08]] # [km offshore, alpha]

var city: CityMap
var zoom := 1.0
var _water: Array[PackedVector2Array] = []
var _rivers: Array[PackedVector2Array] = []
var _islands: Array[PackedVector2Array] = []
var _union: Array = []        # merged coast rings (px)
var _contours: Array = []     # [ring(px), alpha]
var _tris := {}
var _depth: Texture2D
var _waves: WaveMarks


## Small animated "≈" marks scattered over open water (constant screen size).
class WaveMarks:
	extends Node2D
	var pts: PackedVector2Array = PackedVector2Array()
	var phase: PackedFloat32Array = PackedFloat32Array()
	var zoom := 1.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_frames_drawn() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		if zoom < 0.08:
			return
		var inv := 1.0 / clampf(zoom, 0.05, 2.0)
		var a := clampf((zoom - 0.08) / 0.1, 0.0, 1.0) * 0.55
		for i in pts.size():
			var ph := phase[i]
			var bob := sin(_t * 0.9 + ph) * 3.0
			var fade := 0.55 + 0.45 * sin(_t * 0.6 + ph * 1.7)
			draw_set_transform(pts[i] + Vector2(bob, 0) * inv, 0.0, Vector2(inv, inv))
			var c := Color(1, 1, 1, a * fade)
			for k in 2:
				var y := k * 6.0
				var x0 := -11.0 + k * 5.0
				draw_arc(Vector2(x0, y), 5.0, PI * 1.1, PI * 1.9, 6, c, 1.8, true)
				draw_arc(Vector2(x0 + 9.0, y), 5.0, PI * 1.1, PI * 1.9, 6, c, 1.8, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for wp in city.water_polys:
		_water.append(MapLayer.scaled(wp))
	for rv in city.river_polys:
		_rivers.append(MapLayer.scaled(rv))
	for isl in city.island_polys:
		_islands.append(MapLayer.scaled(isl))
	var c := city
	_depth = MapLayer.smooth_texture("res://assets/maps/%s_depth.png" % city.id, func() -> Image: return c.build_depth_image())
	for ring in city.water_union():
		_union.append(MapLayer.scaled(ring))
		for cs in CONTOURS:
			for off in Geometry2D.offset_polygon(ring, -float(cs[0]), Geometry2D.JOIN_ROUND):
				if not Geometry2D.is_polygon_clockwise(off) and off.size() >= 8:
					_contours.append([MapLayer.scaled(off), cs[1]])
	for isl in city.island_polys:
		for cs in CONTOURS.slice(0, 3):
			for off in Geometry2D.offset_polygon(isl, float(cs[0]), Geometry2D.JOIN_ROUND):
				_contours.append([MapLayer.scaled(off), cs[1]])
	_waves = WaveMarks.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(city.id + "_waves")
	var tries := 0
	while _waves.pts.size() < 140 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf() * city.size_km.x, rng.randf() * city.size_km.y)
		if not city.is_sea(p):
			continue
		var open := true
		for k in 6:
			if not city.is_sea(p + Vector2.from_angle(TAU * k / 6.0) * 0.9):
				open = false
				break
		if open:
			_waves.pts.append(p * PX)
			_waves.phase.append(rng.randf() * TAU)
	add_child(_waves)
	queue_redraw()


func set_zoom(z: float) -> void:
	if _waves:
		_waves.zoom = z
	if absf(z - zoom) / zoom > 0.08:
		zoom = z
		queue_redraw()


func _px(screen: float) -> float:
	return screen / clampf(zoom, 0.03, 4.0)


func _draw() -> void:
	if city == null:
		return
	# 1) two-tone sand shore band (only its land half stays visible)
	var shore_w := maxf(34.0, _px(6.0))
	for poly in _water:
		_ring(poly, Color("d8c9a6"), shore_w)
	for poly in _water:
		_ring(poly, Color("e9dcbd"), shore_w * 0.55)
	for poly in _rivers:
		_ring(poly, Palette.SHORE, maxf(8.0, _px(3.0)))
	# 2) soft anti-aliased edge, then depth-tinted fills
	for poly in _water:
		_ring(poly, Color("9fd8e6"), _px(2.0))
	for poly in _rivers:
		_ring(poly, Palette.WATER, _px(1.6))
	for i in _water.size():
		_fill(_water[i], "w%d" % i, true)
	for i in _rivers.size():
		_fill(_rivers[i], "r%d" % i, false)
	# 3) offshore contour lines (inside the merged sea: no internal seams)
	for c in _contours:
		_ring(c[0], Color(1, 1, 1, c[1]), maxf(5.0, _px(1.4)))
	# 4) islands
	for i in _islands.size():
		_ring(_islands[i], Color("d8c9a6"), maxf(26.0, _px(5.0)))
		_ring(_islands[i], Color("e9dcbd"), maxf(14.0, _px(2.8)))
		_fill(_islands[i], "i%d" % i, false, Palette.LAND)
		_ring(_islands[i], Palette.LAND, _px(1.4))
	# 5) crisp coastline
	var coast := Color("5f86a3")
	coast.a = 0.55
	for ring in _union:
		_ring(ring, coast, maxf(3.0, _px(1.3)))
	for isl in _islands:
		_ring(isl, coast, maxf(3.0, _px(1.3)))
	# map frame
	draw_rect(Rect2(Vector2.ZERO, city.size_km * PX), Color(0, 0, 0, 0.12), false, maxf(6.0, _px(2.0)))


func _ring(poly: PackedVector2Array, c: Color, w: float) -> void:
	var r := poly.duplicate()
	r.append(r[0])
	draw_polyline(r, c, w, true)


func _fill(poly: PackedVector2Array, key: String, textured: bool, col: Color = Palette.WATER) -> void:
	if not _tris.has(key):
		_tris[key] = Geometry2D.triangulate_polygon(poly)
	var idx: PackedInt32Array = _tris[key]
	if idx.size() < 3:
		for part in Geometry2D.decompose_polygon_in_convex(poly):
			draw_colored_polygon(part, col)
		return
	var cols := PackedColorArray()
	cols.resize(poly.size())
	if textured and _depth:
		cols.fill(Color.WHITE)
		var uvs := PackedVector2Array()
		uvs.resize(poly.size())
		var size := city.size_km * PX
		for i in poly.size():
			uvs[i] = Vector2(clampf(poly[i].x / size.x, 0.0, 1.0), clampf(poly[i].y / size.y, 0.0, 1.0))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols, uvs,
			PackedInt32Array(), PackedFloat32Array(), _depth.get_rid())
	else:
		cols.fill(col)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols)
