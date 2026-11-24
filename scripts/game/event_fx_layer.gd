class_name EventFxLayer
extends Node2D
## Makes city events visible on the map:
##   - road traffic: little cars flowing along the arterial roads, turning into red,
##     crawling jams around a derby stadium, a closed bridge, a summit venue…
##     and almost empty streets during the pandemic lockdowns;
##   - event venues: pulsing service-radius rings for announced events (green when a
##     station already serves them), crowds streaming in, fireworks at celebrations.

const PX := MapLayer.PX
const CAR_COLORS := [Color("4a5568"), Color("2b6cb0"), Color("718096"), Color("9b2c2c"), Color("2f855a"), Color("2d3748")]

var state: GameState
var zoom := 0.2
var speed := 1.0
var detail := true
var _roads: Array = []              # PackedVector2Array (px)
var _cum: Array = []                # PackedFloat32Array cumulative lengths
var _cong := PackedFloat32Array()   # 0..1 per road
var _flow := 1.0
var _cars: Array = []               # {r, d, dir, col, lane}
var _venues: Array = []             # {pos, kind, name, active, left, ready, need}
var _crowd: Array = []              # {pos, vel, life}
var _sparks: Array = []             # {pos, vel, life, col}
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _frame := 0


func setup(st: GameState, roads: Array) -> void:
	state = st
	_rng.seed = hash(st.city_id + "_traffic")
	for r in roads:
		var pts: PackedVector2Array = r[0]
		_roads.append(pts)
		var cum := PackedFloat32Array([0.0])
		for i in range(1, pts.size()):
			cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
		_cum.append(cum)
	_cong.resize(_roads.size())
	refresh()


func set_zoom(z: float) -> void:
	zoom = z


func set_detail(on: bool) -> void:
	detail = on
	_spawn_cars()


## Re-reads the active and upcoming events; call when events start/end or monthly.
func refresh() -> void:
	if state == null:
		return
	_cong.fill(0.08)
	_flow = 1.0
	_venues.clear()
	for a in state.active_events:
		var id := str(a["id"])
		match id:
			"bridge_traffic":
				for b in CityEvents.flavor(state.city).get("bridges", []):
					var mid: Vector2 = (state.city.project(b["a"][0], b["a"][1]) + state.city.project(b["b"][0], b["b"][1])) * 0.5 * PX
					_jam_near(mid, 4.0, 0.95)
			"derby":
				var st: Array = RealEvents.STADIUMS.get(state.city_id, [])
				if not st.is_empty():
					var s: Array = st[(state.year * 12 + state.month) % st.size()]
					var p := state.city.project(s[0], s[1]) * PX
					_jam_near(p, 5.0, 1.0)
					_venues.append({"pos": p, "kind": "stadium", "name": I18n.t("event_derby_short"), "active": true, "left": 0, "ready": true, "need": false})
			"rain":
				_raise_all(0.3)
			"snow_storm":
				_raise_all(0.55)
	for e in state.calendar.active(state):
		var fx := str(e.get("fx", ""))
		if fx == "empty":
			_flow = 0.15
			continue
		if e.has("venue"):
			var p := state.calendar.venue_pos(state, e) * PX
			var carm := float(e.get("mods", {}).get("car", 1.0))
			if carm > 1.0:
				_jam_near(p, 6.0, clampf((carm - 1.0) * 2.2, 0.4, 1.0))
			_venues.append({"pos": p, "kind": fx, "name": I18n.t("re_" + str(e["id"])), "active": true, "left": 0,
				"ready": state.calendar.is_served(state, e), "need": e.get("need_serve", false)})
	for u in state.calendar.upcoming(state):
		var e: Dictionary = u["e"]
		if not e.has("venue"):
			continue
		_venues.append({"pos": state.calendar.venue_pos(state, e) * PX, "kind": str(e.get("fx", "")), "name": I18n.t("re_" + str(e["id"])),
			"active": false, "left": int(u["left"]), "ready": state.calendar.is_served(state, e), "need": e.get("need_serve", false)})
	_spawn_cars()
	queue_redraw()


func _jam_near(p: Vector2, km: float, level: float) -> void:
	var r := km * PX
	for i in _roads.size():
		var best := INF
		for q in _roads[i]:
			best = minf(best, q.distance_to(p))
		if best < r:
			_cong[i] = maxf(_cong[i], level * (1.0 - 0.6 * best / r))


func _raise_all(level: float) -> void:
	for i in _cong.size():
		_cong[i] = maxf(_cong[i], level)


func _spawn_cars() -> void:
	_cars.clear()
	if _roads.is_empty():
		return
	var total := 0.0
	var weights := PackedFloat32Array()
	for i in _roads.size():
		var cum: PackedFloat32Array = _cum[i]
		var w: float = cum[cum.size() - 1] * (1.0 + 2.5 * _cong[i])
		weights.append(w)
		total += w
	var n := int(clampf(total / PX * 1.6 * _flow, 8.0, 240.0 if detail else 90.0))
	for k in n:
		var x := _rng.randf() * total
		var ri := 0
		while ri < weights.size() - 1 and x > weights[ri]:
			x -= weights[ri]
			ri += 1
		var cum: PackedFloat32Array = _cum[ri]
		_cars.append({"r": ri, "d": _rng.randf() * cum[cum.size() - 1], "dir": 1.0 if _rng.randf() < 0.5 else -1.0,
			"col": CAR_COLORS[_rng.randi() % CAR_COLORS.size()], "v": _rng.randf_range(0.8, 1.2)})


func _pos_on(ri: int, d: float) -> Array:
	var pts: PackedVector2Array = _roads[ri]
	var cum: PackedFloat32Array = _cum[ri]
	var i := cum.bsearch(d)
	i = clampi(i, 1, pts.size() - 1)
	var seg := cum[i] - cum[i - 1]
	var t := 0.0 if seg <= 0.0 else (d - cum[i - 1]) / seg
	var a := pts[i - 1]
	var b := pts[i]
	return [a.lerp(b, clampf(t, 0.0, 1.0)), (b - a).normalized()]


func _process(delta: float) -> void:
	if state == null:
		return
	_t += delta
	var dt := delta * speed
	for c in _cars:
		var cum: PackedFloat32Array = _cum[c["r"]]
		var len: float = cum[cum.size() - 1]
		var v: float = 160.0 * float(c["v"]) * (1.0 - 0.88 * _cong[c["r"]])
		c["d"] = float(c["d"]) + float(c["dir"]) * v * dt
		if c["d"] > len:
			c["d"] = len
			c["dir"] = -1.0
		elif c["d"] < 0.0:
			c["d"] = 0.0
			c["dir"] = 1.0
	# crowds streaming into active venues
	for vn in _venues:
		if vn["active"] and detail and _crowd.size() < 160 and _rng.randf() < dt * 22.0:
			var ang := _rng.randf() * TAU
			var start: Vector2 = vn["pos"] + Vector2.from_angle(ang) * _rng.randf_range(1.2, 2.6) * PX
			_crowd.append({"pos": start, "vel": (vn["pos"] - start) / _rng.randf_range(3.0, 6.0), "life": 1.0})
		if vn["active"] and vn["kind"] == "celebration" and detail and _rng.randf() < dt * 1.6:
			_firework(vn["pos"] + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * PX)
	for p in _crowd:
		p["pos"] += p["vel"] * dt
		p["life"] = float(p["life"]) - dt * 0.2
	_crowd = _crowd.filter(func(p): return p["life"] > 0.0)
	for s in _sparks:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.97
		s["vel"].y += 40.0 * delta
		s["life"] = float(s["life"]) - delta * 0.7
	_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
	_frame += 1
	# full rate while cars are visible, otherwise a lighter refresh for the pulses
	if (zoom >= 0.1 and not _cars.is_empty()) or not _sparks.is_empty() or _frame % 3 == 0:
		queue_redraw()


func _firework(at: Vector2) -> void:
	var col := Color.from_hsv(_rng.randf(), 0.7, 1.0)
	for i in 26:
		_sparks.append({"pos": at, "vel": Vector2.from_angle(TAU * i / 26.0) * _rng.randf_range(90.0, 160.0), "life": 1.0, "col": col})


func _draw() -> void:
	if state == null:
		return
	var inv := 1.0 / clampf(zoom, 0.03, 3.0)
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	# jammed roads: glowing red / amber bands
	for i in _roads.size():
		var c := _cong[i]
		if c < 0.4:
			continue
		var col := Color("f6ad55").lerp(Color("e53e3e"), clampf((c - 0.4) / 0.5, 0.0, 1.0))
		col.a = 0.35 + 0.25 * pulse * c
		draw_polyline(_roads[i], col, maxf(20.0, 7.0 * inv), true)
	# cars
	if zoom >= 0.1:
		var r := clampf(3.4 * inv, 5.0, 16.0)
		for car in _cars:
			var pd := _pos_on(car["r"], car["d"])
			var dir: Vector2 = pd[1] * float(car["dir"])
			var p: Vector2 = pd[0] + dir.orthogonal() * r * 0.9
			var jam := _cong[car["r"]] > 0.55
			var col: Color = Color("c53030") if jam else car["col"]
			draw_line(p - dir * r * 1.1, p + dir * r * 1.1, col, r * 1.4, true)
			if jam:
				draw_circle(p - dir * r * 1.2, r * 0.45, Color(1.0, 0.2, 0.2, 0.6 + 0.4 * pulse))
	# crowds
	var cr := clampf(2.2 * inv, 3.0, 10.0)
	for p in _crowd:
		draw_circle(p["pos"], cr, Color(0.25, 0.2, 0.45, 0.65 * float(p["life"])))
	for s in _sparks:
		var c2: Color = s["col"]
		c2.a = float(s["life"])
		draw_circle(s["pos"], clampf(2.0 * inv, 3.0, 12.0), c2)
	# venues
	var f := ThemeBuilder.font(850)
	for vn in _venues:
		var pos: Vector2 = vn["pos"]
		var col: Color = Palette.GOOD if (vn["ready"] or not vn["need"]) else Palette.BAD
		if vn["active"]:
			col = Palette.ACCENT
			for k in 3:
				var ph := fmod(_t * 0.6 + k / 3.0, 1.0)
				draw_arc(pos, (0.3 + ph * 1.6) * PX, 0.0, TAU, 64, Color(col, 0.55 * (1.0 - ph)), maxf(6.0, 3.0 * inv), true)
		else:
			var rr := RealEvents.SERVE_KM * PX
			draw_circle(pos, rr, Color(col, 0.08 + 0.05 * pulse))
			var segs := 36
			for k in segs:
				if k % 2 == 0:
					var a0 := TAU * k / segs + _t * 0.15
					draw_arc(pos, rr, a0, a0 + TAU / segs, 4, Color(col, 0.85), maxf(5.0, 2.5 * inv), true)
		# pin + label at constant screen size
		draw_set_transform(pos, 0.0, Vector2(inv, inv))
		var bob := -4.0 * pulse
		draw_circle(Vector2(0, -34 + bob), 20.0, Color.WHITE)
		draw_circle(Vector2(0, -34 + bob), 16.0, col)
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -22 + bob), Vector2(9, -22 + bob), Vector2(0, -6 + bob)]), Color.WHITE)
		draw_colored_polygon(Icon._star(Vector2(0, -34 + bob), 9.0, 4.0), Color.WHITE)
		var txt: String = vn["name"]
		if not vn["active"]:
			txt += "  ·  %d %s" % [vn["left"], I18n.t("months_short")]
		var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		var box := Rect2(Vector2(-sz.x * 0.5 - 12, -96 + bob), Vector2(sz.x + 24, 34))
		draw_rect(box, Color(Palette.INK, 0.9))
		draw_rect(Rect2(box.position, Vector2(6, box.size.y)), col)
		draw_string(f, Vector2(-sz.x * 0.5, -72 + bob), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.CREAM)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
