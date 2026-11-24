extends Node
## Root: theme, screen switching with fades, back button & app lifecycle.

var current: Node
var fade: ColorRect
var fade_layer: CanvasLayer
var _busy := false


func _ready() -> void:
	# Touch scrolling: controls inside any ScrollContainer must let drags through,
	# otherwise a finger resting on a button/card can never scroll the list.
	get_tree().node_added.connect(_on_node_added)
	var theme := ThemeBuilder.build()
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.fallback_font = ThemeBuilder.font(650)
	ThemeDB.fallback_font_size = 26
	get_tree().root.theme = theme
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	RenderingServer.set_default_clear_color(Palette.BG)
	get_tree().root.size_changed.connect(_update_content_scale)
	Settings.changed.connect(_update_content_scale)
	_update_content_scale()
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Palette.BG
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	var args := OS.get_cmdline_user_args()
	if args.has("--city"):
		var idx := args.find("--city")
		_show_game(args[idx + 1] if idx + 1 < args.size() else "istanbul", true)
	else:
		_show_menu()
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)


func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		sc.scroll_deadzone = 12
		sc.follow_focus = false
		return
	if not (n is Control):
		return
	var c := n as Control
	if c.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	var p := n.get_parent()
	while p != null and not (p is Viewport):
		if p is ScrollContainer:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		if p is CanvasLayer:
			return
		p = p.get_parent()


## Keeps UI at the same physical size in portrait and landscape by swapping the base resolution.
func _update_content_scale() -> void:
	var win := get_window()
	var s := win.size
	if s.x <= 0 or s.y <= 0:
		return
	var ts := Settings.text_scale
	var base := Vector2(1280, 720) if s.x > s.y else Vector2(720, 1280)
	var target := Vector2i(base / ts)
	if win.content_scale_size != target:
		win.content_scale_size = target


func _show_menu() -> void:
	var m := MainMenu.new()
	m.start_city.connect(start_city)
	_set_current(m)


## `id` is a save slot: a city id, optionally suffixed with "_sandbox".
func _show_game(id: String, fresh: bool) -> void:
	var st: GameState
	if fresh and id.begins_with("scn_"):
		SaveManager.delete_save(id)
		st = ScenarioData.create(id.trim_prefix("scn_"))
	elif fresh and id == "weekly":
		SaveManager.delete_save(id)
		st = ScenarioData.create_weekly()
	elif fresh:
		SaveManager.delete_save(id)
		st = GameState.new(id.trim_suffix("_sandbox"))
		st.sandbox = id.ends_with("_sandbox")
		st.tutorial_step = 0 if not SaveManager.progress.get("tutorial_done", false) else 6
		if st.sandbox:
			st.tutorial_step = 6
	else:
		st = SaveManager.load_game(id)
	var g := GameScreen.new()
	g.setup(st)
	g.exit_to_menu.connect(go_menu)
	_set_current(g)
	SaveManager.progress["last_city"] = id
	SaveManager.save_progress()


func _set_current(n: Node) -> void:
	if current:
		current.queue_free()
	current = n
	add_child(n)
	move_child(fade_layer, -1)


func start_city(id: String, fresh: bool) -> void:
	_transition(func(): _show_game(id, fresh))


func go_menu() -> void:
	_transition(func(): _show_menu())


func _transition(cb: Callable) -> void:
	if _busy:
		return
	_busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(func():
		cb.call()
	)
	tw.tween_interval(0.05)
	tw.tween_property(fade, "color:a", 0.0, 0.4)
	tw.tween_callback(func():
		_busy = false
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if current and current.has_method("on_back"):
				current.on_back()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if current is GameScreen:
				(current as GameScreen).save_now()
			get_tree().quit()
