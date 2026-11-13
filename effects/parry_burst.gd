extends Node3D

const FLASH_TIME = 0.25

@onready var shards: CPUParticles3D = $Shards
@onready var spores: CPUParticles3D = $Spores
@onready var flash: OmniLight3D = $Flash

func _ready() -> void:
	shards.emitting = true
	spores.emitting = true
	spores.finished.connect(queue_free)
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(flash, "light_energy", 0.0, FLASH_TIME)
