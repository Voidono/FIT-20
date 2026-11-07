extends Node

const SAVE_PATH = "user://settings.cfg"
var save_path: String = SAVE_PATH
var config = ConfigFile.new()

func _ready():
	load_settings()

func load_settings():
	var err = config.load(save_path)
	if err != OK:
		# Chưa có file settings -> dùng giá trị mặc định
		set_master_volume(1.0)
		set_music_volume(1.0)
		set_effects_volume(1.0)
		return
	
	var volume = config.get_value("audio", "master_volume", 1.0)
	set_master_volume(volume)
	
	var music_volume = config.get_value("audio", "music_volume", 1.0)
	set_music_volume(music_volume)
	set_effects_volume(config.get_value("audio", "effects_volume", 1.0))



func set_master_volume(value: float):
	value = clampf(value, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index("Master")
	_apply_volume(bus_index, value)
	config.set_value("audio", "master_volume", value)
	save_settings()

func get_master_volume() -> float:
	var bus_index = AudioServer.get_bus_index("Master")
	return 0.0 if AudioServer.is_bus_mute(bus_index) else db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
func set_music_volume(value: float):
	value = clampf(value, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index("Music")
	_apply_volume(bus_index, value)
	config.set_value("audio", "music_volume", value)
	save_settings()

func get_music_volume() -> float:
	var bus_index = AudioServer.get_bus_index("Music")
	return 0.0 if AudioServer.is_bus_mute(bus_index) else db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func save_settings():
	config.save(save_path)

func set_effects_volume(value: float) -> void:
	value = clampf(value, 0, 1)
	_apply_volume(AudioServer.get_bus_index("sound effect"), value)
	config.set_value("audio", "effects_volume", value)
	save_settings()

func get_effects_volume() -> float:
	var index := AudioServer.get_bus_index("sound effect")
	return 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))

func _apply_volume(index: int, value: float) -> void:
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
