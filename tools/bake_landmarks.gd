extends Node
## Builds small low-poly 3D models of each city's landmarks from primitives and renders
## them to transparent sprites (assets/landmarks/<id>.png) seen from a 3/4 angle.
## The map shows these sprites when you zoom in.
##
## Run (needs a GL context):
##   xvfb-run godot --path . --rendering-driver opengl3 tools/bake_landmarks.tscn

const SIZE := 512
const ORTHO := 16.0           # world units covered by the camera, same for every model
const OUT := "res://assets/landmarks/"

const STONE := Color("dbc9a4")
const STONE_D := Color("c9b48c")
const WHITE := Color("ebe2d0")
const LEAD := Color("6c7a8b")
const SLATE := Color("5b6878")
const BRICK := Color("c0705a")
const TERRA := Color("c8603c")
const GOLD := Color("e0b44a")
const GLASS := Color("7fb3d5")
const ROCK := Color("9c8f7c")
const GREEN := Color("8fbf7a")

var vp: SubViewport
var stage: Node3D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	vp = SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO
	# 3/4 view from the south-south-west, looking down ~38°
	cam.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-38), deg_to_rad(-20), 0)), Vector3.ZERO)
	cam.position = cam.transform.basis.z * 40.0 + Vector3(0, 5.5, 0)
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-140), 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = false
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("dfe6f2")
	e.ambient_light_energy = 0.42
	env.environment = e
	vp.add_child(env)
	_run()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _add(mesh: Mesh, pos: Vector3, c: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	mi.rotation = rot
	stage.add_child(mi)
	return mi


func cyl(r_top: float, r_bot: float, h: float, base: Vector3, c: Color, sides := 24) -> void:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	_add(m, base + Vector3(0, h * 0.5, 0), c)


func box(sz: Vector3, base: Vector3, c: Color, rot_y := 0.0) -> void:
	var m := BoxMesh.new()
	m.size = sz
	_add(m, base + Vector3(0, sz.y * 0.5, 0), c, Vector3(0, rot_y, 0))


func dome(r: float, base: Vector3, c: Color, squash := 1.0) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * squash
	m.is_hemisphere = true
	m.radial_segments = 24
	m.rings = 8
	_add(m, base, c)


func ball(r: float, center: Vector3, c: Color, squash := 1.0) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0 * squash
	_add(m, center, c)


func pyramid(w: float, h: float, base: Vector3, c: Color) -> void:
	cyl(0.0, w * 0.7071, h, base, c, 4)


func minaret(base: Vector3, h: float, c: Color = WHITE, cap: Color = LEAD) -> void:
	cyl(0.22, 0.26, h, base, c, 10)
	cyl(0.36, 0.36, 0.12, base + Vector3(0, h * 0.72, 0), c, 12)
	cyl(0.0, 0.26, h * 0.28, base + Vector3(0, h, 0), cap, 10)


func crenels(center: Vector3, w: float, d: float, y: float, c: Color) -> void:
	var n := int(w / 0.5)
	for i in n:
		var x := -w * 0.5 + (i + 0.5) * w / n
		if i % 2 == 0:
			box(Vector3(0.25, 0.3, 0.25), center + Vector3(x, y, d * 0.5), c)
			box(Vector3(0.25, 0.3, 0.25), center + Vector3(x, y, -d * 0.5), c)


func ground(_r: float, _c: Color = GREEN) -> void:
	pass # the map itself is the ground


# ------------------------------------------------------------------ models

func m_galata() -> void:
	ground(2.6, Color("cfc4ad"))
	cyl(1.55, 1.75, 6.5, Vector3.ZERO, STONE)
	cyl(1.95, 1.95, 0.25, Vector3(0, 6.5, 0), STONE_D)
	cyl(1.45, 1.45, 1.1, Vector3(0, 6.75, 0), WHITE)
	for i in 8:
		var a := TAU * i / 8.0
		box(Vector3(0.28, 0.6, 0.1), Vector3(cos(a) * 1.46, 6.95, sin(a) * 1.46), Color("3a4656"), -a)
	cyl(0.0, 1.75, 2.9, Vector3(0, 7.85, 0), SLATE, 24)
	cyl(0.04, 0.04, 0.6, Vector3(0, 10.7, 0), GOLD, 6)


func m_kizkulesi() -> void:
	ball(2.6, Vector3(0, -1.6, 0), ROCK, 0.45)
	box(Vector3(3.2, 1.3, 2.0), Vector3(-0.6, -0.2, 0.3), WHITE)
	box(Vector3(1.3, 3.2, 1.3), Vector3(0.9, -0.2, -0.2), WHITE)
	cyl(0.72, 0.72, 1.0, Vector3(0.9, 3.0, -0.2), WHITE, 8)
	cyl(0.0, 0.85, 1.4, Vector3(0.9, 4.0, -0.2), LEAD, 8)
	cyl(0.03, 0.03, 0.5, Vector3(0.9, 5.4, -0.2), GOLD, 6)
	dome(0.5, Vector3(-1.4, 1.1, 0.3), LEAD)


func m_rumelihisari() -> void:
	ground(5.0)
	for t in [[Vector3(-3, 0, 1), 1.4, 4.6], [Vector3(2.6, 0, 1.6), 1.2, 4.0], [Vector3(0.4, 0, -2.4), 1.15, 5.0]]:
		cyl(t[1], t[1] * 1.08, t[2], t[0], STONE)
		cyl(0.0, t[1] * 1.15, t[1] * 1.5, t[0] + Vector3(0, t[2], 0), LEAD)
	box(Vector3(5.6, 2.2, 0.5), Vector3(-0.2, 0, 1.4), STONE_D, 0.12)
	box(Vector3(0.5, 2.2, 4.0), Vector3(-1.4, 0, -0.6), STONE_D, -0.5)
	box(Vector3(0.5, 2.2, 4.4), Vector3(1.6, 0, -0.4), STONE_D, 0.6)


func m_mosque() -> void:
	ground(5.6, Color("cfc4ad"))
	box(Vector3(6.0, 2.4, 6.0), Vector3.ZERO, WHITE)
	cyl(2.0, 2.2, 0.8, Vector3(0, 2.4, 0), WHITE, 24)
	dome(2.0, Vector3(0, 3.2, 0), LEAD, 1.0)
	cyl(0.02, 0.06, 0.6, Vector3(0, 5.2, 0), GOLD, 6)
	for d in [Vector3(2.4, 0, 0), Vector3(-2.4, 0, 0), Vector3(0, 0, 2.4), Vector3(0, 0, -2.4)]:
		dome(1.2, d + Vector3(0, 2.4, 0), LEAD)
	for d in [Vector3(2.3, 0, 2.3), Vector3(-2.3, 0, 2.3), Vector3(2.3, 0, -2.3), Vector3(-2.3, 0, -2.3)]:
		dome(0.65, d + Vector3(0, 2.4, 0), LEAD)
	for m in [Vector3(3.6, 0, 3.6), Vector3(-3.6, 0, 3.6), Vector3(3.6, 0, -3.6), Vector3(-3.6, 0, -3.6), Vector3(5.2, 0, 3.6), Vector3(-5.2, 0, 3.6)]:
		minaret(m, 7.0)


func m_anitkabir() -> void:
	ground(6.2, Color("cdbf9f"))
	box(Vector3(10.0, 0.8, 7.0), Vector3.ZERO, STONE_D)
	box(Vector3(7.6, 2.8, 4.4), Vector3(0, 0.8, 0), STONE)
	box(Vector3(8.2, 0.5, 5.0), Vector3(0, 3.6, 0), STONE_D)
	for i in 9:
		var x := -3.6 + i * 0.9
		cyl(0.16, 0.16, 2.8, Vector3(x, 0.8, 2.4), WHITE, 8)
		cyl(0.16, 0.16, 2.8, Vector3(x, 0.8, -2.4), WHITE, 8)
	for i in 5:
		var z := -2.0 + i * 1.0
		cyl(0.16, 0.16, 2.8, Vector3(3.9, 0.8, z), WHITE, 8)
		cyl(0.16, 0.16, 2.8, Vector3(-3.9, 0.8, z), WHITE, 8)
	box(Vector3(1.6, 0.6, 9.0), Vector3(0, 0, 6.0), STONE_D)


func m_atakule() -> void:
	ground(2.4, Color("cfc4ad"))
	box(Vector3(3.2, 1.2, 3.2), Vector3.ZERO, WHITE)
	cyl(0.55, 0.75, 8.0, Vector3(0, 1.2, 0), WHITE, 16)
	ball(1.7, Vector3(0, 9.8, 0), GLASS, 0.55)
	cyl(1.9, 1.9, 0.25, Vector3(0, 9.3, 0), WHITE, 24)
	cyl(0.05, 0.12, 2.0, Vector3(0, 10.7, 0), Color("d0d0d0"), 6)


func m_kale() -> void:
	ball(4.2, Vector3(0, -2.2, 0), Color("a8b07a"), 0.55)
	box(Vector3(6.0, 1.8, 0.6), Vector3(0, 0, 1.8), STONE_D)
	box(Vector3(6.0, 1.8, 0.6), Vector3(0, 0, -1.8), STONE_D)
	box(Vector3(0.6, 1.8, 4.2), Vector3(3.0, 0, 0), STONE_D)
	box(Vector3(0.6, 1.8, 4.2), Vector3(-3.0, 0, 0), STONE_D)
	for p in [Vector3(3, 0, 1.8), Vector3(-3, 0, 1.8), Vector3(3, 0, -1.8), Vector3(-3, 0, -1.8), Vector3(0, 0, 1.8)]:
		box(Vector3(1.1, 2.6, 1.1), p, STONE)
		crenels(p + Vector3(0, 0, 0), 1.1, 1.1, 2.6, STONE)
	box(Vector3(1.2, 1.0, 1.0), Vector3(-1.2, 0, 0), TERRA)
	pyramid(1.4, 0.7, Vector3(-1.2, 1.0, 0), Color("a3482c"))


func m_asansor() -> void:
	ground(2.6, Color("cfc4ad"))
	box(Vector3(2.4, 7.0, 2.0), Vector3.ZERO, BRICK)
	for y in [1.5, 3.0, 4.5]:
		box(Vector3(2.5, 0.12, 2.1), Vector3(0, y, 0), STONE)
	box(Vector3(3.0, 1.3, 2.6), Vector3(0, 7.0, 0), STONE)
	box(Vector3(3.2, 0.2, 2.8), Vector3(0, 8.3, 0), BRICK)
	box(Vector3(0.6, 0.6, 0.6), Vector3(0, 8.5, 0), GOLD)


func m_saatkulesi() -> void:
	ground(2.4, Color("d8cdb5"))
	cyl(1.6, 1.6, 0.4, Vector3.ZERO, STONE_D, 8)
	cyl(0.9, 1.0, 3.2, Vector3(0, 0.4, 0), Color("efe4cc"), 8)
	cyl(1.15, 1.15, 0.25, Vector3(0, 3.6, 0), STONE_D, 8)
	cyl(0.75, 0.85, 2.0, Vector3(0, 3.85, 0), Color("efe4cc"), 8)
	for i in 4:
		var a := TAU * i / 4.0 + PI / 8.0
		cyl(0.38, 0.38, 0.06, Vector3(cos(a) * 0.82, 4.6, sin(a) * 0.82), WHITE, 16)
	cyl(0.95, 0.95, 0.2, Vector3(0, 5.85, 0), STONE_D, 8)
	cyl(0.5, 0.6, 1.0, Vector3(0, 6.05, 0), Color("efe4cc"), 8)
	dome(0.55, Vector3(0, 7.05, 0), GOLD)
	cyl(0.03, 0.03, 0.6, Vector3(0, 7.5, 0), GOLD, 6)


func m_kadifekale() -> void:
	ball(4.4, Vector3(0, -2.4, 0), Color("c2a877"), 0.55)
	box(Vector3(7.0, 1.6, 0.6), Vector3(0, 0, 2.0), Color("c9a46a"))
	box(Vector3(0.6, 1.6, 4.4), Vector3(-3.5, 0, -0.2), Color("c9a46a"))
	box(Vector3(0.6, 1.6, 4.4), Vector3(3.5, 0, -0.2), Color("c9a46a"))
	for p in [Vector3(-3.5, 0, 2.0), Vector3(3.5, 0, 2.0), Vector3(0, 0, 2.0), Vector3(-1.8, 0, 2.0), Vector3(1.8, 0, 2.0)]:
		box(Vector3(1.0, 2.3, 1.0), p, Color("d2b07a"))
	for x in [-2.4, -1.2, 0.6, 2.0]:
		cyl(0.35, 0.4, 0.8, Vector3(x, 0, -1.2), Color("5f8a4f"), 8)
		ball(0.6, Vector3(x, 1.2, -1.2), Color("6f9f5c"))


func _house(pos: Vector3, c: Color, rot: float) -> void:
	box(Vector3(2.0, 1.4, 1.6), pos, WHITE, rot)
	box(Vector3(2.4, 1.4, 2.0), pos + Vector3(0, 1.4, 0), c, rot)
	box(Vector3(2.6, 0.06, 2.2), pos + Vector3(0, 1.4, 0), Color("6d4a2f"), rot)
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = 1.85
	m.height = 1.1
	m.radial_segments = 4
	_add(m, pos + Vector3(0, 3.35, 0), TERRA, Vector3(0, rot + PI / 4.0, 0))


func m_odunpazari() -> void:
	ground(4.6, Color("cfc4ad"))
	_house(Vector3(-2.2, 0, 0.8), Color("e7b84a"), 0.1)
	_house(Vector3(0.4, 0, 1.6), Color("d96a4f"), -0.1)
	_house(Vector3(2.6, 0, 0.4), Color("6aa3c8"), 0.05)
	_house(Vector3(-0.6, 0, -1.6), Color("9bc178"), 0.0)
	_house(Vector3(2.0, 0, -2.2), Color("c98ab8"), -0.15)


func m_hidirlik() -> void:
	ground(3.0, Color("cfc4ad"))
	box(Vector3(4.2, 1.6, 4.2), Vector3.ZERO, STONE_D)
	cyl(1.6, 1.7, 3.0, Vector3(0, 1.6, 0), STONE, 24)
	crenels(Vector3(0, 0, 0), 4.2, 4.2, 1.6, STONE_D)
	cyl(1.7, 1.7, 0.2, Vector3(0, 4.6, 0), STONE_D, 24)


func m_yivli() -> void:
	ground(2.4, Color("cfc4ad"))
	box(Vector3(2.2, 1.6, 2.2), Vector3.ZERO, STONE)
	for i in 8:
		var a := TAU * i / 8.0
		cyl(0.22, 0.26, 6.8, Vector3(cos(a) * 0.55, 1.6, sin(a) * 0.55), BRICK, 8)
	cyl(0.55, 0.62, 6.8, Vector3(0, 1.6, 0), BRICK, 16)
	cyl(0.9, 0.9, 0.18, Vector3(0, 6.6, 0), STONE, 16)
	cyl(0.45, 0.5, 1.0, Vector3(0, 8.4, 0), BRICK, 12)
	cyl(0.0, 0.5, 0.9, Vector3(0, 9.4, 0), LEAD, 12)


func m_ulucami() -> void:
	ground(5.4, Color("cfc4ad"))
	box(Vector3(7.6, 2.2, 6.2), Vector3.ZERO, STONE)
	for i in 5:
		for j in 4:
			dome(0.68, Vector3(-3.0 + i * 1.5, 2.2, -2.25 + j * 1.5), LEAD)
	minaret(Vector3(4.2, 0, 3.0), 6.8, STONE)
	minaret(Vector3(-4.2, 0, 3.0), 6.8, STONE)


func m_tophane() -> void:
	ball(3.4, Vector3(0, -1.8, 0), Color("a8b07a"), 0.55)
	box(Vector3(5.0, 1.5, 0.5), Vector3(-0.5, 0, 1.4), STONE_D)
	box(Vector3(1.4, 4.6, 1.4), Vector3(1.6, 0, -0.4), STONE)
	for i in 4:
		var a := TAU * i / 4.0
		cyl(0.36, 0.36, 0.06, Vector3(1.6 + cos(a) * 0.72, 3.8, -0.4 + sin(a) * 0.72), WHITE, 16)
	pyramid(1.7, 1.4, Vector3(1.6, 4.6, -0.4), LEAD)


func m_trb_kale() -> void:
	ball(3.8, Vector3(0, -2.0, 0), Color("7fa86a"), 0.5)
	box(Vector3(6.4, 2.0, 0.6), Vector3(0, 0, 1.6), STONE_D, 0.1)
	box(Vector3(0.6, 2.0, 3.6), Vector3(-3.0, 0, 0), STONE_D)
	for p in [Vector3(-3.0, 0, 1.6), Vector3(3.0, 0, 1.9), Vector3(-3.0, 0, -1.6)]:
		cyl(0.8, 0.9, 3.0, p, STONE, 12)
		crenels(p, 1.6, 1.6, 3.0, STONE)
	box(Vector3(1.8, 1.6, 1.4), Vector3(0.6, 0, -0.6), WHITE)
	pyramid(2.2, 0.9, Vector3(0.6, 1.6, -0.6), TERRA)


const MODELS := {
	"decor_galata": "m_galata", "decor_kizkulesi": "m_kizkulesi", "decor_rumelihisari": "m_rumelihisari",
	"decor_sultanahmet": "m_mosque", "decor_anitkabir": "m_anitkabir", "decor_atakule": "m_atakule",
	"decor_kale": "m_kale", "decor_asansor": "m_asansor", "decor_saatkulesi": "m_saatkulesi",
	"decor_kadifekale": "m_kadifekale", "decor_odunpazari": "m_odunpazari", "decor_hidirlik": "m_hidirlik",
	"decor_yivli": "m_yivli", "decor_ulucami": "m_ulucami", "decor_tophane": "m_tophane", "decor_trb_kale": "m_trb_kale",
}


## Thin dark contour around the silhouette so the sprite reads on any map colour.
func _outline(src: Image) -> Image:
	var w := src.get_width() + 6
	var h := src.get_height() + 6
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(3, 3))
	var line := Color(0.16, 0.13, 0.12, 0.85)
	var res := out.duplicate()
	for y in h:
		for x in w:
			if out.get_pixel(x, y).a > 0.5:
				continue
			var hit := 0.0
			for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
					hit = maxf(hit, out.get_pixel(q.x, q.y).a)
			if hit > 0.3:
				var c := out.get_pixel(x, y)
				res.set_pixel(x, y, line.lerp(c, c.a) if c.a > 0.0 else Color(line.r, line.g, line.b, line.a * hit))
	return res


func _run() -> void:
	var meta := {}
	for key in MODELS.keys():
		stage = Node3D.new()
		vp.add_child(stage)
		call(MODELS[key])
		for i in 4:
			await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var used := img.get_used_rect()
		var cropped := _outline(img.get_region(used))
		var id := str(key).trim_prefix("decor_")
		cropped.save_png(OUT + id + ".png")
		# where the model's ground origin (0,0,0) lands in the cropped image
		var cam: Camera3D = vp.get_camera_3d()
		var o := cam.unproject_position(Vector3.ZERO) - Vector2(used.position) + Vector2(3, 3)
		meta[id] = {"ax": o.x, "ay": o.y, "w": used.size.x, "h": used.size.y}
		print("baked ", id, " ", used.size)
		stage.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(OUT + "landmarks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()
	get_tree().quit()
