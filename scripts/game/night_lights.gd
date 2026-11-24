class_name NightLights
extends Node2D
## Additive city lights shown at night: districts, stations, bridges and train headlights.
## Lives on a CanvasLayer that follows the camera, so CanvasModulate darkening doesn't affect it.

const PX := MapLayer.PX

var city: CityMap
var net: TransitNetwork
var vehicles: VehicleLayer
var zoom := 1.0
var _glow: Texture2D
var _static: StaticPart
var _dyn: DynPart
var _bridges: Array = []


class StaticPart:
	extends Node2D
	var owner_l: NightLights
	func _draw() -> void:
		owner_l._draw_static(self)


class DynPart:
	extends Node2D
	var owner_l: NightLights
	func _process(_d: float) -> void:
		if owner_l.modulate.a > 0.02:
			queue_redraw()
	func _draw() -> void:
		owner_l._draw_dynamic(self)


func setup(c: CityMap, n: TransitNetwork, v: VehicleLayer) -> void:
	city = c
	net = n
	vehicles = v
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	_glow = gt
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_static = StaticPart.new()
	_static.owner_l = self
	_static.use_parent_material = true
	add_child(_static)
	_dyn = DynPart.new()
	_dyn.owner_l = self
	_dyn.use_parent_material = true
	add_child(_dyn)
	for b in CityEvents.flavor(c).get("bridges", []):
		_bridges.append([c.project(b["a"][0], b["a"][1]) * PX, c.project(b["b"][0], b["b"][1]) * PX])
	n.changed.connect(_static.queue_redraw)
	modulate.a = 0.0


func set_zoom(z: float) -> void:
	if absf(z - zoom) / zoom > 0.05:
		zoom = z
		_static.queue_redraw()


func _g(ci: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	ci.draw_texture_rect(_glow, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


func _draw_static(ci: CanvasItem) -> void:
	if city == null:
		return
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	var warm := Color(1.0, 0.68, 0.3, 0.2)
	for z in city.zones:
		if z["pop"] <= 0 and z["poi_id"] == "":
			continue
		var dens: float = clampf(sqrt(z["pop"] + z["jobs"]) / 28.0, 0.25, 1.0)
		var r: float = (5.0 + 4.0 * dens) * inv
		for s in z["samples"]:
			_g(ci, s * PX, r, Color(warm, warm.a * dens))
	for b in _bridges:
		for k in 13:
			_g(ci, (b[0] as Vector2).lerp(b[1], k / 12.0), 7.0 * inv, Color(1.0, 0.88, 0.55, 0.6))
	for s in net.stations.values():
		_g(ci, s["pos"] * PX, 22.0 * inv, Color(0.6, 0.8, 1.0, 0.4))


func _draw_dynamic(ci: CanvasItem) -> void:
	if vehicles == null:
		return
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	for v in vehicles.light_points:
		var p: Vector2 = v[0]
		var d: Vector2 = v[1]
		_g(ci, p, 10.0 * inv, Color(1.0, 0.95, 0.8, 0.55))
		_g(ci, p + d * 16.0 * inv, 9.0 * inv, Color(1.0, 1.0, 0.85, 0.45))
