extends Node2D

enum State { FOLLOW, AIM, FLY, RETURN }

@export var follow_speed: float = 8.0
@export var offset: Vector2 = Vector2(-45, -10)
@export var bob_height: float = 3.0
@export var bob_speed: float = 2.0

@export var gravity: float = 1050.0
@export var min_throw_speed: float = 420.0
@export var max_throw_speed: float = 1900.0
@export var max_drag_px: float = 240.0
@export var bounce: float = 0.7
@export var collide_radius: float = 16.0
@export var collide_mask: int = 1
@export var max_fly_time: float = 20.0
@export var return_speed: float = 900.0
@export var exclude_player_from_collision: bool = true

@export var dash_color: Color = Color(1, 1, 1, 0.7)
@export var power_color: Color = Color(1.0, 0.6, 0.25, 0.95)
@export var shake_strength: float = 8.0
@export var shake_duration: float = 0.25

@onready var player: Node2D = get_node("../Player")

var _state: State = State.FOLLOW
var _control: bool = false
var _skill: int = 1
var _dragging: bool = false
var _time: float = 0.0
var _drag_start: Vector2 = Vector2.ZERO
var _drag_now: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _fly_time: float = 0.0
var _resting: bool = false

func _process(delta):
	_time += delta
	match _state:
		State.FOLLOW:
			_follow(delta, 1.0)
		State.AIM:
			_follow(delta, 0.5)
			if _dragging:
				_drag_now = get_global_mouse_position()
			queue_redraw()
		State.FLY:
			_update_fly(delta)
		State.RETURN:
			_update_return(delta)

func _input(event):
	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_F or ke.physical_keycode == KEY_F:
				_toggle_control()
			elif ke.keycode == KEY_1:
				_switch_skill(1)
			elif ke.keycode == KEY_2:
				_switch_skill(2)
			elif ke.keycode == KEY_3:
				_switch_skill(3)
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if _state == State.AIM:
				_dragging = true
				_drag_now = get_global_mouse_position()
				queue_redraw()
			elif _state == State.FLY:
				_start_return()
			elif _control and _state == State.FOLLOW:
				_press_skill()
		else:
			if _state == State.AIM and _dragging:
				_release_throw()

func _toggle_control():
	if _control:
		_control = false
		_dragging = false
		if _state == State.FLY:
			_start_return()
		elif _state == State.AIM:
			_state = State.FOLLOW
		queue_redraw()
		return
	if _state == State.FLY or _state == State.RETURN:
		return
	_control = true
	_skill = 1
	_state = State.FOLLOW
	_dragging = false
	queue_redraw()

func _switch_skill(s: int):
	if not _control:
		return
	if _state == State.AIM:
		_dragging = false
		_state = State.FOLLOW
	_skill = s
	queue_redraw()
	print("当前功能：", _skill)

func _press_skill():
	match _skill:
		1:
			_state = State.AIM
			_dragging = true
			_drag_start = get_global_mouse_position()
			_drag_now = _drag_start
			queue_redraw()
		2:
			_skill2_press()
		3:
			_skill3_press()

func _skill2_press():
	print("功能2：待实现")

func _skill3_press():
	print("功能3：待实现")

func _follow(delta, dampening: float):
	var target: Vector2 = player.global_position + offset + Vector2(0, sin(_time * bob_speed) * bob_height)
	var weight: float = 1.0 - exp(-follow_speed * dampening * delta)
	global_position = global_position.lerp(target, weight)

func _pull_vector() -> Vector2:
	return (_drag_start - _drag_now).limit_length(max_drag_px)

func _power() -> float:
	return clampf(_pull_vector().length() / max_drag_px, 0.0, 1.0)

func _throw_velocity() -> Vector2:
	var pull: Vector2 = _pull_vector()
	if pull.length() < 14.0:
		return Vector2.ZERO
	var p: float = clampf(pull.length() / max_drag_px, 0.0, 1.0)
	var speed: float = min_throw_speed + (max_throw_speed - min_throw_speed) * pow(p, 0.7)
	return pull.normalized() * speed

func _release_throw():
	_dragging = false
	queue_redraw()
	var v: Vector2 = _throw_velocity()
	if v == Vector2.ZERO:
		_state = State.FOLLOW
		return
	_velocity = v
	_fly_time = 0.0
	_resting = false
	_state = State.FLY

func _update_fly(delta):
	_fly_time += delta
	if not _resting:
		_velocity.y += gravity * delta
	var from: Vector2 = global_position
	_move_with_collisions(delta)
	_check_hit(from, global_position)
	if _state == State.FLY and _fly_time > max_fly_time:
		_start_return()

func _exclude_rids() -> Array[RID]:
	var arr: Array[RID] = []
	if exclude_player_from_collision and player is CollisionObject2D:
		arr.append((player as CollisionObject2D).get_rid())
	return arr

func _move_with_collisions(delta):
	if _velocity.length() < 0.01:
		return
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = collide_radius
	var motion: Vector2 = _velocity * delta
	for i in range(4):
		if motion.length() < 0.01:
			break
		var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D(0.0, global_position)
		params.motion = motion
		params.collision_mask = collide_mask
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.exclude = _exclude_rids()
		var res: PackedFloat32Array = space.cast_motion(params)
		var safe: float = res[0]
		if safe >= 1.0:
			global_position += motion
			break
		global_position += motion * safe
		var info_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		info_params.shape = shape
		info_params.transform = Transform2D(0.0, global_position)
		info_params.collision_mask = collide_mask
		info_params.collide_with_bodies = true
		info_params.collide_with_areas = false
		info_params.exclude = _exclude_rids()
		var info: Dictionary = space.get_rest_info(info_params)
		if info.is_empty():
			_velocity = Vector2.ZERO
			break
		var normal: Vector2 = info["normal"]
		var speed_before: float = _velocity.length()
		_velocity = _velocity.bounce(normal) * bounce
		global_position += normal * 0.6
		_on_wall_bounce(speed_before)
		if speed_before < 70.0:
			_velocity = Vector2.ZERO
			_resting = true
			break
		motion = _velocity * delta

func _check_hit(from: Vector2, to: Vector2):
	for b in get_tree().get_nodes_in_group("button_target"):
		var e: Node2D = b as Node2D
		if e == null:
			continue
		var radius: float = 34.0
		var r: Variant = e.get("hit_radius")
		if typeof(r) == TYPE_FLOAT or typeof(r) == TYPE_INT:
			radius = float(r)
		if _dist_to_segment(e.global_position, from, to) <= radius:
			if e.has_method("activate"):
				e.call("activate")
			_hit_feedback()
			_start_return()
			return

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _start_return():
	_state = State.RETURN
	_dragging = false
	_velocity = Vector2.ZERO
	_resting = false
	scale = Vector2.ONE
	modulate = Color.WHITE
	queue_redraw()

func _update_return(delta):
	var target: Vector2 = player.global_position + offset
	var to_target: Vector2 = target - global_position
	if to_target.length() < 24.0:
		global_position = target
		_state = State.FOLLOW
		queue_redraw()
		return
	var speed: float = clampf(return_speed + to_target.length() * 3.0, return_speed, 2600.0)
	global_position += to_target.normalized() * speed * delta

func _hit_feedback():
	scale = Vector2(1.6, 0.5)
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	modulate = Color(1.6, 1.6, 1.6)
	var mt: Tween = create_tween()
	mt.tween_property(self, "modulate", Color.WHITE, 0.18)
	_shake(shake_strength, shake_duration)

func _on_wall_bounce(speed: float):
	var k: float = clampf(speed / 1400.0, 0.0, 1.0)
	scale = Vector2(1.0 + 0.35 * k, 1.0 - 0.25 * k)
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shake(2.0 + 4.0 * k, 0.1)

func _shake(strength: float, duration: float):
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var t: Tween = create_tween()
	var steps: int = 6
	for i in range(steps):
		t.tween_property(cam, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), duration / steps)
	t.tween_property(cam, "offset", Vector2.ZERO, duration / steps)

func _preview_points() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var vel: Vector2 = _throw_velocity()
	if vel == Vector2.ZERO:
		return pts
	var pos: Vector2 = Vector2.ZERO
	var step: float = 0.03
	pts.append(pos)
	for i in range(60):
		vel.y += gravity * step
		pos += vel * step
		pts.append(pos)
		if pos.y > 700.0:
			break
	return pts

func _draw():
	if _control:
		_draw_skill_pips()
	if _state != State.AIM:
		return
	var p: float = _power()
	var col: Color = dash_color.lerp(power_color, p)
	var mouse_local: Vector2 = to_local(_drag_now)
	draw_line(Vector2.ZERO, mouse_local, Color(1, 1, 1, 0.1 + 0.15 * p), 2.0)
	draw_circle(mouse_local, 6.0, Color(col.r, col.g, col.b, 0.35))
	var pts: PackedVector2Array = _preview_points()
	if pts.size() < 2:
		return
	_draw_dashed(pts, col, 2.0 + 2.0 * p)
	draw_circle(pts[pts.size() - 1], 3.0 + 3.0 * p, col)

func _draw_skill_pips():
	var colors: Array[Color] = [power_color, Color(0.4, 0.9, 1.0), Color(0.7, 0.6, 1.0)]
	for i in range(3):
		var active: bool = (_skill == i + 1)
		var col: Color = colors[i] if active else Color(0.6, 0.6, 0.6, 0.3)
		var r: float = 4.5 if active else 3.0
		draw_circle(Vector2(-14.0 + i * 14.0, -44.0), r, col)

func _draw_dashed(pts: PackedVector2Array, col: Color, width: float):
	var dash: float = 9.0
	var gap: float = 7.0
	var drawing: bool = true
	var acc: float = 0.0
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var seg_len: float = a.distance_to(b)
		if seg_len <= 0.0001:
			continue
		var t: float = 0.0
		while t < seg_len:
			var limit: float = (dash if drawing else gap) - acc
			var step: float = minf(limit, seg_len - t)
			if drawing and step > 0.0:
				draw_line(a.lerp(b, t / seg_len), a.lerp(b, (t + step) / seg_len), col, width)
			t += step
			acc += step
			if acc >= (dash if drawing else gap) - 0.0001:
				acc = 0.0
				drawing = not drawing
