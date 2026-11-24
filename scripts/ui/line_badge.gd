class_name LineBadge
extends Control
## Rounded colour pill with optional line code (e.g. "M2").

var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()
var text := "":
	set(v):
		text = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := size.y * 0.5
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if text != "":
		var f := ThemeBuilder.font(900)
		var fs := int(size.y * 0.62)
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
		var tc := Color("161616") if lum > 0.62 else Color.WHITE
		draw_string(f, Vector2((size.x - tw) * 0.5, size.y * 0.5 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
