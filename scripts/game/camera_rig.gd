class_name CameraRig
extends Camera2D
## Touch-first camera: one-finger pan with inertia, pinch zoom around the fingers,
## double-tap zoom, mouse wheel / drag on desktop. Emits taps in world space.

signal tapped(world: Vector2, screen: Vector2)
signal long_pressed(world: Vector2, screen: Vector2)
signal zoom_changed(z: float)
signal moved

const TAP_MAX_MS := 280
const TAP_MAX_MOVE := 16.0
const LONG_PRESS_MS := 520
const FRICTION := 5.5

var bounds := Rect2(0, 0, 1000, 1000)
var min_zoom := 0.05
var max_zoom := 1.2
var input_enabled := true

var _touches := {}           # index -> position
var _press_time := 0
var _press_pos := Vector2.ZERO
var _moved := false
var _velocity := Vector2.ZERO
var _last_drag_time := 0
var _pinch_dist := 0.0
var _pinch_center := Vector2.ZERO
var _last_tap_time := 0
var _last_tap_pos := Vector2.ZERO
var _mouse_down := false
var _long_fired := false
var _zoom_tween: Tween
var _last_zoom := 0.0


func _ready() -> void:
	set_process(true)


func setup_bounds(b: Rect2, viewport_size: Vector2) -> void:
	bounds = b
	var fit := minf(viewport_size.x / b.size.x, viewport_size.y / b.size.y)
	min_zoom = fit * 0.85
	max_zoom = 1.4


func screen_to_world(sp: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * sp


func _process(delta: float) -> void:
	if _touches.is_empty() and not _mouse_down and _velocity.length() > 2.0:
		position -= _velocity * delta / zoom.x
		_velocity = _velocity.lerp(Vector2.ZERO, clampf(FRICTION * delta, 0.0, 1.0))
		_clamp()
		moved.emit()
	# long press
	if (_touches.size() == 1 or _mouse_down) and not _moved and not _long_fired and _press_time > 0:
		if Time.get_ticks_msec() - _press_time > LONG_PRESS_MS:
			_long_fired = true
			long_pressed.emit(screen_to_world(_press_pos), _press_pos)
	if absf(zoom.x - _last_zoom) > 0.0001:
		_last_zoom = zoom.x
		zoom_changed.emit(zoom.x)


func handle_input(event: InputEvent) -> bool:
	if not input_enabled:
		return false
	if event is InputEventScreenTouch:
		_on_touch(event)
		return true
	if event is InputEventScreenDrag:
		_on_drag(event)
		return true
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, 1.15)
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, 1.0 / 1.15)
			return true
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_mouse_down = true
				_begin_press(mb.position)
			else:
				_mouse_down = false
				_end_press(mb.position)
			return true
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_down:
		var mm := event as InputEventMouseMotion
		_pan(mm.relative, mm.position)
		return true
	if event is InputEventMagnifyGesture:
		zoom_at(event.position, event.factor)
		return true
	if event is InputEventPanGesture:
		position += event.delta * 12.0 / zoom.x
		_clamp()
		moved.emit()
		return true
	return false


func _begin_press(pos: Vector2) -> void:
	_press_time = Time.get_ticks_msec()
	_press_pos = pos
	_moved = false
	_long_fired = false
	_velocity = Vector2.ZERO


func _end_press(pos: Vector2) -> void:
	var dt := Time.get_ticks_msec() - _press_time
	if not _moved and not _long_fired and dt < TAP_MAX_MS:
		var now := Time.get_ticks_msec()
		if now - _last_tap_time < 320 and pos.distance_to(_last_tap_pos) < 40.0:
			_last_tap_time = 0
			smooth_zoom_at(pos, 1.8)
		else:
			_last_tap_time = now
			_last_tap_pos = pos
			tapped.emit(screen_to_world(pos), pos)
	elif Time.get_ticks_msec() - _last_drag_time > 90:
		_velocity = Vector2.ZERO
	_press_time = 0


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_begin_press(e.position)
		elif _touches.size() == 2:
			_moved = true
			_start_pinch()
	else:
		var was_single := _touches.size() == 1
		_touches.erase(e.index)
		if was_single:
			_end_press(e.position)
		elif _touches.size() == 1:
			# continue panning with the remaining finger without a jump
			_velocity = Vector2.ZERO


func _start_pinch() -> void:
	var pts: Array = _touches.values()
	_pinch_dist = (pts[0] as Vector2).distance_to(pts[1])
	_pinch_center = ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		_touches[e.index] = e.position
	if _touches.size() >= 2:
		_touches[e.index] = e.position
		var pts: Array = _touches.values()
		var d := (pts[0] as Vector2).distance_to(pts[1])
		var c := ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5
		if _pinch_dist > 1.0:
			zoom_at(c, d / _pinch_dist)
		position -= (c - _pinch_center) / zoom.x
		_clamp()
		_pinch_dist = d
		_pinch_center = c
		moved.emit()
		return
	_touches[e.index] = e.position
	_pan(e.relative, e.position)


func _pan(rel: Vector2, pos: Vector2) -> void:
	if not _moved and pos.distance_to(_press_pos) < TAP_MAX_MOVE:
		return
	_moved = true
	position -= rel / zoom.x
	var now := Time.get_ticks_msec()
	var dt := maxf(1.0, float(now - _last_drag_time)) / 1000.0
	_last_drag_time = now
	_velocity = _velocity.lerp(rel / dt, 0.4)
	_clamp()
	moved.emit()


func zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := screen_to_world(screen_pos)
	var z := clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(z, z)
	force_update_scroll()
	var after := screen_to_world(screen_pos)
	position += before - after
	_clamp()
	moved.emit()


func smooth_zoom_at(screen_pos: Vector2, factor: float) -> void:
	var target := clampf(zoom.x * factor, min_zoom, max_zoom)
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	var start := zoom.x
	_zoom_tween.tween_method(func(z: float):
		zoom_at(screen_pos, z / zoom.x), start, target, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func fly_to(world: Vector2, z: float = -1.0, duration: float = 0.6) -> void:
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_velocity = Vector2.ZERO
	_zoom_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(self, "position", world, duration)
	if z > 0.0:
		var tz := clampf(z, min_zoom, max_zoom)
		_zoom_tween.tween_property(self, "zoom", Vector2(tz, tz), duration)
	_zoom_tween.chain().tween_callback(func(): _clamp(); moved.emit())


func _clamp() -> void:
	var vs := get_viewport_rect().size / zoom.x
	var margin := vs * 0.35
	var minp := bounds.position - margin + vs * 0.5
	var maxp := bounds.end + margin - vs * 0.5
	if minp.x > maxp.x:
		position.x = bounds.get_center().x
	else:
		position.x = clampf(position.x, minp.x, maxp.x)
	if minp.y > maxp.y:
		position.y = bounds.get_center().y
	else:
		position.y = clampf(position.y, minp.y, maxp.y)


func reset_touches() -> void:
	_touches.clear()
	_mouse_down = false
	_press_time = 0
