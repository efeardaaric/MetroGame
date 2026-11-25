class_name Face
extends RefCounted
## Small flat portraits for the people of Cıvıltı. A "look" dictionary describes a face;
## random citizens get one derived from their handle, the recurring cast have fixed ones.

const SKINS := [Color("f1c9a5"), Color("e2b48c"), Color("c99872"), Color("a8774f"), Color("f5d7bd")]
const HAIRS := [Color("2b1d14"), Color("4a2f1d"), Color("6b4a2b"), Color("a57a46"), Color("1c1c1c"), Color("b8b8b2")]
const SHIRTS := [Color("1d3566"), Color("7d1626"), Color("2f6b4f"), Color("6d4c8f"), Color("c47a1f"), Color("3d4b5c"), Color("b8455a")]
const BGS := [Color("f3ebdd"), Color("dfe8f1"), Color("f0dfd2"), Color("e3ecd9"), Color("ece2f0")]


## Deterministic look for a handle.
static func look_for(handle: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(handle)
	var female := rng.randf() < 0.5
	var age := rng.randi() % 3  # 0 young, 1 middle, 2 old
	var hair := 0
	if female:
		hair = [2, 3, 4, 5, 5, 2][rng.randi() % 6]  # long, bun, curly, headscarf
	else:
		hair = [0, 1, 1, 1, 4][rng.randi() % 5]       # bald, short, curly
	var hc: Color = HAIRS[rng.randi() % 5]
	if age == 2:
		hc = HAIRS[5]
	return {
		"skin": SKINS[rng.randi() % SKINS.size()], "hair": hair, "hair_col": hc,
		"beard": 0 if female else [0, 0, 1, 2][rng.randi() % 4],
		"glasses": rng.randf() < 0.28, "hat": "" if rng.randf() < 0.85 or hair == 5 else ["cap", "beret"][rng.randi() % 2],
		"shirt": SHIRTS[rng.randi() % SHIRTS.size()], "bg": BGS[rng.randi() % BGS.size()],
		"scarf_col": SHIRTS[rng.randi() % SHIRTS.size()].lightened(0.25), "age": age,
		"smile": rng.randf() < 0.6,
	}


## Look of a recurring character (indices / hex strings in SocialTemplates.CAST).
static func cast_look(id: String) -> Dictionary:
	var src: Dictionary = SocialTemplates.CAST.get(id, {}).get("look", {})
	var lk := src.duplicate()
	lk["skin"] = SKINS[int(src.get("skin", 0))]
	lk["hair_col"] = HAIRS[int(src.get("hair_col", 0))]
	for key in ["shirt", "bg", "scarf_col"]:
		if src.has(key):
			lk[key] = Color(str(src[key]))
	return lk


static func look_of(who: Dictionary) -> Dictionary:
	if who.has("cast"):
		return cast_look(str(who["cast"]))
	return look_for(str(who.get("handle", "x")))


## Draws a round portrait of radius r centred at c.
static func draw(ci: CanvasItem, c: Vector2, r: float, lk: Dictionary, blink: bool = false) -> void:
	var k := r / 50.0
	ci.draw_circle(c, r, lk.get("bg", BGS[0]))
	var skin: Color = lk.get("skin", SKINS[0])
	var hc: Color = lk.get("hair_col", HAIRS[0])
	var hair: int = lk.get("hair", 1)
	# long hair behind the head
	if hair == 2:
		ci.draw_rect(Rect2(c + Vector2(-25, -10) * k, Vector2(50, 42) * k), hc)
	# shoulders
	var shirt: Color = lk.get("shirt", SHIRTS[0])
	ci.draw_circle(c + Vector2(0, 64) * k, 38 * k, shirt)
	ci.draw_rect(Rect2(c + Vector2(-7, 24) * k, Vector2(14, 12) * k), skin.darkened(0.06))
	if lk.get("uniform", false):
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 30) * k, c + Vector2(0, 42) * k, c + Vector2(-16, 40) * k]), Palette.CREAM)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(9, 30) * k, c + Vector2(0, 42) * k, c + Vector2(16, 40) * k]), Palette.CREAM)
		ci.draw_circle(c + Vector2(-18, 46) * k, 3 * k, Logo.BRASS)
		ci.draw_circle(c + Vector2(18, 46) * k, 3 * k, Logo.BRASS)
	# headscarf frames the face
	if hair == 5:
		var sc: Color = lk.get("scarf_col", Color("b8455a"))
		ci.draw_circle(c + Vector2(0, 4) * k, 30 * k, sc)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, 14) * k, c + Vector2(26, 14) * k, c + Vector2(14, 36) * k, c + Vector2(-14, 36) * k]), sc)
	# ears and face
	if hair != 5:
		ci.draw_circle(c + Vector2(-23, 6) * k, 5 * k, skin.darkened(0.08))
		ci.draw_circle(c + Vector2(23, 6) * k, 5 * k, skin.darkened(0.08))
	ci.draw_circle(c + Vector2(0, 5) * k, 22 * k, skin)
	# hair on top
	match hair:
		1:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 0) * k, c + Vector2(-20, -14) * k, c + Vector2(-8, -20) * k, c + Vector2(10, -20) * k, c + Vector2(21, -12) * k, c + Vector2(22, 0) * k, c + Vector2(16, -8) * k, c + Vector2(-14, -8) * k]), hc)
		2, 3:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-23, 6) * k, c + Vector2(-20, -14) * k, c + Vector2(0, -21) * k, c + Vector2(20, -14) * k, c + Vector2(23, 6) * k, c + Vector2(14, -6) * k, c + Vector2(-2, -10) * k, c + Vector2(-16, -4) * k]), hc)
			if hair == 3:
				ci.draw_circle(c + Vector2(0, -22) * k, 8 * k, hc)
		4:
			for p in [Vector2(-16, -12), Vector2(-6, -18), Vector2(6, -18), Vector2(16, -12), Vector2(-21, -2), Vector2(21, -2)]:
				ci.draw_circle(c + p * k, 7.5 * k, hc)
		0:
			ci.draw_arc(c + Vector2(0, 5) * k, 21 * k, PI * 0.95, PI * 1.12, 6, hc, 3 * k)
			ci.draw_arc(c + Vector2(0, 5) * k, 21 * k, PI * 1.88, PI * 2.05, 6, hc, 3 * k)
	# wrinkles for the elders
	if int(lk.get("age", 0)) == 2:
		ci.draw_line(c + Vector2(-8, -8) * k, c + Vector2(8, -8) * k, skin.darkened(0.15), 1.2 * k)
	# eyes & brows
	var ink := Color("2e211a")
	for x in [-8.0, 8.0]:
		if blink:
			ci.draw_line(c + Vector2(x - 3, 3) * k, c + Vector2(x + 3, 3) * k, ink, 2 * k)
		else:
			ci.draw_circle(c + Vector2(x, 3) * k, 2.4 * k, ink)
		var bc: Color = hc if hair != 5 else ink
		ci.draw_line(c + Vector2(x - 5, -3) * k, c + Vector2(x + 4, -4) * k, bc.darkened(0.1), 2.2 * k, true)
	if lk.get("glasses", false):
		for x in [-8.0, 8.0]:
			ci.draw_arc(c + Vector2(x, 3) * k, 6 * k, 0.0, TAU, 16, Color("2b2b2b"), 1.6 * k, true)
		ci.draw_line(c + Vector2(-2, 3) * k, c + Vector2(2, 3) * k, Color("2b2b2b"), 1.6 * k)
	# beard / moustache
	var beard: int = lk.get("beard", 0)
	var bcol: Color = hc if int(lk.get("age", 0)) < 2 else HAIRS[5]
	if beard == 2:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 8) * k, c + Vector2(-14, 24) * k, c + Vector2(0, 28) * k, c + Vector2(14, 24) * k, c + Vector2(20, 8) * k, c + Vector2(10, 18) * k, c + Vector2(-10, 18) * k]), bcol)
	if beard >= 1:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, 15) * k, c + Vector2(-8, 10) * k, c + Vector2(0, 11) * k, c + Vector2(8, 10) * k, c + Vector2(13, 15) * k, c + Vector2(6, 14) * k, c + Vector2(0, 15) * k, c + Vector2(-6, 14) * k]), bcol)
	# mouth
	if lk.get("smile", true):
		ci.draw_arc(c + Vector2(0, 14) * k, 5 * k, 0.25, PI - 0.25, 8, Color("8b4b3b"), 2 * k, true)
	else:
		ci.draw_line(c + Vector2(-4, 18) * k, c + Vector2(4, 18) * k, Color("8b4b3b"), 2 * k, true)
	# hats
	match str(lk.get("hat", "")):
		"driver":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -10) * k, c + Vector2(26, -10) * k, c + Vector2(30, -27) * k, c + Vector2(-30, -27) * k]), Color("1d3566"))
			ci.draw_rect(Rect2(c + Vector2(-26, -12) * k, Vector2(52, 6) * k), Color("0f1d3d"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-23, -7) * k, c + Vector2(23, -7) * k, c + Vector2(17, -1) * k, c + Vector2(-17, -1) * k]), Color("0b1020"))
			ci.draw_circle(c + Vector2(0, -19) * k, 5.5 * k, Logo.BRASS_DARK)
			ci.draw_circle(c + Vector2(0, -19) * k, 4.2 * k, Logo.BRASS)
		"cap":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -6) * k, c + Vector2(-18, -20) * k, c + Vector2(0, -25) * k, c + Vector2(18, -20) * k, c + Vector2(22, -6) * k]), shirt.lightened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -8) * k, c + Vector2(30, -8) * k, c + Vector2(26, -3) * k, c + Vector2(-2, -4) * k]), shirt.darkened(0.2))
		"beret":
			ci.draw_circle(c + Vector2(-2, -14) * k, 15 * k, Color("2d2d38"))
			ci.draw_rect(Rect2(c + Vector2(-20, -12) * k, Vector2(38, 5) * k), Color("2d2d38"))
		"kasket":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-24, -6) * k, c + Vector2(-22, -18) * k, c + Vector2(4, -24) * k, c + Vector2(24, -16) * k, c + Vector2(26, -6) * k]), Color("5a4a3a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -6) * k, c + Vector2(28, -7) * k, c + Vector2(24, -2) * k, c + Vector2(-4, -2) * k]), Color("3e3226"))
