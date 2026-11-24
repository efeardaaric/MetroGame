class_name GamePanels
extends RefCounted
## Builds the content of in-game sheets and dialogs.

var gs: GameScreen


func _init(game_screen: GameScreen) -> void:
	gs = game_screen


func _st() -> GameState:
	return gs.state


# ------------------------------------------------------------------ build menu

func build_sheet() -> Sheet:
	var s := Sheet.create(I18n.t("build_title"), 0.78)
	var grid := GridContainer.new()
	var vs := gs.root_ui.get_viewport_rect().size
	var avail := minf(620.0, vs.x * 0.46) if vs.x > vs.y * 1.15 else minf(vs.x, Sheet.MAX_W)
	grid.columns = 2 if avail - 60.0 >= 500.0 else 1
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for mode in TransitModes.ORDER:
		grid.add_child(_mode_card(mode))
	s.body.add_child(grid)
	return s


func _mode_card(mode: String) -> Control:
	var m := TransitModes.get_mode(mode)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(240, 210)
	b.add_theme_stylebox_override("normal", ThemeBuilder.box(Palette.PANEL_2, 24, 0, Color.TRANSPARENT, 18, 16))
	b.add_theme_stylebox_override("hover", ThemeBuilder.box(Palette.PANEL_3, 24, 0, Color.TRANSPARENT, 18, 16))
	b.add_theme_stylebox_override("pressed", ThemeBuilder.box(Palette.PANEL_3, 24, 2, Palette.ACCENT, 18, 16))
	var v := UI.vbox(6)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_top = 14
	v.offset_right = -18
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(12)
	var col := TransitModes.LINE_COLORS[["metro", "tram", "metrobus", "rail", "funicular", "ferry"].find(mode) * 2 % TransitModes.LINE_COLORS.size()]
	h.add_child(UI.color_dot(col, 44, TransitModes.mode_prefix(mode)))
	var name := UI.label(I18n.t(m["name_key"]), 30, Palette.TEXT, 900)
	h.add_child(name)
	v.add_child(h)
	var d := UI.wrap_label(I18n.t(m["desc_key"]), 21, Palette.MUTED)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var cost_txt: String
	if mode == "ferry":
		cost_txt = "%s %s" % [Geo.fmt_money(m["cost_station"]), I18n.t("station_cost")]
	else:
		cost_txt = "%s%s · %s %s" % [Geo.fmt_money(m["cost_km"]), I18n.t("per_km"), Geo.fmt_money(m["cost_station"]), I18n.t("station_cost")]
	var stats := UI.label(cost_txt, 21, Palette.ACCENT, 800)
	v.add_child(stats)
	var cap := UI.label("%s %d · %d km/h" % [I18n.t("capacity"), m["capacity"], int(m["speed"])], 20, Palette.FAINT, 700)
	v.add_child(cap)
	b.add_child(v)
	b.pressed.connect(func():
		Audio.play("tap")
		gs.start_build(mode)
	)
	return b


# ------------------------------------------------------------------ lines

func lines_sheet() -> Sheet:
	var st := _st()
	var s := Sheet.create(I18n.t("tab_lines"), 0.7)
	if st.net.lines.is_empty():
		s.body.add_child(UI.wrap_label(I18n.t("no_lines"), 26, Palette.MUTED))
		var b := UI.button(I18n.t("tab_build"), "AccentButton", "build")
		b.pressed.connect(gs.open_build_menu)
		s.body.add_child(b)
		return s
	var ids: Array = st.net.lines.keys()
	ids.sort()
	for lid in ids:
		s.body.add_child(_line_row(lid))
	return s


func _line_row(lid: int) -> Control:
	var st := _st()
	var l: Dictionary = st.net.lines[lid]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 108
	b.add_theme_stylebox_override("normal", ThemeBuilder.box(Palette.PANEL_2, 22, 0, Color.TRANSPARENT, 18, 12))
	b.add_theme_stylebox_override("hover", ThemeBuilder.box(Palette.PANEL_3, 22, 0, Color.TRANSPARENT, 18, 12))
	b.add_theme_stylebox_override("pressed", ThemeBuilder.box(Palette.PANEL_3, 22, 0, Color.TRANSPARENT, 18, 12))
	var h := UI.hbox(16)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -18
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := UI.color_dot(st.net.line_color(l), 46, l["name"])
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(badge)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var first := st.net.station_display_name(l["stations"][0])
	var last := st.net.station_display_name(l["stations"][l["stations"].size() - 1])
	var title := UI.label("%s – %s" % [first, last], 24, Palette.TEXT, 800)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	v.add_child(title)
	var load: float = st.demand.line_load.get(lid, 0.0)
	var sub := UI.label("%s · %s %s · %d %s" % [I18n.t(TransitModes.get_mode(l["mode"])["name_key"]),
		Geo.fmt_short(st.demand.line_riders.get(lid, 0.0)), I18n.t("riders_short"), l["vehicles"], I18n.t("vehicles_short")], 20, Palette.MUTED)
	v.add_child(sub)
	v.add_child(UI.progress(minf(load, 1.0), _load_color(load), 8.0))
	h.add_child(v)
	b.add_child(h)
	b.pressed.connect(func():
		Audio.play("tap")
		gs.open_line(lid)
	)
	return b


func _load_color(load: float) -> Color:
	if load < 0.75:
		return Palette.GOOD
	if load < 1.0:
		return Palette.WARN
	return Palette.BAD


func line_sheet(lid: int) -> Sheet:
	var st := _st()
	var l: Dictionary = st.net.lines[lid]
	var m := TransitModes.get_mode(l["mode"])
	var s := Sheet.create("", 0.82)
	s.title_label.queue_free()
	var badge := UI.color_dot(st.net.line_color(l), 52, l["name"])
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.header.add_child(badge)
	s.header.move_child(badge, 0)
	var tl := UI.label(I18n.t(m["name_key"]) + ("  ·  " + I18n.t("loop") if l.get("loop", false) else ""), 30, Palette.TEXT, 900)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.header.add_child(tl)
	s.header.move_child(tl, 1)
	var content := UI.vbox(14)
	s.body.add_child(content)
	var fill := func():
		UI.clear(content)
		_fill_line(content, lid)
	fill.call()
	s.set_meta("live", fill)
	return s


func _fill_line(content: VBoxContainer, lid: int) -> void:
	var st := _st()
	if not st.net.lines.has(lid):
		return
	var l: Dictionary = st.net.lines[lid]
	var m := TransitModes.get_mode(l["mode"])
	var first := st.net.station_display_name(l["stations"][0])
	var last := st.net.station_display_name(l["stations"][l["stations"].size() - 1])
	var route := UI.wrap_label("%s ⟷ %s" % [first, last], 24, Palette.MUTED)
	content.add_child(route)
	var load: float = st.demand.line_load.get(lid, 0.0)
	var riders: float = st.demand.line_riders.get(lid, 0.0)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.add_child(_stat_tile(I18n.t("line_riders"), Geo.fmt_int(riders), Palette.INFO))
	grid.add_child(_stat_tile(I18n.t("load"), "%d%%" % int(load * 100.0), _load_color(load), I18n.t("crowded") if load > 1.0 else ""))
	grid.add_child(_stat_tile(I18n.t("headway"), "%.1f %s" % [st.net.line_headway_min(l), I18n.t("minutes_short")], Palette.TEXT))
	grid.add_child(_stat_tile(I18n.t("capacity"), "%s %s" % [Geo.fmt_short(st.net.line_hourly_capacity(l)), I18n.t("per_hour_pax")], Palette.TEXT))
	grid.add_child(_stat_tile(I18n.t("length"), "%.1f km · %d %s" % [st.net.line_length(l), l["stations"].size(), I18n.t("stations")], Palette.TEXT))
	grid.add_child(_stat_tile(I18n.t("opex_year"), Geo.fmt_money(st.net.line_annual_opex(l)), Palette.WARN))
	for c in grid.get_children():
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	if m["underground"]:
		content.add_child(UI.stat_row(I18n.t("tunnel_depth"), I18n.t("depth_deep") if l.get("deep", false) else I18n.t("depth_shallow")))

	# vehicles stepper
	var vcard := UI.card()
	var vv := UI.vbox(10)
	var vh := UI.hbox(12)
	var vt := UI.vbox(2)
	vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt.add_child(UI.label(I18n.t("vehicles"), 26, Palette.TEXT, 850))
	vt.add_child(UI.label(I18n.t("add_vehicle_cost") % Geo.fmt_money(m["vehicle_cost"]), 20, Palette.MUTED))
	vh.add_child(vt)
	var minus := UI.icon_button("minus", 72)
	var count := UI.label(str(l["vehicles"]), 38, Palette.ACCENT, 900)
	count.custom_minimum_size.x = 70
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := UI.icon_button("plus", 72, "AccentButton", Color("1b1405"))
	minus.disabled = l["vehicles"] <= 1
	var cap := st.net.depot_capacity(l)
	plus.disabled = l["vehicles"] >= cap
	minus.pressed.connect(func():
		st.net.set_vehicles(lid, l["vehicles"] - 1)
		st.refund(m["vehicle_cost"] * 0.4)
		_after_line_change(content, lid)
	)
	plus.pressed.connect(func():
		if not st.spend(m["vehicle_cost"]):
			gs._error(I18n.t("not_enough_cash"))
			return
		st.net.set_vehicles(lid, l["vehicles"] + 1)
		st.feed.on_vehicles_added(st, lid)
		Audio.play("cash", 1.1, -6.0)
		_after_line_change(content, lid)
	)
	vh.add_child(minus)
	vh.add_child(count)
	vh.add_child(plus)
	vv.add_child(vh)
	# depot
	var dh := UI.hbox(12)
	var dl := UI.label("%s: %d / %d" % [I18n.t("depot"), l["vehicles"], cap], 22, Palette.MUTED if l["vehicles"] < cap else Palette.WARN)
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dl)
	if cap < m["max_vehicles"]:
		var exp_cost := st.net.depot_expand_cost(l)
		var eb := UI.button("%s (%s)" % [I18n.t("expand_depot"), Geo.fmt_money(exp_cost)], "", "", 60)
		eb.add_theme_font_size_override("font_size", 21)
		eb.pressed.connect(func():
			if not st.spend(exp_cost):
				gs._error(I18n.t("not_enough_cash"))
				return
			st.net.expand_depot(lid)
			Audio.play("build", 1.2, -6.0)
			_after_line_change(content, lid)
		)
		dh.add_child(eb)
	vv.add_child(dh)
	vcard.add_child(vv)
	content.add_child(vcard)

	# colour picker
	var ch := HFlowContainer.new()
	ch.add_theme_constant_override("h_separation", 10)
	ch.add_theme_constant_override("v_separation", 10)
	for i in TransitModes.LINE_COLORS.size():
		var cb := Button.new()
		cb.custom_minimum_size = Vector2(56, 56)
		cb.focus_mode = Control.FOCUS_NONE
		var sel: bool = int(l["color"]) == i
		cb.add_theme_stylebox_override("normal", ThemeBuilder.box(TransitModes.LINE_COLORS[i], 28, 4 if sel else 0, Color.WHITE, 0, 0))
		cb.add_theme_stylebox_override("hover", ThemeBuilder.box(TransitModes.LINE_COLORS[i].lightened(0.15), 28, 4 if sel else 0, Color.WHITE, 0, 0))
		cb.add_theme_stylebox_override("pressed", ThemeBuilder.box(TransitModes.LINE_COLORS[i], 28, 4, Color.WHITE, 0, 0))
		cb.pressed.connect(func():
			Audio.play("tap")
			st.net.set_line_color(lid, i)
			_after_line_change(content, lid)
		)
		ch.add_child(cb)
	content.add_child(UI.label(I18n.t("color"), 22, Palette.MUTED))
	content.add_child(ch)

	# actions
	var row := UI.hbox(12)
	if not l.get("loop", false):
		var ext := UI.button(I18n.t("extend"), "", "extend")
		ext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ext.pressed.connect(func(): gs.start_extend(lid, false))
		row.add_child(ext)
	var prof := UI.button(I18n.t("profile"), "", "profile")
	prof.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof.pressed.connect(func(): gs.show_modal(profile_modal(lid)))
	row.add_child(prof)
	content.add_child(row)
	var del := UI.button(I18n.t("delete_line"), "DangerButton", "trash")
	del.pressed.connect(func():
		var m2 := Modal.confirm(gs.ui_layer, I18n.t("confirm_delete_line") % l["name"], func():
			var lname: String = l["name"]
			st.log_remove(lid)
			var refund := st.net.remove_line(lid)
			st.feed.on_line_removed(st, lname)
			st.refund(refund)
			Audio.play("undo")
			if is_instance_valid(gs.sheet):
				gs.sheet.close()
			st.recompute_if_dirty()
			gs._update_hud()
		)
		gs.modal_count += 1
		m2.tree_exited.connect(func(): gs.modal_count = maxi(0, gs.modal_count - 1))
	)
	content.add_child(del)


func _after_line_change(content: VBoxContainer, lid: int) -> void:
	var st := _st()
	st.recompute_if_dirty()
	gs._update_hud()
	UI.clear(content)
	_fill_line(content, lid)


func _stat_tile(title: String, value: String, color: Color, note: String = "") -> Control:
	var p := UI.card()
	var v := UI.vbox(2)
	v.add_child(UI.label(title, 20, Palette.MUTED))
	var vl := UI.label(value, 28, color, 900)
	vl.clip_text = true
	v.add_child(vl)
	if note != "":
		v.add_child(UI.label(note, 19, Palette.BAD, 800))
	p.add_child(v)
	return p


func profile_modal(lid: int) -> Modal:
	var st := _st()
	var l: Dictionary = st.net.lines[lid]
	var m := Modal.create(I18n.t("profile_title") % l["name"], 900.0)
	var pv := ProfileView.new()
	pv.setup(st, l)
	pv.custom_minimum_size = Vector2(minf(840.0, gs.root_ui.get_viewport_rect().size.x - 110.0), 430)
	m.body.add_child(pv)
	var legend := UI.hbox(18)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	for it in [[Color("8d6e4f"), I18n.t("ground")], [Palette.WATER, I18n.t("sea")], [st.net.line_color(l), I18n.t("track")]]:
		legend.add_child(UI.color_dot(it[0], 22))
		legend.add_child(UI.label(it[1], 21, Palette.MUTED))
	m.body.add_child(legend)
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	return m


# ------------------------------------------------------------------ station

func station_sheet(sid: int) -> Sheet:
	var st := _st()
	var s: Dictionary = st.net.stations[sid]
	var sh := Sheet.create(st.net.station_display_name(sid), 0.55)
	var row := UI.hbox(10)
	for lid in s["lines"]:
		var l: Dictionary = st.net.lines[lid]
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(110, 60)
		var badge := UI.color_dot(st.net.line_color(l), 44, l["name"])
		badge.position = Vector2(8, 8)
		b.add_child(badge)
		b.pressed.connect(func(): gs.open_line(lid))
		row.add_child(b)
	sh.body.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.add_child(_stat_tile(I18n.t("boardings"), Geo.fmt_int(st.demand.station_boardings.get(sid, 0.0)), Palette.INFO))
	grid.add_child(_stat_tile(I18n.t("elevation"), "%d m" % int(st.city.elevation(s["pos"])), Palette.TEXT))
	for c in grid.get_children():
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.body.add_child(grid)
	if s["lines"].size() > 1:
		sh.body.add_child(UI.label("⇄ " + I18n.t("transfer"), 24, Palette.GOOD, 850))
	var rn := UI.button(I18n.t("rename_station"), "", "build", 64)
	rn.pressed.connect(func(): gs.show_modal(rename_modal(sid)))
	sh.body.add_child(rn)
	# extend shortcut when station is a line end
	for lid in s["lines"]:
		var l: Dictionary = st.net.lines[lid]
		if l.get("loop", false):
			continue
		var stl: Array = l["stations"]
		if stl[0] == sid or stl[stl.size() - 1] == sid:
			var b := UI.button("%s %s" % [I18n.t("extend"), l["name"]], "", "extend")
			b.pressed.connect(func(): gs.start_extend(lid, stl[0] == sid))
			sh.body.add_child(b)
	return sh


# ------------------------------------------------------------------ goals

func goal_text(g: Dictionary) -> String:
	match g["type"]:
		"riders":
			return I18n.t("goal_riders") % Geo.fmt_short(g["value"])
		"cross_sides":
			return I18n.t("goal_cross_sides")
		"serve_pois":
			var names: Array = []
			for pid in g["pois"]:
				for poi in _st().city.pois:
					if poi["id"] == pid:
						names.append(I18n.t(poi["name_key"]))
			return I18n.t("goal_serve_pois") % ", ".join(names)
		"modes":
			return I18n.t("goal_modes") % g["value"]
		"mode_riders":
			var mn := I18n.t(TransitModes.get_mode(g["mode"])["name_key"])
			return I18n.t("goal_mode_riders") % [mn, Geo.fmt_short(g["value"])]
		"profit":
			return I18n.t("goal_profit")
		"coverage":
			return I18n.t("goal_coverage") % int(g["value"] * 100.0)
	return g["id"]


func goals_sheet() -> Sheet:
	var st := _st()
	var s := Sheet.create(I18n.t("goals_title"), 0.8)
	var stars := st.stars()
	var sr := UI.hbox(8)
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		sr.add_child(Icon.make("star" if i < stars else "star_o", 56, Palette.ACCENT if i < stars else Palette.FAINT))
	s.body.add_child(sr)
	var sg: Array = st.city.data["star_goals"]
	s.body.add_child(UI.wrap_label("★ %s · ★★ %s · ★★★ %s" % [str(sg[0]), str(sg[1]), str(sg[2])], 20, Palette.FAINT))
	var sat := st.demand.satisfaction
	s.body.add_child(UI.stat_row(I18n.t("satisfaction"), "%d%%" % int(sat), Palette.GOOD if sat >= 65 else Palette.WARN))
	s.body.add_child(UI.stat_row(I18n.t("coverage"), "%d%%" % int(st.demand.coverage * 100.0)))
	for g in st.goals():
		var done := st.completed_goals.has(g["id"])
		var prog := 1.0 if done else st.goal_progress(g)
		var card := UI.card()
		var v := UI.vbox(8)
		var h := UI.hbox(12)
		h.add_child(Icon.make("check" if done else "target", 36, Palette.GOOD if done else Palette.MUTED))
		var t := UI.wrap_label(goal_text(g), 24, Palette.TEXT if not done else Palette.GOOD)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		v.add_child(h)
		v.add_child(UI.progress(prog, Palette.GOOD if done else Palette.ACCENT, 10.0))
		card.add_child(v)
		s.body.add_child(card)
	return s


# ------------------------------------------------------------------ finance

func finance_sheet() -> Sheet:
	var s := Sheet.create(I18n.t("finance_title"), 0.85)
	var content := UI.vbox(14)
	s.body.add_child(content)
	var fill := func():
		UI.clear(content)
		_fill_finance(content)
	fill.call()
	s.set_meta("live", fill)
	return s


func _fill_finance(content: VBoxContainer) -> void:
	var st := _st()
	var inc := st.monthly_income()
	var grant := st.monthly_grant()
	var exp := st.monthly_expense()
	var net := inc + grant - exp
	content.add_child(UI.stat_row(I18n.t("cash"), Geo.fmt_money(st.cash), Palette.BAD if st.cash < 0 else Palette.ACCENT))
	content.add_child(UI.stat_row(I18n.t("income_month"), "+" + Geo.fmt_money(inc), Palette.GOOD))
	content.add_child(UI.stat_row(I18n.t("grant_month"), "+" + Geo.fmt_money(grant), Palette.GOOD))
	content.add_child(UI.stat_row(I18n.t("expense_month"), "-" + Geo.fmt_money(exp), Palette.BAD))
	content.add_child(HSeparator.new())
	content.add_child(UI.stat_row(I18n.t("net_month"), ("+" if net >= 0 else "") + Geo.fmt_money(net), Palette.GOOD if net >= 0 else Palette.BAD))
	content.add_child(UI.stat_row(I18n.t("credit"), Geo.fmt_money(st.credit_limit())))
	content.add_child(UI.wrap_label(I18n.t("grant_hint"), 20, Palette.FAINT))
	var hist: Array = st.history.slice(maxi(0, st.history.size() - 24))
	var rv: Array = []
	var cv: Array = []
	var lb: Array = []
	for h in hist:
		rv.append(h["riders"])
		cv.append(h["cash"])
		lb.append("%s %02d" % [I18n.month_name(int(h["m"])), int(h["y"]) % 100])
	content.add_child(UI.label(I18n.t("riders_history"), 24, Palette.TEXT, 850))
	var c1 := MiniChart.new()
	c1.custom_minimum_size.y = 210
	c1.formatter = func(v: float) -> String: return Geo.fmt_short(v)
	c1.set_data(rv, lb, Palette.INFO, "bar")
	content.add_child(c1)
	content.add_child(UI.label(I18n.t("cash_history"), 24, Palette.TEXT, 850))
	var c2 := MiniChart.new()
	c2.custom_minimum_size.y = 210
	c2.formatter = func(v: float) -> String: return Geo.fmt_money(v)
	c2.set_data(cv, lb, Palette.ACCENT, "line")
	content.add_child(c2)


# ------------------------------------------------------------------ layers

func layers_sheet() -> Sheet:
	var s := Sheet.create(I18n.t("overlay_title"), 0.5)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for it in [["none", "overlay_none", "home"], ["pop", "overlay_pop", "people"], ["jobs", "overlay_jobs", "target"], ["elev", "overlay_elev", "profile"]]:
		var b := UI.button(I18n.t(it[1]), "AccentButton" if gs.overlay == it[0] else "", it[2], 90)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind: String = it[0]
		b.pressed.connect(func():
			gs.set_overlay(kind)
			s.close()
		)
		grid.add_child(b)
	s.body.add_child(grid)
	return s


# ------------------------------------------------------------------ year report

func year_report(r: Dictionary) -> Modal:
	var m := Modal.create(I18n.t("year_report") % r["year"], 640.0)
	var b := m.body
	var big := UI.label(Geo.fmt_int(r["riders"]), 60, Palette.INFO, 900)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(big)
	var sub := UI.label(I18n.t("riders_day"), 24, Palette.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(sub)
	b.add_child(HSeparator.new())
	b.add_child(UI.stat_row(I18n.t("fare_income"), "+" + Geo.fmt_money(r["fare_income"]), Palette.GOOD))
	b.add_child(UI.stat_row(I18n.t("grant"), "+" + Geo.fmt_money(r["grant"]), Palette.GOOD))
	b.add_child(UI.stat_row(I18n.t("opex"), "-" + Geo.fmt_money(r["expense"]), Palette.BAD))
	b.add_child(UI.stat_row(I18n.t("capex"), "-" + Geo.fmt_money(maxf(0.0, r["capex"])), Palette.WARN))
	var op: float = r["operating_profit"]
	b.add_child(UI.stat_row(I18n.t("op_profit"), ("+" if op >= 0 else "") + Geo.fmt_money(op), Palette.GOOD if op >= 0 else Palette.BAD))
	b.add_child(HSeparator.new())
	b.add_child(UI.stat_row(I18n.t("satisfaction"), "%d%%" % int(r["satisfaction"])))
	b.add_child(UI.stat_row(I18n.t("coverage"), "%d%%" % int(r["coverage"] * 100.0)))
	b.add_child(UI.stat_row(I18n.t("lines_count"), str(r["lines"])))
	b.add_child(UI.stat_row(I18n.t("net_cash"), Geo.fmt_money(r["cash"]), Palette.ACCENT))
	var row := UI.hbox(12)
	var tl := UI.button(I18n.t("timelapse"), "", "calendar")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.pressed.connect(func():
		m.close()
		gs.show_modal(timelapse_modal())
	)
	row.add_child(tl)
	var ok := UI.button(I18n.t("continue"), "AccentButton", "play")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(m.close)
	row.add_child(ok)
	b.add_child(row)
	return m


# ------------------------------------------------------------------ social feed ("Cıvıltı")

var _social_filter := "all"


func social_sheet() -> Sheet:
	var st := _st()
	st.feed.unread = 0
	var s := Sheet.create(I18n.t("social_title"), 0.88)
	var bird := Icon.make("bird", 44, Palette.INFO)
	bird.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.header.add_child(bird)
	s.header.move_child(bird, 0)
	var content := UI.vbox(14)
	s.body.add_child(content)
	var fill := func():
		UI.clear(content)
		_fill_social(content, s)
	fill.call()
	s.set_meta("live", fill)
	return s


func _fill_social(content: VBoxContainer, s: Sheet) -> void:
	var st := _st()
	var feed := st.feed
	feed.unread = 0
	# public opinion
	var card := UI.card()
	var v := UI.vbox(8)
	var ap := feed.approval
	var col := Palette.GOOD if ap >= 60 else (Palette.WARN if ap >= 40 else Palette.BAD)
	v.add_child(UI.stat_row(I18n.t("public_opinion"), "%d%%" % int(ap), col))
	v.add_child(UI.progress(ap / 100.0, col, 10.0))
	v.add_child(UI.wrap_label(I18n.t("opinion_hint"), 19, Palette.FAINT))
	card.add_child(v)
	content.add_child(card)
	# trending
	var tr := feed.trending(5)
	if not tr.is_empty():
		content.add_child(UI.label(I18n.t("trending"), 22, Palette.MUTED, 800))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		for tag in tr:
			var chip := PanelContainer.new()
			chip.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(Palette.INFO, 0.15), 16, 0, Color.TRANSPARENT, 12, 6))
			chip.add_child(UI.label(tag, 21, Palette.INFO, 850))
			flow.add_child(chip)
		content.add_child(flow)
	# filters
	var fr := UI.hbox(8)
	for it in [["all", "filter_all"], ["pos", "filter_praise"], ["neg", "filter_complaints"], ["news", "filter_news"]]:
		var key: String = it[0]
		var b := UI.button(I18n.t(it[1]), "AccentButton" if _social_filter == key else "", "", 56)
		b.add_theme_font_size_override("font_size", 20)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			_social_filter = key
			UI.clear(content)
			_fill_social(content, s)
		)
		fr.add_child(b)
	content.add_child(fr)
	var shown := 0
	for p in feed.posts:
		var kind: String = p["who"].get("kind", "citizen")
		match _social_filter:
			"pos":
				if float(p["sent"]) <= 0.3 or kind != "citizen":
					continue
			"neg":
				if float(p["sent"]) >= -0.3:
					continue
			"news":
				if kind == "citizen":
					continue
		content.add_child(PostCard.make(p, feed))
		shown += 1
		if shown >= 40:
			break
	if shown == 0:
		content.add_child(UI.wrap_label(I18n.t("social_empty"), 23, Palette.MUTED))


# ------------------------------------------------------------------ research ("Ar-Ge")

func tech_sheet() -> Sheet:
	var s := Sheet.create(I18n.t("tech_title"), 0.85)
	var content := UI.vbox(12)
	s.body.add_child(content)
	var fill := func():
		UI.clear(content)
		_fill_tech(content)
	fill.call()
	s.set_meta("live", fill)
	return s


func _fill_tech(content: VBoxContainer) -> void:
	var st := _st()
	content.add_child(UI.wrap_label(I18n.t("tech_hint"), 21, Palette.FAINT))
	if not st.research.is_empty():
		var cur := UI.card()
		var cv := UI.vbox(8)
		var rid: String = st.research["id"]
		var hh := UI.hbox(10)
		hh.add_child(Icon.make("flask", 36, Palette.INFO))
		var tl := UI.label(I18n.t("tech_running") + ": " + I18n.t("tech_" + rid), 24, Palette.TEXT, 850)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hh.add_child(tl)
		cv.add_child(hh)
		var total: int = st.research["total"]
		var left: int = st.research["months"]
		cv.add_child(UI.progress(1.0 - float(left) / total, Palette.INFO, 12.0))
		cv.add_child(UI.label(I18n.t("months_left") % left, 20, Palette.MUTED))
		cur.add_child(cv)
		content.add_child(cur)
	for id in TechData.ORDER:
		content.add_child(_tech_card(id))


func _tech_card(id: String) -> Control:
	var st := _st()
	var t := TechData.get_tech(id)
	var state := st.tech_state(id)
	var done := state == "done"
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ThemeBuilder.box(Color("16302c") if done else Palette.PANEL_2, 22, 2 if done else 0, Color(Palette.GOOD, 0.5), 18, 14))
	var h := UI.hbox(14)
	var ic := Icon.make(t["icon"], 44, Palette.GOOD if done else (Palette.TEXT if state == "available" else Palette.FAINT))
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(ic)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(I18n.t("tech_" + id), 26, Palette.TEXT, 900))
	v.add_child(UI.wrap_label(I18n.t("tech_" + id + "_d"), 20, Palette.MUTED))
	var info := ""
	match state:
		"done": info = "✓ " + I18n.t("tech_done")
		"running": info = I18n.t("tech_running")
		"locked_year": info = I18n.t("tech_from_year") % int(t["year"])
		"locked_req": info = I18n.t("tech_requires") % I18n.t("tech_" + str(t["requires"]))
		"busy": info = I18n.t("tech_busy")
		_: info = "%s · %d %s" % [Geo.fmt_money(t["cost"]), int(t["months"]), I18n.t("months_short")]
	v.add_child(UI.label(info, 20, Palette.GOOD if done else Palette.ACCENT, 800))
	h.add_child(v)
	if state == "available":
		var b := UI.button(I18n.t("tech_start"), "AccentButton", "", 64)
		b.add_theme_font_size_override("font_size", 21)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = not st.can_afford(t["cost"])
		b.pressed.connect(func():
			if st.start_research(id):
				Audio.play("cash")
				gs.toast.show_msg(I18n.t("tech_started") % I18n.t("tech_" + id), "info")
				gs._update_hud()
				gs._refresh_live_sheet()
			else:
				gs._error(I18n.t("not_enough_cash"))
		)
		h.add_child(b)
	card.add_child(h)
	return card


# ------------------------------------------------------------------ timelapse

func timelapse_modal() -> Modal:
	var st := _st()
	var m := Modal.create(I18n.t("timelapse"), 900.0)
	var vs := gs.root_ui.get_viewport_rect().size
	var tv := TimelapseView.new()
	tv.setup(st)
	tv.custom_minimum_size = Vector2(minf(840.0, vs.x - 110.0), minf(760.0, vs.y * 0.55))
	m.body.add_child(tv)
	var row := UI.hbox(12)
	var again := UI.button(I18n.t("replay"), "", "undo")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(tv.restart)
	row.add_child(again)
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(m.close)
	row.add_child(ok)
	m.body.add_child(row)
	return m


# ------------------------------------------------------------------ rename station

func rename_modal(sid: int) -> Modal:
	var st := _st()
	var m := Modal.create(I18n.t("rename_station"), 620.0)
	var le := LineEdit.new()
	le.text = st.net.station_display_name(sid)
	le.max_length = 28
	le.custom_minimum_size.y = 76
	le.add_theme_font_size_override("font_size", 28)
	le.add_theme_stylebox_override("normal", ThemeBuilder.box(Palette.PANEL_2, 18, 2, Palette.STROKE, 18, 10))
	le.add_theme_stylebox_override("focus", ThemeBuilder.box(Palette.PANEL_2, 18, 2, Palette.ACCENT, 18, 10))
	le.select_all_on_focus = true
	m.body.add_child(le)
	var apply := func():
		if le.text.strip_edges() != "":
			st.net.rename_station(sid, le.text)
			gs.world.network.queue_redraw()
			Audio.play("place")
			gs.check_achievements()
		m.close()
		if is_instance_valid(gs.sheet):
			gs.sheet.close()
	le.text_submitted.connect(func(_t): apply.call())
	var ok := UI.button(I18n.t("ok"), "AccentButton")
	ok.pressed.connect(apply)
	m.body.add_child(ok)
	le.call_deferred("grab_focus")
	return m
