class_name Management
extends RefCounted
## Operator management layer: fare policy, maintenance budget, night service, wages, loans,
## line incidents (breakdowns, strikes, floods, earthquakes), decision events and timed missions.
## Methods take the GameState explicitly (no stored back-reference → no ref cycle).

signal dilemma_raised(d: Dictionary)
signal incident_started(lid: int, kind: String)
signal mission_changed
signal mission_result(success: bool, m: Dictionary)
signal earthquake(minor: bool)

const MAINT_OPEX := [0.85, 1.0, 1.2]
const MAINT_SAT := [-4.0, 0.0, 2.0]
const MAINT_BREAKDOWN := [2.4, 1.0, 0.3]
const LOAN_YEARS := 5
const LOAN_RATE := 0.07
const MAX_LOANS := 2

var fare := 1.0              # fare policy multiplier 0.6 .. 1.6
var maint := 1               # 0 low, 1 normal, 2 high
var night := false           # 24h weekend service
var wage := 1.0              # permanent opex multiplier from labour deals
var sat_bonus := 0.0
var flags := {}
var loans: Array = []        # [{principal, monthly, months}]
var fare_cap := {}           # {mult, months}
var mission := {}            # active challenge
var pending := {}            # decision awaiting the player
var timed: Array = []        # temporary demand modifiers [{id, mods, months}] e.g. a rival app
var _cooldown := 2
var _mission_cd := 4
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# ------------------------------------------------------------------ economics

func effective_fare() -> float:
	if not fare_cap.is_empty():
		return minf(fare, float(fare_cap["mult"]))
	return fare


func opex_mult() -> float:
	return wage * MAINT_OPEX[maint] * (1.07 if night else 1.0)


func loan_payment() -> float:
	var s := 0.0
	for l in loans:
		s += float(l["monthly"])
	return s


func loan_amount(st: GameState) -> float:
	return roundf(float(st.city.data["annual_grant"]) * 0.8 / 50.0) * 50.0


func take_loan(st: GameState) -> bool:
	if loans.size() >= MAX_LOANS:
		return false
	var amount := loan_amount(st)
	var months := LOAN_YEARS * 12
	var total := amount * (1.0 + LOAN_RATE * LOAN_YEARS)
	loans.append({"principal": amount, "monthly": total / months, "months": months})
	st.cash += amount
	st.cash_changed.emit()
	return true


func repay_cost(l: Dictionary) -> float:
	# early repayment: remaining instalments with a 40% interest discount
	return float(l["monthly"]) * int(l["months"]) * 0.92


func repay(st: GameState, idx: int) -> bool:
	if idx < 0 or idx >= loans.size():
		return false
	var c := repay_cost(loans[idx])
	if not st.spend(c):
		return false
	loans.remove_at(idx)
	return true


## Demand-side effects of the current policies.
func demand_mods() -> Dictionary:
	var f := effective_fare()
	var sat: float = sat_bonus + MAINT_SAT[maint] + (2.0 if night else 0.0)
	sat -= maxf(0.0, f - 1.0) * 16.0
	sat += maxf(0.0, 1.0 - f) * 6.0
	var m := {"fare_pen": (f - 1.0) * 12.0, "sat_add": sat}
	if night:
		m["demand"] = 1.03
	for t in timed:
		for k in t["mods"].keys():
			m[k] = float(m.get(k, 1.0)) * float(t["mods"][k])
	return m


func set_fare(st: GameState, v: float) -> void:
	fare = clampf(snappedf(v, 0.05), 0.6, 1.6)
	st._update_mods()


func set_maint(st: GameState, v: int) -> void:
	maint = clampi(v, 0, 2)
	st._update_mods()


func set_night(st: GameState, on: bool) -> void:
	if on != night:
		st.feed.bump(3.0 if on else -2.0)
	night = on
	st._update_mods()


# ------------------------------------------------------------------ monthly tick

func monthly(st: GameState) -> void:
	var g: float = st.city.data["annual_grant"]
	# loans
	for l in loans:
		l["months"] = int(l["months"]) - 1
	loans = loans.filter(func(l): return int(l["months"]) > 0)
	if not fare_cap.is_empty():
		fare_cap["months"] = int(fare_cap["months"]) - 1
		if fare_cap["months"] <= 0:
			fare_cap = {}
			st._update_mods()
	# temporary modifiers (rival services…)
	var had := timed.size()
	for t in timed:
		t["months"] = int(t["months"]) - 1
	timed = timed.filter(func(t): return int(t["months"]) > 0)
	if timed.size() != had:
		st._update_mods()
	# fleets age
	for l in st.net.lines.values():
		if not l.has("con"):
			l["age"] = int(l.get("age", 0)) + 1
	# incidents expire
	for l in st.net.lines.values():
		if l.has("incident"):
			l["incident"]["months"] = int(l["incident"]["months"]) - 1
			if l["incident"]["months"] <= 0:
				l.erase("incident")
				st.dirty = true
	# random breakdowns (maintenance budget matters)
	for l in st.net.lines.values():
		if l.has("incident") or l["mode"] == "ferry" and _rng.randf() < 0.5:
			continue
		if l.has("con") and int(l["con"]["lo"]) < 0:
			continue
		var chance: float = 0.011 * MAINT_BREAKDOWN[maint] * (1.0 + float(l["vehicles"]) / 40.0) * (1.0 + float(l.get("age", 0)) / 96.0)
		if _rng.randf() < chance:
			set_incident(st, l["id"], "breakdown", 0.5, 1 + _rng.randi() % 2)
	# earthquakes (rare)
	if st.city_id in ["istanbul", "izmir"] and _rng.randf() < 0.006 and st.net.lines.size() >= 2:
		var minor := flags.has("retrofit")
		if not minor:
			var under: Array = st.net.lines.values().filter(func(l): return TransitModes.get_mode(l["mode"])["underground"])
			under.shuffle()
			for l in under.slice(0, 2):
				set_incident(st, l["id"], "quake", 0.0, 2)
			st.cash -= g * 0.15
			st.cash_changed.emit()
			st.feed.bump(-3.0)
		else:
			st.feed.bump(4.0)
		st.feed.post("quake_minor" if minor else "quake_major", {}, st, "news", 2.0)
		earthquake.emit(minor)
	_tick_mission(st)
	# decision events
	_cooldown -= 1
	if pending.is_empty() and _cooldown <= 0 and _rng.randf() < 0.32:
		_raise_dilemma(st)
	_mission_cd -= 1


func set_incident(st: GameState, lid: int, kind: String, cap: float, months: int) -> void:
	if not st.net.lines.has(lid):
		return
	st.net.lines[lid]["incident"] = {"kind": kind, "cap": cap, "months": months}
	st.dirty = true
	st.net.changed.emit()
	var l: Dictionary = st.net.lines[lid]
	if kind in ["breakdown", "strike", "flood"]:
		st.feed.post("inc_" + kind, {"line": l["name"]}, st, "citizen", 1.4)
	incident_started.emit(lid, kind)


func repair_cost(st: GameState, lid: int) -> float:
	var l: Dictionary = st.net.lines[lid]
	return roundf(float(st.city.data["annual_grant"]) * 0.035 + 2.0 * float(l["vehicles"]))


func can_repair(st: GameState, lid: int) -> bool:
	if not st.net.lines.has(lid) or not st.net.lines[lid].has("incident"):
		return false
	return st.net.lines[lid]["incident"]["kind"] != "strike"


func repair(st: GameState, lid: int) -> bool:
	if not can_repair(st, lid):
		return false
	if not st.spend(repair_cost(st, lid)):
		return false
	st.net.lines[lid].erase("incident")
	st.dirty = true
	st.net.changed.emit()
	st.feed.post("inc_fixed", {"line": st.net.lines[lid]["name"]}, st, "official")
	return true


# ------------------------------------------------------------------ decision events

func _raise_dilemma(st: GameState) -> void:
	var cands: Array = []
	var total := 0.0
	var any_crowd := false
	for lid in st.demand.line_load.keys():
		if st.demand.line_load[lid] > 1.0:
			any_crowd = true
	for id in Dilemmas.LIST.keys():
		var d: Dictionary = Dilemmas.LIST[id]
		if st.net.lines.size() < int(d.get("min_lines", 0)):
			continue
		if d.has("requires_city") and not d["requires_city"].has(st.city_id):
			continue
		if d.has("not_flag") and flags.has(d["not_flag"]):
			continue
		if d.get("needs_crowding", false) and not any_crowd:
			continue
		if Dilemmas.MISSIONS.has(_mission_of(d)) and (not mission.is_empty() or _mission_cd > 0):
			continue
		cands.append(id)
		total += float(d["weight"])
	if cands.is_empty():
		return
	var r := _rng.randf() * total
	var pick: String = cands[0]
	for id in cands:
		r -= float(Dilemmas.LIST[id]["weight"])
		if r <= 0.0:
			pick = id
			break
	var ev := {"id": pick}
	var d: Dictionary = Dilemmas.LIST[pick]
	match d.get("target", ""):
		"busy_line":
			ev["line"] = _busiest_line(st, false)
		"underground_line":
			ev["line"] = _busiest_line(st, true)
			if ev["line"] < 0:
				return
		"busy_station":
			ev["station"] = _busiest_station(st)
	pending = ev
	dilemma_raised.emit(ev)


func _mission_of(d: Dictionary) -> String:
	for o in d["options"]:
		if o.has("mission"):
			return o["mission"]
	return ""


func _busiest_line(st: GameState, underground: bool) -> int:
	var best := -1
	var bv := -1.0
	for l in st.net.lines.values():
		if underground and not TransitModes.get_mode(l["mode"])["underground"]:
			continue
		if l.has("incident"):
			continue
		var v: float = st.demand.line_riders.get(l["id"], 0.0) + _rng.randf()
		if v > bv:
			bv = v
			best = l["id"]
	return best


func _busiest_station(st: GameState) -> int:
	var best := -1
	var bv := -1.0
	for s in st.net.stations.values():
		var v: float = st.demand.station_boardings.get(s["id"], 0.0) + _rng.randf()
		if v > bv:
			bv = v
			best = s["id"]
	return best


## Text variables for a pending decision.
func vars_of(st: GameState, ev: Dictionary) -> Dictionary:
	var v := {}
	if ev.has("line") and st.net.lines.has(ev["line"]):
		v["line"] = st.net.lines[ev["line"]]["name"]
	if ev.has("station") and st.net.stations.has(ev["station"]):
		v["station"] = st.net.station_display_name(ev["station"])
	var g: float = st.city.data["annual_grant"]
	var opts: Array = Dilemmas.LIST[ev["id"]]["options"]
	for i in opts.size():
		if opts[i].has("cash_g"):
			v["cost%d" % (i + 1)] = Geo.fmt_money(absf(float(opts[i]["cash_g"]) * g))
	v["loan"] = Geo.fmt_money(loan_amount(st))
	return v


## Applies option `idx` of the pending decision. Returns a short result text.
func resolve(st: GameState, idx: int) -> String:
	if pending.is_empty():
		return ""
	var ev := pending
	pending = {}
	_cooldown = 3 + _rng.randi() % 3
	var id: String = ev["id"]
	var o: Dictionary = Dilemmas.LIST[id]["options"][idx]
	var g: float = st.city.data["annual_grant"]
	var extra := ""
	if o.has("cash_g"):
		var amt := float(o["cash_g"]) * g
		if amt < 0.0:
			if st.sandbox:
				pass
			else:
				st.cash += amt
				st.year_capex -= amt
		else:
			st.cash += amt
		st.cash_changed.emit()
	if o.has("approval"):
		st.feed.bump(float(o["approval"]))
	if o.has("wage"):
		wage += float(o["wage"])
	if o.has("sat_bonus"):
		sat_bonus += float(o["sat_bonus"])
	if o.has("flag"):
		flags[o["flag"]] = true
	if o.has("fare_cap"):
		fare_cap = {"mult": o["fare_cap"][0], "months": o["fare_cap"][1]}
	if o.has("incident") and ev.has("line"):
		set_incident(st, ev["line"], "flood" if id == "flood" else "breakdown", o["incident"]["cap"], o["incident"]["months"])
	if o.has("rename_sponsor") and ev.has("station") and st.net.stations.has(ev["station"]):
		var sp: String = Dilemmas.SPONSORS[_rng.randi() % Dilemmas.SPONSORS.size()]
		var base := st.net.station_display_name(ev["station"])
		st.net.stations[ev["station"]]["name"] = (sp + " " + base).substr(0, 28)
		st.net.changed.emit()
	if o.has("strike"):
		if _rng.randf() < float(o["strike"][0]):
			var ls: Array = st.net.lines.values()
			ls.shuffle()
			for l in ls.slice(0, int(o["strike"][1])):
				set_incident(st, l["id"], "strike", 0.0, 1)
			st.feed.bump(-3.0)
			extra = I18n.t("strike_happened")
		else:
			extra = I18n.t("strike_avoided")
	if o.has("mission"):
		start_mission(st, o["mission"])
	if o.has("rival"):
		timed = timed.filter(func(t): return t["id"] != "rival")
		timed.append({"id": "rival", "mods": {"car": 0.86}, "months": int(o["rival"])})
		st.feed.post("rival", {}, st, "citizen", 1.2)
	st._update_mods()
	st.dirty = true
	var post_cat := "dlg_%s_%d" % [id, idx + 1]
	if SocialTemplates.T.has(post_cat):
		st.feed.post(post_cat, vars_of(st, ev), st, "citizen", 1.3)
	var res := I18n.t("dlg_%s_r%d" % [id, idx + 1])
	return (res + " " + extra).strip_edges()


# ------------------------------------------------------------------ missions

func start_mission(st: GameState, type: String) -> void:
	var spec: Dictionary = Dilemmas.MISSIONS[type]
	var m := {"type": type, "months": spec["months"], "total": spec["months"],
		"reward": roundf(float(spec["reward_g"]) * float(st.city.data["annual_grant"]) / 10.0) * 10.0, "streak": 0}
	match type:
		"riders_growth":
			m["target"] = roundf(maxf(st.riders * 1.3, st.riders + 20000.0) / 1000.0) * 1000.0
		"connect_zone":
			var best: Dictionary = {}
			var bp := -1.0
			for z in st.city.zones:
				if z["poi_id"] != "" or z["pop"] < 80:
					continue
				var served := false
				for s in st.net.stations.values():
					if s["pos"].distance_to(z["pos"]) < 1.2:
						served = true
						break
				var score: float = z["pop"] * _rng.randf_range(0.6, 1.4)
				if not served and score > bp:
					bp = score
					best = z
			if best.is_empty():
				return
			m["zone"] = best["name"]
			m["x"] = best["pos"].x
			m["y"] = best["pos"].y
		"build_mode":
			var options: Array = ["metro", "tram", "metrobus", "rail", "funicular"]
			if not st.city.water_polys.is_empty() and st.city_id not in ["ankara", "eskisehir", "bursa"]:
				options.append("ferry")
			if st.city_id in ["bursa", "trabzon", "izmir"]:
				options.append("gondola")
			var used := st.net.modes_in_use()
			options = options.filter(func(x): return not used.has(x))
			if options.is_empty():
				return
			m["mode"] = options[_rng.randi() % options.size()]
		"no_crowding", "satisfaction":
			m["need"] = spec["need"]
	mission = m
	mission_changed.emit()


func mission_progress(st: GameState) -> float:
	if mission.is_empty():
		return 0.0
	match mission["type"]:
		"riders_growth":
			return clampf(st.riders / float(mission["target"]), 0.0, 1.0)
		"connect_zone":
			return 1.0 if _zone_served(st) else 0.0
		"build_mode":
			return 1.0 if st.net.modes_in_use().has(mission["mode"]) else 0.0
		"no_crowding", "satisfaction":
			return clampf(float(mission["streak"]) / float(mission["need"]), 0.0, 1.0)
	return 0.0


func _zone_served(st: GameState) -> bool:
	var p := Vector2(mission["x"], mission["y"])
	for s in st.net.stations.values():
		if s["pos"].distance_to(p) < 1.2:
			return true
	return false


func mission_text(st: GameState) -> String:
	if mission.is_empty():
		return ""
	match mission["type"]:
		"riders_growth":
			return I18n.t("mis_riders_growth") % Geo.fmt_short(mission["target"])
		"connect_zone":
			return I18n.t("mis_connect_zone") % mission["zone"]
		"build_mode":
			return I18n.t("mis_build_mode") % I18n.t(TransitModes.get_mode(mission["mode"])["name_key"])
		"no_crowding":
			return I18n.t("mis_no_crowding") % int(mission["need"])
		"satisfaction":
			return I18n.t("mis_satisfaction") % [int(Dilemmas.MISSIONS["satisfaction"]["level"]), int(mission["need"])]
	return ""


func _tick_mission(st: GameState) -> void:
	if mission.is_empty():
		return
	match mission["type"]:
		"no_crowding":
			var ok := not st.net.lines.is_empty()
			for lid in st.demand.line_load.keys():
				if st.demand.line_load[lid] > 1.0:
					ok = false
			mission["streak"] = int(mission["streak"]) + 1 if ok else 0
		"satisfaction":
			var ok2 := st.demand.satisfaction >= float(Dilemmas.MISSIONS["satisfaction"]["level"])
			mission["streak"] = int(mission["streak"]) + 1 if ok2 else 0
	mission["months"] = int(mission["months"]) - 1
	if mission_progress(st) >= 0.999:
		var m := mission
		mission = {}
		_mission_cd = 4
		st.cash += float(m["reward"])
		st.cash_changed.emit()
		st.feed.bump(3.0)
		st.feed.post("mission_ok", {}, st, "news", 1.5)
		mission_result.emit(true, m)
	elif int(mission["months"]) <= 0:
		var m2 := mission
		mission = {}
		_mission_cd = 5
		st.feed.bump(float(Dilemmas.MISSIONS[m2["type"]]["fail_approval"]))
		st.feed.post("mission_fail", {}, st, "news", 1.2)
		mission_result.emit(false, m2)
	mission_changed.emit()


# ------------------------------------------------------------------ persistence

func to_dict() -> Dictionary:
	return {"fare": fare, "maint": maint, "night": night, "wage": wage, "sat_bonus": sat_bonus, "flags": flags,
		"loans": loans, "fare_cap": fare_cap, "timed": timed, "mission": mission, "cooldown": _cooldown, "mission_cd": _mission_cd}


func from_dict(d: Dictionary) -> void:
	fare = d.get("fare", 1.0)
	maint = int(d.get("maint", 1))
	night = d.get("night", false)
	wage = d.get("wage", 1.0)
	sat_bonus = d.get("sat_bonus", 0.0)
	flags = d.get("flags", {})
	loans = d.get("loans", [])
	fare_cap = d.get("fare_cap", {})
	timed = d.get("timed", [])
	mission = d.get("mission", {})
	_cooldown = int(d.get("cooldown", 2))
	_mission_cd = int(d.get("mission_cd", 4))
