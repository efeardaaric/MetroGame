class_name Achievements
extends RefCounted
## Persistent achievements (stored in SaveManager.progress["achievements"]).
## Disabled in sandbox mode. Ids map to i18n keys "ach_<id>" and "ach_<id>_d".

const LIST: Array = [
	["first_line", "build"], ["loop", "undo"], ["network_10", "lines"], ["stations_50", "target"],
	["deep_dive", "profile"], ["bosphorus", "extend"], ["ferry_captain", "bird"], ["hill_climber", "profile"],
	["all_modes", "star"], ["riders_100k", "people"], ["riders_1m", "people"], ["profitable", "coin"],
	["tycoon", "coin"], ["beloved", "heart"], ["viral", "megaphone"], ["archaeologist", "info"],
	["tech_all", "gear"], ["decade", "calendar"], ["three_stars", "trophy"],
]


static func unlocked() -> Dictionary:
	if not SaveManager.progress.has("achievements"):
		SaveManager.progress["achievements"] = {}
	return SaveManager.progress["achievements"]


static func is_unlocked(id: String) -> bool:
	return unlocked().has(id)


static func icon_of(id: String) -> String:
	for a in LIST:
		if a[0] == id:
			return a[1]
	return "trophy"


## Evaluates all conditions; returns ids unlocked now. `flags` carries one-off events
## (e.g. {"archaeology": true, "viral": true}).
static func check(st: GameState, flags: Dictionary = {}) -> Array:
	if not st.is_campaign():
		return []
	var got: Array = []
	var net := st.net
	var modes := {}
	var any_loop := false
	var deep_sea := false
	var ferry_riders := 0.0
	for l in net.lines.values():
		modes[l["mode"]] = true
		if l.get("loop", false):
			any_loop = true
		if l["mode"] == "ferry":
			ferry_riders += st.demand.line_riders.get(l["id"], 0.0)
		if l.get("deep", false) and not deep_sea:
			var path := net.line_path(l)
			for i in path.size() - 1:
				for k in 8:
					if st.city.is_sea(path[i].lerp(path[i + 1], (k + 0.5) / 8.0)):
						deep_sea = true
	var conds := {
		"first_line": net.lines.size() >= 1,
		"loop": any_loop,
		"network_10": net.lines.size() >= 10,
		"stations_50": net.stations.size() >= 50,
		"deep_dive": deep_sea,
		"bosphorus": st.completed_goals.has("cross_bosphorus"),
		"ferry_captain": ferry_riders >= 5000.0,
		"hill_climber": modes.has("funicular"),
		"all_modes": modes.size() >= 6,
		"riders_100k": st.riders >= 100000.0,
		"riders_1m": st.riders >= 1000000.0,
		"profitable": st.last_year_profit >= 0.0 and st.last_year_profit > -1e29,
		"tycoon": st.cash >= 30000.0,
		"beloved": st.feed.approval >= 80.0 and st.feed.posts.size() >= 20,
		"viral": flags.get("viral", false),
		"archaeologist": flags.get("archaeology", false),
		"tech_all": st.researched.size() >= TechData.TECH.size(),
		"decade": st.years_elapsed() >= 10.0,
		"three_stars": st.stars() >= 3,
	}
	var u := unlocked()
	for id in conds.keys():
		if conds[id] and not u.has(id):
			u[id] = "%d-%02d" % [st.year, st.month + 1]
			got.append(id)
			Platform.unlock_achievement(id)
	if not got.is_empty():
		SaveManager.save_progress()
	return got
