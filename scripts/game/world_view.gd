class_name WorldView
extends Node2D
## Bundles all map layers + camera for a city.

var state: GameState
var map: MapLayer
var labels: LabelLayer
var network: NetworkLayer
var vehicles: VehicleLayer
var draft: DraftLayer
var flavor: FlavorLayer
var growth: GrowthLayer
var diagram_veil: DiagramVeil
var events: EventFxLayer
var _zoom_pending := -1.0
var _zoom_applied_ms := -1000
const ZOOM_REBUILD_MS := 110


## Cream "paper" laid over the geography in schematic mode.
class DiagramVeil:
	extends Node2D
	var size_px := Vector2.ONE
	func _draw() -> void:
		draw_rect(Rect2(Vector2(-6000, -6000), size_px + Vector2(12000, 12000)), Color(Palette.CREAM, 0.88))
		var g := NetworkLayer.DIAGRAM_GRID * 4.0
		var x := 0.0
		while x <= size_px.x:
			draw_line(Vector2(x, 0), Vector2(x, size_px.y), Color(Palette.INK, 0.05), 3.0)
			x += g
		var y := 0.0
		while y <= size_px.y:
			draw_line(Vector2(0, y), Vector2(size_px.x, y), Color(Palette.INK, 0.05), 3.0)
			y += g
var daylight: CanvasModulate
var lights_layer: CanvasLayer
var lights: NightLights
var day_t := 0.33            # 0..1 time of day (0.33 ≈ 08:00)
const DAY_SECONDS := 150.0   # real seconds per in-game day at 1x
var camera: CameraRig


func setup(s: GameState) -> void:
	state = s
	map = MapLayer.new()
	add_child(map)
	map.setup(s.city)
	growth = GrowthLayer.new()
	add_child(growth)
	growth.setup(s)
	flavor = FlavorLayer.new()
	add_child(flavor)
	flavor.setup(s.city)
	labels = LabelLayer.new()
	add_child(labels)
	labels.setup(s.city)
	events = EventFxLayer.new()
	add_child(events)
	events.setup(s, map._roads)
	diagram_veil = DiagramVeil.new()
	diagram_veil.size_px = s.city.size_km * MapLayer.PX
	diagram_veil.modulate.a = 0.0
	add_child(diagram_veil)
	network = NetworkLayer.new()
	add_child(network)
	network.setup(s.net, s.demand)
	vehicles = VehicleLayer.new()
	add_child(vehicles)
	vehicles.setup(s.net, network, s.demand)
	draft = DraftLayer.new()
	add_child(draft)
	daylight = CanvasModulate.new()
	add_child(daylight)
	lights_layer = CanvasLayer.new()
	lights_layer.layer = 1
	lights_layer.follow_viewport_enabled = true
	add_child(lights_layer)
	lights = NightLights.new()
	lights_layer.add_child(lights)
	lights.setup(s.city, s.net, vehicles)
	camera = CameraRig.new()
	add_child(camera)
	camera.make_current()
	var b := Rect2(Vector2.ZERO, s.city.size_km * MapLayer.PX)
	camera.setup_bounds(b, get_viewport_rect().size)
	camera.position = b.get_center()
	var z := camera.min_zoom * 1.25
	camera.zoom = Vector2(z, z)
	camera.zoom_changed.connect(_on_zoom)
	labels.min_zoom = camera.min_zoom
	labels.year = s.year
	s.ridership_updated.connect(func(): network.queue_redraw())
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_zoom(z)


func _on_viewport_resized() -> void:
	if camera == null:
		return
	camera.setup_bounds(Rect2(Vector2.ZERO, state.city.size_km * MapLayer.PX), get_viewport_rect().size)
	labels.min_zoom = camera.min_zoom
	if camera.zoom.x < camera.min_zoom:
		camera.zoom = Vector2(camera.min_zoom, camera.min_zoom)
	camera._clamp()


## Cheap layers follow every zoom step; the expensive vector rebuilds (network,
## water, roads, lights) are throttled while pinching and settle on the final zoom.
func _on_zoom(z: float) -> void:
	vehicles.zoom = z
	draft.zoom = z
	events.set_zoom(z)
	_zoom_pending = z
	if Time.get_ticks_msec() - _zoom_applied_ms >= ZOOM_REBUILD_MS:
		_apply_zoom()


func _apply_zoom() -> void:
	var z := _zoom_pending
	_zoom_pending = -1.0
	_zoom_applied_ms = Time.get_ticks_msec()
	labels.set_zoom(z)
	network.set_zoom(z)
	flavor.set_zoom(z)
	map.set_zoom(z)
	lights.set_zoom(z)


func _process(_d: float) -> void:
	if _zoom_pending > 0.0 and Time.get_ticks_msec() - _zoom_applied_ms >= ZOOM_REBUILD_MS:
		_apply_zoom()


## Advances the visual day/night cycle.
func advance_day(dt_real: float, speed: float) -> void:
	if not Settings.day_night:
		day_t = 0.5
	else:
		day_t = fmod(day_t + dt_real * speed / DAY_SECONDS, 1.0)
	var h := day_t * 24.0
	var day_c := Color(1, 1, 1)
	var dusk_c := Color(1.0, 0.8, 0.66)
	var night_c := Color(0.30, 0.36, 0.56)
	var c: Color
	var night := 0.0
	if h < 5.0 or h >= 21.0:
		c = night_c
		night = 1.0
	elif h < 6.5:
		var t := (h - 5.0) / 1.5
		c = night_c.lerp(dusk_c, t)
		night = 1.0 - t
	elif h < 8.0:
		c = dusk_c.lerp(day_c, (h - 6.5) / 1.5)
	elif h < 18.0:
		c = day_c
	elif h < 19.5:
		c = day_c.lerp(dusk_c, (h - 18.0) / 1.5)
		night = (h - 18.0) / 1.5 * 0.35
	else:
		var t2 := (h - 19.5) / 1.5
		c = dusk_c.lerp(night_c, t2)
		night = 0.35 + 0.65 * t2
	daylight.color = c
	lights.modulate.a = night


func clock_text() -> String:
	var mins := int(day_t * 24.0 * 60.0)
	return "%02d:%02d" % [mins / 60, (mins % 60) / 10 * 10]


func is_night() -> bool:
	var h := day_t * 24.0
	return h < 6.0 or h >= 19.5


func focus_km(p: Vector2, z: float = -1.0) -> void:
	camera.fly_to(p * MapLayer.PX, z)


## Schematic metro-map view: octilinear lines, faded geography.
func set_diagram(on: bool) -> void:
	network.set_diagram(on)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(diagram_veil, "modulate:a", 1.0 if on else 0.0, 0.3)
	tw.tween_property(labels, "modulate:a", 0.0 if on else 1.0, 0.3)
	tw.tween_property(flavor, "modulate:a", 0.0 if on else 1.0, 0.3)
	tw.tween_property(growth, "modulate:a", 0.0 if on else 1.0, 0.3)
	tw.tween_property(events, "modulate:a", 0.0 if on else 1.0, 0.3)


## Quality switch for slower devices.
func apply_quality(high: bool) -> void:
	if map and map.water and map.water._waves:
		map.water._waves.visible = high and not Settings.reduce_motion
	if map:
		for c in map.get_children():
			if c is Sprite2D and c != map.hillshade and c != map.heat:
				c.visible = high # paper grain
	if lights:
		lights.set_detail(high)
	if flavor:
		flavor.set_detail(high)
	if events:
		events.set_detail(high)
