extends Node
## Campaign progress + per-city save slots (JSON in user://).

const PROGRESS_PATH := "user://progress.json"

var progress := {"stars": {}, "best_riders": {}, "tutorial_done": false, "last_city": ""}


func _ready() -> void:
	_load_progress()


func _load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed.keys():
			progress[k] = parsed[k]


func save_progress() -> void:
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(progress))


func total_stars() -> int:
	var s := 0
	for v in progress["stars"].values():
		s += int(v)
	return s


func city_stars(id: String) -> int:
	return int(progress["stars"].get(id, 0))


func is_unlocked(id: String) -> bool:
	var d := CityData.get_city(id)
	return total_stars() >= int(d.get("unlock_stars", 0))


func record_result(state: GameState) -> void:
	progress["last_city"] = state.slot()
	if not state.is_campaign():
		save_progress()
		return
	var id := state.city_id
	progress["stars"][id] = max(city_stars(id), state.stars())
	progress["best_riders"][id] = max(float(progress["best_riders"].get(id, 0.0)), state.best_riders)
	Platform.submit_score(state.best_riders)
	save_progress()


func save_path(id: String) -> String:
	return "user://save_%s.json" % id


func has_save(id: String) -> bool:
	return FileAccess.file_exists(save_path(id))


func save_game(state: GameState) -> void:
	var f := FileAccess.open(save_path(state.slot()), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state.to_dict()))
	record_result(state)


## `slot` is a city id, optionally suffixed with "_sandbox".
func load_game(slot: String) -> GameState:
	var parsed = null
	if has_save(slot):
		var f := FileAccess.open(save_path(slot), FileAccess.READ)
		if f:
			parsed = JSON.parse_string(f.get_as_text())
	var id := slot.trim_suffix("_sandbox")
	if parsed is Dictionary and parsed.has("city"):
		id = parsed["city"]
	var st := GameState.new(id)
	st.sandbox = slot.ends_with("_sandbox")
	if parsed is Dictionary:
		st.from_dict(parsed)
	return st


func record_scenario(id: String, stars: int) -> void:
	if not progress.has("scenarios"):
		progress["scenarios"] = {}
	progress["scenarios"][id] = maxi(int(progress["scenarios"].get(id, 0)), stars)
	save_progress()


func scenario_stars(id: String) -> int:
	return int(progress.get("scenarios", {}).get(id, 0))


func record_weekly(week: int, score: float) -> bool:
	var w: Dictionary = progress.get("weekly", {})
	var best := 0.0
	if int(w.get("week", 0)) == week:
		best = float(w.get("best", 0.0))
	var improved := score > best
	progress["weekly"] = {"week": week, "best": maxf(best, score)}
	save_progress()
	return improved


func weekly_best(week: int) -> float:
	var w: Dictionary = progress.get("weekly", {})
	return float(w.get("best", 0.0)) if int(w.get("week", 0)) == week else 0.0


func delete_save(id: String) -> void:
	if has_save(id):
		DirAccess.remove_absolute(save_path(id))


func last_city() -> String:
	var lc: String = progress.get("last_city", "")
	if lc.begins_with("scn_") or lc == "weekly":
		return lc if has_save(lc) else ""
	return lc if lc != "" and has_save(lc) else ""



## Packs progress + every save slot into a compact text code (clipboard transfer).
func export_code() -> String:
	var bundle := {"progress": progress, "saves": {}, "v": 1}
	var d := DirAccess.open("user://")
	if d:
		for f in d.get_files():
			if f.begins_with("save_") and f.ends_with(".json"):
				var fa := FileAccess.open("user://" + f, FileAccess.READ)
				if fa:
					bundle["saves"][f] = fa.get_as_text()
	var raw := JSON.stringify(bundle).to_utf8_buffer()
	return "RAYA1:" + Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_GZIP))


func import_code(code: String) -> bool:
	code = code.strip_edges()
	if not code.begins_with("RAYA1:"):
		return false
	var packed := Marshalls.base64_to_raw(code.substr(6))
	if packed.is_empty():
		return false
	var raw := packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var parsed = JSON.parse_string(raw.get_string_from_utf8())
	if not (parsed is Dictionary) or not parsed.has("progress"):
		return false
	for f in parsed.get("saves", {}).keys():
		if str(f).begins_with("save_") and str(f).ends_with(".json") and not str(f).contains("/"):
			var fa := FileAccess.open("user://" + f, FileAccess.WRITE)
			if fa:
				fa.store_string(parsed["saves"][f])
	for k in parsed["progress"].keys():
		progress[k] = parsed["progress"][k]
	save_progress()
	return true
