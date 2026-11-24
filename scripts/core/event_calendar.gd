class_name EventCalendar
extends RefCounted
## Runs the dated real-world events of RealEvents for one city: announces them,
## starts them on their date, checks whether the player prepared the venue and
## rewards or punishes accordingly. Also remembers the outcome for elections.

signal announced(e: Dictionary, months_left: int)
signal started(e: Dictionary, served: bool)

var done := {}        # occurrence key -> "ok" | "fail" | "done" | "missed"
var notified := {}    # occurrence key -> true once announced
var rep := 0.0        # election reputation earned from events since the last vote


static func now_t(st: GameState) -> int:
	return st.year * 12 + st.month


func venue_pos(st: GameState, e: Dictionary) -> Vector2:
	var v: Array = e.get("venue", [])
	if v.is_empty():
		return Vector2(-1, -1)
	return st.city.project(v[0], v[1])


func is_served(st: GameState, e: Dictionary) -> bool:
	var p := venue_pos(st, e)
	if p.x < 0.0:
		return true
	for s in st.net.stations.values():
		if s["lines"].size() > 0 and s["pos"].distance_to(p) <= RealEvents.SERVE_KM and st.net.station_operational(s["id"]):
			return true
	return false


## Upcoming announced events, soonest first: [{e, left, key}]
func upcoming(st: GameState) -> Array:
	var out: Array = []
	var now := now_t(st)
	for e in RealEvents.for_city(st.city_id):
		var t := RealEvents.occurrence(e, now)
		var k := RealEvents.key(e, t)
		if done.has(k) or not notified.has(k):
			continue
		var left := t - now
		if left > 0:
			out.append({"e": e, "left": left, "key": k})
	out.sort_custom(func(a, b): return a["left"] < b["left"])
	return out


## Active real events with a venue (for map effects).
func active(st: GameState) -> Array:
	var out: Array = []
	for a in st.active_events:
		if str(a["id"]).begins_with("re_"):
			var e := RealEvents.get_event(str(a["id"]).trim_prefix("re_"))
			if not e.is_empty():
				out.append(e)
	return out


## Called once at the start of every month (and once when a game starts).
func monthly(st: GameState) -> void:
	var now := now_t(st)
	var start := st.start_year * 12
	for e in RealEvents.for_city(st.city_id):
		var t := RealEvents.occurrence(e, now)
		var k := RealEvents.key(e, t)
		if done.has(k):
			continue
		if t < start:
			done[k] = "missed"
			continue
		var left := t - now
		if left < 0:
			done[k] = "missed"
			continue
		if left > 0 and left <= int(e["lead"]) and not notified.has(k):
			notified[k] = true
			st.feed.post("re_announce", {"event": _name(e), "n": left}, st, "news", 2.5)
			announced.emit(e, left)
		elif left > 0 and notified.has(k) and e.get("need_serve", false) and left in [6, 3, 1] and not is_served(st, e):
			st.feed.post("re_reminder", {"event": _name(e), "n": left}, st, "news", 1.8)
		if left == 0:
			_start(st, e, k)
	_sync_zones(st)


func _start(st: GameState, e: Dictionary, k: String) -> void:
	var served := is_served(st, e)
	notified[k] = true
	st.active_events.append({"id": "re_" + str(e["id"]), "months": int(e["months"])})
	var vars := {"event": _name(e)}
	var special := "re_" + str(e["id"])
	if SocialTemplates.T.has(special):
		st.feed.post(special, vars, st, "news", 3.0)
	if e.get("quake", false):
		_quake(st)
	if e.get("need_serve", false):
		var g: float = st.city.data["annual_grant"]
		if served:
			done[k] = "ok"
			var reward := roundf(g * float(e.get("reward", 0.2)))
			if not st.sandbox:
				st.cash += reward
				st.cash_changed.emit()
			st.feed.bump(6.0)
			rep += 4.0
			st.feed.post("re_ok", vars, st, "citizen", 2.0)
			st.feed.post("re_ok_news", vars, st, "news", 2.0)
		else:
			done[k] = "fail"
			st.feed.bump(-6.0)
			rep -= 5.0
			st.feed.post("re_fail", vars, st, "citizen", 2.4)
			st.feed.post("re_fail_news", vars, st, "news", 2.4)
	else:
		done[k] = "done"
	st._update_mods()
	started.emit(e, served)


## Real earthquake: underground lines damaged for a while, emergency spending.
func _quake(st: GameState) -> void:
	var under: Array = st.net.lines.values().filter(func(l): return TransitModes.get_mode(l["mode"])["underground"])
	for l in under.slice(0, 2):
		st.mgmt.set_incident(st, l["id"], "quake", 0.0, 2)
	if not st.sandbox:
		st.cash -= float(st.city.data["annual_grant"]) * 0.1
		st.cash_changed.emit()
	st.mgmt.earthquake.emit(false)


## Event venues attract extra trips while the event runs.
func _sync_zones(st: GameState) -> void:
	var keep := {}
	for e in active(st):
		if e.has("venue") and int(e.get("crowd", 0)) > 0:
			var tag := "ev_" + str(e["id"])
			keep[tag] = true
			st.city.ensure_dynamic_zone(tag, venue_pos(st, e), float(e["crowd"]))
	st.city.prune_dynamic_zones("ev_", keep)


static func _name(e: Dictionary) -> Array:
	var k := "re_" + str(e["id"])
	var v: Array = I18n.STRINGS.get(k, [k, k])
	return [v[0], v[1]]


func to_dict() -> Dictionary:
	return {"done": done, "notified": notified.keys(), "rep": rep}


func from_dict(d: Dictionary) -> void:
	done = d.get("done", {})
	notified.clear()
	for k in d.get("notified", []):
		notified[str(k)] = true
	rep = float(d.get("rep", 0.0))
