extends Node
## Visual smoke test: drives the real game and saves screenshots.
## Run (needs a display, e.g. xvfb-run):
##   godot --path . --rendering-driver opengl3 --resolution 720x1280 tests/shots.tscn -- --out=/tmp/shots

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.progress = {"stars": {}, "best_riders": {}, "tutorial_done": false, "last_city": ""}
	for cid in CityData.CITY_IDS:
		SaveManager.delete_save(cid)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	await wait(1.5)
	print("menu ready ms ", Time.get_ticks_msec() - t0)
	await shot("01_menu")
	var menu: MainMenu = main.current
	menu.open_city_select()
	await wait(0.8)
	await shot("02_cities")
	var t1 := Time.get_ticks_msec()
	main.start_city("istanbul", true)
	await wait(1.6)
	print("game load ms ", Time.get_ticks_msec() - t1)
	var g: GameScreen = main.current
	await shot("03_game_start")
	g.open_build_menu()
	await wait(0.6)
	await shot("04_build_menu")
	g.start_build("metro")
	await wait(0.3)
	var st := g.state
	var pts := [[28.87, 40.985], [28.905, 40.995], [28.948, 41.008], [28.977, 41.03], [28.987, 41.062], [29.012, 41.08], [29.02, 41.11]]
	for p in pts:
		g._build_tap(st.city.project(p[0], p[1]) * MapLayer.PX)
	g.world.camera.position = st.city.project(28.95, 41.04) * MapLayer.PX
	var z := 0.22
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.6)
	await shot("05_drafting")
	g.finish_build()
	await wait(0.4)
	# second: deep metro crossing to Asia
	g.start_build("metro")
	g.build_deep = true
	for p in [[28.948, 41.008], [29.003, 41.022], [29.03, 40.99], [29.08, 40.98], [29.13, 40.94]]:
		g._build_tap(st.city.project(p[0], p[1]) * MapLayer.PX)
	g.finish_build()
	g.start_build("tram")
	for p in [[28.905, 41.04], [28.93, 41.02], [28.95, 41.012], [28.975, 41.006]]:
		g._build_tap(st.city.project(p[0], p[1]) * MapLayer.PX)
	g.finish_build()
	g.start_build("ferry")
	for p in [[29.026, 40.995], [28.98, 41.018]]:
		g._build_tap(st.city.project(p[0], p[1]) * MapLayer.PX)
	g.finish_build()
	g._set_speed(3)
	await wait(3.0)
	await shot("06_network")
	z = 0.5
	g.world.camera.position = st.city.project(28.985, 41.02) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("07_zoomed")
	var lid: int = st.net.lines.keys()[0]
	g.open_line(lid)
	await wait(0.8)
	await shot("08_line_sheet")
	g.show_modal(g.panels.profile_modal(st.net.lines.keys()[1]))
	await wait(1.2)
	await shot("09_profile")
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0
	g.open_finance()
	await wait(0.8)
	await shot("10_finance")
	g.open_goals()
	await wait(0.8)
	await shot("11_goals")
	g.sheet.close()
	g.set_overlay("pop")
	z = 0.12
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("12_overlay_pop")
	g.set_overlay("none")
	g._on_year_ended({"year": 2026, "income": 3000.0, "fare_income": 1200.0, "grant": 1800.0, "expense": 600.0, "capex": 9000.0,
		"profit": 2400.0, "operating_profit": 600.0, "riders": st.riders, "satisfaction": 71.0, "coverage": 0.12, "cash": st.cash, "lines": 4, "stations": 20})
	await wait(1.0)
	await shot("13_year_report")
	print("FPS ", Engine.get_frames_per_second())
	get_tree().quit()
