class_name Elections
extends RefCounted
## Local elections on the real Turkish calendar (end of March 2014, 2019, 2024, 2029…).
## The vote share is driven by rider satisfaction, public opinion, how much of the
## city the network reaches, ridership growth, debt and campaign promises.
## Losing an election ends the campaign.

const YEARS := [2014, 2019, 2024, 2029, 2034, 2039, 2044]
const MONTH := 2               # March (0-based)
const WIN_SHARE := 50.0
const PROMISE_LEAD := 14       # months before the vote when a promise is chosen
const COVERAGE_TARGETS := [0.1, 0.18, 0.26, 0.34]
const PROMISES := ["lines", "riders", "sat"]

var wins := 0
var promise := {}             # {type, base, opened}
var asked := {}               # election year -> true once a promise was offered
var last_riders := 0.0
var last_result := {}
var _poll_seed := 0


func next_year(st: GameState) -> int:
	var now := st.year * 12 + st.month
	for y in YEARS:
		if y * 12 + MONTH >= now and y * 12 + MONTH > st.start_year * 12 + 18:
			return y
	return YEARS[YEARS.size() - 1] + 5


func months_left(st: GameState) -> int:
	return next_year(st) * 12 + MONTH - (st.year * 12 + st.month)


func coverage_target() -> float:
	return COVERAGE_TARGETS[mini(wins, COVERAGE_TARGETS.size() - 1)]


## 0..1 progress of the current promise and whether it is met right now.
func promise_progress(st: GameState) -> float:
	match str(promise.get("type", "")):
		"lines":
			return clampf(float(promise.get("opened", 0)) / 2.0, 0.0, 1.0)
		"riders":
			var base := maxf(float(promise.get("base", 0.0)), 8000.0)
			return clampf((st.riders - base) / (base * 0.3), 0.0, 1.0)
		"sat":
			return clampf((st.demand.satisfaction - 40.0) / 30.0, 0.0, 1.0)
	return 0.0


## Breakdown of the projected vote share (percent).
func vote(st: GameState) -> Dictionary:
	var d := st.demand
	var parts := {}
	parts["base"] = 10.0
	var sat := d.satisfaction if not st.net.lines.is_empty() else 35.0
	parts["sat"] = 0.2 * sat
	parts["approval"] = 0.25 * st.feed.approval
	parts["coverage"] = 22.0 * clampf(d.coverage / coverage_target(), 0.0, 1.2)
	var base_r := maxf(last_riders, 10000.0 * float(st.city.data.get("demand_scale", 1.0)))
	parts["growth"] = 6.0 * clampf((st.riders - last_riders) / base_r, 0.0, 1.0)
	parts["promise"] = 0.0
	if not promise.is_empty():
		parts["promise"] = 6.0 if promise_progress(st) >= 0.999 else -6.0
	parts["debt"] = -(float(st.debt_months) * 3.0 + (3.0 if st.cash < 0.0 else 0.0))
	parts["fatigue"] = -2.0 * wins
	parts["events"] = clampf(st.calendar.rep, -12.0, 12.0)
	var total := 0.0
	for k in parts.keys():
		total += float(parts[k])
	parts["total"] = clampf(total, 5.0, 85.0)
	return parts


## Opinion poll: the projection with a little month-to-month noise.
func poll(st: GameState) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d_%d_%d" % [st.year, st.month, _poll_seed])
	return clampf(float(vote(st)["total"]) + rng.randf_range(-2.5, 2.5), 3.0, 90.0)


## Called at the start of each month. Returns "", "promise" or "held".
func monthly(st: GameState) -> String:
	var left := months_left(st)
	var ey := next_year(st)
	if left == 0:
		var v := vote(st)
		var share: float = v["total"]
		var won := share >= WIN_SHARE
		last_result = {"year": ey, "share": share, "won": won, "parts": v}
		if won:
			wins += 1
			last_riders = st.riders
			st.calendar.rep = 0.0
			st.feed.bump(5.0)
			st.feed.post("elec_win", {"n": int(round(share))}, st, "news", 3.0)
			st.feed.post("elec_win_cit", {"n": int(round(share))}, st, "citizen", 2.0)
		else:
			st.feed.post("elec_lose", {"n": int(round(share))}, st, "news", 3.0)
		promise = {}
		_poll_seed += 1
		return "held"
	if left == PROMISE_LEAD and not asked.has(ey):
		asked[ey] = true
		return "promise"
	if left <= 12 and left % 3 == 0:
		st.feed.post("elec_poll", {"n": int(round(poll(st))), "m": left}, st, "news", 2.0)
	elif left == 1:
		st.feed.post("elec_last", {"n": int(round(poll(st)))}, st, "news", 2.0)
	return ""


func make_promise(st: GameState, type: String) -> void:
	promise = {"type": type, "base": st.riders, "opened": 0}
	st.feed.post("elec_promise_" + type, {}, st, "official", 2.0)


func on_line_opened() -> void:
	if str(promise.get("type", "")) == "lines":
		promise["opened"] = int(promise.get("opened", 0)) + 1


func to_dict() -> Dictionary:
	return {"wins": wins, "promise": promise, "asked": asked.keys(), "last_riders": last_riders, "last": last_result, "seed": _poll_seed}


func from_dict(d: Dictionary) -> void:
	wins = int(d.get("wins", 0))
	promise = d.get("promise", {})
	asked.clear()
	for y in d.get("asked", []):
		asked[int(y)] = true
	last_riders = float(d.get("last_riders", 0.0))
	last_result = d.get("last", {})
	_poll_seed = int(d.get("seed", 0))
