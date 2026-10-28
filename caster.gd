extends EnemyBase

const GroundWaveScene = preload("res://ground_wave.tscn")
const SPEED = 2.5
const KEEP_MIN = 6.0
const KEEP_MAX = 10.0
const ARENA_RADIUS = 20.0
const WINDUP_TIME = 0.8
const ATTACK_COOLDOWN = 2.5
const WINDUP_COLOR = Color(0.8, 0.2, 1.0)

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
	var dir = player.global_position - global_position
	dir.y = 0
	if dir.length() == 0.0:
		return
	var wave = GroundWaveScene.instantiate()
	get_tree().current_scene.add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.45, global_position.z)
	wave.launch(dir.normalized())

func interrupt() -> void:
	if windup_timer <= 0.0:
		return
	windup_timer = 0.0
	attack_timer = ATTACK_COOLDOWN 
	set_color(base_color)

func _on_damaged() -> void:
	interrupt()
