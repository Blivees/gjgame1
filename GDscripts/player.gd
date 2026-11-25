extends CharacterBody2D

# 状态：idle 待机 / walk 步行 / run 冲刺 / climb 攀爬
enum State { idle, walk, run, climb }

@export var speed: float = 300.0
@export var jump_force: float = -800.0
@export var gravity: float = 1800.0
# 冲刺时的速度倍率（按住 Shift）
@export var sprint_multiplier: float = 2.0
# 沿梯子上下攀爬的速度
@export var climb_speed: float = 200.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
# 梯子瓦片层（场景里 LadderLayer 与 Player 同级，挂 ladder.gd）
@onready var ladder_layer: Node = get_node_or_null("../LadderLayer")

# 记录最后一次移动方向：1 向右，-1 向左
var last_dir: int = 1
# 当前状态
var state: State = State.idle

# 状态 → 对应动画名（run / climb 动画还没做时，自动跳过不报错）
const STATE_ANIM := {
	State.idle: "idle",
	State.walk: "walk",
	State.run: "run",
	State.climb: "climb",
}

func _physics_process(delta: float) -> void:
	var new_state := _detect_state()
	if new_state != state:
		_exit_state(state)
		state = new_state
		_enter_state(state)

	_state_physics(delta)
	move_and_slide()

# ===== 状态判定（优先级：climb > run > walk > idle）=====
func _detect_state() -> State:
	var input_dir := Input.get_axis("move_left", "move_right")
	var climb_dir := Input.get_axis("move_up", "move_down")
	var touching := _touching_ladder()

	# 攀爬：已在梯子上就保持；贴梯子并按上下进入
	if state == State.climb:
		if touching and not Input.is_action_just_pressed("jump"):
			return State.climb
	elif touching and climb_dir != 0.0:
		return State.climb

	if input_dir == 0.0:
		return State.idle
	if Input.is_physical_key_pressed(KEY_SHIFT):
		return State.run
	return State.walk

func _touching_ladder() -> bool:
	if ladder_layer and ladder_layer.has_method("is_on_ladder"):
		return ladder_layer.is_on_ladder(global_position)
	return false

# ===== 进入 / 退出状态 =====
func _enter_state(s: State) -> void:
	if s == State.climb:
		velocity.y = 0.0

	var anim_name: String = STATE_ANIM.get(s, "")
	if anim_player and anim_name != "" and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func _exit_state(s: State) -> void:
	pass

# ===== 各状态物理更新 =====
func _state_physics(delta: float) -> void:
	match state:
		State.idle:
			velocity.x = 0.0
			_update_facing(0.0)
			_apply_gravity_and_jump(delta)

		State.walk:
			var d := Input.get_axis("move_left", "move_right")
			velocity.x = d * speed
			_update_facing(d)
			_apply_gravity_and_jump(delta)

		State.run:
			var d := Input.get_axis("move_left", "move_right")
			velocity.x = d * speed * sprint_multiplier
			_update_facing(d)
			_apply_gravity_and_jump(delta)

		State.climb:
			var d := Input.get_axis("move_left", "move_right")
			var c := Input.get_axis("move_up", "move_down")
			velocity.x = d * speed
			velocity.y = c * climb_speed
			_update_facing(d)
			# 空格蹬离梯子
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_force

func _apply_gravity_and_jump(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func _update_facing(input_dir: float) -> void:
	if input_dir != 0.0:
		last_dir = 1 if input_dir > 0 else -1
	sprite.flip_h = last_dir < 0
