class_name Logo
extends Control
## The game's mark: a brass transit token (jeton) like the ones Istanbul commuters
## dropped into turnstiles for decades, stamped with an "M". It flips in once and
## catches the light now and then.

const BRASS := Color("c99a3b")
const BRASS_LIGHT := Color("f1d27a")
const BRASS_DARK := Color("7a5a1e")

var _t := 0.0
var coin_scale := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.y * 0.46, size.x * 0.3) * coin_scale
	# flip-in: the coin spins about its vertical axis and settles
	var flip := clampf(_t / 0.9, 0.0, 1.0)
	var sx := absf(cos((1.0 - flip) * PI * 2.0)) if flip < 1.0 else 1.0
	sx = maxf(sx, 0.04)
	draw_set_transform(c, 0.0, Vector2(sx, 1.0))
	draw_token(self, Vector2.ZERO, r, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draws the token on any CanvasItem (also used by the city intro board).
static func draw_token(ci: CanvasItem, c: Vector2, r: float, t: float) -> void:
	# drop shadow
	ci.draw_circle(c + Vector2(0, r * 0.07), r * 1.02, Color(0, 0, 0, 0.35))
	# rim
	ci.draw_circle(c, r, BRASS_DARK)
	ci.draw_circle(c, r * 0.97, BRASS)
	ci.draw_arc(c, r * 0.93, PI * 1.05, PI * 1.85, 32, Color(BRASS_LIGHT, 0.7), r * 0.05, true)
	# field
	ci.draw_circle(c, r * 0.8, BRASS_DARK.lerp(BRASS, 0.55))
	ci.draw_circle(c, r * 0.77, BRASS.darkened(0.06))
	# milled ring of dots
	var n := 36
	for i in n:
		var a := TAU * i / n
		ci.draw_circle(c + Vector2.from_angle(a) * r * 0.875, r * 0.028, BRASS_DARK)
	# stamped M: shadow, then the raised face
	var pts := PackedVector2Array()
	for p in [Vector2(-0.38, 0.36), Vector2(-0.38, -0.34), Vector2(0.0, 0.12), Vector2(0.38, -0.34), Vector2(0.38, 0.36)]:
		pts.append(c + p * r)
	var w := r * 0.2
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(r * 0.03, r * 0.04))
	ci.draw_polyline(sh, BRASS_DARK, w, true)
	ci.draw_polyline(pts, BRASS_LIGHT.lerp(BRASS, 0.35), w, true)
	for i in [0, 4]:
		ci.draw_circle(sh[i], w * 0.5, BRASS_DARK)
		ci.draw_circle(pts[i], w * 0.5, BRASS_LIGHT.lerp(BRASS, 0.35))
	# small star punched above the M, like the old token's cut-out
	ci.draw_colored_polygon(Icon._star(c + Vector2(0, -r * 0.58), r * 0.09, r * 0.04), BRASS_DARK)
	# a glint that sweeps across every few seconds
	var g := fmod(t, 5.0) - 1.2
	if g > 0.0 and g < 0.8:
		var x := lerpf(-r, r, g / 0.8)
		var top := c + Vector2(x - r * 0.25, -r * 0.7)
		var bot := c + Vector2(x + r * 0.25, r * 0.7)
		ci.draw_line(top, bot, Color(1, 1, 0.9, 0.22 * sin(g / 0.8 * PI)), r * 0.18, true)
