class_name GameScreen
extends Node
## In-game screen: map, HUD, building, panels, simulation loop.

signal exit_to_menu

const SPEEDS := [0.0, 1.0, 2.0, 4.0]
const AUTOSAVE_SEC := 30.0

var state: GameState
var world: WorldView
var ui_layer: CanvasLayer
var root_ui: Control
var toast: Toast
var panels: GamePanels

# HUD
var hud: VBoxContainer
var date_label: Label
var month_bar: ProgressBar
var cash_label: Label
var riders_label: Label
var sat_label: Label
var sat_icon: Icon
var speed_buttons: Array[Button] = []
var nav: PanelContainer
var build_bar: PanelContainer
var build_hint: Label
var build_cost_label: Label
var build_info_label: Label
var depth_button: Button
var finish_button: Button
var fps_label: Label
var tutorial_panel: PanelContainer
var social_badge: Label
var ach_banner: AchievementBanner
var mission_chip: Button
var mission_label: Label
var mission_bar: ProgressBar
var _pending_decision := {}
var _shake := 0.0
var day_icon: Icon
var snow: SnowOverlay
var _amb_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _last_viral_toast := -100000

var speed_idx := 1
var modal_count := 0
var sheet: Sheet
var build_mode := ""
var build_deep := false
var draft_nodes: Array = []
var draft_extend := -1
var draft_at_start := false
var draft_eval := {}
var draft_nodes_committed: Array = []
var overlay := "none"
var _hud_timer := 0.0
var _autosave := 0.0
var _last_riders := 0.0
var _gesture_on_ui := false


func setup(s: GameState) -> void:
	state = s


func _ready() -> void:
	world = WorldView.new()
	add_child(world)
	world.setup(state)
	world.camera.tapped.connect(_on_tap)
	world.camera.long_pressed.connect(_on_long_press)
	panels = GamePanels.new(self)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root_ui)
	_build_hud()
	_build_nav()
	_build_build_bar()
	toast = Toast.new()
	root_ui.add_child(toast)
	fps_label = UI.label("", 20, Palette.MUTED)
	fps_label.position = Vector2(12, 240)
	root_ui.add_child(fps_label)

	snow = SnowOverlay.new()
	root_ui.add_child(snow)
	root_ui.move_child(snow, 0)
	_rng.randomize()
	state.event_started.connect(_on_city_event)
	state.tech_completed.connect(_on_tech_done)
	state.mgmt.dilemma_raised.connect(_on_dilemma)
	state.mgmt.incident_started.connect(_on_incident)
	state.mgmt.mission_changed.connect(_update_mission_chip)
	state.mgmt.mission_result.connect(_on_mission_result)
	state.mgmt.earthquake.connect(_on_quake)
	ach_banner = AchievementBanner.new()
	root_ui.add_child(ach_banner)
	state.feed.post_added.connect(_on_post)
	if state.feed.posts.is_empty():
		state.feed.post("no_network", {}, state, "citizen")
		state.feed.post("no_network", {}, state, "citizen")
	_update_badge()
	_update_mission_chip()
	state.year_ended.connect(_on_year_ended)
	state.goals_changed.connect(_on_goals_changed)
	state.bankrupt.connect(_on_bankrupt)
	state.month_passed.connect(_on_month)
	state.cash_changed.connect(_update_hud)
	state.ridership_updated.connect(_on_ridership)
	state.recompute_if_dirty()
	state.async_demand = true
	_last_riders = state.riders
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	_update_hud()
	_set_speed(1)
	_focus_initial()
	if state.tutorial_step < 6 and not SaveManager.progress.get("tutorial_done", false):
		call_deferred("_show_tutorial")
	if state.game_over:
		call_deferred("_on_bankrupt")


func _focus_initial() -> void:
	if state.net.stations.is_empty():
		var z: Dictionary = state.city.zones[0]
		world.camera.position = z["pos"] * MapLayer.PX
		var zz := clampf(world.camera.min_zoom * 2.6, world.camera.min_zoom, world.camera.max_zoom)
		world.camera.zoom = Vector2(zz, zz)
	else:
		var c := Vector2.ZERO
		for s in state.net.stations.values():
			c += s["pos"]
		c /= state.net.stations.size()
		world.camera.position = c * MapLayer.PX
		var zz := clampf(world.camera.min_zoom * 2.0, world.camera.min_zoom, world.camera.max_zoom)
		world.camera.zoom = Vector2(zz, zz)
	world._on_zoom(world.camera.zoom.x)


# ======================================================================== HUD

func _build_hud() -> void:
	hud = UI.vbox(10)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(hud)
	var row1 := UI.hbox(10)
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(row1)
	var menu_b := UI.icon_button("menu", 76, "AccentButton", Palette.INK)
	menu_b.pressed.connect(open_pause_menu)
	row1.add_child(menu_b)
	# date chip
	var date_chip := PanelContainer.new()
	date_chip.add_theme_stylebox_override("panel", _board_box())
	date_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dv := UI.vbox(4)
	var dh := UI.hbox(8)
	day_icon = Icon.make("sun", 28, Palette.LED)
	day_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dh.add_child(day_icon)
	date_label = _led_label(26)
	dh.add_child(date_label)
	dv.add_child(dh)
	month_bar = UI.progress(0.0, Palette.LED, 5.0)
	dv.add_child(month_bar)
	date_chip.add_child(dv)
	row1.add_child(date_chip)
	# speed control
	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", _board_box(6))
	var sh := UI.hbox(2)
	for i in 4:
		var kind: String = ["pause", "play", "ff", "fff"][i]
		var b := UI.icon_button(kind, 60, "FlatButton", Palette.TEXT)
		b.pressed.connect(_set_speed.bind(i))
		sh.add_child(b)
		speed_buttons.append(b)
	sp.add_child(sh)
	row1.add_child(sp)
	# stats row
	var row2 := UI.hbox(10)
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(row2)
	cash_label = _stat_chip(row2, "coin", Palette.ACCENT, func(): open_finance())
	riders_label = _stat_chip(row2, "people", Palette.INFO, func(): open_finance())
	var sat_chip := _stat_chip(row2, "smile", Palette.GOOD, func(): open_goals())
	sat_label = sat_chip
	sat_icon = sat_chip.get_meta("icon")
	# active mission strip
	mission_chip = Button.new()
	mission_chip.focus_mode = Control.FOCUS_NONE
	mission_chip.custom_minimum_size.y = 58
	var mst := ThemeBuilder.box(Color(0.11, 0.16, 0.27, 0.94), 20, 1, Color(Palette.INFO, 0.5), 12, 6, 6)
	mission_chip.add_theme_stylebox_override("normal", mst)
	mission_chip.add_theme_stylebox_override("hover", mst)
	mission_chip.add_theme_stylebox_override("pressed", mst)
	mission_chip.pressed.connect(func(): open_goals())
	var mh := UI.hbox(10)
	mh.set_anchors_preset(Control.PRESET_FULL_RECT)
	mh.offset_left = 14
	mh.offset_right = -14
	mh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mic := Icon.make("target", 28, Palette.INFO)
	mic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mh.add_child(mic)
	var mv := UI.vbox(3)
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.alignment = BoxContainer.ALIGNMENT_CENTER
	mission_label = UI.label("", 20, Palette.TEXT, 800)
	mission_label.clip_text = true
	mission_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mv.add_child(mission_label)
	mission_bar = UI.progress(0.0, Palette.INFO, 6.0)
	mv.add_child(mission_bar)
	mh.add_child(mv)
	mission_chip.add_child(mh)
	mission_chip.visible = false
	hud.add_child(mission_chip)


## Departure-board panel: near-black with a bezel.
func _board_box(pad: int = 12) -> StyleBoxFlat:
	var b := ThemeBuilder.box(Palette.BOARD, 16, 3, Color("2a3142"), pad, 6, 8)
	b.border_width_bottom = 5
	b.border_color = Color("232a39")
	return b


func _led_label(size: int) -> Label:
	var l := UI.label("", size, Palette.LED)
	l.add_theme_font_override("font", ThemeBuilder.led(850))
	l.add_theme_color_override("font_outline_color", Color(1.0, 0.6, 0.05, 0.25))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _stat_chip(parent: Control, icon_kind: String, col: Color, cb: Callable) -> Label:
	var chip := Button.new()
	chip.focus_mode = Control.FOCUS_NONE
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.custom_minimum_size.y = 62
	var st := _board_box()
	chip.add_theme_stylebox_override("normal", st)
	chip.add_theme_stylebox_override("hover", st)
	var stp := _board_box()
	stp.bg_color = Color("161c28")
	chip.add_theme_stylebox_override("pressed", stp)
	chip.pressed.connect(cb)
	var h := UI.hbox(8)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Icon.make(icon_kind, 30, col)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := _led_label(27)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	h.add_child(l)
	chip.add_child(h)
	parent.add_child(chip)
	l.set_meta("icon", ic)
	return l


var nav_roundels: Array = []
var nav_active := -1


## Bottom navigation drawn as a metro line: each tab is a station roundel.
class RouteLine:
	extends Control
	var roundels: Array = []
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if roundels.size() < 2:
			return
		var pts := PackedVector2Array()
		for r in roundels:
			var c: Control = r
			pts.append(c.get_global_rect().get_center() - get_global_rect().position)
		var y := pts[0].y
		draw_line(Vector2(pts[0].x, y), Vector2(pts[pts.size() - 1].x, y), Palette.INK, 16.0, true)
		var n := pts.size() - 1
		for i in n:
			var col: Color = Palette.STRIPES[i % Palette.STRIPES.size()]
			draw_line(Vector2(pts[i].x, y), Vector2(pts[i + 1].x, y), col, 8.0, true)


func _build_nav() -> void:
	nav = PanelContainer.new()
	var nsb := ThemeBuilder.box(Color(0.07, 0.11, 0.19, 0.97), 30, 2, Palette.STROKE, 8, 10, 14)
	nsb.border_width_bottom = 6
	nsb.border_color = Color(0.03, 0.05, 0.1, 1)
	nav.add_theme_stylebox_override("panel", nsb)
	root_ui.add_child(nav)
	var route := RouteLine.new()
	nav.add_child(route)
	var h := UI.hbox(0)
	nav.add_child(h)
	nav_roundels.clear()
	var items := [
		["build", "tab_build", func(): open_build_menu()],
		["lines", "tab_lines", func(): open_lines()],
		["layers", "tab_map", func(): open_layers()],
		["target", "tab_goals", func(): open_goals()],
		["chart", "tab_finance", func(): open_finance()],
		["bird", "tab_social", func(): open_social()],
		["flask", "tab_tech", func(): open_tech()],
	]
	for idx in items.size():
		var it: Array = items[idx]
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(64, 108)
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover_pressed", StyleBoxEmpty.new())
		var v := UI.vbox(4)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var roundel := PanelContainer.new()
		roundel.custom_minimum_size = Vector2(60, 60)
		roundel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		roundel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := Icon.make(it[0], 32, Palette.INK)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		roundel.add_child(ic)
		roundel.set_meta("icon", ic)
		v.add_child(roundel)
		var l := UI.label(I18n.t(it[1]), 17, Palette.MUTED, 800)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", ThemeBuilder.display(700))
		roundel.set_meta("label", l)
		v.add_child(l)
		b.add_child(v)
		nav_roundels.append(roundel)
		if it[0] == "bird":
			social_badge = UI.label("", 17, Color.WHITE, 900)
			social_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			social_badge.add_theme_stylebox_override("normal", ThemeBuilder.box(Palette.BAD, 14, 2, Palette.INK, 7, 1))
			social_badge.position = Vector2(40, 0)
			b.add_child(social_badge)
		var cb: Callable = it[2]
		b.button_down.connect(func(): UI.pop_in(roundel, 0.85))
		b.pressed.connect(func():
			Audio.play("tap")
			Settings.vibrate(8)
			cb.call()
		)
		h.add_child(b)
	route.roundels = nav_roundels
	_set_nav(nav_active)


func _set_nav(idx: int) -> void:
	nav_active = idx
	for i in nav_roundels.size():
		var r: PanelContainer = nav_roundels[i]
		var active := i == idx
		var col: Color = Palette.STRIPES[mini(i, Palette.STRIPES.size() - 1)] if i < 4 else Palette.STRIPES[i % 4]
		var sb := ThemeBuilder.box(Palette.ACCENT if active else Palette.CREAM, 30, 5, Palette.INK if not active else Palette.CREAM, 0, 0)
		if i == 0 and not active:
			sb.bg_color = Palette.CREAM
			sb.border_color = Palette.BAD
		r.add_theme_stylebox_override("panel", sb)
		var ic: Icon = r.get_meta("icon")
		ic.set_color(Palette.INK)
		var l: Label = r.get_meta("label")
		l.add_theme_color_override("font_color", Palette.ACCENT if active else Palette.MUTED)
		r.scale = Vector2.ONE * (1.12 if active else 1.0)
		r.pivot_offset = Vector2(30, 30)
		col = col


func _build_build_bar() -> void:
	build_bar = PanelContainer.new()
	build_bar.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(0.09, 0.12, 0.18, 0.97), 32, 2, Color(Palette.ACCENT, 0.5), 20, 16, 12))
	build_bar.visible = false
	root_ui.add_child(build_bar)
	var v := UI.vbox(12)
	build_bar.add_child(v)
	var stripe := Deco.LineStripe.new()
	stripe.thickness = 6.0
	stripe.custom_minimum_size = Vector2(160, 14)
	stripe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stripe)
	build_hint = UI.wrap_label("", 23, Palette.MUTED)
	v.add_child(build_hint)
	var info := UI.hbox(12)
	build_info_label = UI.label("", 24, Palette.TEXT, 800)
	build_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_info_label.clip_text = true
	info.add_child(build_info_label)
	var cost_board := PanelContainer.new()
	cost_board.add_theme_stylebox_override("panel", _board_box(14))
	build_cost_label = _led_label(30)
	cost_board.add_child(build_cost_label)
	info.add_child(cost_board)
	v.add_child(info)
	var row := UI.hbox(10)
	var cancel := UI.icon_button("close", 80, "", Palette.BAD)
	cancel.pressed.connect(cancel_build)
	row.add_child(cancel)
	var undo := UI.icon_button("undo", 80, "", Palette.TEXT)
	undo.pressed.connect(undo_draft)
	row.add_child(undo)
	depth_button = UI.button(I18n.t("depth_shallow"), "", "", 80)
	depth_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	depth_button.clip_text = true
	depth_button.pressed.connect(_toggle_depth)
	row.add_child(depth_button)
	finish_button = UI.button(I18n.t("finish"), "AccentButton", "check", 80)
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.pressed.connect(finish_build)
	row.add_child(finish_button)
	v.add_child(row)


func _on_resize() -> void:
	var vs := root_ui.get_viewport_rect().size
	var safe := SafeArea.margins(root_ui)
	var side := 16.0
	var w := minf(vs.x - side * 2.0 - safe.x - safe.z, 900.0)
	hud.position = Vector2((vs.x - w) * 0.5, 14.0 + safe.y)
	hud.size = Vector2(w, 0)
	hud.custom_minimum_size.x = w
	var nav_w := minf(vs.x - side * 2.0 - safe.x - safe.z, 760.0)
	nav.custom_minimum_size.x = nav_w
	nav.reset_size()
	nav.position = Vector2((vs.x - nav_w) * 0.5, vs.y - nav.size.y - 14.0 - safe.w)
	build_bar.custom_minimum_size.x = nav_w
	build_bar.reset_size()
	build_bar.position = Vector2((vs.x - nav_w) * 0.5, vs.y - build_bar.size.y - 14.0 - safe.w)
	if toast:
		toast.bottom_offset = vs.y - minf(nav.position.y, build_bar.position.y if build_bar.visible else nav.position.y) + 16.0
		toast._layout()
	if tutorial_panel:
		_layout_tutorial()


func _update_hud() -> void:
	if date_label == null:
		return
	date_label.text = "%s %d" % [I18n.month_name(state.month), state.year]
	cash_label.text = "∞" if state.sandbox else Geo.fmt_money(state.cash)
	cash_label.add_theme_color_override("font_color", Palette.BAD if state.cash < 0 else Palette.TEXT)
	var trend := ""
	if state.target_riders > state.riders * 1.02:
		trend = " ↑"
	elif state.target_riders < state.riders * 0.98:
		trend = " ↓"
	riders_label.text = Geo.fmt_short(state.riders) + trend
	var sat := state.demand.satisfaction
	sat_label.text = "%d%%" % int(round(sat))
	var sc := Palette.GOOD if sat >= 65 else (Palette.WARN if sat >= 40 else Palette.BAD)
	sat_icon.set_color(sc)


func _set_speed(i: int) -> void:
	speed_idx = i
	for k in speed_buttons.size():
		var b := speed_buttons[k]
		var active := k == i
		var ic: Icon = b.get_meta("icon")
		ic.set_color(Palette.ACCENT if active else Palette.MUTED)
		b.add_theme_stylebox_override("normal", ThemeBuilder.box(Color(1, 1, 1, 0.1) if active else Color(0, 0, 0, 0), 18, 0, Color.TRANSPARENT, 6, 6))


func current_speed() -> float:
	if modal_count > 0 or state.game_over:
		return 0.0
	return SPEEDS[speed_idx]


func _process(delta: float) -> void:
	var sp := current_speed()
	state.advance(delta, sp)
	world.advance_day(delta, sp)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		world.camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 26.0 * _shake / world.camera.zoom.x
	elif world.camera.offset != Vector2.ZERO:
		world.camera.offset = Vector2.ZERO
	world.vehicles.speed = sp if sp > 0.0 else 0.0
	_hud_timer += delta
	if _hud_timer > 0.25:
		_hud_timer = 0.0
		month_bar.value = state.month_progress
		date_label.text = "%s %d · %s" % [I18n.month_name(state.month), state.year, world.clock_text()]
		var night := world.is_night()
		if day_icon.kind != ("moon" if night else "sun"):
			day_icon.set_kind("moon" if night else "sun")
			day_icon.set_color(Color("bcd4ff") if night else Palette.ACCENT)
		if Settings.show_fps:
			fps_label.text = "%d FPS" % Engine.get_frames_per_second()
		fps_label.visible = Settings.show_fps
	_amb_timer += delta
	if _amb_timer > 0.5:
		_update_ambience(_amb_timer)
		_amb_timer = 0.0
	_autosave += delta
	if _autosave > AUTOSAVE_SEC:
		_autosave = 0.0
		save_now()


func _view_rect() -> Rect2:
	var vs := root_ui.get_viewport_rect().size / world.camera.zoom.x
	return Rect2(world.camera.position - vs * 0.5, vs)


## City soundscape: sea & gulls where the camera looks at water, traffic hum over land,
## steppe wind in the Ankara winter, the odd ferry horn and tram bell.
func _update_ambience(dt: float) -> void:
	var r := _view_rect()
	var water := 0
	var total := 0
	for i in 5:
		for j in 5:
			var p := (r.position + r.size * Vector2((i + 0.5) / 5.0, (j + 0.5) / 5.0)) / MapLayer.PX
			if state.city.in_bounds(p):
				total += 1
				if state.city.is_sea(p):
					water += 1
	var wf := float(water) / maxi(1, total)
	var close := clampf((world.camera.zoom.x - world.camera.min_zoom) / 0.4, 0.0, 1.0)
	var f := CityEvents.flavor(state.city)
	var amb: Array = f.get("ambience", [])
	var levels := {}
	if amb.has("sea"):
		levels["sea_loop"] = wf * (0.35 + 0.5 * close)
	if amb.has("city"):
		levels["city_loop"] = (1.0 - wf) * (0.12 + 0.3 * close)
	if state.is_snowing() or (state.city_id == "ankara" and CityEvents.is_winter(state.city, state.month)):
		levels["wind_loop"] = 0.55 if state.has_event("snow_storm") else 0.3
	Audio.set_ambience(levels)
	var paused := current_speed() <= 0.0
	# gulls
	var gulls := world.flavor.birds_in(r)
	if gulls > 0 and not paused and _rng.randf() < dt * (0.15 + 0.05 * gulls):
		Audio.ambience_shot("gull_%d" % (1 + _rng.randi() % 6), clampf(0.25 + 0.6 * close, 0.0, 0.85), _rng.randf_range(0.9, 1.12))
	if not paused:
		var modes := state.net.modes_in_use()
		if f.get("ferry_horn", false) and modes.has("ferry") and wf > 0.1 and _rng.randf() < dt * 0.025:
			Audio.ambience_shot("ferry_horn", 0.35 + 0.4 * close)
		if modes.has("tram") and close > 0.45 and _rng.randf() < dt * 0.03:
			Audio.ambience_shot("tram_bell", 0.4 * close)
	# snow
	var target := 0.0
	if state.has_event("snow_storm"):
		target = 1.0
	elif state.is_snowing():
		target = 0.4
	snow.intensity = lerpf(snow.intensity, target, 0.3)


func _exit_tree() -> void:
	Audio.stop_ambience()


func save_now() -> void:
	state.flush_demand()
	SaveManager.save_game(state)


# ======================================================================== input

func _unhandled_input(event: InputEvent) -> void:
	if modal_count > 0:
		return
	if event is InputEventScreenTouch and event.pressed and event.index == 0:
		_gesture_on_ui = _is_over_ui(event.position)
	if event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		_gesture_on_ui = _is_over_ui(event.position)
	if _gesture_on_ui and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse):
		if event is InputEventScreenTouch and not event.pressed:
			_gesture_on_ui = false
		if event is InputEventMouseButton and not event.pressed:
			_gesture_on_ui = false
		return
	if world.camera.handle_input(event):
		get_viewport().set_input_as_handled()


func _is_over_ui(p: Vector2) -> bool:
	var blockers: Array = [hud, nav if nav.visible else null, build_bar if build_bar.visible else null, tutorial_panel]
	if is_instance_valid(sheet):
		blockers.append(sheet.panel)
	for b in blockers:
		if b != null and is_instance_valid(b) and b.is_visible_in_tree():
			if b == hud:
				for c in hud.get_children():
					for cc in c.get_children():
						if cc is Control and (cc as Control).get_global_rect().has_point(p):
							return true
			elif (b as Control).get_global_rect().has_point(p):
				return true
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state:
			save_now()


func on_back() -> void:
	if modal_count > 0:
		return
	if build_mode != "":
		cancel_build()
	elif is_instance_valid(sheet):
		sheet.close()
	else:
		open_pause_menu()


func _on_tap(world_pos: Vector2, _screen: Vector2) -> void:
	if build_mode != "":
		_build_tap(world_pos)
		return
	var zoom := world.camera.zoom.x
	var sid := world.network.pick_station(world_pos, 34.0 / zoom)
	if sid >= 0:
		open_station(sid)
		return
	var lid := world.network.pick_line(world_pos, 22.0 / zoom)
	if lid >= 0:
		open_line(lid)
		return
	select_line(-1)
	world.network.selected_station = -1
	world.network.queue_redraw()
	if is_instance_valid(sheet):
		sheet.close()


func _on_long_press(world_pos: Vector2, _screen: Vector2) -> void:
	if build_mode != "":
		return
	var zoom := world.camera.zoom.x
	var sid := world.network.pick_station(world_pos, 34.0 / zoom)
	if sid >= 0:
		Settings.vibrate(25)
		open_station(sid)


func select_line(lid: int) -> void:
	world.network.selected_line = lid
	world.network.queue_redraw()


# ======================================================================== sheets / modals

func show_sheet(s: Sheet) -> void:
	if is_instance_valid(sheet):
		sheet.queue_free()
	sheet = s
	s.side_top = hud.position.y + hud.get_combined_minimum_size().y + 12.0
	root_ui.add_child(s)
	s.closed.connect(func():
		if sheet == s:
			_set_nav(-1)
			sheet = null
			if build_mode == "":
				select_line(-1)
				world.network.selected_station = -1
	)
	# keep toasts above
	root_ui.move_child(toast, -1)


func show_modal(m: Control) -> void:
	modal_count += 1
	ui_layer.add_child(m)
	m.tree_exited.connect(func(): modal_count = maxi(0, modal_count - 1))
	world.camera.reset_touches()


func open_build_menu() -> void:
	if build_mode != "":
		return
	show_sheet(panels.build_sheet())
	_set_nav(0)
	_tutorial_event("build_menu")


func open_lines() -> void:
	show_sheet(panels.lines_sheet())
	_set_nav(1)


func open_line(lid: int) -> void:
	if not state.net.lines.has(lid):
		return
	select_line(lid)
	world.network.selected_station = -1
	show_sheet(panels.line_sheet(lid))


func open_station(sid: int) -> void:
	world.network.selected_station = sid
	select_line(-1)
	show_sheet(panels.station_sheet(sid))


func open_goals() -> void:
	show_sheet(panels.goals_sheet())
	_set_nav(3)


func open_finance() -> void:
	show_sheet(panels.finance_sheet())
	_set_nav(4)


func open_social() -> void:
	show_sheet(panels.social_sheet())
	_update_badge()
	_set_nav(5)


func _update_badge() -> void:
	if social_badge == null or not is_instance_valid(social_badge):
		return
	var n := state.feed.unread
	social_badge.visible = n > 0
	social_badge.text = str(mini(n, 99))


func _on_post(p: Dictionary) -> void:
	if is_instance_valid(sheet) and sheet.title_label and is_instance_valid(sheet.title_label) and sheet.title_label.text == I18n.t("social_title"):
		state.feed.unread = 0
		_refresh_live_sheet()
	_update_badge()
	if p.get("viral", false) and float(p["sent"]) > 0.5:
		check_achievements({"viral": true})
	if p.get("viral", false) and Time.get_ticks_msec() - _last_viral_toast > 15000:
		_last_viral_toast = Time.get_ticks_msec()
		var txt := state.feed.text_of(p)
		if txt.length() > 90:
			txt = txt.substr(0, 88) + "…"
		toast.show_msg("@%s: %s" % [p["who"]["handle"], txt], "social", 4.0)


func _on_dilemma(ev: Dictionary) -> void:
	# wait for other modals; show when free
	_pending_decision = ev
	call_deferred("_try_show_decision")


func _try_show_decision() -> void:
	if _pending_decision.is_empty() or state.mgmt.pending.is_empty():
		return
	if modal_count > 0 or build_mode != "":
		get_tree().create_timer(1.0).timeout.connect(_try_show_decision)
		return
	var ev := _pending_decision
	_pending_decision = {}
	Audio.play("chime")
	Settings.vibrate(30)
	show_modal(panels.decision_modal(ev))


func on_decision_done(result: String) -> void:
	if result != "":
		toast.show_msg(result, "info", 4.0)
	if not state.mgmt.mission.is_empty() and state.mgmt.mission.get("_announced", false) == false:
		state.mgmt.mission["_announced"] = true
		toast.show_msg(I18n.t("mission_started") % state.mgmt.mission_text(state), "info", 4.5)
	state.recompute_if_dirty()
	_update_hud()
	_update_mission_chip()
	world.network.rebuild()
	_refresh_live_sheet()


func _on_incident(lid: int, kind: String) -> void:
	if not state.net.lines.has(lid):
		return
	var l: Dictionary = state.net.lines[lid]
	toast.show_msg(I18n.t("incident_toast") % [I18n.t("incident_" + kind), l["name"], int(l["incident"]["months"])], "error", 4.0)
	Audio.play("error")
	world.network.rebuild()


func _on_quake(minor: bool) -> void:
	_shake = 1.6 if not minor else 0.9
	Settings.vibrate(400)
	toast.show_msg(I18n.t("quake_minor_toast" if minor else "quake_major_toast"), "good" if minor else "error", 5.0)
	world.network.rebuild()


func _update_mission_chip() -> void:
	if mission_chip == null:
		return
	var mg := state.mgmt
	mission_chip.visible = not mg.mission.is_empty()
	if mission_chip.visible:
		mission_label.text = "%s · %d %s" % [mg.mission_text(state), int(mg.mission["months"]), I18n.t("months_short")]
		mission_bar.value = mg.mission_progress(state)
	if tutorial_panel:
		_layout_tutorial()


func _on_mission_result(ok: bool, m: Dictionary) -> void:
	if ok:
		toast.show_msg(I18n.t("mission_ok_toast") % Geo.fmt_money(m["reward"]), "star", 4.5)
		Audio.play("goal")
	else:
		toast.show_msg(I18n.t("mission_fail_toast"), "error", 4.0)
		Audio.play("error")
	_update_hud()


func _on_city_event(eid: String) -> void:
	toast.show_msg(I18n.t("event_" + eid), "info", 4.5)
	Audio.play("chime", 1.0, -6.0)
	world.labels.queue_redraw()


func open_tech() -> void:
	show_sheet(panels.tech_sheet())
	_set_nav(6)


func _on_tech_done(id: String) -> void:
	toast.show_msg(I18n.t("tech_complete") % I18n.t("tech_" + id), "good", 4.0)
	Audio.play("goal")
	_refresh_live_sheet()
	_update_hud()
	check_achievements()


func check_achievements(flags: Dictionary = {}) -> void:
	for id in Achievements.check(state, flags):
		ach_banner.push(id)


func open_layers() -> void:
	show_sheet(panels.layers_sheet())
	_set_nav(2)


func set_overlay(kind: String) -> void:
	overlay = kind
	world.map.set_overlay(kind)
	world.labels.dim = kind != "none"
	world.labels.queue_redraw()


func open_pause_menu() -> void:
	var m := Modal.create(I18n.t("paused"), 560.0)
	var add := func(text: String, variation: String, icon: String, cb: Callable):
		var b := UI.button(text, variation, icon)
		b.pressed.connect(cb)
		m.body.add_child(b)
	add.call(I18n.t("resume"), "AccentButton", "play", m.close)
	add.call(I18n.t("settings"), "", "gear", func():
		SettingsPanel.open(m, func(): _refresh_language())
	)
	add.call(I18n.t("timelapse"), "", "calendar", func():
		m.close()
		show_modal(panels.timelapse_modal())
	)
	add.call(I18n.t("achievements"), "", "trophy", func():
		var am := AchievementBanner.open_list(ui_layer)
		modal_count += 1
		am.tree_exited.connect(func(): modal_count = maxi(0, modal_count - 1))
	)
	add.call(I18n.t("how_to_play"), "", "info", func(): show_help())
	add.call(I18n.t("save_quit"), "", "home", func():
		save_now()
		m.close()
		exit_to_menu.emit()
	)
	show_modal(m)


func show_help() -> void:
	var m := Modal.create(I18n.t("how_to_play"), 700.0)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(820.0, root_ui.get_viewport_rect().size.y * 0.62))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var l := UI.wrap_label(I18n.t("htp_body"), 25, Palette.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(l)
	m.body.add_child(sc)
	var ok := UI.button(I18n.t("ok"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	show_modal(m)


func _refresh_language() -> void:
	# rebuild UI texts
	UI.clear(nav)
	nav.queue_free()
	_build_nav()
	build_bar.queue_free()
	_build_build_bar()
	_on_resize()
	_update_hud()
	world.labels.queue_redraw()
	world.network.queue_redraw()


# ======================================================================== building

func start_build(mode: String) -> void:
	if is_instance_valid(sheet):
		sheet.close()
	build_mode = mode
	build_deep = false
	draft_nodes = []
	draft_extend = -1
	draft_eval = {}
	nav.visible = false
	build_bar.visible = true
	depth_button.visible = TransitModes.get_mode(mode)["underground"]
	world.network.highlight_ends_mode = mode
	select_line(-1)
	_update_build_ui()
	call_deferred("_on_resize")
	_tutorial_event("build_start")


func start_extend(lid: int, at_start: bool) -> void:
	var l: Dictionary = state.net.lines[lid]
	start_build(l["mode"])
	build_deep = l.get("deep", false)
	draft_extend = lid
	draft_at_start = at_start
	var st: Array = l["stations"]
	var sid: int = st[0] if at_start else st[st.size() - 1]
	draft_nodes = [{"pos": state.net.stations[sid]["pos"], "sid": sid}]
	world.focus_km(state.net.stations[sid]["pos"])
	_refresh_draft()
	toast.show_msg(I18n.t("extending") % l["name"])


func cancel_build() -> void:
	build_mode = ""
	draft_nodes = []
	draft_extend = -1
	world.draft.clear()
	world.network.highlight_ends_mode = ""
	world.network.queue_redraw()
	build_bar.visible = false
	nav.visible = true
	Audio.play("undo")
	call_deferred("_on_resize")


func undo_draft() -> void:
	if draft_nodes.is_empty():
		cancel_build()
		return
	draft_nodes.pop_back()
	if draft_nodes.is_empty():
		draft_extend = -1
	elif draft_nodes.size() == 1 and draft_extend >= 0:
		pass
	Audio.play("undo")
	_refresh_draft()


func _toggle_depth() -> void:
	if draft_extend >= 0:
		toast.show_msg(I18n.t("depth_hint"))
		return
	build_deep = not build_deep
	_refresh_draft()


func _build_tap(world_pos: Vector2) -> void:
	var p := world_pos / MapLayer.PX
	var zoom := world.camera.zoom.x
	var sid := world.network.pick_station(world_pos, 34.0 / zoom)
	var mode := build_mode
	if draft_nodes.is_empty():
		if sid >= 0:
			var end := state.net.line_end_at(sid, mode)
			if not end.is_empty():
				start_extend(end["line_id"], end["at_start"])
				return
			draft_nodes.append({"pos": state.net.stations[sid]["pos"], "sid": sid})
		else:
			var err := state.net.station_site_error(mode, p)
			if err != "":
				_error(err)
				return
			draft_nodes.append({"pos": p, "sid": -1})
		Audio.play("place")
		Settings.vibrate(10)
		_refresh_draft()
		_tutorial_event("first_stop")
		return
	var node := {"pos": p, "sid": -1}
	if sid >= 0:
		node = {"pos": state.net.stations[sid]["pos"], "sid": sid}
		if sid == draft_nodes[draft_nodes.size() - 1]["sid"]:
			return
		var first_sid: int = draft_nodes[0]["sid"]
		var closes_loop := false
		if draft_extend < 0:
			closes_loop = sid == first_sid and draft_nodes.size() >= 3
		else:
			var st: Array = state.net.lines[draft_extend]["stations"]
			var other: int = st[st.size() - 1] if draft_at_start else st[0]
			closes_loop = sid == other and st.size() + draft_nodes.size() >= 4
			if not closes_loop and st.has(sid):
				_error(I18n.t("err_same_station"))
				return
		if not closes_loop:
			for n in draft_nodes:
				if n["sid"] == sid:
					_error(I18n.t("err_same_station"))
					return
	else:
		var err := state.net.station_site_error(mode, p)
		if err != "":
			_error(err)
			return
	var last: Dictionary = draft_nodes[draft_nodes.size() - 1]
	var seg := state.net.evaluate_segment(mode, build_deep, last["pos"], node["pos"])
	if not seg["ok"]:
		_error(seg["reason"])
		return
	draft_nodes.append(node)
	var ev := state.net.evaluate_draft(mode, build_deep, draft_nodes, draft_extend)
	if not ev["ok"]:
		draft_nodes.pop_back()
		_error(ev["reason"])
		return
	Audio.play("place", 1.0 + minf(draft_nodes.size(), 10) * 0.03)
	Settings.vibrate(10)
	_refresh_draft()


func _error(msg: String) -> void:
	toast.show_msg(msg, "error")
	Audio.play("error")
	Settings.vibrate(30)


func _refresh_draft() -> void:
	var col: Color
	if draft_extend >= 0:
		col = state.net.line_color(state.net.lines[draft_extend])
	else:
		col = TransitModes.LINE_COLORS[state.net.next_color_index()]
	draft_eval = state.net.evaluate_draft(build_mode, build_deep, draft_nodes, draft_extend) if draft_nodes.size() > 0 else {}
	world.draft.set_draft(draft_nodes, draft_eval, build_mode, col)
	_update_build_ui()


func _update_build_ui() -> void:
	var m := TransitModes.get_mode(build_mode)
	var name := I18n.t(m["name_key"])
	if draft_nodes.is_empty():
		build_hint.text = I18n.t("build_hint_first") + "\n" + I18n.t("build_hint_extend")
	else:
		build_hint.text = I18n.t("build_hint_next")
	var cost: float = draft_eval.get("cost", 0.0)
	var length: float = draft_eval.get("length", 0.0)
	var n := draft_nodes.size()
	build_info_label.text = "%s · %d %s · %.1f km" % [name, n, I18n.t("stations"), length]
	build_cost_label.text = Geo.fmt_money(cost)
	build_cost_label.add_theme_color_override("font_color", Palette.LED if state.can_afford(cost) else Palette.BAD)
	depth_button.text = I18n.t("depth_deep_short") if build_deep else I18n.t("depth_shallow_short")
	depth_button.add_theme_color_override("font_color", Palette.INFO if build_deep else Palette.TEXT)
	finish_button.disabled = n < 2


func finish_build() -> void:
	if draft_nodes.size() < 2:
		_error(I18n.t("need_two_stops"))
		return
	var ev := state.net.evaluate_draft(build_mode, build_deep, draft_nodes, draft_extend)
	if not ev["ok"]:
		_error(ev["reason"])
		return
	var cost: float = ev["cost"]
	if not state.spend(cost):
		_error(I18n.t("not_enough_cash"))
		return
	var extending := draft_extend >= 0
	draft_nodes_committed = []
	for n in draft_nodes:
		if n["sid"] < 0:
			draft_nodes_committed.append(n["pos"])
	var lid := state.net.commit_draft(build_mode, build_deep, draft_nodes, cost, draft_extend, draft_at_start, ev.get("vehicles", 0))
	var lname: String = state.net.lines[lid]["name"]
	state.log_line(lid)
	_check_archaeology(lid, cost)
	state.feed.on_line_opened(state, lid, extending)
	Audio.play("build")
	Settings.vibrate(40)
	toast.show_msg((I18n.t("line_extended") if extending else I18n.t("line_built")) % lname, "good")
	cancel_build()
	state.recompute_if_dirty()
	state.check_goals()
	_update_hud()
	select_line(lid)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		if world.network.selected_line == lid and not is_instance_valid(sheet):
			select_line(-1)
	)
	_tutorial_event("line_built")
	check_achievements()
	save_now()


# ======================================================================== events

## Istanbul's historic peninsula: underground works may hit archaeological finds.
func _check_archaeology(lid: int, cost: float) -> void:
	var l: Dictionary = state.net.lines[lid]
	if not TransitModes.get_mode(l["mode"])["underground"]:
		return
	var hit := false
	for n in draft_nodes_committed:
		if CityEvents.in_historic_zone(state.city, n):
			hit = true
			break
	if not hit or _rng.randf() > 0.45:
		return
	var extra := maxf(60.0, cost * 0.18)
	state.cash -= extra
	state.year_capex += extra
	state.cash_changed.emit()
	state.feed.on_archaeology(state, lid)
	check_achievements({"archaeology": true})
	var m := Modal.create(I18n.t("archaeology_title"), 620.0)
	m.body.add_child(Icon.make("info", 64, Palette.ACCENT))
	var lb := UI.wrap_label(I18n.t("archaeology_body") % [l["name"], Geo.fmt_money(extra)], 25, Palette.TEXT)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(lb)
	var ok := UI.button(I18n.t("ok"), "AccentButton")
	ok.pressed.connect(m.close)
	m.body.add_child(ok)
	Audio.play("chime")
	show_modal(m)


func _on_ridership() -> void:
	_update_hud()
	world.network.queue_redraw()
	_refresh_live_sheet()


func _refresh_live_sheet() -> void:
	if is_instance_valid(sheet) and sheet.has_meta("live"):
		var cb: Callable = sheet.get_meta("live")
		cb.call()


func _on_month() -> void:
	_update_hud()
	_update_mission_chip()
	check_achievements()
	if state.debt_months > 0:
		toast.show_msg(I18n.t("debt_warning") % (GameState.DEBT_MONTHS_LIMIT - state.debt_months), "error", 3.5)
	_refresh_live_sheet()


func _on_year_ended(report: Dictionary) -> void:
	Audio.play("year")
	world.map.invalidate_overlay()
	if overlay != "none":
		world.map.set_overlay(overlay)
	show_modal(panels.year_report(report))
	save_now()


func _on_goals_changed(newly: Array) -> void:
	var before_total := SaveManager.total_stars()
	for g in newly:
		toast.show_msg(I18n.t("goal_done") + " " + panels.goal_text(g), "star", 3.5)
		state.feed.on_goal(state, panels.goal_text(g))
	Audio.play("goal")
	Settings.vibrate(50)
	var prev_city := SaveManager.city_stars(state.city_id)
	SaveManager.record_result(state)
	var now_city := SaveManager.city_stars(state.city_id)
	if now_city > prev_city:
		toast.show_msg(I18n.t("stars_earned") % now_city, "star", 4.0)
		for cid in CityData.CITY_IDS:
			var d := CityData.get_city(cid)
			var need: int = d.get("unlock_stars", 0)
			if before_total < need and SaveManager.total_stars() >= need:
				toast.show_msg(I18n.t("city_unlocked") % I18n.t(d["name_key"]), "star", 4.5)


func _on_bankrupt() -> void:
	var m := Modal.create(I18n.t("bankrupt_title"), 600.0, false)
	var l := UI.wrap_label(I18n.t("bankrupt_body"), 27, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.body.add_child(l)
	var restart := UI.button(I18n.t("restart"), "AccentButton", "undo")
	restart.pressed.connect(func():
		SaveManager.delete_save(state.slot())
		m.close()
		get_parent().call("start_city", state.slot(), true)
	)
	m.body.add_child(restart)
	var menu := UI.button(I18n.t("main_menu"), "", "home")
	menu.pressed.connect(func():
		m.close()
		exit_to_menu.emit()
	)
	m.body.add_child(menu)
	Audio.play("error")
	show_modal(m)


# ======================================================================== tutorial

func _show_tutorial() -> void:
	if tutorial_panel:
		tutorial_panel.queue_free()
	if state.tutorial_step >= 6:
		return
	tutorial_panel = PanelContainer.new()
	tutorial_panel.add_theme_stylebox_override("panel", ThemeBuilder.box(Color(0.12, 0.16, 0.24, 0.97), 26, 2, Color(Palette.ACCENT, 0.7), 22, 18, 14))
	var v := UI.vbox(12)
	var h := UI.hbox(14)
	var ic := Icon.make("info", 40, Palette.ACCENT)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(ic)
	var l := UI.wrap_label(I18n.t("tut_%d" % (state.tutorial_step + 1)), 25, Palette.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_panel.set_meta("label", l)
	h.add_child(l)
	v.add_child(h)
	var row := UI.hbox(10)
	var skip := UI.button(I18n.t("tut_skip"), "FlatButton", "", 60)
	skip.add_theme_font_size_override("font_size", 22)
	skip.pressed.connect(func():
		state.tutorial_step = 6
		SaveManager.progress["tutorial_done"] = true
		SaveManager.save_progress()
		tutorial_panel.queue_free()
		tutorial_panel = null
	)
	row.add_child(skip)
	row.add_child(UI.spacer())
	# steps that wait for an action have no Next button
	if state.tutorial_step in [0, 4, 5]:
		var nx := UI.button(I18n.t("tut_next"), "AccentButton", "", 60)
		nx.pressed.connect(func(): _advance_tutorial())
		row.add_child(nx)
	v.add_child(row)
	tutorial_panel.add_child(v)
	root_ui.add_child(tutorial_panel)
	_layout_tutorial()
	UI.pop_in(tutorial_panel, 0.95)


func _layout_tutorial() -> void:
	if not is_instance_valid(tutorial_panel):
		return
	var vs := root_ui.get_viewport_rect().size
	var w := minf(vs.x - 40.0, 700.0)
	tutorial_panel.custom_minimum_size.x = w
	var l: Label = tutorial_panel.get_meta("label")
	l.custom_minimum_size.x = w - 44.0 - 40.0 - 14.0
	tutorial_panel.size = Vector2(w, 0)
	tutorial_panel.reset_size()
	_shrink_tutorial_later()
	var y := hud.position.y + hud.get_combined_minimum_size().y + 16.0
	tutorial_panel.position = Vector2((vs.x - w) * 0.5, y)


## Autowrapped labels report their final height only after a layout pass.
func _shrink_tutorial_later() -> void:
	for _i in 2:
		await get_tree().process_frame
		if not is_instance_valid(tutorial_panel):
			return
		tutorial_panel.size.y = 0
		tutorial_panel.reset_size()


func _advance_tutorial() -> void:
	state.tutorial_step += 1
	if state.tutorial_step >= 6:
		SaveManager.progress["tutorial_done"] = true
		SaveManager.save_progress()
		if tutorial_panel:
			tutorial_panel.queue_free()
			tutorial_panel = null
		return
	_show_tutorial()


func _tutorial_event(ev: String) -> void:
	if tutorial_panel == null or state.tutorial_step >= 6:
		return
	var step := state.tutorial_step
	if step == 0 and (ev == "build_menu" or ev == "build_start"):
		state.tutorial_step = 1
		_advance_tutorial()
		return
	if (step == 1 and (ev == "build_menu" or ev == "build_start")) \
			or (step == 2 and ev == "first_stop") \
			or (step == 3 and ev == "line_built"):
		_advance_tutorial()
	elif step == 1 and ev == "first_stop":
		state.tutorial_step = 2
		_advance_tutorial()
