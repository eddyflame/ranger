extends Node2D

const SynthAudio = preload("res://scenes/synth_audio.gd")
const SaveSystem = preload("res://scenes/save_system.gd")

@onready var player = $Player

# Enemy respawn data
var enemy_spawn_data: Array = []
var respawn_timer: Timer = null

# Winding path outline points
var OUTLINE_POINTS := PackedVector2Array([
	Vector2(0, 250), Vector2(400, 250), Vector2(400, 100), Vector2(800, 100),
	Vector2(800, 200), Vector2(1100, 200), Vector2(1100, 100), Vector2(1300, 100),
	Vector2(1300, 150), Vector2(1600, 150), Vector2(1600, 450), Vector2(1300, 450),
	Vector2(1300, 350), Vector2(1100, 350), Vector2(1100, 500), Vector2(800, 500),
	Vector2(800, 350), Vector2(400, 350), Vector2(400, 500), Vector2(0, 500)
])

func _ready():
	SynthAudioManager.set_bgm_mode("explore")
	
	# Dynamic Map Inflation & Positions Scaling (1.6x space for kiting)
	var map_scale := 1.6
	var centroid := Vector2.ZERO
	for p in OUTLINE_POINTS:
		centroid += p
	centroid /= OUTLINE_POINTS.size()
	
	for i in range(OUTLINE_POINTS.size()):
		var dir = OUTLINE_POINTS[i] - centroid
		OUTLINE_POINTS[i] = centroid + dir * map_scale
		
	# Scale starting positions of player and existing enemies
	for child in get_children():
		if child.is_in_group("enemies") or child == player:
			var dir = child.global_position - centroid
			child.global_position = centroid + dir * map_scale

	# Update Camera2D limits dynamically to match the inflated map
	if player:
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			var min_x = OUTLINE_POINTS[0].x
			var max_x = OUTLINE_POINTS[0].x
			var min_y = OUTLINE_POINTS[0].y
			var max_y = OUTLINE_POINTS[0].y
			for p in OUTLINE_POINTS:
				min_x = min(min_x, p.x)
				max_x = max(max_x, p.x)
				min_y = min(min_y, p.y)
				max_y = max(max_y, p.y)
			camera.limit_left = int(min_x - 300)
			camera.limit_right = int(max_x + 300)
			camera.limit_top = int(min_y - 200)
			camera.limit_bottom = int(max_y + 200)

	# Programmatically duplicate normal enemies to increase density
	var existing_mobs = []
	for child in get_children():
		if child.is_in_group("enemies"):
			existing_mobs.append(child)
			
	for mob in existing_mobs:
		var mob_name = mob.name.to_lower()
		if "boss" in mob_name or "treant" in mob_name or "queen" in mob_name or "mage" in mob_name:
			continue
		var path = mob.scene_file_path
		if path != "":
			var scene = load(path)
			if scene:
				var extra = scene.instantiate()
				var angle = randf() * TAU
				var dist = randf_range(120.0, 240.0)
				extra.global_position = mob.global_position + Vector2(cos(angle), sin(angle)) * dist
				add_child(extra)

	# 1. Build Navigation Polygon dynamically covering the map's bounding box
	var nav_region = $NavigationRegion2D
	if nav_region:
		var min_x = OUTLINE_POINTS[0].x
		var max_x = OUTLINE_POINTS[0].x
		var min_y = OUTLINE_POINTS[0].y
		var max_y = OUTLINE_POINTS[0].y
		for p in OUTLINE_POINTS:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)
			
		var bounding_box = PackedVector2Array([
			Vector2(min_x - 600, min_y - 400),
			Vector2(max_x + 600, min_y - 400),
			Vector2(max_x + 600, max_y + 400),
			Vector2(min_x - 600, max_y + 400)
		])
		var nav_poly = NavigationPolygon.new()
		nav_poly.add_outline(bounding_box)
		nav_poly.make_polygons_from_outlines()
		nav_region.navigation_polygon = nav_poly
		# NavigationRegion2D bakes automatically on ready with GDExtension bindings in Godot 4.7

	if player:
		if not SaveSystem.load_game(player):
			# Baseline stats for starting Stage 4 directly (Level 1 reset, 1 skill point)
			player.set_level(1)
			player.set_skill_points(1)
			player.set_gold(300)
			var starter_inv = [
				{"name": "Furious Blade", "type": "weapon", "atk_bonus": 10.0, "description": "+10 ATK."},
				{"name": "Chainmail", "type": "armor", "def_bonus": 2.0, "hp_bonus": 50.0, "description": "+2 DEF, +50 HP."},
				{"name": "Potion of Healing", "type": "potion", "hp_restore": 150.0, "description": "Consumable. Restores 150 HP."},
				{}, {}, {}, {}, {}
			]
			player.set_inventory(starter_inv)
			player.set_hp(player.get_total_max_hp())
			player.set_mp(player.get_total_max_mp())

	# 2. Draw ground road visuals matching path
	create_road_visual()
	
	# 3. Spawn forest border walls
	spawn_forest_borders()
	spawn_boundary_walls()

	# Record enemy spawn info for 1-minute respawn
	for child in get_children():
		if child.is_in_group("enemies"):
			var path = child.scene_file_path
			if path == "":
				var cname = child.name.to_lower()
				if "abyssboss" in cname or "abyss_boss" in cname or "abyss" in cname:
					path = "res://scenes/abyss_boss.tscn"
				elif "spiderqueen" in cname or "spider_queen" in cname or "queen" in cname:
					path = "res://scenes/spider_queen.tscn"
				elif "boss" in cname:
					path = "res://scenes/boss.tscn"
				elif "ranged" in cname or "spitter" in cname:
					path = "res://scenes/ranged_enemy.tscn"
				elif "spiderling" in cname:
					path = "res://scenes/spiderling.tscn"
				else:
					path = "res://scenes/enemy.tscn"
			var is_b = "boss" in child.name.to_lower() or "queen" in child.name.to_lower() or "mage" in child.name.to_lower()
			enemy_spawn_data.append({
				"scene_path": path,
				"position": child.global_position,
				"is_boss": is_b
			})

	# Setup 1-minute respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 60.0  # 1 minute
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
			
	# Connect Spider Queen minion spawn signal
	var boss = get_node_or_null("Boss")
	if boss and boss.has_signal("minion_spawned"):
		boss.connect("minion_spawned", Callable(self, "_on_boss_minion_spawned"))

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
	road.color = Color(0.14, 0.08, 0.16, 1.0) # Sleek modern dark purple gravel road for spider level
	road.z_index = -8
	add_child(road)
	
	# Add a border line to the road for aesthetic polish
	var road_border = Line2D.new()
	road_border.points = OUTLINE_POINTS
	# Close the line path loop
	road_border.add_point(OUTLINE_POINTS[0])
	road_border.width = 3.0
	road_border.default_color = Color(0.20, 0.12, 0.22, 1.0)
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
		var step_dist = 90.0 # Distance between tree nodes
		var steps = int(segment_length / step_dist)
		
		var dir_norm = segment_dir.normalized()
		var outward_normal = Vector2(dir_norm.y, -dir_norm.x)
		
		for j in range(steps):
			var spawn_pos = p1 + dir_norm * (j * step_dist)
			spawn_pos += outward_normal * 18.0
			spawn_pos += Vector2(randf_range(-6, 6), randf_range(-6, 6))
			
			var tree_inst = tree_scene.instantiate()
			tree_inst.global_position = spawn_pos
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
		text_prefix = TranslationManager.t("ALERT_CRIT")
		if victim == player:
			player.call("trigger_shake", 12.0, 0.3)
		else:
			if player: player.call("trigger_shake", 8.0, 0.2)
			
	if attacker and attacker.has_method("get_searing_effect") and attacker.call("get_searing_effect"):
		color = Color(1.0, 0.5, 0.0)
		
	var block_suffix = ""
	if victim.has_meta("last_damage_status") and victim.get_meta("last_damage_status") == "blocked":
		victim.remove_meta("last_damage_status")
		block_suffix = TranslationManager.t("ALERT_BLOCKED")
		
	if victim == player and text_prefix == "":
		color = Color(1.0, 0.2, 0.2)
		
	spawn_floating_text(victim.global_position + Vector2(0, -20), "%s-%d%s" % [text_prefix, int(amount), block_suffix], color)
	if text_prefix == TranslationManager.t("ALERT_CRIT"):
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
	spawn_floating_text(player.global_position + Vector2(0, -30), ( "+%d Gold" if TranslationManager.current_locale == "en" else "+%d 金币" ) % amount, Color(0.95, 0.8, 0.15))
	SynthAudio.play_gold(self)

func spawn_floating_text(pos: Vector2, text: String, color: Color):
	var label = Label.new()
	label.text = TranslationManager.t(text)
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 14
	label.label_settings.font_color = color
	label.label_settings.outline_size = 3
	label.label_settings.outline_color = Color.BLACK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	label.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)

func _on_boss_stomped(pos: Vector2, radius: float, boss_node: Node):
	var stomp_ring = Line2D.new()
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	stomp_ring.points = points
	stomp_ring.width = 4.0
	stomp_ring.default_color = Color(0.9, 0.3, 0.95, 0.8) # Purple-pink boss stomp shockwave
	stomp_ring.global_position = pos
	stomp_ring.scale = Vector2(5.0, 5.0)
	stomp_ring.z_index = -3
	add_child(stomp_ring)
	
	spawn_floating_text(pos + Vector2(0, -70), "STOMP!", Color(0.9, 0.3, 0.95))
	
	var tween = create_tween()
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
		
	var p_scene = preload("res://scenes/blink_particles.tscn")
	var p1 = p_scene.instantiate()
	p1.global_position = from
	add_child(p1)
	
	var p2 = p_scene.instantiate()
	p2.global_position = to
	add_child(p2)
	
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
	var p_scene = preload("res://scenes/level_up_particles.tscn")
	var p = p_scene.instantiate()
	if player:
		player.add_child(p)
		player.call("trigger_shake", 10.0, 0.3)
		spawn_floating_text(player.global_position + Vector2(0, -50), "★ LEVEL UP! ★", Color(1.0, 0.85, 0.15))
		
	# Play epic level up fanfare sound
	SynthAudio.play_level_up(self)

func _respawn_enemies():
	var living = get_tree().get_nodes_in_group("enemies")
	if living.size() >= 30:
		return
	print("[Respawn] 1 minute elapsed — spawning new enemy wave")
	for spawn in enemy_spawn_data:
		if spawn.get("is_boss", false):
			continue
		if spawn.scene_path == "": continue
		var enemy_scene = load(spawn.scene_path)
		if enemy_scene:
			var enemy_inst = enemy_scene.instantiate()
			enemy_inst.global_position = spawn.position
			add_child(enemy_inst)
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

func _on_boss_minion_spawned(minion_node):
	if minion_node:
		# Add to group so HUD can detect and manage
		minion_node.add_to_group("enemies")
		if minion_node.has_signal("damage_taken"):
			minion_node.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(minion_node))
		if minion_node.has_signal("healed"):
			minion_node.connect("healed", Callable(self, "_on_character_healed").bind(minion_node))
		if minion_node.has_signal("slow_applied"):
			minion_node.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(minion_node))
		if minion_node.has_signal("died"):
			minion_node.connect("died", Callable(self, "_on_enemy_died").bind(minion_node))

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
			
		# Find the Outline Point with the maximum X coordinate (the far edge of the map)
		var max_pt = OUTLINE_POINTS[0]
		for p in OUTLINE_POINTS:
			if p.x > max_pt.x:
				max_pt = p
				
		# Spawn exit portal at the far edge outline point
		var portal_scene = load("res://scenes/exit_portal.tscn")
		if portal_scene:
			var portal = portal_scene.instantiate()
			portal.global_position = max_pt
			add_child(portal)
			print("[Boss Defeat] Spawning exit portal at the far map edge: ", max_pt)
			
		spawn_floating_text(death_pos + Vector2(0, -80), "🎉 领主已击败！通关传送门已开启", Color(1.0, 0.85, 0.15))
	else:
		# 25% chance to drop gear for regular enemies
		if randf() <= 0.25:
			var loot = SaveSystem.generate_graded_loot(false)
			SaveSystem.spawn_loot_drop(self, death_pos, loot)
			SaveSystem.register_unlocked_item(loot)

	if player:
		SaveSystem.save_game(player)

func _on_character_slow_applied(duration: float, victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -35), "减速 (Slowed)!", Color(0.65, 0.25, 0.85))

func spawn_boundary_walls():
	var min_x = OUTLINE_POINTS[0].x
	var max_x = OUTLINE_POINTS[0].x
	var min_y = OUTLINE_POINTS[0].y
	var max_y = OUTLINE_POINTS[0].y
	for p in OUTLINE_POINTS:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
		
	var left = min_x - 300
	var right = max_x + 300
	var top = min_y - 200
	var bottom = max_y + 200
	
	var walls = [
		{ "pos": Vector2(left - 10, (top + bottom)/2.0), "size": Vector2(20, (bottom - top) + 100) },
		{ "pos": Vector2(right + 10, (top + bottom)/2.0), "size": Vector2(20, (bottom - top) + 100) },
		{ "pos": Vector2((left + right)/2.0, top - 10), "size": Vector2((right - left) + 100, 20) },
		{ "pos": Vector2((left + right)/2.0, bottom + 10), "size": Vector2((right - left) + 100, 20) }
	]
	
	for w in walls:
		var sb = StaticBody2D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = w.size
		col.shape = shape
		sb.add_child(col)
		
		sb.global_position = w.pos
		add_child(sb)
