extends CPUParticles2D

func _ready():
	emitting = true
	# Auto free the node after particle emissions finish
	finished.connect(queue_free)
