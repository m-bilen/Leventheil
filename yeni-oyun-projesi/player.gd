extends CharacterBody3D
signal dash_started
signal dash_ended
signal spikes_toggled
signal jump_started
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 0.15
var attack_timer = 0.0
const ACCEL = 12.0        
const FRICTION = 14.0    
const ROT_SPEED = 10.0   
const MAX_HEALTH = 5
var health = MAX_HEALTH
var weight = 0.0
@onready var model = $"character-female-a2"
@onready var attack_area = $"character-female-a2/AttackArea"
var bob_time = 0.0
var was_on_floor = true 
const SPEED = 5.0
const RUN_SPEED = 9.0
const DASH_SPEED = 20.0
const DASH_TIME = 0.2
var is_dashing = false 
var dash_timer = 0.0
var dash_direction = Vector3.ZERO
const DASH_COOLDOWN = 0.8
var cooldown_timer = 0



func _physics_process(delta: float) -> void:
	# --- Yerçekimi ---
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = 5.0
		model.scale = Vector3(0.7,1.3,0.7)
		jump_started.emit()
	var target_scale = Vector3.ONE
	if Input.is_action_just_pressed("toggle_spikes"):
		spikes_toggled.emit()
	if is_dashing:
		target_scale = Vector3(1.3,0.5,1.3)
	model.scale = model.scale.lerp(target_scale, 10.0 * delta)
	cooldown_timer -= delta
	attack_timer -= delta
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0:
		attack()
		attack_timer = ATTACK_COOLDOWN


	# --- Girdi yönü ---
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	var current_speed = SPEED
	if Input.is_action_just_pressed("dash") and not is_dashing and direction and cooldown_timer <=0 :
		print("direction: ", direction, " | dashing: ", is_dashing, " | cooldown: ", cooldown_timer)
		is_dashing = true
		cooldown_timer = DASH_COOLDOWN
		dash_started.emit()
		print("DASH BASLADI")
		dash_timer = DASH_TIME
		dash_direction = direction
		
	if Input.is_action_pressed("run"):
		current_speed = RUN_SPEED
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

	# --- Modeli hareket yönüne döndür ---
	if direction:
		var target_angle = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, ROT_SPEED * delta)

	# --- Procedural canlılık: yürürken zıplama (bob) + eğilme (tilt) ---
	var speed_ratio = Vector2(velocity.x, velocity.z).length() / SPEED
	if speed_ratio > 0.1:
		bob_time += delta * 12.0
		model.position.y = abs(sin(bob_time)) * 0.08 * speed_ratio
		model.rotation.x = -speed_ratio * 0.15
	else:
		bob_time = 0.0
		model.position.y = lerp(model.position.y, 0.0, 10.0 * delta)
		model.rotation.x = lerp_angle(model.rotation.x, 0.0, 10.0 * delta)
		if is_on_floor() and not was_on_floor:
			model.scale = Vector3(1.3,0.7,1)
		was_on_floor = is_on_floor()
func take_damage(amount: int) -> void:
	health -= amount
	get_parent().get_node("CanvasLayer/HealthBar").value = health
	get_parent().get_node("Camera3D").shake(0.6)
	print("oyuncu can :",health)
	if health <= 0:
		print("ÖLDÜN")
		get_tree().reload_current_scene()
func attack() -> void:
	print("saldiri! icindekiler: ", attack_area.get_overlapping_bodies())
	var mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_from = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	var ground = Plane(Vector3.UP, global_position.y)
	var hit = ground.intersects_ray(ray_from, ray_dir)
	
	if hit != null:
		var aim = hit - global_position
		model.rotation.y = atan2(aim.x, aim.z)
	
	await get_tree().physics_frame
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
