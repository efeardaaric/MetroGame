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
	var g: GameScreen = main.current
	if g.tutorial_panel:
		g.tutorial_panel.queue_free()
		g.tutorial_panel = null
	var st := g.state
	for cat in ["crowded", "fare_up", "line_open", "debt", "poi_university", "chatter_neg"]:
		st.feed.post(cat, {"line": "M1", "a": "Kızılay", "b": "Batıkent", "st": "Ulus", "mode": ["metro", "metro"], "poi": ["ODTÜ", "METU"], "poitag": ["ODTÜ", "METU"]}, st, "citizen")
	st.feed.post("line_open", {"line": "M1", "a": "Kızılay", "b": "Batıkent", "st": "Ulus"}, st, "citizen")
	g.open_social()
	await wait(1.0)
	await shot("M5_social")
	g.sheet.close()
	await wait(0.4)
	ProfileCard.open(g, {"name": "Nuri Aksoy", "handle": "vatman_nuri", "kind": "citizen", "cast": "nuri"})
	await wait(1.0)
	await shot("M6_profile")
	for c in g.ui_layer.get_children():
		if c is Modal:
			c.queue_free()
	g.modal_count = 0
	ProfileCard.open(g, st.feed.posts[2]["who"])
	await wait(1.0)
	await shot("M7_profile2")
	get_tree().quit()
