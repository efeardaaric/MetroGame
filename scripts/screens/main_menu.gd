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
	Audio.set_ambience({"sea_loop": 0.25, "city_loop": 0.08})
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
	if world:
		world.advance_day(delta, 5.0)
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
	var pat := Deco.CiniPattern.new()
	pat.band = 0.0
	pat.cell = 72.0
	pat.color = Color(Palette.CREAM, 0.045)
	pat.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(pat)

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
	# title as a station sign
	var sign := PanelContainer.new()
	sign.add_theme_stylebox_override("panel", ThemeBuilder.enamel(Palette.PANEL, 22, true, 0, 40, 18, 0.9))
	var sv := UI.vbox(0)
	var title := UI.title(I18n.t("app_title_main").to_upper(), 74 if land else 86, Palette.CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(title)
	var title2 := UI.title(I18n.t("app_title_sub").to_upper(), 40 if land else 46, Palette.ACCENT)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(title2)
	var stripe := Deco.LineStripe.new()
	stripe.thickness = 9.0
	stripe.custom_minimum_size = Vector2(420, 22)
	stripe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sv.add_child(stripe)
	sign.add_child(sv)
	menu_box.add_child(sign)
	var tag := UI.label(I18n.t("app_tagline").to_upper(), 24, Palette.ACCENT, 800)
	tag.add_theme_font_override("font", ThemeBuilder.display(700))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(tag)
	menu_box.add_child(UI.gap(8 if land else 30))
	var last := SaveManager.last_city()
	if last != "":
		var cname: String
		if last == "weekly":
			cname = I18n.t("weekly_title")
		elif last.begins_with("scn_"):
			cname = I18n.t(last)
		else:
			cname = I18n.t(CityData.get_city(last.trim_suffix("_sandbox"))["name_key"])
			if last.ends_with("_sandbox"):
				cname += " (" + I18n.t("sandbox") + ")"
		var cont := Deco.ticket_button("%s · %s" % [I18n.t("continue"), cname], "play", Palette.STRIPES[0], 100)
		cont.pressed.connect(func(): start_city.emit(last, false))
		menu_box.add_child(cont)
	var play := Deco.ticket_button(I18n.t("play"), "build" if last != "" else "play", Palette.STRIPES[1] if last != "" else Palette.STRIPES[0], 100)
	play.pressed.connect(open_city_select)
	menu_box.add_child(play)
	var mrow := UI.hbox(14)
	var scn := Deco.ticket_button(I18n.t("scenarios"), "flask", Palette.STRIPES[1], 84)
	scn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scn.pressed.connect(open_scenarios)
	mrow.add_child(scn)
	menu_box.add_child(mrow)
	var row := UI.hbox(14)
	var htp := Deco.ticket_button(I18n.t("how_to_play"), "info", Palette.STRIPES[2], 84)
	htp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htp.pressed.connect(_show_help)
	row.add_child(htp)
	var st := UI.icon_button("gear", 84, "AccentButton", Palette.INK)
	st.pressed.connect(func(): SettingsPanel.open(ui_layer, func(): _build_menu()))
	row.add_child(st)
	menu_box.add_child(row)
	var ach := Deco.ticket_button(I18n.t("achievements") + "  %d/%d" % [Achievements.unlocked().size(), Achievements.LIST.size()], "trophy", Palette.STRIPES[3], 84)
	ach.pressed.connect(func(): AchievementBanner.open_list(ui_layer))
	menu_box.add_child(ach)
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


func open_scenarios() -> void:
	var m := Modal.create(I18n.t("scenarios"), 760.0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.y = minf(1000.0, root.get_viewport_rect().size.y * 0.66)
	var v := UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	for scd in ScenarioData.LIST:
		var id: String = scd["id"]
		var card := PanelContainer.new()
		var csb := ThemeBuilder.box(Palette.PANEL_2, 22, 3, CityData.get_city(scd["city"])["accent"], 18, 14)
		csb.border_width_left = 12
		card.add_theme_stylebox_override("panel", csb)
		var cv := UI.vbox(8)
		var top := UI.hbox(10)
		var t := UI.title(I18n.t("scn_" + id), 30)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(t)
		var stars := SaveManager.scenario_stars(id)
		for i in 3:
			top.add_child(Icon.make("star" if i < stars else "star_o", 28, Palette.ACCENT if i < stars else Palette.FAINT))
		cv.add_child(top)
		cv.add_child(UI.label("%s · %d · %d %s" % [I18n.t(CityData.get_city(scd["city"])["name_key"]), int(scd["start_year"]), int(scd["years"]), I18n.t("year")], 20, Palette.ACCENT, 800))
		cv.add_child(UI.wrap_label(I18n.t("scn_" + id + "_d"), 21, Palette.MUTED))
		var slot := "scn_" + id
		var row := UI.hbox(10)
		var play := UI.button(I18n.t("continue") if SaveManager.has_save(slot) else I18n.t("play"), "AccentButton", "play", 64)
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.pressed.connect(func():
			m.close()
			start_city.emit(slot, not SaveManager.has_save(slot))
		)
		row.add_child(play)
		if SaveManager.has_save(slot):
			var fresh := UI.icon_button("undo", 64)
			fresh.pressed.connect(func():
				m.close()
				start_city.emit(slot, true)
			)
			row.add_child(fresh)
		cv.add_child(row)
		card.add_child(cv)
		v.add_child(card)
	m.body.add_child(sc)
	var ok := UI.button(I18n.t("close"))
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	ui_layer.add_child(m)


func open_weekly() -> void:
	var key := ScenarioData.week_key()
	var spec := ScenarioData.weekly_spec(key)
	var m := Modal.create(I18n.t("weekly_title"), 640.0)
	m.body.add_child(UI.plate("%s · #%d" % [I18n.t(CityData.get_city(spec["city"])["name_key"]), key % 100], CityData.get_city(spec["city"])["accent"]))
	m.body.add_child(UI.wrap_label(I18n.t("weekly_desc"), 23, Palette.MUTED))
	for k in spec["mods"]:
		var r := UI.hbox(10)
		r.add_child(Icon.make("warning", 30, Palette.WARN))
		var l := UI.wrap_label(I18n.t("wmod_" + str(k)), 23, Palette.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		m.body.add_child(r)
	var best := SaveManager.weekly_best(key)
	if best > 0.0:
		m.body.add_child(UI.stat_row(I18n.t("best"), Geo.fmt_int(best), Palette.ACCENT))
	var has := SaveManager.has_save("weekly")
	var play := UI.button(I18n.t("continue") if has else I18n.t("play"), "AccentButton", "play")
	play.pressed.connect(func():
		m.close()
		var cont := has and _weekly_save_matches(key)
		start_city.emit("weekly", not cont)
	)
	m.body.add_child(play)
	ui_layer.add_child(m)


func _weekly_save_matches(key: int) -> bool:
	var f := FileAccess.open(SaveManager.save_path("weekly"), FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	return d is Dictionary and int(d.get("scenario", {}).get("week", 0)) == key


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
	var csb := ThemeBuilder.box(Palette.PANEL_2, 28, 3, d["accent"], 20, 20, 14)
	csb.border_width_bottom = 10
	card.add_theme_stylebox_override("panel", csb)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(12)
	card.add_child(v)
	var prev := CityPreview.new()
	prev.city_id = cid
	prev.custom_minimum_size = Vector2(0, 230)
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(prev)
	var h := UI.hbox(10)
	# city name as a metro station sign
	var plate := PanelContainer.new()
	var psb := ThemeBuilder.box(Palette.INK, 12, 0, Color.TRANSPARENT, 16, 4)
	psb.border_width_left = 12
	psb.border_color = d["accent"]
	plate.add_theme_stylebox_override("panel", psb)
	var name := UI.title(I18n.t(d["name_key"]).to_upper(), 40, Palette.CREAM)
	plate.add_child(name)
	h.add_child(plate)
	h.add_child(UI.spacer())
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
	var sb_slot := cid + "_sandbox"
	var sb := UI.button(I18n.t("sandbox") + (" · " + I18n.t("continue") if SaveManager.has_save(sb_slot) else ""), "FlatButton", "", 60)
	sb.add_theme_font_size_override("font_size", 22)
	sb.add_theme_color_override("font_color", Palette.INFO)
	sb.tooltip_text = I18n.t("sandbox_desc")
	sb.pressed.connect(func(): start_city.emit(sb_slot, not SaveManager.has_save(sb_slot)))
	v.add_child(sb)
	return card
