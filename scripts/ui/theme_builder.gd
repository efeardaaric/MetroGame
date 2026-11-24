class_name ThemeBuilder
extends RefCounted
## Builds the global UI theme in code (fonts, buttons, panels, sliders...).

static var _font_cache := {}


static func font(weight: int = 600) -> Font:
	if _font_cache.has(weight):
		return _font_cache[weight]
	var base: FontFile = load("res://assets/fonts/Nunito.ttf")
	if base.fallbacks.is_empty() and ResourceLoader.exists("res://assets/fonts/NotoEmoji.ttf"):
		base.fallbacks = [load("res://assets/fonts/NotoEmoji.ttf")]
	var fv := FontVariation.new()
	fv.base_font = base
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	_font_cache[weight] = fv
	return fv


static var _display_cache := {}
static var _led_cache := {}


## Characterful display face for titles and big numbers (Bricolage Grotesque, OFL).
static func display(weight: int = 800) -> Font:
	weight = clampi(weight, 200, 800)
	if _display_cache.has(weight):
		return _display_cache[weight]
	var base: FontFile = load("res://assets/fonts/BricolageGrotesque.ttf")
	if base.fallbacks.is_empty():
		base.fallbacks = [load("res://assets/fonts/Nunito.ttf")]
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight, ts.name_to_tag("opsz"): 48, ts.name_to_tag("wdth"): 92}
	_display_cache[weight] = fv
	return fv


## Dot-matrix "departure board" face for the HUD (Doto, OFL).
static func led(weight: int = 800) -> Font:
	if _led_cache.has(weight):
		return _led_cache[weight]
	var base: FontFile = load("res://assets/fonts/Doto.ttf")
	if base.fallbacks.is_empty():
		base.fallbacks = [load("res://assets/fonts/Nunito.ttf")]
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight, ts.name_to_tag("ROND"): 100}
	fv.spacing_glyph = 1
	_led_cache[weight] = fv
	return fv


## Tactile key: a coloured face sitting on a darker lip; pressed sinks into the lip.
static func key3d(face: Color, lip: Color, pressed: bool = false, radius: int = 18, pad_h: int = 22, pad_v: int = 12) -> StyleBoxFlat:
	var s := box(face, radius, 0, Color.TRANSPARENT, pad_h, pad_v)
	s.border_color = lip
	s.border_width_bottom = 2 if pressed else 7
	s.content_margin_top = pad_v + (5 if pressed else 0)
	s.content_margin_bottom = pad_v - (5 if pressed else 0) + 2
	s.border_blend = false
	return s


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

	# Buttons — tactile keys
	var face := Palette.PANEL_3
	var lip := Palette.PANEL_3.darkened(0.45)
	t.set_stylebox("normal", "Button", key3d(face, lip))
	t.set_stylebox("hover", "Button", key3d(face.lightened(0.06), lip))
	t.set_stylebox("pressed", "Button", key3d(face.darkened(0.08), lip, true))
	t.set_stylebox("hover_pressed", "Button", key3d(face.darkened(0.08), lip, true))
	t.set_stylebox("disabled", "Button", key3d(Palette.PANEL_2, Palette.PANEL_2.darkened(0.3)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.ACCENT)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("font_hover_pressed_color", "Button", Palette.ACCENT)
	t.set_font("font", "Button", display(700))
	t.set_font_size("font_size", "Button", 26)
	t.set_constant("h_separation", "Button", 10)

	# Accent key: ferry yellow
	t.add_type("AccentButton")
	t.set_type_variation("AccentButton", "Button")
	t.set_stylebox("normal", "AccentButton", key3d(Palette.ACCENT, Palette.ACCENT_DARK))
	t.set_stylebox("hover", "AccentButton", key3d(Palette.ACCENT.lightened(0.08), Palette.ACCENT_DARK))
	t.set_stylebox("pressed", "AccentButton", key3d(Palette.ACCENT.darkened(0.05), Palette.ACCENT_DARK, true))
	t.set_stylebox("hover_pressed", "AccentButton", key3d(Palette.ACCENT.darkened(0.05), Palette.ACCENT_DARK, true))
	t.set_stylebox("disabled", "AccentButton", key3d(Palette.ACCENT.darkened(0.55), Palette.ACCENT.darkened(0.7)))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "AccentButton", Palette.INK)
	t.set_color("font_disabled_color", "AccentButton", Color(0, 0, 0, 0.45))
	t.set_font("font", "AccentButton", display(800))

	# Danger key: tram red
	t.add_type("DangerButton")
	t.set_type_variation("DangerButton", "Button")
	var red := Palette.BAD.darkened(0.1)
	t.set_stylebox("normal", "DangerButton", key3d(red, red.darkened(0.45)))
	t.set_stylebox("hover", "DangerButton", key3d(red.lightened(0.08), red.darkened(0.45)))
	t.set_stylebox("pressed", "DangerButton", key3d(red.darkened(0.08), red.darkened(0.45), true))
	t.set_stylebox("hover_pressed", "DangerButton", key3d(red.darkened(0.08), red.darkened(0.45), true))
	t.set_stylebox("disabled", "DangerButton", key3d(red.darkened(0.5), red.darkened(0.65)))

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
