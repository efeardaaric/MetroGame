class_name CityMap
extends RefCounted
## Runtime geography of a city in kilometre space (x → east, y → south).

const KM_PER_DEG_LAT := 110.57
const SAMPLES_PER_ZONE := 28
const GRID_STEP := 0.5 # km, heatmap resolution

var id: String
var data: Dictionary
var lon_min: float
var lat_max: float
var km_per_deg_lon: float
var size_km: Vector2

var water_polys: Array[PackedVector2Array] = []
var river_polys: Array[PackedVector2Array] = []
var island_polys: Array[PackedVector2Array] = []
var park_polys: Array[PackedVector2Array] = []
var park_names: Array[String] = []
var divide: PackedVector2Array = PackedVector2Array()
var hills: Array = []
var base_elev := 0.0

## zones: {name, pos:Vector2, pop:float, jobs:float, r:float, samples:PackedVector2Array, poi_id}
var zones: Array = []
var pois: Array = []

var _noise := FastNoiseLite.new()
var _water_cache := {}


func _init(city_id: String) -> void:
	id = city_id
	data = CityData.get_city(city_id)
	var b: Array = data["bounds"]
	lon_min = b[0]
	lat_max = b[3]
	var lat_mid: float = (b[1] + b[3]) * 0.5
	km_per_deg_lon = 111.32 * cos(deg_to_rad(lat_mid))
	size_km = Vector2((b[2] - b[0]) * km_per_deg_lon, (b[3] - b[1]) * KM_PER_DEG_LAT)
	base_elev = data.get("base_elev", 0.0)
	_noise.seed = hash(city_id)
	_noise.frequency = 0.08
	_noise.fractal_octaves = 3
	_build_geometry()
	_build_zones()


func project(lon: float, lat: float) -> Vector2:
	return Vector2((lon - lon_min) * km_per_deg_lon, (lat_max - lat) * KM_PER_DEG_LAT)


func _proj_list(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(project(p[0], p[1]))
	return out


func _build_geometry() -> void:
	for poly in data.get("water_polys", []):
		water_polys.append(_proj_list(poly))
	for ch in data.get("channels", []):
		var poly := _channel_poly(_proj_list(ch["pts"]), ch["w"])
		if ch.get("river", false):
			river_polys.append(poly)
		else:
			water_polys.append(poly)
	for lk in data.get("lakes", []):
		water_polys.append(Geo.ellipse(project(lk["lon"], lk["lat"]), lk["rx"], lk["ry"], lk.get("rot", 0.0), 28))
	for isl in data.get("islands", []):
		island_polys.append(Geo.ellipse(project(isl["lon"], isl["lat"]), isl["rx"], isl["ry"], isl.get("rot", 0.0), 22))
	for pk in data.get("parks", []):
		park_polys.append(Geo.ellipse(project(pk["lon"], pk["lat"]), pk["rx"], pk["ry"], pk.get("rot", 0.0), 30))
		park_names.append(pk.get("name_key", ""))
	if data.get("divide", []).size() > 0:
		divide = _proj_list(data["divide"])
	for h in data.get("hills", []):
		hills.append({"pos": project(h["lon"], h["lat"]), "h": h["h"], "r": h["r"]})


func _channel_poly(center: PackedVector2Array, widths: Array) -> PackedVector2Array:
	# Smooth the centreline a little (Chaikin) for nicer banks.
	var pts := center
	var ws: Array = widths.duplicate()
	for _i in 2:
		var np := PackedVector2Array()
		var nw: Array = []
		np.append(pts[0])
		nw.append(ws[0])
		for i in pts.size() - 1:
			np.append(pts[i].lerp(pts[i + 1], 0.25))
			np.append(pts[i].lerp(pts[i + 1], 0.75))
			nw.append(lerpf(ws[i], ws[i + 1], 0.25))
			nw.append(lerpf(ws[i], ws[i + 1], 0.75))
		np.append(pts[pts.size() - 1])
		nw.append(ws[ws.size() - 1])
		pts = np
		ws = nw
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var d: Vector2
		if i == 0:
			d = pts[1] - pts[0]
		elif i == pts.size() - 1:
			d = pts[i] - pts[i - 1]
		else:
			d = pts[i + 1] - pts[i - 1]
		var n := Vector2(-d.y, d.x).normalized()
		var hw: float = ws[i] * 0.5
		left.append(pts[i] + n * hw)
		right.append(pts[i] - n * hw)
	right.reverse()
	left.append_array(right)
	return left


func _build_zones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + "_zones")
	for z in data.get("zones", []):
		var pos := project(z["lon"], z["lat"])
		zones.append(_make_zone(z["name"], pos, float(z["pop"]), float(z["jobs"]), float(z["r"]), "", rng))
	for p in data.get("pois", []):
		var pos := project(p["lon"], p["lat"])
		var poi := {"id": p["id"], "name_key": p["name_key"], "pos": pos, "kind": p["kind"]}
		pois.append(poi)
		var zp := _make_zone(p["name_key"], pos, 0.0, float(p.get("jobs", 50)), 0.5, p["id"], rng)
		zp["kind"] = p["kind"]
		zones.append(zp)


func _make_zone(zname: String, pos: Vector2, pop: float, jobs: float, r: float, poi_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var samples := PackedVector2Array()
	var tries := 0
	while samples.size() < SAMPLES_PER_ZONE and tries < 400:
		tries += 1
		# Gaussian-ish distribution: denser in the centre.
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * r * (0.6 + 0.6 * rng.randf())
		var s := pos + Vector2(cos(a), sin(a)) * d
		if s.x < 0 or s.y < 0 or s.x > size_km.x or s.y > size_km.y:
			continue
		if is_water(s):
			continue
		samples.append(s)
	if samples.is_empty():
		samples.append(pos)
	return {"name": zname, "pos": pos, "pop": pop, "jobs": jobs, "r": r, "samples": samples, "poi_id": poi_id,
			"base_pop": pop, "base_jobs": jobs}


func is_water(p: Vector2) -> bool:
	for rv in river_polys:
		if Geometry2D.is_point_in_polygon(p, rv):
			return true
	return is_sea(p)


func is_river(p: Vector2) -> bool:
	for rv in river_polys:
		if Geometry2D.is_point_in_polygon(p, rv):
			return true
	return false


## Open water (sea, strait, lake) — excludes small rivers.
func is_sea(p: Vector2) -> bool:
	for isl in island_polys:
		if Geometry2D.is_point_in_polygon(p, isl):
			return false
	for w in water_polys:
		if Geometry2D.is_point_in_polygon(p, w):
			return true
	return false


func is_park(p: Vector2) -> int:
	for i in park_polys.size():
		if Geometry2D.is_point_in_polygon(p, park_polys[i]):
			return i
	return -1


func in_bounds(p: Vector2) -> bool:
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= size_km.x and p.y <= size_km.y


func is_near_water(p: Vector2, radius: float) -> bool:
	if is_water(p):
		return true
	for i in 12:
		var a := TAU * i / 12.0
		for r in [radius * 0.5, radius]:
			if is_water(p + Vector2(cos(a), sin(a)) * r):
				return true
	return false


## Ground elevation in metres (negative under water = sea bed).
func elevation(p: Vector2) -> float:
	if is_water(p):
		return -32.0
	var e := base_elev
	for h in hills:
		var d2: float = (p - h["pos"]).length_squared()
		var r: float = h["r"]
		e += h["h"] * exp(-d2 / (r * r))
	e += _noise.get_noise_2d(p.x, p.y) * 25.0
	return max(e, 2.0 if base_elev < 100.0 else base_elev * 0.9)


## Which side of the dividing water body a point is on (0 = west/Europe, 1 = east/Asia).
func side_of(p: Vector2) -> int:
	if divide.size() < 2:
		return 0
	for i in divide.size() - 1:
		var a := divide[i]
		var b := divide[i + 1]
		var ymin: float = min(a.y, b.y)
		var ymax: float = max(a.y, b.y)
		if p.y >= ymin and p.y <= ymax:
			var t := 0.0 if is_equal_approx(a.y, b.y) else (p.y - a.y) / (b.y - a.y)
			var x := lerpf(a.x, b.x, t)
			return 1 if p.x > x else 0
	return 0


func total_population() -> float:
	var s := 0.0
	for z in zones:
		s += z["pop"]
	return s


func nearest_zone_name(p: Vector2) -> String:
	var best := ""
	var bd := INF
	for z in zones:
		if z["poi_id"] != "":
			continue
		var d: float = (z["pos"] - p).length() / max(0.6, z["r"] * 0.6)
		if d < bd:
			bd = d
			best = z["name"]
	return best


func nearest_poi(p: Vector2, max_d: float) -> Dictionary:
	var best := {}
	var bd := max_d
	for poi in pois:
		var d: float = (poi["pos"] - p).length()
		if d < bd:
			bd = d
			best = poi
	return best


## Annual growth of population and jobs.
func grow(years: float) -> void:
	for z in zones:
		var g := pow(1.016, years)
		z["pop"] = z["base_pop"] * g
		z["jobs"] = z["base_jobs"] * pow(1.02, years)


## Builds a heat-map image (RGBA8). kind: "pop" or "jobs".
func build_heat_image(kind: String) -> Image:
	var w := int(ceil(size_km.x / GRID_STEP))
	var h := int(ceil(size_km.y / GRID_STEP))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var vals := PackedFloat32Array()
	vals.resize(w * h)
	var vmax := 0.0
	for y in h:
		for x in w:
			var p := Vector2((x + 0.5) * GRID_STEP, (y + 0.5) * GRID_STEP)
			if is_water(p):
				vals[y * w + x] = -1.0
				continue
			var v := 0.0
			for z in zones:
				var amount: float = z["pop"] if kind == "pop" else z["jobs"]
				if amount <= 0.0:
					continue
				var r: float = max(0.6, z["r"]) * 0.8
				var d2: float = (p - z["pos"]).length_squared()
				v += amount / (r * r) * exp(-d2 / (r * r))
			vals[y * w + x] = v
			vmax = max(vmax, v)
	var c_lo := Color(1, 0.95, 0.4, 0.0)
	var c_mid := Color(1.0, 0.62, 0.15, 0.55) if kind == "pop" else Color(0.2, 0.75, 0.95, 0.55)
	var c_hi := Color(0.86, 0.12, 0.25, 0.8) if kind == "pop" else Color(0.45, 0.2, 0.9, 0.8)
	for y in h:
		for x in w:
			var v: float = vals[y * w + x]
			if v < 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var t := sqrt(v / maxf(vmax, 0.0001))
			var c: Color
			if t < 0.5:
				c = c_lo.lerp(c_mid, t * 2.0)
			else:
				c = c_mid.lerp(c_hi, (t - 0.5) * 2.0)
			img.set_pixel(x, y, c)
	return img
