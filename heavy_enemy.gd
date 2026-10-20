extends CharacterBody3D
enum State { CHASE, WINDUP , ATTACK , RECOVER, STUNNED}
const SPEED = 1.5
const ATTACK_RANGE = 2.5
const WINDUP_TIME = 0.8
const ATTACK_TIME = 0.2
const RECOVER_TIME = 1.0
const ATTACK_DAMAGE = 2
const MAX_HEALTH = 30
const STUN_TIME = 2.0
const PARRIES_TO_KILL = 3
var parry_count = 0
signal died
var state: State = State.CHASE
var state_timer = 0.0
var health = MAX_HEALTH
@onready var player = get_parent().get_node("Player")
@onready var mesh = $MeshInstance3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	state_timer -= delta
	match state:
		State.CHASE:
			do_chase()
		State.WINDUP:
			do_windup()
		State.ATTACK:
			do_attack()
		State.RECOVER:
			do_recover()
		State.STUNNED:
			do_stunned()
	move_and_slide()
func do_chase() -> void:
	var dist = global_position.distance_to(player.global_position)
	if dist < ATTACK_RANGE:
		enter_state(State.WINDUP)
		return
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
func do_windup() -> void:
	velocity.x = 0
	velocity.z = 0
	if state_timer <=0.0:
		enter_state(State.ATTACK)
func do_attack() -> void:
	if state_timer <= 0.0:
		enter_state(State.RECOVER)
func do_recover() -> void:
	if state_timer <= 0.0:
		enter_state(State.CHASE)
func enter_state(new_state: State) -> void:
	state = new_state 
	match new_state:
		State.WINDUP:
			state_timer = WINDUP_TIME
			mesh.mesh.material.albedo_color = Color.YELLOW
		State.ATTACK:
			state_timer = ATTACK_TIME
			mesh.mesh.material.albedo_color = Color.RED
			hit_player()
		State.RECOVER:
			state_timer = RECOVER_TIME
			mesh.mesh.material.albedo_color = Color.GRAY
		State.CHASE:
			mesh.mesh.material.albedo_color = base_color
		State.STUNNED:
			state_timer = STUN_TIME
			mesh.mesh.material.albedo_color = Color.CYAN
func hit_player() -> void:
	var dist = global_position.distance_to(player.global_position)
	if dist< ATTACK_RANGE:
		player.take_damage(ATTACK_DAMAGE)
func take_damage(amount:int) -> void:
	health -= amount
	if health <= 0:
		died.emit()
		set_physics_process(false)
		queue_free()
var base_color = Color.WHITE
func _ready() -> void:
	add_to_group("enemies")
	mesh.mesh = mesh.mesh.duplicate()
	mesh.mesh.material = mesh.mesh.material.duplicate()
	base_color = mesh.mesh.material.albedo_color
func can_be_parried() -> bool:
	return state == State.WINDUP
func on_parried() -> bool:
	parry_count += 1
	print("parry sayisi: ", parry_count, " | can: ", health)
	enter_state(State.STUNNED)
	return parry_count >= PARRIES_TO_KILL
func do_stunned() -> void:
	velocity.x = 0
	velocity.z = 0
	if state_timer <= 0.0:
		enter_state(State.CHASE)
