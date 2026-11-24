class_name PosterView
extends Control
## Shareable network poster (1080×1350): schematic map in the "Bilet & Tabela" style + stats.

var state: GameState


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Palette.CREAM)
	# header band
	draw_rect(Rect2(0, 0, w, 190), Palette.INK)
	var f := ThemeBuilder.display(800)
	var city := I18n.t(state.city.data["name_key"]).to_upper()
	draw_string(f, Vector2(60, 115), city, HORIZONTAL_ALIGNMENT_LEFT, -1, 86, Palette.CREAM)
	draw_string(ThemeBuilder.font(800), Vector2(64, 160), I18n.t("poster_subtitle") % state.year, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.ACCENT)
	# stripe
	var sw := w / 4.0
	for i in 4:
		draw_rect(Rect2(i * sw, 190, sw, 14), Palette.STRIPES[i])
	# map area
	var area := Rect2(50, 250, w - 100, h - 520)
	var pts := []
	for s in state.net.stations.values():
		pts.append(s["pos"])
	if pts.is_empty():
		return
	var bb := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		bb = bb.expand(p)
	bb = bb.grow(maxf(1.5, maxf(bb.size.x, bb.size.y) * 0.08))
	var sc := minf(area.size.x / bb.size.x, area.size.y / bb.size.y)
	var off := area.position + (area.size - bb.size * sc) * 0.5 - bb.position * sc
	var xf := func(p: Vector2) -> Vector2: return off + p * sc
	# faint water silhouette
	for wp in state.city.water_polys:
		var poly := PackedVector2Array()
		for q in wp:
			poly.append(xf.call(q))
		var clipped := Geometry2D.intersect_polygons(poly, PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]))
		for c in clipped:
			if not Geometry2D.is_polygon_clockwise(c) or true:
				var idx := Geometry2D.triangulate_polygon(c)
				if idx.size() >= 3:
					var cols := PackedColorArray()
					cols.resize(c.size())
					cols.fill(Color("cfe3ee"))
					RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, c, cols)
	# octilinear lines
	for l in state.net.lines.values():
		var col := state.net.line_color(l)
		var line_pts := PackedVector2Array()
		var st: Array = l["stations"]
		for i in st.size():
			var p: Vector2 = xf.call(state.net.stations[st[i]]["pos"])
			if i > 0:
				var bend := NetworkLayer.octi(line_pts[line_pts.size() - 1], p)
				line_pts.append(bend)
			line_pts.append(p)
		if l.get("loop", false):
			line_pts.append(NetworkLayer.octi(line_pts[line_pts.size() - 1], line_pts[0]))
			line_pts.append(line_pts[0])
		var rp := Geo.rounded_path(line_pts, 22.0, 6)
		draw_polyline(rp, Color.WHITE, 22.0, true)
		draw_polyline(rp, col, 14.0, true)
	for s in state.net.stations.values():
		var p: Vector2 = xf.call(s["pos"])
		var hub: bool = s["lines"].size() > 1
		draw_circle(p, 13.0 if hub else 9.0, Palette.INK)
		draw_circle(p, 9.0 if hub else 6.0, Color.WHITE)
	# stats band
	var y := h - 250.0
	draw_rect(Rect2(0, y, w, 250), Palette.INK)
	var stats := [
		[Geo.fmt_short(state.riders), I18n.t("riders_day")],
		[str(state.net.lines.size()), I18n.t("lines_count")],
		[str(state.net.stations.size()), I18n.t("stations_count")],
		["%d%%" % int(state.demand.satisfaction), I18n.t("satisfaction")],
	]
	var cw := w / 4.0
	for i in 4:
		var x := i * cw
		draw_string(ThemeBuilder.led(850), Vector2(x, y + 110), stats[i][0], HORIZONTAL_ALIGNMENT_CENTER, cw, 64, Palette.LED)
		draw_string(ThemeBuilder.font(700), Vector2(x, y + 160), stats[i][1], HORIZONTAL_ALIGNMENT_CENTER, cw, 24, Palette.MUTED)
	draw_string(ThemeBuilder.display(800), Vector2(0, h - 34), "METRO TYCOON: TÜRKİYE", HORIZONTAL_ALIGNMENT_CENTER, w, 34, Palette.ACCENT)


## Renders the poster off-screen and saves it as PNG. Returns the user:// path.
static func render_to_file(host: Node, st: GameState) -> String:
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 1350)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.transparent_bg = false
	var pv := PosterView.new()
	pv.state = st
	pv.size = Vector2(1080, 1350)
	vp.add_child(pv)
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var path := "user://raya_%s_%d.png" % [st.city_id, st.year]
	img.save_png(path)
	vp.queue_free()
	return path
