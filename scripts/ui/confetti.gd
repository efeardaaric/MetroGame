class_name Confetti
extends Control
## Celebration burst in the line colours (line openings, scenario wins).

var _parts: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func burst(count: int = 90) -> void:
	if Settings.reduce_motion:
		return
	var vs := get_viewport_rect().size
	for i in count:
		_parts.append({
			"p": Vector2(vs.x * 0.5 + _rng.randf_range(-60, 60), vs.y * 0.42),
			"v": Vector2.from_angle(_rng.randf_range(-PI * 0.95, -PI * 0.05)) * _rng.randf_range(400, 1100),
			"r": _rng.randf() * TAU, "w": _rng.randf_range(-8, 8),
			"c": Palette.STRIPES[_rng.randi() % Palette.STRIPES.size()] if _rng.randf() < 0.85 else Palette.CREAM,
			"s": Vector2(_rng.randf_range(10, 18), _rng.randf_range(5, 9)), "life": _rng.randf_range(1.6, 2.6),
		})


func _process(delta: float) -> void:
	if _parts.is_empty():
		return
	for p in _parts:
		p["v"].y += 1300.0 * delta
		p["v"] *= 0.985
		p["p"] += p["v"] * delta
		p["r"] += p["w"] * delta
		p["life"] -= delta
	_parts = _parts.filter(func(p): return p["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		draw_set_transform(p["p"], p["r"], Vector2(1.0, absf(cos(p["r"] * 1.7)) + 0.15))
		var c: Color = p["c"]
		c.a = clampf(p["life"], 0.0, 1.0)
		draw_rect(Rect2(-p["s"] * 0.5, p["s"]), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
