class_name BattleDebugPanel
extends CanvasLayer
## Dev-only tuning panel. Removes itself in release builds. F1 or the DBG button toggles it.
## Buttons are built from the battle's Library nodes, so new skills / difficulties show up by themselves.

@onready var toggle_button: Button = %ToggleButton
@onready var panel: Control = %Panel
@onready var list: VBoxContainer = %List

var battle: BossBattle


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	battle = get_parent() as BossBattle
	toggle_button.pressed.connect(_toggle)
	panel.hide()
	_build.call_deferred()  # the battle's Library is not ready yet at this point


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F1:
		_toggle()


func _build() -> void:
	if battle == null:
		return
	for preset in battle.get_difficulties():
		_add_button("Difficulty: " + preset.display_name,
				func() -> void: battle.set_difficulty(preset))
	for chosen_skill in battle.get_skills():
		_add_button("Skill: " + chosen_skill.display_name,
				func() -> void: battle.set_skill(chosen_skill))
	_add_button("Boss -> phase 2", func() -> void: battle.debug_set_boss_ratio(0.6))
	_add_button("Boss -> phase 3", func() -> void: battle.debug_set_boss_ratio(0.3))
	_add_button("Boss HP = 1", func() -> void: battle.debug_set_boss_ratio(0.0))
	_add_button("Fill mercy", func() -> void: battle.debug_fill_mercy())
	_add_button("Heal player", func() -> void: battle.debug_heal())
	_add_button("Toggle mobile controls", func() -> void: battle.toggle_mobile_controls())


func _toggle() -> void:
	panel.visible = not panel.visible


func _add_button(label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", 12)
	button.pressed.connect(callback)
	list.add_child(button)
