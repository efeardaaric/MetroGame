class_name Toast
extends Control
## Stacked, auto-dismissing notifications near the top of the screen.

var _box: VBoxContainer
var top_offset := 260.0
var bottom_offset := 0.0 # when > 0 toasts stack upwards from this distance above the bottom


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = UI.vbox(10)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vs := get_viewport_rect().size
	var w := minf(vs.x - 40.0, 640.0)
	_box.custom_minimum_size.x = w
	_box.reset_size()
	if bottom_offset > 0.0:
		_box.position = Vector2((vs.x - w) * 0.5, vs.y - bottom_offset - _box.size.y)
	else:
		_box.position = Vector2((vs.x - w) * 0.5, top_offset + SafeArea.margins(self).y)


func _process(_d: float) -> void:
	if bottom_offset > 0.0 and _box.get_child_count() > 0:
		_layout()


func show_msg(text: String, kind: String = "info", seconds: float = 2.6) -> void:
	var col := Palette.INFO
	var ic := "info"
	match kind:
		"error":
			col = Palette.BAD
			ic = "warning"
		"good":
			col = Palette.GOOD
			ic = "check"
		"money":
			col = Palette.ACCENT
			ic = "coin"
		"star":
			col = Palette.ACCENT
			ic = "star"
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(0.08, 0.1, 0.15, 0.96), 24, 2, Color(col, 0.6), 20, 14, 10))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(14)
	h.add_child(Icon.make(ic, 34, col))
	var l := UI.wrap_label(text, 25, Palette.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	p.add_child(h)
	_box.add_child(p)
	while _box.get_child_count() > 3:
		var old := _box.get_child(0)
		_box.remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)
