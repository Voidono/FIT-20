extends AnimatedSprite2D


@onready var anim = get_node(".")

func _ready() -> void:
	anim.play("Down")
