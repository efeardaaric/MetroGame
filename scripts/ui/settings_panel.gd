class_name SettingsPanel
extends RefCounted
## Settings dialog shared by the main menu and the in-game pause menu.


static func open(parent: Node, on_language_changed: Callable = Callable()) -> Modal:
	var m := Modal.create(I18n.t("settings"), 640.0)
	var b := m.body

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
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	b.add_child(ok)
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
