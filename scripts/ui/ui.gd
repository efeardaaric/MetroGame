class_name UI
extends RefCounted
## Factory helpers to build UI in code with consistent styling.


static func label(text: String, size: int = 26, color: Color = Palette.TEXT, weight: int = 650) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if weight >= 900:
		l.add_theme_font_override("font", ThemeBuilder.display(800))
	elif weight != 650:
		l.add_theme_font_override("font", ThemeBuilder.font(weight))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, size: int = 24, color: Color = Palette.MUTED) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 100
	return l


static func button(text: String, variation: String = "", icon_kind: String = "", min_h: float = 76.0) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size.y = min_h
	b.focus_mode = Control.FOCUS_NONE
	if icon_kind != "":
		var ic := Icon.make(icon_kind, 34, Palette.INK if variation == "AccentButton" else Palette.TEXT)
		b.add_child(ic)
		b.set_meta("icon", ic)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		# keep icon positioned at the left padding
		var place := func():
			var sb := b.get_theme_stylebox("normal")
			var lip: float = sb.border_width_bottom if sb is StyleBoxFlat else 0.0
			ic.position = Vector2(22, (b.size.y - lip - ic.size.y) * 0.5)
		b.resized.connect(place)
		b.button_down.connect(func(): ic.position.y += 5)
		b.button_up.connect(place)
		b.text = "      " + text if text != "" else ""
	b.pressed.connect(func():
		Audio.play("tap")
		Settings.vibrate(8)
	)
	return b


static func icon_button(icon_kind: String, size: float = 76.0, variation: String = "", icon_color: Color = Palette.TEXT) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	if variation != "":
		b.theme_type_variation = variation
	var ic := Icon.make(icon_kind, size * 0.48, icon_color)
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lip := 0.0 if variation == "FlatButton" else 3.5
	ic.offset_left = size * 0.26
	ic.offset_top = size * 0.26 - lip
	ic.offset_right = -size * 0.26
	ic.offset_bottom = -size * 0.26 - lip
	b.add_child(ic)
	if lip > 0.0:
		b.button_down.connect(func():
			ic.offset_top += 5.0
			ic.offset_bottom += 5.0
		)
		b.button_up.connect(func():
			ic.offset_top = size * 0.26 - lip
			ic.offset_bottom = -size * 0.26 - lip
		)
	b.set_meta("icon", ic)
	b.pressed.connect(func():
		Audio.play("tap")
		Settings.vibrate(8)
	)
	return b


static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func spacer(expand: bool = true) -> Control:
	var c := Control.new()
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(h, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func card(variation: String = "CardPanel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


static func progress(value: float, color: Color = Palette.GOOD, h: float = 12.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.step = 0.001
	pb.value = value
	pb.show_percentage = false
	pb.custom_minimum_size.y = h
	var fill := ThemeBuilder.box(color, int(h * 0.5), 0, Color.TRANSPARENT, 0, 0)
	pb.add_theme_stylebox_override("fill", fill)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


static func color_dot(c: Color, size: float = 26.0, text: String = "") -> Control:
	var d := LineBadge.new()
	d.color = c
	d.text = text
	d.custom_minimum_size = Vector2(maxf(size, 18.0 + text.length() * size * 0.42), size)
	return d


static func stat_row(title: String, value: String, value_color: Color = Palette.TEXT) -> HBoxContainer:
	var h := hbox(8)
	var t := label(title, 23, Palette.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var v := label(value, 24, value_color, 800)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	return h


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func pop_in(c: Control, from_scale: float = 0.9) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(from_scale, from_scale)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, 0.28)
	tw.tween_property(c, "modulate:a", 1.0, 0.18)


## Big title in the display face.
static func title(text: String, size: int = 40, color: Color = Palette.TEXT) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", ThemeBuilder.display(800))
	return l


## A station-sign plate: coloured bar + label, used for section headings.
static func plate(text: String, color: Color = Palette.ACCENT, size: int = 22) -> Control:
	var p := PanelContainer.new()
	var sb := ThemeBuilder.box(Palette.INK, 10, 0, Color.TRANSPARENT, 14, 6)
	sb.border_width_left = 8
	sb.border_color = color
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l := label(text.to_upper(), size, Palette.CREAM)
	l.add_theme_font_override("font", ThemeBuilder.display(800))
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
