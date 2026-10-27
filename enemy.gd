extends EnemyBase
const KNOCKBACK_FORCE = 8.0
const KNOCKBACK_TIME = 0.2
const FLANK_DISTANCE = 4.0
const SEPARATION_RADIUS = 1.6
const SEPARATION_FORCE = 1.5
const ENGAGE_RADIUS = 1.2
var flank_dir = Vector3.ZERO
var knockback_timer = 0
var knockback_dir = Vector3.ZERO
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0
const SPEED = 2.0
func _ready()-> void:
	super()
	var angle = randf() * TAU
	flank_dir = Vector3(cos(angle), 0, sin(angle))
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
	apply_status_effects()
	move_and_slide()
	attack_timer -= delta
	if attack_timer <= 0:
		var dist = global_position.distance_to(player.global_position)
		if dist < 1.5 :
			player.take_damage(ATTACK_DAMAGE)
			attack_timer = ATTACK_COOLDOWN
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
	knockback_dir = (global_position - player.global_position).normalized()
	knockback_dir.y = 0
	knockback_timer = KNOCKBACK_TIME
