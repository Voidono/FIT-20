extends Area2D

@export var scene_path: String = "res://scenes/mapsides/thư_viện.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # hoặc kiểm tra tên node: body.name == "Player"
		get_tree().change_scene_to_file(scene_path)
