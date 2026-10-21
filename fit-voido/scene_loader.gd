extends Node

const LOADING_SCREEN = "res://scenes/UI/loading_scene.tscn"
var target_scene := ""

func go_to(path: String):
	target_scene = path
	get_tree().change_scene_to_file(LOADING_SCREEN)
