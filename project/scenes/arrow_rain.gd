extends Area2D

const SynthAudio = preload("res://scenes/synth_audio.gd")

var tick_damage: float = 10.0
var skill_attacker: Node2D = null

var total_ticks: int = 6
var ticks_remaining: int = 6
var tick_timer: Timer = null
var pulse_time: float = 0.0

func setup(damage: float, attacker: Node2D):
	tick_damage = damage
	skill_attacker = attacker

func _ready():
	# Configure repeating tick timer (triggers every 0.5s)
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.one_shot = false
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timeout)
	add_child(tick_timer)
	
	# Play initial shoot sound effect
	SynthAudio.play_shoot(self)
	
	# Pulse animation update
	queue_redraw()

func _process(delta):
	pulse_time += delta * 6.0
	queue_redraw()

func _draw():
	# Pulsing alpha values for the border and zone fill
	var pulse_val = (sin(pulse_time) + 1.0) * 0.5
	var fill_color = Color(0.95, 0.45, 0.1, 0.06 + pulse_val * 0.04)
	var border_color = Color(0.95, 0.45, 0.1, 0.35 + pulse_val * 0.25)
	
	# Draw filled target reticle area
	draw_circle(Vector2.ZERO, 120.0, fill_color)
	# Draw boundary outline ring
	draw_arc(Vector2.ZERO, 120.0, 0.0, TAU, 64, border_color, 2.0)

func _on_tick_timeout():
	if ticks_remaining <= 0:
		return
		
	ticks_remaining -= 1
	_apply_aoe_damage()
	
	if ticks_remaining <= 0:
		# Stop particles emission and wait for remaining arrows to drop before freeing
		$CPUParticles2D.emitting = false
		tick_timer.stop()
		var cleanup_timer = get_tree().create_timer(0.6)
		cleanup_timer.timeout.connect(queue_free)

func _apply_aoe_damage():
	var targets = get_overlapping_bodies()
	var damaged_any = false
	
	for body in targets:
		if body.is_in_group("enemies") and body.has_method("take_damage") and not body.call("get_is_dead"):
			body.call("take_damage", tick_damage, skill_attacker)
			
			# Apply slowing status effect via C++ Character method
			if body.has_method("apply_slow"):
				body.call("apply_slow", 1.5) # 1.5 seconds slow refresh on tick
				
			damaged_any = true
			
	if damaged_any:
		SynthAudio.play_hit(self)
