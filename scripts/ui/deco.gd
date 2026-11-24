class_name Deco
extends RefCounted
## Signature decorative elements of the "Bilet & Tabela" visual identity.


## Geometric İznik-style star lattice (original procedural pattern). Fades out downward.
class CiniPattern:
	extends Control
	var color := Color(0.96, 0.92, 0.85, 0.07)
	var cell := 56.0
	var band := 150.0       # visible height before fading out (0 = full)
	var radius := 30.0      # clip corner radius of the host panel

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var h := size.y if band <= 0.0 else minf(size.y, band)
		var cols := int(ceil(size.x / cell)) + 1
		var rows := int(ceil(h / cell)) + 1
		for r in rows:
			var fade := 1.0 if band <= 0.0 else clampf(1.0 - (r * cell) / h, 0.0, 1.0)
			if fade <= 0.02:
				continue
			var c := Color(color, color.a * fade)
			for q in cols:
				var ctr := Vector2(q * cell, r * cell)
				_star(ctr, cell * 0.42, c)
				_star(ctr + Vector2(cell * 0.5, cell * 0.5), cell * 0.16, Color(c, c.a * 0.8))

	func _star(ctr: Vector2, r: float, c: Color) -> void:
		# eight-pointed star made of two interlaced squares
		var a := PackedVector2Array()
		var b := PackedVector2Array()
		for k in 5:
			a.append(ctr + Vector2.from_angle(PI / 4.0 + k * PI / 2.0) * r)
			b.append(ctr + Vector2.from_angle(k * PI / 2.0) * r)
		draw_polyline(a, c, 1.6, true)
		draw_polyline(b, c, 1.6, true)
		draw_arc(ctr, r * 0.38, 0, TAU, 16, c, 1.4, true)


## A route bar: coloured line segments joined by white station dots.
class LineStripe:
	extends Control
	var colors: Array = Palette.STRIPES
	var thickness := 7.0
	var dots := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if custom_minimum_size.y < thickness + 8.0:
			custom_minimum_size.y = thickness + 8.0
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := size.y * 0.5
		var n := colors.size()
		var w := size.x / n
		for i in n:
			var x0 := i * w + (thickness * 0.5 if i == 0 else 0.0)
			var x1 := (i + 1) * w - (thickness * 0.5 if i == n - 1 else 0.0)
			draw_line(Vector2(x0, y), Vector2(x1, y), colors[i], thickness, true)
		draw_circle(Vector2(thickness * 0.5, y), thickness * 0.5, colors[0])
		draw_circle(Vector2(size.x - thickness * 0.5, y), thickness * 0.5, colors[n - 1])
		if dots:
			for i in range(1, n):
				var p := Vector2(i * w, y)
				draw_circle(p, thickness * 0.95, Palette.INK)
				draw_circle(p, thickness * 0.62, Color.WHITE)


## Draws a perforated ticket stub on the left of its parent button.
class TicketStub:
	extends Control
	var stub_color := Palette.BAD
	var stub_w := 92.0
	var notch_color := Palette.BG

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func _draw() -> void:
		var lip := 7.0
		var h := size.y - lip
		var sb := StyleBoxFlat.new()
		sb.bg_color = stub_color
		sb.corner_radius_top_left = 16
		sb.corner_radius_bottom_left = 16
		sb.anti_aliasing = true
		draw_style_box(sb, Rect2(0, 0, stub_w, h))
		# perforation
		var x := stub_w
		var yy := 10.0
		while yy < h - 8.0:
			draw_circle(Vector2(x, yy), 2.2, Color(Palette.INK, 0.35))
			yy += 9.0
		# notches
		draw_circle(Vector2(x, 0), 9.0, notch_color)
		draw_circle(Vector2(x, h), 9.0, notch_color)


## Creates a cream "ticket" button with a coloured, perforated stub carrying an icon.
static func ticket_button(text: String, icon_kind: String, stub: Color, height: float = 96.0) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = height
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var face := Palette.CREAM
	var lip := Palette.CREAM_DARK.darkened(0.25)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var pressed: bool = st.contains("pressed")
		var k := ThemeBuilder.key3d(face.lightened(0.04) if st == "hover" else face, lip, pressed, 16, 0, 12)
		k.content_margin_left = 92 + 28
		b.add_theme_stylebox_override(st, k)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Palette.INK)
	b.add_theme_font_override("font", ThemeBuilder.display(800))
	b.add_theme_font_size_override("font_size", 30)
	var deco := TicketStub.new()
	deco.stub_color = stub
	b.add_child(deco)
	var ic := Icon.make(icon_kind, 40, Palette.CREAM)
	b.add_child(ic)
	var place := func(): ic.position = Vector2((92.0 - 40.0) * 0.5, (b.size.y - 7.0 - 40.0) * 0.5)
	b.resized.connect(place)
	b.button_down.connect(func():
		deco.position.y = 5
		ic.position.y += 5
	)
	b.button_up.connect(func():
		deco.position.y = 0
		place.call()
	)
	b.pressed.connect(func():
		Audio.play("tap")
		Settings.vibrate(8)
	)
	return b
