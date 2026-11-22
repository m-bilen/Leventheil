extends EnemyBase
const GroundBurstScene = preload("res://enemies/ground_burst.tscn")
enum State { CHASE, WINDUP , ATTACK , RECOVER, STUNNED, PUSH}
@export var slam_chance: float = 0.0
@export var speed: float = 1.5
@export var windup_time: float = 0.8
@export var attack_damage: int = 2
@export var parries_to_kill: int = 3
@export var parry_only: bool = false
@export var display_name: String = ""
@export var parry_window: float = 0.3
@export var harvestable: bool = false
@export var escalation_windup: Array[float] = []
@export var escalation_slam: Array[float] = []
@export var escalation_color: Color = Color(0.55, 0.0, 0.1)
@export var can_push: bool = false
@export var escalation_double: Array[float] = []
const SpikeIcon = preload("res://ui/icons/spike.svg")
const PIP_SPACING = 0.32
const PIP_DIM = Color(1, 1, 1, 0.25)
@onready var parry_pips: Node3D = $ParryPips
const FOLLOWUP_WINDUP_SCALE = 0.6
const FOLLOWUP_MIN_WINDUP = 0.5
const FRONT_ANGLE = 60.0
const PUSH_RANGE = 2.2
const PUSH_WINDUP = 0.3
const PUSH_SWING = 0.15
const PUSH_COOLDOWN = 3.0
const PUSH_FORCE = 12.0
const SLAM_COLOR = Color(0.8, 0.2, 1.0)
const SLAM_RADIUS = 3
const SLAM_DAMAGE = 2
const WINDOW_COLOR = Color(1.0, 0.5, 0.1)
const ATTACK_RANGE = 2.5
const ATTACK_TIME = 0.2
const RECOVER_TIME = 1.0
const STUN_TIME = 2.0
const TURN_SPEED = 4.0
const PIP_HEIGHT = 1.0
var double_chance = 0.0
var is_followup = false
var just_pushed = false
var push_ready = false
var push_done = false
var parry_count = 0
var state: State = State.CHASE
var state_timer = 0.0
var window_open = false
var is_slam = false
var start_windup_time = 0.0
var start_color = Color.WHITE
var turn_speed = TURN_SPEED

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
	if state_timer <= 0.0:
		enter_state(State.ATTACK)

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

func open_parry_window() -> void:
	window_open = true
	set_color(WINDOW_COLOR)
	if model:
		model.set_pose(EnemyModel.Pose.OPEN)
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
			state_timer = max(windup_time * FOLLOWUP_WINDUP_SCALE, FOLLOWUP_MIN_WINDUP) if is_followup else windup_time
			window_open = false
			is_slam = not is_followup and randf() < slam_chance
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
			push_ready = not just_pushed and distance_to_player() < PUSH_RANGE
			just_pushed = false
			is_followup = false
		State.STUNNED:
			state_timer = STUN_TIME
			set_color(Color.CYAN)
		State.PUSH:
			state_timer = PUSH_WINDUP + PUSH_SWING
			push_done = false
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
	if not escalation_windup.is_empty():
		var t = clamp(float(parry_count) / (parries_to_kill - 1), 0.0, 1.0)
		base_color = start_color.lerp(escalation_color, t)
		if model and model.has_method("set_rage"):
			model.set_rage(t)

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
	if display_name != "":
		parry_pips.visible = false
		var rage = clamp(float(parry_count) / (parries_to_kill - 1), 0.0, 1.0)
		Events.boss_state_changed.emit(remaining, parries_to_kill, rage)
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

func _ready() -> void:
	super()
	speed *= randf_range(0.9, 1.1)
	turn_speed = TURN_SPEED * randf_range(0.8, 1.2)
	start_windup_time = windup_time
	start_color = base_color
	escalate()
	update_parry_pips()
	if display_name != "":
		Events.boss_spawned.emit(display_name)
		Events.camera_focus_requested.emit(global_position, 1.0)
		Events.camera_shake_requested.emit(0.8)

func update_model_pose() -> void:
	if not model:
		return
	match state:
		State.CHASE:
			model.set_pose(EnemyModel.Pose.IDLE)
		State.WINDUP:
			model.set_pose(EnemyModel.Pose.SLAM if is_slam else EnemyModel.Pose.WINDUP)
		State.ATTACK:
			model.set_pose(EnemyModel.Pose.STRIKE)
		State.RECOVER:
			model.set_pose(EnemyModel.Pose.RECOVER)
		State.STUNNED:
			model.set_pose(EnemyModel.Pose.STUNNED)
		State.PUSH:
			model.set_pose(EnemyModel.Pose.PUSH)


func spawn_slam_wave() -> void:
	var wave = GroundBurstScene.instantiate()
	wave.delay = windup_time
	wave.radius = SLAM_RADIUS
	wave.damage = SLAM_DAMAGE
	get_tree().current_scene.add_child(wave)
	wave.global_position = Vector3(global_position.x, 0.25, global_position.z)

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
