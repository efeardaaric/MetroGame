class_name FlavorLayer
extends Node2D
## City-specific living details: Bosphorus bridges, landmarks, gull flocks over the water,
## flamingos at the bird sanctuary, ferry wakes are drawn by VehicleLayer.

const PX := MapLayer.PX

var city: CityMap
var zoom := 1.0
var _birds: Array = []   # {pos, vel, target, kind, phase, home, r}
var _bridges: Array = [] # [a, b, name_key] in world px
var _decor: Array = []
var _rng := RandomNumberGenerator.new()
var _water_pts: PackedVector2Array = PackedVector2Array()
var _t := 0.0
var _bird_node: BirdDraw


class BirdDraw:
	extends Node2D
	var layer: FlavorLayer
	func _draw() -> void:
		layer._draw_birds(self)


func setup(c: CityMap) -> void:
	city = c
	_bird_node = BirdDraw.new()
	_bird_node.layer = self
	_bird_node.z_index = 5
	add_child(_bird_node)
	_rng.seed = hash(c.id + "_birds")
	var f := CityEvents.flavor(c)
	for b in f.get("bridges", []):
		_bridges.append([c.project(b["a"][0], b["a"][1]) * PX, c.project(b["b"][0], b["b"][1]) * PX, b["name_key"]])
	for d in f.get("decor", []):
		_decor.append({"kind": d["kind"], "pos": c.project(d["lon"], d["lat"]) * PX, "name_key": d["name_key"]})
	# sample open-water points for the gulls to roam between (near the coast is nicer)
	var tries := 0
	while _water_pts.size() < 60 and tries < 4000:
		tries += 1
		var p := Vector2(_rng.randf() * c.size_km.x, _rng.randf() * c.size_km.y)
		if not c.is_sea(p):
			continue
		var near_land := false
		for k in 8:
			if not c.is_sea(p + Vector2.from_angle(TAU * k / 8.0) * 1.8):
				near_land = true
				break
		if near_land or _rng.randf() < 0.1:
			_water_pts.append(p * PX)
	for spec in f.get("birds", []):
		for i in int(spec["count"]):
			var bird := {"kind": spec["kind"], "phase": _rng.randf() * TAU}
			if spec["kind"] == "flamingo":
				var home: Vector2 = c.project(spec["lon"], spec["lat"]) * PX
				bird["home"] = home
				bird["r"] = float(spec.get("r", 1.0)) * PX
				bird["pos"] = home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * bird["r"]
				bird["vel"] = Vector2.ZERO
				bird["target"] = bird["pos"]
			elif not _water_pts.is_empty():
				# gulls fly in small groups around a shared target
				var start: Vector2 = _water_pts[_rng.randi() % _water_pts.size()]
				bird["pos"] = start + Vector2(_rng.randf_range(-300, 300), _rng.randf_range(-300, 300))
				bird["vel"] = Vector2.from_angle(_rng.randf() * TAU) * 120.0
				bird["target"] = _water_pts[_rng.randi() % _water_pts.size()]
			else:
				continue
			_birds.append(bird)
	queue_redraw()


var detail := true


func set_detail(on: bool) -> void:
	detail = on
	_bird_node.visible = on


func set_zoom(z: float) -> void:
	if absf(z - zoom) / maxf(zoom, 0.001) > 0.02:
		queue_redraw()
	zoom = z


func _process(delta: float) -> void:
	_t += delta
	for b in _birds:
		if b["kind"] == "flamingo":
			# slow wading
			if (b["pos"] as Vector2).distance_to(b["target"]) < 8.0:
				b["target"] = b["home"] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * b["r"]
			b["pos"] = (b["pos"] as Vector2).move_toward(b["target"], delta * 14.0)
			continue
		var to: Vector2 = b["target"] - b["pos"]
		if to.length() < 250.0:
			b["target"] = _water_pts[_rng.randi() % _water_pts.size()]
		var desired := to.normalized() * 260.0
		var vel: Vector2 = b["vel"]
		vel = vel.lerp(desired, clampf(delta * 0.6, 0.0, 1.0))
		# gentle circling
		vel = vel.rotated(sin(_t * 0.7 + b["phase"]) * delta * 0.9)
		b["vel"] = vel
		b["pos"] = b["pos"] + vel * delta
	_bird_node.queue_redraw()
	if Engine.get_frames_drawn() % 30 == 0:
		queue_redraw()


func _draw() -> void:
	if city == null:
		return
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	# bridges (under the network, over the water)
	for br in _bridges:
		var a: Vector2 = br[0]
		var b: Vector2 = br[1]
		var w := maxf(14.0, 5.0 * inv)
		draw_line(a, b, Color(0.32, 0.34, 0.4, 0.95), w + 6.0 * inv, true)
		draw_line(a, b, Color(0.86, 0.86, 0.88), w, true)
		# pylons
		for t in [0.3, 0.7]:
			var p := a.lerp(b, t)
			draw_circle(p, w * 0.75, Color(0.5, 0.2, 0.15))
		if zoom > 0.2:
			_label((a + b) * 0.5 + Vector2(0, -22) * inv, I18n.t(br[2]), inv, Color(0.25, 0.28, 0.35))
	# landmarks
	for d in _decor:
		var p: Vector2 = d["pos"]
		draw_set_transform(p, 0.0, Vector2(inv, inv))
		match d["kind"]:
			"islet_tower":
				draw_circle(Vector2(0, 6), 16.0, Palette.LAND)
				draw_circle(Vector2(0, 6), 16.0, Palette.SHORE, false, 2.5)
				_tower(Color("f1f1f1"), Color("b23a3a"))
			"tower":
				_tower(Color("e9e2d0"), Color("6b7b8c"))
			"fortress":
				draw_rect(Rect2(-16, -10, 32, 18), Color("b8a98c"))
				for x in [-16, -6, 4]:
					draw_rect(Rect2(x, -16, 6, 6), Color("b8a98c"))
				draw_rect(Rect2(-16, -10, 32, 18), Color("7a6b55"), false, 2.0)
		if zoom > 0.16:
			var txt := I18n.t(d["name_key"])
			var f := ThemeBuilder.font(800)
			var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
			draw_string_outline(f, Vector2(-sz.x * 0.5, 40), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color(Palette.LAND, 0.9))
			draw_string(f, Vector2(-sz.x * 0.5, 40), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("5a4a3a"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_birds(ci: Node2D) -> void:
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	if zoom < 0.07:
		return
	for b in _birds:
		var p: Vector2 = b["pos"]
		ci.draw_set_transform(p, 0.0, Vector2(inv, inv))
		if b["kind"] == "flamingo":
			var bob := sin(_t * 2.0 + b["phase"]) * 1.5
			ci.draw_line(Vector2(0, 4), Vector2(0, 14), Color("d16b86"), 1.5)
			ci.draw_circle(Vector2(0, bob), 5.5, Color("f28cae"))
			ci.draw_line(Vector2(2, bob - 2), Vector2(5, bob - 10), Color("f28cae"), 2.0)
			ci.draw_circle(Vector2(5, bob - 11), 2.2, Color("f28cae"))
		else:
			var flap := sin(_t * 9.0 + b["phase"]) * 5.0
			var dir: Vector2 = (b["vel"] as Vector2).normalized()
			var side := Vector2(-dir.y, dir.x)
			var shadow := Vector2(6, 9)
			ci.draw_polyline(PackedVector2Array([side * 9 + Vector2(0, flap) + shadow, shadow, -side * 9 + Vector2(0, flap) + shadow]), Color(0, 0, 0, 0.12), 2.5, true)
			ci.draw_polyline(PackedVector2Array([side * 9 + Vector2(0, flap), Vector2.ZERO, -side * 9 + Vector2(0, flap)]), Color(1, 1, 1, 0.95), 3.0, true)
			ci.draw_polyline(PackedVector2Array([side * 9 + Vector2(0, flap), Vector2.ZERO, -side * 9 + Vector2(0, flap)]), Color(0.35, 0.38, 0.45, 0.9), 1.2, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _tower(body: Color, roof: Color) -> void:
	draw_rect(Rect2(-6, -20, 12, 26), body)
	draw_rect(Rect2(-6, -20, 12, 26), Color(0, 0, 0, 0.3), false, 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -20), Vector2(0, -34), Vector2(8, -20)]), roof)


func _label(pos: Vector2, txt: String, inv: float, col: Color) -> void:
	var f := ThemeBuilder.font(800)
	draw_set_transform(pos, 0.0, Vector2(inv, inv))
	var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	draw_string_outline(f, Vector2(-sz.x * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 6, Color(Palette.WATER, 0.9))
	draw_string(f, Vector2(-sz.x * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Fraction of birds currently inside a world rect (used to trigger gull calls).
func birds_in(rect: Rect2) -> int:
	var n := 0
	for b in _birds:
		if b["kind"] == "gull" and rect.has_point(b["pos"]):
			n += 1
	return n
