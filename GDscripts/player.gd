extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_force: float = -550.0
@export var gravity: float = 1800.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# 记录最后一次移动方向：1 向右，-1 向左
var last_dir: int = 1

func _physics_process(delta: float) -> void:
	# 左右移动
	var input_dir: float = Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * speed

	if input_dir != 0:
		# 移动时 walk 优先，同时记录朝向
		last_dir = 1 if input_dir > 0 else -1
		sprite.flip_h = last_dir < 0
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")
	else:
		# 不移动时播 idle，镜像沿用最后一次的朝向
		sprite.flip_h = last_dir < 0
		if anim_player and anim_player.current_animation != "idle":
			anim_player.play("idle")

	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# 在地上才能跳
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force

	move_and_slide()
