extends Node3D

var direction := Vector3.FORWARD

@onready var chips: CPUParticles3D = $Chips

func _ready() -> void:
	chips.direction = direction
	chips.emitting = true
	chips.finished.connect(queue_free)
