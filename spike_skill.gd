extends Node3D
const SpikeScene = preload("res://spike.tscn")
const SPIKE_COUNT = 16
const SPIKE_RADIUS = 0.5
const SPIN_SPEED = 15.0
const WEIGHT_PER_SPIKE = 0.5
const DASH_RADIUS = 1.5
var is_spinning = false
var current_spikes = 0
var hit_something = false
var is_active = true
func _ready() -> void:
	for i in SPIKE_COUNT:
		var spike = SpikeScene.instantiate()
		add_child(spike)
		spike.hit_enemy.connect(_on_spike_hit)
		position_spikes(SPIKE_RADIUS)
		current_spikes = SPIKE_COUNT
		update_weight()
		update_label()
	get_parent().dash_started.connect(_on_dash_started)
	get_parent().dash_ended.connect(_on_dash_ended)
	get_parent().spikes_toggled.connect(_on_spikes_toggled)
	get_parent().jump_started.connect(_on_jump_started)
	Events.enemy_died.connect(_on_enemy_died)
func _on_dash_started() -> void:
	if not is_active:
		return
	for spike in get_children():
		spike.set_damaging(true)
	is_spinning = true
	position_spikes(DASH_RADIUS)
	hit_something = false
func _on_dash_ended() -> void:
	for spike in get_children():
		spike.set_damaging(false)
	is_spinning = false 
	position_spikes(SPIKE_RADIUS)
	if hit_something:
		lose_spikes(2)
func _on_spikes_toggled() -> void:
	is_active = not is_active
	visible = is_active
	if is_active:
		update_weight()
	else:
		get_parent().weight = 0.0
	update_label()
func _on_jump_started(aim_dir: Vector3) -> void:
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
	update_label()
	position_spikes(SPIKE_RADIUS) 

func _process(delta:float) -> void:
	if is_spinning:
		rotate_y(SPIN_SPEED * delta)
func _on_spike_hit()-> void:
	hit_something = true
	get_parent().hit_stop(0.2)
	get_tree().current_scene.get_node("Camera3D").shake(0.4)
func lose_spikes(amount: int) -> void:
	for i in amount:
		if current_spikes <= 0:
			return
		var spike = get_children()[0]
		remove_child(spike)
		spike.queue_free()
		current_spikes -=1
	print("kalan diken",current_spikes)
	update_weight()
	update_label()
	position_spikes(SPIKE_RADIUS)
func update_weight() -> void:
	get_parent().weight = current_spikes * WEIGHT_PER_SPIKE
func update_label() -> void:
	get_tree().current_scene.get_node("CanvasLayer/SpikeLabel").text = "Spike " + str(current_spikes)
func position_spikes(radius: float) -> void:
	var children = get_children()
	for i in children.size():
		var angle = TAU / children.size() * i
		children[i].position = Vector3(cos(angle) * radius, 0.9, sin(angle) * radius)
		children[i].rotation = Vector3(0, -angle, -PI/2)
func gain_spikes(amount: int) -> void:
	for i in amount:
		if current_spikes >= SPIKE_COUNT:
			return
		var spike = SpikeScene.instantiate()
		add_child(spike)
		spike.hit_enemy.connect(_on_spike_hit)
		current_spikes += 1
	position_spikes(SPIKE_RADIUS)
	update_weight()
	update_label()
func _on_enemy_died(_enemy: Node3D) -> void:
	gain_spikes(1)
