class_name RealEvents
extends RefCounted
## Real-world dated events (summits, finals, festivals, disasters) for each city.
## Each one is announced `lead` months in advance so the player can prepare:
## a venue served by an operational station (within SERVE_KM) when the event starts
## brings money and goodwill; failing to serve it costs approval and votes.
##
## Fields:
##   id, city ("*" = every city), y, m (0-based month), lead (months of notice),
##   months (duration), venue [lon, lat] (optional), crowd (extra daily trip ends
##   at the venue while it runs), need_serve, reward (share of the annual grant),
##   mods (demand modifiers while active, see CityEvents), fx (map effect kind),
##   yearly (repeats every year from the city's start), quake (triggers damage).

const SERVE_KM := 1.2

const LIST := [
	# ---------------------------------------------------------------- İstanbul
	{"id": "ist_ecoc", "city": "istanbul", "y": 2010, "m": 2, "lead": 2, "months": 9, "venue": [28.977, 41.006],
		"crowd": 60, "need_serve": false, "mods": {"kind": {"landmark": 1.3}, "demand": 1.03}, "fx": "culture"},
	{"id": "ist_marathon", "city": "istanbul", "y": 2010, "m": 10, "lead": 1, "months": 1, "yearly": true,
		"venue": [29.025, 41.045], "crowd": 40, "need_serve": false, "mods": {"car": 1.45}, "fx": "closure"},
	{"id": "ist_ucl", "city": "istanbul", "y": 2023, "m": 5, "lead": 18, "months": 1, "venue": [28.766, 41.075],
		"crowd": 260, "need_serve": true, "reward": 0.22, "mods": {"car": 1.25}, "fx": "stadium"},
	# ---------------------------------------------------------------- Ankara
	{"id": "ank_centenary", "city": "ankara", "y": 2023, "m": 9, "lead": 12, "months": 1, "venue": [32.854, 39.920],
		"crowd": 220, "need_serve": true, "reward": 0.18, "mods": {"car": 1.3, "kind": {"landmark": 1.5}}, "fx": "celebration"},
	{"id": "ank_nato", "city": "ankara", "y": 2026, "m": 6, "lead": 18, "months": 1, "venue": [32.806, 39.910],
		"crowd": 170, "need_serve": true, "reward": 0.25, "mods": {"car": 1.55}, "fx": "summit"},
	# ---------------------------------------------------------------- İzmir
	{"id": "izm_quake", "city": "izmir", "y": 2020, "m": 9, "lead": 0, "months": 2, "quake": true,
		"need_serve": false, "mods": {"demand": 0.9}, "fx": ""},
	# ---------------------------------------------------------------- Eskişehir
	{"id": "esk_turkic", "city": "eskisehir", "y": 2013, "m": 0, "lead": 9, "months": 12, "venue": [30.523, 39.763],
		"crowd": 60, "need_serve": true, "reward": 0.2, "mods": {"kind": {"landmark": 1.3}}, "fx": "culture"},
	# ---------------------------------------------------------------- Antalya
	{"id": "ant_g20", "city": "antalya", "y": 2015, "m": 10, "lead": 12, "months": 1, "venue": [30.875, 36.857],
		"crowd": 110, "need_serve": true, "reward": 0.22, "mods": {"car": 1.45}, "fx": "summit"},
	{"id": "ant_expo", "city": "antalya", "y": 2016, "m": 3, "lead": 18, "months": 6, "venue": [30.862, 36.952],
		"crowd": 130, "need_serve": true, "reward": 0.3, "mods": {"kind": {"landmark": 1.1}}, "fx": "culture"},
	{"id": "ant_cop31", "city": "antalya", "y": 2026, "m": 10, "lead": 18, "months": 1, "venue": [30.862, 36.952],
		"crowd": 180, "need_serve": true, "reward": 0.28, "mods": {"car": 1.4}, "fx": "summit"},
	# ---------------------------------------------------------------- Bursa
	{"id": "bur_turkic", "city": "bursa", "y": 2022, "m": 0, "lead": 12, "months": 12, "venue": [29.060, 40.184],
		"crowd": 60, "need_serve": true, "reward": 0.2, "mods": {"kind": {"landmark": 1.3}}, "fx": "culture"},
	# ---------------------------------------------------------------- Trabzon
	{"id": "trb_eyof", "city": "trabzon", "y": 2011, "m": 6, "lead": 18, "months": 1, "venue": [39.728, 40.999],
		"crowd": 60, "need_serve": true, "reward": 0.3, "mods": {"car": 1.2}, "fx": "stadium"},
	# ---------------------------------------------------------------- everywhere
	{"id": "covid", "city": "*", "y": 2020, "m": 2, "lead": 0, "months": 15, "need_serve": false,
		"mods": {"demand": 0.55, "car": 0.85}, "fx": "empty"},
]

## Stadiums used by the random derby event for its map effects.
const STADIUMS := {
	"istanbul": [[29.037, 40.988], [28.991, 41.103], [29.002, 41.039]],
	"ankara": [[32.646, 39.972]],
	"izmir": [[27.077, 38.399]],
	"trabzon": [[39.678, 40.997]],
	"bursa": [[29.007, 40.230]],
}


static func get_event(id: String) -> Dictionary:
	for e in LIST:
		if e["id"] == id:
			return e
	return {}


static func for_city(city_id: String) -> Array:
	return LIST.filter(func(e): return e["city"] == city_id or e["city"] == "*")


## Absolute month index (year*12 + month) of an event occurrence on or after `from_t`.
static func occurrence(e: Dictionary, from_t: int) -> int:
	var t := int(e["y"]) * 12 + int(e["m"])
	if e.get("yearly", false):
		while t < from_t:
			t += 12
	return t


## Occurrence key used to remember what has already happened (yearly events repeat).
static func key(e: Dictionary, t: int) -> String:
	return "%s@%d" % [e["id"], t / 12] if e.get("yearly", false) else str(e["id"])


static func mods_of(active_id: String) -> Dictionary:
	var e := get_event(active_id.trim_prefix("re_"))
	return e.get("mods", {})
