extends Area2D

const SynthAudio = preload("res://scenes/synth_audio.gd")

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2 # Detect player layer (Units is layer 2)
	
	# Spawn a neat pop-up floating text to guide the player
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("spawn_floating_text"):
		main_scene.call("spawn_floating_text", global_position + Vector2(0, -40), "★ 传送门已开启 ★", Color(0.15, 0.85, 1.0))

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Play chimes sound on exit, attached to the player (body)
		SynthAudio.play_heal(body)
		var gm = get_tree().current_scene.get_node_or_null("GameManager")
		if gm:
			gm.trigger_victory()
		queue_free()
