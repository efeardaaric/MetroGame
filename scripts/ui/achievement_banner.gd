class_name AchievementBanner
extends Control
## Gold "achievement unlocked" banner that slides from the top. Queues multiple unlocks.

var _queue: Array = []
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func push(id: String) -> void:
	_queue.append(id)
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var id: String = _queue.pop_front()
	var vs := get_viewport_rect().size
	var w := minf(vs.x - 40.0, 640.0)
	var p := PanelContainer.new()
	var sb := ThemeBuilder.box(Color("2b2410"), 26, 3, Palette.ACCENT, 20, 16, 18)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = w
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(16)
	var medal := PanelContainer.new()
	medal.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.ACCENT, 34, 0, Color.TRANSPARENT, 12, 12))
	medal.add_child(Icon.make(Achievements.icon_of(id), 44, Color("2b2410")))
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(medal)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.label(I18n.t("achievement_unlocked").to_upper(), 18, Palette.ACCENT, 900))
	v.add_child(UI.label(I18n.t("ach_" + id), 28, Palette.TEXT, 900))
	var d := UI.wrap_label(I18n.t("ach_" + id + "_d"), 20, Palette.MUTED)
	d.custom_minimum_size.x = w - 150.0
	v.add_child(d)
	h.add_child(v)
	p.add_child(h)
	add_child(p)
	p.reset_size()
	var top := 20.0 + SafeArea.margins(self).y
	p.position = Vector2((vs.x - w) * 0.5, -p.size.y - 20.0)
	Audio.play("goal", 1.15)
	Settings.vibrate(60)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "position:y", top, 0.45)
	tw.tween_interval(3.2)
	tw.tween_property(p, "position:y", -p.size.y - 40.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		p.queue_free()
		_next()
	)


## Modal listing all achievements.
static func open_list(parent: Node) -> Modal:
	var u := Achievements.unlocked()
	var m := Modal.create(I18n.t("achievements") + "  %d/%d" % [u.size(), Achievements.LIST.size()], 700.0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.y = minf(900.0, parent.get_viewport().get_visible_rect().size.y * 0.62)
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	for a in Achievements.LIST:
		var id: String = a[0]
		var got := u.has(id)
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", ThemeBuilder.box(Color("2b2410") if got else Palette.PANEL_2, 20, 2 if got else 0, Color(Palette.ACCENT, 0.6), 16, 12))
		var h := UI.hbox(14)
		h.add_child(Icon.make(a[1] if got else "lock", 44, Palette.ACCENT if got else Palette.FAINT))
		var tv := UI.vbox(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.label(I18n.t("ach_" + id), 25, Palette.TEXT if got else Palette.MUTED, 900))
		tv.add_child(UI.wrap_label(I18n.t("ach_" + id + "_d"), 20, Palette.MUTED if got else Palette.FAINT))
		h.add_child(tv)
		if got:
			h.add_child(UI.label(str(u[id]), 18, Palette.ACCENT, 800))
		row.add_child(h)
		v.add_child(row)
	m.body.add_child(sc)
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	parent.add_child(m)
	return m
