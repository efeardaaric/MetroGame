class_name Sheet
extends Control
## Bottom sheet with title bar, scrollable body and slide animation.
## Works in portrait and landscape (max width, centred).

signal closed

const MAX_W := 780.0

var panel: PanelContainer
var body: VBoxContainer
var scroll: ScrollContainer
var title_label: Label
var header: HBoxContainer
var dim: ColorRect
var max_height_ratio := 0.62
var dismissable := true
var modal_dim := false
var _closing := false
var side_top := 12.0


static func create(title: String, height_ratio: float = 0.62, with_dim: bool = false) -> Sheet:
	var s := Sheet.new()
	s.max_height_ratio = height_ratio
	s.modal_dim = with_dim
	s._build(title)
	return s


func _build(title: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35 if modal_dim else 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP if modal_dim else Control.MOUSE_FILTER_IGNORE
	dim.gui_input.connect(func(e: InputEvent):
		if dismissable and e is InputEventMouseButton and e.pressed:
			close()
	)
	add_child(dim)
	panel = PanelContainer.new()
	var sb := ThemeBuilder.box(Palette.PANEL, 34, 1, Palette.STROKE, 28, 18, 16)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var pat := Deco.CiniPattern.new()
	pat.band = 170.0
	panel.add_child(pat)
	var v := UI.vbox(14)
	panel.add_child(v)
	# route stripe instead of a plain grabber
	var stripe := Deco.LineStripe.new()
	stripe.thickness = 6.0
	stripe.custom_minimum_size = Vector2(150, 16)
	stripe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stripe)
	header = UI.hbox(10)
	v.add_child(header)
	title_label = UI.title(title, 36)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title_label)
	var close_b := UI.icon_button("close", 64, "FlatButton", Palette.MUTED)
	close_b.pressed.connect(close)
	header.add_child(close_b)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	body = UI.vbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()
	_animate_in()


func set_title(t: String) -> void:
	title_label.text = t


func is_side() -> bool:
	var vs := get_viewport_rect().size
	return vs.x > vs.y * 1.15


func _layout() -> void:
	var vs := get_viewport_rect().size
	var safe := SafeArea.margins(self)
	var sb: StyleBoxFlat = panel.get_theme_stylebox("panel")
	if is_side():
		# landscape: docked side panel on the right
		var w := minf(620.0, vs.x * 0.46)
		var top := maxf(side_top, 12.0 + safe.y)
		panel.size = Vector2(w, vs.y - top - 12.0 - safe.w)
		panel.position = Vector2(vs.x - w - 12.0 - safe.z, top)
		sb.set_corner_radius_all(30)
		sb.content_margin_bottom = 18
		return
	var w2 := minf(vs.x, MAX_W)
	var max_h := vs.y * max_height_ratio
	body.reset_size()
	var content_h := body.get_combined_minimum_size().y + 150.0 + safe.w
	var h := clampf(content_h, 240.0, max_h)
	panel.size = Vector2(w2, h)
	panel.position = Vector2((vs.x - w2) * 0.5, vs.y - h)
	sb.set_corner_radius_all(34)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.content_margin_bottom = 18 + safe.w


func refresh_layout() -> void:
	await get_tree().process_frame
	if is_instance_valid(self):
		_layout()


func _animate_in() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_side():
		var target_x := panel.position.x
		panel.position.x = get_viewport_rect().size.x
		tw.tween_property(panel, "position:x", target_x, 0.26)
	else:
		var target_y := panel.position.y
		panel.position.y = get_viewport_rect().size.y
		tw.tween_property(panel, "position:y", target_y, 0.26)
	if modal_dim:
		var a := dim.color.a
		dim.color.a = 0.0
		create_tween().tween_property(dim, "color:a", a, 0.2)
	Audio.play("swoosh", 1.2, -10.0)


func close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_parallel(true)
	if is_side():
		tw.tween_property(panel, "position:x", get_viewport_rect().size.x, 0.18)
	else:
		tw.tween_property(panel, "position:y", get_viewport_rect().size.y, 0.18)
	tw.tween_property(dim, "color:a", 0.0, 0.18)
	tw.chain().tween_callback(func():
		closed.emit()
		queue_free()
	)
