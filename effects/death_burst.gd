extends Node3D

const FLASH_TIME = 0.5

var color:= Color.WHITE
var size := 1.0

@onready var shards: CPUParticles3D = $Shards
@onready var wisp: CPUParticles3D = $Wisp
@onready var motes: CPUParticles3D = $Motes
@onready var flash: OmniLight3D = $Flash

func _ready() -> void:
	for p in [shards, wisp, motes]:
		p.scale_amount_min *= size
		p.scale_amount_max *= size
	wisp.color = color
	motes.color = color
	flash.light_color = color
	flash.omni_range *= size
	shards.emitting = true 
	wisp.emitting = true
	motes.emitting = true
	wisp.finished.connect(queue_free)
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, FLASH_TIME)    
