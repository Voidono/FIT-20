extends HSlider

func _ready():
	# Khi mở scene, đồng bộ slider với giá trị đã lưu
	value = Setting.get_master_volume()
	value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float):
	Setting.set_master_volume(new_value)
