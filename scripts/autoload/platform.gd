extends Node
## Platform services bridge: Game Center (iOS), Google Play Games (Android), native share
## and cloud save. Everything degrades gracefully when the plugin isn't installed, so the
## game runs identically on desktop / without accounts. See docs/PLATFORM.md.
##
## Expected plugin singletons (install the plugins listed in docs/PLATFORM.md):
##   iOS:      "GameCenter"            (godot-ios-plugins / gamecenter)
##   Android:  "GodotPlayGameServices" (godot-play-game-services)
##   Share:    "GodotShare" / "Share"  (any share plugin exposing share_image / shareImage)

signal signed_in(ok: bool)

# Achievement / leaderboard ids as created in App Store Connect & Play Console.
const IOS_PREFIX := "com.efeardaaric.metrotycoon."
var ANDROID_IDS := {} # fill with "CgkI..." ids from the Play Console: {"first_line": "CgkI..."}
const LEADERBOARD := "best_riders"

var _gc: Object
var _pgs: Object
var _share: Object
var signed := false


func _ready() -> void:
	if Engine.has_singleton("GameCenter"):
		_gc = Engine.get_singleton("GameCenter")
	if Engine.has_singleton("GodotPlayGameServices"):
		_pgs = Engine.get_singleton("GodotPlayGameServices")
	for n in ["GodotShare", "Share"]:
		if Engine.has_singleton(n):
			_share = Engine.get_singleton(n)
			break
	call_deferred("sign_in")


func has_games_service() -> bool:
	return _gc != null or _pgs != null


func sign_in() -> void:
	if _gc and _gc.has_method("authenticate"):
		_gc.authenticate()
		signed = true
	elif _pgs and _pgs.has_method("initialize"):
		_pgs.initialize()
		signed = true
	signed_in.emit(signed)


func unlock_achievement(id: String) -> void:
	if _gc and _gc.has_method("award_achievement"):
		_gc.award_achievement({"name": IOS_PREFIX + id, "progress": 100.0})
	elif _pgs and ANDROID_IDS.has(id) and _pgs.has_method("unlockAchievement"):
		_pgs.unlockAchievement(ANDROID_IDS[id])


func submit_score(value: float) -> void:
	if _gc and _gc.has_method("post_score"):
		_gc.post_score({"score": int(value), "category": IOS_PREFIX + LEADERBOARD})
	elif _pgs and ANDROID_IDS.has(LEADERBOARD) and _pgs.has_method("submitScore"):
		_pgs.submitScore(ANDROID_IDS[LEADERBOARD], int(value))


func show_achievements() -> void:
	if _gc and _gc.has_method("show_game_center"):
		_gc.show_game_center({"view": "achievements"})
	elif _pgs and _pgs.has_method("showAchievements"):
		_pgs.showAchievements()


## Shares an image. Returns a user-facing description of what happened.
func share_image(path: String, text: String) -> String:
	var abs_path := ProjectSettings.globalize_path(path)
	if _share:
		if _share.has_method("share_image"):
			_share.share_image(abs_path, "Metro Tycoon: Türkiye", text, "image/png")
			return ""
		if _share.has_method("shareImage"):
			_share.shareImage(abs_path, "Metro Tycoon: Türkiye", text, "image/png")
			return ""
	# fallback: copy into the Pictures folder where possible
	var pics := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if pics != "" and DirAccess.dir_exists_absolute(pics):
		var dst := pics.path_join(path.get_file())
		if DirAccess.copy_absolute(abs_path, dst) == OK:
			if not OS.has_feature("mobile"):
				OS.shell_show_in_file_manager(dst)
			return dst
	DisplayServer.clipboard_set(text)
	return abs_path
