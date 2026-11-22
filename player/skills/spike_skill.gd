extends Node3D
const SpikeScene = preload("res://player/skills/spike.tscn")
var spike_material = preload("res://player/skills/spike_material.tres")
const GLOW_IDLE = 0.4
const GLOW_DASH = 3.0
const SPIKE_COUNT = 16
const SPIKE_RADIUS = 0.5
const SPIN_SPEED = 15.0
const WEIGHT_PER_SPIKE = 0.5
const DASH_RADIUS = 1.5
const SHIELD_COST_PER_DAMAGE = 3
const SHIELD_MIN_SPIKES = 4
const CHAIN_RANGE = 4.0
const CHAIN_HOP_STOP = 0.03
const FINAL_STOP_BASE = 0.1
const FINAL_STOP_PER_HIT = 0.03
const FINAL_STOP_MAX = 0.3
var is_spinning = false
var current_spikes = 0
const DASH_HIT_RADIUS = 1.9
const SPIKES_PER_DAMAGE = 6.0
const HARVEST_PER_HIT = 1
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
	Events.vine_trap_sprung.connect(_on_vine_trap_sprung)
	get_parent().dash_started.connect(_on_dash_started)
	get_parent().dash_ended.connect(_on_dash_ended)
	get_parent().stance_toggled.connect(_on_stance_toggled)
	get_parent().jump_pressed.connect(_on_jump_pressed)
	Events.enemy_died.connect(_on_enemy_died)
	get_parent().finisher_landed.connect(_on_finisher_landed)
	get_parent().attack_landed.connect(_on_attack_landed)
	spike_material.emission_energy_multiplier = GLOW_IDLE
	Events.stance_changed.emit.call_deferred(is_active)
func _on_dash_started() -> void:
	if not is_active or current_spikes <= 0:
		return
	is_spinning = true
	spike_material.emission_energy_multiplier = GLOW_DASH
	position_spikes(DASH_RADIUS)
	dash_damage = ceili(current_spikes / SPIKES_PER_DAMAGE)
	enemies_hit.clear()
func _on_dash_ended() -> void:
	if not is_spinning:
		return
	is_spinning = false
	spike_material.emission_energy_multiplier = GLOW_IDLE
	position_spikes(SPIKE_RADIUS)
	lose_spikes(enemies_hit.size())
func _on_stance_toggled() -> void:
	is_active = not is_active
	Events.stance_changed.emit(is_active)
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
	var hit_this_frame = false
	var chain_stopped = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in enemies_hit:
			continue
		var offset = enemy.global_position - global_position
		offset.y = 0
		if offset.length() <= DASH_HIT_RADIUS:
			enemies_hit.append(enemy)
			enemy.take_damage(dash_damage)
			hit_this_frame = true
			if enemy.has_method("stops_dash_chain") and enemy.stops_dash_chain():
				chain_stopped = true
	if not hit_this_frame:
		return
	Events.camera_shake_requested.emit(0.4)
	if chain_stopped:
		finish_chain()
		get_parent().end_dash()
		return
	var next = find_chain_target()
	if next:
		get_parent().hit_stop(CHAIN_HOP_STOP)
		get_parent().redirect_dash(next.global_position)
	else:
		finish_chain()
func _on_finisher_landed() -> void:
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

func find_chain_target() -> Node3D:
	var best = null
	var best_distance = CHAIN_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in enemies_hit:
			continue
		var offset = enemy.global_position - global_position
		offset.y = 0
		var distance = offset.length()
		if distance < best_distance:
			best_distance = distance
			best = enemy
		if enemy.has_method("stops_dash_chain") and enemy.stops_dash_chain():
			continue
	return best

func finish_chain() -> void:
	var stop = FINAL_STOP_BASE + FINAL_STOP_PER_HIT * enemies_hit.size()
	get_parent().hit_stop(min(stop, FINAL_STOP_MAX))

func _on_attack_landed(target: Node3D) -> void:
	if target.has_method("is_harvestable_from") and target.is_harvestable_from(get_parent().global_position):
		gain_spikes(HARVEST_PER_HIT)

func _on_vine_trap_sprung(_point: Vector3, _caught: int) -> void:
	gain_spikes(1)
