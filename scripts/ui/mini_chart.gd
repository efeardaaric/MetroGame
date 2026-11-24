class_name MiniChart
extends Control
## Small bar / line chart for history data.

var values: Array = []
var labels: Array = []
var color := Palette.GOOD
var kind := "bar" # or "line"
var formatter: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y < 10:
		custom_minimum_size.y = 200


func set_data(v: Array, l: Array, c: Color, k: String = "bar") -> void:
	values = v
	labels = l
	color = c
	kind = k
	queue_redraw()


func _draw() -> void:
	var f := ThemeBuilder.font(700)
	var pad_b := 30.0
	var pad_t := 30.0
	var h := size.y - pad_b - pad_t
	var w := size.x
	draw_line(Vector2(0, pad_t + h), Vector2(w, pad_t + h), Color(1, 1, 1, 0.1), 2.0)
	if values.is_empty():
		draw_string(f, Vector2(0, pad_t + h * 0.5), "—", HORIZONTAL_ALIGNMENT_CENTER, w, 24, Palette.FAINT)
		return
	var vmax := 0.0
	var vmin := 0.0
	for v in values:
		vmax = maxf(vmax, v)
		vmin = minf(vmin, v)
	var span := maxf(vmax - vmin, 0.0001)
	var n := values.size()
	var step := minf(w / n, 60.0)
	var zero_y := pad_t + h * (vmax / span)
	if kind == "bar":
		for i in n:
			var v: float = values[i]
			var bh := h * absf(v) / span
			var x := i * step + step * 0.18
			var y := zero_y - bh if v >= 0 else zero_y
			var c := color if v >= 0 else Palette.BAD
			var sb := StyleBoxFlat.new()
			sb.bg_color = c if i == n - 1 else Color(c, 0.65)
			sb.set_corner_radius_all(int(minf(6.0, step * 0.3)))
			draw_style_box(sb, Rect2(x, y, step * 0.64, maxf(bh, 2.0)))
	else:
		var pts := PackedVector2Array()
		for i in n:
			var v: float = values[i]
			pts.append(Vector2(i * step + step * 0.5, zero_y - h * v / span))
		var fill := pts.duplicate()
		fill.append(Vector2(pts[pts.size() - 1].x, zero_y))
		fill.append(Vector2(pts[0].x, zero_y))
		if pts.size() >= 2:
			draw_colored_polygon(fill, Color(color, 0.15))
			draw_polyline(pts, color, 4.0, true)
		draw_circle(pts[pts.size() - 1], 7.0, color)
	# labels: first, middle, last
	for i in [0, n / 2, n - 1]:
		if i < labels.size():
			draw_string(f, Vector2(i * step, size.y - 4), str(labels[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.FAINT)
	if formatter.is_valid():
		draw_string(f, Vector2(0, 20), formatter.call(vmax), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.MUTED)
