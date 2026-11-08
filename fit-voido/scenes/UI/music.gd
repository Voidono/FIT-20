extends CanvasLayer
## Persistent non-positional music; configure tracks in music.tscn.
@export var default_track: AudioStream
## Keys: fit_runner, garbage_quest, boss_fight.
@export var activity_tracks: Dictionary[String, AudioStream] = {}
## Exact res:// scene paths, including standalone minigames.
@export var scene_tracks: Dictionary[String, AudioStream] = {}
@export_range(0.0, 3.0) var fade_seconds: float = 0.35
@onready var _player: AudioStreamPlayer = $AudioStreamPlayer
var _fade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Loop the imported WAVs natively, avoiding a restart gap at finished.
	var tracks: Array = [default_track] + activity_tracks.values() + scene_tracks.values()
	for track in tracks:
		if track is AudioStreamWAV:
			track.loop_begin = 0
			track.loop_end = roundi(track.get_length() * track.mix_rate)
			track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_player.finished.connect(_player.play)
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == "res://scenes/UI/loading_scene.tscn":
		return
	var track: AudioStream = scene_tracks.get(scene.scene_file_path, default_track)
	if scene.scene_file_path == "res://scenes/UI/activity_host.tscn":
		track = activity_tracks.get(SceneLoader.activity_id, default_track)
	play_music(track)

## Same track preserves playback. null means silence; new requests cancel old fades.
func play_music(track: AudioStream, fade: float = -1.0) -> void:
	if _player.stream == track and (_fade == null or not _fade.is_running()):
		return
	if _fade != null:
		_fade.kill()
	var duration := fade_seconds if fade < 0.0 else fade
	if duration <= 0.0:
		_switch_track(track)
		_player.volume_db = 0.0
		return
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", -60.0, duration)
	_fade.tween_callback(_switch_track.bind(track))
	_fade.tween_property(_player, "volume_db", 0.0, duration)

func _switch_track(track: AudioStream) -> void:
	_player.stop()
	_player.stream = track
	if track != null:
		_player.play()
