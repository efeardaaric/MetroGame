class_name GrowthLayer
extends Node2D
## New development around busy stations (transit-oriented growth), shown as fresh city blocks.

const PX := MapLayer.PX

var state: GameState


func setup(s: GameState) -> void:
	state = s
	s.net.changed.connect(queue_redraw)
	s.year_ended.connect(func(_r): queue_redraw())
	queue_redraw()


func _draw() -> void:
	if state == null:
		return
	for st in state.net.stations.values():
		var dev: float = st.get("dev", 0.0)
		if dev <= 0.01:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = int(st["id"]) * 7717
		var n := int(dev * 34.0)
		var ang := rng.randf() * PI
		var placed := 0
		var tries := 0
		while placed < n and tries < n * 4:
			tries += 1
			var a := rng.randf() * TAU
			var d := rng.randf_range(0.18, 0.55 + dev * 0.5)
			var c: Vector2 = st["pos"] + Vector2.from_angle(a) * d
			if state.city.is_water(c) or state.city.is_park(c) >= 0:
				continue
			var tall := rng.randf() < dev * 0.5
			var sz := Vector2(rng.randf_range(0.08, 0.16), rng.randf_range(0.06, 0.12)) * (1.3 if tall else 1.0)
			var pts := PackedVector2Array()
			for k in 4:
				var corner := Vector2(sz.x * (1 if k == 1 or k == 2 else -1), sz.y * (1 if k >= 2 else -1)) * 0.5
				pts.append((c + corner.rotated(ang)) * PX)
			var col := Color("cdb48a") if tall else Color("d9c7a3")
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, Color(0.55, 0.45, 0.3, 0.35), 3.0, true)
			placed += 1
