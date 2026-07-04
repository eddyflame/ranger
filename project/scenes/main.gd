extends Node2D

const SynthAudio = preload("res://scenes/synth_audio.gd")
const SaveSystem = preload("res://scenes/save_system.gd")

@onready var wolf1 = $Enemy_Wolf1
@onready var wolf2 = $Enemy_Wolf2
@onready var wolf3 = $Enemy_Wolf3
@onready var player = $Player

# Enemy respawn data: store their scene path and original position
var enemy_spawn_data: Array = []
var respawn_timer: Timer = null

# Static road outlines to prevent get_outline count out of bounds crashes
var OUTLINE_POINTS := PackedVector2Array([
	Vector2(0, 150), Vector2(400, 150), Vector2(400, 250), Vector2(600, 250),
	Vector2(600, 100), Vector2(1000, 100), Vector2(1000, 250), Vector2(1200, 250),
	Vector2(1200, 150), Vector2(1600, 150), Vector2(1600, 450), Vector2(1200, 450),
	Vector2(1200, 350), Vector2(1000, 350), Vector2(1000, 500), Vector2(600, 500),
	Vector2(600, 350), Vector2(400, 350), Vector2(400, 450), Vector2(0, 450)
])

func _ready():
	SynthAudioManager.set_bgm_mode("explore")
	if player:
		if not SaveSystem.load_game(player):
			# Baseline starting stats for Stage 1 (fresh level 1, 1 skill point)
			player.set_level(1)
			player.set_xp(0)
			player.set_gold(0)
			player.set_skill_points(1)
			player.set_inventory([{}, {}, {}, {}, {}, {}, {}, {}])
	print("--- MAIN READY: PRINTING CHILDREN ---")
	for child in get_children():
		print("Child Name: ", child.name, " | Class: ", child.get_class(), " | Position: ", child.position if child is Node2D else "N/A")
	print("-------------------------------------")
	
	# 1. Draw ground road visuals matching path
	create_road_visual()
	
	# 2. Spawn forest border walls
	spawn_forest_borders()

	# Record enemy spawn info for 5-minute respawn
	for child in get_children():
		if child.is_in_group("enemies"):
			enemy_spawn_data.append({
				"scene_path": child.scene_file_path,
				"position": child.global_position
			})

	# Setup 5-minute respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 300.0  # 5 minutes
	respawn_timer.one_shot = false
	respawn_timer.autostart = true
	respawn_timer.timeout.connect(_respawn_enemies)
	add_child(respawn_timer)

	# 4. Connect signals for all Character children
	for child in get_children():
		if child.has_signal("damage_taken"):
			child.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(child))
		if child.has_signal("healed"):
			child.connect("healed", Callable(self, "_on_character_healed").bind(child))
		if child.has_signal("boss_stomped"):
			child.connect("boss_stomped", Callable(self, "_on_boss_stomped").bind(child))
		if child.has_signal("slow_applied"):
			child.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(child))
		# Connect enemy death to dynamic loot generation
		if child.is_in_group("enemies") and child.has_signal("died"):
			child.connect("died", Callable(self, "_on_enemy_died").bind(child))
			
	# Connect XP, gold, shoot, blink, level up signals on player
	if player:
		if player.has_signal("xp_gained"):
			player.connect("xp_gained", Callable(self, "_on_player_xp_gained"))
		if player.has_signal("gold_gained"):
			player.connect("gold_gained", Callable(self, "_on_player_gold_gained"))
		if player.has_signal("shot_projectile"):
			player.connect("shot_projectile", func():
				if player.get_skill_q_active() and player.mp >= 8.0:
					SynthAudio.play_searing_arrow(self)
				else:
					SynthAudio.play_shoot(self)
			)
		if player.has_signal("blinked"):
			player.connect("blinked", Callable(self, "_on_player_blinked"))
		if player.has_signal("level_up"):
			player.connect("level_up", Callable(self, "_on_player_level_up"))
		# Connect player death to game over
		if player.has_signal("died"):
			player.connect("died", Callable(self, "_on_player_died"))


func _on_player_died():
	var gm = get_node_or_null("GameManager")
	if gm:
		gm.trigger_game_over()
	


func create_road_visual():
	var road = Polygon2D.new()
	road.polygon = OUTLINE_POINTS
	road.color = Color(0.18, 0.16, 0.13, 1.0) # Sleek modern dark road gravel
	road.z_index = -8
	add_child(road)
	
	# Add a border line to the road for aesthetic polish
	var road_border = Line2D.new()
	road_border.points = OUTLINE_POINTS
	# Close the line path loop
	road_border.add_point(OUTLINE_POINTS[0])
	road_border.width = 3.0
	road_border.default_color = Color(0.24, 0.22, 0.18, 1.0)
	road_border.z_index = -7
	add_child(road_border)

func spawn_forest_borders():
	var tree_scene = preload("res://scenes/tree.tscn")
	var outlines = OUTLINE_POINTS
	
	for i in range(outlines.size()):
		var p1 = outlines[i]
		var p2 = outlines[(i + 1) % outlines.size()]
		
		var segment_dir = p2 - p1
		var segment_length = segment_dir.length()
		var step_dist = 36.0 # Distance between tree nodes
		var steps = int(segment_length / step_dist)
		
		var dir_norm = segment_dir.normalized()
		var outward_normal = Vector2(dir_norm.y, -dir_norm.x)
		
		for j in range(steps):
			var spawn_pos = p1 + dir_norm * (j * step_dist)
			# Push the tree outwards to clear the road/navigation area from colliders
			spawn_pos += outward_normal * 18.0
			# Random offset for a natural organic layout
			spawn_pos += Vector2(randf_range(-6, 6), randf_range(-6, 6))
			
			var tree_inst = tree_scene.instantiate()
			tree_inst.global_position = spawn_pos
			# Add random visual sizes
			var scale_factor = randf_range(0.85, 1.2)
			tree_inst.get_node("Visual").scale = Vector2(scale_factor, scale_factor)
			add_child(tree_inst)

func _on_character_damage_taken(amount: float, attacker: Node, victim: Node):
	if victim.has_meta("last_damage_status") and victim.get_meta("last_damage_status") == "evaded":
		victim.remove_meta("last_damage_status")
		spawn_floating_text(victim.global_position + Vector2(0, -25), "闪避 (Evaded)!", Color(0.4, 0.7, 1.0))
		return
		
	if amount <= 0.0: return
	SaveSystem.spawn_hit_sparks(self, victim.global_position)
	
	var color = Color(0.95, 0.2, 0.2)
	var text_prefix = ""
	
	if attacker and attacker.has_meta("last_hit_was_crit") and attacker.get_meta("last_hit_was_crit"):
		attacker.remove_meta("last_hit_was_crit")
		color = Color(1.0, 0.15, 0.15)
		text_prefix = "暴击 "
		if victim == player:
			player.call("trigger_shake", 12.0, 0.3)
		else:
			if player: player.call("trigger_shake", 8.0, 0.2)
			
	if attacker and attacker.has_method("get_searing_effect") and attacker.call("get_searing_effect"):
		color = Color(1.0, 0.5, 0.0)
		
	var block_suffix = ""
	if victim.has_meta("last_damage_status") and victim.get_meta("last_damage_status") == "blocked":
		victim.remove_meta("last_damage_status")
		block_suffix = " (格挡)"
		
	if victim == player and text_prefix == "":
		color = Color(1.0, 0.2, 0.2)
		
	spawn_floating_text(victim.global_position + Vector2(0, -20), "%s-%d%s" % [text_prefix, int(amount), block_suffix], color)
	if text_prefix == "暴击 ":
		SynthAudio.play_crit(self)
	else:
		SynthAudio.play_hit(self)
	
	if victim == player:
		player.call("trigger_shake", 6.0, 0.15)

func _on_character_healed(amount: float, victim: Node):
	if amount <= 0.0: return
	spawn_floating_text(victim.global_position + Vector2(0, -20), "+%d HP" % int(amount), Color(0.2, 0.9, 0.2))
	if victim == player:
		SynthAudio.play_heal(self)

func _on_player_xp_gained(amount: int):
	if amount <= 0: return
	spawn_floating_text(player.global_position + Vector2(0, -40), "+%d XP" % amount, Color(0.7, 0.3, 0.9))

func _on_player_gold_gained(amount: int):
	if amount <= 0: return
	spawn_floating_text(player.global_position + Vector2(0, -30), "+%d 金币" % amount, Color(0.95, 0.8, 0.15))

func spawn_floating_text(pos: Vector2, text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 14
	label.label_settings.font_color = color
	label.label_settings.outline_size = 3
	label.label_settings.outline_color = Color.BLACK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	# Small random offset so texts don't stack perfectly
	label.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	add_child(label)
	
	var tween = create_tween()
	# Float upwards and fade out
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)

func _on_boss_stomped(pos: Vector2, radius: float, boss_node: Node):
	# Create a visual shockwave expanding ring
	var stomp_ring = Line2D.new()
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	stomp_ring.points = points
	stomp_ring.width = 4.0
	stomp_ring.default_color = Color(1.0, 0.45, 0.2, 0.8) # bright warning orange
	stomp_ring.global_position = pos
	stomp_ring.scale = Vector2(5.0, 5.0) # Start small
	stomp_ring.z_index = -3
	add_child(stomp_ring)
	
	spawn_floating_text(pos + Vector2(0, -70), "WAR STOMP!", Color(1.0, 0.25, 0.1))
	
	var tween = create_tween()
	# Expand to stomp radius and fade out
	tween.tween_property(stomp_ring, "scale", Vector2(radius, radius), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(stomp_ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(stomp_ring.queue_free)
	
	SynthAudio.play_stomp(self)
	if player:
		player.call("trigger_shake", 12.0, 0.45)

func _on_player_blinked(from: Vector2, to: Vector2):
	SynthAudio.play_blink(self)
	if player:
		player.call("trigger_shake", 8.0, 0.18)
		
	# Spawn particle puffs at start and end
	var p_scene = preload("res://scenes/blink_particles.tscn")
	var p1 = p_scene.instantiate()
	p1.global_position = from
	add_child(p1)
	
	var p2 = p_scene.instantiate()
	p2.global_position = to
	add_child(p2)
	
	# Draw brief purple lightning arc
	var line = Line2D.new()
	line.points = [from, to]
	line.width = 4.0
	line.default_color = Color(0.85, 0.35, 1.0, 0.8)
	add_child(line)
	
	var tween = create_tween()
	tween.tween_property(line, "width", 0.0, 0.15)
	tween.parallel().tween_property(line, "self_modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _on_player_level_up(new_level: int):
	# Rising sparkles particle beam attached to player
	var p_scene = preload("res://scenes/level_up_particles.tscn")
	var p = p_scene.instantiate()
	if player:
		player.add_child(p)
		player.call("trigger_shake", 10.0, 0.3)
		spawn_floating_text(player.global_position + Vector2(0, -50), "★ LEVEL UP! ★", Color(1.0, 0.85, 0.15))
		
	# Play epic level up fanfare sound
	SynthAudio.play_level_up(self)

func _respawn_enemies():
	# Only respawn if no living enemies remain
	var living = get_tree().get_nodes_in_group("enemies")
	if living.size() > 0:
		return
	print("[Respawn] 5 minutes elapsed — spawning new enemy wave")
	for spawn in enemy_spawn_data:
		if spawn.scene_path == "": continue
		var enemy_scene = load(spawn.scene_path)
		if enemy_scene:
			var enemy_inst = enemy_scene.instantiate()
			enemy_inst.global_position = spawn.position
			add_child(enemy_inst)
			# Connect signals for the new instance
			if enemy_inst.has_signal("damage_taken"):
				enemy_inst.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(enemy_inst))
			if enemy_inst.has_signal("healed"):
				enemy_inst.connect("healed", Callable(self, "_on_character_healed").bind(enemy_inst))
			if enemy_inst.has_signal("boss_stomped"):
				enemy_inst.connect("boss_stomped", Callable(self, "_on_boss_stomped").bind(enemy_inst))
			if enemy_inst.has_signal("slow_applied"):
				enemy_inst.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(enemy_inst))
			if enemy_inst.is_in_group("enemies") and enemy_inst.has_signal("died"):
				enemy_inst.connect("died", Callable(self, "_on_enemy_died").bind(enemy_inst))

func _on_enemy_died(enemy_node):
	if not enemy_node: return
	var is_boss = ("Boss" in enemy_node.name)
	var death_pos = enemy_node.global_position

	var hud = get_node_or_null("HUD")
	if hud:
		if is_boss:
			hud.feed_boss_kill()
		else:
			hud.feed_kill(enemy_node.character_name)

	if is_boss:
		# Boss drops 3 items scattered around its death position
		for i in range(3):
			var loot = SaveSystem.generate_graded_loot(true)
			var scatter = Vector2(randf_range(-60, 60), randf_range(-40, 40))
			SaveSystem.spawn_loot_drop(self, death_pos + scatter, loot)
			SaveSystem.register_unlocked_item(loot)
		# Delay victory by 6 seconds so player can pick up drops
		spawn_floating_text(death_pos + Vector2(0, -80), "🎉 Boss已击杀！6秒后通关…", Color(1.0, 0.85, 0.15))
		var delay_timer = get_tree().create_timer(6.0)
		delay_timer.timeout.connect(func():
			var gm = get_node_or_null("GameManager")
			if gm: gm.trigger_victory()
		)
	else:
		var loot = SaveSystem.generate_graded_loot(false)
		SaveSystem.spawn_loot_drop(self, death_pos, loot)
		SaveSystem.register_unlocked_item(loot)

	if player:
		SaveSystem.save_game(player)

func _on_character_slow_applied(duration: float, victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -35), "减速 (Slowed)!", Color(0.65, 0.25, 0.85))
