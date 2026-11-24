class_name TransitModes
extends RefCounted
## Definitions of the six vehicle / infrastructure types.
## Money is in million ₺ (M₺). Distances in km, speeds in km/h.

const ORDER: Array[String] = ["metro", "tram", "metrobus", "rail", "funicular", "gondola", "ferry"]

const MODES := {
	"metro": {
		"name_key": "mode_metro", "desc_key": "mode_metro_desc", "icon": "M",
		"speed": 36.0, "capacity": 1200, "dwell_min": 0.5,
		"cost_km": 170.0, "cost_km_deep": 260.0, "cost_station": 90.0,
		"vehicle_cost": 55.0, "vehicle_opex": 7.0, "km_opex": 2.2,
		"underground": true, "surface": false, "water": "tunnel",
		"max_grade": 0.05, "min_spacing": 0.6, "max_stations": 40, "max_length": 0.0,
		"default_vehicles": 4, "max_vehicles": 40, "width": 9.0, "comfort": 1.0,
	},
	"tram": {
		"name_key": "mode_tram", "desc_key": "mode_tram_desc", "icon": "T",
		"speed": 18.0, "capacity": 300, "dwell_min": 0.4,
		"cost_km": 45.0, "cost_km_deep": 45.0, "cost_station": 6.0,
		"vehicle_cost": 14.0, "vehicle_opex": 2.0, "km_opex": 0.7,
		"underground": false, "surface": true, "water": "bridge",
		"max_grade": 0.07, "min_spacing": 0.3, "max_stations": 40, "max_length": 0.0,
		"default_vehicles": 4, "max_vehicles": 40, "width": 6.0, "comfort": 0.95,
	},
	"metrobus": {
		"name_key": "mode_metrobus", "desc_key": "mode_metrobus_desc", "icon": "B",
		"speed": 26.0, "capacity": 160, "dwell_min": 0.3,
		"cost_km": 18.0, "cost_km_deep": 18.0, "cost_station": 3.0,
		"vehicle_cost": 3.5, "vehicle_opex": 1.1, "km_opex": 0.5,
		"underground": false, "surface": true, "water": "bridge",
		"max_grade": 0.09, "min_spacing": 0.5, "max_stations": 50, "max_length": 0.0,
		"default_vehicles": 8, "max_vehicles": 80, "width": 6.0, "comfort": 0.8,
	},
	"rail": {
		"name_key": "mode_rail", "desc_key": "mode_rail_desc", "icon": "R",
		"speed": 48.0, "capacity": 1600, "dwell_min": 0.8,
		"cost_km": 75.0, "cost_km_deep": 75.0, "cost_station": 30.0,
		"vehicle_cost": 60.0, "vehicle_opex": 7.5, "km_opex": 1.2,
		"underground": false, "surface": true, "water": "bridge",
		"max_grade": 0.035, "min_spacing": 1.5, "max_stations": 40, "max_length": 0.0,
		"default_vehicles": 4, "max_vehicles": 30, "width": 8.0, "comfort": 0.95,
	},
	"funicular": {
		"name_key": "mode_funicular", "desc_key": "mode_funicular_desc", "icon": "F",
		"speed": 14.0, "capacity": 260, "dwell_min": 0.7,
		"cost_km": 110.0, "cost_km_deep": 110.0, "cost_station": 12.0,
		"vehicle_cost": 10.0, "vehicle_opex": 1.2, "km_opex": 0.8,
		"underground": false, "surface": true, "water": "none",
		"max_grade": 1.0, "min_spacing": 0.2, "max_stations": 2, "max_length": 3.0,
		"default_vehicles": 2, "max_vehicles": 2, "width": 5.0, "comfort": 1.0,
	},
	"gondola": {
		"name_key": "mode_gondola", "desc_key": "mode_gondola_desc", "icon": "G",
		"speed": 18.0, "capacity": 240, "dwell_min": 0.6,
		"cost_km": 55.0, "cost_km_deep": 55.0, "cost_station": 18.0,
		"vehicle_cost": 4.0, "vehicle_opex": 0.6, "km_opex": 0.6,
		"underground": false, "surface": true, "water": "any",
		"max_grade": 3.0, "min_spacing": 0.3, "max_stations": 3, "max_length": 10.0,
		"default_vehicles": 8, "max_vehicles": 30, "width": 4.0, "comfort": 1.15,
	},
	"ferry": {
		"name_key": "mode_ferry", "desc_key": "mode_ferry_desc", "icon": "V",
		"speed": 24.0, "capacity": 900, "dwell_min": 3.0,
		"cost_km": 0.0, "cost_km_deep": 0.0, "cost_station": 20.0,
		"vehicle_cost": 35.0, "vehicle_opex": 4.0, "km_opex": 0.0,
		"underground": false, "surface": true, "water": "only",
		"max_grade": 1.0, "min_spacing": 0.8, "max_stations": 8, "max_length": 0.0,
		"default_vehicles": 2, "max_vehicles": 16, "width": 5.0, "comfort": 1.05,
	},
}

const LINE_COLORS: Array[Color] = [
	Color("e63946"), Color("1d72d8"), Color("2a9d8f"), Color("f4a100"), Color("8e44ad"),
	Color("e76f51"), Color("00a8e8"), Color("43aa8b"), Color("d81b60"), Color("6d4c41"),
	Color("f15bb5"), Color("3a86ff"), Color("8ac926"), Color("ff7b00"), Color("5e60ce"),
]

const BRIDGE_COST_KM := 140.0       # extra cost for surface modes crossing water
const MAX_BRIDGE_KM := 1.8          # longest bridge allowed
const DEEP_TUNNEL_DEPTH := 38.0     # metres below ground / sea bed
const SHALLOW_TUNNEL_DEPTH := 14.0


static func get_mode(id: String) -> Dictionary:
	return MODES.get(id, MODES["metro"])


static func mode_prefix(id: String) -> String:
	match id:
		"metro": return "M"
		"tram": return "T"
		"metrobus": return "MB"
		"rail": return "B"
		"funicular": return "F"
		"ferry": return "V"
		"gondola": return "TF"
	return "L"
