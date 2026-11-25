extends Node
## Visual check: zoomed-out map, event traffic effects, venue markers, agenda chips, post pop-ups.

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	I18n.set_language("tr")
	SaveManager.progress = {"stars": {}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	GameScreen.skip_intro = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _open(id: String) -> GameScreen:
	main.start_city(id, true)
	await wait(1.6)
	var g: GameScreen = main.current
	g.auto_quality = false
	g._set_speed(0)
	g.world.day_t = 0.5
	return g


func _zoom(g: GameScreen, lon: float, lat: float, z: float) -> void:
	g.world.camera.position = g.state.city.project(lon, lat) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)


func _run() -> void:
	await wait(1.0)
	await shot("E0_menu")
	for id in ["istanbul", "ankara", "izmir", "antalya"]:
		var g := await _open(id)
		for c in g.ui_layer.get_children():
			if c is Modal:
				c.queue_free()
		g.modal_count = 0
		var z := g.world.camera.min_zoom
		g.world.camera.position = g.state.city.size_km * MapLayer.PX * 0.5
		g.world.camera.zoom = Vector2(z, z)
		g.world._on_zoom(z)
		await wait(0.6)
		await shot("E1_min_" + id)
	# Istanbul derby day traffic
	var g := await _open("istanbul")
	g.state.month = 3
	g.state.active_events.append({"id": "derby", "months": 1})
	g.state.active_events.append({"id": "bridge_traffic", "months": 1})
	g.world.events.refresh()
	g._set_speed(1)
	_zoom(g, 29.03, 41.0, 0.22)
	await wait(1.5)
	await shot("E2_derby")
	_zoom(g, 29.03, 40.99, 0.55)
	await wait(1.0)
	await shot("E3_derby_close")
	# Ankara: jump to 2025, NATO summit announced
	g = await _open("ankara")
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0
	g.state.year = 2025
	g.state.month = 1
	g.state.calendar.monthly(g.state)
	await wait(1.2)
	await shot("E4_nato_modal")
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0
	await wait(0.5)
	_zoom(g, 32.80, 39.91, 0.25)
	g.agenda.refresh()
	await wait(0.8)
	await shot("E5_nato_venue")
	g.state.feed.post("re_reminder", {"event": ["NATO Zirvesi", "NATO Summit"], "n": 6}, g.state, "news", 2.0)
	await wait(0.8)
	await shot("E6_post_pop")
	g.agenda.open_election()
	await wait(0.8)
	await shot("E7_election")
	get_tree().quit()
