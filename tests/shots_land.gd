extends Node
## Landscape / other-city visual check.

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.progress = {"stars": {"istanbul": 2}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("shot ", name)


func build(g: GameScreen, mode: String, deep: bool, pts: Array) -> void:
	g.start_build(mode)
	g.build_deep = deep
	for p in pts:
		g._build_tap(g.state.city.project(p[0], p[1]) * MapLayer.PX)
	g.finish_build()


func _run() -> void:
	await wait(1.2)
	await shot("L01_menu")
	(main.current as MainMenu).open_city_select()
	await wait(0.6)
	await shot("L02_cities")
	main.start_city("ankara", true)
	await wait(1.4)
	var g: GameScreen = main.current
	build(g, "metro", false, [[32.58, 39.97], [32.67, 39.948], [32.73, 39.965], [32.80, 39.968], [32.855, 39.942], [32.854, 39.920]])
	build(g, "rail", false, [[32.60, 39.965], [32.70, 39.955], [32.80, 39.950], [32.845, 39.936], [32.92, 39.93]])
	build(g, "tram", false, [[32.854, 39.920], [32.84, 39.905], [32.80, 39.909], [32.78, 39.893], [32.75, 39.875]])
	g._set_speed(3)
	await wait(2.5)
	await shot("L03_ankara")
	g.open_build_menu()
	await wait(0.6)
	await shot("L04_build")
	g.sheet.close()
	await wait(0.3)
	g.open_goals()
	await wait(0.6)
	await shot("L05_goals")
	g.exit_to_menu.emit()
	await wait(1.0)
	main.start_city("izmir", true)
	await wait(1.4)
	g = main.current
	build(g, "ferry", false, [[27.112, 38.458], [27.133, 38.421]])
	build(g, "metro", false, [[27.05, 38.392], [27.09, 38.40], [27.133, 38.417], [27.15, 38.437], [27.18, 38.452], [27.22, 38.465]])
	build(g, "funicular", false, [[27.135, 38.418], [27.145, 38.413]])
	g._set_speed(3)
	var z := 0.35
	g.world.camera.position = g.state.city.project(27.13, 38.43) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(2.0)
	await shot("L06_izmir")
	g.set_overlay("elev")
	await wait(0.6)
	await shot("L07_izmir_elev")
	get_tree().quit()
