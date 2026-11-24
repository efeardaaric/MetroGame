extends Node
## Records the raw scenes for the social-media promo in one Movie Maker run.
## Run: godot --path . --resolution 1080x1920 --write-movie raw.avi --fixed-fps 30 tools/promo_capture.tscn
## Prints "SCENE <name> <frame>" markers that tools/make_promo.py uses to cut the clips.

var main: Node
var g: GameScreen


func _ready() -> void:
	Settings.high_quality = true
	Settings.reduce_motion = false
	Settings.colorblind = false
	var lang := "tr"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lang = a.substr(7)
	I18n.set_language(lang)
	SaveManager.progress = {"stars": {"istanbul": 3, "ankara": 3, "izmir": 3}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func mark(name: String) -> void:
	print("SCENE %s %d" % [name, Engine.get_frames_drawn()])


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _quiet(screen: GameScreen) -> void:
	screen.auto_quality = false
	screen.toast.visible = false
	screen.ach_banner.visible = false
	screen.state.mgmt._cooldown = 9999
	screen.state.active_events.clear()
	screen.state._update_mods()
	screen.world.apply_quality(true)


func _cam(lon: float, lat: float, z: float) -> void:
	g.world.camera.position = g.state.city.project(lon, lat) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)


func _add_lines(specs: Array, veh: int = 14) -> Array:
	var st := g.state
	var ids: Array = []
	for sp in specs:
		var nodes := ScenarioData.lonlat_pts(st, sp[2])
		var ev := st.net.evaluate_draft(sp[0], sp[1], nodes)
		if not ev["ok"]:
			print("skip ", sp[0], " ", ev["reason"])
			continue
		var lid := st.net.commit_draft(sp[0], sp[1], nodes, ev["cost"], -1, false, ev["vehicles"])
		st.net.lines[lid]["vehicles"] = veh if sp[0] != "ferry" else 5
		ids.append(lid)
	st.dirty = true
	st.recompute_if_dirty()
	st.riders = st.target_riders
	return ids


func _hud(on: bool) -> void:
	g.hud.visible = on
	g.nav.visible = on
	if g.tutorial_panel:
		g.tutorial_panel.visible = false


func _run() -> void:
	await wait(1.0)
	main.start_city("istanbul", true)
	await wait(1.8)
	g = main.current
	_quiet(g)
	g.state.cash = 90000.0
	g.world.day_t = 0.42

	# ---------------- BUILD: draw a line stop by stop, open it
	_cam(29.1, 40.965, 0.26)
	await wait(0.4)
	mark("build")
	g.start_build("metro")
	var pts := [[29.03, 40.99], [29.07, 40.983], [29.112, 40.99], [29.13, 40.94], [29.19, 40.905], [29.26, 40.88]]
	for p in pts:
		await wait(0.38)
		g._build_tap(g.state.city.project(p[0], p[1]) * MapLayer.PX)
	await wait(0.45)
	g.finish_build()
	for l in g.state.net.lines.values():
		l.erase("con")
	g.state.net.changed.emit()
	g._on_construction_done(g.state.net.lines.keys()[0])
	g._set_speed(3)
	await wait(1.8)

	# ---------------- populate the city
	_add_lines([
		["metro", false, [[28.87, 40.985], [28.905, 40.995], [28.948, 41.008], [28.977, 41.03], [28.987, 41.062], [29.012, 41.08], [29.02, 41.11]]],
		["metro", true, [[28.86, 41.0], [28.91, 41.003], [28.948, 41.008], [29.003, 41.022], [29.03, 40.99]]],
		["tram", false, [[28.905, 41.04], [28.93, 41.02], [28.948, 41.008], [28.975, 41.006]]],
		["ferry", false, [[29.026, 40.993], [29.003, 41.03], [29.02, 41.045]]],
		["metro", false, [[29.03, 41.026], [29.07, 41.022], [29.115, 41.025], [29.18, 41.035]]],
		["metrobus", false, [[28.72, 40.985], [28.78, 40.995], [28.84, 41.0], [28.9, 41.02], [28.96, 41.045], [28.99, 41.065]]],
	])
	for s in g.state.net.stations.values():
		s["dev"] = 0.6
	g.world.growth.queue_redraw()
	for i in 10:
		g.state.feed.monthly(g.state)
	g._update_hud()

	# ---------------- HOOK: dramatic push-in on the Bosphorus at golden hour
	_hud(false)
	g.world.day_t = 0.76
	_cam(28.96, 41.05, 0.1)
	await wait(0.3)
	mark("hook")
	var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(t: float):
		var a := g.state.city.project(28.96, 41.05) * MapLayer.PX
		var b := g.state.city.project(29.01, 41.03) * MapLayer.PX
		g.world.camera.position = a.lerp(b, t)
		var z := lerpf(0.1, 0.38, t)
		g.world.camera.zoom = Vector2(z, z)
		g.world._on_zoom(z)
	, 0.0, 1.0, 3.2)
	await wait(3.4)

	# ---------------- TUNNEL: cross-section of the deep line under the strait
	_hud(true)
	g.world.day_t = 0.45
	_cam(29.0, 41.015, 0.3)
	var deep_lid := -1
	for l in g.state.net.lines.values():
		if l.get("deep", false):
			deep_lid = l["id"]
	await wait(0.3)
	mark("tunnel")
	g.show_modal(g.panels.profile_modal(deep_lid))
	await wait(3.4)
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0

	# ---------------- NIGHT: sunset to night over the city, trains running
	_hud(false)
	_cam(28.99, 41.03, 0.2)
	g.world.day_t = 0.74
	g._set_speed(3)
	await wait(0.3)
	mark("night")
	var tw2 := create_tween()
	tw2.tween_property(g.world, "day_t", 0.93, 3.2)
	tw2.parallel().tween_method(func(z: float):
		g.world.camera.zoom = Vector2(z, z)
		g.world._on_zoom(z), 0.2, 0.26, 3.2)
	await wait(3.4)

	# ---------------- SOCIAL: the city reacts
	_hud(true)
	g.world.day_t = 0.45
	_cam(28.99, 41.03, 0.2)
	await wait(0.3)
	mark("social")
	g.open_social()
	await wait(1.2)
	var p := g.state.feed.post("line_open", {"line": "M5", "a": "Kadıköy", "b": "Pendik", "st": "Kartal", "mode": ["metro", "metro"]}, g.state, "citizen", 6.0)
	p["viral"] = true
	p["likes"] = 48213
	g._refresh_live_sheet()
	await wait(2.2)
	g.sheet.close()
	await wait(0.3)

	# ---------------- CRISIS: earthquake shake, line failure, union decision
	_cam(28.97, 41.03, 0.24)
	await wait(0.3)
	mark("crisis")
	var lids: Array = g.state.net.lines.keys()
	g.state.mgmt.set_incident(g.state, lids[1], "quake", 0.0, 2)
	g.toast.visible = true
	g._on_quake(false)
	await wait(1.3)
	g.state.mgmt.pending = {"id": "union_wage"}
	g._on_dilemma(g.state.mgmt.pending)
	await wait(2.2)
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0
	g.toast.visible = false
	for l in g.state.net.lines.values():
		l.erase("incident")
	g.state.net.changed.emit()

	# ---------------- DIAGRAM: map morphs into a schematic
	_hud(false)
	_cam(29.02, 41.0, 0.24)
	await wait(0.3)
	mark("diagram")
	await wait(0.5)
	g.world.set_diagram(true)
	await wait(2.4)
	g.world.set_diagram(false)

	# ---------------- CITIES montage
	var cities := [
		["ankara", [["metro", false, [[32.58, 39.97], [32.67, 39.948], [32.73, 39.965], [32.80, 39.968], [32.855, 39.942], [32.854, 39.920]]],
					["tram", false, [[32.854, 39.920], [32.84, 39.905], [32.80, 39.909], [32.78, 39.893], [32.75, 39.875]]]], 32.80, 39.94, 0.22, "snow"],
		["izmir", [["ferry", false, [[27.112, 38.458], [27.133, 38.421]]], ["ferry", false, [[27.093, 38.462], [27.075, 38.402]]],
				   ["metro", false, [[27.05, 38.392], [27.09, 38.40], [27.133, 38.417], [27.15, 38.437], [27.18, 38.452], [27.22, 38.465]]]], 27.12, 38.43, 0.3, ""],
		["bursa", [["gondola", false, [[29.062, 40.184], [29.10, 40.15], [29.125, 40.105]]],
				   ["metro", false, [[28.90, 40.225], [28.99, 40.218], [29.045, 40.195], [29.062, 40.184], [29.10, 40.19]]]], 29.06, 40.16, 0.2, ""],
		["trabzon", [["tram", false, [[39.665, 40.996], [39.69, 40.998], [39.722, 41.003], [39.752, 40.999], [39.785, 40.994]]],
					 ["gondola", false, [[39.732, 41.004], [39.736, 40.989]]]], 39.73, 40.998, 0.6, ""],
	]
	for c in cities:
		g.exit_to_menu.emit()
		await wait(0.8)
		main.start_city(c[0], true)
		await wait(1.6)
		g = main.current
		_quiet(g)
		g.state.cash = 90000.0
		_add_lines(c[1], 12)
		_hud(false)
		g.world.day_t = 0.5 if c[0] != "izmir" else 0.78
		if c[5] == "snow":
			g.state.month = 0
			g.state.active_events.append({"id": "snow_storm", "months": 3})
		_cam(c[2], c[3], c[4])
		g._set_speed(3)
		await wait(0.5)
		mark("city_" + c[0])
		var tw3 := create_tween()
		tw3.tween_method(func(z: float):
			g.world.camera.zoom = Vector2(z, z)
			g.world._on_zoom(z), c[4], c[4] * 1.18, 1.6)
		await wait(1.7)

	# ---------------- END: title screen
	g.exit_to_menu.emit()
	await wait(1.2)
	mark("end")
	await wait(4.0)
	mark("done")
	get_tree().quit()
