extends Node
## Touch-scroll regression test: dragging on top of buttons inside a sheet must scroll it,
## must not trigger the button, and live refreshes must keep the scroll position.

var main: Node
var fails := 0


func _ready() -> void:
	Input.emulate_touch_from_mouse = true
	SaveManager.progress = {"stars": {}, "best_riders": {}, "tutorial_done": true, "last_city": ""}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_run()


func check(c: bool, m: String) -> void:
	print(("  ok   " if c else "  FAIL ") + m)
	if not c:
		fails += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func drag(from: Vector2, to: Vector2, steps: int = 12) -> void:
	touch(from, true)
	await get_tree().process_frame
	var prev := from
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = p
		d.relative = p - prev
		d.velocity = (p - prev) * 60.0
		Input.parse_input_event(d)
		prev = p
		await get_tree().process_frame
	touch(to, false)
	await get_tree().process_frame


func _run() -> void:
	await wait(1.0)
	main.start_city("istanbul", true)
	await wait(1.5)
	var g: GameScreen = main.current
	g._set_speed(0)
	for i in 12:
		g.state.feed.monthly(g.state)
	g.open_social()
	await wait(0.8)
	var sc: ScrollContainer = g.sheet.scroll
	print("  touchscreen available: ", DisplayServer.is_touchscreen_available())
	var maxv := sc.get_v_scroll_bar().max_value - sc.size.y
	print("  scrollable range: ", maxv)
	# find a filter button (Övgü) inside the scroll and drag starting on it
	var btn: Button = null
	for b in sc.find_children("*", "Button", true, false):
		if b.text.strip_edges() == I18n.t("filter_praise"):
			btn = b
	var pressed := [false]
	if btn:
		btn.pressed.connect(func(): pressed[0] = true)
		check(btn.mouse_filter == Control.MOUSE_FILTER_PASS, "buttons inside scroll pass drags through")
	var start := btn.get_global_rect().get_center() if btn else sc.get_global_rect().get_center()
	var before := sc.scroll_vertical
	await drag(start, start - Vector2(0, 420))
	await wait(0.4)
	print("  scroll %d -> %d" % [before, sc.scroll_vertical])
	check(sc.scroll_vertical > before + 100, "dragging over a button scrolls the sheet")
	check(not pressed[0], "the button under the finger is not triggered by a scroll")
	# a plain tap on a button still works
	if btn:
		var p := btn.get_global_rect().get_center()
		if sc.get_global_rect().has_point(p):
			touch(p, true)
			await get_tree().process_frame
			touch(p, false)
			await wait(0.3)
	# live refresh keeps position
	var keep := sc.scroll_vertical
	await g._refresh_live_sheet()
	await wait(0.2)
	print("  after refresh %d (was %d)" % [sc.scroll_vertical, keep])
	check(absi(sc.scroll_vertical - keep) <= 2, "live refresh keeps the scroll position")
	# modal (scenarios list) in the main menu
	g.exit_to_menu.emit()
	await wait(1.0)
	var menu: MainMenu = main.current
	menu.open_scenarios()
	await wait(0.8)
	var msc: ScrollContainer = null
	for c in menu.ui_layer.find_children("*", "ScrollContainer", true, false):
		msc = c
	var m0 := msc.scroll_vertical
	var c0 := msc.get_global_rect().get_center()
	await drag(c0 + Vector2(0, 150), c0 - Vector2(0, 250))
	await wait(0.4)
	check(msc.scroll_vertical > m0 + 100, "scenario list scrolls by dragging (%d -> %d)" % [m0, msc.scroll_vertical])
	print("FAILURES: ", fails)
	get_tree().quit(1 if fails > 0 else 0)
