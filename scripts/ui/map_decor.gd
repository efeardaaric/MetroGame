class_name MapDecor
extends Control
## Screen-space cartographic furniture shown when zoomed out: a compass rose
## and a scale bar in the lower-left corner, fading out as you zoom in.

var g: GameScreen
var _alpha := 0.0
var _last_zoom := -1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_d: float) -> void:
	if g == null or g.world == null:
		return
	var cam := g.world.camera
	var a := clampf(1.0 - (cam.zoom.x / maxf(cam.min_zoom, 0.001) - 1.0) / 1.2, 0.0, 1.0)
	if g.build_mode != "":
		a = 0.0
	if absf(a - _alpha) > 0.01 or absf(cam.zoom.x - _last_zoom) > 0.0005:
		_alpha = a
		_last_zoom = cam.zoom.x
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01 or g == null:
		return
	var vs := get_viewport_rect().size
	var base_y := g.nav.position.y - 40.0
	var safe := SafeArea.margins(self)
	var c := Vector2(70.0 + safe.x, base_y - 70.0)
	var ink := Color(Palette.INK, 0.8 * _alpha)
	var paper := Color(Palette.CREAM, 0.85 * _alpha)
	# compass rose
	draw_circle(c, 52.0, paper)
	draw_arc(c, 52.0, 0.0, TAU, 48, ink, 2.0, true)
	draw_arc(c, 44.0, 0.0, TAU, 48, Color(ink, ink.a * 0.4), 1.0, true)
	for k in 8:
		var ang := -PI * 0.5 + TAU * k / 8.0
		var long := 40.0 if k % 2 == 0 else 24.0
		var tip := c + Vector2.from_angle(ang) * long
		var l := c + Vector2.from_angle(ang - 0.35) * 9.0
		var r := c + Vector2.from_angle(ang + 0.35) * 9.0
		var col := Color(Palette.BAD, 0.9 * _alpha) if k == 0 else ink
		draw_colored_polygon(PackedVector2Array([c, l, tip]), col)
		draw_colored_polygon(PackedVector2Array([c, tip, r]), Color(col, col.a * 0.55))
	var f := ThemeBuilder.display(800)
	var n := "K" if I18n.lang == "tr" else "N"
	var ns := f.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(f, c + Vector2(-ns.x * 0.5, -58), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
	# scale bar
	var z := g.world.camera.zoom.x
	var km := 0.5
	for cand in [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0]:
		if cand * MapLayer.PX * z <= 190.0:
			km = cand
	var w := km * MapLayer.PX * z
	var p := Vector2(c.x + 80.0, c.y + 30.0)
	if p.x + w > vs.x - 20.0:
		return
	draw_rect(Rect2(p + Vector2(-8, -30), Vector2(w + 16, 46)), paper)
	draw_rect(Rect2(p, Vector2(w, 8)), ink, false, 2.0)
	draw_rect(Rect2(p, Vector2(w * 0.5, 8)), ink)
	var lf := ThemeBuilder.font(800)
	var txt := ("%d km" % int(km)) if km >= 1.0 else "500 m"
	draw_string(lf, p + Vector2(0, -8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ink)
