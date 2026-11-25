class_name CityIntro
extends Control
## "Sıradaki durak": when a city opens, a station name board drops in for a moment,
## with the city's altitude in the corner the way TCDD station boards show "Rakım".

const RAKIM := {"istanbul": 39, "ankara": 938, "izmir": 25, "eskisehir": 789, "antalya": 39, "bursa": 155, "trabzon": 37}

var city_id := ""
var year := 2010
var _t := 0.0


static func show_for(parent: Control, cid: String, y: int) -> void:
	var c := CityIntro.new()
	c.city_id = cid
	c.year = y
	parent.add_child(c)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	Audio.play("chime", 0.9, -6.0)
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(queue_free)


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	var drop := clampf(_t / 0.35, 0.0, 1.0)
	drop = 1.0 - pow(1.0 - drop, 3.0)
	var name := I18n.t(CityData.get_city(city_id)["name_key"]).to_upper()
	var fd := ThemeBuilder.display(800)
	var fs := 92
	var tw := fd.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := clampf(tw + 140.0, 460.0, vs.x - 40.0)
	var h := 190.0
	var pos := Vector2((vs.x - w) * 0.5, vs.y * 0.36 - h * 0.5 - (1.0 - drop) * 120.0)
	# hanging chains
	for side in [0.18, 0.82]:
		var x: float = pos.x + w * side
		draw_line(Vector2(x, pos.y - 70.0), Vector2(x, pos.y + 6.0), Color(0.15, 0.15, 0.18, 0.9), 5.0)
	var sb := ThemeBuilder.enamel(Palette.PANEL, 22, true, 0, 0, 0, 0.9)
	draw_style_box(sb, Rect2(pos, Vector2(w, h)))
	var small := ThemeBuilder.display(700)
	var cap := I18n.t("next_stop").to_upper()
	var cw := small.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(small, Vector2(pos.x + (w - cw) * 0.5, pos.y + 46.0), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(Palette.CREAM, 0.75))
	draw_string(fd, Vector2(pos.x + (w - tw) * 0.5, pos.y + 132.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CREAM)
	var rk := I18n.t("altitude") % RAKIM.get(city_id, 0)
	var yt := str(year)
	draw_string(small, Vector2(pos.x + 34.0, pos.y + h - 22.0), rk, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(Palette.CREAM, 0.7))
	var yw := small.get_string_size(yt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(small, Vector2(pos.x + w - 34.0 - yw, pos.y + h - 22.0), yt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(Palette.LED, 0.9))
