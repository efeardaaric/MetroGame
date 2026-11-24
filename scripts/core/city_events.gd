class_name CityEvents
extends RefCounted
## City-specific seasons and random events, expressed as demand modifiers.
##
## A modifier dictionary may contain:
##   car: float             – multiplier on car travel time (higher = rail more attractive)
##   speed: {mode: float}   – vehicle speed multiplier per mode
##   comfort: {mode: float} – perceived comfort per mode (higher = more attractive)
##   poi: {poi_id: float}   – attraction multiplier for a POI
##   kind: {poi_kind: float}– attraction multiplier for POI kinds
##   demand: float          – overall trip generation multiplier

const EVENTS := {
	"bridge_traffic": {"chance": 0.09, "months": 1, "mods": {"car": 1.35}, "post": "ev_bridge_traffic", "icon": "warning"},
	"derby": {"chance": 0.06, "months": 1, "mods": {"demand": 1.06}, "post": "ev_derby", "icon": "people"},
	"rain": {"chance": 0.07, "months": 1, "mods": {"car": 1.15, "speed": {"tram": 0.9, "metrobus": 0.9}}, "post": "ev_rain", "icon": "info"},
	"concert": {"chance": 0.05, "months": 1, "mods": {"kind": {"landmark": 1.5}}, "post": "ev_concert", "icon": "people"},
	"snow_storm": {"chance": 0.45, "months": 1, "winter_only": true,
		"mods": {"car": 1.45, "speed": {"tram": 0.6, "metrobus": 0.55, "rail": 0.85}}, "post": "ev_snow", "icon": "warning"},
	"imbat": {"chance": 0.35, "months": 1, "summer_only": true, "mods": {"comfort": {"ferry": 1.2}}, "post": "ev_imbat", "icon": "info"},
}


static func flavor(city: CityMap) -> Dictionary:
	return city.data.get("flavor", {})


static func is_winter(city: CityMap, month: int) -> bool:
	return flavor(city).get("winter_months", []).has(month)


static func is_summer(city: CityMap, month: int) -> bool:
	return flavor(city).get("summer_months", []).has(month)


## Seasonal modifiers that always apply for this city & month.
static func seasonal_mods(city: CityMap, month: int) -> Dictionary:
	var f := flavor(city)
	var mods := {}
	if f.has("comfort"):
		mods = combine(mods, {"comfort": f["comfort"]})
	if is_winter(city, month):
		# winter: icy roads, trams/buses a bit slower, metro relatively better
		mods = combine(mods, {"car": 1.15, "speed": {"tram": 0.85, "metrobus": 0.85}})
	var uni: Array = f.get("university_pois", [])
	if not uni.is_empty():
		var m := 0.35 if month in [6, 7] else (1.35 if month in [8, 9] else 1.0)
		var poi := {}
		for pid in uni:
			poi[pid] = m
		mods = combine(mods, {"poi": poi})
	if is_summer(city, month):
		mods = combine(mods, {"comfort": {"ferry": 1.25}, "kind": {"landmark": 1.3}})
	if f.has("fair_month") and month == int(f["fair_month"]):
		mods = combine(mods, {"poi": {f["fair_poi"]: 3.0}})
	return mods


## Rolls new random events for the month. Returns array of event ids.
static func roll_events(city: CityMap, month: int, rng: RandomNumberGenerator, active: Array) -> Array:
	var out: Array = []
	var active_ids: Array = []
	for a in active:
		active_ids.append(a["id"])
	for eid in flavor(city).get("events", []):
		if not EVENTS.has(eid) or active_ids.has(eid):
			continue
		var ev: Dictionary = EVENTS[eid]
		if ev.get("winter_only", false) and not is_winter(city, month):
			continue
		if ev.get("summer_only", false) and not is_summer(city, month):
			continue
		if rng.randf() < ev["chance"]:
			out.append(eid)
	return out


static func event_mods(active: Array) -> Dictionary:
	var mods := {}
	for a in active:
		if EVENTS.has(a["id"]):
			mods = combine(mods, EVENTS[a["id"]]["mods"])
	return mods


static func combine(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate(true)
	for k in b.keys():
		if b[k] is Dictionary:
			var sub: Dictionary = out.get(k, {})
			for kk in b[k].keys():
				sub[kk] = float(sub.get(kk, 1.0)) * float(b[k][kk])
			out[k] = sub
		else:
			out[k] = float(out.get(k, 1.0)) * float(b[k])
	return out


## True if a point lies in a historic (archaeologically sensitive) zone.
static func in_historic_zone(city: CityMap, p: Vector2) -> bool:
	for h in flavor(city).get("historic", []):
		if city.project(h["lon"], h["lat"]).distance_to(p) <= float(h["r"]):
			return true
	return false
