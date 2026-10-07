extends Node3D
const SpikeScene = preload("res://spike.tscn")
const SPIKE_COUNT = 16
const SPIKE_RADIUS = 0.3
const SPIN_SPEED = 15.0
const WEIGHT_PER_SPIKE = 0.5
var is_spinning = false
var current_spikes = 0
var hit_something = false
func _ready() -> void:
	for i in SPIKE_COUNT:
		var spike = SpikeScene.instantiate()
		add_child(spike)
		spike.hit_enemy.connect(_on_spike_hit)
		var angle = TAU / SPIKE_COUNT * i
		spike.position = Vector3(cos(angle)*SPIKE_RADIUS,0.3,sin(angle)*SPIKE_RADIUS)
		spike.rotation = Vector3(0,-angle,-PI/2)
		current_spikes = SPIKE_COUNT
		update_weight()
		update_label()
	get_parent().dash_started.connect(_on_dash_started)
	get_parent().dash_ended.connect(_on_dash_ended)
	get_parent().spikes_toggled.connect(_on_spikes_toggled)
	get_parent().jump_started.connect(_on_jump_started)
func _on_dash_started() -> void:
	for spike in get_children():
		spike.set_damaging(true)
	is_spinning = true
	scale = Vector3(3,3,3)
	hit_something = false
func _on_dash_ended() -> void:
	for spike in get_children():
		spike.set_damaging(false)
	is_spinning = false 
	scale = Vector3.ONE 
	if hit_something:
		lose_spikes(2)
func _on_spikes_toggled() -> void:
	visible = not visible
	if visible:
		update_weight()
	else:
		get_parent().weight = 0.0
	update_label()
func _on_jump_started() -> void:
	if current_spikes <= 0:
		return
	var dir = get_parent().velocity
	dir.y = 0
	dir = dir.normalized()
	if dir.length() < 0.1:
		return
	var spike = get_children()[0]
	spike.reparent(get_tree().current_scene)
	spike.launch(dir)
	current_spikes -=1
	update_weight()
	update_label()
	print("kalan diken: ", current_spikes)
func _process(delta:float) -> void:
	if is_spinning:
		rotate_y(SPIN_SPEED * delta)
func _on_spike_hit()-> void:
	hit_something = true
func lose_spikes(amount: int) -> void:
	for i in amount:
		if current_spikes <= 0:
			return
		get_children()[0].queue_free()
		current_spikes -=1
		print("kalan diken",current_spikes)
		update_weight()
		update_label()
func update_weight() -> void:
	get_parent().weight = current_spikes * WEIGHT_PER_SPIKE
func update_label() -> void:
	get_tree().current_scene.get_node("CanvasLayer/SpikeLabel").text = "Spike " + str(current_spikes)
