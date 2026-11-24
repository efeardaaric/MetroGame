class_name TransitNetwork
extends RefCounted
## Stations and lines. Pure data + validation; no rendering.

signal changed

const MAX_SEGMENT_KM := 14.0
const MAX_FERRY_SEGMENT_KM := 30.0
const STATION_SNAP_KM := 0.35
const DEPOT_BASE := 10
const DEPOT_STEP := 6

var city: CityMap
var stations := {}  # id -> {id, pos, name, lines:Array}
var lines := {}     # id -> line dict
var _next_station := 1
var _next_line := 1
var tech: Array = []        # researched technology ids (shared with GameState)


func _init(city_map: CityMap) -> void:
	city = city_map


# ---------------------------------------------------------------- queries

func station_at(p: Vector2, radius: float = STATION_SNAP_KM) -> int:
	var best := -1
	var bd := radius
	for s in stations.values():
		var d: float = s["pos"].distance_to(p)
		if d < bd:
			bd = d
			best = s["id"]
	return best


func station_display_name(sid: int) -> String:
	if not stations.has(sid):
		return "?"
	var n: String = stations[sid]["name"]
	if n.begins_with("@"):
		var parts := n.substr(1).split("#")
		var base := I18n.t(parts[0])
		return base if parts.size() == 1 else "%s %s" % [base, parts[1]]
	return n


func line_path(line: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	for sid in line["stations"]:
		out.append(stations[sid]["pos"])
	if line.get("loop", false) and out.size() > 2:
		out.append(out[0])
	return out


func line_length(line: Dictionary) -> float:
	return Geo.polyline_length(line_path(line))


## Round-trip time in minutes.
func line_cycle_min(line: Dictionary) -> float:
	var m := TransitModes.get_mode(line["mode"])
	var length := line_length(line)
	var n_st: int = line["stations"].size()
	var one_way: float = length / m["speed"] * 60.0 + n_st * m["dwell_min"]
	if line.get("loop", false):
		return max(one_way, 4.0)
	return max(one_way * 2.0 + 4.0, 6.0) # +turnaround


func line_headway_min(line: Dictionary) -> float:
	var v: int = max(1, line["vehicles"])
	return line_cycle_min(line) / v


func line_hourly_capacity(line: Dictionary) -> float:
	if line["vehicles"] <= 0:
		return 0.0
	var m := TransitModes.get_mode(line["mode"])
	var inc_cap: float = float(line["incident"]["cap"]) if line.has("incident") else 1.0
	return m["capacity"] * 60.0 / line_headway_min(line) * TechData.mode_mult(tech, "capacity", line["mode"]) * inc_cap


func depot_capacity(line: Dictionary) -> int:
	var m := TransitModes.get_mode(line["mode"])
	return min(m["max_vehicles"], DEPOT_BASE + DEPOT_STEP * line.get("depot", 0))


func depot_expand_cost(line: Dictionary) -> float:
	var m := TransitModes.get_mode(line["mode"])
	return round(m["vehicle_cost"] * 1.6 + 8.0)


func line_annual_opex(line: Dictionary) -> float:
	var m := TransitModes.get_mode(line["mode"])
	return line["vehicles"] * m["vehicle_opex"] * TechData.mode_mult(tech, "opex", line["mode"]) + line_length(line) * m["km_opex"] + line["stations"].size() * 0.4


func total_annual_opex() -> float:
	var s := 0.0
	for l in lines.values():
		s += line_annual_opex(l)
	return s


func line_display_name(line: Dictionary) -> String:
	return line["name"]


func modes_in_use() -> Array:
	var out := []
	for l in lines.values():
		if not out.has(l["mode"]):
			out.append(l["mode"])
	return out


func network_value() -> float:
	var s := 0.0
	for l in lines.values():
		s += l.get("built_cost", 0.0)
	return s


# ---------------------------------------------------------------- validation

## Evaluates a single segment. Returns {ok, reason, cost, length, water_km, bridge_km, grade}.
func evaluate_segment(mode: String, deep: bool, a: Vector2, b: Vector2) -> Dictionary:
	var m := TransitModes.get_mode(mode)
	var length := a.distance_to(b)
	var res := {"ok": true, "reason": "", "cost": 0.0, "length": length, "water_km": 0.0,
				"bridge_km": 0.0, "grade": 0.0, "water_runs": []}
	if length < m["min_spacing"]:
		res["ok"] = false
		res["reason"] = I18n.t("err_too_close") % [m["min_spacing"]]
		return res
	var max_seg := MAX_FERRY_SEGMENT_KM if mode == "ferry" else MAX_SEGMENT_KM
	if length > max_seg:
		res["ok"] = false
		res["reason"] = I18n.t("err_too_long") % [max_seg]
		return res
	# sample along the segment
	var steps := int(ceil(length / 0.08)) + 1
	var water_km := 0.0
	var run := 0.0
	var longest_run := 0.0
	var land_mid := 0.0
	var step_len: float = length / maxi(1, steps - 1)
	var runs: Array = []
	var run_start := -1.0
	for i in steps:
		var t: float = float(i) / maxi(1, steps - 1)
		var p := a.lerp(b, t)
		var wet := city.is_sea(p)
		if not wet and city.is_river(p):
			res["cost_river"] = true
		if wet:
			water_km += step_len
			run += step_len
			longest_run = max(longest_run, run)
			if run_start < 0.0:
				run_start = t
		else:
			if run_start >= 0.0:
				runs.append(Vector2(run_start, t))
			run_start = -1.0
			run = 0.0
			var dd: float = t * length
			if dd > 0.6 and dd < length - 0.6:
				land_mid += step_len
	if run_start >= 0.0:
		runs.append(Vector2(run_start, 1.0))
	res["water_km"] = water_km
	res["water_runs"] = runs
	var cost_km: float = m["cost_km_deep"] * TechData.mult(tech, "cost_km_deep") if (deep and m["underground"]) else m["cost_km"]
	var cost: float = length * cost_km
	if res.has("cost_river") and m["surface"]:
		cost += 6.0 # small river bridge
	match m["water"]:
		"tunnel":
			if longest_run > 0.6 and not deep:
				res["ok"] = false
				res["reason"] = I18n.t("err_shallow_water")
				return res
			cost += water_km * 60.0 # immersed tube premium
		"bridge":
			if longest_run > TransitModes.MAX_BRIDGE_KM:
				res["ok"] = false
				res["reason"] = I18n.t("err_bridge_long") % [TransitModes.MAX_BRIDGE_KM]
				return res
			res["bridge_km"] = water_km
			cost += water_km * TransitModes.BRIDGE_COST_KM
		"none":
			if water_km > 0.05:
				res["ok"] = false
				res["reason"] = I18n.t("err_no_water")
				return res
		"only":
			if land_mid > 1.0:
				res["ok"] = false
				res["reason"] = I18n.t("err_ferry_land")
				return res
	# grade check for surface modes
	if not m["underground"] and mode != "ferry":
		var ea := city.elevation(a)
		var eb := city.elevation(b)
		var grade: float = abs(eb - ea) / max(1.0, length * 1000.0)
		res["grade"] = grade
		if grade > m["max_grade"]:
			res["ok"] = false
			res["reason"] = I18n.t("err_grade") % [grade * 100.0, m["max_grade"] * 100.0]
			return res
		# hills cost extra for surface works
		cost *= 1.0 + grade * 4.0
	if mode == "funicular" and length > m["max_length"]:
		res["ok"] = false
		res["reason"] = I18n.t("err_funicular_len") % [m["max_length"]]
		return res
	res["cost"] = cost
	return res


## Checks if a station can be placed at p for mode. Returns "" or an error string.
func station_site_error(mode: String, p: Vector2) -> String:
	if not city.in_bounds(p):
		return I18n.t("err_bounds")
	if city.is_water(p):
		return I18n.t("err_station_water")
	if city.is_park(p) >= 0:
		return I18n.t("err_park")
	if mode == "ferry" and not city.is_near_water(p, 0.5):
		return I18n.t("err_pier_coast")
	return ""


## Evaluates a draft: nodes = [{pos, sid}] in build order. Returns {ok, cost, segments, length, reason}.
func evaluate_draft(mode: String, deep: bool, nodes: Array, existing_line_id: int = -1) -> Dictionary:
	var m := TransitModes.get_mode(mode)
	var total := 0.0
	var length := 0.0
	var segs: Array = []
	var ok := true
	var reason := ""
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if n["sid"] < 0:
			total += m["cost_station"] * TechData.mult(tech, "cost_station")
		elif not _station_has_mode(n["sid"], mode):
			total += m["cost_station"] * 0.5 * TechData.mult(tech, "cost_station") # platform added to existing station
		if i > 0:
			var e := evaluate_segment(mode, deep, nodes[i - 1]["pos"], n["pos"])
			segs.append(e)
			total += e["cost"]
			length += e["length"]
			if not e["ok"] and ok:
				ok = false
				reason = e["reason"]
	var station_count := nodes.size()
	if existing_line_id >= 0 and lines.has(existing_line_id):
		station_count += lines[existing_line_id]["stations"].size() - 1
	if station_count > m["max_stations"]:
		ok = false
		reason = I18n.t("err_max_stations") % [m["max_stations"]]
	var veh := 0
	if existing_line_id < 0 and nodes.size() >= 2:
		var cycle: float = (length / m["speed"] * 60.0 + nodes.size() * m["dwell_min"]) * 2.0 + 4.0
		veh = clampi(int(ceil(cycle / 7.0)), 1, mini(DEPOT_BASE, m["max_vehicles"]))
		total += veh * m["vehicle_cost"]
	return {"ok": ok, "cost": total, "segments": segs, "length": length, "reason": reason, "vehicles": veh}


func _station_has_mode(sid: int, mode: String) -> bool:
	if not stations.has(sid):
		return false
	for lid in stations[sid]["lines"]:
		if lines.has(lid) and lines[lid]["mode"] == mode:
			return true
	return false


# ---------------------------------------------------------------- mutation

func _unique_station_name(p: Vector2) -> String:
	var poi := city.nearest_poi(p, 0.7)
	var base: String
	if not poi.is_empty():
		base = "@" + poi["name_key"]
	else:
		base = city.nearest_zone_name(p)
	var used := {}
	for s in stations.values():
		used[s["name"]] = true
	if not used.has(base):
		return base
	for n in range(2, 99):
		var cand := (base + "#" + str(n)) if base.begins_with("@") else ("%s %d" % [base, n])
		if not used.has(cand):
			return cand
	return base


func add_station(p: Vector2) -> int:
	var sid := _next_station
	_next_station += 1
	stations[sid] = {"id": sid, "pos": p, "name": _unique_station_name(p), "lines": []}
	return sid


func next_line_name(mode: String) -> String:
	var prefix := TransitModes.mode_prefix(mode)
	var n := 1
	var used := {}
	for l in lines.values():
		used[l["name"]] = true
	while used.has("%s%d" % [prefix, n]):
		n += 1
	return "%s%d" % [prefix, n]


func next_color_index() -> int:
	var counts := {}
	for l in lines.values():
		counts[l["color"]] = counts.get(l["color"], 0) + 1
	for i in TransitModes.LINE_COLORS.size():
		if not counts.has(i):
			return i
	return lines.size() % TransitModes.LINE_COLORS.size()


## Commits a draft. When extending, `at_start` selects which end receives the new nodes
## (nodes[0] must be that end station). Returns line id.
func commit_draft(mode: String, deep: bool, nodes: Array, cost: float, extend_line: int = -1, at_start: bool = false, vehicles: int = 0) -> int:
	var sids: Array = []
	for n in nodes:
		var sid: int = n["sid"]
		if sid < 0:
			sid = add_station(n["pos"])
		sids.append(sid)
	var lid: int
	var loop := false
	if sids.size() > 2 and sids[0] == sids[sids.size() - 1]:
		loop = true
		sids.pop_back()
	if extend_line >= 0 and lines.has(extend_line):
		lid = extend_line
		var line: Dictionary = lines[lid]
		var new_part := sids.slice(1)
		if at_start:
			new_part.reverse()
			var st: Array = new_part + line["stations"]
			line["stations"] = st
		else:
			line["stations"].append_array(new_part)
		# closing a loop by extending to the other end
		var s: Array = line["stations"]
		if s.size() > 3 and s[0] == s[s.size() - 1]:
			s.pop_back()
			line["loop"] = true
		line["built_cost"] = line.get("built_cost", 0.0) + cost
	else:
		lid = _next_line
		_next_line += 1
		var m := TransitModes.get_mode(mode)
		lines[lid] = {
			"id": lid, "mode": mode, "deep": deep, "stations": sids, "loop": loop,
			"vehicles": vehicles if vehicles > 0 else mini(m["default_vehicles"], DEPOT_BASE),
			"depot": 0, "color": next_color_index(), "name": next_line_name(mode),
			"built_cost": cost,
		}
		lines[lid]["vehicles"] = min(lines[lid]["vehicles"], m["max_vehicles"])
	_rebuild_station_lines()
	changed.emit()
	return lid


func remove_line(lid: int) -> float:
	if not lines.has(lid):
		return 0.0
	var refund: float = lines[lid].get("built_cost", 0.0) * 0.25
	lines.erase(lid)
	_rebuild_station_lines()
	# drop orphan stations
	for sid in stations.keys():
		if stations[sid]["lines"].is_empty():
			stations.erase(sid)
	changed.emit()
	return refund


func set_vehicles(lid: int, n: int) -> void:
	if not lines.has(lid):
		return
	var l: Dictionary = lines[lid]
	l["vehicles"] = clampi(n, 1, depot_capacity(l))
	changed.emit()


func expand_depot(lid: int) -> void:
	if lines.has(lid):
		lines[lid]["depot"] = lines[lid].get("depot", 0) + 1
		changed.emit()


func rename_station(sid: int, new_name: String) -> void:
	var n := new_name.strip_edges().replace("@", "")
	if stations.has(sid) and n != "":
		stations[sid]["name"] = n.substr(0, 28)
		changed.emit()


func set_line_color(lid: int, idx: int) -> void:
	if lines.has(lid):
		lines[lid]["color"] = idx
		changed.emit()


func _rebuild_station_lines() -> void:
	for s in stations.values():
		s["lines"] = []
	for l in lines.values():
		for sid in l["stations"]:
			if stations.has(sid) and not stations[sid]["lines"].has(l["id"]):
				stations[sid]["lines"].append(l["id"])


func line_color(line: Dictionary) -> Color:
	return TransitModes.LINE_COLORS[int(line["color"]) % TransitModes.LINE_COLORS.size()]


## Endpoint info for extension: returns {line_id, at_start} if sid is an end of a line of this mode.
func line_end_at(sid: int, mode: String) -> Dictionary:
	for l in lines.values():
		if l["mode"] != mode or l.get("loop", false):
			continue
		var s: Array = l["stations"]
		if s.is_empty():
			continue
		if s[s.size() - 1] == sid:
			return {"line_id": l["id"], "at_start": false}
		if s[0] == sid:
			return {"line_id": l["id"], "at_start": true}
	return {}


# ---------------------------------------------------------------- persistence

func to_dict() -> Dictionary:
	var st: Array = []
	for s in stations.values():
		st.append({"id": s["id"], "x": s["pos"].x, "y": s["pos"].y, "name": s["name"]})
	var ln: Array = []
	for l in lines.values():
		ln.append(l.duplicate(true))
	return {"stations": st, "lines": ln, "next_station": _next_station, "next_line": _next_line}


func from_dict(d: Dictionary) -> void:
	stations.clear()
	lines.clear()
	for s in d.get("stations", []):
		var sid := int(s["id"])
		stations[sid] = {"id": sid, "pos": Vector2(s["x"], s["y"]), "name": s["name"], "lines": []}
	for l in d.get("lines", []):
		var line: Dictionary = l.duplicate(true)
		line["id"] = int(line["id"])
		var sids: Array = []
		for x in line["stations"]:
			sids.append(int(x))
		line["stations"] = sids
		line["vehicles"] = int(line["vehicles"])
		line["depot"] = int(line.get("depot", 0))
		line["color"] = int(line.get("color", 0))
		lines[line["id"]] = line
	_next_station = int(d.get("next_station", stations.size() + 1))
	_next_line = int(d.get("next_line", lines.size() + 1))
	_rebuild_station_lines()
	changed.emit()
