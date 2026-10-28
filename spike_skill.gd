extends Node3D
const SpikeScene = preload("res://spike.tscn")
const SPIKE_COUNT = 16
const SPIKE_RADIUS = 0.5
const SPIN_SPEED = 15.0
const WEIGHT_PER_SPIKE = 0.5
const DASH_RADIUS = 1.5
const SHIELD_COST_PER_DAMAGE = 3
const SHIELD_MIN_SPIKES = 4
var is_spinning = false
var current_spikes = 0
const DASH_HIT_RADIUS = 1.9
const SPIKES_PER_DAMAGE = 6.0
var dash_damage = 0
var enemies_hit: Array = []
var is_active = true
func _ready() -> void:
	for i in SPIKE_COUNT:
		var spike = SpikeScene.instantiate()
		add_child(spike)
	position_spikes(SPIKE_RADIUS)
	current_spikes = SPIKE_COUNT
	update_weight()
	broadcast_spikes.call_deferred()
	Events.wave_started.connect(_on_wave_started)
	get_parent().dash_started.connect(_on_dash_started)
	get_parent().dash_ended.connect(_on_dash_ended)
	get_parent().stance_toggled.connect(_on_stance_toggled)
	get_parent().jump_pressed.connect(_on_jump_pressed)
	Events.enemy_died.connect(_on_enemy_died)
	get_parent().finisher_landed.connect(_on_finisher_landed)
func _on_dash_started() -> void:
	if not is_active or current_spikes <= 0:
		return
	is_spinning = true
	position_spikes(DASH_RADIUS)
	dash_damage = ceili(current_spikes / SPIKES_PER_DAMAGE)
	enemies_hit.clear()
func _on_dash_ended() -> void:
	if not is_spinning:
		return
	is_spinning = false
	position_spikes(SPIKE_RADIUS)
	if not enemies_hit.is_empty():
		lose_spikes(2)
func _on_stance_toggled() -> void:
	is_active = not is_active
	visible = is_active
	update_weight()
	broadcast_spikes()
func _on_jump_pressed(aim_dir: Vector3) -> void:
	if not is_active:
		return
	if current_spikes <= 0:
		return
	if aim_dir == Vector3.ZERO:
		return
	var spike = get_children()[0]
	spike.reparent(get_tree().current_scene)
	spike.launch(aim_dir)
	current_spikes -=1
	update_weight()
	broadcast_spikes()
	position_spikes(SPIKE_RADIUS) 

func _process(delta:float) -> void:
	if is_spinning:
		rotate_y(SPIN_SPEED * delta)
func lose_spikes(amount: int) -> void:
	for i in amount:
		if current_spikes <= 0:
			break
		var spike = get_children()[0]
		remove_child(spike)
		spike.queue_free()
		current_spikes -=1
	update_weight()
	broadcast_spikes()
	position_spikes(SPIKE_RADIUS)
func update_weight() -> void:
	if is_active: 
		get_parent().weight = current_spikes * WEIGHT_PER_SPIKE
	else:
		get_parent().weight = 0.0
func broadcast_spikes() -> void:
	Events.spikes_changed.emit(current_spikes)
func position_spikes(radius: float) -> void:
	var children = get_children()
	for i in children.size():
		var angle = TAU / children.size() * i
		children[i].position = Vector3(cos(angle) * radius, 0.9, sin(angle) * radius)
		children[i].rotation = Vector3(0, -angle, -PI/2)
func gain_spikes(amount: int) -> void:
	for i in amount:
		if current_spikes >= SPIKE_COUNT:
			break
		var spike = SpikeScene.instantiate()
		add_child(spike)
		current_spikes += 1
	position_spikes(SPIKE_RADIUS)
	update_weight()
	broadcast_spikes()
func _on_enemy_died(_enemy: Node3D) -> void:
	if not is_active:
		gain_spikes(1)

func _physics_process(_delta: float) -> void:
	if not is_spinning:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in enemies_hit:
			continue
		var offset = enemy.global_position - global_position
		offset.y = 0
		if offset.length() <= DASH_HIT_RADIUS:
			enemies_hit.append(enemy)
			enemy.take_damage(dash_damage)
			Events.camera_shake_requested.emit(0.4)
			get_parent().hit_stop(0.2)
func _on_finisher_landed() -> void:
# Light stance already got +1 from the kill itself in _on_enemy_died.
	if is_active:
		gain_spikes(1)
func absorb_damage(amount: int) -> bool:
	if not is_active or current_spikes <= SHIELD_MIN_SPIKES:
		return false
	lose_spikes(amount * SHIELD_COST_PER_DAMAGE)
	return true
func enables_parry() -> bool:
	return is_active and current_spikes > 0
func _on_wave_started(_number: int) -> void:
	gain_spikes(SPIKE_COUNT)
