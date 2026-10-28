extends EnemyBase

const GroundBurstScene = preload("res://ground_burst.tscn")
const SPEED = 4
const KEEP_MIN = 6.0
const KEEP_MAX = 10.0
const ARENA_RADIUS = 20.0
const WINDUP_TIME = 0.8
const ATTACK_COOLDOWN = 2.5
const WINDUP_COLOR = Color(0.8, 0.2, 1.0)
const LEAD_TIME = 0.6
const MAX_LEAD = 3.0

var windup_timer = 0.0
var attack_timer = 1.5

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var to_player = player.global_position - global_position
	to_player.y = 0
	var dist = to_player.length()
	var move = Vector3.ZERO
	if windup_timer <= 0.0:
		if dist < KEEP_MIN:
			move = -to_player.normalized()
		elif dist > KEEP_MAX:
			move = to_player.normalized()
	var next = global_position + move
	if Vector2(next.x, next.z).length() > ARENA_RADIUS:
		move = Vector3.ZERO
	velocity.x = move.x * SPEED
	velocity.z = move.z * SPEED
	apply_status_effects()
	move_and_slide()
	attack_timer = max(attack_timer - delta, 0.0)
	if windup_timer > 0.0:
		windup_timer -= delta
		if windup_timer <= 0.0:
			cast()
	elif attack_timer <= 0.0 and dist <= KEEP_MAX + 2.0:
		start_windup()

func start_windup() -> void:
	windup_timer = WINDUP_TIME 
	set_color(base_color)

func cast() -> void:
	set_color(base_color)
	attack_timer = ATTACK_COOLDOWN
	var burst = GroundBurstScene.instantiate()
	get_tree().current_scene.add_child(burst)
	var lead = player.velocity * LEAD_TIME
	lead.y = 0
	lead = lead.limit_length(MAX_LEAD)
	var target = player.global_position + lead
	burst.global_position = Vector3(target.x, 0.25, target.z)

func interrupt() -> void:
	if windup_timer <= 0.0:
		return
	windup_timer = 0.0
	attack_timer = ATTACK_COOLDOWN 
	set_color(base_color)

func _on_damaged() -> void:
	interrupt()
