extends CharacterBody3D
signal dash_started
signal dash_ended
signal spikes_toggled
signal jump_started(aim_dir: Vector3)
signal parried
const ANIM_IDLE = "mixamo_com"
const ANIM_RUN = "Running/mixamo_com"
const ANIM_JUMP = "Jumping Up/mixamo_com"
const ANIM_ATTACK = "Stable Sword Outward Slash/mixamo_com"
const ANIM_DASH = "Standing Dodge Forward/mixamo_com"
const ANIM_FALL = "falling/mixamo_com"
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 0.15
const PARRY_RANGE = 3.0
const ATTACK_COOLDOWN_HEAVY = 0.55
const ATTACK_COOLDOWN_LIGHT = 0.22
const ATTACK_SPEED_HEAVY = 0.8
const ATTACK_SPEED_LIGHT = 1.6
const ATTACK_START_LIGHT = 0.7
const ATTACK_START_HEAVY = 0.0
const ATTACK_TIME_LIGHT = 0.5
const ATTACK_TIME_HEAVY = 1.2
const MAX_WEIGHT = 8.0
var hit_stop_count = 0
var in_finisher = false
var action_timer = 0.0
var attack_timer = 0.0
const ACCEL = 12.0        
const FRICTION = 14.0    
const ROT_SPEED = 10.0   
const MAX_HEALTH = 5
var health = MAX_HEALTH
var weight = 0.0
var action_anim = false
@onready var model = $Model
@onready var attack_area = $Model/AttackArea
@onready var anim = $Model/AnimationPlayer
var bob_time = 0.0
var was_on_floor = true 
const SPEED_LIGHT = 6.0
const SPEED_HEAVY = 4.0
const RUN_SPEED_LIGHT = 10.5
const RUN_SPEED_HEAVY = 7.0
const DASH_SPEED = 20.0
const DASH_TIME = 0.2
var is_dashing = false 
var dash_timer = 0.0
var dash_direction = Vector3.ZERO
const DASH_COOLDOWN = 0.8
var cooldown_timer = 0



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = 5.0
		model.scale = Vector3(0.7,1.3,0.7)
		jump_started.emit(get_aim_direction())
	var target_scale = Vector3.ONE
	if Input.is_action_just_pressed("toggle_spikes"):
		spikes_toggled.emit()
	if is_dashing:
		target_scale = Vector3(1.3,0.5,1.3)
	model.scale = model.scale.lerp(target_scale, 10.0 * delta)
	cooldown_timer = max(cooldown_timer - delta, 0.0)
	attack_timer = max(attack_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
		attack()
		attack_timer = lerp(ATTACK_COOLDOWN_LIGHT, ATTACK_COOLDOWN_HEAVY,get_weight_ratio())

	action_timer = max(action_timer - delta, 0.0)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	var t = get_weight_ratio()
	var walk_speed = lerp(SPEED_LIGHT, SPEED_HEAVY, t)
	var current_speed = walk_speed
	if Input.is_action_just_pressed("dash") and not is_dashing and direction and cooldown_timer <=0 :
		is_dashing = true
		anim.play(ANIM_DASH)
		cooldown_timer = DASH_COOLDOWN
		dash_started.emit()
		if try_parry():
			parried.emit()
			cooldown_timer = 0.0
			hit_stop(0.15)
			get_parent().get_node("Camera3D").shake(0.5)
		dash_timer = DASH_TIME
		dash_direction = direction
		
	if Input.is_action_pressed("run"):
		current_speed = lerp(RUN_SPEED_LIGHT, RUN_SPEED_HEAVY, t)
	if is_dashing:
		var dash_speed = DASH_SPEED - weight
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		dash_timer -= delta
		if dash_timer <=0:
			is_dashing = false
			dash_ended.emit()
	else:
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, ACCEL * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
	move_and_slide()
	update_animation()

	# --- Modeli hareket yönüne döndür ---
	if direction:
		var target_angle = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, ROT_SPEED * delta)

	# --- Procedural canlılık: yürürken zıplama (bob) + eğilme (tilt) ---
	var speed_ratio = Vector2(velocity.x, velocity.z).length() / walk_speed
	if speed_ratio > 0.1:
		bob_time += delta * 12.0
		model.position.y = abs(sin(bob_time)) * 0.08 * speed_ratio
		model.rotation.x = -speed_ratio * 0.15
	else:
		bob_time = 0.0
		model.position.y = lerp(model.position.y, 0.0, 10.0 * delta)
		model.rotation.x = lerp_angle(model.rotation.x, 0.0, 10.0 * delta)
	if is_on_floor() and not was_on_floor:
		model.scale = Vector3(1.3,0.7,1.3)
	was_on_floor = is_on_floor() 
func take_damage(amount: int) -> void:
	health -= amount
	get_parent().get_node("CanvasLayer/HealthBar").value = health
	get_parent().get_node("Camera3D").shake(0.6)
	print("oyuncu can :",health)
	if health <= 0:
		print("ÖLDÜN")
		get_tree().reload_current_scene.call_deferred()
func attack() -> void:
	var aim = get_aim_direction()
	if aim != Vector3.ZERO:
		model.rotation.y = atan2(aim.x, aim.z)
	
	var t = get_weight_ratio()
	var anim_speed = lerp(ATTACK_SPEED_LIGHT, ATTACK_SPEED_HEAVY, t)
	var anim_start = lerp(ATTACK_START_LIGHT, ATTACK_START_HEAVY, t)
	var anim_dur = lerp(ATTACK_TIME_LIGHT, ATTACK_TIME_HEAVY, t)
	
	anim.play(ANIM_ATTACK, -1.0, anim_speed)
	anim.seek(anim_start, true)
	action_timer = anim_dur / anim_speed
	
	await get_tree().physics_frame
	
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
			hit_stop(0.15)
			get_parent().get_node("Camera3D").shake(0.15)

func update_animation() -> void:
	if action_timer > 0:
		return
	
	if not is_on_floor():
		if velocity.y > 0.0:
			play_anim(ANIM_JUMP)
		else:
			play_anim(ANIM_FALL)
		return
	
	var speed = Vector2(velocity.x, velocity.z).length()
	if speed > 0.5:
		play_anim(ANIM_RUN)
	else:
		play_anim(ANIM_IDLE)
func play_anim(anim_name: String) -> void:
	if anim.current_animation != anim_name:
		anim.play(anim_name)
func get_aim_direction() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_from = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	var ground = Plane(Vector3.UP , global_position.y)
	var hit = ground.intersects_ray(ray_from , ray_dir)
	if hit == null:
		return Vector3.ZERO
	var aim = hit - global_position
	aim.y = 0
	return aim.normalized()

func hit_stop(duration: float) -> void:
	if in_finisher:
		return
	hit_stop_count += 1
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration,true, false, true).timeout
	hit_stop_count -= 1
	if hit_stop_count <= 0:
		Engine.time_scale = 1.0


func try_parry() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_method("can_be_parried"):
			continue
		if not node.can_be_parried():
			continue
		if global_position.distance_to(node.global_position) > PARRY_RANGE:
			continue
		var is_final = node.on_parried()
		if is_final:
			finisher(node)
		return true
	return false

func finisher(target) -> void:
	in_finisher = true
	if is_instance_valid(target):
		target.set_physics_process(false)
	var cam = get_parent().get_node("Camera3D")
	Engine.time_scale = 0.1
	cam.focus_zoom(0.9)
	cam.shake(1.0)
	await get_tree().create_timer(0.6,true,false,true).timeout
	Engine.time_scale = 1.0
	in_finisher = false
	if is_instance_valid(target):
		target.die()
	print("FINISHER!")
func get_weight_ratio() -> float:
	return clamp(weight / MAX_WEIGHT, 0.0, 1.0)
