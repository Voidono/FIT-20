extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var music = root.get_node("Music")
	var player: AudioStreamPlayer = music.get_node("AudioStreamPlayer")
	var first := AudioStreamWAV.new()
	first.data = PackedByteArray([0, 0, 0, 0])
	var second := AudioStreamWAV.new()
	second.data = PackedByteArray([0, 0, 0, 0])
	music.play_music(first, 0.0)
	assert(player.stream == first)
	music.play_music(second, 0.01)
	music.play_music(first, 0.01)
	await create_timer(0.1).timeout
	assert(player.stream == first)
	assert(is_equal_approx(player.volume_db, 0.0))
	music.play_music(null, 0.0)
	assert(player.stream == null and not player.playing)
	change_scene_to_file("res://tests/fixtures/return_scene.tscn")
	await scene_changed
	await create_timer(0.8).timeout
	assert(player.stream == music.default_track)
	music.fade_seconds = 0.0
	music.activity_tracks["fit_runner"] = second
	root.get_node("SceneLoader").activity_id = "fit_runner"
	current_scene.scene_file_path = "res://scenes/UI/activity_host.tscn"
	music._on_scene_changed()
	assert(player.stream == second)
	root.get_node("SceneLoader").activity_id = ""
	current_scene.scene_file_path = "res://tests/fixtures/return_scene.tscn"
	music._on_scene_changed()
	assert(player.stream == music.default_track)
	var character_script = load("res://scenes/Character/character.gd")
	assert(character_script.can_instantiate())
	var character = character_script.new()
	var steps := AudioStreamPlayer.new()
	root.add_child(steps)
	character._footstep_player = steps
	character.footstep_sounds.append(first)
	character._update_footsteps(24.0)
	assert(steps.stream == null)
	character._update_footsteps(24.0)
	assert(steps.stream == first)
	character._update_footsteps(0.0)
	assert(character._step_distance == 0.0)
	character.free()
	steps.free()
	print("PASS: fades, silence, activity music and return, footstep cadence and idle reset")
	quit()
