class_name TechData
extends RefCounted
## Research projects ("Ar-Ge"). Effects are applied by GameState/TransitNetwork/DemandModel.
##
## effect keys:
##   opex: {mode|"all": mult}        vehicle operating cost multiplier
##   capacity: {mode: mult}          hourly capacity multiplier
##   cost_km_deep: mult              deep-tunnel cost multiplier
##   cost_station: mult              station cost multiplier
##   fare: mult                      fare income multiplier
##   mods: {...}                     demand modifiers (see CityEvents) incl. dwell, wait, transfer, sat

const ORDER: Array[String] = ["contactless", "realtime", "ac_fleet", "prefab", "electric_bus", "fast_ferry",
	"psd", "cbtc", "tbm2", "driverless"]

const TECH := {
	"contactless": {"cost": 350.0, "months": 2, "icon": "coin", "year": 2026,
		"effect": {"fare": 1.08, "mods": {"transfer": 0.7}}},
	"realtime": {"cost": 300.0, "months": 2, "icon": "info", "year": 2026,
		"effect": {"mods": {"wait": 0.8, "sat": 3.0}}},
	"ac_fleet": {"cost": 650.0, "months": 3, "icon": "smile", "year": 2026,
		"effect": {"mods": {"comfort": {"metro": 1.06, "tram": 1.08, "metrobus": 1.1, "rail": 1.06}, "sat": 3.0}}},
	"prefab": {"cost": 800.0, "months": 4, "icon": "build", "year": 2027,
		"effect": {"cost_station": 0.75}},
	"electric_bus": {"cost": 550.0, "months": 3, "icon": "train", "year": 2027,
		"effect": {"opex": {"metrobus": 0.7}, "mods": {"comfort": {"metrobus": 1.08}}}},
	"fast_ferry": {"cost": 600.0, "months": 4, "icon": "ff", "year": 2027,
		"effect": {"mods": {"speed": {"ferry": 1.3}}}},
	"psd": {"cost": 750.0, "months": 4, "icon": "check", "year": 2028,
		"effect": {"mods": {"dwell": 0.8, "sat": 4.0}}},
	"cbtc": {"cost": 1100.0, "months": 5, "icon": "lines", "year": 2028,
		"effect": {"capacity": {"metro": 1.25, "rail": 1.2}}},
	"tbm2": {"cost": 1200.0, "months": 6, "icon": "profile", "year": 2029,
		"effect": {"cost_km_deep": 0.8}},
	"driverless": {"cost": 1600.0, "months": 6, "icon": "train", "year": 2030, "requires": "cbtc",
		"effect": {"opex": {"metro": 0.65}, "capacity": {"metro": 1.15}, "mods": {"wait": 0.9}}},
}


static func get_tech(id: String) -> Dictionary:
	return TECH.get(id, {})


## Combined numeric effect of all researched techs for a key (e.g. "fare").
static func mult(done: Array, key: String) -> float:
	var m := 1.0
	for id in done:
		var e: Dictionary = TECH.get(id, {}).get("effect", {})
		if e.has(key) and not (e[key] is Dictionary):
			m *= float(e[key])
	return m


## Per-mode multiplier (with "all" fallback) for keys like "opex" / "capacity".
static func mode_mult(done: Array, key: String, mode: String) -> float:
	var m := 1.0
	for id in done:
		var e: Dictionary = TECH.get(id, {}).get("effect", {})
		if e.has(key) and e[key] is Dictionary:
			m *= float(e[key].get(mode, e[key].get("all", 1.0)))
	return m


static func demand_mods(done: Array) -> Dictionary:
	var mods := {}
	for id in done:
		var e: Dictionary = TECH.get(id, {}).get("effect", {})
		if e.has("mods"):
			var add: Dictionary = e["mods"].duplicate(true)
			# "sat" is additive: keep it separate from multiplicative combine
			var sat: float = add.get("sat", 0.0)
			add.erase("sat")
			mods = CityEvents.combine(mods, add)
			mods["sat_add"] = float(mods.get("sat_add", 0.0)) + sat
	return mods
