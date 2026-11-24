extends Node
## Generates store screenshots and a trailer from the real game.
## Screenshots:  godot --path . --resolution 1290x2796 tools/store_media.tscn -- --out=DIR --mode=shots
## Trailer:      godot --path . --resolution 720x1280 --write-movie out.avi --fixed-fps 30 tools/store_media.tscn -- --mode=trailer

var out_dir := "user://store"
var mode := "shots"
var main: Node
var g: GameScreen


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		if a.begins_with("--mode="):
			mode = a.substr(7)
		if a.begins_with("--lang="):
			I18n.set_language(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out_dir)
	Settings.high_quality = true
	SaveManager.progress = {"stars": {"istanbul": 3, "ankara": 3}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if mode == "trailer":
		_trailer()
	else:
		_shots()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _setup_network() -> void:
	main.start_city("istanbul", true)
	await wait(1.6)
	g = main.current
	g.auto_quality = false
	g.toast.visible = false
	g.ach_banner.visible = false
	g.world.apply_quality(true)
	var st := g.state
	st.cash = 80000.0
	var specs := [
		["metro", false, [[28.87, 40.985], [28.905, 40.995], [28.948, 41.008], [28.977, 41.03], [28.987, 41.062], [29.012, 41.08], [29.02, 41.11]]],
		["metro", true, [[28.86, 41.0], [28.91, 41.003], [28.948, 41.008], [29.003, 41.022], [29.03, 40.99], [29.08, 40.98], [29.13, 40.94], [29.19, 40.905]]],
		["tram", false, [[28.905, 41.04], [28.93, 41.02], [28.948, 41.008], [28.975, 41.006]]],
		["ferry", false, [[29.026, 40.993], [29.003, 41.03], [29.02, 41.045]]],
		["metro", false, [[29.03, 41.026], [29.07, 41.022], [29.115, 41.025], [29.18, 41.035]]],
		["metrobus", false, [[28.72, 40.985], [28.78, 40.995], [28.84, 41.0], [28.9, 41.02], [28.96, 41.045], [28.99, 41.065]]],
	]
	for sp in specs:
		var nodes := ScenarioData.lonlat_pts(st, sp[2])
		var ev := st.net.evaluate_draft(sp[0], sp[1], nodes)
		var lid := st.net.commit_draft(sp[0], sp[1], nodes, ev["cost"], -1, false, ev["vehicles"])
		st.net.lines[lid]["vehicles"] = 14 if sp[0] != "ferry" else 5
	for s in st.net.stations.values():
		s["dev"] = 0.5
	st.dirty = true
	st.recompute_if_dirty()
	st.riders = st.target_riders
	for i in 8:
		st.feed.monthly(st)
	g._update_hud()
	g.world.growth.queue_redraw()
	st.active_events.clear()
	st._ev_rng.seed = 1
	st._update_mods()
	g._set_speed(2)


func _cam(lon: float, lat: float, z: float) -> void:
	g.world.camera.position = g.state.city.project(lon, lat) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)


func _clear_modals() -> void:
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0


func _shots() -> void:
	await wait(1.2)
	await shot("01_menu")
	await _setup_network()
	g.agenda.pop_holder.visible = false
	g.world.day_t = 0.45
	_cam(28.99, 41.02, 0.2)
	await wait(1.5)
	await shot("02_network")
	# derby day: jammed roads around the stadium
	g.state.month = 3
	g.state.active_events.append({"id": "derby", "months": 1})
	g.state.active_events.append({"id": "bridge_traffic", "months": 1})
	g.world.events.refresh()
	_cam(29.03, 41.0, 0.42)
	await wait(1.6)
	await shot("03_derby")
	g.state.active_events.clear()
	g.world.events.refresh()
	g.world.day_t = 0.9
	_cam(29.0, 41.02, 0.17)
	await wait(1.5)
	await shot("04_night")
	g.world.day_t = 0.45
	# a real event announced: the 2023 European cup final
	g.state.year = 2022
	g.state.month = 0
	g.state.calendar.monthly(g.state)
	g.agenda.refresh()
	await wait(1.4)
	await shot("05_event")
	_clear_modals()
	g.agenda.open_election()
	await wait(1.2)
	await shot("06_election")
	_clear_modals()
	g.open_social()
	await wait(1.0)
	await shot("07_social")
	g.sheet.close()
	var lid: int = g.state.net.lines.keys()[1]
	g.show_modal(g.panels.profile_modal(lid))
	await wait(1.5)
	await shot("08_profile")
	get_tree().quit()


func _trailer() -> void:
	await wait(1.5)
	await _setup_network()
	g._set_speed(1)
	g.state.mgmt._cooldown = 999
	g.hud.modulate.a = 0.0
	g.nav.modulate.a = 0.0
	g.world.day_t = 0.3
	_cam(28.95, 41.04, 0.12)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float):
		var a := g.state.city.project(28.93, 41.06) * MapLayer.PX
		var b := g.state.city.project(29.0, 41.02) * MapLayer.PX
		g.world.camera.position = a.lerp(b, t)
		var z := lerpf(0.12, 0.42, t)
		g.world.camera.zoom = Vector2(z, z)
		g.world._on_zoom(z)
		g.world.day_t = lerpf(0.3, 0.95, t)
	, 0.0, 1.0, 9.0)
	tw.tween_callback(func():
		g.world.day_t = 0.5
		g.world.set_diagram(true)
		_cam(29.0, 41.02, 0.14)
	)
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		g.world.set_diagram(false)
		g.world.day_t = 0.5
		g.hud.modulate.a = 1.0
		g.nav.modulate.a = 1.0
		g.confetti.burst(160)
	)
	tw.tween_interval(3.0)
	tw.tween_callback(func(): get_tree().quit())
