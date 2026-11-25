class_name CityData
extends RefCounted
## Static, hand-authored geography for the playable cities.
## Coordinates are WGS84 (lon, lat). They are simplified/stylised outlines,
## projected to kilometres at runtime by CityMap.
##
## Zone fields: name, lon, lat, pop (thousand residents), jobs (attraction index,
## thousand daily trip ends), r (approx. radius km).
## POI fields: id, name_key, lon, lat, kind (airport/university/landmark/terminal/business).

const CITY_IDS: Array[String] = ["istanbul", "ankara", "izmir", "eskisehir", "antalya", "bursa", "trabzon"]


static func get_city(id: String) -> Dictionary:
	match id:
		"istanbul":
			return _istanbul()
		"ankara":
			return _ankara()
		"izmir":
			return _izmir()
		"eskisehir":
			return _eskisehir()
		"antalya":
			return _antalya()
		"bursa":
			return _bursa()
		"trabzon":
			return _trabzon()
	return _istanbul()


static func _istanbul() -> Dictionary:
	return {
		"id": "istanbul",
		"name_key": "city_istanbul",
		"subtitle_key": "city_istanbul_sub",
		"bounds": [28.55, 40.78, 29.45, 41.30], # lon_min, lat_min, lon_max, lat_max
		"start_cash": 12000.0,
		"annual_grant": 3600.0,
		"demand_scale": 1.05,
		"difficulty": 3,
		"unlock_stars": 0,
		"base_elev": 40.0,
		"accent": Color("e63946"),
		# Seas: closed polygons (lon, lat)
		"water_polys": [
			# Black Sea
			[[28.55, 41.285], [28.80, 41.272], [28.95, 41.262], [29.03, 41.252], [29.085, 41.238],
			 [29.12, 41.226], [29.165, 41.222], [29.25, 41.202], [29.35, 41.192], [29.45, 41.18],
			 [29.45, 41.31], [28.55, 41.31]],
			# Sea of Marmara
			[[29.003, 41.014], [28.985, 41.006], [28.95, 41.001], [28.92, 40.994], [28.89, 40.981],
			 [28.865, 40.974], [28.84, 40.962], [28.81, 40.957], [28.785, 40.968], [28.75, 40.979],
			 [28.72, 40.977], [28.68, 40.990], [28.64, 41.000], [28.60, 41.010], [28.55, 41.020],
			 [28.55, 40.77], [29.45, 40.77], [29.45, 40.800], [29.38, 40.808], [29.30, 40.818],
			 [29.25, 40.860], [29.20, 40.880], [29.15, 40.903], [29.11, 40.930], [29.08, 40.953],
			 [29.05, 40.964], [29.035, 40.975], [29.026, 40.985], [29.022, 40.996], [29.012, 41.003]],
		],
		# Channels: centreline + widths in km (Bosphorus, Golden Horn)
		"channels": [
			{"pts": [[29.125, 41.232], [29.075, 41.195], [29.057, 41.167], [29.062, 41.140],
					 [29.066, 41.116], [29.061, 41.096], [29.058, 41.080], [29.044, 41.068],
					 [29.033, 41.054], [29.019, 41.040], [29.006, 41.026], [28.998, 41.008]],
			 "w": [3.2, 1.6, 1.5, 1.8, 1.4, 1.0, 0.8, 0.85, 0.95, 1.1, 1.5, 2.4]},
			{"pts": [[28.982, 41.016], [28.968, 41.024], [28.957, 41.032], [28.946, 41.041], [28.935, 41.048]],
			 "w": [0.55, 0.45, 0.38, 0.30, 0.18]},
		],
		"lakes": [
			{"lon": 28.765, "lat": 41.010, "rx": 1.6, "ry": 2.6, "rot": 0.3},
			{"lon": 28.585, "lat": 41.050, "rx": 2.0, "ry": 3.2, "rot": -0.2},
			{"lon": 28.84, "lat": 41.215, "rx": 1.2, "ry": 1.8, "rot": 0.0}, # Alibeyköy/Kemerburgaz reservoirs (stylised)
		],
		"islands": [
			{"lon": 29.120, "lat": 40.858, "rx": 1.4, "ry": 2.0, "rot": 0.2},
			{"lon": 29.094, "lat": 40.877, "rx": 0.9, "ry": 1.0, "rot": 0.0},
			{"lon": 29.071, "lat": 40.890, "rx": 0.6, "ry": 0.7, "rot": 0.0},
			{"lon": 29.050, "lat": 40.907, "rx": 0.45, "ry": 0.5, "rot": 0.0},
		],
		# Hills: gaussian bumps for elevation (metres)
		"hills": [
			{"lon": 29.06, "lat": 41.03, "h": 230.0, "r": 3.0},  # Çamlıca
			{"lon": 29.01, "lat": 41.10, "h": 140.0, "r": 4.5},
			{"lon": 28.98, "lat": 41.04, "h": 90.0, "r": 2.0},   # Beyoğlu / Taksim ridge
			{"lon": 28.80, "lat": 41.10, "h": 120.0, "r": 7.0},
			{"lon": 29.18, "lat": 41.05, "h": 160.0, "r": 6.0},
			{"lon": 29.21, "lat": 40.95, "h": 260.0, "r": 4.0},  # Aydos
			{"lon": 28.95, "lat": 41.20, "h": 180.0, "r": 8.0},  # Belgrad forest
			{"lon": 29.30, "lat": 41.12, "h": 200.0, "r": 9.0},
		],
		# Protected forest areas: no stations allowed (cheap tunnels only)
		"parks": [
			{"lon": 28.97, "lat": 41.19, "rx": 6.0, "ry": 3.5, "rot": 0.2, "name_key": "park_belgrad"},
			{"lon": 29.32, "lat": 41.10, "rx": 5.5, "ry": 3.0, "rot": -0.1, "name_key": "park_omerli"},
		],
		"zones": [
			{"name": "Fatih", "lon": 28.948, "lat": 41.014, "pop": 370, "jobs": 520, "r": 2.2},
			{"name": "Beyoğlu", "lon": 28.977, "lat": 41.036, "pop": 230, "jobs": 430, "r": 1.6},
			{"name": "Beşiktaş", "lon": 29.004, "lat": 41.046, "pop": 175, "jobs": 330, "r": 1.6},
			{"name": "Levent", "lon": 29.012, "lat": 41.080, "pop": 60, "jobs": 520, "r": 1.4},
			{"name": "Şişli", "lon": 28.987, "lat": 41.062, "pop": 270, "jobs": 470, "r": 1.7},
			{"name": "Sarıyer", "lon": 29.035, "lat": 41.150, "pop": 340, "jobs": 140, "r": 3.2},
			{"name": "Kağıthane", "lon": 28.970, "lat": 41.083, "pop": 450, "jobs": 170, "r": 1.9},
			{"name": "Eyüpsultan", "lon": 28.925, "lat": 41.070, "pop": 400, "jobs": 110, "r": 2.6},
			{"name": "Gaziosmanpaşa", "lon": 28.905, "lat": 41.062, "pop": 490, "jobs": 90, "r": 1.5},
			{"name": "Sultangazi", "lon": 28.870, "lat": 41.105, "pop": 540, "jobs": 70, "r": 2.0},
			{"name": "Esenler", "lon": 28.877, "lat": 41.040, "pop": 440, "jobs": 110, "r": 1.4},
			{"name": "Bayrampaşa", "lon": 28.910, "lat": 41.042, "pop": 270, "jobs": 120, "r": 1.2},
			{"name": "Zeytinburnu", "lon": 28.905, "lat": 40.993, "pop": 290, "jobs": 150, "r": 1.3},
			{"name": "Bakırköy", "lon": 28.868, "lat": 40.980, "pop": 220, "jobs": 230, "r": 1.7},
			{"name": "Bahçelievler", "lon": 28.857, "lat": 41.000, "pop": 590, "jobs": 140, "r": 1.4},
			{"name": "Güngören", "lon": 28.878, "lat": 41.020, "pop": 290, "jobs": 90, "r": 1.0},
			{"name": "Bağcılar", "lon": 28.845, "lat": 41.036, "pop": 730, "jobs": 160, "r": 1.7},
			{"name": "Küçükçekmece", "lon": 28.790, "lat": 41.000, "pop": 790, "jobs": 180, "r": 2.6},
			{"name": "Başakşehir", "lon": 28.800, "lat": 41.093, "pop": 500, "jobs": 160, "r": 3.0},
			{"name": "Avcılar", "lon": 28.720, "lat": 40.985, "pop": 450, "jobs": 110, "r": 1.8},
			{"name": "Esenyurt", "lon": 28.672, "lat": 41.032, "pop": 980, "jobs": 170, "r": 2.6},
			{"name": "Beylikdüzü", "lon": 28.640, "lat": 40.995, "pop": 400, "jobs": 130, "r": 1.9},
			{"name": "Büyükçekmece", "lon": 28.590, "lat": 41.020, "pop": 270, "jobs": 70, "r": 2.2},
			{"name": "Arnavutköy", "lon": 28.740, "lat": 41.180, "pop": 340, "jobs": 60, "r": 4.0},
			{"name": "Üsküdar", "lon": 29.030, "lat": 41.024, "pop": 520, "jobs": 260, "r": 2.0},
			{"name": "Kadıköy", "lon": 29.040, "lat": 40.990, "pop": 480, "jobs": 380, "r": 1.9},
			{"name": "Ataşehir", "lon": 29.112, "lat": 40.992, "pop": 420, "jobs": 330, "r": 1.7},
			{"name": "Ümraniye", "lon": 29.115, "lat": 41.025, "pop": 720, "jobs": 230, "r": 2.2},
			{"name": "Çekmeköy", "lon": 29.180, "lat": 41.035, "pop": 290, "jobs": 50, "r": 2.2},
			{"name": "Sancaktepe", "lon": 29.230, "lat": 41.000, "pop": 470, "jobs": 70, "r": 2.2},
			{"name": "Maltepe", "lon": 29.130, "lat": 40.937, "pop": 520, "jobs": 150, "r": 1.8},
			{"name": "Kartal", "lon": 29.190, "lat": 40.900, "pop": 470, "jobs": 160, "r": 1.8},
			{"name": "Pendik", "lon": 29.260, "lat": 40.880, "pop": 740, "jobs": 180, "r": 2.4},
			{"name": "Tuzla", "lon": 29.300, "lat": 40.835, "pop": 280, "jobs": 200, "r": 2.2},
			{"name": "Sultanbeyli", "lon": 29.270, "lat": 40.963, "pop": 330, "jobs": 50, "r": 1.6},
			{"name": "Beykoz", "lon": 29.100, "lat": 41.130, "pop": 250, "jobs": 60, "r": 3.0},
		],
		"pois": [
			{"id": "ist_airport", "name_key": "poi_ist_airport", "lon": 28.742, "lat": 41.262, "kind": "airport", "jobs": 260},
			{"id": "saw_airport", "name_key": "poi_saw_airport", "lon": 29.309, "lat": 40.900, "kind": "airport", "jobs": 140},
			{"id": "sultanahmet", "name_key": "poi_sultanahmet", "lon": 28.977, "lat": 41.006, "kind": "landmark", "jobs": 160},
			{"id": "taksim", "name_key": "poi_taksim", "lon": 28.986, "lat": 41.037, "kind": "landmark", "jobs": 150},
			{"id": "maslak", "name_key": "poi_maslak", "lon": 29.020, "lat": 41.112, "kind": "business", "jobs": 230},
			{"id": "itu", "name_key": "poi_itu", "lon": 29.023, "lat": 41.104, "kind": "university", "jobs": 70},
			{"id": "bogazici", "name_key": "poi_bogazici", "lon": 29.050, "lat": 41.084, "kind": "university", "jobs": 50},
			{"id": "otogar", "name_key": "poi_otogar", "lon": 28.894, "lat": 41.039, "kind": "terminal", "jobs": 90},
			{"id": "finance", "name_key": "poi_finance", "lon": 29.104, "lat": 40.996, "kind": "business", "jobs": 160},
		],
		"flavor": {
			"birds": [{"kind": "gull", "count": 18}],
			"ambience": ["sea", "city"],
			"ferry_horn": true,
			"comfort": {"ferry": 1.2},
			"historic": [{"lon": 28.962, "lat": 41.010, "r": 2.6}],
			"decor": [
				{"kind": "tower", "lon": 28.9741, "lat": 41.0256, "name_key": "decor_galata"},
				{"kind": "islet_tower", "lon": 29.0041, "lat": 41.0211, "name_key": "decor_kizkulesi"},
				{"kind": "fortress", "lon": 29.0515, "lat": 41.085, "name_key": "decor_rumelihisari"},
				{"kind": "mosque", "lon": 28.9768, "lat": 41.0054, "name_key": "decor_sultanahmet"},
			],
			"bridges": [
				{"a": [29.013, 41.0475], "b": [29.036, 41.0425], "name_key": "bridge_15temmuz"},
				{"a": [29.049, 41.0915], "b": [29.071, 41.0885], "name_key": "bridge_fsm"},
				{"a": [29.062, 41.2035], "b": [29.103, 41.1975], "name_key": "bridge_yss"},
				{"a": [28.9715, 41.0170], "b": [28.9765, 41.0245], "name_key": "bridge_galata"},
			],
			"events": ["bridge_traffic", "derby", "rain", "concert"],
			"chatter": "flavor_istanbul",
		},
		"goals": [
			{"id": "riders_200k", "type": "riders", "value": 200000},
			{"id": "cross_bosphorus", "type": "cross_sides"},
			{"id": "both_airports", "type": "serve_pois", "pois": ["ist_airport", "saw_airport"]},
			{"id": "riders_800k", "type": "riders", "value": 800000},
			{"id": "three_modes", "type": "modes", "value": 3},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_2m", "type": "riders", "value": 2000000},
		],
		"star_goals": [3, 5, 7], # number of completed goals for 1/2/3 stars
		# Side test for "cross_sides": European side is left of this polyline (lon, lat)
		"divide": [[29.125, 41.40], [29.125, 41.232], [29.075, 41.195], [29.057, 41.167], [29.062, 41.140],
				   [29.066, 41.116], [29.061, 41.096], [29.058, 41.080], [29.044, 41.068],
				   [29.033, 41.054], [29.019, 41.040], [29.006, 41.026], [28.998, 41.008], [29.00, 40.70]],
	}


static func _ankara() -> Dictionary:
	return {
		"id": "ankara",
		"name_key": "city_ankara",
		"subtitle_key": "city_ankara_sub",
		"bounds": [32.55, 39.78, 33.08, 40.14],
		"start_cash": 7000.0,
		"annual_grant": 2000.0,
		"demand_scale": 1.0,
		"difficulty": 1,
		"unlock_stars": 0,
		"base_elev": 860.0,
		"accent": Color("2a9d8f"),
		"water_polys": [],
		"channels": [
			# Ankara Çayı (stylised stream, narrow — bridges are cheap)
			{"pts": [[32.62, 39.96], [32.72, 39.955], [32.80, 39.952], [32.86, 39.950], [32.95, 39.962], [33.08, 39.975]],
			 "w": [0.10, 0.10, 0.10, 0.10, 0.10, 0.10], "river": true},
		],
		"lakes": [
			{"lon": 32.826, "lat": 39.825, "rx": 0.5, "ry": 1.9, "rot": 0.5}, # Eymir
			{"lon": 32.795, "lat": 39.790, "rx": 1.2, "ry": 3.0, "rot": 0.3}, # Mogan (north tip)
			{"lon": 32.98, "lat": 40.08, "rx": 0.9, "ry": 0.7, "rot": 0.0},   # Çubuk dam (stylised)
		],
		"islands": [],
		"hills": [
			{"lon": 32.86, "lat": 39.87, "h": 280.0, "r": 5.0},   # Çankaya
			{"lon": 32.86, "lat": 39.941, "h": 120.0, "r": 0.8},  # Ankara Kalesi
			{"lon": 32.92, "lat": 39.93, "h": 200.0, "r": 4.0},   # Mamak hills
			{"lon": 32.78, "lat": 40.02, "h": 180.0, "r": 6.0},
			{"lon": 32.96, "lat": 39.86, "h": 300.0, "r": 6.0},   # Elmadağ side
			{"lon": 32.62, "lat": 39.86, "h": 160.0, "r": 7.0},
		],
		"parks": [
			{"lon": 32.765, "lat": 39.882, "rx": 1.2, "ry": 0.8, "rot": 0.0, "name_key": "park_odtu"},
			{"lon": 32.80, "lat": 39.94, "rx": 1.4, "ry": 1.0, "rot": 0.0, "name_key": "park_ataturk"},
		],
		"zones": [
			{"name": "Kızılay", "lon": 32.854, "lat": 39.920, "pop": 120, "jobs": 520, "r": 1.3},
			{"name": "Ulus", "lon": 32.855, "lat": 39.942, "pop": 90, "jobs": 300, "r": 1.2},
			{"name": "Çankaya", "lon": 32.862, "lat": 39.890, "pop": 520, "jobs": 260, "r": 2.6},
			{"name": "Kavaklıdere", "lon": 32.860, "lat": 39.906, "pop": 140, "jobs": 210, "r": 1.0},
			{"name": "Balgat", "lon": 32.825, "lat": 39.905, "pop": 160, "jobs": 140, "r": 1.3},
			{"name": "Çayyolu", "lon": 32.700, "lat": 39.885, "pop": 230, "jobs": 60, "r": 2.6},
			{"name": "Ümitköy", "lon": 32.725, "lat": 39.900, "pop": 160, "jobs": 60, "r": 1.6},
			{"name": "Keçiören", "lon": 32.862, "lat": 39.985, "pop": 940, "jobs": 140, "r": 3.0},
			{"name": "Yenimahalle", "lon": 32.800, "lat": 39.968, "pop": 520, "jobs": 160, "r": 2.6},
			{"name": "Batıkent", "lon": 32.730, "lat": 39.965, "pop": 290, "jobs": 80, "r": 2.0},
			{"name": "Ostim", "lon": 32.755, "lat": 39.980, "pop": 40, "jobs": 260, "r": 1.4},
			{"name": "Mamak", "lon": 32.920, "lat": 39.930, "pop": 680, "jobs": 90, "r": 3.0},
			{"name": "Altındağ", "lon": 32.885, "lat": 39.955, "pop": 400, "jobs": 120, "r": 2.0},
			{"name": "Etimesgut", "lon": 32.670, "lat": 39.948, "pop": 600, "jobs": 110, "r": 3.0},
			{"name": "Eryaman", "lon": 32.640, "lat": 39.975, "pop": 280, "jobs": 50, "r": 2.0},
			{"name": "Sincan", "lon": 32.580, "lat": 39.970, "pop": 560, "jobs": 120, "r": 3.0},
			{"name": "Pursaklar", "lon": 32.900, "lat": 40.035, "pop": 150, "jobs": 30, "r": 1.8},
			{"name": "Gölbaşı", "lon": 32.805, "lat": 39.800, "pop": 150, "jobs": 40, "r": 2.5},
			{"name": "Dikmen", "lon": 32.835, "lat": 39.880, "pop": 230, "jobs": 60, "r": 1.6},
			{"name": "Cebeci", "lon": 32.880, "lat": 39.925, "pop": 110, "jobs": 110, "r": 1.0},
		],
		"pois": [
			{"id": "esenboga", "name_key": "poi_esenboga", "lon": 32.995, "lat": 40.122, "kind": "airport", "jobs": 90},
			{"id": "odtu", "name_key": "poi_odtu", "lon": 32.780, "lat": 39.893, "kind": "university", "jobs": 90},
			{"id": "bilkent", "name_key": "poi_bilkent", "lon": 32.750, "lat": 39.870, "kind": "university", "jobs": 70},
			{"id": "hacettepe", "name_key": "poi_hacettepe", "lon": 32.735, "lat": 39.866, "kind": "university", "jobs": 60},
			{"id": "asti", "name_key": "poi_asti", "lon": 32.812, "lat": 39.918, "kind": "terminal", "jobs": 90},
			{"id": "gar", "name_key": "poi_ankara_gar", "lon": 32.845, "lat": 39.936, "kind": "terminal", "jobs": 80},
			{"id": "anitkabir", "name_key": "poi_anitkabir", "lon": 32.837, "lat": 39.925, "kind": "landmark", "jobs": 60},
			{"id": "sogutozu", "name_key": "poi_sogutozu", "lon": 32.800, "lat": 39.909, "kind": "business", "jobs": 180},
		],
		"flavor": {
			"birds": [],
			"ambience": ["city"],
			"winter_months": [11, 0, 1],
			"university_pois": ["odtu", "bilkent", "hacettepe"],
			"decor": [
				{"kind": "tower", "lon": 32.857, "lat": 39.886, "name_key": "decor_atakule"},
				{"kind": "fortress", "lon": 32.864, "lat": 39.9405, "name_key": "decor_kale"},
				{"kind": "fortress", "lon": 32.8369, "lat": 39.9251, "name_key": "decor_anitkabir"},
			],
			"bridges": [],
			"events": ["snow_storm", "rain", "concert", "derby"],
			"chatter": "flavor_ankara",
		},
		"goals": [
			{"id": "riders_100k", "type": "riders", "value": 100000},
			{"id": "universities", "type": "serve_pois", "pois": ["odtu", "bilkent", "hacettepe"]},
			{"id": "airport_ank", "type": "serve_pois", "pois": ["esenboga"]},
			{"id": "riders_300k", "type": "riders", "value": 300000},
			{"id": "coverage_40", "type": "coverage", "value": 0.40},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_600k", "type": "riders", "value": 600000},
		],
		"star_goals": [3, 5, 7],
		"divide": [],
	}


static func _izmir() -> Dictionary:
	return {
		"id": "izmir",
		"name_key": "city_izmir",
		"subtitle_key": "city_izmir_sub",
		"bounds": [26.95, 38.27, 27.30, 38.55],
		"start_cash": 6500.0,
		"annual_grant": 1800.0,
		"demand_scale": 0.4,
		"difficulty": 2,
		"unlock_stars": 2,
		"base_elev": 20.0,
		"accent": Color("f4a261"),
		"water_polys": [
			# Gulf of İzmir
			[[27.172, 38.457], [27.160, 38.446], [27.146, 38.438], [27.136, 38.426], [27.128, 38.419],
			 [27.110, 38.411], [27.090, 38.404], [27.070, 38.399], [27.050, 38.396], [27.030, 38.398],
			 [27.000, 38.401], [26.975, 38.398], [26.94, 38.396], [26.94, 38.56], [26.97, 38.56],
			 [26.975, 38.525], [27.000, 38.503], [27.030, 38.487], [27.060, 38.474], [27.090, 38.462],
			 [27.110, 38.458], [27.130, 38.461], [27.150, 38.463], [27.165, 38.463]],
		],
		"channels": [
			# Meles stream (stylised)
			{"pts": [[27.150, 38.440], [27.170, 38.425], [27.185, 38.410], [27.200, 38.395]],
			 "w": [0.12, 0.10, 0.08, 0.06], "river": true},
		],
		"lakes": [],
		"islands": [],
		"hills": [
			{"lon": 27.145, "lat": 38.413, "h": 180.0, "r": 0.9},  # Kadifekale
			{"lon": 27.10, "lat": 38.36, "h": 300.0, "r": 4.0},    # Karabağlar heights
			{"lon": 27.03, "lat": 38.37, "h": 450.0, "r": 4.0},    # Balçova / Narlıdere
			{"lon": 27.25, "lat": 38.42, "h": 350.0, "r": 5.0},    # Bornova hills
			{"lon": 27.18, "lat": 38.50, "h": 250.0, "r": 4.0},    # Yamanlar
			{"lon": 27.22, "lat": 38.33, "h": 220.0, "r": 5.0},
		],
		"parks": [
			{"lon": 27.00, "lat": 38.505, "rx": 1.2, "ry": 1.0, "rot": 0.0, "name_key": "park_kus"},
		],
		"zones": [
			{"name": "Konak", "lon": 27.133, "lat": 38.417, "pop": 340, "jobs": 420, "r": 1.6},
			{"name": "Alsancak", "lon": 27.145, "lat": 38.437, "pop": 90, "jobs": 260, "r": 0.9},
			{"name": "Bayraklı", "lon": 27.185, "lat": 38.463, "pop": 300, "jobs": 250, "r": 1.8},
			{"name": "Karşıyaka", "lon": 27.112, "lat": 38.467, "pop": 350, "jobs": 160, "r": 1.7},
			{"name": "Bostanlı", "lon": 27.093, "lat": 38.465, "pop": 120, "jobs": 60, "r": 1.0},
			{"name": "Mavişehir", "lon": 27.070, "lat": 38.478, "pop": 90, "jobs": 60, "r": 1.0},
			{"name": "Çiğli", "lon": 27.060, "lat": 38.497, "pop": 210, "jobs": 140, "r": 2.2},
			{"name": "Bornova", "lon": 27.220, "lat": 38.465, "pop": 450, "jobs": 210, "r": 2.4},
			{"name": "Buca", "lon": 27.175, "lat": 38.388, "pop": 510, "jobs": 110, "r": 2.6},
			{"name": "Karabağlar", "lon": 27.120, "lat": 38.382, "pop": 480, "jobs": 90, "r": 2.2},
			{"name": "Gaziemir", "lon": 27.135, "lat": 38.320, "pop": 140, "jobs": 120, "r": 1.8},
			{"name": "Balçova", "lon": 27.050, "lat": 38.388, "pop": 80, "jobs": 70, "r": 1.0},
			{"name": "Narlıdere", "lon": 27.000, "lat": 38.392, "pop": 65, "jobs": 30, "r": 1.0},
			{"name": "Göztepe", "lon": 27.085, "lat": 38.398, "pop": 150, "jobs": 80, "r": 1.0},
			{"name": "Hatay", "lon": 27.105, "lat": 38.400, "pop": 120, "jobs": 60, "r": 0.9},
			{"name": "Bayraklı Kuleleri", "lon": 27.170, "lat": 38.452, "pop": 20, "jobs": 230, "r": 0.6},
			{"name": "Çamdibi", "lon": 27.190, "lat": 38.443, "pop": 160, "jobs": 40, "r": 1.0},
			{"name": "Ataşehir (İzmir)", "lon": 27.090, "lat": 38.515, "pop": 70, "jobs": 30, "r": 1.0},
		],
		"pois": [
			{"id": "adb", "name_key": "poi_adb", "lon": 27.157, "lat": 38.292, "kind": "airport", "jobs": 80},
			{"id": "ege_uni", "name_key": "poi_ege_uni", "lon": 27.225, "lat": 38.456, "kind": "university", "jobs": 70},
			{"id": "deu", "name_key": "poi_deu", "lon": 27.205, "lat": 38.371, "kind": "university", "jobs": 60},
			{"id": "saat_kulesi", "name_key": "poi_saat_kulesi", "lon": 27.128, "lat": 38.419, "kind": "landmark", "jobs": 60},
			{"id": "otogar_izm", "name_key": "poi_otogar_izm", "lon": 27.255, "lat": 38.443, "kind": "terminal", "jobs": 50},
			{"id": "kulturpark", "name_key": "poi_kulturpark", "lon": 27.145, "lat": 38.430, "kind": "landmark", "jobs": 40},
		],
		"flavor": {
			"birds": [{"kind": "gull", "count": 12}, {"kind": "flamingo", "count": 14, "lon": 27.0, "lat": 38.505, "r": 1.4}],
			"ambience": ["sea", "city"],
			"ferry_horn": true,
			"comfort": {"ferry": 1.1},
			"summer_months": [5, 6, 7, 8],
			"fair_month": 8,
			"fair_poi": "kulturpark",
			"decor": [
				{"kind": "tower", "lon": 27.1225, "lat": 38.4095, "name_key": "decor_asansor"},
				{"kind": "fortress", "lon": 27.142, "lat": 38.4135, "name_key": "decor_kadifekale"},
				{"kind": "tower", "lon": 27.1287, "lat": 38.4189, "name_key": "decor_saatkulesi"},
			],
			"bridges": [],
			"events": ["imbat", "rain", "concert", "derby"],
			"chatter": "flavor_izmir",
		},
		"goals": [
			{"id": "ferry_bay", "type": "mode_riders", "mode": "ferry", "value": 8000},
			{"id": "riders_80k", "type": "riders", "value": 80000},
			{"id": "airport_izm", "type": "serve_pois", "pois": ["adb"]},
			{"id": "riders_250k", "type": "riders", "value": 250000},
			{"id": "funicular", "type": "mode_riders", "mode": "funicular", "value": 1500},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_500k", "type": "riders", "value": 500000},
		],
		"star_goals": [3, 5, 7],
		"divide": [],
	}


static func _eskisehir() -> Dictionary:
	return {
		"id": "eskisehir", "name_key": "city_eskisehir", "subtitle_key": "city_eskisehir_sub",
		"bounds": [30.40, 39.72, 30.64, 39.84],
		"start_cash": 3200.0, "annual_grant": 900.0, "demand_scale": 0.45,
		"difficulty": 1, "unlock_stars": 3, "base_elev": 790.0, "accent": Color("8e44ad"),
		"water_polys": [],
		"channels": [
			{"pts": [[30.40, 39.792], [30.45, 39.786], [30.49, 39.781], [30.515, 39.777], [30.54, 39.779], [30.58, 39.784], [30.64, 39.790]],
			 "w": [0.06, 0.06, 0.06, 0.07, 0.06, 0.06, 0.06], "river": true},
		],
		"lakes": [{"lon": 30.452, "lat": 39.770, "rx": 0.35, "ry": 0.22, "rot": 0.2}],
		"islands": [],
		"hills": [
			{"lon": 30.525, "lat": 39.755, "h": 90.0, "r": 1.6},
			{"lon": 30.50, "lat": 39.735, "h": 160.0, "r": 3.0},
			{"lon": 30.60, "lat": 39.74, "h": 120.0, "r": 3.0},
		],
		"parks": [{"lon": 30.452, "lat": 39.773, "rx": 0.9, "ry": 0.6, "rot": 0.1, "name_key": "park_sazova"}],
		"zones": [
			{"name": "Odunpazarı", "lon": 30.525, "lat": 39.762, "pop": 260, "jobs": 180, "r": 1.4},
			{"name": "Köprübaşı", "lon": 30.517, "lat": 39.776, "pop": 40, "jobs": 260, "r": 0.7},
			{"name": "Tepebaşı", "lon": 30.500, "lat": 39.790, "pop": 210, "jobs": 140, "r": 1.4},
			{"name": "Bağlar", "lon": 30.490, "lat": 39.772, "pop": 90, "jobs": 60, "r": 0.9},
			{"name": "Batıkent", "lon": 30.470, "lat": 39.802, "pop": 110, "jobs": 40, "r": 1.1},
			{"name": "Emek", "lon": 30.545, "lat": 39.802, "pop": 100, "jobs": 40, "r": 1.0},
			{"name": "Vişnelik", "lon": 30.555, "lat": 39.766, "pop": 90, "jobs": 50, "r": 0.9},
			{"name": "Sümer", "lon": 30.550, "lat": 39.782, "pop": 80, "jobs": 70, "r": 0.9},
			{"name": "Çamlıca", "lon": 30.490, "lat": 39.748, "pop": 90, "jobs": 30, "r": 1.0},
			{"name": "Osmangazi", "lon": 30.580, "lat": 39.775, "pop": 70, "jobs": 40, "r": 1.0},
		],
		"pois": [
			{"id": "anadolu_uni", "name_key": "poi_anadolu_uni", "lon": 30.500, "lat": 39.792, "kind": "university", "jobs": 90},
			{"id": "esogu", "name_key": "poi_esogu", "lon": 30.484, "lat": 39.752, "kind": "university", "jobs": 70},
			{"id": "esk_otogar", "name_key": "poi_esk_otogar", "lon": 30.565, "lat": 39.776, "kind": "terminal", "jobs": 50},
			{"id": "esk_gar", "name_key": "poi_esk_gar", "lon": 30.508, "lat": 39.781, "kind": "terminal", "jobs": 50},
			{"id": "sazova", "name_key": "poi_sazova", "lon": 30.446, "lat": 39.768, "kind": "landmark", "jobs": 40},
		],
		"flavor": {"birds": [], "ambience": ["city"], "university_pois": ["anadolu_uni", "esogu"],
			"decor": [{"kind": "tower", "lon": 30.527, "lat": 39.758, "name_key": "decor_odunpazari"}],
			"bridges": [], "events": ["rain", "concert"], "chatter": "flavor_eskisehir"},
		"goals": [
			{"id": "riders_30k", "type": "riders", "value": 30000},
			{"id": "unis_esk", "type": "serve_pois", "pois": ["anadolu_uni", "esogu"]},
			{"id": "tram_city", "type": "mode_riders", "mode": "tram", "value": 25000},
			{"id": "riders_80k", "type": "riders", "value": 80000},
			{"id": "coverage_50", "type": "coverage", "value": 0.50},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_150k", "type": "riders", "value": 150000},
		],
		"star_goals": [3, 5, 7], "divide": [],
	}


static func _antalya() -> Dictionary:
	return {
		"id": "antalya", "name_key": "city_antalya", "subtitle_key": "city_antalya_sub",
		"bounds": [30.56, 36.83, 30.90, 36.99],
		"start_cash": 4800.0, "annual_grant": 1300.0, "demand_scale": 0.7,
		"difficulty": 2, "unlock_stars": 4, "base_elev": 40.0, "accent": Color("ff7b00"),
		"water_polys": [
			[[30.56, 36.868], [30.60, 36.866], [30.625, 36.866], [30.65, 36.872], [30.675, 36.880], [30.695, 36.884],
			 [30.705, 36.882], [30.712, 36.886], [30.73, 36.882], [30.76, 36.872], [30.79, 36.860], [30.82, 36.852],
			 [30.86, 36.846], [30.90, 36.842], [30.90, 36.80], [30.56, 36.80]],
		],
		"channels": [
			{"pts": [[30.74, 36.97], [30.75, 36.93], [30.77, 36.89], [30.785, 36.862]], "w": [0.05, 0.05, 0.06, 0.07], "river": true},
		],
		"lakes": [], "islands": [],
		"hills": [
			{"lon": 30.57, "lat": 36.93, "h": 520.0, "r": 5.0},
			{"lon": 30.62, "lat": 36.98, "h": 300.0, "r": 5.0},
			{"lon": 30.88, "lat": 36.98, "h": 120.0, "r": 4.0},
		],
		"parks": [{"lon": 30.665, "lat": 36.893, "rx": 0.6, "ry": 0.4, "rot": 0.0, "name_key": "park_ataturk_ant"}],
		"zones": [
			{"name": "Muratpaşa", "lon": 30.720, "lat": 36.892, "pop": 330, "jobs": 260, "r": 1.6},
			{"name": "Kaleiçi", "lon": 30.706, "lat": 36.886, "pop": 20, "jobs": 180, "r": 0.5},
			{"name": "Konyaaltı", "lon": 30.630, "lat": 36.880, "pop": 190, "jobs": 110, "r": 1.6},
			{"name": "Kepez", "lon": 30.700, "lat": 36.930, "pop": 450, "jobs": 120, "r": 2.6},
			{"name": "Varsak", "lon": 30.730, "lat": 36.955, "pop": 160, "jobs": 30, "r": 1.6},
			{"name": "Lara", "lon": 30.800, "lat": 36.868, "pop": 120, "jobs": 140, "r": 1.6},
			{"name": "Meltem", "lon": 30.655, "lat": 36.893, "pop": 90, "jobs": 90, "r": 0.9},
			{"name": "Fener", "lon": 30.760, "lat": 36.880, "pop": 110, "jobs": 60, "r": 1.2},
			{"name": "Aksu", "lon": 30.840, "lat": 36.940, "pop": 70, "jobs": 30, "r": 2.0},
			{"name": "Döşemealtı", "lon": 30.620, "lat": 36.975, "pop": 70, "jobs": 30, "r": 2.0},
		],
		"pois": [
			{"id": "ayt", "name_key": "poi_ayt", "lon": 30.800, "lat": 36.900, "kind": "airport", "jobs": 120},
			{"id": "akdeniz_uni", "name_key": "poi_akdeniz_uni", "lon": 30.650, "lat": 36.897, "kind": "university", "jobs": 70},
			{"id": "konyaalti_beach", "name_key": "poi_konyaalti_beach", "lon": 30.625, "lat": 36.870, "kind": "landmark", "jobs": 70},
			{"id": "lara_beach", "name_key": "poi_lara_beach", "lon": 30.820, "lat": 36.856, "kind": "landmark", "jobs": 70},
			{"id": "ant_otogar", "name_key": "poi_ant_otogar", "lon": 30.680, "lat": 36.922, "kind": "terminal", "jobs": 50},
		],
		"flavor": {"birds": [{"kind": "gull", "count": 10}], "ambience": ["sea", "city"], "summer_months": [5, 6, 7, 8],
			"tourism": true,
			"decor": [{"kind": "tower", "lon": 30.704, "lat": 36.884, "name_key": "decor_hidirlik"},
				{"kind": "tower", "lon": 30.7037, "lat": 36.8853, "name_key": "decor_yivli"}],
			"bridges": [], "events": ["rain", "concert"], "chatter": "flavor_antalya"},
		"goals": [
			{"id": "riders_40k", "type": "riders", "value": 40000},
			{"id": "airport_ant", "type": "serve_pois", "pois": ["ayt"]},
			{"id": "beaches", "type": "serve_pois", "pois": ["konyaalti_beach", "lara_beach"]},
			{"id": "riders_120k", "type": "riders", "value": 120000},
			{"id": "three_modes", "type": "modes", "value": 3},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_250k", "type": "riders", "value": 250000},
		],
		"star_goals": [3, 5, 7], "divide": [],
	}


static func _bursa() -> Dictionary:
	return {
		"id": "bursa", "name_key": "city_bursa", "subtitle_key": "city_bursa_sub",
		"bounds": [28.85, 40.09, 29.24, 40.28],
		"start_cash": 5200.0, "annual_grant": 1500.0, "demand_scale": 0.75,
		"difficulty": 2, "unlock_stars": 5, "base_elev": 120.0, "accent": Color("2a9d8f"),
		"water_polys": [],
		"channels": [
			{"pts": [[28.85, 40.215], [28.92, 40.225], [28.98, 40.235], [29.05, 40.245], [29.12, 40.25], [29.24, 40.255]],
			 "w": [0.07, 0.07, 0.07, 0.07, 0.07, 0.07], "river": true},
		],
		"lakes": [], "islands": [],
		"hills": [
			{"lon": 29.12, "lat": 40.09, "h": 1700.0, "r": 6.5},
			{"lon": 29.02, "lat": 40.13, "h": 600.0, "r": 4.5},
			{"lon": 29.20, "lat": 40.15, "h": 700.0, "r": 4.5},
			{"lon": 29.06, "lat": 40.186, "h": 60.0, "r": 1.0},
		],
		"parks": [{"lon": 29.14, "lat": 40.11, "rx": 4.0, "ry": 2.0, "rot": 0.1, "name_key": "park_uludag"}],
		"zones": [
			{"name": "Heykel", "lon": 29.062, "lat": 40.184, "pop": 60, "jobs": 330, "r": 0.8},
			{"name": "Osmangazi", "lon": 29.045, "lat": 40.195, "pop": 520, "jobs": 220, "r": 2.2},
			{"name": "Yıldırım", "lon": 29.100, "lat": 40.190, "pop": 560, "jobs": 140, "r": 2.4},
			{"name": "Nilüfer", "lon": 28.990, "lat": 40.218, "pop": 420, "jobs": 200, "r": 2.6},
			{"name": "Görükle", "lon": 28.880, "lat": 40.228, "pop": 90, "jobs": 30, "r": 1.6},
			{"name": "Emek", "lon": 29.000, "lat": 40.245, "pop": 130, "jobs": 50, "r": 1.4},
			{"name": "OSB", "lon": 29.030, "lat": 40.242, "pop": 10, "jobs": 300, "r": 1.4},
			{"name": "Kestel", "lon": 29.210, "lat": 40.200, "pop": 70, "jobs": 40, "r": 1.6},
			{"name": "Soğanlı", "lon": 29.060, "lat": 40.230, "pop": 140, "jobs": 60, "r": 1.4},
			{"name": "Hamitler", "lon": 29.110, "lat": 40.230, "pop": 120, "jobs": 30, "r": 1.4},
			{"name": "Teferrüç", "lon": 29.100, "lat": 40.170, "pop": 30, "jobs": 30, "r": 0.6},
		],
		"pois": [
			{"id": "uludag_uni", "name_key": "poi_uludag_uni", "lon": 28.872, "lat": 40.224, "kind": "university", "jobs": 90},
			{"id": "uludag_ski", "name_key": "poi_uludag_ski", "lon": 29.125, "lat": 40.105, "kind": "landmark", "jobs": 50},
			{"id": "bursa_otogar", "name_key": "poi_bursa_otogar", "lon": 29.075, "lat": 40.262, "kind": "terminal", "jobs": 50},
			{"id": "ulu_cami", "name_key": "poi_ulu_cami", "lon": 29.060, "lat": 40.184, "kind": "landmark", "jobs": 60},
		],
		"flavor": {"birds": [], "ambience": ["city"], "winter_months": [11, 0, 1], "ski_poi": "uludag_ski",
			"university_pois": ["uludag_uni"],
			"decor": [{"kind": "fortress", "lon": 29.052, "lat": 40.187, "name_key": "decor_tophane"},
				{"kind": "mosque", "lon": 29.0617, "lat": 40.1839, "name_key": "decor_ulucami"}],
			"bridges": [], "events": ["rain", "snow_storm", "concert", "derby"], "chatter": "flavor_bursa"},
		"goals": [
			{"id": "riders_50k", "type": "riders", "value": 50000},
			{"id": "gondola_uludag", "type": "mode_riders", "mode": "gondola", "value": 2000},
			{"id": "uni_bursa", "type": "serve_pois", "pois": ["uludag_uni"]},
			{"id": "riders_150k", "type": "riders", "value": 150000},
			{"id": "coverage_35", "type": "coverage", "value": 0.35},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_300k", "type": "riders", "value": 300000},
		],
		"star_goals": [3, 5, 7], "divide": [],
	}


static func _trabzon() -> Dictionary:
	return {
		"id": "trabzon", "name_key": "city_trabzon", "subtitle_key": "city_trabzon_sub",
		"bounds": [39.62, 40.955, 39.86, 41.03],
		"start_cash": 3000.0, "annual_grant": 800.0, "demand_scale": 0.45,
		"difficulty": 3, "unlock_stars": 6, "base_elev": 15.0, "accent": Color("7b2d8b"),
		"water_polys": [
			[[39.62, 40.999], [39.65, 41.001], [39.68, 41.004], [39.70, 41.007], [39.72, 41.009], [39.735, 41.008],
			 [39.75, 41.004], [39.77, 41.001], [39.79, 40.999], [39.81, 40.995], [39.83, 40.991], [39.86, 40.987],
			 [39.86, 41.06], [39.62, 41.06]],
		],
		"channels": [
			{"pts": [[39.745, 40.955], [39.748, 40.975], [39.75, 40.990], [39.752, 41.003]], "w": [0.04, 0.05, 0.06, 0.07], "river": true},
		],
		"lakes": [], "islands": [],
		"hills": [
			{"lon": 39.735, "lat": 40.992, "h": 230.0, "r": 0.9},
			{"lon": 39.70, "lat": 40.965, "h": 420.0, "r": 3.0},
			{"lon": 39.80, "lat": 40.965, "h": 380.0, "r": 3.0},
			{"lon": 39.65, "lat": 40.97, "h": 300.0, "r": 3.0},
		],
		"parks": [],
		"zones": [
			{"name": "Ortahisar", "lon": 39.722, "lat": 41.003, "pop": 140, "jobs": 220, "r": 0.9},
			{"name": "Meydan", "lon": 39.732, "lat": 41.004, "pop": 30, "jobs": 160, "r": 0.5},
			{"name": "Kaşüstü", "lon": 39.690, "lat": 40.998, "pop": 60, "jobs": 30, "r": 0.9},
			{"name": "Değirmendere", "lon": 39.752, "lat": 40.999, "pop": 80, "jobs": 60, "r": 0.8},
			{"name": "Bahçecik", "lon": 39.705, "lat": 40.992, "pop": 60, "jobs": 20, "r": 0.7},
			{"name": "Pelitli", "lon": 39.800, "lat": 40.989, "pop": 50, "jobs": 20, "r": 0.9},
			{"name": "Beşirli", "lon": 39.665, "lat": 40.996, "pop": 50, "jobs": 25, "r": 0.9},
			{"name": "Yalıncak", "lon": 39.780, "lat": 40.990, "pop": 40, "jobs": 30, "r": 0.8},
			{"name": "Boztepe", "lon": 39.735, "lat": 40.991, "pop": 20, "jobs": 10, "r": 0.4},
		],
		"pois": [
			{"id": "tzx", "name_key": "poi_tzx", "lon": 39.785, "lat": 40.994, "kind": "airport", "jobs": 40},
			{"id": "ktu", "name_key": "poi_ktu", "lon": 39.770, "lat": 40.992, "kind": "university", "jobs": 60},
			{"id": "boztepe", "name_key": "poi_boztepe", "lon": 39.736, "lat": 40.989, "kind": "landmark", "jobs": 40},
			{"id": "trb_meydan", "name_key": "poi_trb_meydan", "lon": 39.732, "lat": 41.005, "kind": "landmark", "jobs": 40},
		],
		"flavor": {"birds": [{"kind": "gull", "count": 8}], "ambience": ["sea", "city"], "ferry_horn": true,
			"decor": [{"kind": "fortress", "lon": 39.715, "lat": 41.004, "name_key": "decor_trb_kale"}],
			"bridges": [], "events": ["rain", "concert", "derby"], "chatter": "flavor_trabzon"},
		"goals": [
			{"id": "riders_15k", "type": "riders", "value": 15000},
			{"id": "boztepe", "type": "serve_pois", "pois": ["boztepe"]},
			{"id": "airport_trb", "type": "serve_pois", "pois": ["tzx"]},
			{"id": "riders_40k", "type": "riders", "value": 40000},
			{"id": "two_modes", "type": "modes", "value": 2},
			{"id": "profit_year", "type": "profit"},
			{"id": "riders_80k", "type": "riders", "value": 80000},
		],
		"star_goals": [3, 5, 7], "divide": [],
	}
