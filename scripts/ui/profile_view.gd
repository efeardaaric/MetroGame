class_name ProfileView
extends Control
## Longitudinal section ("boy kesit") of a line: terrain, sea, and the track.

var state: GameState
var line: Dictionary
var _ground := PackedFloat32Array()
var _track := PackedFloat32Array()
var _dist := PackedFloat32Array()
var _station_d: Array = []
var _station_names: Array = []
var _emin := 0.0
var _emax := 100.0
var _anim := 0.0


func setup(s: GameState, l: Dictionary) -> void:
	state = s
	line = l
	_compute()


func _ready() -> void:
	custom_minimum_size.y = 420
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "_anim", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _process(_d: float) -> void:
	if _anim < 1.0:
		queue_redraw()


func _compute() -> void:
	var path := state.net.line_path(line)
	var m := TransitModes.get_mode(line["mode"])
	var depth := TransitModes.DEEP_TUNNEL_DEPTH if line.get("deep", false) else TransitModes.SHALLOW_TUNNEL_DEPTH
	var acc := 0.0
	_station_d.clear()
	_station_names.clear()
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var seg := a.distance_to(b)
		_station_d.append(acc)
		var sid_idx: int = i % line["stations"].size()
		_station_names.append(state.net.station_display_name(line["stations"][sid_idx]))
		var steps := maxi(4, int(seg / 0.1))
		for k in steps:
			var t := float(k) / steps
			var p := a.lerp(b, t)
			var g := state.city.elevation(p)
			_ground.append(g)
			_dist.append(acc + seg * t)
			var tr: float
			if m["underground"]:
				var surface := maxf(g, 0.0)
				tr = (g if g < 0.0 else surface) - depth
				if g < 0.0:
					tr = g - depth * 0.8
			elif line["mode"] == "ferry":
				tr = 0.0
			else:
				tr = maxf(g, 0.0) + (12.0 if g < 0.0 else 0.0)
			_track.append(tr)
		acc += seg
	_station_d.append(acc)
	if not line.get("loop", false):
		_station_names.append(state.net.station_display_name(line["stations"][line["stations"].size() - 1]))
	else:
		_station_names.append(_station_names[0])
	_ground.append(state.city.elevation(path[path.size() - 1]))
	_track.append(_track[_track.size() - 1])
	_dist.append(acc)
	# smooth the track a little
	for _it in 3:
		for i in range(1, _track.size() - 1):
			_track[i] = (_track[i - 1] + _track[i] * 2.0 + _track[i + 1]) * 0.25
	_emin = 0.0
	_emax = 10.0
	for i in _ground.size():
		_emin = minf(_emin, minf(_ground[i], _track[i]))
		_emax = maxf(_emax, maxf(_ground[i], _track[i]))
	_emin -= 15.0
	_emax += 25.0


func _draw() -> void:
	if _dist.is_empty():
		return
	var f := ThemeBuilder.font(750)
	var left := 64.0
	var right := 16.0
	var top := 50.0
	var bottom := 70.0
	var w := size.x - left - right
	var h := size.y - top - bottom
	var total := _dist[_dist.size() - 1]
	var X := func(d: float) -> float: return left + d / maxf(total, 0.001) * w
	var Y := func(e: float) -> float: return top + (1.0 - (e - _emin) / (_emax - _emin)) * h
	var sky := StyleBoxFlat.new()
	sky.bg_color = Color("1c2a40")
	sky.set_corner_radius_all(18)
	draw_style_box(sky, Rect2(left, top, w, h))
	var n := int(_dist.size() * _anim)
	n = clampi(n, 2, _dist.size())
	# sea
	var sea_y: float = Y.call(0.0)
	for i in n - 1:
		if _ground[i] < 0.0:
			var x0: float = X.call(_dist[i])
			var x1: float = X.call(_dist[i + 1])
			draw_rect(Rect2(x0, sea_y, x1 - x0 + 1, Y.call(_ground[i]) - sea_y), Color(Palette.WATER, 0.75))
	# ground body
	var poly := PackedVector2Array()
	for i in n:
		poly.append(Vector2(X.call(_dist[i]), Y.call(_ground[i])))
	poly.append(Vector2(X.call(_dist[n - 1]), top + h))
	poly.append(Vector2(left, top + h))
	draw_colored_polygon(poly, Color("8d6e4f"))
	var edge := poly.slice(0, n)
	draw_polyline(edge, Color("b9a07a"), 4.0, true)
	# track
	var col := state.net.line_color(line)
	var tpts := PackedVector2Array()
	for i in n:
		tpts.append(Vector2(X.call(_dist[i]), Y.call(_track[i])))
	if TransitModes.get_mode(line["mode"])["underground"]:
		draw_polyline(tpts, Color(0.06, 0.06, 0.08, 0.6), 18.0, true)
	draw_polyline(tpts, col, 9.0, true)
	# stations
	for i in _station_d.size():
		var d: float = _station_d[i]
		if d > _dist[n - 1] + 0.001:
			break
		var idx := 0
		while idx < _dist.size() - 1 and _dist[idx] < d:
			idx += 1
		var p := Vector2(X.call(d), Y.call(_track[idx]))
		draw_circle(p, 11.0, Color.WHITE)
		draw_circle(p, 6.0, col)
		var gy: float = Y.call(maxf(_ground[idx], 0.0))
		draw_line(Vector2(p.x, gy), Vector2(p.x, p.y), Color(1, 1, 1, 0.35), 2.0)
		var name: String = _station_names[i]
		if name.length() > 12:
			name = name.substr(0, 11) + "…"
		draw_set_transform(Vector2(p.x, top + h + 14), 0.6, Vector2.ONE)
		draw_string(f, Vector2(0, 0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.MUTED)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# axis labels
	for e in [_emin + 15.0, 0.0, _emax - 25.0]:
		var y: float = Y.call(e)
		draw_line(Vector2(left - 6, y), Vector2(left, y), Palette.FAINT, 2.0)
		draw_string(f, Vector2(0, y + 6), "%dm" % int(e), HORIZONTAL_ALIGNMENT_LEFT, left - 8, 17, Palette.FAINT)
	draw_string(f, Vector2(left, top - 14), "%.1f km" % total, HORIZONTAL_ALIGNMENT_RIGHT, w, 20, Palette.MUTED)
