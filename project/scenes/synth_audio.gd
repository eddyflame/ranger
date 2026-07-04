extends Node

# Plays a basic synthesized tone with a volume decay envelope
static func play_sound(node: Node, start_freq: float, end_freq: float, duration: float, type: String = "sine", volume: float = 0.25):
	if not is_instance_valid(node):
		return
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
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
			
		var envelope = 1.0 - (float(i) / num_samples)
		val *= envelope * volume
		
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

# BGM SEQUENCER STATE
var bgm_mode: String = "off"
var current_step: int = 0
var timer: Timer = null

func _ready():
	# Start a threat scanner loop that checks for enemies
	start_threat_scanner()

func set_bgm_mode(mode: String):
	if bgm_mode == mode:
		return
	bgm_mode = mode
	current_step = 0
	
	if bgm_mode == "off":
		if timer:
			timer.stop()
		return
		
	if not timer:
		timer = Timer.new()
		add_child(timer)
		timer.timeout.connect(_on_beat_tick)
		
	if bgm_mode == "menu":
		timer.wait_time = 0.3
	elif bgm_mode == "explore":
		timer.wait_time = 0.25
	elif bgm_mode == "battle":
		timer.wait_time = 0.18
		
	timer.start()

func _on_beat_tick():
	if bgm_mode == "off":
		return
	play_bgm_step(bgm_mode, current_step)
	current_step = (current_step + 1) % 16

func play_bgm_step(mode: String, step: int):
	if mode == "menu":
		# Slow melancholic theme
		var chord_idx = step / 4
		var note_idx = step % 4
		var chords = [
			[261.63, 311.13, 392.00, 523.25], # Cm
			[196.00, 233.08, 293.66, 392.00], # Gm
			[207.65, 261.63, 311.13, 415.30], # Ab
			[196.00, 233.08, 293.66, 392.00]  # Gm
		]
		var bass_freqs = [65.41, 49.00, 51.91, 49.00]
		if note_idx == 0:
			play_sound(self, bass_freqs[chord_idx], bass_freqs[chord_idx], 0.6, "sine", 0.08)
		var freq = chords[chord_idx][note_idx]
		play_sound(self, freq, freq, 0.25, "sine", 0.04)

	elif mode == "explore":
		# Peaceful explore theme
		var chord_idx = step / 4
		var note_idx = step % 4
		var chords = [
			[220.00, 261.63, 329.63, 440.00], # Am
			[146.83, 174.61, 220.00, 293.66], # Dm
			[164.81, 196.00, 246.94, 329.63], # Em
			[220.00, 261.63, 329.63, 440.00]  # Am
		]
		var bass_freqs = [55.00, 73.42, 82.41, 55.00]
		if note_idx == 0:
			play_sound(self, bass_freqs[chord_idx], bass_freqs[chord_idx], 0.5, "sine", 0.06)
		var freq = chords[chord_idx][note_idx]
		play_sound(self, freq, freq, 0.22, "sine", 0.03)

	elif mode == "battle":
		# Intense chip-tune combat beat
		if step % 4 == 0:
			play_sound(self, 120.0, 40.0, 0.1, "sine", 0.18) # Kick
		elif step % 4 == 2:
			play_sound(self, 250.0, 100.0, 0.06, "noise", 0.08) # Snare
		else:
			play_sound(self, 800.0, 800.0, 0.02, "noise", 0.03) # Hi-hat
			
		var bass_notes = [73.42, 73.42, 87.31, 87.31, 73.42, 73.42, 98.00, 98.00, 73.42, 73.42, 103.83, 103.83, 73.42, 73.42, 98.00, 98.00]
		var bass_freq = bass_notes[step]
		play_sound(self, bass_freq, bass_freq, 0.15, "saw", 0.025)
		
		if step % 2 == 0:
			var melody_notes = [293.66, 329.63, 349.23, 392.00, 440.00, 466.16, 440.00, 392.00]
			var melody_freq = melody_notes[(step / 2) % 8]
			play_sound(self, melody_freq, melody_freq, 0.18, "square", 0.015)

# AUTOMATIC THREAT DETECTOR SCANNER LOOP
func start_threat_scanner():
	var threat_timer = Timer.new()
	threat_timer.name = "ThreatTimer"
	add_child(threat_timer)
	threat_timer.wait_time = 1.0
	threat_timer.timeout.connect(check_threats)
	threat_timer.start()

func check_threats():
	if bgm_mode == "off" or bgm_mode == "menu":
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	var has_threat = false
	var player_pos = player.global_position
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(player_pos) < 550.0:
			has_threat = true
			break
			
	if has_threat:
		set_bgm_mode("battle")
	else:
		set_bgm_mode("explore")

# SFX WRAPPERS
static func play_shoot(node: Node):
	play_sound(node, 600.0, 200.0, 0.12, "sine", 0.2)

static func play_hit(node: Node):
	play_sound(node, 300.0, 50.0, 0.08, "noise", 0.3)

static func play_gold(node: Node):
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
	play_sound(node, 523.25, 523.25, 0.08, "sine", 0.25)
	var t1 = node.get_tree().create_timer(0.08)
	t1.timeout.connect(func(): 
		play_sound(node, 659.25, 659.25, 0.08, "sine", 0.25)
		var t2 = node.get_tree().create_timer(0.08)
		t2.timeout.connect(func(): 
			play_sound(node, 783.99, 783.99, 0.12, "sine", 0.25)
		)
	)

static func play_purchase(node: Node):
	play_sound(node, 600.0, 900.0, 0.1, "sine", 0.25)
	var timer = node.get_tree().create_timer(0.08)
	timer.timeout.connect(func(): play_sound(node, 1200.0, 1200.0, 0.15, "sine", 0.25))

static func play_crit(node: Node):
	play_sound(node, 180.0, 45.0, 0.16, "square", 0.35)
	play_sound(node, 1100.0, 80.0, 0.13, "noise", 0.22)

static func play_level_up(node: Node):
	var freqs = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50]
	for i in range(freqs.size()):
		var f = freqs[i]
		var t = node.get_tree().create_timer(i * 0.07)
		t.timeout.connect(func():
			if is_instance_valid(node):
				play_sound(node, f, f * 1.02, 0.25, "sine", 0.25)
		)

static func play_searing_arrow(node: Node):
	play_sound(node, 1200.0, 400.0, 0.14, "saw", 0.22)
	play_sound(node, 800.0, 100.0, 0.10, "noise", 0.18)

static func play_arrow_rain(node: Node):
	for i in range(5):
		var t = node.get_tree().create_timer(i * 0.05)
		t.timeout.connect(func():
			if is_instance_valid(node):
				play_sound(node, 800.0 - (i * 80.0), 300.0, 0.08, "sine", 0.15)
		)
