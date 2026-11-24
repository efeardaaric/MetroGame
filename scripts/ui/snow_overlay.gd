class_name SnowOverlay
extends Control
## Screen-space falling snow (Ankara winter / snow storms).

var intensity := 0.0:
	set(v):
		intensity = clampf(v, 0.0, 1.0)
var _flakes: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 240:
		_flakes.append(_new_flake(true))


func _new_flake(anywhere: bool) -> Dictionary:
	var vs := get_viewport_rect().size if is_inside_tree() else Vector2(720, 1280)
	return {
		"p": Vector2(_rng.randf() * vs.x, _rng.randf() * vs.y if anywhere else -10.0),
		"s": _rng.randf_range(40.0, 120.0),
		"r": _rng.randf_range(1.5, 4.5),
		"ph": _rng.randf() * TAU,
	}


func _process(delta: float) -> void:
	if intensity <= 0.01:
		if visible:
			visible = false
		return
	visible = true
	var vs := get_viewport_rect().size
	for f in _flakes:
		f["ph"] += delta
		f["p"] += Vector2(sin(f["ph"]) * 18.0, f["s"]) * delta
		if f["p"].y > vs.y + 10.0:
			var nf := _new_flake(false)
			f["p"] = nf["p"]
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.78, 0.86, 1.0, 0.16 * intensity))
	var n := int(_flakes.size() * intensity)
	for i in n:
		var f: Dictionary = _flakes[i]
		draw_circle(f["p"] + Vector2(1.5, 2.0), f["r"] + 0.8, Color(0.35, 0.45, 0.6, 0.35))
		draw_circle(f["p"], f["r"], Color(1, 1, 1, 0.95))
