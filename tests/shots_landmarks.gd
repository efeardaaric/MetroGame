extends Node
## Visual check: 3D landmark sprites on the map at close zoom.

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


func _cam(g: GameScreen, lon: float, lat: float, z: float) -> void:
	g.world.camera.position = g.state.city.project(lon, lat) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)


func _run() -> void:
	await wait(1.0)
	var spots := [["istanbul", 28.985, 41.017, 0.55, "L1_ist"], ["istanbul", 29.03, 41.06, 0.4, "L2_ist_bos"],
		["ankara", 32.85, 39.93, 0.45, "L3_ank"], ["izmir", 27.13, 38.415, 0.6, "L4_izm"], ["bursa", 29.058, 40.186, 0.9, "L5_bur"]]
	for sp in spots:
		main.start_city(sp[0], true)
		await wait(1.6)
		var g: GameScreen = main.current
		g.auto_quality = false
		g._set_speed(0)
		g.world.day_t = 0.5
		g.hud.visible = false
		_cam(g, sp[1], sp[2], sp[3])
		await wait(0.6)
		await shot(sp[4])
	get_tree().quit()
