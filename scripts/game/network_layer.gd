class_name NetworkLayer
extends Node2D
## Draws lines (metro-map style with parallel offsets) and stations.

const PX := MapLayer.PX

var net: TransitNetwork
var demand: DemandModel
var zoom := 1.0
var selected_line := -1
var selected_station := -1
var highlight_ends_mode := "" # when building: highlight extendable ends
var show_names := true
var paths := {}       # lid -> PackedVector2Array (world px, rounded)
var raw_paths := {}   # lid -> PackedVector2Array (world px, unrounded with offsets)
var cums := {}        # lid -> PackedFloat32Array
var _pulse := 0.0


func setup(n: TransitNetwork, d: DemandModel) -> void:
	net = n
	demand = d
	net.changed.connect(rebuild)
	rebuild()


func set_zoom(z: float) -> void:
	if absf(z - zoom) / zoom > 0.03:
		zoom = z
		rebuild()


func screen_w(px: float) -> float:
	# width in world units for a given on-screen width, limited so it scales a bit with zoom
	return px / clampf(zoom, 0.05, 2.0)


func rebuild() -> void:
	paths.clear()
	raw_paths.clear()
	cums.clear()
	if net == null:
		return
	# group lines per station pair for parallel offsets
	var seg_lines := {}
	for l in net.lines.values():
		var st: Array = l["stations"]
		var n := st.size()
		var segs := n if l.get("loop", false) else n - 1
		for k in segs:
			var a: int = st[k]
			var b: int = st[(k + 1) % n]
			var key := _seg_key(a, b)
			if not seg_lines.has(key):
				seg_lines[key] = []
			seg_lines[key].append(l["id"])
	var spacing := screen_w(9.0)
	for l in net.lines.values():
		var st: Array = l["stations"]
		var n := st.size()
		if n < 2:
			continue
		var loop: bool = l.get("loop", false)
		var segs := n if loop else n - 1
		var seg_off: Array = []
		for k in segs:
			var a: int = st[k]
			var b: int = st[(k + 1) % n]
			var key := _seg_key(a, b)
			var arr: Array = seg_lines[key]
			arr.sort()
			var idx := arr.find(l["id"])
			var o := (idx - (arr.size() - 1) * 0.5) * spacing
			var lo := mini(a, b)
			var hi := maxi(a, b)
			var dir: Vector2 = (net.stations[hi]["pos"] - net.stations[lo]["pos"]).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			seg_off.append(nrm * o)
		var pts := PackedVector2Array()
		for i in n:
			var off := Vector2.ZERO
			var cnt := 0
			if i < segs:
				off += seg_off[i]
				cnt += 1
			if i > 0:
				off += seg_off[i - 1]
				cnt += 1
			elif loop:
				off += seg_off[segs - 1]
				cnt += 1
			if cnt > 0:
				off /= cnt
			pts.append(net.stations[st[i]]["pos"] * PX + off)
		if loop:
			pts.append(pts[0])
		raw_paths[l["id"]] = pts
		var rp := Geo.rounded_path(pts, screen_w(26.0), 6)
		paths[l["id"]] = rp
		cums[l["id"]] = Geo.cumulative(rp)
	queue_redraw()


func _seg_key(a: int, b: int) -> int:
	return mini(a, b) * 100000 + maxi(a, b)


func _process(delta: float) -> void:
	if selected_station >= 0 or highlight_ends_mode != "":
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	if net == null:
		return
	var any_sel := selected_line >= 0
	# casing first (dark outline) for all lines to separate overlaps
	for lid in paths.keys():
		var l: Dictionary = net.lines[lid]
		var m := TransitModes.get_mode(l["mode"])
		var w := screen_w(m["width"])
		var p: PackedVector2Array = paths[lid]
		var dimmed: bool = any_sel and lid != selected_line
		var case_c := Color(1, 1, 1, 0.25 if dimmed else 0.9)
		if l["mode"] == "ferry":
			continue
		draw_polyline(p, case_c, w + screen_w(4.0), true)
	for lid in paths.keys():
		_draw_line(lid, any_sel and lid != selected_line)
	# stations
	var r := screen_w(7.5)
	for s in net.stations.values():
		var sid: int = s["id"]
		var pos: Vector2 = s["pos"] * PX
		var nl: int = s["lines"].size()
		var on_sel: bool = not any_sel or s["lines"].has(selected_line)
		var alpha := 1.0 if on_sel else 0.35
		if demand and demand.station_boardings.has(sid) and zoom > 0.12:
			_draw_crowd(pos, demand.station_boardings[sid], alpha)
		var is_hub := nl > 1
		if is_hub:
			var rr := r * 1.45
			draw_circle(pos, rr + screen_w(2.5), Color(Palette.STATION_STROKE, alpha))
			draw_circle(pos, rr, Color(1, 1, 1, alpha))
			draw_circle(pos, rr * 0.38, Color(Palette.STATION_STROKE, alpha))
		else:
			var col := Palette.STATION_STROKE
			if nl == 1 and net.lines.has(s["lines"][0]):
				col = net.line_color(net.lines[s["lines"][0]])
			draw_circle(pos, r + screen_w(2.5), Color(col, alpha))
			draw_circle(pos, r, Color(1, 1, 1, alpha))
		if sid == selected_station:
			var pr := r * (2.2 + 0.4 * sin(_pulse * 5.0))
			draw_arc(pos, pr, 0, TAU, 32, Palette.ACCENT, screen_w(3.0), true)
	# extendable line ends while building
	if highlight_ends_mode != "":
		for l in net.lines.values():
			if l["mode"] != highlight_ends_mode or l.get("loop", false):
				continue
			var st: Array = l["stations"]
			for sid in [st[0], st[st.size() - 1]]:
				var pos: Vector2 = net.stations[sid]["pos"] * PX
				var pr := r * (2.0 + 0.35 * sin(_pulse * 4.0))
				draw_arc(pos, pr, 0, TAU, 28, Color(net.line_color(l), 0.9), screen_w(3.5), true)
	# station names when zoomed in
	if zoom >= 0.22 and show_names:
		var f := ThemeBuilder.font(800)
		var inv := 1.0 / zoom
		for s in net.stations.values():
			var on_sel: bool = not any_sel or s["lines"].has(selected_line)
			var txt := net.station_display_name(s["id"])
			var pos: Vector2 = s["pos"] * PX
			draw_set_transform(pos, 0.0, Vector2(inv, inv))
			var a := 1.0 if on_sel else 0.35
			draw_string_outline(f, Vector2(18, -14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, 7, Color(1, 1, 1, 0.92 * a))
			draw_string(f, Vector2(18, -14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.12, 0.14, 0.2, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_line(lid: int, dimmed: bool) -> void:
	var l: Dictionary = net.lines[lid]
	var m := TransitModes.get_mode(l["mode"])
	var c := net.line_color(l)
	if l.has("incident"):
		_draw_incident(lid, l, c, m)
		return
	if dimmed:
		c = c.lerp(Color(0.8, 0.8, 0.8), 0.6)
		c.a = 0.55
	var w := screen_w(m["width"])
	var p: PackedVector2Array = paths[lid]
	match l["mode"]:
		"metro":
			draw_polyline(p, c, w, true)
			if l.get("deep", false):
				_draw_dashes(lid, Color(1, 1, 1, 0.55 * c.a), w * 0.18, screen_w(10.0), screen_w(10.0))
		"tram":
			draw_polyline(p, c, w, true)
			draw_polyline(p, Color(1, 1, 1, 0.45 * c.a), w * 0.3, true)
		"metrobus":
			draw_polyline(p, c, w, true)
			_draw_dashes(lid, Color(1, 1, 1, 0.9 * c.a), w * 0.22, screen_w(8.0), screen_w(8.0))
		"rail":
			draw_polyline(p, Color(0.15, 0.15, 0.2, c.a), w, true)
			draw_polyline(p, c, w * 0.62, true)
			_draw_dashes(lid, Color(1, 1, 1, 0.85 * c.a), w * 0.3, screen_w(12.0), screen_w(12.0))
		"funicular":
			draw_polyline(p, c, w, true)
			_draw_dashes(lid, Color(1, 1, 1, c.a), w * 0.5, screen_w(4.0), screen_w(7.0))
		"ferry":
			_draw_dashes(lid, c, w, screen_w(14.0), screen_w(9.0))
		_:
			draw_polyline(p, c, w, true)


func _draw_incident(lid: int, l: Dictionary, c: Color, m: Dictionary) -> void:
	var p: PackedVector2Array = paths[lid]
	var w := screen_w(m["width"])
	var closed: bool = float(l["incident"]["cap"]) <= 0.0
	var base := c.lerp(Color(0.55, 0.55, 0.58), 0.75 if closed else 0.35)
	draw_polyline(p, base, w, true)
	_draw_dashes(lid, Palette.BAD if closed else Palette.WARN, w * 0.45, screen_w(10.0), screen_w(10.0))
	# warning badge at the middle of the line
	var cum: PackedFloat32Array = cums[lid]
	var mid: Array = Geo.sample_polyline(p, cum, cum[cum.size() - 1] * 0.5)
	var r := screen_w(15.0)
	var pos: Vector2 = mid[0]
	draw_circle(pos, r + screen_w(2.5), Color.WHITE)
	draw_circle(pos, r, Palette.BAD if closed else Palette.WARN)
	draw_line(pos + Vector2(0, -r * 0.5), pos + Vector2(0, r * 0.15), Color.WHITE, screen_w(3.5), true)
	draw_circle(pos + Vector2(0, r * 0.5), screen_w(2.2), Color.WHITE)


func _draw_dashes(lid: int, c: Color, w: float, dash: float, gap: float) -> void:
	var p: PackedVector2Array = paths[lid]
	var cum: PackedFloat32Array = cums[lid]
	var total := cum[cum.size() - 1]
	var d := gap * 0.5
	while d < total:
		var a: Array = Geo.sample_polyline(p, cum, d)
		var b: Array = Geo.sample_polyline(p, cum, minf(d + dash, total))
		draw_line(a[0], b[0], c, w, true)
		d += dash + gap


func _draw_crowd(pos: Vector2, boardings: float, alpha: float) -> void:
	var n := clampi(int(boardings / 6000.0), 0, 10)
	if n <= 0:
		return
	var r := screen_w(17.0)
	var dot := screen_w(3.0)
	for i in n:
		var a := -PI * 0.5 + (i - (n - 1) * 0.5) * 0.42
		draw_circle(pos + Vector2(cos(a), sin(a)) * r, dot, Color(0.25, 0.27, 0.33, 0.8 * alpha))


## Hit testing in world px.
func pick_station(world: Vector2, radius_px: float) -> int:
	var best := -1
	var bd := radius_px
	for s in net.stations.values():
		var d: float = (s["pos"] * PX).distance_to(world)
		if d < bd:
			bd = d
			best = s["id"]
	return best


func pick_line(world: Vector2, radius_px: float) -> int:
	var best := -1
	var bd := radius_px
	for lid in raw_paths.keys():
		var p: PackedVector2Array = raw_paths[lid]
		for i in p.size() - 1:
			var d := Geo.dist_to_segment(world, p[i], p[i + 1])
			if d < bd:
				bd = d
				best = lid
	return best
