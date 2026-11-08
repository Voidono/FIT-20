extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var music = root.get_node("Music")
	var player = music.get_node("AudioStreamPlayer")
	var loader = root.get_node("SceneLoader")
	music.fade_seconds = 0
	var fixture := Node.new()
	root.add_child(fixture)
	current_scene = fixture
	fixture.scene_file_path = "res://scenes/UI/activity_host.tscn"
	for id in ["fit_runner", "fit_runner_race", "garbage_quest", "boss_fight"]:
		loader.activity_id = id
		music._on_scene_changed()
		var expected := "FinalBossfight.wav" if id == "boss_fight" else "Runnergame.wav"
		assert(player.stream.resource_path.get_file() == expected)
		assert(player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
		assert(player.stream.get_length() > 0 and player.stream.loop_end > 0)
		print(id, " -> ", expected, " (", player.stream.get_length(), "s)")
	loader.activity_id = ""
	fixture.scene_file_path = "res://scenes/mapsides/t_4.tscn"
	music._on_scene_changed()
	assert(player.stream.resource_path.get_file() == "MainBGM.wav")
	assert(player.bus == &"Music")
	var before = player.stream
	fixture.scene_file_path = "res://scenes/UI/loading_scene.tscn"
	music._on_scene_changed()
	assert(player.stream == before)
	print("MainBGM.wav: ", before.get_length(), "s; PASS: track routing, loops, return and loading continuity")
	quit()
