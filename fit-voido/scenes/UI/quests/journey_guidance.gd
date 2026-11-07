extends RefCounted
## Read-only presentation of the next story action. Does not reopen or mutate quests.
const CHAPTERS := ["KHỞI ĐẦU", "NHỮNG NGƯỜI BẠN", "DẤU VẾT THỜI GIAN", "CON BUG", "ĐƯỜNG TRỞ VỀ"]
const COPY := {
	"meet_minh": [1, "Gặp Minh", "Hỏi chuyện Minh ở gần cổng trường.", "CỔNG TRƯỜNG"],
	"reach_building_c": [1, "Tìm đến Nhà C", "Gặp giảng viên trước tòa nhà màu xanh.", "SÂN TRƯỜNG · NHÀ C"],
	"stage1_challenge": [1, "Nhận viên đá đầu tiên", "Trở lại gặp giảng viên trước Nhà C.", "NHÀ C"],
	"garbage_quest": [1, "Một sân trường sạch hơn", "Hoàn thành Dọn rác với ít nhất một sao.", "THỬ THÁCH DỌN RÁC"],
	"fit_runner": [1, "Tìm nhịp chạy của bạn", "Hoàn thành hai vòng ở chế độ Practice.", "SÂN THỂ THAO"],
	"enter_room_417": [2, "Một chỗ ngồi ở 417C", "Lên tầng 4 Nhà C, vào phòng máy 417C.", "NHÀ C · TẦNG 4"],
	"choose_room417_seat": [2, "Chọn bạn cùng bàn", "Trò chuyện với nhóm đầu lớp hoặc cuối lớp để chọn chỗ ngồi.", "PHÒNG MÁY 417C"],
	"chapter2_quiz": [2, "Bạn hiểu FIT đến đâu?", "Gặp giảng viên và trả lời đúng cả 5 câu hỏi.", "PHÒNG MÁY 417C"],
	"reach_room_416": [3, "Tiếng gọi từ phòng 416", "Tới cửa phòng 416 và hỏi chuyện giảng viên.", "NHÀ C · TẦNG 4"],
	"unlock_room_416": [3, "Một năm đáng nhớ", "Dùng manh mối của giảng viên để nhập mã cửa 416.", "PHÒNG 416"],
	"reach_room_419": [3, "Gõ cửa phòng 419", "Hỏi giảng viên Truyền thông Đa phương tiện về viên đá tiếp theo.", "NHÀ C · TẦNG 4"],
	"find_thay_tuan": [3, "Người thầy trên đường chạy", "Tìm thầy Tuấn mặc áo marathon, gần đường chạy.", "SÂN THỂ THAO"],
	"fit_runner_race": [3, "Một cuộc đua cùng FIT", "Gặp thầy Tuấn. Về đích trong ba vị trí đầu ở Ghost Race.", "SÂN THỂ THAO"],
	"return_to_tuan": [3, "Tài liệu đang chờ bạn", "Trở lại gặp thầy Tuấn để nhận chương trình lễ kỷ niệm.", "SÂN THỂ THAO"],
	"deliver_marathon_documents": [3, "Chuyển một lời nhắn", "Giao chương trình cho giảng viên phụ trách lễ kỷ niệm, bên ngoài 210C.", "NHÀ C · VĂN PHÒNG KHOA"],
	"rescue_faculty_head": [4, "Có chuyện ở văn phòng", "Tương tác với cửa 210C. Giúp thầy Trưởng khoa giải quyết CON BUG.", "VĂN PHÒNG KHOA · 210C"],
	"claim_boss_reward": [4, "Sau cơn hỗn loạn", "Trở lại cửa 210C để gặp thầy Trưởng khoa và nhận viên đá cuối.", "VĂN PHÒNG KHOA · 210C"],
	"activate_time_gate": [5, "Đã đến lúc trở về", "Tương tác với cửa 210C, mở Cánh Cửa Thời Gian và đặt bốn viên đá.", "VĂN PHÒNG KHOA · 210C"],
}

static func resolve(state: Node) -> Dictionary:
	if state.has_flag("ending_complete"):
		return {"id": "journey_complete", "title": "Một hành trình để nhớ", "objective": "Bạn đã trở về. Những ký ức về FIT vẫn còn ở đây.", "chapter": 5, "location": "HÀNH TRÌNH ĐÃ HOÀN THÀNH"}
	var id := ""
	if state.has_time_stone(4):
		id = "activate_time_gate"
	elif state.has_time_stone(3):
		id = "claim_boss_reward" if state.has_completed_quest("boss_fight") else "rescue_faculty_head"
	elif state.has_time_stone(2):
		if state.has_quest_item("marathon_documents"):
			id = "deliver_marathon_documents"
		elif state.has_completed_quest("fit_runner_race") and not state.has_flag("tuan_documents_claimed"):
			id = "return_to_tuan"
		elif state.has_flag("tuan_identity_verified"):
			id = "fit_runner_race"
		elif state.has_flag("room419_lead_received"):
			id = "find_thay_tuan"
		elif state.has_flag("room416_rescue_complete"):
			id = "reach_room_419"
		elif state.has_flag("room416_help_requested"):
			id = "unlock_room_416"
		else:
			id = "reach_room_416"
	elif state.has_time_stone(1):
		if state.selected_skill() != &"":
			id = "chapter2_quiz"
		elif state.has_completed_quest("enter_room_417"):
			id = "choose_room417_seat"
		else:
			id = "enter_room_417"
	elif state.can_claim_stage1_stone():
		id = "stage1_challenge"
	elif not state.stage1_activity().is_empty():
		id = state.stage1_activity()
	elif state.has_flag("intro_complete") or state.is_quest_active("reach_building_c"):
		id = "reach_building_c"
	elif state.is_quest_active("meet_minh"):
		id = "meet_minh"
	if id.is_empty():
		# Retain the generic quest API for optional/custom content, one row at a time.
		var quests: Array = state.tracked_quests()
		quests.reverse()
		for quest in quests:
			if not bool(quest["completed"]):
				return quest
		return {}
	var data: Dictionary = state.quest_info(id)
	var copy: Array = COPY[id]
	data.merge({"title": copy[1], "objective": copy[2], "chapter": copy[0], "location": copy[3]}, true)
	# Custom quest copy remains an authoring override, not a second source of state.
	var details: Dictionary = state._quest_details.get(id, {})
	for key in ["title", "objective"]:
		if details.has(key):
			data[key] = details[key]
	if id == "unlock_room_416" and state.has_flag("room416_unlocked"):
		data["objective"] = "Cửa đã mở. Nói chuyện với giảng viên để nhận manh mối tiếp theo."
	if id == "chapter2_quiz" and state.quiz_best_score("chapter2_fit_quiz") >= 5:
		data["objective"] = "Bạn đã đạt 5/5. Gặp lại giảng viên để nhận viên đá thứ hai."
	return {} if bool(data.get("hidden", false)) else data
