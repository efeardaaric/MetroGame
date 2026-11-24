class_name GameState
extends RefCounted
## Simulation state for one city session: money, calendar, ridership, goals.

signal month_passed
signal year_ended(report: Dictionary)
signal cash_changed
signal goals_changed(newly_completed: Array)
signal ridership_updated
signal bankrupt
signal event_started(event_id: String)
signal tech_completed(tech_id: String)
signal construction_done(lid: int)
signal scenario_finished(success: bool, stars: int, score: float)
signal construction_overrun(lid: int, months: int)

const START_YEAR := 2026
const FARE := 10.0            # ₺ per linked trip
const MONTH_SECONDS := 14.0   # real seconds per month at 1x
const RAMP := 0.4             # monthly convergence of ridership to target
const DEBT_MONTHS_LIMIT := 6

var city_id: String
var city: CityMap
var net: TransitNetwork
var demand: DemandModel

var cash := 0.0
var year := START_YEAR
var start_year := START_YEAR
var scenario := {}            # scenario / weekly challenge definition (empty for the campaign)
var grant_mult := 1.0
var scenario_done := false
var month := 0              # 0..11
var month_progress := 0.0
var riders := 0.0           # current daily riders (ramping)
var target_riders := 0.0
var mode_riders := {}
var debt_months := 0
var completed_goals: Array = []
var history: Array = []     # monthly {y, m, riders, income, expense, cash}
var year_income := 0.0
var year_expense := 0.0
var year_capex := 0.0
var last_year_profit := -INF
var best_riders := 0.0
var game_over := false
var dirty := true
var tutorial_step := 0
var total_built := 0.0
var feed := SocialFeed.new()
var mgmt := Management.new()
var researched: Array = []      # tech ids
var research := {}              # {id, months, total} while a project runs
var sandbox := false
var build_log: Array = []       # timelapse: [{y, m, lid, mode, color, pts, op}]
var active_events: Array = []   # [{id, months}]
var _ev_rng := RandomNumberGenerator.new()
var async_demand := false   # GameScreen enables this so heavy recomputes run on a worker thread
var _task_id := -1
var _pending: DemandModel


func _init(id: String) -> void:
	city_id = id
	city = CityMap.new(id)
	net = TransitNetwork.new(city)
	demand = DemandModel.new(city, net)
	cash = city.data["start_cash"]
	net.changed.connect(func(): dirty = true)
	_ev_rng.randomize()
	net.tech = researched
	_update_mods()


## Recomputes seasonal + event demand modifiers; marks demand dirty when they change.
func _update_mods() -> void:
	var parts := [CityEvents.seasonal_mods(city, month), CityEvents.event_mods(active_events),
		TechData.demand_mods(researched), mgmt.demand_mods()]
	var m := {}
	var sat_add := 0.0
	var fare_pen := 0.0
	for part in parts:
		var p: Dictionary = part.duplicate(true)
		sat_add += float(p.get("sat_add", 0.0))
		fare_pen += float(p.get("fare_pen", 0.0))
		p.erase("sat_add")
		p.erase("fare_pen")
		m = CityEvents.combine(m, p)
	m["sat_add"] = sat_add
	m["fare_pen"] = fare_pen
	if m != demand.mods:
		demand.mods = m
		dirty = true


func is_snowing() -> bool:
	if CityEvents.is_winter(city, month):
		return true
	for e in active_events:
		if e["id"] == "snow_storm":
			return true
	return false


func has_event(eid: String) -> bool:
	for e in active_events:
		if e["id"] == eid:
			return true
	return false


## Save slot name: sandbox games live in their own slot.
func slot() -> String:
	if scenario.get("kind", "") == "weekly":
		return "weekly"
	if scenario.get("kind", "") == "scenario":
		return "scn_" + str(scenario["id"])
	return city_id + ("_sandbox" if sandbox else "")


func is_campaign() -> bool:
	return scenario.is_empty() and not sandbox


func allowed_modes() -> Array:
	return scenario.get("allowed", TransitModes.ORDER)


func _check_scenario() -> void:
	if scenario.is_empty() or scenario_done:
		return
	var deadline_reached := float(year - start_year) + month / 12.0 >= float(scenario.get("years", 99))
	if scenario.get("kind", "") == "weekly":
		if deadline_reached:
			scenario_done = true
			scenario_finished.emit(true, 0, best_riders)
		return
	var all_done := true
	for g in goals():
		if not completed_goals.has(g["id"]):
			all_done = false
	if all_done:
		scenario_done = true
		scenario_finished.emit(true, ScenarioData.stars_for(self), best_riders)
	elif deadline_reached:
		scenario_done = true
		scenario_finished.emit(false, 0, best_riders)


func years_elapsed() -> float:
	return (year - start_year) + month / 12.0


func spend(amount: float) -> bool:
	if sandbox:
		total_built += amount
		return true
	if amount > cash + credit_limit():
		return false
	cash -= amount
	year_capex += amount
	total_built += amount
	cash_changed.emit()
	return true


func refund(amount: float) -> void:
	cash += amount
	year_capex -= amount
	cash_changed.emit()


func credit_limit() -> float:
	return city.data["annual_grant"] * 0.5


func can_afford(amount: float) -> bool:
	return sandbox or amount <= cash + credit_limit()


func recompute_if_dirty() -> void:
	_poll_task()
	if not dirty:
		return
	if async_demand:
		if _task_id >= 0:
			return # one at a time; picked up again when the running task finishes
		dirty = false
		var snap_net := TransitNetwork.new(city)
		snap_net.from_dict(net.to_dict())
		snap_net.tech = researched.duplicate()
		_pending = DemandModel.new(city, snap_net)
		_pending.mods = demand.mods.duplicate(true)
		_pending.zones = city.zones.duplicate(true)
		_pending.zones_snapshot = true
		var job := _pending
		_task_id = WorkerThreadPool.add_task(func(): job.compute(), false, "demand")
		return
	dirty = false
	demand.compute()
	_apply_demand()


func _poll_task() -> void:
	if _task_id < 0:
		return
	if not WorkerThreadPool.is_task_completed(_task_id):
		return
	WorkerThreadPool.wait_for_task_completion(_task_id)
	_task_id = -1
	demand.copy_from(_pending)
	_pending = null
	_apply_demand()
	check_goals()


func _apply_demand() -> void:
	target_riders = demand.riders
	mode_riders = demand.mode_riders.duplicate()
	if riders <= 0.0 and target_riders > 0.0:
		riders = target_riders * 0.3
	ridership_updated.emit()


## Blocks until any running async computation has finished (used before saving / in tests).
func flush_demand() -> void:
	if _task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
		demand.copy_from(_pending)
		_pending = null
		_apply_demand()


func monthly_grant() -> float:
	var opinion := demand.satisfaction * 0.7 + feed.approval * 0.3
	var sat_mult := lerpf(0.75, 1.2, opinion / 100.0)
	return city.data["annual_grant"] * grant_mult * sat_mult / 12.0


func monthly_income() -> float:
	return riders * 30.0 * FARE * mgmt.effective_fare() * TechData.mult(researched, "fare") / 1_000_000.0


func monthly_expense() -> float:
	return net.total_annual_opex() * mgmt.opex_mult() / 12.0 + mgmt.loan_payment()


## Advance the simulation by `delta` real seconds at the given speed multiplier.
func advance(delta: float, speed: float) -> void:
	recompute_if_dirty()
	if game_over or speed <= 0.0:
		return
	month_progress += delta * speed / MONTH_SECONDS
	while month_progress >= 1.0:
		month_progress -= 1.0
		_end_month()


func _end_month() -> void:
	recompute_if_dirty()
	riders += (target_riders - riders) * RAMP
	if target_riders <= 0.0:
		riders = 0.0
	best_riders = max(best_riders, riders)
	var inc := monthly_income()
	var grant := monthly_grant()
	var exp := monthly_expense()
	cash += inc + grant - exp
	year_income += inc + grant
	year_expense += exp
	history.append({"y": year, "m": month, "riders": riders, "income": inc + grant, "fare": inc,
					"expense": exp, "cash": cash, "sat": demand.satisfaction})
	if history.size() > 120:
		history.pop_front()
	if cash < -credit_limit():
		debt_months += 1
	else:
		debt_months = 0
	cash_changed.emit()
	month_passed.emit()
	check_goals()
	if sandbox:
		debt_months = 0
	if debt_months >= DEBT_MONTHS_LIMIT:
		game_over = true
		bankrupt.emit()
		return
	month += 1
	if month >= 12:
		_end_year()
	_tick_events()
	_tick_research()
	_tick_construction()
	_check_scenario()
	mgmt.monthly(self)
	feed.monthly(self)


# ---------------------------------------------------------------- construction

const BUILD_MONTHS_KM := {"metro": 0.55, "tram": 0.28, "metrobus": 0.14, "rail": 0.3, "funicular": 1.4, "gondola": 0.5, "ferry": 0.0}


static func build_months(mode: String, deep: bool, length_km: float, new_stations: int) -> int:
	var per: float = BUILD_MONTHS_KM.get(mode, 0.3) * (1.5 if deep else 1.0)
	var m := length_km * per + new_stations * (0.35 if mode == "metro" else 0.15) + 1.0
	if mode == "ferry":
		m = 1.0 + new_stations * 0.5
	return clampi(int(ceil(m)), 1, 30)


## Puts a freshly committed line (or extension) under construction.
func start_construction(lid: int, months: int, prev_count: int, at_start: bool, cost: float) -> void:
	if not net.lines.has(lid):
		return
	var l: Dictionary = net.lines[lid]
	var n: int = l["stations"].size()
	var lo := -1
	var hi := -1
	if prev_count > 0:
		var added := n - prev_count
		if l.get("loop", false):
			added = maxi(0, added)
		lo = added if at_start else 0
		hi = n - 1 if at_start else prev_count - 1
		if l.get("loop", false):
			lo = 0
			hi = prev_count - 1
	if sandbox:
		months = maxi(1, months / 3)
	l["con"] = {"months": months, "total": months, "lo": lo, "hi": hi, "cost": cost, "overrun": false, "rushed": false}
	dirty = true
	net.changed.emit()


func rush_cost(lid: int) -> float:
	var c: Dictionary = net.lines[lid]["con"]
	return roundf(float(c["cost"]) * 0.3)


## Pays extra to halve the remaining construction time (once per project).
func rush_construction(lid: int) -> bool:
	if not net.lines.has(lid) or not net.lines[lid].has("con"):
		return false
	var c: Dictionary = net.lines[lid]["con"]
	if c.get("rushed", false) or int(c["months"]) <= 1:
		return false
	if not spend(rush_cost(lid)):
		return false
	c["months"] = maxi(1, int(ceil(int(c["months"]) / 2.0)))
	c["rushed"] = true
	return true


func _tick_construction() -> void:
	for l in net.lines.values():
		if not l.has("con"):
			continue
		var c: Dictionary = l["con"]
		c["months"] = int(c["months"]) - 1
		if int(c["months"]) <= 0:
			# one-off cost overrun check right before opening
			if not c.get("overrun", false) and int(c["total"]) >= 3 and _ev_rng.randf() < 0.22:
				c["overrun"] = true
				var extra := roundf(float(c["cost"]) * _ev_rng.randf_range(0.08, 0.22))
				var delay := 1 + _ev_rng.randi() % 3
				c["months"] = delay
				if not sandbox:
					cash -= extra
					year_capex += extra
				cash_changed.emit()
				feed.post("con_overrun", {"line": l["name"], "n": delay}, self, "news", 1.4)
				construction_overrun.emit(l["id"], delay)
				continue
			l.erase("con")
			dirty = true
			net.changed.emit()
			construction_done.emit(l["id"])


# ---------------------------------------------------------------- assets

func modernize_cost(lid: int) -> float:
	var l: Dictionary = net.lines[lid]
	var m := TransitModes.get_mode(l["mode"])
	return roundf(float(l.get("built_cost", 0.0)) * 0.12 + float(l["vehicles"]) * m["vehicle_cost"] * 0.35)


func modernize(lid: int) -> bool:
	if not net.lines.has(lid) or not spend(modernize_cost(lid)):
		return false
	net.lines[lid]["age"] = 0
	net.lines[lid]["modern"] = true
	feed.post("modernized", {"line": net.lines[lid]["name"]}, self, "citizen", 1.3)
	feed.bump(2.0)
	dirty = true
	return true


func hub_cost() -> float:
	return roundf(float(city.data["annual_grant"]) * 0.09 / 10.0) * 10.0


func upgrade_hub(sid: int) -> bool:
	if not net.stations.has(sid) or net.stations[sid].get("hub", 0) > 0:
		return false
	if not spend(hub_cost()):
		return false
	net.stations[sid]["hub"] = 1
	_sync_hub_zones()
	feed.post("hub_open", {"station": net.station_display_name(sid)}, self, "citizen", 1.3)
	net.changed.emit()
	dirty = true
	return true


## Interchange hubs attract shops and offices: modelled as small job centres.
func _sync_hub_zones() -> void:
	for sid in net.stations.keys():
		var s: Dictionary = net.stations[sid]
		if s.get("hub", 0) > 0:
			city.ensure_dynamic_zone("hub_%d" % sid, s["pos"], 45.0)
	var keep := {}
	for sid in net.stations.keys():
		if net.stations[sid].get("hub", 0) > 0:
			keep["hub_%d" % sid] = true
	city.prune_dynamic_zones("hub_", keep)


## Transit-oriented development: busy stations grow their neighbourhoods every year.
func _recompute_tod() -> void:
	for z in city.zones:
		if z["poi_id"] != "":
			continue
		var t := 0.0
		for s in net.stations.values():
			if s["pos"].distance_to(z["pos"]) <= float(z["r"]) + 0.8:
				t += float(s.get("dev", 0.0)) * 0.05
		z["tod"] = 1.0 + minf(0.4, t)
	city.grow(years_elapsed())


func _develop_stations() -> void:
	for s in net.stations.values():
		if not net.station_operational(s["id"]):
			continue
		var b: float = demand.station_boardings.get(s["id"], 0.0)
		if b > 1500.0:
			s["dev"] = minf(1.0, float(s.get("dev", 0.0)) + 0.1 + b / 250000.0)
	for z in city.zones:
		if z["poi_id"] != "":
			continue
		var t := 0.0
		for s in net.stations.values():
			if s["pos"].distance_to(z["pos"]) <= float(z["r"]) + 0.8:
				t += float(s.get("dev", 0.0)) * 0.05
		z["tod"] = 1.0 + minf(0.4, t)


# ---------------------------------------------------------------- research

func tech_state(id: String) -> String:
	if researched.has(id):
		return "done"
	if research.get("id", "") == id:
		return "running"
	var t := TechData.get_tech(id)
	if year < int(t.get("year", 0)):
		return "locked_year"
	if t.has("requires") and not researched.has(t["requires"]):
		return "locked_req"
	if not research.is_empty():
		return "busy"
	return "available"


func start_research(id: String) -> bool:
	if tech_state(id) != "available":
		return false
	var t := TechData.get_tech(id)
	if not spend(t["cost"]):
		return false
	research = {"id": id, "months": int(t["months"]), "total": int(t["months"])}
	return true


func _tick_research() -> void:
	if research.is_empty():
		return
	research["months"] = int(research["months"]) - 1
	if research["months"] <= 0:
		var id: String = research["id"]
		research = {}
		researched.append(id)
		_update_mods()
		dirty = true
		feed.on_tech(self, id)
		tech_completed.emit(id)


# ---------------------------------------------------------------- timelapse log

func log_line(lid: int) -> void:
	if not net.lines.has(lid):
		return
	var l: Dictionary = net.lines[lid]
	var pts: Array = []
	for p in net.line_path(l):
		pts.append([snappedf(p.x, 0.01), snappedf(p.y, 0.01)])
	build_log.append({"y": year, "m": month, "lid": lid, "mode": l["mode"], "color": l["color"], "pts": pts, "op": "set"})


func log_remove(lid: int) -> void:
	build_log.append({"y": year, "m": month, "lid": lid, "op": "del"})


func _tick_events() -> void:
	for e in active_events:
		e["months"] = int(e["months"]) - 1
	active_events = active_events.filter(func(e): return e["months"] > 0)
	for eid in CityEvents.roll_events(city, month, _ev_rng, active_events):
		active_events.append({"id": eid, "months": CityEvents.EVENTS[eid]["months"]})
		feed.on_event(self, eid)
		event_started.emit(eid)
	_update_mods()


func _end_year() -> void:
	var fare_income := 0.0
	for h in history:
		if h["y"] == year:
			fare_income += h["fare"]
	var report := {
		"year": year,
		"income": year_income,
		"fare_income": fare_income,
		"grant": year_income - fare_income,
		"expense": year_expense,
		"capex": year_capex,
		"profit": year_income - year_expense,
		"operating_profit": fare_income - year_expense,
		"riders": riders,
		"satisfaction": demand.satisfaction,
		"coverage": demand.coverage,
		"cash": cash,
		"lines": net.lines.size(),
		"stations": net.stations.size(),
	}
	last_year_profit = fare_income - year_expense
	feed.on_year(self, report)
	year += 1
	month = 0
	year_income = 0.0
	year_expense = 0.0
	year_capex = 0.0
	_develop_stations()
	city.grow(years_elapsed())
	dirty = true
	check_goals()
	year_ended.emit(report)


# ---------------------------------------------------------------- goals

func goals() -> Array:
	if not scenario.is_empty():
		return scenario.get("objectives", [])
	return city.data["goals"]


func goal_progress(goal: Dictionary) -> float:
	match goal["type"]:
		"riders":
			return clampf(riders / float(goal["value"]), 0.0, 1.0)
		"serve_pois":
			var n := 0
			for pid in goal["pois"]:
				if _poi_served(pid):
					n += 1
			return float(n) / goal["pois"].size()
		"cross_sides":
			return 1.0 if _crosses_sides() else 0.0
		"modes":
			var used := 0
			for m in net.modes_in_use():
				if mode_riders.get(m, 0.0) > 500.0:
					used += 1
			return clampf(float(used) / goal["value"], 0.0, 1.0)
		"mode_riders":
			return clampf(mode_riders.get(goal["mode"], 0.0) / float(goal["value"]), 0.0, 1.0)
		"profit":
			return 1.0 if last_year_profit >= 0.0 else 0.0
		"coverage":
			return clampf(demand.coverage / float(goal["value"]), 0.0, 1.0)
	return 0.0


func _poi_served(pid: String) -> bool:
	for poi in city.pois:
		if poi["id"] == pid:
			for s in net.stations.values():
				if s["lines"].size() > 0 and s["pos"].distance_to(poi["pos"]) <= 1.0 and net.station_operational(s["id"]):
					return true
	return false


func _crosses_sides() -> bool:
	# a single connected component with stations on both sides
	var comp := {}
	var cid := 0
	for sid in net.stations.keys():
		if comp.has(sid):
			continue
		var stack := [sid]
		comp[sid] = cid
		while not stack.is_empty():
			var s: int = stack.pop_back()
			for lid in net.stations[s]["lines"]:
				for o in net.lines[lid]["stations"]:
					if not comp.has(o):
						comp[o] = cid
						stack.append(o)
			for o in net.stations.keys():
				if not comp.has(o) and net.stations[o]["pos"].distance_to(net.stations[s]["pos"]) <= 0.45:
					comp[o] = cid
					stack.append(o)
		cid += 1
	var sides := {}
	for sid in comp.keys():
		var key := "%d_%d" % [comp[sid], city.side_of(net.stations[sid]["pos"])]
		sides[key] = true
	for c in cid:
		if sides.has("%d_0" % c) and sides.has("%d_1" % c):
			return true
	return false


func check_goals() -> void:
	var newly: Array = []
	for g in goals():
		if completed_goals.has(g["id"]):
			continue
		if goal_progress(g) >= 0.999:
			completed_goals.append(g["id"])
			newly.append(g)
	if not newly.is_empty():
		goals_changed.emit(newly)


func stars() -> int:
	var sg: Array = city.data["star_goals"]
	var n := completed_goals.size()
	var s := 0
	for i in sg.size():
		if n >= sg[i]:
			s = i + 1
	return s


# ---------------------------------------------------------------- persistence

func to_dict() -> Dictionary:
	return {
		"version": 1, "city": city_id, "cash": cash, "year": year, "month": month,
		"month_progress": month_progress, "riders": riders, "debt_months": debt_months,
		"completed_goals": completed_goals, "history": history, "year_income": year_income,
		"year_expense": year_expense, "year_capex": year_capex, "last_year_profit": last_year_profit if last_year_profit > -1e30 else -1e30,
		"best_riders": best_riders, "game_over": game_over, "tutorial_step": tutorial_step,
		"total_built": total_built, "network": net.to_dict(),
		"feed": feed.to_dict(), "events": active_events,
		"mgmt": mgmt.to_dict(), "start_year": start_year, "scenario": scenario, "grant_mult": grant_mult,
		"scenario_done": scenario_done, "researched": researched, "research": research, "sandbox": sandbox, "build_log": build_log,
	}


func from_dict(d: Dictionary) -> void:
	cash = d.get("cash", cash)
	year = int(d.get("year", START_YEAR))
	start_year = int(d.get("start_year", START_YEAR))
	scenario = d.get("scenario", {})
	grant_mult = d.get("grant_mult", 1.0)
	scenario_done = d.get("scenario_done", false)
	month = int(d.get("month", 0))
	month_progress = d.get("month_progress", 0.0)
	riders = d.get("riders", 0.0)
	debt_months = int(d.get("debt_months", 0))
	completed_goals = d.get("completed_goals", [])
	history = d.get("history", [])
	year_income = d.get("year_income", 0.0)
	year_expense = d.get("year_expense", 0.0)
	year_capex = d.get("year_capex", 0.0)
	var lyp: float = d.get("last_year_profit", -1e30)
	last_year_profit = -INF if lyp <= -1e29 else lyp
	best_riders = d.get("best_riders", 0.0)
	game_over = d.get("game_over", false)
	tutorial_step = int(d.get("tutorial_step", 99))
	total_built = d.get("total_built", 0.0)
	city.grow(years_elapsed())
	net.from_dict(d.get("network", {}))
	_sync_hub_zones()
	for z in city.zones:
		z["tod"] = 1.0
	_recompute_tod()
	feed.from_dict(d.get("feed", {}))
	mgmt.from_dict(d.get("mgmt", {}))
	researched.clear()
	researched.append_array(d.get("researched", []))
	research = d.get("research", {})
	sandbox = d.get("sandbox", false)
	build_log = d.get("build_log", [])
	active_events = d.get("events", [])
	_update_mods()
	dirty = true
	recompute_if_dirty()
