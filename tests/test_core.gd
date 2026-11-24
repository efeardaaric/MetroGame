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
	print("  projected vote with this network: ", st.elec.vote(st), " coverage ", st.demand.coverage)
	for i in mini(5, st.feed.posts.size()):
		print("    @%s: %s (%d likes)" % [st.feed.posts[i]["who"]["handle"], st.feed.posts[i]["tr"], st.feed.posts[i]["likes"]])
	check(SocialFeed.tr_suffix("M1", "da") == "de", "M1'de")
	check(SocialFeed.tr_suffix("Fatih", "dan") == "ten", "Fatih'ten")
	check(SocialFeed.tr_suffix("Konak", "a") == "a", "Konak'a")
	check(SocialFeed.tr_suffix("Bostancı", "a") == "ya", "Bostancı'ya")
	check(SocialFeed.tr_suffix("M4", "da") == "te", "M4'te")
	check(SocialFeed.tr_suffix("Kadıköy", "dan") == "den", "Kadıköy'den")
	# research
	var r_st := GameState.new("istanbul")
	check(r_st.tech_state("driverless") == "locked_year", "driverless locked until 2017")
	check(r_st.start_research("contactless"), "start contactless research")
	check(r_st.tech_state("ac_fleet") == "busy", "one project at a time")
	var inc0 := r_st.monthly_income()
	for i in 3:
		r_st._end_month()
	check(r_st.researched.has("contactless"), "research completes after months")
	r_st.riders = 100000.0
	check(r_st.monthly_income() > 100000.0 * 30.0 * GameState.FARE / 1e6 * 1.05, "contactless raises fare income")
	var c1 := r_st.net.evaluate_draft("metro", false, [{"pos": Vector2(20, 30), "sid": -1}, {"pos": Vector2(22, 30), "sid": -1}])
	r_st.researched.append("prefab")
	var c2 := r_st.net.evaluate_draft("metro", false, [{"pos": Vector2(20, 30), "sid": -1}, {"pos": Vector2(22, 30), "sid": -1}])
	check(c2["cost"] < c1["cost"], "prefab stations are cheaper")
	# sandbox
	var sbx := GameState.new("ankara")
	sbx.sandbox = true
	var before := sbx.cash
	check(sbx.spend(1e7) and sbx.cash == before, "sandbox spending is free")
	check(sbx.slot() == "ankara_sandbox", "sandbox slot")
	check(Achievements.check(sbx).is_empty(), "no achievements in sandbox")
	# timelapse log
	st.log_line(st.net.lines.keys()[0])
	check(st.build_log.size() == 1 and st.build_log[0]["pts"].size() >= 2, "timelapse log entry")
	# ---- management
	var mg_st := GameState.new("istanbul")
	mg_st.cash = 1e6
	build(mg_st, "metro", false, [ll(mg_st, 29.03, 40.99), ll(mg_st, 29.08, 40.98), ll(mg_st, 29.13, 40.94)])
	build(mg_st, "metro", false, [ll(mg_st, 28.977, 41.036), ll(mg_st, 28.987, 41.062), ll(mg_st, 29.012, 41.080)])
	mg_st.recompute_if_dirty()
	var base_r := mg_st.target_riders
	mg_st.mgmt.set_fare(mg_st, 1.5)
	mg_st.recompute_if_dirty()
	check(mg_st.target_riders < base_r * 0.95, "higher fare reduces ridership (%.0f -> %.0f)" % [base_r, mg_st.target_riders])
	mg_st.mgmt.set_fare(mg_st, 1.0)
	var e0 := mg_st.monthly_expense()
	mg_st.mgmt.set_maint(mg_st, 2)
	check(mg_st.monthly_expense() > e0, "high maintenance costs more")
	mg_st.mgmt.set_maint(mg_st, 1)
	var lid0: int = mg_st.net.lines.keys()[0]
	mg_st.mgmt.set_incident(mg_st, lid0, "strike", 0.0, 1)
	mg_st.recompute_if_dirty()
	check(mg_st.demand.line_riders.get(lid0, 0.0) == 0.0, "closed line carries nobody")
	check(not mg_st.mgmt.can_repair(mg_st, lid0), "strikes can't be repaired")
	mg_st.mgmt.set_incident(mg_st, lid0, "breakdown", 0.5, 2)
	check(mg_st.mgmt.repair(mg_st, lid0) and not mg_st.net.lines[lid0].has("incident"), "emergency repair clears breakdown")
	var c0 := mg_st.cash
	check(mg_st.mgmt.take_loan(mg_st) and mg_st.cash > c0, "loan credited")
	check(mg_st.monthly_expense() > e0, "loan instalments added to expenses")
	# every decision option resolves without errors
	for did in Dilemmas.LIST.keys():
		for oi in Dilemmas.LIST[did]["options"].size():
			mg_st.mgmt.mission = {}
			mg_st.mgmt.pending = {"id": did, "line": lid0, "station": mg_st.net.stations.keys()[0]}
			var res := mg_st.mgmt.resolve(mg_st, oi)
			check(res != "" and not res.begins_with("dlg_"), "decision %s/%d -> %s" % [did, oi + 1, res])
	# missions
	mg_st.mgmt.mission = {}
	mg_st.mgmt.start_mission(mg_st, "riders_growth")
	check(not mg_st.mgmt.mission.is_empty() and mg_st.mgmt.mission_text(mg_st) != "", "mission text")
	mg_st.riders = float(mg_st.mgmt.mission["target"]) + 1.0
	var cb := mg_st.cash
	mg_st.mgmt._tick_mission(mg_st)
	check(mg_st.mgmt.mission.is_empty() and mg_st.cash > cb, "mission completes and pays")
	var sv2: Dictionary = JSON.parse_string(JSON.stringify(mg_st.to_dict()))
	var mg2 := GameState.new("istanbul")
	mg2.from_dict(sv2)
	check(mg2.mgmt.loans.size() == mg_st.mgmt.loans.size() and absf(mg2.mgmt.wage - mg_st.mgmt.wage) < 0.001, "management saved")
	# a long simulation triggers some decisions & incidents
	var sim := GameState.new("istanbul")
	sim.cash = 1e6
	build(sim, "metro", false, [ll(sim, 29.03, 40.99), ll(sim, 29.08, 40.98), ll(sim, 29.13, 40.94)])
	build(sim, "tram", false, [ll(sim, 28.905, 41.04), ll(sim, 28.93, 41.02), ll(sim, 28.95, 41.012)])
	var raised := [0]
	var incs := [0]
	sim.mgmt.dilemma_raised.connect(func(_e): raised[0] += 1; sim.mgmt.resolve(sim, 0))
	sim.mgmt.incident_started.connect(func(_l, _k): incs[0] += 1)
	for i in 60:
		sim._end_month()
	print("  5 years: %d decisions, %d incidents, wage %.2f" % [raised[0], incs[0], sim.mgmt.wage])
	check(raised[0] >= 4, "decisions happen regularly")
	# ---- construction, express, hubs, growth
	var cs := GameState.new("istanbul")
	cs.cash = 1e6
	var clid := build(cs, "metro", false, [ll(cs, 28.87, 40.985), ll(cs, 28.905, 40.995), ll(cs, 28.948, 41.008), ll(cs, 28.977, 41.03), ll(cs, 28.987, 41.062), ll(cs, 29.012, 41.08), ll(cs, 29.02, 41.11)])
	cs.recompute_if_dirty()
	var open_r := cs.target_riders
	cs.start_construction(clid, 3, 0, false, 1000.0)
	cs.recompute_if_dirty()
	check(cs.target_riders == 0.0, "line under construction carries nobody")
	for i in 3:
		cs._tick_construction()
	if cs.net.lines[clid].has("con"):
		for i in 4:
			cs._tick_construction()
	check(not cs.net.lines[clid].has("con"), "construction finishes (incl. possible overrun)")
	cs.recompute_if_dirty()
	check(absf(cs.target_riders - open_r) < 1.0, "ridership restored after opening")
	var h_before := cs.net.line_headway_min(cs.net.lines[clid])
	cs.net.lines[clid]["express"] = true
	cs.dirty = true
	cs.recompute_if_dirty()
	check(cs.net.line_headway_min(cs.net.lines[clid]) < h_before, "express shortens the cycle")
	print("    express riders %.0f vs local %.0f" % [cs.target_riders, open_r])
	check(cs.target_riders > 0.0, "express line carries riders")
	cs.net.lines[clid]["express"] = false
	var t2lid := build(cs, "tram", false, [ll(cs, 28.905, 41.04), ll(cs, 28.93, 41.02), ll(cs, 28.948, 41.008)])
	var hub_sid := cs.net.station_at(ll(cs, 28.948, 41.008), 0.4)
	var zc := cs.city.zones.size()
	check(cs.upgrade_hub(hub_sid) and cs.city.zones.size() == zc + 1, "hub adds a job centre")
	cs.dirty = true
	cs.recompute_if_dirty()
	cs._develop_stations()
	var devd := 0
	for s0 in cs.net.stations.values():
		if s0.get("dev", 0.0) > 0.0:
			devd += 1
	check(devd > 0, "busy stations develop (%d)" % devd)
	cs.net.lines[clid]["age"] = 200
	var ex0 := cs.net.line_annual_opex(cs.net.lines[clid])
	check(cs.modernize(clid) and cs.net.line_annual_opex(cs.net.lines[clid]) < ex0, "modernising resets ageing costs")
	# ---- new cities
	for cid2 in ["eskisehir", "antalya", "bursa", "trabzon"]:
		var nc := GameState.new(cid2)
		var zs: Array = nc.city.zones.filter(func(z): return z["pop"] > 0)
		zs.sort_custom(func(a, b): return a["pop"] > b["pop"])
		var a2: Vector2 = zs[0]["pos"]
		var b2: Vector2 = zs[1]["pos"]
		var nodes2: Array = [{"pos": a2, "sid": -1}, {"pos": a2.lerp(b2, 0.5), "sid": -1}, {"pos": b2, "sid": -1}]
		var ev2 := nc.net.evaluate_draft("tram", false, nodes2)
		if not ev2["ok"]:
			ev2 = nc.net.evaluate_draft("metro", false, nodes2)
			nc.net.commit_draft("metro", false, nodes2, ev2["cost"], -1, false, ev2["vehicles"])
		else:
			nc.net.commit_draft("tram", false, nodes2, ev2["cost"], -1, false, ev2["vehicles"])
		nc.recompute_if_dirty()
		print("    %s: %.1fx%.1f km, %d zones, first line riders %.0f (%s)" % [cid2, nc.city.size_km.x, nc.city.size_km.y, nc.city.zones.size(), nc.target_riders, ev2["reason"]])
		check(ev2["ok"] and nc.target_riders > 1000.0, cid2 + " playable")
	var bg := GameState.new("bursa")
	var gev := bg.net.evaluate_segment("gondola", false, bg.city.project(29.062, 40.184), bg.city.project(29.125, 40.11))
	check(gev["ok"], "Bursa gondola up Uludağ allowed: " + gev["reason"])
	# ---- scenarios & weekly
	for scd in ScenarioData.LIST:
		var ss := ScenarioData.create(scd["id"])
		check(ss.goals().size() >= 2 and ss.year == int(scd["start_year"]), "scenario " + scd["id"])
	var ws := ScenarioData.create_weekly()
	check(ws.slot() == "weekly" and ws.scenario["mods"].size() == 2, "weekly challenge %s %s" % [ws.city_id, str(ws.scenario["mods"])])
	var won := [false]
	var sc1 := ScenarioData.create("ank_campus")
	sc1.scenario_finished.connect(func(ok, _s, _sc): won[0] = not ok)
	for i in 50:
		sc1._end_month()
	check(won[0], "scenario fails after its deadline")
	var code := SaveManager.export_code()
	check(code.begins_with("RAYA1:") and SaveManager.import_code(code), "save export/import round trip")
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

	# ---------------------------------------------------------------- start years, events, elections
	print("elections & real events")
	var es := GameState.new("ankara")
	check(es.year == 2010 and es.start_year == 2010, "campaign starts in 2010")
	check(es.elec.next_year(es) == 2014, "first election March 2014")
	check(es.elec.months_left(es) == 50, "50 months to the 2014 vote")
	var held: Array = []
	es.election_held.connect(func(r): held.append(r))
	var promised := [false]
	es.election_promise.connect(func(): promised[0] = true)
	var ann: Array = []
	es.calendar.announced.connect(func(e, left): ann.append(e["id"]))
	es.calendar.monthly(es)
	while es.year * 12 + es.month < 2014 * 12 + 2 and not es.game_over:
		es._end_month()
	check(promised[0], "promise offered 14 months before the vote")
	check(held.size() == 1, "election held in March 2014")
	print("  empty-network vote: %.1f %s" % [held[0]["share"] if held.size() > 0 else -1.0, str(held[0]["parts"] if held.size() > 0 else {})])
	check(held.size() > 0 and not held[0]["won"], "doing nothing loses the election")
	check(es.game_over and es.lost_election, "lost election ends the game")
	var d2 := es.to_dict()
	var es2 := GameState.new("ankara")
	es2.from_dict(d2)
	check(es2.lost_election and es2.elec.last_result.get("year", 0) == 2014, "election result persists")
	# Antalya: G20 2015 announced a year ahead; a station at the venue earns the reward
	var an := GameState.new("antalya")
	var an_ann: Array = []
	an.calendar.announced.connect(func(e, left): an_ann.append(e["id"]))
	while an.year * 12 + an.month < 2015 * 12 + 9:
		an._end_month()
	check(an_ann.has("ant_g20"), "G20 announced in advance")
	check(an_ann.has("ant_expo"), "EXPO 2016 announced in advance")
	var g20 := RealEvents.get_event("ant_g20")
	var vp := an.calendar.venue_pos(an, g20)
	var lid := build(an, "tram", false, [vp + Vector2(-2.5, 0.3), vp + Vector2(-0.2, 0.0)])
	check(lid >= 0 and an.calendar.is_served(an, g20), "venue served by the new tram")
	var cash0 := an.cash
	while an.year * 12 + an.month < 2015 * 12 + 10:
		an._end_month()
	check(an.calendar.done.get("ant_g20", "") == "ok", "G20 prepared -> ok")
	check(an.has_event("re_ant_g20"), "G20 is active this month")
	print("  cash %.0f -> %.0f" % [cash0, an.cash])
	# COVID hits every city in March 2020
	while an.year * 12 + an.month < 2020 * 12 + 3 and not an.game_over:
		an._end_month()
	check(an.has_event("re_covid") or an.game_over, "pandemic active spring 2020")
	var imp := 0
	for p in an.feed.posts:
		if p.get("imp", false):
			imp += 1
	check(imp > 0, "important posts flagged for pop-ups")

	print("total ms ", Time.get_ticks_msec() - t0)
	print("FAILURES: ", failures)
	get_tree().quit(1 if failures > 0 else 0)
