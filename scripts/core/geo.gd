class_name Geo
extends RefCounted
## Small geometry helpers.


static func ellipse(center: Vector2, rx: float, ry: float, rot: float, segments: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		out.append(center + p)
	return out


static func polyline_length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in pts.size() - 1:
		l += pts[i].distance_to(pts[i + 1])
	return l


static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


## Returns position and direction at distance `d` along polyline.
static func sample_polyline(pts: PackedVector2Array, cum: PackedFloat32Array, d: float) -> Array:
	if pts.size() < 2:
		return [pts[0] if pts.size() > 0 else Vector2.ZERO, Vector2.RIGHT]
	var total := cum[cum.size() - 1]
	d = clampf(d, 0.0, total)
	# binary search
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if cum[mid] <= d:
			lo = mid
		else:
			hi = mid
	var seg_len := cum[hi] - cum[lo]
	var t := 0.0 if seg_len <= 0.00001 else (d - cum[lo]) / seg_len
	var a := pts[lo]
	var b := pts[hi]
	return [a.lerp(b, t), (b - a).normalized()]


static func cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(pts.size())
	var acc := 0.0
	for i in pts.size():
		if i > 0:
			acc += pts[i - 1].distance_to(pts[i])
		out[i] = acc
	return out


## Rounds sharp corners of a station-to-station polyline for a nicer "metro map" look.
static func rounded_path(pts: PackedVector2Array, radius: float, steps: int = 5) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var out := PackedVector2Array()
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var a := pts[i - 1]
		var b := pts[i]
		var c := pts[i + 1]
		var la := a.distance_to(b)
		var lc := c.distance_to(b)
		var r: float = min(radius, la * 0.45, lc * 0.45)
		if r <= 0.0001:
			out.append(b)
			continue
		var p0 := b + (a - b).normalized() * r
		var p2 := b + (c - b).normalized() * r
		for s in steps + 1:
			var t := float(s) / steps
			var q0 := p0.lerp(b, t)
			var q1 := b.lerp(p2, t)
			out.append(q0.lerp(q1, t))
	out.append(pts[pts.size() - 1])
	return out


static func fmt_money(m: float) -> String:
	# m is million ₺
	var neg := m < 0.0
	var a: float = abs(m)
	var s: String
	if a >= 1000.0:
		s = "%.2f mr ₺" % (a / 1000.0) if I18n.lang == "tr" else "₺%.2fB" % (a / 1000.0)
	else:
		s = "%.0f mn ₺" % a if I18n.lang == "tr" else "₺%.0fM" % a
	return ("-" if neg else "") + s


static func fmt_int(v: float) -> String:
	var n := int(round(v))
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var sep := "." if I18n.lang == "tr" else ","
	while s.length() > 3:
		out = sep + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out


static func fmt_short(v: float) -> String:
	var a: float = abs(v)
	if a >= 1_000_000.0:
		return ("%.2fM" % (v / 1_000_000.0)).replace(".", "," if I18n.lang == "tr" else ".")
	if a >= 10_000.0:
		return "%dK" % int(round(v / 1000.0))
	return fmt_int(v)
