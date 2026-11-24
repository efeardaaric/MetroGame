extends Node
## Music + pooled sound effects. Streams are generated offline (tools/gen_audio.py).

const SFX := {
	"tap": "res://assets/audio/tap.wav",
	"place": "res://assets/audio/place.wav",
	"build": "res://assets/audio/build.wav",
	"cash": "res://assets/audio/cash.wav",
	"error": "res://assets/audio/error.wav",
	"chime": "res://assets/audio/chime.wav",
	"goal": "res://assets/audio/goal.wav",
	"year": "res://assets/audio/year.wav",
	"swoosh": "res://assets/audio/swoosh.wav",
	"undo": "res://assets/audio/undo.wav",
}
const MUSIC := "res://assets/audio/music.wav"
const AMB_DIR := "res://assets/audio/amb/"
const AMB_LOOPS := ["sea_loop", "city_loop", "wind_loop"]
const AMB_SHOTS := ["gull_1", "gull_2", "gull_3", "gull_4", "gull_5", "gull_6", "ferry_horn", "tram_bell"]
const POOL := 8

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _streams := {}
var _next := 0
var _last_play := {}
var _amb := {}          # loop name -> AudioStreamPlayer
var _amb_target := {}   # loop name -> linear target volume
var _amb_shot: AudioStreamPlayer
var _amb_streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for k in SFX.keys():
		if ResourceLoader.exists(SFX[k]):
			_streams[k] = load(SFX[k])
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	if ResourceLoader.exists(MUSIC):
		var s = load(MUSIC)
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		_music.stream = s
	for n in AMB_LOOPS + AMB_SHOTS:
		var path: String = AMB_DIR + n + ".ogg"
		if ResourceLoader.exists(path):
			var st = load(path)
			if st is AudioStreamOggVorbis and n in AMB_LOOPS:
				st.loop = true
			_amb_streams[n] = st
	for n in AMB_LOOPS:
		var pl := AudioStreamPlayer.new()
		pl.volume_db = -80.0
		if _amb_streams.has(n):
			pl.stream = _amb_streams[n]
		add_child(pl)
		_amb[n] = pl
		_amb_target[n] = 0.0
	_amb_shot = AudioStreamPlayer.new()
	add_child(_amb_shot)
	Settings.changed.connect(_apply_volume)
	_apply_volume()


## Sets target levels (0..1) for the ambience loops; they fade smoothly.
func set_ambience(levels: Dictionary) -> void:
	for n in AMB_LOOPS:
		_amb_target[n] = float(levels.get(n, 0.0))


func stop_ambience() -> void:
	for n in AMB_LOOPS:
		_amb_target[n] = 0.0


## Plays a positional-ish ambience one-shot (gull, ferry horn...). `level` 0..1.
func ambience_shot(name: String, level: float = 1.0, pitch: float = 1.0) -> void:
	if not _amb_streams.has(name) or Settings.ambience_volume <= 0.001 or level <= 0.01:
		return
	var p := AudioStreamPlayer.new()
	p.stream = _amb_streams[name]
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(maxf(0.0001, Settings.ambience_volume * level))
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _process(delta: float) -> void:
	for n in AMB_LOOPS:
		var pl: AudioStreamPlayer = _amb[n]
		if pl.stream == null:
			continue
		var target: float = _amb_target[n] * Settings.ambience_volume
		var cur := db_to_linear(pl.volume_db) if pl.playing else 0.0
		var nv := move_toward(cur, target, delta * 0.5)
		if nv <= 0.001:
			if pl.playing:
				pl.stop()
			pl.volume_db = -80.0
			continue
		if not pl.playing:
			pl.play(randf() * maxf(0.0, pl.stream.get_length() - 1.0))
		pl.volume_db = linear_to_db(nv)


func _apply_volume() -> void:
	_music.volume_db = linear_to_db(max(0.0001, Settings.music_volume * 0.55))
	if Settings.music_volume <= 0.001:
		_music.stop()
	elif _music.stream and not _music.playing:
		_music.play()


func play_music() -> void:
	if _music.stream and not _music.playing and Settings.music_volume > 0.001:
		_music.play()


func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not _streams.has(name) or Settings.sfx_volume <= 0.001:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(name, 0)) < 35:
		return
	_last_play[name] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(Settings.sfx_volume) + vol_db
	p.play()
