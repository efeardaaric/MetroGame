class_name MainMenu
extends Node
## Title screen with a live, slowly drifting demo network in the background.

signal start_city(id: String, fresh: bool)

var world: WorldView
var demo: GameState
var ui_layer: CanvasLayer
var root: Control
var menu_box: VBoxContainer
var city_panel: Control
var _drift_t := 0.0


func _ready() -> void:
	demo = GameState.new("istanbul")
	_build_demo_network()
	world = WorldView.new()
	add_child(world)
	world.setup(demo)
	world.camera.input_enabled = false
	world.network.show_names = false
	var z := world.camera.min_zoom * 2.4
	world.camera.zoom = Vector2(z, z)
	world._on_zoom(z)
	world.camera.position = demo.city.project(28.99, 41.03) * MapLayer.PX
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	_build_menu()
	Audio.play_music()
	get_viewport().size_changed.connect(_on_resize)


func _on_resize() -> void:
	var had_cities := is_instance_valid(city_panel)
	_build_menu()
	if had_cities:
		open_city_select()


func _build_demo_network() -> void:
	var lines := [
		["metro", false, [[28.87, 40.985], [28.905, 40.995], [28.948, 41.008], [28.977, 41.03], [28.987, 41.062], [29.012, 41.08], [29.02, 41.11]]],
		["metro", true, [[28.86, 41.0], [28.91, 41.003], [28.955, 41.006], [29.003, 41.022], [29.03, 40.99], [29.08, 40.98], [29.13, 40.94], [29.19, 40.905]]],
		["tram", false, [[28.905, 41.04], [28.93, 41.02], [28.95, 41.012], [28.975, 41.006], [28.985, 41.026], [29.005, 41.044]]],
		["ferry", false, [[29.028, 40.995], [28.98, 41.017], [29.0, 41.043], [29.02, 41.026]]],
		["metrobus", false, [[28.72, 40.985], [28.78, 40.995], [28.84, 41.0], [28.9, 41.02], [28.96, 41.045], [28.99, 41.065], [29.03, 41.065], [29.06, 41.04], [29.1, 41.0]]],
		["metro", false, [[29.03, 41.026], [29.07, 41.022], [29.115, 41.025], [29.18, 41.035]]],
	]
	for spec in lines:
		var nodes: Array = []
		for ll in spec[2]:
			var p: Vector2 = demo.city.project(ll[0], ll[1])
			var sid := demo.net.station_at(p, 0.4)
			nodes.append({"pos": p if sid < 0 else demo.net.stations[sid]["pos"], "sid": sid})
		var lid := demo.net.commit_draft(spec[0], spec[1], nodes, 0.0)
		demo.net.lines[lid]["vehicles"] = 8 if spec[0] != "ferry" else 4


func _process(delta: float) -> void:
	_drift_t += delta
	if world and world.camera:
		var base: Vector2 = demo.city.project(28.99, 41.03) * MapLayer.PX
		world.camera.position = base + Vector2(cos(_drift_t * 0.05), sin(_drift_t * 0.037)) * 1100.0


func _build_menu() -> void:
	UI.clear(root)
	# gradient veil for readability
	var veil := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(Palette.BG, 0.55))
	grad.set_color(1, Color(Palette.BG, 0.95))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	veil.texture = gt
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	menu_box = UI.vbox(18)
	menu_box.custom_minimum_size.x = 560
	center.add_child(menu_box)
	var land := root.get_viewport_rect().size.x > root.get_viewport_rect().size.y
	menu_box.add_theme_constant_override("separation", 12 if land else 18)
	var logo := Logo.new()
	logo.custom_minimum_size = Vector2(560, 110 if land else 170)
	menu_box.add_child(logo)
	var title := UI.label(I18n.t("app_title"), 80 if land else 96, Palette.TEXT, 1000)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(title)
	var tag := UI.label(I18n.t("app_tagline"), 28, Palette.MUTED, 700)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(tag)
	menu_box.add_child(UI.gap(8 if land else 30))
	var last := SaveManager.last_city()
	if last != "":
		var cont := UI.button("%s · %s" % [I18n.t("continue"), I18n.t(CityData.get_city(last)["name_key"])], "AccentButton", "play", 96)
		cont.pressed.connect(func(): start_city.emit(last, false))
		menu_box.add_child(cont)
	var play := UI.button(I18n.t("play"), "" if last != "" else "AccentButton", "build" if last != "" else "play", 96)
	play.pressed.connect(open_city_select)
	menu_box.add_child(play)
	var row := UI.hbox(14)
	var htp := UI.button(I18n.t("how_to_play"), "", "info")
	htp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htp.pressed.connect(_show_help)
	row.add_child(htp)
	var st := UI.icon_button("gear", 84)
	st.pressed.connect(func(): SettingsPanel.open(ui_layer, func(): _build_menu()))
	row.add_child(st)
	menu_box.add_child(row)
	var cr := UI.button(I18n.t("credits"), "FlatButton", "", 64)
	cr.add_theme_color_override("font_color", Palette.MUTED)
	cr.pressed.connect(_show_credits)
	menu_box.add_child(cr)
	var ver := UI.label("v" + str(ProjectSettings.get_setting("application/config/version", "1.0")), 18, Palette.FAINT)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = root.get_viewport_rect().size - Vector2(110, 50 + SafeArea.margins(root).w)
	root.add_child(ver)
	menu_box.modulate.a = 0.0
	create_tween().tween_property(menu_box, "modulate:a", 1.0, 0.5)


func on_back() -> void:
	if is_instance_valid(city_panel):
		city_panel.queue_free()
		menu_box.visible = true
	else:
		get_tree().quit()


func _show_help() -> void:
	var m := Modal.create(I18n.t("how_to_play"), 700.0)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(820.0, root.get_viewport_rect().size.y * 0.62))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var l := UI.wrap_label(I18n.t("htp_body"), 25, Palette.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(l)
	m.body.add_child(sc)
	var ok := UI.button(I18n.t("ok"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	ui_layer.add_child(m)


func _show_credits() -> void:
	var m := Modal.create(I18n.t("credits"), 640.0)
	var l := UI.wrap_label(I18n.t("credits_body"), 25, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	ui_layer.add_child(m)


# ------------------------------------------------------------------ city select

func open_city_select() -> void:
	menu_box.visible = false
	city_panel = Control.new()
	city_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(city_panel)
	var safe := SafeArea.margins(root)
	var vs := root.get_viewport_rect().size
	var v := UI.vbox(16)
	var w := minf(vs.x - 40.0, 1100.0)
	v.position = Vector2((vs.x - w) * 0.5, 30.0 + safe.y)
	v.size = Vector2(w, vs.y - 60.0 - safe.y - safe.w)
	city_panel.add_child(v)
	var head := UI.hbox(12)
	var back := UI.icon_button("close", 76)
	back.pressed.connect(on_back)
	head.add_child(back)
	var t := UI.label(I18n.t("select_city"), 44, Palette.TEXT, 950)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var stars := UI.hbox(6)
	stars.add_child(Icon.make("star", 40, Palette.ACCENT))
	stars.add_child(UI.label(str(SaveManager.total_stars()), 34, Palette.ACCENT, 900))
	head.add_child(stars)
	v.add_child(head)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var flow := GridContainer.new()
	flow.columns = 1 if w < 900 else 3
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 16)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(flow)
	for cid in ["istanbul", "ankara", "izmir"]:
		flow.add_child(_city_card(cid))
	city_panel.modulate.a = 0.0
	create_tween().tween_property(city_panel, "modulate:a", 1.0, 0.25)


func _city_card(cid: String) -> Control:
	var d := CityData.get_city(cid)
	var unlocked := SaveManager.is_unlocked(cid)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(0.1, 0.13, 0.2, 0.95), 30, 2, Color(d["accent"], 0.5), 20, 20, 12))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(12)
	card.add_child(v)
	var prev := CityPreview.new()
	prev.city_id = cid
	prev.custom_minimum_size = Vector2(0, 230)
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(prev)
	var h := UI.hbox(10)
	var name := UI.label(I18n.t(d["name_key"]), 42, Palette.TEXT, 950)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var cs := SaveManager.city_stars(cid)
	for i in 3:
		h.add_child(Icon.make("star" if i < cs else "star_o", 34, Palette.ACCENT if i < cs else Palette.FAINT))
	v.add_child(h)
	v.add_child(UI.wrap_label(I18n.t(d["subtitle_key"]), 23, Palette.MUTED))
	var info := UI.hbox(16)
	info.add_child(UI.label("%s: %s" % [I18n.t("difficulty"), I18n.t("diff_%d" % d["difficulty"])], 21, Palette.FAINT, 800))
	var best: float = SaveManager.progress["best_riders"].get(cid, 0.0)
	if best > 0.0:
		info.add_child(UI.label("%s: %s" % [I18n.t("best"), Geo.fmt_short(best)], 21, Palette.FAINT, 800))
	v.add_child(info)
	if not unlocked:
		var lk := UI.hbox(10)
		lk.add_child(Icon.make("lock", 34, Palette.MUTED))
		lk.add_child(UI.label(I18n.t("stars_needed") % d["unlock_stars"], 26, Palette.MUTED, 850))
		v.add_child(lk)
		card.modulate = Color(1, 1, 1, 0.7)
		return card
	var row := UI.hbox(12)
	if SaveManager.has_save(cid):
		var cont := UI.button(I18n.t("continue"), "AccentButton", "play")
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.pressed.connect(func(): start_city.emit(cid, false))
		row.add_child(cont)
		var fresh := UI.icon_button("undo", 76)
		fresh.tooltip_text = I18n.t("new_game")
		fresh.pressed.connect(func():
			Modal.confirm(ui_layer, I18n.t("confirm_restart"), func():
				SaveManager.delete_save(cid)
				start_city.emit(cid, true)
			)
		)
		row.add_child(fresh)
	else:
		var play := UI.button(I18n.t("play"), "AccentButton", "play")
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.pressed.connect(func(): start_city.emit(cid, true))
		row.add_child(play)
	v.add_child(row)
	return card
