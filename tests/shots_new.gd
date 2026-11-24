extends Node
## Visual check for construction, express, hubs, diagram mode, scenarios, weekly, poster, new cities.

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.progress = {"stars": {"istanbul": 3, "ankara": 3}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("shot ", name)


func close_modals(g) -> void:
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0


func build(g, mode: String, deep: bool, pts: Array) -> void:
	g.start_build(mode)
	g.build_deep = deep
	for p in pts:
		g._build_tap(g.state.city.project(p[0], p[1]) * MapLayer.PX)
	g.finish_build()


func _run() -> void:
	await wait(1.2)
	await shot("N01_menu")
	var menu: MainMenu = main.current
	menu.open_city_select()
	await wait(0.7)
	await shot("N02_cities")
	menu.on_back()
	menu.open_scenarios()
	await wait(0.8)
	await shot("N03_scenarios")
	for c in menu.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	menu.open_weekly()
	await wait(0.8)
	await shot("N04_weekly")
	for c in menu.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	main.start_city("istanbul", true)
	await wait(1.5)
	var g: GameScreen = main.current
	var st := g.state
	st.cash = 60000.0
	build(g, "metro", false, [[28.87, 40.985], [28.905, 40.995], [28.948, 41.008], [28.977, 41.03], [28.987, 41.062], [29.012, 41.08], [29.02, 41.11]])
	build(g, "metro", true, [[28.948, 41.008], [29.003, 41.022], [29.03, 40.99], [29.08, 40.98], [29.13, 40.94]])
	build(g, "tram", false, [[28.905, 41.04], [28.93, 41.02], [28.948, 41.008]])
	var z := 0.2
	g.world.camera.position = st.city.project(28.97, 41.03) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	g._set_speed(0)
	await wait(0.8)
	await shot("N05_construction")
	var l1: int = st.net.lines.keys()[0]
	g.open_line(l1)
	await wait(0.8)
	await shot("N06_line_construction")
	g.sheet.close()
	# finish construction instantly for the rest
	for l in st.net.lines.values():
		l.erase("con")
	st.net.changed.emit()
	st.dirty = true
	st.net.lines[l1]["express"] = true
	st.net.lines[l1]["age"] = 60
	st.net.changed.emit()
	g._on_construction_done(l1)
	g._set_speed(2)
	await wait(1.2)
	await shot("N07_opened_express")
	var hub_sid := st.net.station_at(st.city.project(28.948, 41.008), 0.4)
	g.open_station(hub_sid)
	await wait(0.8)
	await shot("N08_station_hub")
	st.upgrade_hub(hub_sid)
	for s in st.net.stations.values():
		s["dev"] = 0.8
	g.world.growth.queue_redraw()
	g.sheet.close()
	z = 0.4
	g.world.camera.position = st.city.project(28.95, 41.01) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("N09_growth")
	g.open_line(l1)
	await wait(0.8)
	g.sheet.scroll.scroll_vertical = 600
	await wait(0.3)
	await shot("N10_line_express_age")
	g.sheet.close()
	z = 0.13
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	g.world.set_diagram(true)
	await wait(1.0)
	await shot("N11_diagram")
	g.world.set_diagram(false)
	Settings.colorblind = true
	g.world.network.queue_redraw()
	z = 0.25
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.6)
	await shot("N12_colorblind")
	Settings.colorblind = false
	st.active_events.append({"id": "rain", "months": 2})
	await wait(2.5)
	await shot("N13_rain")
	st.active_events.clear()
	g.show_modal(g.panels.poster_modal())
	await wait(1.5)
	await shot("N14_poster")
	close_modals(g)
	SettingsPanel.open(g.ui_layer)
	await wait(0.8)
	await shot("N15_settings")
	close_modals(g)
	g.exit_to_menu.emit()
	await wait(1.0)
	for cid in ["bursa", "trabzon", "eskisehir", "antalya"]:
		main.start_city(cid, true)
		await wait(1.6)
		g = main.current
		g.world.camera.zoom = Vector2(g.world.camera.min_zoom * 1.3, g.world.camera.min_zoom * 1.3)
		g.world._on_zoom(g.world.camera.zoom.x)
		await wait(0.6)
		await shot("N16_" + cid)
		g.exit_to_menu.emit()
		await wait(1.0)
	main.start_city("scn_ist_1989", true)
	await wait(1.6)
	await shot("N17_scenario_game")
	get_tree().quit()
