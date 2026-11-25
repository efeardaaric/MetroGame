class_name AgendaUI
extends RefCounted
## Election countdown, upcoming real events, their dialogs, and the pop-up that
## drops important social-media posts onto the screen.

var g: GameScreen
var row: HBoxContainer
var elec_chip: Button
var elec_label: Label
var elec_bar: ProgressBar
var event_chip: Button
var event_label: Label
var event_icon: Icon
var pop_holder: Control
var _pop_queue: Array = []
var _pop_busy := false


func _init(screen: GameScreen) -> void:
	g = screen


# ------------------------------------------------------------------ HUD chips

func build(hud: VBoxContainer) -> void:
	row = UI.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(row)
	var e := _chip("megaphone", Palette.ACCENT)
	elec_chip = e[0]
	elec_label = e[1]
	elec_bar = UI.progress(0.0, Palette.ACCENT, 5.0)
	(e[2] as VBoxContainer).add_child(elec_bar)
	elec_chip.pressed.connect(open_election)
	row.add_child(elec_chip)
	var v := _chip("calendar", Palette.INFO)
	event_chip = v[0]
	event_label = v[1]
	event_icon = v[3]
	event_chip.pressed.connect(open_next_event)
	row.add_child(event_chip)
	pop_holder = Control.new()
	pop_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.root_ui.add_child(pop_holder)
	refresh()


func _chip(icon: String, col: Color) -> Array:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 54
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := ThemeBuilder.box(Color(0.11, 0.12, 0.2, 0.94), 18, 1, Color(col, 0.55), 10, 4, 4)
	for s in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(s, st)
	var h := UI.hbox(8)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Icon.make(icon, 26, col)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var vb := UI.vbox(2)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.label("", 19, Palette.TEXT, 800)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(l)
	h.add_child(vb)
	b.add_child(h)
	return [b, l, vb, ic]


func refresh() -> void:
	if row == null:
		return
	var st := g.state
	elec_chip.visible = st.is_campaign()
	if elec_chip.visible:
		var left := st.elec.months_left(st)
		var poll := int(round(st.elec.poll(st)))
		if left == 0:
			elec_label.text = I18n.t("elec_chip_now") % poll
		else:
			elec_label.text = I18n.t("elec_chip") % [st.elec.next_year(st), left, poll]
		elec_bar.value = clampf(poll / 100.0 / 0.7, 0.0, 1.0)
		var col := Palette.GOOD if poll >= 53 else (Palette.WARN if poll >= Elections.WIN_SHARE - 2 else Palette.BAD)
		elec_bar.add_theme_stylebox_override("fill", ThemeBuilder.box(col, 3))
	var up := st.calendar.upcoming(st)
	event_chip.visible = not up.is_empty()
	if not up.is_empty():
		var e: Dictionary = up[0]["e"]
		var ready: bool = not e.get("need_serve", false) or st.calendar.is_served(st, e)
		event_label.text = I18n.t("re_chip") % [I18n.t("re_" + str(e["id"])), int(up[0]["left"])]
		event_icon.set_color(Palette.GOOD if ready else Palette.BAD)
	row.visible = elec_chip.visible or event_chip.visible


# ------------------------------------------------------------------ events

func open_next_event() -> void:
	var up := g.state.calendar.upcoming(g.state)
	if not up.is_empty():
		event_modal(up[0]["e"], int(up[0]["left"]))


func event_modal(e: Dictionary, left: int) -> void:
	var st := g.state
	var m := Modal.create(I18n.t("re_announce_title"), 640.0)
	m.body.add_child(UI.plate(I18n.t("re_" + str(e["id"])).to_upper(), Palette.ACCENT, 26))
	var body := I18n.t("re_announce_body") % [I18n.t("re_" + str(e["id"])), left, RealEvents.SERVE_KM]
	var l := UI.wrap_label(body, 24, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	if e.get("need_serve", false):
		var ok := st.calendar.is_served(st, e)
		m.body.add_child(UI.plate(I18n.t("re_ready" if ok else "re_not_ready").to_upper(), Palette.GOOD if ok else Palette.BAD))
	if e.has("venue"):
		var show := UI.button(I18n.t("re_show_venue"), "AccentButton", "target")
		show.pressed.connect(func():
			m.close()
			g.world.focus_km(st.calendar.venue_pos(st, e), 0.32)
		)
		m.body.add_child(show)
	var close := UI.button(I18n.t("ok"), "")
	close.pressed.connect(m.close)
	m.body.add_child(close)
	Audio.play("chime")
	g.show_modal(m)


func on_announced(e: Dictionary, left: int) -> void:
	refresh()
	g.world.events.refresh()
	if e.get("need_serve", false):
		g.call_deferred("_queue_modal", func(): event_modal(e, left))
	else:
		g.toast.show_msg(I18n.t("re_chip") % [I18n.t("re_" + str(e["id"])), left], "info", 4.0)


func on_started(e: Dictionary, served: bool) -> void:
	var name := I18n.t("re_" + str(e["id"]))
	if e.get("need_serve", false):
		if served:
			g.toast.show_msg(I18n.t("re_ok_toast") % [name, Geo.fmt_money(roundf(float(g.state.city.data["annual_grant"]) * float(e.get("reward", 0.2))))], "star", 5.0)
			Audio.play("goal")
		else:
			g.toast.show_msg(I18n.t("re_fail_toast") % name, "error", 5.0)
			Audio.play("error")
	else:
		g.toast.show_msg(I18n.t("re_started_toast") % name, "info", 4.0)
	g.world.events.refresh()
	refresh()


# ------------------------------------------------------------------ elections

func open_election() -> void:
	var st := g.state
	var ey := st.elec.next_year(st)
	var m := Modal.create(I18n.t("elec_title") % ey, 640.0)
	var intro := UI.wrap_label(I18n.t("elec_intro") % [ey, int(Elections.WIN_SHARE)], 23, Palette.MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(intro)
	var v := st.elec.vote(st)
	for k in ["base", "sat", "approval", "coverage", "growth", "promise", "debt", "fatigue", "events"]:
		var val: float = v[k]
		if k in ["promise", "debt", "fatigue", "events", "growth"] and absf(val) < 0.05:
			continue
		var title := I18n.t("elec_part_" + k)
		if k == "coverage":
			title = title % int(round(st.elec.coverage_target() * 100.0))
		m.body.add_child(UI.stat_row(title, "%+.1f" % val, Palette.GOOD if val > 0.0 else Palette.BAD))
	var tot: float = v["total"]
	m.body.add_child(UI.stat_row(I18n.t("elec_projection"), "%d%%" % int(round(tot)), Palette.GOOD if tot >= Elections.WIN_SHARE else Palette.BAD))
	if not st.elec.promise.is_empty():
		m.body.add_child(UI.label(I18n.t("elec_promise_status") % [I18n.t("elec_promise_" + str(st.elec.promise["type"])), int(st.elec.promise_progress(st) * 100.0)], 22, Palette.ACCENT, 800))
	var ok := UI.button(I18n.t("ok"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	g.show_modal(m)


func promise_modal() -> void:
	var st := g.state
	var m := Modal.create(I18n.t("elec_promise_title"), 640.0, false)
	var l := UI.wrap_label(I18n.t("elec_promise_body"), 24, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	for p in Elections.PROMISES:
		var b := UI.button(I18n.t("elec_promise_" + p), "AccentButton", "megaphone")
		b.pressed.connect(func():
			st.elec.make_promise(st, p)
			m.close()
			refresh()
		)
		m.body.add_child(b)
	var none := UI.button(I18n.t("elec_promise_none"), "")
	none.pressed.connect(m.close)
	m.body.add_child(none)
	Audio.play("chime")
	g.show_modal(m)


func on_election(res: Dictionary) -> void:
	var st := g.state
	var won: bool = res.get("won", false)
	var share := int(round(float(res.get("share", 0.0))))
	var m := Modal.create(I18n.t("elec_won_title" if won else "elec_lost_title"), 620.0, false)
	var big := UI.title("%d%%" % share, 84, Palette.GOOD if won else Palette.BAD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(big)
	var l := UI.wrap_label(I18n.t("elec_won_body" if won else "elec_lost_body") % share, 24, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	if won:
		g.confetti.burst(160)
		Audio.play("year")
		var ok := UI.button(I18n.t("ok"), "AccentButton", "check")
		ok.pressed.connect(m.close)
		m.body.add_child(ok)
	else:
		Audio.play("error")
		var restart := UI.button(I18n.t("restart"), "AccentButton", "undo")
		restart.pressed.connect(func():
			SaveManager.delete_save(st.slot())
			m.close()
			g.get_parent().call("start_city", st.slot(), true)
		)
		m.body.add_child(restart)
		var menu := UI.button(I18n.t("main_menu"), "", "home")
		menu.pressed.connect(func():
			m.close()
			g.exit_to_menu.emit()
		)
		m.body.add_child(menu)
	g.show_modal(m)
	refresh()


func monthly_warning() -> void:
	var st := g.state
	if not st.is_campaign():
		return
	var left := st.elec.months_left(st)
	if left in [12, 6, 3, 1]:
		var poll := int(round(st.elec.poll(st)))
		g.toast.show_msg(I18n.t("elec_warn") % [left, poll, int(Elections.WIN_SHARE)], "error" if poll < Elections.WIN_SHARE else "info", 4.5)


# ------------------------------------------------------------------ post pop-ups

func push_post(p: Dictionary) -> void:
	if not p.get("imp", false):
		return
	if _pop_queue.size() >= 3:
		_pop_queue.pop_front()
	_pop_queue.append(p)
	if not _pop_busy:
		_next_pop()


func _next_pop() -> void:
	if _pop_queue.is_empty() or not is_instance_valid(pop_holder):
		_pop_busy = false
		return
	_pop_busy = true
	var p: Dictionary = _pop_queue.pop_front()
	var vs := g.root_ui.get_viewport_rect().size
	var w := minf(vs.x - 32.0, 640.0)
	var card := PostCard.make(p, g.state.feed)
	card.custom_minimum_size.x = w
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_all(card)
	var holder := Button.new()
	holder.flat = true
	holder.focus_mode = Control.FOCUS_NONE
	holder.add_child(card)
	pop_holder.add_child(holder)
	var top := g.hud.position.y + g.hud.get_combined_minimum_size().y + 12.0
	holder.position = Vector2((vs.x - w) * 0.5, top - 40.0)
	holder.size = Vector2(w, 10)
	holder.modulate.a = 0.0
	await g.get_tree().process_frame
	if not is_instance_valid(holder):
		_pop_busy = false
		return
	holder.size = card.size
	holder.pressed.connect(func():
		holder.visible = false
		g.open_social()
	)
	Audio.play("tap", 1.6, -8.0)
	var tw := holder.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "position:y", top, 0.35)
	tw.parallel().tween_property(holder, "modulate:a", 1.0, 0.25)
	tw.tween_interval(4.2)
	tw.tween_property(holder, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(holder, "position:y", top - 30.0, 0.3)
	tw.tween_callback(func():
		holder.queue_free()
		_next_pop()
	)


func _ignore_all(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_all(c)
