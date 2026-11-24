class_name Modal
extends Control
## Centred dialog with dim background and pop-in animation.

signal closed

var panel: PanelContainer
var body: VBoxContainer
var dismissable := true
var _closing := false


static func create(title: String = "", width: float = 640.0, dismiss: bool = true) -> Modal:
	var m := Modal.new()
	m.dismissable = dismiss
	m._build(title, width)
	return m


func _build(title: String, width: float) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if dismissable and e is InputEventMouseButton and e.pressed:
			close()
	)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeBuilder.box(Palette.PANEL, 34, 1, Palette.STROKE, 32, 28, 24))
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	body = UI.vbox(18)
	panel.add_child(body)
	if title != "":
		var t := UI.label(title, 38, Palette.TEXT, 900)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(t)


func _ready() -> void:
	var vs := get_viewport_rect().size
	panel.custom_minimum_size.x = minf(panel.custom_minimum_size.x, vs.x - 40.0)
	await get_tree().process_frame
	UI.pop_in(panel)


func close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(func():
		closed.emit()
		queue_free()
	)


static func confirm(parent: Node, text: String, on_yes: Callable, danger: bool = true) -> Modal:
	var m := Modal.create("", 600.0)
	var l := UI.wrap_label(text, 28, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	var row := UI.hbox(14)
	var no := UI.button(I18n.t("cancel"))
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(m.close)
	var yes := UI.button(I18n.t("yes"), "DangerButton" if danger else "AccentButton")
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func():
		m.close()
		on_yes.call()
	)
	row.add_child(no)
	row.add_child(yes)
	m.body.add_child(row)
	parent.add_child(m)
	return m
