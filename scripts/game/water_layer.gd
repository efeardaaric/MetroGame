class_name WaterLayer
extends Node2D
## Vector sea / rivers / islands drawn above the terrain rasters.
## Edges get an anti-aliased stroke whose width tracks the zoom, so coastlines are
## smooth and sharp at any magnification (no raster stair-stepping).

const PX := MapLayer.PX

var city: CityMap
var zoom := 1.0
var _water: Array[PackedVector2Array] = []
var _rivers: Array[PackedVector2Array] = []
var _islands: Array[PackedVector2Array] = []
var _tris := {}  # poly index -> PackedInt32Array


func _ready() -> void:
	for wp in city.water_polys:
		_water.append(MapLayer.scaled(wp))
	for rv in city.river_polys:
		_rivers.append(MapLayer.scaled(rv))
	for isl in city.island_polys:
		_islands.append(MapLayer.scaled(isl))
	queue_redraw()


func set_zoom(z: float) -> void:
	if absf(z - zoom) / zoom > 0.08:
		zoom = z
		queue_redraw()


func _px(screen: float) -> float:
	return screen / clampf(zoom, 0.03, 4.0)


func _draw() -> void:
	if city == null:
		return
	var shore_w := maxf(26.0, _px(5.0))
	# 1) shore band (only its land half remains visible after the water fill)
	for poly in _water:
		_ring(poly, Palette.SHORE, shore_w)
	for poly in _rivers:
		_ring(poly, Palette.SHORE, maxf(8.0, _px(3.0)))
	# 2) anti-aliased water edge drawn *before* the fills: other polygons' fills hide the
	#    parts that lie inside open water, only the smooth outer edge at the coast remains
	for poly in _water:
		_ring(poly, Palette.WATER, _px(2.0))
	for poly in _rivers:
		_ring(poly, Palette.WATER, _px(1.6))
	for i in _water.size():
		_fill(_water[i], Palette.WATER, "w%d" % i)
	for i in _rivers.size():
		_fill(_rivers[i], Palette.WATER, "r%d" % i)
	# 3) islands on top of the sea
	for i in _islands.size():
		_ring(_islands[i], Palette.SHORE, maxf(22.0, _px(4.0)))
		_fill(_islands[i], Palette.LAND, "i%d" % i)
		_ring(_islands[i], Palette.LAND, _px(1.4))
	# map frame
	draw_rect(Rect2(Vector2.ZERO, city.size_km * PX), Color(0, 0, 0, 0.12), false, maxf(6.0, _px(2.0)))


func _ring(poly: PackedVector2Array, c: Color, w: float) -> void:
	var r := poly.duplicate()
	r.append(r[0])
	draw_polyline(r, c, w, true)


func _fill(poly: PackedVector2Array, c: Color, key: String) -> void:
	if not _tris.has(key):
		_tris[key] = Geometry2D.triangulate_polygon(poly)
	var idx: PackedInt32Array = _tris[key]
	if idx.size() >= 3:
		var cols := PackedColorArray()
		cols.resize(poly.size())
		cols.fill(c)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols)
	else:
		for part in Geometry2D.decompose_polygon_in_convex(poly):
			draw_colored_polygon(part, c)
