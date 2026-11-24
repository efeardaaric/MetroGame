class_name CityData
extends RefCounted
## Static, hand-authored geography for the playable cities.
## Coordinates are WGS84 (lon, lat). They are simplified/stylised outlines,
## projected to kilometres at runtime by CityMap.
##
## Zone fields: name, lon, lat, pop (thousand residents), jobs (attraction index,
## thousand daily trip ends), r (approx. radius km).
## POI fields: id, name_key, lon, lat, kind (airport/university/landmark/terminal/business).

const CITY_IDS: Array[String] = ["istanbul", "ankara", "izmir"]


static func get_city(id: String) -> Dictionary:
	match id:
		"istanbul":
			return _istanbul()
		"ankara":
			return _ankara()
		"izmir":
			return _izmir()
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
			],
			"bridges": [],
			"events": ["snow_storm", "rain", "concert"],
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
			],
			"bridges": [],
			"events": ["imbat", "rain", "concert"],
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
