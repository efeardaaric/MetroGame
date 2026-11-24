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
const POOL := 8

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _streams := {}
var _next := 0
var _last_play := {}


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
	Settings.changed.connect(_apply_volume)
	_apply_volume()


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
