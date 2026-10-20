extends CharacterBody3D
@onready var mesh = $MeshInstance3D
var flash_timer = 0.0
var base_color = Color.WHITE
const KNOCKBACK_FORCE = 8.0
const KNOCKBACK_TIME = 0.2
var knockback_timer = 0
var knockback_dir = Vector3.ZERO
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0
const SPEED = 2.0
const MAX_HEALTH = 3
var health = MAX_HEALTH
@onready var player = get_parent().get_node("Player")
func _ready()-> void:
	add_to_group("enemies")
	mesh.mesh = mesh.mesh.duplicate()
	mesh.mesh.material = mesh.mesh.material.duplicate()
	base_color = mesh.mesh.material.albedo_color
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	flash_timer = 0.1
	mesh.mesh.material.albedo_color = Color.WHITE
	health -= amount
	knockback_dir = (global_position - player.global_position).normalized()
	knockback_dir.y = 0
	knockback_timer = KNOCKBACK_TIME
	if health <= 0:
		Events.enemy_died.emit(self)
		set_physics_process(false)
		queue_free()
func _physics_process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			mesh.mesh.material.albedo_color = base_color
	if not is_on_floor():
		velocity += get_gravity() * delta
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = knockback_dir.x * KNOCKBACK_FORCE
		velocity.z = knockback_dir.z * KNOCKBACK_FORCE
	else :
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	move_and_slide()
	attack_timer -= delta
	if attack_timer <= 0:
		var dist = global_position.distance_to(player.global_position)
		if dist < 1.5 :
			player.take_damage(ATTACK_DAMAGE)
			attack_timer = ATTACK_COOLDOWN
