class_name DemandModel
extends RefCounted
## Gravity-based trip demand + transit assignment.
## Produces daily ridership, per-line loads and per-station boardings.

const WALK_KMH := 5.0
const WALK_MAX_KM := 1.2
const FEEDER_MAX_KM := 3.0
const FEEDER_KMH := 16.0
const TRIP_RATE := 2.0           # one-way trips per resident per day
const DEMAND_SCALE := 0.6        # calibration (non-home-based trips, visitors, students)
const TRANSFER_PENALTY := 3.0    # minutes
const MAX_SHARE := 0.72
const PEAK_HOUR_FACTOR := 0.085

var city: CityMap
var net: TransitNetwork
var car_speed := 24.0
var car_overhead := 9.0

# results
var riders := 0.0
var boardings := 0.0
var line_riders := {}      # lid -> boardings/day
var line_load := {}        # lid -> peak load factor (0..>1)
var line_seg_flow := {}    # lid -> PackedFloat32Array (max of both directions per segment)
var station_boardings := {} # sid -> boardings/day
var mode_riders := {}      # mode -> boardings/day
var coverage := 0.0        # share of population within walking distance
var avg_trip_min := 0.0
var satisfaction := 70.0
var crowded_lines := 0
var debug := false
var city_scale := 1.0
var mods := {}  # seasonal / event modifiers, see CityEvents
var zones: Array = []      # snapshot used by async workers (falls back to city.zones)
var zones_snapshot := false
var debug_rows: Array = []


func _init(c: CityMap, n: TransitNetwork) -> void:
	city = c
	net = n
	city_scale = c.data.get("demand_scale", 1.0)
	match c.id:
		"istanbul":
			car_speed = 15.0
			car_overhead = 12.0
		"ankara":
			car_speed = 21.0
			car_overhead = 9.0
		_:
			car_speed = 18.0
			car_overhead = 10.0


func compute() -> void:
	if not zones_snapshot:
		zones = city.zones
	riders = 0.0
	boardings = 0.0
	line_riders.clear()
	line_load.clear()
	line_seg_flow.clear()
	station_boardings.clear()
	mode_riders.clear()
	coverage = 0.0
	crowded_lines = 0
	avg_trip_min = 0.0

	var op_lines: Array = []
	for l in net.lines.values():
		var closed: bool = l.has("incident") and float(l["incident"]["cap"]) <= 0.0
		if l["vehicles"] > 0 and l["stations"].size() >= 2 and not closed and net.is_operational(l):
			op_lines.append(l)
			line_riders[l["id"]] = 0.0
			var segs: int = l["stations"].size() - (0 if l.get("loop", false) else 1)
			var f := PackedFloat32Array()
			f.resize(segs * 2)
			line_seg_flow[l["id"]] = f
			mode_riders[l["mode"]] = mode_riders.get(l["mode"], 0.0)
	if op_lines.is_empty():
		_update_coverage({})
		satisfaction = 70.0
		return

	# ---- graph
	var g := _build_graph(op_lines)
	var hub_of: Dictionary = g["hub_of"]
	# ---- access tables per zone: {sid: [share, minutes]}
	var access: Array = []
	var covered_pop := 0.0
	var total_pop := 0.0
	for z in zones:
		var tab := {}
		var samples: PackedVector2Array = z["samples"]
		var w := 1.0 / samples.size()
		var walk_cov := 0.0
		for s in samples:
			var best_sid := -1
			var best_d := FEEDER_MAX_KM
			for sid in hub_of.keys():
				var d: float = net.stations[sid]["pos"].distance_to(s)
				if d < best_d:
					best_d = d
					best_sid = sid
			if best_sid < 0:
				continue
			var minutes: float
			var share := w
			if best_d <= WALK_MAX_KM:
				minutes = best_d * 1.25 / WALK_KMH * 60.0
				walk_cov += w
			else:
				minutes = 6.0 + best_d * 1.3 / FEEDER_KMH * 60.0
				share *= 0.75
			if not tab.has(best_sid):
				tab[best_sid] = [0.0, 0.0]
			tab[best_sid][0] += share
			tab[best_sid][1] += minutes * share
		for sid in tab.keys():
			if tab[sid][0] > 0.0:
				tab[sid][1] /= tab[sid][0]
		access.append(tab)
		covered_pop += z["pop"] * walk_cov
		total_pop += z["pop"]
	coverage = covered_pop / max(1.0, total_pop)

	# ---- shortest paths from every hub
	var sp := {} # sid -> {dist:PackedFloat32Array, prev:PackedInt32Array}
	for sid in hub_of.keys():
		sp[sid] = _dijkstra(g, hub_of[sid])

	# ---- gravity demand
	var nz := zones.size()
	var jobs := PackedFloat32Array()
	jobs.resize(nz)
	var poi_m: Dictionary = mods.get("poi", {})
	var kind_m: Dictionary = mods.get("kind", {})
	for i in nz:
		var z: Dictionary = zones[i]
		var j: float = z["jobs"]
		if z["poi_id"] != "":
			j *= float(poi_m.get(z["poi_id"], 1.0)) * float(kind_m.get(z.get("kind", ""), 1.0))
		jobs[i] = j
	var car_mult: float = mods.get("car", 1.0)
	var fare_pen: float = mods.get("fare_pen", 0.0)
	var demand_mult: float = mods.get("demand", 1.0)
	var attract_norm := PackedFloat32Array()
	attract_norm.resize(nz)
	for i in nz:
		var s := 0.0
		for j in nz:
			if i == j:
				continue
			s += jobs[j] * _impedance(zones[i]["pos"].distance_to(zones[j]["pos"]))
		attract_norm[i] = max(s, 0.0001)

	# pass 1 & 2 (capacity restraint)
	var line_factor := {}
	for l in op_lines:
		line_factor[l["id"]] = 1.0
	var path_cache := {}
	var time_sum := 0.0
	for pass_i in 2:
		riders = 0.0
		time_sum = 0.0
		for lid in line_riders.keys():
			line_riders[lid] = 0.0
			var f: PackedFloat32Array = line_seg_flow[lid]
			f.fill(0.0)
		station_boardings.clear()
		for i in nz:
			var zi: Dictionary = zones[i]
			if zi["pop"] <= 0.0 or access[i].is_empty():
				continue
			var produced: float = zi["pop"] * 1000.0 * TRIP_RATE * DEMAND_SCALE * city_scale * demand_mult
			for j in nz:
				if i == j or access[j].is_empty():
					continue
				var zj: Dictionary = zones[j]
				var dist: float = zi["pos"].distance_to(zj["pos"])
				if dist < 1.2:
					continue
				var trips: float = produced * jobs[j] * _impedance(dist) / attract_norm[i]
				# both directions: return trips counted from the other side automatically
				var car_t := (dist * 1.3 / car_speed * 60.0 + car_overhead) * car_mult
				for so in access[i].keys():
					var ao: Array = access[i][so]
					var spo: Dictionary = sp[so]
					for sd in access[j].keys():
						if so == sd:
							continue
						var ad: Array = access[j][sd]
						var net_t: float = spo["dist"][hub_of[sd]]
						if net_t >= INF * 0.5:
							continue
						var tt: float = ao[1] + net_t + ad[1] + fare_pen
						var share: float = MAX_SHARE / (1.0 + exp((tt - car_t) / 10.0 - 0.2))
						var flow: float = trips * ao[0] * ad[0] * share
						if flow < 0.5:
							continue
						var key: int = so * 100000 + sd
						var path: Dictionary
						if path_cache.has(key):
							path = path_cache[key]
						else:
							path = _trace(g, spo["prev"], hub_of[so], hub_of[sd])
							path_cache[key] = path
						var fac := 1.0
						for lid in path["lines"]:
							fac = min(fac, line_factor.get(lid, 1.0))
						flow *= fac
						riders += flow
						if debug and pass_i == 1:
							debug_rows.append([flow, zi["name"], zj["name"], tt, car_t, ao[0], ad[0], trips])
						time_sum += flow * tt
						for e in path["edges"]:
							var lid2: int = e[0]
							var f2: PackedFloat32Array = line_seg_flow[lid2]
							if e[1] is Array:
								for si in e[1]:
									f2[si] += flow
							else:
								f2[e[1]] += flow
						for b in path["boards"]:
							var lid3: int = b[0]
							line_riders[lid3] += flow
							station_boardings[b[1]] = station_boardings.get(b[1], 0.0) + flow
		# capacity check
		crowded_lines = 0
		for l in op_lines:
			var lid: int = l["id"]
			var f3: PackedFloat32Array = line_seg_flow[lid]
			var peak := 0.0
			for v in f3:
				peak = max(peak, v)
			var cap := net.line_hourly_capacity(l)
			var load: float = peak * PEAK_HOUR_FACTOR / maxf(1.0, cap)
			line_load[lid] = load
			if pass_i == 0:
				line_factor[lid] = 1.0 if load <= 1.0 else pow(1.0 / load, 0.75)
			elif load > 0.95:
				crowded_lines += 1
	if debug:
		debug_rows.sort_custom(func(a, b): return a[0] > b[0])
		for r in debug_rows.slice(0, 12):
			print("      %7.0f %s -> %s  tt %.1f car %.1f ao %.2f ad %.2f trips %.0f" % r)
		debug_rows.clear()
	boardings = 0.0
	for l in op_lines:
		var lid: int = l["id"]
		boardings += line_riders[lid]
		mode_riders[l["mode"]] = mode_riders.get(l["mode"], 0.0) + line_riders[lid]
	avg_trip_min = time_sum / max(1.0, riders)
	# satisfaction: crowding, waiting and speed
	var sat := 82.0
	var wsum := 0.0
	var load_pen := 0.0
	var wait_pen := 0.0
	for l in op_lines:
		var lid: int = l["id"]
		var w: float = line_riders[lid] + 1.0
		wsum += w
		load_pen += w * clampf((line_load[lid] - 0.85) * 50.0, 0.0, 40.0)
		wait_pen += w * clampf((net.line_headway_min(l) - 4.0) * 1.6, 0.0, 25.0)
	if wsum > 0.0:
		sat -= load_pen / wsum + wait_pen / wsum
	sat += clampf((35.0 - avg_trip_min) * 0.4, -10.0, 10.0)
	sat += float(mods.get("sat_add", 0.0))
	satisfaction = clampf(sat, 5.0, 100.0)


## Copies results computed by another model (used by the async worker).
func copy_from(o: DemandModel) -> void:
	riders = o.riders
	boardings = o.boardings
	line_riders = o.line_riders
	line_load = o.line_load
	line_seg_flow = o.line_seg_flow
	station_boardings = o.station_boardings
	mode_riders = o.mode_riders
	coverage = o.coverage
	avg_trip_min = o.avg_trip_min
	satisfaction = o.satisfaction
	crowded_lines = o.crowded_lines


func _update_coverage(_hubs: Dictionary) -> void:
	coverage = 0.0


func _impedance(d: float) -> float:
	return 1.0 / pow(d + 2.5, 1.7)


## Graph: hub node per station, route node per (station, line).
func _build_graph(op_lines: Array) -> Dictionary:
	var hub_of := {}
	var node_count := 0
	var adj: Array = [] # Array of Array of [to, cost, kind, a, b]
	# kind: 0 board(line, sid) 1 alight 2 ride(line, seg_index_dir) 3 walk
	for l in op_lines:
		var mask0: Array = net.stop_mask(l)
		for i in l["stations"].size():
			var sid: int = l["stations"][i]
			if mask0[i] and not hub_of.has(sid):
				hub_of[sid] = node_count
				node_count += 1
				adj.append([])
	var speed_m: Dictionary = mods.get("speed", {})
	var comfort_m: Dictionary = mods.get("comfort", {})
	for l in op_lines:
		var lid: int = l["id"]
		var m := TransitModes.get_mode(l["mode"])
		var spd: float = m["speed"] * float(speed_m.get(l["mode"], 1.0))
		var wait: float = minf(net.line_headway_min(l) * 0.5, 15.0) * float(mods.get("wait", 1.0))
		var tpen: float = TRANSFER_PENALTY * float(mods.get("transfer", 1.0))
		var st: Array = l["stations"]
		var mask: Array = net.stop_mask(l)
		var express: bool = l.get("express", false) and net.can_express(l)
		if express:
			spd *= 1.15
		var route_nodes: Array = []
		for i in st.size():
			var sid: int = st[i]
			if not mask[i]:
				route_nodes.append(-1)
				continue
			var rn := node_count
			node_count += 1
			adj.append([])
			route_nodes.append(rn)
			var tp: float = tpen * (0.4 if net.stations[sid].get("hub", 0) > 0 else 1.0)
			adj[hub_of[sid]].append([rn, wait + tp * 0.5, 0, lid, sid])
			adj[rn].append([hub_of[sid], tp * 0.5, 1, lid, sid])
		var n := st.size()
		var loop: bool = l.get("loop", false) and net.active_range(l) == Vector2i(0, n - 1)
		var segs := n if loop else n - 1
		var comfort: float = m["comfort"] * float(comfort_m.get(l["mode"], 1.0))
		var dwell: float = m["dwell_min"] * float(mods.get("dwell", 1.0))
		# connect consecutive stops; skipped stations fold their segments into one edge
		var k := 0
		while k < segs:
			if route_nodes[k] < 0:
				k += 1
				continue
			var d := 0.0
			var seg_list: Array = []
			var j := k
			while true:
				var nb: int = (j + 1) % n
				d += net.stations[st[j]]["pos"].distance_to(net.stations[st[nb]]["pos"])
				seg_list.append(j)
				j += 1
				if j >= segs or route_nodes[j % n] >= 0 or (not loop and j >= n - 1):
					break
			var b_node: int = route_nodes[j % n] if j % n < route_nodes.size() else -1
			if b_node < 0:
				break
			var t: float = (d / spd * 60.0 + dwell) / comfort
			var fwd: Array = []
			var back: Array = []
			for sidx in seg_list:
				fwd.append(sidx * 2)
				back.append(sidx * 2 + 1)
			adj[route_nodes[k]].append([b_node, t, 2, lid, fwd if fwd.size() > 1 else fwd[0]])
			adj[b_node].append([route_nodes[k], t, 2, lid, back if back.size() > 1 else back[0]])
			k = j
	# walking transfers between nearby stations
	var sids := hub_of.keys()
	for i in sids.size():
		for j in range(i + 1, sids.size()):
			var d: float = net.stations[sids[i]]["pos"].distance_to(net.stations[sids[j]]["pos"])
			if d <= 0.45:
				var t := 2.0 + d * 1.2 / WALK_KMH * 60.0
				adj[hub_of[sids[i]]].append([hub_of[sids[j]], t, 3, -1, -1])
				adj[hub_of[sids[j]]].append([hub_of[sids[i]], t, 3, -1, -1])
	return {"hub_of": hub_of, "adj": adj, "n": node_count}


func _dijkstra(g: Dictionary, src: int) -> Dictionary:
	var n: int = g["n"]
	var adj: Array = g["adj"]
	var dist := PackedFloat64Array()
	dist.resize(n)
	dist.fill(INF)
	var prev := PackedInt32Array()   # index into adj[from] encoded as from*64+edge_idx
	prev.resize(n)
	prev.fill(-1)
	dist[src] = 0.0
	var heap := MinHeap.new()
	heap.push(0.0, src)
	while not heap.is_empty():
		var top := heap.pop()
		var d: float = top[0]
		var u: int = top[1]
		if d > dist[u]:
			continue
		var edges: Array = adj[u]
		for ei in edges.size():
			var e: Array = edges[ei]
			var v: int = e[0]
			var nd: float = d + e[1]
			if nd < dist[v]:
				dist[v] = nd
				prev[v] = u * 1024 + ei
				heap.push(nd, v)
	return {"dist": dist, "prev": prev}


func _trace(g: Dictionary, prev: PackedInt32Array, src: int, dst: int) -> Dictionary:
	var adj: Array = g["adj"]
	var edges: Array = []
	var boards: Array = []
	var lines_used: Array = []
	var v := dst
	var guard := 0
	while v != src and guard < 4000:
		guard += 1
		var code := prev[v]
		if code < 0:
			break
		var u := code / 1024
		var e: Array = adj[u][code % 1024]
		match int(e[2]):
			0:
				boards.append([e[3], e[4]])
				if not lines_used.has(e[3]):
					lines_used.append(e[3])
			2:
				edges.append([e[3], e[4]])
		v = u
	return {"edges": edges, "boards": boards, "lines": lines_used}


class MinHeap:
	var keys: Array[float] = []
	var vals: Array[int] = []

	func is_empty() -> bool:
		return keys.is_empty()

	func push(k: float, v: int) -> void:
		keys.append(k)
		vals.append(v)
		var i := keys.size() - 1
		while i > 0:
			var p := (i - 1) >> 1
			if keys[p] <= keys[i]:
				break
			_swap(i, p)
			i = p

	func pop() -> Array:
		var out := [keys[0], vals[0]]
		var last := keys.size() - 1
		keys[0] = keys[last]
		vals[0] = vals[last]
		keys.pop_back()
		vals.pop_back()
		var i := 0
		var n := keys.size()
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var s := i
			if l < n and keys[l] < keys[s]:
				s = l
			if r < n and keys[r] < keys[s]:
				s = r
			if s == i:
				break
			_swap(i, s)
			i = s
		return out

	func _swap(a: int, b: int) -> void:
		var tk := keys[a]
		keys[a] = keys[b]
		keys[b] = tk
		var tv := vals[a]
		vals[a] = vals[b]
		vals[b] = tv
