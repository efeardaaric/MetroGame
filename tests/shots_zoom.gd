extends Node
## Close-up rendering check (coastlines, hill shading, heat maps at high zoom).

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.progress = {"stars": {}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _run() -> void:
	await wait(1.0)
	main.start_city("istanbul", true)
	await wait(1.5)
	var g = main.current
	g._set_speed(0)
	if "day_t" in g.world:
		g.world.day_t = 0.5
	g.hud.visible = false
	g.nav.visible = false
	var z := 1.3
	g.world.camera.position = g.state.city.project(28.99, 41.02) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("Z1_coast")
	g.set_overlay("pop")
	await wait(0.8)
	await shot("Z2_pop")
	g.set_overlay("none")
	g.world.camera.position = g.state.city.project(29.06, 41.03) * MapLayer.PX
	await wait(0.6)
	await shot("Z3_hills")
	z = 0.16
	g.world.camera.position = g.state.city.project(28.98, 41.03) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("Z4_overview")
	z = 0.45
	g.world.camera.position = g.state.city.project(29.08, 40.92) * MapLayer.PX
	g.world.camera.zoom = Vector2(z, z)
	g.world._on_zoom(z)
	await wait(0.8)
	await shot("Z5_islands")
	get_tree().quit()
