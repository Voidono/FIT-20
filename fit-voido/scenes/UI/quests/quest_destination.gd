extends RefCounted
## Resolve the next local interaction, including stairs between quest destinations.
const DESTINATIONS := {
	"meet_minh": ["campus", "NPC/Minh", "Minh"],
	"reach_building_c": ["campus", "NPC/Lecturer", "Giảng viên Nhà C"],
	"stage1_challenge": ["campus", "NPC/Lecturer", "Nhận viên đá đầu tiên"],
	"garbage_quest": ["campus", "NPC/Lecturer", "Bắt đầu / thử lại Dọn rác"],
	"fit_runner": ["campus", "NPC/Lecturer", "Bắt đầu / thử lại Practice"],
	"enter_room_417": ["classroom", "DialogueNPC", "Giảng viên 417C"],
	"choose_room417_seat": ["classroom", "DialogueNPC5", "Nhóm đầu lớp"],
	"chapter2_quiz": ["classroom", "DialogueNPC", "Giảng viên 417C"],
	"reach_room_416": ["t_4", "Room416Keypad", "Phòng 416"],
	"unlock_room_416": ["t_4", "Room416Keypad", "Phòng 416"],
	"reach_room_419": ["t_4", "SceneDoor", "Phòng 419"],
	"find_thay_tuan": ["campus", "DialogueNPC", "Thầy Tuấn"],
	"fit_runner_race": ["campus", "DialogueNPC", "Thầy Tuấn · Ghost Race"],
	"return_to_tuan": ["campus", "DialogueNPC", "Nhận tài liệu từ thầy Tuấn"],
	"deliver_marathon_documents": ["t_2", "DocumentRecipient", "Giao tài liệu · 210C"],
	"rescue_faculty_head": ["t_2", "FacultyBossDoor", "Văn phòng Khoa · 210C"],
	"claim_boss_reward": ["t_2", "FacultyBossDoor", "Nhận viên đá cuối · 210C"],
	"activate_time_gate": ["t_2", "FacultyBossDoor", "Cánh Cửa Thời Gian · 210C"],
}

static func map_id(scene: Node) -> String:
	var file := scene.scene_file_path.get_file()
	if file == "nửa đầu.tscn": return "campus"
	if file in ["phòng_máy_2.tscn", "room_417.tscn"]: return "classroom"
	if file in ["t_2.tscn", "t_3.tscn", "t_4.tscn"]: return file.get_basename()
	return ""

static func _target(scene: Node, path: String, title: String) -> Array[Dictionary]:
	var node := scene.get_node_or_null(NodePath(path)) as Node2D
	if node == null: return []
	return [{"node": node, "label": title}]

static func resolve(scene: Node, objective_id: String) -> Array[Dictionary]:
	if scene == null or not DESTINATIONS.has(objective_id): return []
	var here := map_id(scene)
	if here.is_empty(): return []
	var destination: Array = DESTINATIONS[objective_id]
	if here == destination[0]:
		var result := _target(scene, destination[1], destination[2])
		if objective_id == "choose_room417_seat":
			result.append_array(_target(scene, "DialogueNPC3", "Nhóm cuối lớp"))
		return result
	if here == "classroom":
		return _target(scene, "SceneDoor" if scene.has_node("SceneDoor") else "Exit", "Ra hành lang")
	if here == "campus":
		# The outdoor entrance's Area is at (0,0); its shape carries the real position.
		return _target(scene, "Area/Area2D/CollisionShape2D", "Vào Nhà C")
	var floor_number := int(here.trim_prefix("t_"))
	var target_floor := 4 if destination[0] in ["classroom", "t_4"] else 2
	if floor_number < target_floor:
		return _target(scene, "StairsToFloor%d" % (floor_number + 1), "Lên tầng %d" % (floor_number + 1))
	if floor_number > target_floor:
		return _target(scene, "StairsDownToFloor%d" % (floor_number - 1), "Xuống tầng %d" % (floor_number - 1))
	if destination[0] == "campus":
		return _target(scene, "CampusEntrance", "Ra sân trường")
	if destination[0] == "classroom":
		return _target(scene, "Room417Door", "Vào phòng máy 417C")
	return []
