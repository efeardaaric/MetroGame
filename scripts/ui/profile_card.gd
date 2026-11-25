class_name ProfileCard
extends RefCounted
## Cıvıltı profile: portrait, bio, follower count and the person's latest posts.


class BigFace:
	extends Control
	var who := {}
	var _look := {}
	var _t := 0.0
	func _process(d: float) -> void:
		_t += d
		queue_redraw()
	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		var kind := str(who.get("kind", "citizen"))
		if kind == "official":
			Logo.draw_token(self, c, r * 0.95, _t)
			return
		if kind == "news":
			draw_circle(c, r, Color(str(who.get("color", "457b9d"))))
			var f := ThemeBuilder.display(800)
			var parts: PackedStringArray = str(who["name"]).split(" ")
			var ini := (parts[0].substr(0, 1) + (parts[1].substr(0, 1) if parts.size() > 1 else "")).to_upper()
			var fs := int(r * 0.9)
			var tw := f.get_string_size(ini, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(f, c + Vector2(-tw * 0.5, fs * 0.36), ini, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
			return
		if _look.is_empty():
			_look = Face.look_of(who)
		Face.draw(self, c, r, _look, fmod(_t, 3.7) > 3.58)


static func bio_of(who: Dictionary, st: GameState) -> String:
	var idx := 0 if I18n.lang == "tr" else 1
	if who.has("cast"):
		return SocialTemplates.CAST[str(who["cast"])]["bio"][idx]
	match str(who.get("kind", "citizen")):
		"news":
			return ["Şehrin gündemi, dakikası dakikasına. Haber ve ihbar için DM.", "The city's news, minute by minute. Tips via DM."][idx]
		"official":
			return ["Raylı sistem işletmesinin resmî hesabıdır. Sefer ve arıza duyuruları.", "Official account of the rail operator. Service and disruption notices."][idx]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(who.get("handle", "")))
	var job: Array = SocialTemplates.JOBS[rng.randi() % SocialTemplates.JOBS.size()]
	var q: Array = SocialTemplates.QUIRKS[rng.randi() % SocialTemplates.QUIRKS.size()]
	var hood := ""
	var zones: Array = st.city.zones.filter(func(z): return z["poi_id"] == "" and float(z["base_pop"]) > 30.0)
	if not zones.is_empty():
		hood = zones[rng.randi() % zones.size()]["name"]
	var q0: String = q[idx]
	q0 = q0.substr(0, 1).to_upper() + q0.substr(1)
	if idx == 0:
		var where := (hood + "'" + SocialFeed.tr_suffix(hood, "da") + " oturuyor") if hood != "" else "Şehirli"
		return "%s, %s. %s." % [where, job[0], q0]
	return "%s, %s. %s." % [("Lives in " + hood) if hood != "" else "Local", job[1], q0]


static func followers(who: Dictionary) -> int:
	if who.has("cast"):
		return int(SocialTemplates.CAST[str(who["cast"])]["followers"])
	if str(who.get("kind", "")) == "news":
		return 240000 + hash(str(who["handle"])) % 90000
	if str(who.get("kind", "")) == "official":
		return 412000
	return 40 + absi(hash(str(who.get("handle", "")))) % 2400


static func open(gs: GameScreen, who: Dictionary) -> void:
	var st := gs.state
	var m := Modal.create("", 640.0)
	var face := BigFace.new()
	face.who = who
	face.custom_minimum_size = Vector2(0, 170)
	m.body.add_child(face)
	var name := UI.title(str(who.get("name", "")), 40)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(name)
	var h := UI.label("@%s · %s %s" % [who.get("handle", ""), Geo.fmt_short(followers(who)), I18n.t("followers")], 21, Palette.MUTED, 700)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(h)
	var bio := UI.wrap_label(bio_of(who, st), 24, Palette.TEXT)
	bio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(bio)
	var mine: Array = st.feed.posts.filter(func(p): return p["who"].get("handle", "") == who.get("handle", "-"))
	if not mine.is_empty():
		var t := UI.label(I18n.t("recent_posts").to_upper(), 18, Palette.FAINT, 800)
		t.add_theme_font_override("font", ThemeBuilder.display(700))
		m.body.add_child(t)
		for p in mine.slice(0, 2):
			var pc := PostCard.make(p, st.feed)
			m.body.add_child(pc)
	var ok := UI.button(I18n.t("close"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	gs.show_modal(m)
