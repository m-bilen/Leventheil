extends EnemyBase
const FlashMaterial = preload("res://enemies/flash_material.tres")
const TURN_SPEED = 10.0
@onready var body: Node3D = $Body
@onready var eyes = [$Body/EyeL, $Body/EyeR]
@onready var root_vines: Node3D = $Body/RootVines
var eye_material: StandardMaterial3D
const FoxfireCracks = preload("res://enemies/foxfire_cracks.gdshader")
const MUSHROOM_COUNT = 3
const WINDUP_EYE_BOOST = 1.4
const WINDUP_CRACK_BOOST = 2.0
@export var glow_noise: Texture2D
@onready var trunk: MeshInstance3D = $Body/Trunk
var crack_material: ShaderMaterial
var eye_energy = 1.0
const KNOCKBACK_FORCE = 8.0
const KNOCKBACK_TIME = 0.2
const FLANK_DISTANCE = 4.0
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
var speed = SPEED
var hop_phase = 0.0
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 1.0
const ATTACK_RANGE = 1.5
const WINDUP_TIME = 0.4
var windup_timer = 0.0
var attack_timer = 0.0
const SPEED = 2.0

func _ready()-> void:
	eye_material = $Body/EyeL.material_override.duplicate()
	for eye in eyes:
		eye.material_override = eye_material
	super()
	eye_energy = eye_material.emission_energy_multiplier
	crack_material = ShaderMaterial.new()
	crack_material.shader = FoxfireCracks
	crack_material.set_shader_parameter("noise", glow_noise)
	crack_material.set_shader_parameter("glow_color", spirit_color)
	trunk.material_overlay = crack_material
	grow_mushrooms()
	var angle = randf() * TAU
	flank_dir = Vector3(cos(angle), 0, sin(angle))
	base_body_y = body.position.y
	base_body_scale = body.scale 
	speed = SPEED * randf_range(0.85, 1.15)
	hop_phase = randf() * PI
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = knockback_dir.x * KNOCKBACK_FORCE
		velocity.z = knockback_dir.z * KNOCKBACK_FORCE
	else :
		var direction = get_chase_direction()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
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
	return dir.normalized()

func _on_damaged() -> void:
	body.scale = base_body_scale * Vector3(1.25, 0.75, 1.25)
	knockback_dir = (global_position - player.global_position).normalized()
	knockback_dir.y = 0
	knockback_timer = KNOCKBACK_TIME
	interrupt()

func start_windup() -> void:
	windup_timer = WINDUP_TIME
	set_charged(true)

func strike() -> void:
	strike_pose_timer = STRIKE_POSE_TIME 
	set_charged(false)
	attack_timer = ATTACK_COOLDOWN
	if distance_to_player() < ATTACK_RANGE and player.is_on_floor():
		player.take_damage(ATTACK_DAMAGE)

func interrupt() -> void:
	if windup_timer <= 0.0:
		return
	windup_timer = 0.0
	attack_timer = ATTACK_COOLDOWN
	set_charged(false)

func face_player(delta: float) -> void:
	var to_player = player.global_position - global_position
	var target = atan2(to_player.x, to_player.z)
	body.rotation.y = lerp_angle(body.rotation.y, target, TURN_SPEED * delta)

func _apply_color(color: Color) -> void:
	eye_material.albedo_color = color
	eye_material.emission = color

func _apply_flash(on: bool) -> void:
	for part in body.get_children():
		if part is MeshInstance3D:
			part.material_overlay = FlashMaterial if on else null
	if not on:
		trunk.material_overlay = crack_material

func _apply_rooted(on: bool) -> void:
	root_vines.bind(on)		

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
		hop = abs(sin(hop_time + hop_phase)) * HOP_HEIGHT
	else:
		hop_time = 0.0
	body.position.y = base_body_y + hop
	body.rotation.x = lerp_angle(body.rotation.x, lean, POSE_SPEED * delta)
	var target_scale = base_body_scale * Vector3(2.0 - squash, squash, 2.0 - squash)
	body.scale = body.scale.lerp(target_scale, POSE_SPEED * delta)

func set_charged(on: bool) -> void:
	eye_material.emission_energy_multiplier = eye_energy * (WINDUP_EYE_BOOST if on else 1.0)
	crack_material.set_shader_parameter("glow_energy", WINDUP_CRACK_BOOST if on else 1.0)

func grow_mushrooms() -> void:
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.016
	stem_mesh.bottom_radius = 0.024
	stem_mesh.height = 0.12
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = 0.06
	cap_mesh.height = 0.06
	cap_mesh.is_hemisphere = true
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.7, 0.75, 0.65)
	for i in MUSHROOM_COUNT:
		var a = TAU * i / MUSHROOM_COUNT + randf_range(-0.4, 0.4)
		var r = randf_range(0.06, 0.13)
		var mushroom = Node3D.new()
		body.add_child(mushroom)
		mushroom.position = Vector3(cos(a) * r, 1.0, sin(a) * r)
		mushroom.basis = Basis(Vector3(-sin(a), 0.0, cos(a)), -0.4) * Basis.from_scale(Vector3.ONE * randf_range(0.7, 1.2))
		var stem = MeshInstance3D.new()
		stem.mesh = stem_mesh
		stem.material_override = stem_material
		stem.position.y = stem_mesh.height / 2.0
		mushroom.add_child(stem)
		var cap = MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.material_override = eye_material
		cap.position.y = stem_mesh.height
		mushroom.add_child(cap)
