class_name ScenarioData
extends RefCounted
## Hand-made scenarios (historic / themed challenges with a deadline) and the
## procedurally generated weekly challenge.

const LIST := [
	{"id": "ist_1989", "city": "istanbul", "start_year": 1989, "years": 6, "cash": 7000.0, "grant_mult": 0.75,
	 "allowed": ["metro", "tram", "rail", "ferry", "funicular"],
	 "objectives": [
		{"id": "s_taksim_maslak", "type": "serve_pois", "pois": ["taksim", "maslak"]},
		{"id": "s_riders_150k", "type": "riders", "value": 150000}]},
	{"id": "ist_bosphorus", "city": "istanbul", "start_year": 2004, "years": 6, "cash": 11000.0, "grant_mult": 1.0,
	 "prebuilt": [["metro", false, [[28.977, 41.036], [28.987, 41.062], [29.012, 41.080], [29.02, 41.11]]],
				  ["tram", false, [[28.905, 41.04], [28.93, 41.02], [28.95, 41.012], [28.975, 41.006]]]],
	 "objectives": [
		{"id": "cross_bosphorus", "type": "cross_sides"},
		{"id": "s_riders_500k", "type": "riders", "value": 500000}]},
	{"id": "ank_campus", "city": "ankara", "start_year": 2010, "years": 4, "cash": 6000.0, "grant_mult": 0.9,
	 "prebuilt": [["metro", false, [[32.73, 39.965], [32.80, 39.968], [32.855, 39.942], [32.854, 39.920]]]],
	 "objectives": [
		{"id": "universities", "type": "serve_pois", "pois": ["odtu", "bilkent", "hacettepe"]},
		{"id": "s_riders_150k", "type": "riders", "value": 150000}]},
	{"id": "izm_gulf", "city": "izmir", "start_year": 2012, "years": 4, "cash": 6000.0, "grant_mult": 0.9,
	 "allowed": ["ferry", "tram", "metro"],
	 "objectives": [
		{"id": "s_ferry_15k", "type": "mode_riders", "mode": "ferry", "value": 15000},
		{"id": "s_riders_120k", "type": "riders", "value": 120000}]},
	{"id": "esk_tram", "city": "eskisehir", "start_year": 2004, "years": 5, "cash": 3500.0, "grant_mult": 1.0,
	 "allowed": ["tram"],
	 "objectives": [
		{"id": "s_tram_50k", "type": "mode_riders", "mode": "tram", "value": 50000},
		{"id": "coverage_45", "type": "coverage", "value": 0.45}]},
	{"id": "trb_boztepe", "city": "trabzon", "start_year": 2021, "years": 3, "cash": 3000.0, "grant_mult": 1.0,
	 "objectives": [
		{"id": "boztepe", "type": "serve_pois", "pois": ["boztepe"]},
		{"id": "s_gondola_1k", "type": "mode_riders", "mode": "gondola", "value": 1000},
		{"id": "s_riders_20k", "type": "riders", "value": 20000}]},
	{"id": "ant_season", "city": "antalya", "start_year": 2024, "years": 3, "cash": 5500.0, "grant_mult": 1.0,
	 "objectives": [
		{"id": "s_ant_all", "type": "serve_pois", "pois": ["ayt", "lara_beach", "konyaalti_beach"]},
		{"id": "s_riders_80k", "type": "riders", "value": 80000}]},
	{"id": "bur_industry", "city": "bursa", "start_year": 2015, "years": 5, "cash": 5500.0, "grant_mult": 1.0,
	 "objectives": [
		{"id": "uni_bursa", "type": "serve_pois", "pois": ["uludag_uni"]},
		{"id": "s_gondola_2k", "type": "mode_riders", "mode": "gondola", "value": 2000},
		{"id": "s_riders_120k", "type": "riders", "value": 120000}]},
]

const WEEKLY_MODS := ["budget_low", "no_metro", "strong_union", "cheap_fares", "boom", "rival", "rich", "old_fleet"]


static func get_scenario(id: String) -> Dictionary:
	for s in LIST:
		if s["id"] == id:
			return s
	return {}


static func lonlat_pts(st: GameState, pts: Array) -> Array:
	var nodes: Array = []
	for ll in pts:
		var p := st.city.project(ll[0], ll[1])
		var sid := st.net.station_at(p, 0.4)
		nodes.append({"pos": p if sid < 0 else st.net.stations[sid]["pos"], "sid": sid})
	return nodes


static func create(id: String) -> GameState:
	var sc := get_scenario(id)
	var st := GameState.new(sc["city"])
	st.scenario = sc.duplicate(true)
	st.scenario["kind"] = "scenario"
	st.start_year = int(sc["start_year"])
	st.year = st.start_year
	st.cash = float(sc["cash"])
	st.grant_mult = float(sc.get("grant_mult", 1.0))
	st.tutorial_step = 6
	for pb in sc.get("prebuilt", []):
		var nodes := lonlat_pts(st, pb[2])
		var lid := st.net.commit_draft(pb[0], pb[1], nodes, 0.0)
		st.net.lines[lid]["vehicles"] = 8
		st.log_line(lid)
	st._update_mods()
	return st


## ISO-ish week key, e.g. 202647.
static func week_key() -> int:
	var d := Time.get_datetime_dict_from_system()
	var doy := int(Time.get_unix_time_from_system() / 86400.0) - int(Time.get_unix_time_from_datetime_dict({"year": d["year"], "month": 1, "day": 1}) / 86400.0)
	return int(d["year"]) * 100 + doy / 7 + 1


static func weekly_spec(key: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = key * 7919
	var cities: Array = CityData.CITY_IDS.duplicate()
	var city: String = cities[rng.randi() % cities.size()]
	var mods: Array = WEEKLY_MODS.duplicate()
	var picked: Array = []
	for i in 2:
		var k: String = mods[rng.randi() % mods.size()]
		mods.erase(k)
		picked.append(k)
	return {"id": "weekly", "kind": "weekly", "week": key, "city": city, "years": 3, "start_year": 2026,
		"mods": picked, "objectives": []}


static func create_weekly() -> GameState:
	var spec := weekly_spec(week_key())
	var st := GameState.new(spec["city"])
	st.scenario = spec
	st.tutorial_step = 6
	for k in spec["mods"]:
		match k:
			"budget_low": st.cash *= 0.6
			"rich":
				st.cash *= 1.6
				st.grant_mult = 0.7
			"no_metro": st.scenario["allowed"] = TransitModes.ORDER.filter(func(m): return m != "metro")
			"strong_union": st.mgmt.wage = 1.2
			"cheap_fares": st.mgmt.fare_cap = {"mult": 0.8, "months": 36}
			"boom": st.mgmt.timed.append({"id": "boom", "mods": {"demand": 1.2}, "months": 999})
			"rival": st.mgmt.timed.append({"id": "rival", "mods": {"car": 0.86}, "months": 12})
			"old_fleet": st.scenario["old_fleet"] = true
	st._update_mods()
	return st


## Stars for finishing a scenario based on the share of time left.
static func stars_for(st: GameState) -> int:
	var total := float(st.scenario.get("years", 1)) * 12.0
	var used := float(st.year - st.start_year) * 12.0 + st.month
	var left := 1.0 - used / maxf(1.0, total)
	if left > 0.4:
		return 3
	if left > 0.15:
		return 2
	return 1
