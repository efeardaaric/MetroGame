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
	_update_mods()


## Recomputes seasonal + event demand modifiers; marks demand dirty when they change.
func _update_mods() -> void:
	var m := CityEvents.combine(CityEvents.seasonal_mods(city, month), CityEvents.event_mods(active_events))
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


func years_elapsed() -> float:
	return (year - START_YEAR) + month / 12.0


func spend(amount: float) -> bool:
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
	return amount <= cash + credit_limit()


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
		_pending = DemandModel.new(city, snap_net)
		_pending.mods = demand.mods.duplicate(true)
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
	return city.data["annual_grant"] * sat_mult / 12.0


func monthly_income() -> float:
	return riders * 30.0 * FARE / 1_000_000.0


func monthly_expense() -> float:
	return net.total_annual_opex() / 12.0


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
	if debt_months >= DEBT_MONTHS_LIMIT:
		game_over = true
		bankrupt.emit()
		return
	month += 1
	if month >= 12:
		_end_year()
	_tick_events()
	feed.monthly(self)


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
	city.grow(years_elapsed())
	dirty = true
	check_goals()
	year_ended.emit(report)


# ---------------------------------------------------------------- goals

func goals() -> Array:
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
				if s["lines"].size() > 0 and s["pos"].distance_to(poi["pos"]) <= 1.0:
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
	}


func from_dict(d: Dictionary) -> void:
	cash = d.get("cash", cash)
	year = int(d.get("year", START_YEAR))
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
	feed.from_dict(d.get("feed", {}))
	active_events = d.get("events", [])
	_update_mods()
	dirty = true
	recompute_if_dirty()
