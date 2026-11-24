extends Node
## Headless smoke + balance test for the simulation core.
## Run:  godot --headless --path . tests/test_core.tscn

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FAIL ", msg)


func ll(st: GameState, lon: float, lat: float) -> Vector2:
	return st.city.project(lon, lat)


func build(st: GameState, mode: String, deep: bool, pts: Array) -> int:
	var nodes: Array = []
	for p in pts:
		var sid := st.net.station_at(p, 0.3)
		nodes.append({"pos": p if sid < 0 else st.net.stations[sid]["pos"], "sid": sid})
	var ev := st.net.evaluate_draft(mode, deep, nodes)
	if not ev["ok"]:
		printerr("    draft rejected: ", ev["reason"])
		return -1
	if not st.spend(ev["cost"]):
		printerr("    cannot afford ", ev["cost"])
		return -1
	print("    built %s cost %.0f len %.1f km" % [mode, ev["cost"], ev["length"]])
	return st.net.commit_draft(mode, deep, nodes, ev["cost"], -1, false, ev["vehicles"])


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	print("== Istanbul")
	var st := GameState.new("istanbul")
	print("  size km ", st.city.size_km)
	check(st.city.is_water(ll(st, 29.045, 41.068)), "Bosphorus is water")
	check(not st.city.is_water(ll(st, 28.95, 41.05)), "Fatih/Eyüp is land")
	check(st.city.is_water(ll(st, 29.0, 40.9)), "Marmara is water")
	check(st.city.side_of(ll(st, 29.10, 41.0)) == 1, "Ataşehir on Asian side")
	check(st.city.side_of(ll(st, 28.90, 41.0)) == 0, "Zeytinburnu on European side")
	# M-line Kadıköy - Kartal
	var a := build(st, "metro", false, [ll(st, 29.03, 40.99), ll(st, 29.08, 40.98), ll(st, 29.13, 40.94), ll(st, 29.19, 40.905)])
	check(a > 0, "metro asia built")
	# Marmaray-like deep crossing
	var shallow := st.net.evaluate_segment("metro", false, ll(st, 28.99, 41.02), ll(st, 29.025, 41.02))
	check(not shallow["ok"], "shallow cannot cross Bosphorus: " + shallow["reason"])
	var b := build(st, "metro", true, [ll(st, 28.87, 40.985), ll(st, 28.91, 41.0), ll(st, 28.955, 41.008), ll(st, 29.0, 41.022), ll(st, 29.03, 40.99)])
	check(b > 0, "deep metro crossing built")
	var c := build(st, "metro", false, [ll(st, 28.977, 41.036), ll(st, 28.987, 41.062), ll(st, 29.012, 41.080), ll(st, 29.02, 41.11)])
	check(c > 0, "Taksim-Maslak built")
	var f := build(st, "ferry", false, [ll(st, 29.028, 40.993), ll(st, 28.982, 41.016)])
	check(f > 0, "ferry Kadıköy-Eminönü")
	var t1 := Time.get_ticks_msec()
	st.demand.debug = true
	st.recompute_if_dirty()
	print("  demand compute ms: ", Time.get_ticks_msec() - t1)
	print("  riders target %.0f cov %.2f sat %.1f avg trip %.1f" % [st.target_riders, st.demand.coverage, st.demand.satisfaction, st.demand.avg_trip_min])
	for lid in st.net.lines.keys():
		var l: Dictionary = st.net.lines[lid]
		print("    %s %s riders %.0f load %.2f headway %.1f" % [l["name"], l["mode"], st.demand.line_riders.get(lid, 0.0), st.demand.line_load.get(lid, 0.0), st.net.line_headway_min(l)])
	check(st.target_riders > 20000, "has meaningful ridership")
	check(st.city.side_of(ll(st, 29.10, 41.0)) == 1, "sides")
	st.check_goals()
	print("  goals: ", st.completed_goals)
	check(st.completed_goals.has("cross_bosphorus"), "cross goal complete")
	# simulate 3 years
	print("  cash before sim %.0f" % st.cash)
	for i in 36 * 20:
		st.advance(GameState.MONTH_SECONDS / 20.0, 1.0)
	print("  after 3y: year %d cash %.0f riders %.0f profit %.0f" % [st.year, st.cash, st.riders, st.last_year_profit])
	print("  feed posts %d approval %.1f events %s" % [st.feed.posts.size(), st.feed.approval, str(st.active_events)])
	check(st.feed.posts.size() > 5, "social feed produced posts")
	for i in mini(5, st.feed.posts.size()):
		print("    @%s: %s (%d likes)" % [st.feed.posts[i]["who"]["handle"], st.feed.posts[i]["tr"], st.feed.posts[i]["likes"]])
	check(SocialFeed.tr_suffix("M1", "da") == "de", "M1'de")
	check(SocialFeed.tr_suffix("Fatih", "dan") == "ten", "Fatih'ten")
	check(SocialFeed.tr_suffix("Konak", "a") == "a", "Konak'a")
	check(SocialFeed.tr_suffix("Bostancı", "a") == "ya", "Bostancı'ya")
	check(SocialFeed.tr_suffix("M4", "da") == "te", "M4'te")
	check(SocialFeed.tr_suffix("Kadıköy", "dan") == "den", "Kadıköy'den")
	# seasonal modifiers
	var a_st := GameState.new("ankara")
	a_st.month = 0
	a_st._update_mods()
	check(a_st.demand.mods.get("speed", {}).get("tram", 1.0) < 1.0, "Ankara winter slows trams")
	check(a_st.is_snowing(), "Ankara snows in January")
	var i_st := GameState.new("izmir")
	i_st.month = 8
	i_st._update_mods()
	check(i_st.demand.mods.get("poi", {}).get("kulturpark", 1.0) > 2.0, "Izmir fair boosts Kültürpark in September")
	check(CityEvents.in_historic_zone(st.city, st.city.project(28.95, 41.01)), "Fatih is a historic zone")
	var sv := st.to_dict()
	var js := JSON.stringify(sv)
	var st2 := GameState.new("istanbul")
	st2.from_dict(JSON.parse_string(js))
	check(st2.net.lines.size() == st.net.lines.size(), "save/load lines")
	check(absf(st2.cash - st.cash) < 0.01, "save/load cash")
	check(st2.feed.posts.size() == mini(st.feed.posts.size(), 50), "save/load feed")

	for cid in ["ankara", "izmir"]:
		print("== ", cid)
		var s := GameState.new(cid)
		print("  size km ", s.city.size_km, " zones ", s.city.zones.size())
		s.cash = 20000.0
		if cid == "ankara":
			var m := build(s, "metro", false, [ll(s, 32.58, 39.97), ll(s, 32.67, 39.948), ll(s, 32.73, 39.965), ll(s, 32.80, 39.968), ll(s, 32.855, 39.942), ll(s, 32.854, 39.920)])
			check(m > 0, "Ankara M1")
			var m2 := build(s, "metro", false, [ll(s, 32.854, 39.920), ll(s, 32.812, 39.918), ll(s, 32.78, 39.893), ll(s, 32.75, 39.875), ll(s, 32.70, 39.885)])
			check(m2 > 0, "Ankara M2")
		else:
			var fe := build(s, "ferry", false, [ll(s, 27.112, 38.458), ll(s, 27.133, 38.421)])
			check(fe > 0, "Izmir ferry")
			var me := build(s, "metro", false, [ll(s, 27.05, 38.392), ll(s, 27.09, 38.40), ll(s, 27.133, 38.417), ll(s, 27.15, 38.437), ll(s, 27.18, 38.452), ll(s, 27.22, 38.465)])
			check(me > 0, "Izmir metro")
			var fu := s.net.evaluate_segment("funicular", false, ll(s, 27.135, 38.418), ll(s, 27.145, 38.413))
			print("    funicular eval ", fu["ok"], " ", fu["reason"], " grade ", fu["grade"])
			var tr := s.net.evaluate_segment("tram", false, ll(s, 27.135, 38.418), ll(s, 27.145, 38.413))
			print("    tram eval ", tr["ok"], " ", tr["reason"])
		s.demand.debug = true
		s.recompute_if_dirty()
		print("  riders target %.0f cov %.2f sat %.1f" % [s.target_riders, s.demand.coverage, s.demand.satisfaction])
		check(s.target_riders > 5000, cid + " ridership")
		for i in 24 * 10:
			s.advance(GameState.MONTH_SECONDS / 10.0, 1.0)
		print("  after 2y: cash %.0f riders %.0f profit %.0f goals %s" % [s.cash, s.riders, s.last_year_profit, str(s.completed_goals)])

	# ---- stress: big network performance
	print("== stress")
	var big := GameState.new("istanbul")
	big.cash = 1e9
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var made := 0
	var tries := 0
	while made < 14 and tries < 400:
		tries += 1
		var origin := Vector2(rng.randf_range(8, 60), rng.randf_range(15, 45))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var pts: Array = []
		for k in 9:
			pts.append(origin + dir * k * 1.6 + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)))
		var nodes: Array = []
		var ok := true
		for p in pts:
			if big.net.station_site_error("metro", p) != "":
				ok = false
				break
			var sid := big.net.station_at(p, 0.5)
			nodes.append({"pos": p if sid < 0 else big.net.stations[sid]["pos"], "sid": sid})
		if not ok:
			continue
		var ev := big.net.evaluate_draft("metro", true, nodes)
		if not ev["ok"]:
			continue
		big.net.commit_draft("metro", true, nodes, ev["cost"], -1, false, ev["vehicles"])
		made += 1
	var t2 := Time.get_ticks_msec()
	big.recompute_if_dirty()
	var dt := Time.get_ticks_msec() - t2
	print("  %d lines %d stations -> riders %.0f, compute %d ms" % [big.net.lines.size(), big.net.stations.size(), big.target_riders, dt])
	check(dt < 1500, "large network demand compute under 1.5s on desktop")

	print("total ms ", Time.get_ticks_msec() - t0)
	print("FAILURES: ", failures)
	get_tree().quit(1 if failures > 0 else 0)
