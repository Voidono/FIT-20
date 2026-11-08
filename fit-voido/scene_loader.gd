extends Node

const LOADING_SCREEN = "res://scenes/UI/loading_scene.tscn"
const ACTIVITY_HOST = "res://scenes/UI/activity_host.tscn"
const MENU = "res://scenes/menu & options/menu.tscn"
var target_scene := ""
var previous_scene := MENU
var activity_id := ""
var _restore_position := false
var _scene_spawn: Dictionary = {}
## Session-local hallway return; the boss checkpoint separately returns inside 210.
var office210_return: Dictionary = {}

func leave_office210() -> Error:
	return go_to_spawn(str(office210_return.get("scene", "res://scenes/mapsides/t_2.tscn")), office210_return.get("position", Vector2(2436, 296)))

func is_nearest_door(door: Area2D, player: Node2D) -> bool:
	# Opposing hallway doors have overlapping interaction ranges. Resolve by
	# distance, rather than whichever node receives the input first.
	var scene := get_tree().current_scene
	if scene == null: return true
	var shape := door.get_node_or_null("CollisionShape2D") as Node2D
	var center := shape.global_position if shape != null else door.global_position
	var distance := player.global_position.distance_squared_to(center)
	for candidate in scene.find_children("*", "Area2D", true, false):
		if candidate == door or not candidate.is_visible_in_tree(): continue
		if not (candidate.has_method("_try_use") or candidate.has_method("_locked") or candidate.has_method("_open_keypad") or candidate.has_method("_talk")): continue
		if not candidate.get_overlapping_bodies().has(player): continue
		var other_shape := candidate.get_node_or_null("CollisionShape2D") as Node2D
		var other_center: Vector2 = other_shape.global_position if other_shape != null else candidate.global_position
		if player.global_position.distance_squared_to(other_center) < distance - 0.01: return false
	return true

func show_faculty_disturbance() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	get_tree().root.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(shade, "color:a", 0.3, 0.15)
	tween.tween_property(shade, "color:a", 0.0, 0.3)
	await tween.finished
	layer.queue_free()

func go_to(path: String) -> Error:
	if not ResourceLoader.exists(path, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	if str(_scene_spawn.get("scene", "")) != path:
		_scene_spawn.clear()
	var current := get_tree().current_scene
	if current != null and current.scene_file_path != LOADING_SCREEN:
		previous_scene = current.scene_file_path
	target_scene = path
	return get_tree().change_scene_to_file(LOADING_SCREEN)


## Door travel uses scene-local coordinates, independent of minigame checkpoints.
func go_to_spawn(path: String, position: Vector2) -> Error:
	_scene_spawn = {"scene": path, "position": position}
	_restore_position = false
	var error := go_to(path)
	if error != OK:
		_scene_spawn.clear()
	return error


## Call from a campus NPC/dialogue: SceneLoader.start_minigame("fit_runner").
func start_minigame(id: String) -> Error:
	if not GameState.can_start_activity(id) or not activity_id.is_empty():
		return ERR_UNAUTHORIZED
	var current := get_tree().current_scene
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if current == null or player == null:
		return ERR_UNCONFIGURED
	if not GameState.set_return_point(current.scene_file_path, player.global_position):
		return ERR_INVALID_DATA
	if GameState.last_save_error != OK:
		return GameState.last_save_error
	activity_id = id
	var error := go_to(ACTIVITY_HOST)
	if error != OK:
		activity_id = ""
	return error


func return_from_minigame() -> Error:
	var point := GameState.return_point()
	var path := str(point.get("scene", MENU))
	if not ResourceLoader.exists(path, "PackedScene"):
		path = MENU
	_restore_position = path != MENU
	activity_id = ""
	return go_to(path)


## Called after a player enters its host scene; stale checkpoints never affect normal travel.
func restore_player(player: Node2D) -> void:
	var scene := get_tree().current_scene
	if scene != null and str(_scene_spawn.get("scene", "")) == scene.scene_file_path:
		var position: Vector2 = _scene_spawn["position"]
		player.global_position = scene.to_global(position) if scene is Node2D else position
		_scene_spawn.clear()
		return
	if not _restore_position:
		return
	var point := GameState.return_point()
	if get_tree().current_scene == null:
		return
	if get_tree().current_scene.scene_file_path == str(point.get("scene", "")):
		player.global_position = point.get("position", player.global_position)
		_restore_position = false
