extends EnemyBase
const GroundBurstScene = preload("res://enemies/ground_burst.tscn")
enum State { CHASE, WINDUP , ATTACK , RECOVER, STUNNED}
@export var slam_chance: float = 0.0
@export var speed: float = 1.5
@export var windup_time: float = 0.8
@export var attack_damage: int = 2
@export var parries_to_kill: int = 3
@export var parry_only: bool = false
@export var enrage_windup_multiplier: float = 1.0
@export var display_name: String = ""
@export var parry_window: float = 0.3
var is_enraged = false 
@onready var parry_pips : Label3D = $ParryPips
const SLAM_COLOR = Color(0.8, 0.2, 1.0)
const SLAM_RADIUS = 4.5
const SLAM_DAMAGE = 2
const WINDOW_COLOR = Color(1.0, 0.5, 1.0)
const ATTACK_RANGE = 2.5
const ATTACK_TIME = 0.2
const RECOVER_TIME = 1.0
const STUN_TIME = 2.0
const TURN_SPEED = 4.0
@onready var model: Node3D = get_node_or_null("Model")
var parry_count = 0
var state: State = State.CHASE
var state_timer = 0.0
var window_open = false
var is_slam = false

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
	if model and (state == State.CHASE or state == State.WINDUP):
		face_player(delta)
	apply_status_effects()
	if model:
		model.set_moving(Vector2(velocity.x, velocity.z).length() > 0.3)
	move_and_slide()
func do_chase() -> void:
	var dist = distance_to_player()
	if dist < ATTACK_RANGE:
		enter_state(State.WINDUP)
		return
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
func do_windup() -> void:
	velocity.x = 0
	velocity.z = 0
	if not is_slam and not window_open and state_timer <= parry_window:
		open_parry_window()
	if state_timer <= 0.0:
		enter_state(State.ATTACK)

func open_parry_window() -> void:
	window_open = true
	set_color(WINDOW_COLOR)
	if model:
		model.pose_open()
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
			state_timer = windup_time
			window_open = false
			is_slam = randf() < slam_chance
			if is_slam:
				set_color(SLAM_COLOR)
				spawn_slam_wave()
			else:
				set_color(Color.YELLOW)
		State.ATTACK:
			state_timer = ATTACK_TIME
			set_color(Color.RED)
			if not is_slam:
				hit_player()
			Events.camera_shake_requested.emit(0.6 if is_slam else 0.3)
		State.RECOVER:
			state_timer = RECOVER_TIME
			set_color(Color.GRAY)
		State.CHASE:
			set_color(base_color)
		State.STUNNED:
			state_timer = STUN_TIME
			set_color(Color.CYAN)
	update_model_pose()
func hit_player() -> void:
	var dist = distance_to_player()
	if dist< ATTACK_RANGE:
		player.take_damage(attack_damage)

func can_be_parried() -> bool:
	return state == State.WINDUP and window_open
func on_parried() -> bool:
	parry_count += 1
	update_parry_pips()
	if not is_enraged and enrage_windup_multiplier < 1.0 and parry_count * 2 >= parries_to_kill:
		is_enraged = true
		windup_time *= enrage_windup_multiplier
		base_color = Color(0.55, 0.0, 0.1)
	enter_state(State.STUNNED)
	return parry_count >= parries_to_kill
func do_stunned() -> void:
	velocity.x = 0
	velocity.z = 0
	if state_timer <= 0.0:
		enter_state(State.CHASE)
func take_damage(amount: int) -> void:
	if parry_only:
		flash()
		return
	super(amount)
func update_parry_pips() -> void:
	var remaining = parries_to_kill - parry_count
	parry_pips.text = "• ".repeat(remaining).strip_edges()
func _ready() -> void:
	super()
	if model:
		base_color = model.get_base_color()
		current_color = base_color
	update_parry_pips()
	if display_name != "":
		Events.boss_spawned.emit(display_name)
		Events.camera_focus_requested.emit(global_position, 1.0)
		Events.camera_shake_requested.emit(0.8)

func face_player(delta: float) -> void:
	var to_player = player.global_position - global_position
	var target = atan2(to_player.x, to_player.z)
	model.rotation.y = lerp_angle(model.rotation.y, target, TURN_SPEED * delta)

func _apply_color(color: Color) -> void:
	if model:
		model.set_color(color)
	else:
		super(color)

func _apply_flash(on: bool) -> void:
	if model:
		model.set_flash(on)
	else:
		super(on)

func _apply_rooted(on: bool) -> void:
	if model:
		model.set_rooted(on)
	else:
		super(on)

func update_model_pose() -> void:
	if not model:
		return
	match state:
		State.CHASE:
			model.pose_idle()
		State.WINDUP:
			if is_slam:
				model.pose_slam()
			else:
				model.pose_windup()
		State.ATTACK:
			model.pose_strike()
		State.RECOVER:
			model.pose_recover()
		State.STUNNED:
			model.pose_stunned()

func spawn_slam_wave() -> void:
	var wave = GroundBurstScene.instantiate()
	wave.delay = windup_time
	wave.radius = SLAM_RADIUS
	wave.damage = SLAM_DAMAGE
	get_tree().current_scene.add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.25, global_position.z)
