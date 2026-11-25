class_name DepartureBoard
extends PanelContainer
## Main-menu choices shown as a split-flap station departure board:
##   SAAT   GİDİŞ              PERON
##   08:05  YENİ OYUN              2
## Each row is a button; the flaps rattle into place when the board appears.

signal chosen(id: String)

const TIME_CHARS := 5
const DEST_CHARS := 15
const FLAP_W := 24.0
const FLAP_H := 44.0
const CHARSET := "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ0123456789:·/"

var _rows: Array = []      # {id, time, dest, plat}
var _start := 0.0


class FlapRow:
	extends Button
	var board: DepartureBoard
	var row := 0
	var text_cells := PackedStringArray()
	var _hl := 0.0

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(board.width(), DepartureBoard.FLAP_H + 14.0)
		mouse_entered.connect(func(): _hl = 1.0)
		mouse_exited.connect(func(): _hl = 0.0)
		button_down.connect(func(): _hl = 1.0)
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var f := ThemeBuilder.display(800)
		var x := 0.0
		var y := 7.0
		var now := Time.get_ticks_msec() / 1000.0 - board._start
		if button_pressed or _hl > 0.0:
			draw_rect(Rect2(Vector2(-6, 2), Vector2(size.x + 12, size.y - 4)), Color(Palette.LED, 0.12))
		for i in text_cells.size():
			var target := text_cells[i]
			if target == "|":
				x += DepartureBoard.FLAP_W * 0.6
				continue
			# rattle through random letters until this flap's settle time
			var settle := 0.25 + row * 0.09 + i * 0.025
			var ch := target
			if now < settle and target != " ":
				var k := int(now * 30.0 + i * 7 + row * 13) % DepartureBoard.CHARSET.length()
				ch = DepartureBoard.CHARSET.substr(k, 1)
			var r := Rect2(Vector2(x, y), Vector2(DepartureBoard.FLAP_W - 2.0, DepartureBoard.FLAP_H))
			draw_rect(r, Color("161a22"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), Color("1e232d"))
			draw_line(r.position + Vector2(0, r.size.y * 0.5), r.position + Vector2(r.size.x, r.size.y * 0.5), Color(0, 0, 0, 0.9), 2.0)
			if ch != " ":
				var col := Palette.LED if i < DepartureBoard.TIME_CHARS else Palette.CREAM
				var fs := 34
				var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(f, Vector2(x + (r.size.x - cw) * 0.5, y + DepartureBoard.FLAP_H * 0.5 + fs * 0.36), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			x += DepartureBoard.FLAP_W


func width() -> float:
	return (TIME_CHARS + DEST_CHARS + 1) * FLAP_W + FLAP_W * 1.2


static func fit(s: String, n: int) -> String:
	s = s.to_upper()
	if s.length() > n:
		s = s.substr(0, n)
	return s + " ".repeat(n - s.length())


## rows: [[id, destination text], ...]
func setup(rows: Array) -> void:
	var sb := ThemeBuilder.box(Color("0b0e14"), 10, 4, Color("2b313d"), 16, 12, 12)
	sb.border_width_top = 10
	add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(2)
	add_child(v)
	var head := UI.hbox(0)
	var hs := [[I18n.t("board_time"), TIME_CHARS * FLAP_W + FLAP_W * 0.6], [I18n.t("board_dest"), DEST_CHARS * FLAP_W + FLAP_W * 0.6], [I18n.t("board_plat"), FLAP_W * 2.0]]
	for h in hs:
		var l := UI.label(str(h[0]).to_upper(), 16, Palette.FAINT, 800)
		l.add_theme_font_override("font", ThemeBuilder.display(700))
		l.custom_minimum_size.x = h[1]
		head.add_child(l)
	v.add_child(head)
	# departures leave from "now", every few minutes
	var t := Time.get_datetime_dict_from_system()
	var mins := int(t["hour"]) * 60 + int(t["minute"])
	mins = (mins / 5 + 1) * 5
	_start = Time.get_ticks_msec() / 1000.0
	for i in rows.size():
		var r: Array = rows[i]
		var hhmm := "%02d:%02d" % [(mins / 60) % 24, mins % 60]
		mins += [5, 10, 15][i % 3]
		var cells := PackedStringArray()
		for ch in hhmm:
			cells.append(ch)
		cells.append("|")
		for ch in fit(str(r[1]), DEST_CHARS):
			cells.append(ch)
		cells.append("|")
		cells.append(str(i + 1))
		var fr := FlapRow.new()
		fr.board = self
		fr.row = i
		fr.text_cells = cells
		var id: String = r[0]
		fr.pressed.connect(func():
			Audio.play("tap")
			chosen.emit(id)
		)
		v.add_child(fr)
	# the rattle
	for k in 6:
		get_tree().create_timer(0.08 + k * 0.11).timeout.connect(func():
			if is_inside_tree():
				Audio.play("place", randf_range(1.6, 2.2), -16.0)
		)
