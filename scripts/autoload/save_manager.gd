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
	var id := state.city_id
	progress["stars"][id] = max(city_stars(id), state.stars())
	progress["best_riders"][id] = max(float(progress["best_riders"].get(id, 0.0)), state.best_riders)
	progress["last_city"] = id
	save_progress()


func save_path(id: String) -> String:
	return "user://save_%s.json" % id


func has_save(id: String) -> bool:
	return FileAccess.file_exists(save_path(id))


func save_game(state: GameState) -> void:
	var f := FileAccess.open(save_path(state.city_id), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state.to_dict()))
	record_result(state)


func load_game(id: String) -> GameState:
	var st := GameState.new(id)
	if not has_save(id):
		return st
	var f := FileAccess.open(save_path(id), FileAccess.READ)
	if f == null:
		return st
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		st.from_dict(parsed)
	return st


func delete_save(id: String) -> void:
	if has_save(id):
		DirAccess.remove_absolute(save_path(id))


func last_city() -> String:
	var lc: String = progress.get("last_city", "")
	return lc if lc != "" and has_save(lc) else ""
