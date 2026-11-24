class_name ThemeBuilder
extends RefCounted
## Builds the global UI theme in code (fonts, buttons, panels, sliders...).

static var _font_cache := {}


static func font(weight: int = 600) -> Font:
	if _font_cache.has(weight):
		return _font_cache[weight]
	var base: FontFile = load("res://assets/fonts/Nunito.ttf")
	var fv := FontVariation.new()
	fv.base_font = base
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	_font_cache[weight] = fv
	return fv


static func box(color: Color, radius: int = 18, border: int = 0, border_color: Color = Color.TRANSPARENT,
		pad_h: int = 16, pad_v: int = 10, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = border_color
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	s.anti_aliasing_size = 1.0
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.4)
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font(650)
	t.default_font_size = 26

	# Label
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_constant("line_spacing", "Label", 2)

	# Buttons
	var normal := box(Palette.PANEL_2, 20, 0, Color.TRANSPARENT, 22, 14)
	var hover := box(Palette.PANEL_3, 20, 0, Color.TRANSPARENT, 22, 14)
	var pressed := box(Palette.PANEL_3.darkened(0.15), 20, 0, Color.TRANSPARENT, 22, 14)
	var disabled := box(Palette.PANEL_2.darkened(0.3), 20, 0, Color.TRANSPARENT, 22, 14)
	var focus := StyleBoxEmpty.new()
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.ACCENT)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("font_hover_pressed_color", "Button", Palette.ACCENT)
	t.set_font("font", "Button", font(750))
	t.set_font_size("font_size", "Button", 26)
	t.set_constant("h_separation", "Button", 10)

	# Accent button variation
	t.add_type("AccentButton")
	t.set_type_variation("AccentButton", "Button")
	t.set_stylebox("normal", "AccentButton", box(Palette.ACCENT, 20, 0, Color.TRANSPARENT, 26, 16))
	t.set_stylebox("hover", "AccentButton", box(Palette.ACCENT.lightened(0.1), 20, 0, Color.TRANSPARENT, 26, 16))
	t.set_stylebox("pressed", "AccentButton", box(Palette.ACCENT_DARK, 20, 0, Color.TRANSPARENT, 26, 16))
	t.set_stylebox("hover_pressed", "AccentButton", box(Palette.ACCENT_DARK, 20, 0, Color.TRANSPARENT, 26, 16))
	t.set_stylebox("disabled", "AccentButton", box(Palette.ACCENT.darkened(0.55), 20, 0, Color.TRANSPARENT, 26, 16))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "AccentButton", Color("1b1405"))
	t.set_color("font_disabled_color", "AccentButton", Color(0, 0, 0, 0.45))
	t.set_font("font", "AccentButton", font(850))

	# Danger button
	t.add_type("DangerButton")
	t.set_type_variation("DangerButton", "Button")
	t.set_stylebox("normal", "DangerButton", box(Palette.BAD.darkened(0.25), 20, 0, Color.TRANSPARENT, 22, 14))
	t.set_stylebox("hover", "DangerButton", box(Palette.BAD.darkened(0.1), 20, 0, Color.TRANSPARENT, 22, 14))
	t.set_stylebox("pressed", "DangerButton", box(Palette.BAD.darkened(0.4), 20, 0, Color.TRANSPARENT, 22, 14))
	t.set_stylebox("hover_pressed", "DangerButton", box(Palette.BAD.darkened(0.4), 20, 0, Color.TRANSPARENT, 22, 14))

	# Flat / ghost button
	t.add_type("FlatButton")
	t.set_type_variation("FlatButton", "Button")
	var empty := box(Color(1, 1, 1, 0.0), 18, 0, Color.TRANSPARENT, 12, 10)
	t.set_stylebox("normal", "FlatButton", empty)
	t.set_stylebox("hover", "FlatButton", box(Color(1, 1, 1, 0.06), 18, 0, Color.TRANSPARENT, 12, 10))
	t.set_stylebox("pressed", "FlatButton", box(Color(1, 1, 1, 0.12), 18, 0, Color.TRANSPARENT, 12, 10))
	t.set_stylebox("hover_pressed", "FlatButton", box(Color(1, 1, 1, 0.12), 18, 0, Color.TRANSPARENT, 12, 10))

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(Palette.PANEL, 28, 1, Palette.STROKE, 24, 20, 10))
	t.set_stylebox("panel", "Panel", box(Palette.PANEL, 28, 1, Palette.STROKE, 0, 0, 10))
	t.add_type("CardPanel")
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(Palette.PANEL_2, 22, 0, Color.TRANSPARENT, 20, 16))
	t.add_type("ChipPanel")
	t.set_type_variation("ChipPanel", "PanelContainer")
	t.set_stylebox("panel", "ChipPanel", box(Color(0.1, 0.13, 0.19, 0.92), 22, 1, Palette.STROKE, 14, 8, 6))

	# Progress bar
	t.set_stylebox("background", "ProgressBar", box(Color(1, 1, 1, 0.08), 8, 0, Color.TRANSPARENT, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(Palette.GOOD, 8, 0, Color.TRANSPARENT, 0, 0))
	t.set_constant("outline_size", "ProgressBar", 0)
	t.set_color("font_color", "ProgressBar", Color.TRANSPARENT)

	# Sliders
	t.set_stylebox("slider", "HSlider", box(Color(1, 1, 1, 0.12), 6, 0, Color.TRANSPARENT, 0, 4))
	t.set_stylebox("grabber_area", "HSlider", box(Palette.ACCENT, 6, 0, Color.TRANSPARENT, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(Palette.ACCENT, 6, 0, Color.TRANSPARENT, 0, 4))
	var grab := _circle_texture(34, Color.WHITE)
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", grab)

	# CheckButton (toggle)
	t.set_icon("checked", "CheckButton", _toggle_texture(true))
	t.set_icon("unchecked", "CheckButton", _toggle_texture(false))
	t.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())

	# Scroll
	var sb := box(Color(1, 1, 1, 0.0), 4, 0, Color.TRANSPARENT, 0, 0)
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", box(Color(1, 1, 1, 0.15), 4, 0, Color.TRANSPARENT, 3, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(1, 1, 1, 0.25), 4, 0, Color.TRANSPARENT, 3, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Color(1, 1, 1, 0.3), 4, 0, Color.TRANSPARENT, 3, 0))
	t.set_stylebox("scroll", "HScrollBar", sb)
	t.set_stylebox("grabber", "HScrollBar", box(Color(1, 1, 1, 0.15), 4, 0, Color.TRANSPARENT, 0, 3))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	# Separators
	t.set_stylebox("separator", "HSeparator", box(Color(1, 1, 1, 0.07), 1, 0, Color.TRANSPARENT, 0, 1))
	t.set_constant("separation", "HSeparator", 18)

	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", box(Palette.PANEL_3, 12, 0, Color.TRANSPARENT, 12, 8))
	return t


static func _circle_texture(size: int, c: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - 1.0 - d, 0.0, 1.0)
			var shade := clampf(r - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, max(a, shade * 0.0)))
	return ImageTexture.create_from_image(img)


static func _toggle_texture(on: bool) -> ImageTexture:
	var w := 76
	var h := 42
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := Palette.GOOD if on else Color("3a4660")
	var r := h * 0.5
	for y in h:
		for x in w:
			var px := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(px.x, r, w - r)
			var d := px.distance_to(Vector2(cx, r))
			var a := clampf(r - d, 0.0, 1.0)
			var col := track
			var knob_c := Vector2(w - r if on else r, r)
			var kd := px.distance_to(knob_c)
			var ka := clampf(r - 5.0 - kd, 0.0, 1.0)
			col = col.lerp(Color.WHITE, ka)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
