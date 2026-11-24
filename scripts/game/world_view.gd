class_name WorldView
extends Node2D
## Bundles all map layers + camera for a city.

var state: GameState
var map: MapLayer
var labels: LabelLayer
var network: NetworkLayer
var vehicles: VehicleLayer
var draft: DraftLayer
var camera: CameraRig


func setup(s: GameState) -> void:
	state = s
	map = MapLayer.new()
	add_child(map)
	map.setup(s.city)
	labels = LabelLayer.new()
	add_child(labels)
	labels.setup(s.city)
	network = NetworkLayer.new()
	add_child(network)
	network.setup(s.net, s.demand)
	vehicles = VehicleLayer.new()
	add_child(vehicles)
	vehicles.setup(s.net, network, s.demand)
	draft = DraftLayer.new()
	add_child(draft)
	camera = CameraRig.new()
	add_child(camera)
	camera.make_current()
	var b := Rect2(Vector2.ZERO, s.city.size_km * MapLayer.PX)
	camera.setup_bounds(b, get_viewport_rect().size)
	camera.position = b.get_center()
	var z := camera.min_zoom * 1.25
	camera.zoom = Vector2(z, z)
	camera.zoom_changed.connect(_on_zoom)
	s.ridership_updated.connect(func(): network.queue_redraw())
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_zoom(z)


func _on_viewport_resized() -> void:
	if camera == null:
		return
	camera.setup_bounds(Rect2(Vector2.ZERO, state.city.size_km * MapLayer.PX), get_viewport_rect().size)
	if camera.zoom.x < camera.min_zoom:
		camera.zoom = Vector2(camera.min_zoom, camera.min_zoom)
	camera._clamp()


func _on_zoom(z: float) -> void:
	labels.set_zoom(z)
	network.set_zoom(z)
	vehicles.zoom = z
	draft.zoom = z


func focus_km(p: Vector2, z: float = -1.0) -> void:
	camera.fly_to(p * MapLayer.PX, z)
