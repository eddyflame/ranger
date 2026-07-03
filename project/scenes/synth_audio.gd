extends Node
class_name SynthAudio

# Plays a basic synthesized tone with a volume decay envelope
static func play_sound(node: Node, start_freq: float, end_freq: float, duration: float, type: String = "sine", volume: float = 0.25):
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		# Interpolate frequency for pitch sweeps
		var freq = lerp(start_freq, end_freq, float(i) / num_samples)
		
		var val = 0.0
		if type == "sine":
			val = sin(2.0 * PI * freq * t)
		elif type == "square":
			val = 1.0 if sin(2.0 * PI * freq * t) >= 0 else -1.0
		elif type == "saw":
			val = 2.0 * (freq * t - floor(0.5 + freq * t))
		elif type == "noise":
			val = randf_range(-1.0, 1.0)
			
		# Linear decay volume envelope
		var envelope = 1.0 - (float(i) / num_samples)
		val *= envelope * volume
		
		# Convert float [-1.0, 1.0] to 8-bit signed integer [-128, 127]
		var int_val = int(clamp(val, -1.0, 1.0) * 127.0)
		data.encode_s8(i, int_val)
		
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.mix_rate = sample_rate
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	node.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

# SOUND WRAPPERS
static func play_shoot(node: Node):
	play_sound(node, 600.0, 200.0, 0.12, "sine", 0.2)

static func play_hit(node: Node):
	play_sound(node, 300.0, 50.0, 0.08, "noise", 0.3)

static func play_gold(node: Node):
	# Double high beep
	play_sound(node, 880.0, 880.0, 0.06, "sine", 0.2)
	var timer = node.get_tree().create_timer(0.06)
	timer.timeout.connect(func(): play_sound(node, 1320.0, 1320.0, 0.09, "sine", 0.2))

static func play_blink(node: Node):
	play_sound(node, 300.0, 1400.0, 0.15, "sine", 0.25)

static func play_windwalk(node: Node):
	play_sound(node, 800.0, 200.0, 0.35, "noise", 0.15)

static func play_stomp(node: Node):
	play_sound(node, 150.0, 40.0, 0.45, "square", 0.4)

static func play_heal(node: Node):
	# Rising arpeggio
	play_sound(node, 523.25, 523.25, 0.08, "sine", 0.25) # C5
	var t1 = node.get_tree().create_timer(0.08)
	t1.timeout.connect(func(): 
		play_sound(node, 659.25, 659.25, 0.08, "sine", 0.25) # E5
		var t2 = node.get_tree().create_timer(0.08)
		t2.timeout.connect(func(): 
			play_sound(node, 783.99, 783.99, 0.12, "sine", 0.25) # G5
		)
	)

static func play_purchase(node: Node):
	play_sound(node, 600.0, 900.0, 0.1, "sine", 0.25)
	var timer = node.get_tree().create_timer(0.08)
	timer.timeout.connect(func(): play_sound(node, 1200.0, 1200.0, 0.15, "sine", 0.25))
