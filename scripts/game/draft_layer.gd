class_name DraftLayer
extends Node2D
## Visualises the line currently being drawn by the player.

const PX := MapLayer.PX

var nodes: Array = []      # [{pos, sid}]
var eval: Dictionary = {}
var mode := "metro"
var color := Color.WHITE
var zoom := 1.0
var _t := 0.0


func set_draft(n: Array, e: Dictionary, m: String, c: Color) -> void:
	nodes = n
	eval = e
	mode = m
	color = c
	queue_redraw()


func clear() -> void:
	nodes = []
	eval = {}
	queue_redraw()


func _process(delta: float) -> void:
	if not nodes.is_empty():
		_t += delta
		queue_redraw()


func sw(px: float) -> float:
	return px / clampf(zoom, 0.05, 2.0)


func _draw() -> void:
	if nodes.is_empty():
		return
	var segs: Array = eval.get("segments", [])
	var m := TransitModes.get_mode(mode)
	var w := sw(m["width"])
	for i in range(1, nodes.size()):
		var a: Vector2 = nodes[i - 1]["pos"] * PX
		var b: Vector2 = nodes[i]["pos"] * PX
		var ok := true
		var seg: Dictionary = {}
		if i - 1 < segs.size():
			seg = segs[i - 1]
			ok = seg["ok"]
		var c := color if ok else Palette.BAD
		draw_line(a, b, Color(1, 1, 1, 0.9), w + sw(5.0), true)
		draw_line(a, b, c, w, true)
		# marching ants to show it's a draft
		var length := a.distance_to(b)
		var dir := (b - a) / maxf(length, 0.001)
		var dash := sw(10.0)
		var off := fmod(_t * sw(40.0), dash * 2.0)
		var d := off
		while d < length:
			draw_line(a + dir * d, a + dir * minf(d + dash, length), Color(1, 1, 1, 0.55), w * 0.3, true)
			d += dash * 2.0
		# bridges / underwater sections
		if not seg.is_empty():
			for run in seg.get("water_runs", []):
				var p0 := a.lerp(b, run.x)
				var p1 := a.lerp(b, run.y)
				if m["water"] == "bridge":
					var nrm := Vector2(-dir.y, dir.x) * (w * 0.5 + sw(5.0))
					draw_line(p0 + nrm, p1 + nrm, Color(0.2, 0.2, 0.25), sw(3.0), true)
					draw_line(p0 - nrm, p1 - nrm, Color(0.2, 0.2, 0.25), sw(3.0), true)
		# cost label
		if not seg.is_empty():
			var mid := (a + b) * 0.5
			var txt := Geo.fmt_money(seg["cost"]) if ok else "✕"
			_draw_tag(mid, txt, Palette.PANEL if ok else Palette.BAD)
	for i in nodes.size():
		var p: Vector2 = nodes[i]["pos"] * PX
		var r := sw(9.0)
		var existing: bool = nodes[i]["sid"] >= 0
		draw_circle(p, r + sw(3.0), Palette.STATION_STROKE)
		draw_circle(p, r, Color.WHITE if existing else color.lightened(0.5))
		if i == nodes.size() - 1:
			var pr := r * (1.8 + 0.3 * sin(_t * 6.0))
			draw_arc(p, pr, 0, TAU, 28, Palette.ACCENT, sw(3.0), true)


func _draw_tag(pos: Vector2, txt: String, bg: Color) -> void:
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	var f := ThemeBuilder.font(800)
	var fs := 20
	var size := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_set_transform(pos, 0.0, Vector2(inv, inv))
	var rect := Rect2(-size.x * 0.5 - 10, -40, size.x + 20, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.92)
	sb.set_corner_radius_all(15)
	draw_style_box(sb, rect)
	draw_string(f, Vector2(-size.x * 0.5, -18), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
