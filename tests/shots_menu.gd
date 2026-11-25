extends Node
## Visual check of the menu, city select, city intro board and tutorial mentor.

var out_dir := "user://shots"
var main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	I18n.set_language("tr")
	SaveManager.progress = {"stars": {"istanbul": 2}, "best_riders": {}, "tutorial_done": false, "last_city": "istanbul"}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _run() -> void:
	await wait(0.45)
	await shot("M0_flaps")
	await wait(1.6)
	await shot("M1_menu")
	main.current.open_city_select()
	await wait(0.6)
	await shot("M2_cities")
	main.start_city("ankara", true)
	await wait(1.2)
	await shot("M3_intro")
	await wait(2.6)
	await shot("M4_tutorial")
	get_tree().quit()
