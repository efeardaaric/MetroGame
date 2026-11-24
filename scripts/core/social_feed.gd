class_name SocialFeed
extends RefCounted
## "Cıvıltı" — an in-game social network where citizens react to the player's decisions.

signal post_added(post: Dictionary)

const MAX_POSTS := 80

var posts: Array = []      # newest first
var unread := 0
var approval := 55.0       # public opinion 0..100
var _rng := RandomNumberGenerator.new()
var _cooldown := {}        # key -> months remaining
var _next_id := 1
var _complained := {}      # line id -> true (complaint pending a fix)


func _init() -> void:
	_rng.randomize()


# ------------------------------------------------------------------ generation

func _person() -> Dictionary:
	var fn: String = SocialTemplates.FIRST_NAMES[_rng.randi() % SocialTemplates.FIRST_NAMES.size()]
	var ln: String = SocialTemplates.LAST_NAMES[_rng.randi() % SocialTemplates.LAST_NAMES.size()]
	var suf: String = SocialTemplates.HANDLE_SUFFIX[_rng.randi() % SocialTemplates.HANDLE_SUFFIX.size()]
	var handle := (_ascii(fn) + ("." if _rng.randf() < 0.5 else "") + _ascii(ln)).to_lower() + suf
	var hue := _rng.randf()
	return {"name": "%s %s" % [fn, ln], "handle": handle, "color": Color.from_hsv(hue, 0.55, 0.85).to_html(false), "kind": "citizen"}


static func _ascii(s: String) -> String:
	var map := {"ç": "c", "Ç": "c", "ğ": "g", "Ğ": "g", "ı": "i", "İ": "i", "ö": "o", "Ö": "o", "ş": "s", "Ş": "s", "ü": "u", "Ü": "u"}
	var out := ""
	for ch in s:
		out += map.get(ch, ch)
	return out


func _fill(text: String, vars: Dictionary) -> String:
	# Turkish case suffixes: {key:da} locative, {key:dan} ablative, {key:a} dative
	var re := RegEx.new()
	re.compile("\\{(\\w+):(\\w+)\\}")
	for m in re.search_all(text):
		var key := m.get_string(1)
		if vars.has(key):
			var w := str(vars[key])
			text = text.replace(m.get_string(), w + "'" + tr_suffix(w, m.get_string(2)))
	for k in vars.keys():
		text = text.replace("{" + k + "}", str(vars[k]))
	return text


const _DIGIT_TAIL := {"0": ["ı", "r"], "1": ["i", "r"], "2": ["i", ""], "3": ["ü", "ç"], "4": ["ö", "t"],
	"5": ["e", "ş"], "6": ["ı", ""], "7": ["i", ""], "8": ["i", "z"], "9": ["u", "z"]}


## Turkish vowel harmony + consonant assimilation for a suffix after a proper noun.
static func tr_suffix(word: String, kind: String) -> String:
	var w := word.strip_edges()
	if w.is_empty():
		return ""
	var last_vowel := "e"
	var last_cons := ""
	var tail := w.substr(w.length() - 1)
	if _DIGIT_TAIL.has(tail):
		last_vowel = _DIGIT_TAIL[tail][0]
		last_cons = _DIGIT_TAIL[tail][1]
	else:
		var lw := w.to_lower()
		for i in range(lw.length() - 1, -1, -1):
			var ch := lw.substr(i, 1)
			if "aıoueiöüâî".contains(ch):
				last_vowel = ch
				break
		var lc := lw.substr(lw.length() - 1)
		last_cons = "" if "aıoueiöüâî".contains(lc) else lc
	var back := "aıou".contains(last_vowel)
	var a := "a" if back else "e"
	var hard := last_cons != "" and "fsthçşkp".contains(last_cons)
	match kind:
		"da":
			return ("t" if hard else "d") + a
		"dan":
			return ("t" if hard else "d") + a + "n"
		"a":
			return ("y" + a) if last_cons == "" else a
	return ""


func _tag_safe(s: String) -> String:
	return s.replace(" ", "").replace("'", "").replace("-", "")


## Creates a post from a template category. author: "citizen" | "news" | "official"
func post(category: String, vars: Dictionary, state: GameState, author: String = "citizen", boost: float = 1.0) -> Dictionary:
	if not SocialTemplates.T.has(category):
		return {}
	var arr: Array = SocialTemplates.T[category]
	var tpl: Array = arr[_rng.randi() % arr.size()]
	var v := vars.duplicate()
	if state:
		var cn: Array = I18n.STRINGS[state.city.data["name_key"]]
		v["city"] = [_tag_safe(cn[0]), _tag_safe(cn[1])]
		if not v.has("hood"):
			v["hood"] = _tag_safe(_random_hood(state))
		if not v.has("year"):
			v["year"] = state.year
	var who: Dictionary
	match author:
		"news":
			who = SocialTemplates.NEWS[_rng.randi() % SocialTemplates.NEWS.size()].duplicate()
			who["kind"] = "news"
		"official":
			who = SocialTemplates.OFFICIAL.duplicate()
			who["kind"] = "official"
		_:
			who = _person()
	var sentiment: float = tpl[2]
	var base := _rng.randf_range(4.0, 60.0) * boost
	if absf(sentiment) > 0.75:
		base *= 2.2
	if author == "news":
		base *= 6.0
	var viral := _rng.randf() < 0.08 * boost
	if viral:
		base *= 25.0
	var p := {
		"id": _next_id,
		"who": who,
		"tr": _fill(tpl[0], _lang_vars(v, 0)),
		"en": _fill(tpl[1], _lang_vars(v, 1)),
		"sent": sentiment,
		"likes": int(base * _rng.randf_range(0.8, 1.6)),
		"reposts": int(base * _rng.randf_range(0.05, 0.3)),
		"y": state.year if state else 0,
		"m": state.month if state else 0,
		"liked": false,
		"cat": category,
		"viral": viral,
	}
	_next_id += 1
	posts.push_front(p)
	if posts.size() > MAX_POSTS:
		posts.pop_back()
	unread += 1
	_update_approval()
	post_added.emit(p)
	return p


## Vars may hold [tr, en] pairs; pick the right language.
static func _lang_vars(v: Dictionary, idx: int) -> Dictionary:
	var out := {}
	for k in v.keys():
		out[k] = v[k][idx] if v[k] is Array else v[k]
	return out


static func _both(key: String) -> Array:
	var e: Array = I18n.STRINGS.get(key, [key, key])
	return [e[0], e[1]]


func _random_hood(state: GameState) -> String:
	# prefer an unserved, populous district
	var best := ""
	var best_score := -1.0
	for z in state.city.zones:
		if z["poi_id"] != "" or z["pop"] < 50:
			continue
		var served := false
		for s in state.net.stations.values():
			if s["pos"].distance_to(z["pos"]) < 1.2:
				served = true
				break
		var score: float = z["pop"] * (0.15 if served else 1.0) * _rng.randf_range(0.5, 1.5)
		if score > best_score:
			best_score = score
			best = z["name"]
	return best


func text_of(p: Dictionary) -> String:
	return p["tr"] if I18n.lang == "tr" else p["en"]


func _update_approval() -> void:
	var wsum := 0.0
	var ssum := 0.0
	var n := 0
	for p in posts:
		if n >= 40:
			break
		n += 1
		var w := sqrt(float(p["likes"]) + 1.0) * (1.0 - n * 0.015)
		wsum += w
		ssum += w * float(p["sent"])
	if wsum > 0.0:
		approval = clampf(50.0 + 50.0 * ssum / wsum, 0.0, 100.0)


func trending(limit: int = 4) -> Array:
	var counts := {}
	var re := RegEx.new()
	re.compile("#[\\p{L}\\p{N}_]+")
	var n := 0
	for p in posts:
		n += 1
		if n > 40:
			break
		for m in re.search_all(text_of(p)):
			var tag := m.get_string()
			counts[tag] = counts.get(tag, 0) + 1 + int(p["likes"] / 500)
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	return keys.slice(0, limit)


func _cool(key: String, months: int) -> bool:
	if _cooldown.get(key, 0) > 0:
		return false
	_cooldown[key] = months
	return true


# ------------------------------------------------------------------ reactions to game events

func on_line_opened(state: GameState, lid: int, extended: bool) -> void:
	var l: Dictionary = state.net.lines[lid]
	var st: Array = l["stations"]
	var vars := {
		"line": l["name"],
		"a": state.net.station_display_name(st[0]),
		"b": state.net.station_display_name(st[st.size() - 1]),
		"st": state.net.station_display_name(st[_rng.randi() % st.size()]),
		"mode": _both(TransitModes.get_mode(l["mode"])["name_key"]).map(func(x): return x.to_lower()),
	}
	if extended:
		post("line_extend", vars, state)
		if _rng.randf() < 0.6:
			post("line_extend", vars, state)
		return
	post("official_open", vars, state, "official")
	var n := 2 + _rng.randi() % 3
	for i in n:
		vars["st"] = state.net.station_display_name(st[_rng.randi() % st.size()])
		if i == 0 and SocialTemplates.T.has("open_" + l["mode"]):
			post("open_" + l["mode"], vars, state, "citizen", 1.4)
		else:
			post("line_open", vars, state)
	# points of interest served by this line
	for sid in st:
		var poi := state.city.nearest_poi(state.net.stations[sid]["pos"], 1.0)
		if poi.is_empty():
			continue
		var cat := "poi_" + str(poi["kind"])
		if SocialTemplates.T.has(cat) and _cool("poi_" + str(poi["id"]), 999):
			post(cat, {"poi": _both(poi["name_key"]), "poitag": _both(poi["name_key"]).map(func(x): return _tag_safe(x)), "line": l["name"]}, state, "citizen", 1.3)


func on_line_removed(state: GameState, name: String) -> void:
	post("line_removed", {"line": name}, state, "citizen", 1.5)
	post("line_removed", {"line": name}, state)


func on_vehicles_added(state: GameState, lid: int) -> void:
	if not state.net.lines.has(lid):
		return
	var l: Dictionary = state.net.lines[lid]
	if _complained.has(lid) and _cool("veh_%d" % lid, 3):
		_complained.erase(lid)
		post("official_vehicles", {"line": l["name"]}, state, "official")
		post("vehicles_added", {"line": l["name"]}, state, "citizen", 1.2)


func on_goal(state: GameState, text: String) -> void:
	post("goal", {"n": text}, state, "news")


func on_year(state: GameState, report: Dictionary) -> void:
	var good: bool = report["operating_profit"] >= 0.0 or report["satisfaction"] >= 65.0
	post("year_good" if good else "year_bad", {"n": Geo.fmt_short(report["riders"]), "year": report["year"]}, state, "news")


func on_event(state: GameState, eid: String) -> void:
	var ev: Dictionary = CityEvents.EVENTS.get(eid, {})
	if ev.has("post"):
		post(ev["post"], {}, state, "citizen", 1.5)
		if _rng.randf() < 0.5:
			post(ev["post"], {}, state)


func on_tech(state: GameState, id: String) -> void:
	var name := _both("tech_" + id)
	post("tech_official", {"tech": name}, state, "official")
	post("tech_citizen", {"tech": name}, state, "citizen", 1.3)


func on_archaeology(state: GameState, lid: int) -> void:
	var name: String = state.net.lines[lid]["name"] if state.net.lines.has(lid) else "M"
	post("archaeology", {"line": name}, state, "news", 2.0)
	post("archaeology", {"line": name}, state, "citizen", 1.2)


## Called every in-game month.
func monthly(state: GameState) -> void:
	for k in _cooldown.keys():
		_cooldown[k] = int(_cooldown[k]) - 1
		if _cooldown[k] <= 0:
			_cooldown.erase(k)
	var d := state.demand
	if state.net.lines.is_empty():
		if _rng.randf() < 0.5 and _cool("no_net", 4):
			post("no_network", {}, state)
		return
	# complaints about the most crowded line / longest wait
	var worst := -1
	var worst_load := 1.0
	var slow := -1
	var slow_h := 12.0
	for l in state.net.lines.values():
		var lid: int = l["id"]
		var load: float = d.line_load.get(lid, 0.0)
		if load > worst_load:
			worst_load = load
			worst = lid
		var h := state.net.line_headway_min(l)
		if h > slow_h and d.line_riders.get(lid, 0.0) > 2000.0:
			slow_h = h
			slow = lid
	if worst >= 0 and _cool("crowd_%d" % worst, 3):
		var l: Dictionary = state.net.lines[worst]
		var st: Array = l["stations"]
		post("crowded", {"line": l["name"], "st": state.net.station_display_name(st[_rng.randi() % st.size()])}, state, "citizen", 1.0 + worst_load)
		_complained[worst] = true
	if slow >= 0 and _cool("wait_%d" % slow, 4):
		var l: Dictionary = state.net.lines[slow]
		var st: Array = l["stations"]
		post("long_wait", {"line": l["name"], "n": int(slow_h), "st": state.net.station_display_name(st[_rng.randi() % st.size()])}, state)
		_complained[slow] = true
	if state.debt_months > 0 and _cool("debt", 6):
		post("debt", {}, state, "news")
	# general chatter depending on satisfaction
	if _rng.randf() < 0.7:
		var pos := _rng.randf() * 100.0 < d.satisfaction
		var lines: Array = state.net.lines.values()
		var l: Dictionary = lines[_rng.randi() % lines.size()]
		var st: Array = l["stations"]
		post("chatter_pos" if pos else "chatter_neg", {"line": l["name"], "st": state.net.station_display_name(st[_rng.randi() % st.size()])}, state)
	# local flavour
	var flav: String = CityEvents.flavor(state.city).get("chatter", "")
	if flav != "" and _rng.randf() < 0.35 and _cool("flavor", 2):
		post(flav, {}, state)
	# season starts
	var f := CityEvents.flavor(state.city)
	if f.get("summer_months", []).size() > 0 and state.month == f["summer_months"][0]:
		post("ev_summer", {}, state)
	if f.has("fair_month") and state.month == int(f["fair_month"]):
		post("ev_fair", {}, state, "news", 1.5)
	if f.has("university_pois") and state.month == 8:
		post("ev_university", {}, state)
	# likes keep growing on fresh posts
	for i in mini(posts.size(), 8):
		var p: Dictionary = posts[i]
		p["likes"] = int(p["likes"] * _rng.randf_range(1.05, 1.4)) + _rng.randi() % 6


# ------------------------------------------------------------------ persistence

func to_dict() -> Dictionary:
	return {"posts": posts.slice(0, 50), "approval": approval, "next": _next_id, "complained": _complained.keys()}


func from_dict(d: Dictionary) -> void:
	posts = d.get("posts", [])
	for p in posts:
		p["id"] = int(p["id"])
		p["likes"] = int(p["likes"])
		p["reposts"] = int(p["reposts"])
	approval = d.get("approval", 55.0)
	_next_id = int(d.get("next", posts.size() + 1))
	_complained.clear()
	for k in d.get("complained", []):
		_complained[int(k)] = true
	unread = 0
