extends EnemyBase

const GroundBurstScene = preload("res://enemies/ground_burst.tscn")
const SpikeIcon = preload("res://ui/icons/spike.svg")

enum State { CHASE, WINDUP, ATTACK, RECOVER, STUNNED, PUSH }

@export var is_boss: bool = false
@export var display_name: String = ""
@export var speed: float = 1.5
@export var windup_time: float = 0.8
@export var attack_damage: int = 2
@export var parries_to_kill: int = 3
@export var parry_only: bool = false
@export var parry_window: float = 0.3
@export var harvestable: bool = false
@export var can_push: bool = false
@export var slam_chance: float = 0.0
@export_group("Escalation")
@export var escalation_windup: Array[float] = []
@export var escalation_slam: Array[float] = []
@export var escalation_double: Array[float] = []

const TURN_SPEED = 4.0
const ATTACK_RANGE = 2.5
const ATTACK_TIME = 0.2
const RECOVER_TIME = 1.0
const STUN_TIME = 2.0
const FRONT_ANGLE = 60.0

const FOLLOWUP_CROUCH = 0.45
const LUNGE_SPEED = 5.0
const LUNGE_STOP = 1.6

const PUSH_RANGE = 2.2
const PUSH_WINDUP = 0.3
const PUSH_SWING = 0.15
const PUSH_FORCE = 12.0

const SLAM_RADIUS = 3
const SLAM_DAMAGE = 2

const PIP_SPACING = 0.32
const PIP_DIM = Color(1, 1, 1, 0.25)
const PIP_HEIGHT = 1.0

@onready var parry_pips: Node3D = $ParryPips

var state: State = State.CHASE
var state_timer = 0.0
var turn_speed = TURN_SPEED
var window_open = false
var is_slam = false
var is_followup = false
var lunge_dir = Vector3.ZERO
var push_ready = false
var push_done = false
var just_pushed = false
var parry_count = 0
var double_chance = 0.0
var start_windup_time = 0.0


func _ready() -> void:
	super()
	speed *= randf_range(0.9, 1.1)
	turn_speed = TURN_SPEED * randf_range(0.8, 1.2)
	start_windup_time = windup_time
	escalate()
	update_parry_pips()
	if is_boss:
		Events.boss_spawned.emit(display_name)
		Events.camera_focus_requested.emit(global_position, 1.0)
		Events.camera_shake_requested.emit(0.8)


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
		State.PUSH:
			do_push()
	if model and (state == State.CHASE or state == State.WINDUP):
		face_model_to_player(delta, turn_speed)
	apply_status_effects()
	if model:
		model.set_moving(Vector2(velocity.x, velocity.z).length() > 0.3)
	move_and_slide()
	if model and parry_pips.visible:
		parry_pips.global_position = model.get_head_point() + Vector3.UP * PIP_HEIGHT

func do_chase() -> void:
	var dist = distance_to_player()
	if dist >= PUSH_RANGE:
		push_ready = false
	if can_push and push_ready and is_in_front(player.global_position):
		enter_state(State.PUSH)
		return
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
	if is_followup and window_open and distance_to_player() > LUNGE_STOP:
		velocity.x = lunge_dir.x * LUNGE_SPEED
		velocity.z = lunge_dir.z * LUNGE_SPEED
	if state_timer <= 0.0:
		enter_state(State.ATTACK)


func do_attack() -> void:
	if state_timer <= 0.0:
		enter_state(State.RECOVER)


func do_recover() -> void:
	if state_timer <= 0.0:
		enter_state(State.CHASE)


func do_stunned() -> void:
	velocity.x = 0
	velocity.z = 0
	if state_timer <= 0.0:
		enter_state(State.CHASE)


func do_push() -> void:
	velocity.x = 0
	velocity.z = 0
	if not push_done and state_timer <= PUSH_SWING:
		push_done = true
		just_pushed = true
		if model:
			model.set_pose(EnemyModel.Pose.SHOVE)
		if distance_to_player() < PUSH_RANGE + 0.5 and is_in_front(player.global_position):
			var away = player.global_position - global_position
			away.y = 0
			player.knockback(away.normalized() * PUSH_FORCE)
			Events.camera_shake_requested.emit(0.3)
	if state_timer <= 0.0:
		enter_state(State.RECOVER)


func enter_state(new_state: State) -> void:
	state = new_state
	match new_state:
		State.WINDUP:
			state_timer = FOLLOWUP_CROUCH + parry_window if is_followup else windup_time
			window_open = false
			is_slam = not is_followup and randf() < slam_chance
			set_color(base_color.lerp(Palette.PARRY_HOT, Palette.WINDUP_HEAT))
			if is_slam:
				spawn_slam_wave()
			else:
				set_color(Color.YELLOW)
		State.ATTACK:
			state_timer = ATTACK_TIME
			set_color(base_color)
			if not is_slam:
				hit_player()
			Events.camera_shake_requested.emit(0.6 if is_slam else 0.3)
		State.RECOVER:
			state_timer = RECOVER_TIME
			set_color(base_color.darkened(Palette.RECOVER_DIM))
		State.CHASE:
			set_color(base_color)
			push_ready = not just_pushed and distance_to_player() < PUSH_RANGE
			just_pushed = false
			is_followup = false
		State.STUNNED:
			state_timer = STUN_TIME
			set_color(base_color.darkened(Palette.STUN_DIM))
		State.PUSH:
			state_timer = PUSH_WINDUP + PUSH_SWING
			push_done = false
	update_model_pose()


func update_model_pose() -> void:
	if not model:
		return
	match state:
		State.CHASE:
			model.set_pose(EnemyModel.Pose.IDLE)
		State.WINDUP:
			if is_slam:
				model.set_pose(EnemyModel.Pose.SLAM)
			elif is_followup:
				model.set_pose(EnemyModel.Pose.CROUCH)
			else:
				model.set_pose(EnemyModel.Pose.WINDUP)
		State.ATTACK:
			model.set_pose(EnemyModel.Pose.STRIKE)
		State.RECOVER:
			model.set_pose(EnemyModel.Pose.RECOVER)
		State.STUNNED:
			model.set_pose(EnemyModel.Pose.STUNNED)
		State.PUSH:
			model.set_pose(EnemyModel.Pose.PUSH)


func open_parry_window() -> void:
	window_open = true
	set_color(Palette.PARRY_HOT)
	if is_followup:
		lunge_dir = player.global_position - global_position
		lunge_dir.y = 0
		lunge_dir = lunge_dir.normalized()
	if model:
		model.set_pose(EnemyModel.Pose.LUNGE if is_followup else EnemyModel.Pose.OPEN)


func hit_player() -> void:
	if distance_to_player() < ATTACK_RANGE:
		player.take_damage(attack_damage)


func spawn_slam_wave() -> void:
	var wave = GroundBurstScene.instantiate()
	wave.delay = windup_time
	wave.radius = SLAM_RADIUS
	wave.damage = SLAM_DAMAGE
	get_tree().current_scene.add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.25, global_position.z)


func can_be_parried() -> bool:
	return state == State.WINDUP and window_open


func on_parried() -> bool:
	parry_count += 1
	update_parry_pips()
	escalate()
	var killed = parry_count >= parries_to_kill
	if not killed and not is_followup and randf() < double_chance:
		is_followup = true
		enter_state(State.WINDUP)
	else:
		is_followup = false
		enter_state(State.STUNNED)
	return killed


func escalate() -> void:
	if parry_count < escalation_windup.size():
		windup_time = start_windup_time * escalation_windup[parry_count]
	if parry_count < escalation_slam.size():
		slam_chance = escalation_slam[parry_count]
	if parry_count < escalation_double.size():
		double_chance = escalation_double[parry_count]
	if model and model.has_method("set_rage"):
		model.set_rage(get_rage())


func get_rage() -> float:
	if parries_to_kill <= 1:
		return 1.0
	return clamp(float(parry_count) / (parries_to_kill - 1), 0.0, 1.0)


func update_parry_pips() -> void:
	var remaining = parries_to_kill - parry_count
	if is_boss:
		parry_pips.visible = false
		Events.boss_state_changed.emit(remaining, parries_to_kill, get_rage())
		return
	while parry_pips.get_child_count() < parries_to_kill:
		var pip = Sprite3D.new()
		pip.texture = SpikeIcon
		pip.pixel_size = 0.005
		pip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pip.no_depth_test = true
		parry_pips.add_child(pip)
	for i in parries_to_kill:
		var pip: Sprite3D = parry_pips.get_child(i)
		pip.position.x = (i - (parries_to_kill - 1) / 2.0) * PIP_SPACING
		pip.modulate = Color.WHITE if i < remaining else PIP_DIM



func take_damage(amount: int) -> void:
	if parry_only:
		flash()
		return
	super(amount)


func is_in_front(point: Vector3) -> bool:
	if not model:
		return true
	var facing = Vector3(sin(model.rotation.y), 0.0, cos(model.rotation.y))
	var to_point = point - global_position
	to_point.y = 0
	return facing.angle_to(to_point) <= deg_to_rad(FRONT_ANGLE)


func is_harvestable_from(point: Vector3) -> bool:
	return harvestable and model != null and not is_in_front(point)


func can_be_pushed() -> bool:
	return state == State.CHASE


func stops_dash_chain() -> bool:
	return true
