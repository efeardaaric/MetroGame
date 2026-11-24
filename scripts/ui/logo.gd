class_name Logo
extends Control
## Animated logo: three coloured lines converging on an interchange.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var s := minf(size.x / 560.0, size.y / 170.0)
	var lines := [
		[Color("e63946"), [Vector2(-250, 50), Vector2(-120, 50), Vector2(-40, -10), Vector2(0, -10)]],
		[Color("1d72d8"), [Vector2(250, -55), Vector2(110, -55), Vector2(40, -10), Vector2(0, -10)]],
		[Color("2a9d8f"), [Vector2(-180, -60), Vector2(-60, -60), Vector2(0, -10), Vector2(60, 40), Vector2(200, 40)]],
	]
	var grow := clampf(_t / 1.2, 0.0, 1.0)
	grow = 1.0 - pow(1.0 - grow, 3.0)
	for li in lines:
		var col: Color = li[0]
		var raw: Array = li[1]
		var pts := PackedVector2Array()
		for p in raw:
			pts.append(c + p * s)
		var rp := Geo.rounded_path(pts, 30.0 * s, 8)
		var cum := Geo.cumulative(rp)
		var total := cum[cum.size() - 1] * grow
		var vis := PackedVector2Array()
		for i in rp.size():
			if cum[i] <= total:
				vis.append(rp[i])
		if vis.size() >= 2:
			draw_polyline(vis, Color(1, 1, 1, 0.85), 22.0 * s, true)
			draw_polyline(vis, col, 15.0 * s, true)
	# moving dots (trains)
	if grow >= 1.0:
		for k in 3:
			var li: Array = lines[k]
			var pts := PackedVector2Array()
			for p in li[1]:
				pts.append(c + p * s)
			var rp := Geo.rounded_path(pts, 30.0 * s, 8)
			var cum := Geo.cumulative(rp)
			var total := cum[cum.size() - 1]
			var ph := fmod(_t * 0.25 + k * 0.33, 1.0)
			var smp: Array = Geo.sample_polyline(rp, cum, ph * total)
			draw_circle(smp[0], 7.0 * s, Color.WHITE)
	# interchange
	var hub := c + Vector2(0, -10) * s
	draw_circle(hub, 26.0 * s, Color("1f2533"))
	draw_circle(hub, 19.0 * s, Color.WHITE)
	draw_circle(hub, 8.0 * s, Color("1f2533"))
