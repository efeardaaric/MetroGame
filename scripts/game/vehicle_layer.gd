class_name VehicleLayer
extends Node2D
## Animated vehicles running along line paths (purely visual).

const PX := MapLayer.PX
const VIS_MIN_PER_SEC := 1.6 # simulated minutes per real second at 1x

var net: TransitNetwork
var netlayer: NetworkLayer
var demand: DemandModel
var speed := 1.0
var t := 0.0
var zoom := 1.0
var light_points: Array = []  # [pos, dir] collected for NightLights


func setup(n: TransitNetwork, nl: NetworkLayer, d: DemandModel) -> void:
	net = n
	netlayer = nl
	demand = d


func _process(delta: float) -> void:
	t += delta * speed * VIS_MIN_PER_SEC
	if speed > 0.0 or Engine.get_frames_drawn() % 10 == 0:
		queue_redraw()


func _draw() -> void:
	if net == null:
		return
	light_points.clear()
	var any_sel := netlayer.selected_line >= 0
	var inv := 1.0 / clampf(zoom, 0.05, 2.0)
	for lid in netlayer.paths.keys():
		if not net.lines.has(lid):
			continue
		var l: Dictionary = net.lines[lid]
		var n: int = l["vehicles"]
		if l.has("con") and int(l["con"]["lo"]) < 0:
			continue
		if l.has("incident"):
			n = int(n * float(l["incident"]["cap"]))
		if n <= 0:
			continue
		var p: PackedVector2Array = netlayer.paths[lid]
		var cum: PackedFloat32Array = netlayer.cums[lid]
		var total := cum[cum.size() - 1]
		if total <= 1.0:
			continue
		var m := TransitModes.get_mode(l["mode"])
		var loop: bool = l.get("loop", false)
		var cycle := net.line_cycle_min(l)
		var col := net.line_color(l)
		var alpha := 0.3 if (any_sel and lid != netlayer.selected_line) else 1.0
		var load: float = demand.line_load.get(lid, 0.0) if demand else 0.0
		var length := float(m["width"]) * 2.6 * inv
		var width := float(m["width"]) * 1.25 * inv
		var shown := mini(n, 60)
		for i in shown:
			var phase := fmod(t / cycle + float(i) / n, 1.0)
			var d: float
			var forward := true
			if loop:
				d = phase * total
			else:
				# ping-pong with short dwell at the ends
				var ph := phase * 2.0
				if ph < 1.0:
					d = _ease_ends(ph) * total
				else:
					d = (1.0 - _ease_ends(ph - 1.0)) * total
					forward = false
			var s: Array = Geo.sample_polyline(p, cum, d)
			var pos: Vector2 = s[0]
			var dir: Vector2 = s[1] if forward else -s[1]
			# lateral offset so opposite directions don't overlap
			var nrm := Vector2(-dir.y, dir.x)
			pos += nrm * width * 0.55
			light_points.append([pos, dir])
			draw_set_transform(pos, dir.angle(), Vector2.ONE)
			if l["mode"] == "ferry":
				_draw_boat(length * 1.2, width * 1.4, col, alpha)
			else:
				var body := Rect2(-length * 0.5, -width * 0.5, length, width)
				draw_rect(body.grow(1.6 * inv), Color(0.1, 0.1, 0.14, 0.75 * alpha))
				draw_rect(body, Color(col.lightened(0.15), alpha))
				# load indicator (window strip)
				var fill := clampf(load, 0.0, 1.0)
				var strip := Rect2(-length * 0.42, -width * 0.18, length * 0.84 * fill, width * 0.36)
				var lc := Palette.GOOD if load < 0.8 else (Palette.WARN if load < 1.0 else Palette.BAD)
				draw_rect(strip, Color(lc.lightened(0.3), 0.9 * alpha))
				draw_rect(Rect2(length * 0.38, -width * 0.5, length * 0.12, width), Color(1, 1, 1, 0.55 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ease_ends(x: float) -> float:
	# small dwell at terminals: clamp 4% at each end
	return clampf((x - 0.04) / 0.92, 0.0, 1.0)


func _draw_boat(length: float, width: float, col: Color, alpha: float) -> void:
	# wake
	var wake := PackedVector2Array([Vector2(-length * 0.45, -width * 0.35), Vector2(-length * 2.6, -width * 1.6),
		Vector2(-length * 2.6, width * 1.6), Vector2(-length * 0.45, width * 0.35)])
	draw_colored_polygon(wake, Color(1, 1, 1, 0.22 * alpha))
	var pts := PackedVector2Array([
		Vector2(length * 0.55, 0), Vector2(length * 0.25, -width * 0.5), Vector2(-length * 0.5, -width * 0.5),
		Vector2(-length * 0.5, width * 0.5), Vector2(length * 0.25, width * 0.5)])
	draw_colored_polygon(pts, Color(1, 1, 1, alpha))
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(q * 0.62)
	draw_colored_polygon(inner, Color(col, alpha))
