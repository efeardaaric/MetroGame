class_name WeatherOverlay
extends Control
## Screen-space weather: snow (Ankara/Bursa winters), rain streaks, morning fog.

var snow := 0.0
var rain := 0.0
var fog := 0.0
var _flakes: Array = []
var _drops: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 240:
		_flakes.append(_new_particle(true))
	for i in 200:
		_drops.append(_new_particle(true))


func _new_particle(anywhere: bool) -> Dictionary:
	var vs := get_viewport_rect().size if is_inside_tree() else Vector2(720, 1280)
	return {
		"p": Vector2(_rng.randf() * vs.x * 1.2, _rng.randf() * vs.y if anywhere else -10.0),
		"s": _rng.randf_range(40.0, 120.0),
		"r": _rng.randf_range(1.5, 4.5),
		"ph": _rng.randf() * TAU,
		"v": _rng.randf_range(900.0, 1400.0),
	}


func set_levels(s: float, r: float, f: float, dt: float) -> void:
	var k := clampf(dt * 0.8, 0.0, 1.0)
	snow = lerpf(snow, s, k)
	rain = lerpf(rain, r, k)
	fog = lerpf(fog, f, k)


func _process(delta: float) -> void:
	if snow <= 0.01 and rain <= 0.01 and fog <= 0.01:
		visible = false
		return
	visible = true
	var vs := get_viewport_rect().size
	if snow > 0.01:
		for f in _flakes:
			f["ph"] += delta
			f["p"] += Vector2(sin(f["ph"]) * 18.0, f["s"]) * delta
			if f["p"].y > vs.y + 10.0:
				f["p"] = _new_particle(false)["p"]
	if rain > 0.01:
		for d in _drops:
			d["p"] += Vector2(-0.25, 1.0) * d["v"] * delta
			if d["p"].y > vs.y + 20.0:
				d["p"] = Vector2(_rng.randf() * vs.x * 1.3, -20.0)
	queue_redraw()


func _draw() -> void:
	if fog > 0.01:
		var top := Color(0.93, 0.94, 0.96, 0.0)
		var mid := Color(0.93, 0.94, 0.96, 0.55 * fog)
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)])
		draw_polygon(pts, PackedColorArray([mid, top, mid, mid]))
	if rain > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.42, 0.55, 0.12 * rain))
		var n := int(_drops.size() * rain)
		for i in n:
			var d: Dictionary = _drops[i]
			draw_line(d["p"], d["p"] + Vector2(-0.25, 1.0) * 22.0, Color(0.85, 0.9, 1.0, 0.45), 1.6, true)
	if snow > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.78, 0.86, 1.0, 0.16 * snow))
		var m := int(_flakes.size() * snow)
		for i in m:
			var f: Dictionary = _flakes[i]
			draw_circle(f["p"] + Vector2(1.5, 2.0), f["r"] + 0.8, Color(0.35, 0.45, 0.6, 0.35))
			draw_circle(f["p"], f["r"], Color(1, 1, 1, 0.95))
