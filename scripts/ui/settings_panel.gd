class_name SettingsPanel
extends RefCounted
## Settings dialog shared by the main menu and the in-game pause menu.


static func open(parent: Node, on_language_changed: Callable = Callable()) -> Modal:
	var m := Modal.create(I18n.t("settings"), 640.0)
	var sc0 := ScrollContainer.new()
	sc0.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc0.custom_minimum_size.y = minf(980.0, parent.get_viewport().get_visible_rect().size.y * 0.66)
	m.body.add_child(sc0)
	var b := UI.vbox(18)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc0.add_child(b)

	b.add_child(_slider_row(I18n.t("music"), Settings.music_volume, func(v: float):
		Settings.music_volume = v
		Settings.save_settings()
	))
	b.add_child(_slider_row(I18n.t("sfx"), Settings.sfx_volume, func(v: float):
		Settings.sfx_volume = v
		Settings.save_settings()
		Audio.play("tap")
	))
	b.add_child(_slider_row(I18n.t("ambience"), Settings.ambience_volume, func(v: float):
		Settings.ambience_volume = v
		Settings.save_settings()
	))
	b.add_child(_toggle_row(I18n.t("haptics"), Settings.haptics, func(on: bool):
		Settings.haptics = on
		Settings.save_settings()
		Settings.vibrate(20)
	))
	b.add_child(_toggle_row(I18n.t("day_night"), Settings.day_night, func(on: bool):
		Settings.day_night = on
		Settings.save_settings()
	))
	b.add_child(_toggle_row(I18n.t("show_fps"), Settings.show_fps, func(on: bool):
		Settings.show_fps = on
		Settings.save_settings()
	))
	# language
	var lrow := UI.hbox(12)
	var ll := UI.label(I18n.t("language"), 26, Palette.MUTED)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lrow.add_child(ll)
	for code in ["tr", "en"]:
		var btn := UI.button("Türkçe" if code == "tr" else "English", "AccentButton" if I18n.lang == code else "", "", 64)
		btn.pressed.connect(func():
			Settings.set_language(code)
			m.close()
			if on_language_changed.is_valid():
				on_language_changed.call()
		)
		lrow.add_child(btn)
	b.add_child(lrow)
	b.add_child(HSeparator.new())
	# graphics & accessibility
	b.add_child(UI.plate(I18n.t("accessibility"), Palette.STRIPES[2]))
	b.add_child(_toggle_row(I18n.t("high_quality"), Settings.high_quality, func(on: bool):
		Settings.high_quality = on
		Settings.save_settings()
	))
	b.add_child(_toggle_row(I18n.t("colorblind"), Settings.colorblind, func(on: bool):
		Settings.colorblind = on
		Settings.save_settings()
	))
	b.add_child(_toggle_row(I18n.t("reduce_motion"), Settings.reduce_motion, func(on: bool):
		Settings.reduce_motion = on
		Settings.save_settings()
	))
	var trow := UI.hbox(10)
	var tl := UI.label(I18n.t("text_size"), 26, Palette.MUTED)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(tl)
	for sc in [1.0, 1.15, 1.3]:
		var tb := UI.button("A" if sc == 1.0 else ("A+" if sc < 1.2 else "A++"), "AccentButton" if is_equal_approx(Settings.text_scale, sc) else "", "", 60)
		tb.pressed.connect(func():
			Settings.text_scale = sc
			Settings.save_settings()
			m.close()
		)
		trow.add_child(tb)
	b.add_child(trow)
	b.add_child(HSeparator.new())
	# save transfer between devices (no account needed)
	b.add_child(UI.plate(I18n.t("save_transfer"), Palette.STRIPES[1]))
	var srow := UI.hbox(10)
	var ex := UI.button(I18n.t("export_save"), "", "", 64)
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex.add_theme_font_size_override("font_size", 21)
	ex.pressed.connect(func():
		DisplayServer.clipboard_set(SaveManager.export_code())
		Audio.play("cash")
		ex.text = I18n.t("copied")
	)
	srow.add_child(ex)
	var im := UI.button(I18n.t("import_save"), "", "", 64)
	im.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	im.add_theme_font_size_override("font_size", 21)
	im.pressed.connect(func():
		var ok2 := SaveManager.import_code(DisplayServer.clipboard_get())
		Audio.play("goal" if ok2 else "error")
		im.text = I18n.t("imported") if ok2 else I18n.t("import_failed")
	)
	srow.add_child(im)
	b.add_child(srow)
	b.add_child(UI.wrap_label(I18n.t("save_transfer_hint"), 19, Palette.FAINT))
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	parent.add_child(m)
	return m


static func _slider_row(title: String, value: float, cb: Callable) -> Control:
	var v := UI.vbox(6)
	v.add_child(UI.label(title, 26, Palette.MUTED))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size.y = 48
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(cb)
	v.add_child(s)
	return v


static func _toggle_row(title: String, on: bool, cb: Callable) -> Control:
	var h := UI.hbox(12)
	var l := UI.label(title, 26, Palette.MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var c := CheckButton.new()
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(cb)
	h.add_child(c)
	h.custom_minimum_size.y = 56
	return h
