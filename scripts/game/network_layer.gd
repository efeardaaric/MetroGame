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
var station_d := {}   # lid -> Array of distances along the rounded path for each station
var diagram := false  # schematic "metro map" mode (octilinear, snapped)
var _snap := {}       # sid -> snapped position (px) in diagram mode
var _pulse := 0.0
const DIAGRAM_GRID := 55.0


## Station position in world px (snapped to the schematic grid in diagram mode).
func spos(sid: int) -> Vector2:
	if diagram and _snap.has(sid):
		return _snap[sid]
	return net.stations[sid]["pos"] * PX


func set_diagram(on: bool) -> void:
	diagram = on
	rebuild()


func _build_snap() -> void:
	_snap.clear()
	var used := {}
	var g := DIAGRAM_GRID
	var ids := net.stations.keys()
	ids.sort()
	for sid in ids:
		var p: Vector2 = net.stations[sid]["pos"] * PX
		var q := Vector2(roundf(p.x / g) * g, roundf(p.y / g) * g)
		var tries := 0
		while used.has(q) and tries < 8:
			q += Vector2(g, 0) if tries % 2 == 0 else Vector2(0, g)
			tries += 1
		used[q] = true
		_snap[sid] = q


## Octilinear routing between two points: a straight run then a 45° diagonal.
static func octi(a: Vector2, b: Vector2) -> Vector2:
	var d := b - a
	var ax := absf(d.x)
	var ay := absf(d.y)
	if ax > ay:
		return a + Vector2(signf(d.x) * (ax - ay), 0)
	return a + Vector2(0, signf(d.y) * (ay - ax))


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
	station_d.clear()
	if net == null:
		return
	if diagram:
		_build_snap()
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
			var dir: Vector2 = (spos(hi) - spos(lo)).normalized()
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
			pts.append(spos(st[i]) + off)
		if loop:
			pts.append(pts[0])
		var station_idx: Array = []
		if diagram:
			var dp := PackedVector2Array()
			for i in pts.size():
				if i > 0:
					var bend := octi(pts[i - 1], pts[i])
					if bend.distance_to(pts[i - 1]) > 1.0 and bend.distance_to(pts[i]) > 1.0:
						dp.append(bend)
				station_idx.append(dp.size())
				dp.append(pts[i])
			pts = dp
		else:
			for i in pts.size():
				station_idx.append(i)
		raw_paths[l["id"]] = pts
		var rp := Geo.rounded_path(pts, screen_w(18.0 if diagram else 26.0), 6)
		paths[l["id"]] = rp
		cums[l["id"]] = Geo.cumulative(rp)
		# station distances along the rounded path (scaled from the raw path)
		var raw_cum := Geo.cumulative(pts)
		var rtot := maxf(0.001, raw_cum[raw_cum.size() - 1])
		var ctot: float = cums[l["id"]][cums[l["id"]].size() - 1]
		var sd: Array = []
		for i in n:
			sd.append(raw_cum[station_idx[i]] / rtot * ctot)
		station_d[l["id"]] = sd
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
		var pos: Vector2 = spos(sid)
		var nl: int = s["lines"].size()
		var skipped := _skipped_everywhere(sid)
		var on_sel: bool = not any_sel or s["lines"].has(selected_line)
		var alpha := 1.0 if on_sel else 0.35
		if demand and demand.station_boardings.has(sid) and zoom > 0.12:
			_draw_crowd(pos, demand.station_boardings[sid], alpha)
		var is_hub: bool = nl > 1 or s.get("hub", 0) > 0
		if skipped:
			draw_circle(pos, r * 0.75, Color(Palette.STATION_STROKE, 0.5 * alpha))
			draw_circle(pos, r * 0.45, Color(1, 1, 1, alpha))
		elif is_hub:
			var rr := r * 1.45
			draw_circle(pos, rr + screen_w(2.5), Color(Palette.STATION_STROKE, alpha))
			draw_circle(pos, rr, Color(1, 1, 1, alpha))
			draw_circle(pos, rr * 0.38, Color(Palette.STATION_STROKE, alpha))
			if s.get("hub", 0) > 0:
				draw_arc(pos, rr + screen_w(6.0), 0, TAU, 28, Color(Palette.ACCENT, alpha), screen_w(3.0), true)
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
				var pos: Vector2 = spos(sid)
				var pr := r * (2.0 + 0.35 * sin(_pulse * 4.0))
				draw_arc(pos, pr, 0, TAU, 28, Color(net.line_color(l), 0.9), screen_w(3.5), true)
	# station names when zoomed in
	if zoom >= 0.22 and show_names:
		var f := ThemeBuilder.font(800)
		var inv := 1.0 / zoom
		for s in net.stations.values():
			var on_sel: bool = not any_sel or s["lines"].has(selected_line)
			var txt := net.station_display_name(s["id"])
			var pos: Vector2 = spos(s["id"])
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
	if l.has("con"):
		_draw_construction(lid, l, c, m, dimmed)
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
		"gondola":
			draw_polyline(p, Color(0.2, 0.22, 0.28, c.a), screen_w(2.5), true)
			_draw_dots(lid, c, w * 0.75, screen_w(16.0))
		_:
			draw_polyline(p, c, w, true)
	if l.get("express", false) and net.can_express(l):
		_draw_chevrons(lid, Color(1, 1, 1, 0.95 * c.a), w)
	if Settings.colorblind:
		_draw_pattern(lid, int(l["color"]), w, c.a)


## Sub-polyline of a line's path between two distances.
func _subpath(lid: int, d0: float, d1: float) -> PackedVector2Array:
	var p: PackedVector2Array = paths[lid]
	var cum: PackedFloat32Array = cums[lid]
	var out := PackedVector2Array()
	out.append(Geo.sample_polyline(p, cum, d0)[0])
	for i in p.size():
		if cum[i] > d0 and cum[i] < d1:
			out.append(p[i])
	out.append(Geo.sample_polyline(p, cum, d1)[0])
	return out


func _draw_construction(lid: int, l: Dictionary, c: Color, m: Dictionary, dimmed: bool) -> void:
	var w := screen_w(m["width"])
	var cum: PackedFloat32Array = cums[lid]
	var total := cum[cum.size() - 1]
	var sd: Array = station_d[lid]
	var con: Dictionary = l["con"]
	var lo: int = con["lo"]
	var hi: int = con["hi"]
	var a := 1.0 if not dimmed else 0.5
	# running part (for extensions)
	if lo >= 0:
		draw_polyline(_subpath(lid, sd[lo], sd[hi]), Color(c, a), w, true)
	# parts being built
	var spans: Array = []
	if lo < 0:
		spans.append(Vector2(0, total))
	else:
		if lo > 0:
			spans.append(Vector2(0, sd[lo]))
		if hi < sd.size() - 1:
			spans.append(Vector2(sd[hi], total))
	for sp in spans:
		var sub := _subpath(lid, sp.x, sp.y)
		draw_polyline(sub, Color(0.62, 0.6, 0.56, 0.75 * a), w, true)
		var sc := Geo.cumulative(sub)
		var tot := sc[sc.size() - 1]
		var d := 0.0
		var dash := screen_w(7.0)
		while d < tot:
			var p0: Vector2 = Geo.sample_polyline(sub, sc, d)[0]
			var p1: Vector2 = Geo.sample_polyline(sub, sc, minf(d + dash, tot))[0]
			draw_line(p0, p1, Color(c, a), w * 0.55, true)
			d += dash * 2.2
		# crane badge with progress
		var mid: Vector2 = Geo.sample_polyline(sub, sc, tot * 0.5)[0]
		var r := screen_w(17.0)
		var prog := 1.0 - float(con["months"]) / maxf(1.0, float(con["total"]))
		draw_circle(mid, r + screen_w(2.5), Palette.INK)
		draw_circle(mid, r, Palette.ACCENT)
		draw_arc(mid, r + screen_w(1.2), -PI * 0.5, -PI * 0.5 + TAU * prog, 24, Palette.GOOD, screen_w(3.5), true)
		# simple crane glyph
		var k := r * 0.55
		draw_line(mid + Vector2(-k * 0.3, k), mid + Vector2(-k * 0.3, -k), Palette.INK, screen_w(2.5), true)
		draw_line(mid + Vector2(-k, -k), mid + Vector2(k, -k), Palette.INK, screen_w(2.5), true)
		draw_line(mid + Vector2(k * 0.7, -k), mid + Vector2(k * 0.7, -k * 0.2), Palette.INK, screen_w(1.8), true)


func _skipped_everywhere(sid: int) -> bool:
	var lines_here: Array = net.stations[sid]["lines"]
	if lines_here.is_empty():
		return false
	for lid in lines_here:
		var l: Dictionary = net.lines[lid]
		var i: int = l["stations"].find(sid)
		if not l.get("express", false) or not net.can_express(l):
			return false
		if net.stop_mask(l)[i]:
			return false
	return true


func _draw_dots(lid: int, c: Color, r: float, step: float) -> void:
	var p: PackedVector2Array = paths[lid]
	var cum: PackedFloat32Array = cums[lid]
	var total := cum[cum.size() - 1]
	var d := step * 0.5
	while d < total:
		var s: Array = Geo.sample_polyline(p, cum, d)
		draw_rect(Rect2(s[0] - Vector2(r, r * 0.8) * 0.5, Vector2(r, r * 0.8)), c)
		d += step


func _draw_chevrons(lid: int, c: Color, w: float) -> void:
	var p: PackedVector2Array = paths[lid]
	var cum: PackedFloat32Array = cums[lid]
	var total := cum[cum.size() - 1]
	var step := screen_w(70.0)
	var d := step * 0.5
	while d < total:
		var s: Array = Geo.sample_polyline(p, cum, d)
		var dir: Vector2 = s[1]
		var nrm := dir.orthogonal()
		var q: Vector2 = s[0]
		var k := w * 0.35
		for o in [-0.6, 0.6]:
			var t: Vector2 = q + dir * k * o
			draw_polyline(PackedVector2Array([t - dir * k + nrm * k, t, t - dir * k - nrm * k]), c, screen_w(1.6), true)
		d += step


## Colour-blind aid: each colour index gets its own symbol along the line.
func _draw_pattern(lid: int, cidx: int, w: float, a: float) -> void:
	var p: PackedVector2Array = paths[lid]
	var cum: PackedFloat32Array = cums[lid]
	var total := cum[cum.size() - 1]
	var step := screen_w(90.0)
	var d := step * 0.25
	var r := maxf(w * 0.36, screen_w(3.0))
	var col := Color(1, 1, 1, 0.95 * a)
	var edge := Color(0.1, 0.1, 0.15, 0.9 * a)
	while d < total:
		var q: Vector2 = Geo.sample_polyline(p, cum, d)[0]
		match cidx % 5:
			0:
				draw_circle(q, r + screen_w(1.2), edge)
				draw_circle(q, r, col)
			1:
				draw_rect(Rect2(q - Vector2(r, r), Vector2(r, r) * 2.0).grow(screen_w(1.2)), edge)
				draw_rect(Rect2(q - Vector2(r, r), Vector2(r, r) * 2.0), col)
			2:
				var tri := PackedVector2Array([q + Vector2(0, -r * 1.2), q + Vector2(r * 1.1, r * 0.8), q + Vector2(-r * 1.1, r * 0.8)])
				draw_colored_polygon(tri, col)
				tri.append(tri[0])
				draw_polyline(tri, edge, screen_w(1.2), true)
			3:
				var dia := PackedVector2Array([q + Vector2(0, -r * 1.3), q + Vector2(r * 1.1, 0), q + Vector2(0, r * 1.3), q + Vector2(-r * 1.1, 0)])
				draw_colored_polygon(dia, col)
				dia.append(dia[0])
				draw_polyline(dia, edge, screen_w(1.2), true)
			4:
				draw_line(q + Vector2(-r, -r), q + Vector2(r, r), edge, screen_w(4.0), true)
				draw_line(q + Vector2(r, -r), q + Vector2(-r, r), edge, screen_w(4.0), true)
				draw_line(q + Vector2(-r, -r), q + Vector2(r, r), col, screen_w(2.2), true)
				draw_line(q + Vector2(r, -r), q + Vector2(-r, r), col, screen_w(2.2), true)
		d += step


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
		var d: float = spos(s["id"]).distance_to(world)
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
