class_name TimelapseView
extends Control
## Replays the growth of the player's network ("Zaman Tüneli") over a city silhouette.

signal finished

var state: GameState
var _city: CityMap
var _t := 0.0                 # playback position in log entries (float)
var _speed := 2.2             # entries per second
var _lines := {}              # lid -> {pts, color, mode, grow}
var _idx := 0
var _date := ""
var _playing := true


func setup(s: GameState) -> void:
	state = s
	_city = s.city


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if not state.build_log.is_empty():
		_speed = clampf(state.build_log.size() / 8.0, 1.2, 6.0)


func restart() -> void:
	_t = 0.0
	_idx = 0
	_lines.clear()
	_playing = true


func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta * _speed
	while _idx < state.build_log.size() and _idx < int(_t):
		var e: Dictionary = state.build_log[_idx]
		_date = "%s %d" % [I18n.month_name(int(e["m"])), int(e["y"])]
		if e["op"] == "del":
			_lines.erase(int(e["lid"]))
		else:
			var pts := PackedVector2Array()
			for p in e["pts"]:
				pts.append(Vector2(p[0], p[1]))
			var prev_len := 0.0
			if _lines.has(int(e["lid"])):
				prev_len = Geo.polyline_length(_lines[int(e["lid"])]["pts"])
			_lines[int(e["lid"])] = {"pts": pts, "color": TransitModes.LINE_COLORS[int(e["color"]) % TransitModes.LINE_COLORS.size()],
				"mode": e["mode"], "grow": 0.0, "from": prev_len}
			Audio.play("place", 0.9 + randf() * 0.3, -8.0)
		_idx += 1
	for l in _lines.values():
		l["grow"] = minf(1.0, l["grow"] + delta * 1.6)
	if _idx >= state.build_log.size() and _t > state.build_log.size() + 2.0:
		_playing = false
		finished.emit()
	queue_redraw()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.LAND
	sb.set_corner_radius_all(24)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var sz := _city.size_km
	# fit network bounds (or whole city) into the view
	var bounds := Rect2(Vector2.ZERO, sz)
	var any := false
	for e in state.build_log:
		if e["op"] == "set":
			for p in e["pts"]:
				var v := Vector2(p[0], p[1])
				if not any:
					bounds = Rect2(v, Vector2.ZERO)
					any = true
				else:
					bounds = bounds.expand(v)
	bounds = bounds.grow(maxf(3.0, maxf(bounds.size.x, bounds.size.y) * 0.12))
	var sc := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var off := (size - bounds.size * sc) * 0.5 - bounds.position * sc
	var xf := func(p: Vector2) -> Vector2: return off + p * sc
	for wp in _city.water_polys + _city.river_polys:
		var poly := PackedVector2Array()
		for p in wp:
			poly.append(xf.call(p))
		var idx := Geometry2D.triangulate_polygon(poly)
		if idx.size() >= 3:
			var cols := PackedColorArray()
			cols.resize(poly.size())
			cols.fill(Palette.WATER)
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, poly, cols)
	for isl in _city.island_polys:
		var poly := PackedVector2Array()
		for p in isl:
			poly.append(xf.call(p))
		draw_colored_polygon(poly, Palette.LAND)
	var lw := clampf(sc * 0.35, 4.0, 12.0)
	for l in _lines.values():
		var pts: PackedVector2Array = PackedVector2Array()
		for p in l["pts"]:
			pts.append(xf.call(p))
		var cum := Geo.cumulative(pts)
		var total := cum[cum.size() - 1]
		var from: float = l["from"] * sc
		var show := lerpf(minf(from, total), total, l["grow"])
		var vis := PackedVector2Array()
		for i in pts.size():
			if cum[i] <= show:
				vis.append(pts[i])
			else:
				vis.append(Geo.sample_polyline(pts, cum, show)[0])
				break
		if vis.size() >= 2:
			if l["mode"] == "ferry":
				draw_polyline(vis, Color(l["color"], 0.8), lw * 0.6, true)
			else:
				draw_polyline(vis, Color(1, 1, 1, 0.9), lw + 3.0, true)
				draw_polyline(vis, l["color"], lw, true)
		for p in vis:
			draw_circle(p, lw * 0.55, Color.WHITE)
	var f := ThemeBuilder.font(950)
	draw_string(f, Vector2(24, 58), _date, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(0.12, 0.14, 0.2, 0.85))
	draw_string(ThemeBuilder.font(800), Vector2(24, 92), "%d %s" % [_lines.size(), I18n.t("lines_count").to_lower()], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.12, 0.14, 0.2, 0.6))
	if state.build_log.is_empty():
		draw_string(f, Vector2(0, size.y * 0.5), I18n.t("timelapse_empty"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color(0.2, 0.2, 0.25))
