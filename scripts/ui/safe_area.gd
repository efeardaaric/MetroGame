class_name SafeArea
extends RefCounted
## Converts the device safe area (notch / home indicator) to viewport-space margins.


## Returns Vector4(left, top, right, bottom) in viewport coordinates.
static func margins(node: CanvasItem) -> Vector4:
	var vp := node.get_viewport_rect().size
	if not OS.has_feature("mobile"):
		return Vector4(0, 0, 0, 0)
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0 or win.y <= 0:
		return Vector4(0, 0, 0, 0)
	var sx := vp.x / win.x
	var sy := vp.y / win.y
	var l := maxf(0.0, safe.position.x) * sx
	var t := maxf(0.0, safe.position.y) * sy
	var r := maxf(0.0, win.x - safe.end.x) * sx
	var b := maxf(0.0, win.y - safe.end.y) * sy
	return Vector4(l, t, r, b)
