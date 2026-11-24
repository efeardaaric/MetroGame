class_name PostCard
extends PanelContainer
## A single "Cıvıltı" post: avatar, name/handle, text with highlighted #tags/@mentions, likes.

var post: Dictionary
var feed: SocialFeed
var _like_btn: Button
var _like_lbl: Label


static func make(p: Dictionary, f: SocialFeed) -> PostCard:
	var c := PostCard.new()
	c.post = p
	c.feed = f
	c._build()
	return c


class Avatar:
	extends Control
	var color := Color.WHITE
	var initials := ""
	var kind := "citizen"
	func _draw() -> void:
		var r := size.x * 0.5
		draw_circle(Vector2(r, r), r, color)
		var f := ThemeBuilder.font(900)
		var fs := int(r * 0.85)
		var tw := f.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(r - tw * 0.5, r + fs * 0.36), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		if kind != "citizen":
			# verified badge
			var c := Vector2(size.x - 6, size.y - 6)
			draw_circle(c, 11, Palette.PANEL_2)
			draw_circle(c, 9, Palette.INFO if kind == "news" else Palette.ACCENT)
			draw_polyline(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(-1, 3), c + Vector2(4, -3)]), Color.WHITE, 2.0, true)


func _build() -> void:
	var who: Dictionary = post["who"]
	var bg := Palette.PANEL_2
	if who.get("kind", "") == "official":
		bg = Color("2f2a1a")
	elif post.get("viral", false):
		bg = Color("2a2440")
	add_theme_stylebox_override("panel", ThemeBuilder.box(bg, 22, 0, Color.TRANSPARENT, 16, 14))
	var h := UI.hbox(14)
	add_child(h)
	var av := Avatar.new()
	av.custom_minimum_size = Vector2(58, 58)
	av.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	av.color = Color(who.get("color", "888888"))
	var parts: PackedStringArray = str(who["name"]).split(" ")
	av.initials = (parts[0].substr(0, 1) + (parts[1].substr(0, 1) if parts.size() > 1 else "")).to_upper()
	av.kind = who.get("kind", "citizen")
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(av)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(8)
	var nm := UI.label(who["name"], 23, Palette.TEXT, 900)
	top.add_child(nm)
	var hd := UI.label("@%s · %s %d" % [who["handle"], I18n.month_name(int(post["m"])), int(post["y"])], 19, Palette.FAINT)
	hd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.clip_text = true
	hd.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(hd)
	v.add_child(top)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", 24)
	rt.add_theme_font_size_override("bold_font_size", 24)
	rt.add_theme_font_override("normal_font", ThemeBuilder.font(600))
	rt.add_theme_font_override("bold_font", ThemeBuilder.font(850))
	rt.add_theme_color_override("default_color", Palette.TEXT)
	rt.text = _highlight(feed.text_of(post))
	rt.custom_minimum_size.x = 200
	v.add_child(rt)
	var foot := UI.hbox(18)
	_like_btn = Button.new()
	_like_btn.theme_type_variation = "FlatButton"
	_like_btn.focus_mode = Control.FOCUS_NONE
	_like_btn.custom_minimum_size = Vector2(150, 48)
	var lh := UI.hbox(6)
	lh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lh.position = Vector2(8, 8)
	var heart := Icon.make("heart", 30, Palette.BAD if post.get("liked", false) else Palette.MUTED)
	lh.add_child(heart)
	_like_lbl = UI.label(Geo.fmt_short(post["likes"]), 21, Palette.MUTED, 800)
	lh.add_child(_like_lbl)
	_like_btn.add_child(lh)
	_like_btn.pressed.connect(func():
		post["liked"] = not post.get("liked", false)
		post["likes"] = int(post["likes"]) + (1 if post["liked"] else -1)
		heart.set_color(Palette.BAD if post["liked"] else Palette.MUTED)
		_like_lbl.text = Geo.fmt_short(post["likes"])
		Audio.play("tap", 1.3)
		Settings.vibrate(8)
		UI.pop_in(heart, 0.6)
	)
	foot.add_child(_like_btn)
	var rp := UI.hbox(6)
	rp.add_child(Icon.make("repost", 28, Palette.MUTED))
	rp.add_child(UI.label(Geo.fmt_short(post["reposts"]), 21, Palette.MUTED, 800))
	foot.add_child(rp)
	foot.add_child(UI.spacer())
	var s: float = post["sent"]
	var mood := Icon.make("smile" if s > 0.3 else ("frown" if s < -0.3 else "neutral"), 30,
		Palette.GOOD if s > 0.3 else (Palette.BAD if s < -0.3 else Palette.MUTED))
	foot.add_child(mood)
	v.add_child(foot)


static func _highlight(t: String) -> String:
	t = t.replace("[", "(").replace("]", ")")
	var re := RegEx.new()
	re.compile("([#@][\\p{L}\\p{N}_]+)")
	return re.sub(t, "[color=#4cc9f0][b]$1[/b][/color]", true)
