extends Area2D

signal activated

@export var hit_radius: float = 34.0
@export var one_shot: bool = true
@export var on_color: Color = Color(1.0, 0.9, 0.4)
@export var punch_amount: float = 0.18

var _activated: bool = false

func _ready():
	add_to_group("button_target")

func activate():
	if _activated and one_shot:
		return
	_activated = true
	modulate = on_color
	_punch()
	activated.emit()
	print(name, " 被撞开了")

func _punch():
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2(1.0 + punch_amount, 1.0 - punch_amount * 0.8), 0.06)
	t.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
