extends Node
## Persistent user settings.

signal changed

const PATH := "user://settings.cfg"

var music_volume := 0.6
var sfx_volume := 0.8
var ambience_volume := 0.7
var haptics := true
var language := ""
var show_fps := false
var colorblind_patterns := false
var high_quality := true


func _ready() -> void:
	load_settings()
	if language == "":
		var loc := OS.get_locale_language()
		language = "tr" if loc == "tr" else "en"
	I18n.set_language(language)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	music_volume = cf.get_value("audio", "music", music_volume)
	sfx_volume = cf.get_value("audio", "sfx", sfx_volume)
	ambience_volume = cf.get_value("audio", "ambience", ambience_volume)
	haptics = cf.get_value("general", "haptics", haptics)
	language = cf.get_value("general", "language", language)
	show_fps = cf.get_value("general", "show_fps", show_fps)
	high_quality = cf.get_value("general", "high_quality", high_quality)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.set_value("audio", "ambience", ambience_volume)
	cf.set_value("general", "haptics", haptics)
	cf.set_value("general", "language", language)
	cf.set_value("general", "show_fps", show_fps)
	cf.set_value("general", "high_quality", high_quality)
	cf.save(PATH)
	changed.emit()


func set_language(lang: String) -> void:
	language = lang
	I18n.set_language(lang)
	save_settings()


func vibrate(ms: int = 12) -> void:
	if haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
