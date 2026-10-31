extends EnemyBase
const FlashMaterial = preload("res://enemies/flash_material.tres")
const TURN_SPEED = 10.0
@onready var body: Node3D = $Body
@onready var eyes = [$Body/EyeL, $Body/EyeR]
@onready var root_vines: Node3D = $Body/RootVines
var eye_material: StandardMaterial3D
const KNOCKBACK_FORCE = 8.0
const KNOCKBACK_TIME = 0.2
const FLANK_DISTANCE = 4.0
const SEPARATION_RADIUS = 1.6
const SEPARATION_FORCE = 1.5
const ENGAGE_RADIUS = 1.2
const HOP_HEIGHT = 0.18
const HOP_SPEED = 9.0
const POSE_SPEED = 12.0
const REST_LEAN = 0.25
const WINDUP_LEAN = -0.2
const STRIKE_LEAN = 0.75
const STRIKE_POSE_TIME = 0.15
var flank_dir = Vector3.ZERO
var knockback_timer = 0
var knockback_dir = Vector3.ZERO
var hop_time = 0.0
var strike_pose_timer = 0.0
var base_body_y = 0.0
var base_body_scale = Vector3.ONE
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 1.0
const ATTACK_RANGE = 1.5
const WINDUP_TIME = 0.4
const WINDUP_COLOR = Color(1.0, 0.55, 0.0)
var windup_timer = 0.0
var attack_timer = 0.0
const SPEED = 2.0
func _ready()-> void:
	super()
	eye_material = $Body/EyeL.material_override.duplicate()
	for eye in eyes:
		eye.material_override = eye_material
	base_color = eye_material.emission
	current_color = base_color
	var angle = randf() * TAU
	flank_dir = Vector3(cos(angle), 0, sin(angle))
	base_body_y = body.position.y
	base_body_scale = body.scale 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = knockback_dir.x * KNOCKBACK_FORCE
		velocity.z = knockback_dir.z * KNOCKBACK_FORCE
	else :
		var direction = get_chase_direction()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	if windup_timer > 0.0:
		velocity.x = 0
		velocity.z = 0
	apply_status_effects()
	move_and_slide()
	attack_timer = max(attack_timer - delta, 0.0)
	if windup_timer > 0.0:
		windup_timer -= delta
		if windup_timer <= 0.0:
			strike()
	elif attack_timer <= 0.0 and distance_to_player() < ATTACK_RANGE: 
		start_windup()
	animate_body(delta)
func get_chase_direction() -> Vector3:
	var to_player = player.global_position - global_position
	to_player.y = 0
	var dist = to_player.length()
	var flank = flank_dir * clamp(dist * 0.5, ENGAGE_RADIUS, FLANK_DISTANCE)
	var target = player.global_position + flank
	var dir = target - global_position
	dir.y = 0
	dir = dir.normalized() + get_separation() * SEPARATION_FORCE
	return dir.normalized()
func get_separation() -> Vector3:
	var push = Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var away = global_position - other.global_position
		away.y = 0
		var d = away.length()
		if d > 0.0 and d < SEPARATION_RADIUS:	
			push += away.normalized() * (1.0 -d / SEPARATION_RADIUS)
	return push
func _on_damaged() -> void:
	body.scale = base_body_scale * Vector3(1.25, 0.75, 1.25)
	knockback_dir = (global_position - player.global_position).normalized()
	knockback_dir.y = 0
	knockback_timer = KNOCKBACK_TIME
	interrupt()

func start_windup() -> void:
	windup_timer = WINDUP_TIME
	set_color(WINDUP_COLOR)

func strike() -> void:
	strike_pose_timer = STRIKE_POSE_TIME 
	set_color(base_color)
	attack_timer = ATTACK_COOLDOWN
	if distance_to_player() < ATTACK_RANGE and player.is_on_floor():
		player.take_damage(ATTACK_DAMAGE)

func interrupt() -> void:
	if windup_timer <= 0.0:
		return
	windup_timer = 0.0
	attack_timer = ATTACK_COOLDOWN
	set_color(base_color)

func face_player(delta: float) -> void:
	var to_player = player.global_position - global_position
	var target = atan2(to_player.x, to_player.z)
	body.rotation.y = lerp_angle(body.rotation.y, target, TURN_SPEED * delta)

func _apply_color(color: Color) -> void:
	eye_material.albedo_color = color
	eye_material.emission = color

func _apply_flash(on: bool) -> void:
	var overlay = FlashMaterial if on else null
	for part in body.get_children():
		if part is MeshInstance3D:
			part.material_overlay = overlay

func _apply_rooted(on: bool) -> void:
	root_vines.visible = on

func animate_body(delta: float) -> void:
	var lean = REST_LEAN
	var squash = 1.0
	if windup_timer > 0.0:
		lean = WINDUP_LEAN
		squash = 0.85
	elif strike_pose_timer > 0.0:
		strike_pose_timer -= delta
		lean = STRIKE_LEAN 
		squash = 1.15
	var hop = 0.0
	var moving = Vector2(velocity.x, velocity.z).length() > 0.3
	if moving and windup_timer <= 0.0:
		hop_time += delta * HOP_SPEED
		hop = abs(sin(hop_time)) * HOP_HEIGHT 
	else:
		hop_time = 0.0
	body.position.y = base_body_y + hop
	body.rotation.x = lerp_angle(body.rotation.x, lean, POSE_SPEED * delta)
	var target_scale = base_body_scale * Vector3(2.0 - squash, squash, 2.0 - squash)
	body.scale = body.scale.lerp(target_scale, POSE_SPEED * delta)
