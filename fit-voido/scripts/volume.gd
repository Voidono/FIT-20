extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

func _ready():
	load_settings()

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK:
		# Chưa có file settings -> dùng giá trị mặc định
		set_master_volume(1.0)
		return
	
	var volume = config.get_value("audio", "master_volume", 1.0)
	set_master_volume(volume)

func set_master_volume(value: float):
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	config.set_value("audio", "master_volume", value)
	save_settings()

func get_master_volume() -> float:
	var bus_index = AudioServer.get_bus_index("Master")
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func save_settings():
	config.save(SAVE_PATH)
