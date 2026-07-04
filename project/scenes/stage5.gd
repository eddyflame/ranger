extends Node2D

const SynthAudio = preload("res://scenes/synth_audio.gd")
const SaveSystem = preload("res://scenes/save_system.gd")

@onready var player = $Player

# Enemy respawn data
var enemy_spawn_data: Array = []
var respawn_timer: Timer = null

# Winding obsidian path outline points (volcano cave theme)
var OUTLINE_POINTS := PackedVector2Array([
	Vector2(0, 200), Vector2(500, 200), Vector2(500, 80), Vector2(900, 80),
	Vector2(900, 250), Vector2(1200, 250), Vector2(1200, 100), Vector2(1600, 100),
	Vector2(1600, 500), Vector2(1200, 500), Vector2(1200, 380), Vector2(900, 380),
	Vector2(900, 480), Vector2(500, 480), Vector2(500, 350), Vector2(0, 350)
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

	if player:
		if not SaveSystem.load_game(player):
			# Baseline stats for starting Stage 5 directly (Level 12 reset, 11 skill points)
			player.set_level(12)
			player.set_skill_points(11)
			player.set_gold(1500)
			var starter_inv = [
				{"name": "Furious Blade", "type": "weapon", "atk_bonus": 10.0, "description": "+10 ATK."},
				{"name": "Chainmail", "type": "armor", "def_bonus": 2.0, "hp_bonus": 50.0, "description": "+2 DEF, +50 HP."},
				{"name": "Potion of Healing", "type": "potion", "hp_restore": 150.0, "description": "Consumable. Restores 150 HP."},
				{}, {}, {}, {}, {}
			]
			player.set_inventory(starter_inv)
			player.set_hp(player.get_total_max_hp())
			player.set_mp(player.get_total_max_mp())

	# 2. Draw ground road visuals matching path (obsidian color)
	create_road_visual()
	
	# 3. Spawn obsidian border pillars
	spawn_obsidian_borders()
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
		if child.is_in_group("enemies") and child.has_signal("died"):
			child.connect("died", Callable(self, "_on_enemy_died").bind(child))
			
	# Connect AbyssBoss phase transition signal
	var boss = get_node_or_null("Boss")
	if boss and boss.has_signal("phase_transition_started"):
		boss.connect("phase_transition_started", Callable(self, "_on_boss_phase_transition"))

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
		if player.has_signal("died"):
			player.connect("died", func():
				var delay_timer = get_tree().create_timer(3.0)
				delay_timer.timeout.connect(func():
					var gm = get_node_or_null("GameManager")
					if gm: gm.trigger_game_over()
				)
			)

func create_road_visual():
	var road = Polygon2D.new()
	road.polygon = OUTLINE_POINTS
	road.color = Color(0.18, 0.12, 0.12, 1.0) # Obsidian gravel road
	road.z_index = -8
	add_child(road)
	
	var road_border = Line2D.new()
	road_border.points = OUTLINE_POINTS
	road_border.add_point(OUTLINE_POINTS[0])
	road_border.width = 3.0
	road_border.default_color = Color(0.28, 0.15, 0.15, 1.0) # Lava glow edge
	road_border.z_index = -7
	add_child(road_border)

func spawn_obsidian_borders():
	var tree_scene = preload("res://scenes/tree.tscn")
	var outlines = OUTLINE_POINTS
	
	for i in range(outlines.size()):
		var p1 = outlines[i]
		var p2 = outlines[(i + 1) % outlines.size()]
		
		var segment_dir = p2 - p1
		var segment_length = segment_dir.length()
		
		# Place an obsidian pillar tree every 100 pixels
		var step = 100.0
		var current_dist = 0.0
		
		while current_dist < segment_length:
			var ratio = current_dist / segment_length
			var spawn_pos = p1 + segment_dir * ratio
			
			var pillar = tree_scene.instantiate()
			pillar.global_position = spawn_pos
			# Modulate tree visual to look like volcanic obsidian rock
			pillar.modulate = Color(0.15, 0.1, 0.12, 1.0)
			pillar.scale = Vector2(0.9, 1.2)
			add_child(pillar)
			
			current_dist += step

func _respawn_enemies():
	var living = get_tree().get_nodes_in_group("enemies")
	if living.size() >= 30:
		return
	print("[Stage 5] Respawning enemies...")
	for data in enemy_spawn_data:
		if data.get("is_boss", false):
			continue
		var enemy_scene = load(data.scene_path)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = data.position
			add_child(enemy)
			
			if enemy.has_signal("damage_taken"):
				enemy.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(enemy))
			if enemy.has_signal("died"):
				enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy))
			if enemy.has_signal("slow_applied"):
				enemy.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(enemy))
			
			spawn_floating_text(enemy.global_position + Vector2(0, -30), "👿 怪物复活！", Color(0.85, 0.2, 0.2))

func _on_boss_phase_transition():
	var boss = get_node_or_null("Boss")
	if not boss: return
	
	# Spawn epic floating text
	spawn_floating_text(boss.global_position + Vector2(0, -90), "🔥 【深渊魔王觉醒！】 🔥", Color(1.0, 0.1, 0.1))
	spawn_floating_text(boss.global_position + Vector2(0, -60), "⚠️ 【第二阶段：魔王之躯！】", Color(1.0, 0.4, 0.15))
	
	# High-intensity screen shake on player
	if player:
		player.trigger_shake(15.0, 1.0)
		
	# Play transition synth audio loops
	SynthAudio.play_shoot(self)
	SynthAudio.play_hit(self)

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
		# Triple legendary drops scattered around boss death pos
		for i in range(3):
			var loot = SaveSystem.generate_graded_loot(true)
			var scatter = Vector2(randf_range(-60, 60), randf_range(-40, 40))
			SaveSystem.spawn_loot_drop(self, death_pos + scatter, loot)
			SaveSystem.register_unlocked_item(loot)

		# Find the farthest X point on the outline — the far edge of the map
		var max_pt = OUTLINE_POINTS[0]
		for p in OUTLINE_POINTS:
			if p.x > max_pt.x:
				max_pt = p

		# Spawn exit portal at the far map edge
		var portal_scene = load("res://scenes/exit_portal.tscn")
		if portal_scene:
			var portal = portal_scene.instantiate()
			portal.global_position = max_pt
			add_child(portal)
			print("[Boss Defeat] Spawning exit portal at the far map edge: ", max_pt)

		spawn_floating_text(death_pos + Vector2(0, -80), "🎉 最终魔王已伏诛！最终通关传送门已开启", Color(1.0, 0.85, 0.15))
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

func _on_character_damage_taken(amount: float, attacker: Node, victim: Node):
	if amount <= 0.0:
		spawn_floating_text(victim.global_position + Vector2(randf_range(-20, 20), -45), "闪避 (Evaded)!", Color(0.3, 0.9, 0.3))
	else:
		SaveSystem.spawn_hit_sparks(self, victim.global_position)
		var color = Color(0.85, 0.15, 0.15) if victim == player else Color(1.0, 1.0, 1.0)
		var text_prefix = ""
		if attacker and attacker.has_meta("last_hit_was_crit") and attacker.get_meta("last_hit_was_crit"):
			attacker.remove_meta("last_hit_was_crit")
			color = Color(1.0, 0.15, 0.15)
			text_prefix = TranslationManager.t("ALERT_CRIT")
			if victim == player:
				player.call("trigger_shake", 12.0, 0.3)
			else:
				if player: player.call("trigger_shake", 8.0, 0.2)

		spawn_floating_text(victim.global_position + Vector2(randf_range(-15, 15), -45), "%s-%d" % [text_prefix, int(amount)], color)
		if text_prefix == TranslationManager.t("ALERT_CRIT"):
			SynthAudio.play_crit(self)
		else:
			SynthAudio.play_hit(self)

func _on_character_healed(amount: float, victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -45), "+%d HP" % int(amount), Color(0.2, 0.9, 0.2))

func _on_boss_stomped(victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -35), "💥 震地撞击 (Stomped)!", Color(0.9, 0.45, 0.1))

func _on_player_xp_gained(amount: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -55), "+%d XP" % amount, Color(0.85, 0.85, 0.15))

func _on_player_gold_gained(amount: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -70), "+%d Gold" % amount, Color(0.95, 0.8, 0.15))

func _on_player_blinked(from_pos: Vector2, to_pos: Vector2):
	var blink_p_scene = load("res://scenes/blink_particles.tscn")
	if blink_p_scene:
		var bp1 = blink_p_scene.instantiate()
		bp1.global_position = from_pos
		add_child(bp1)
		
		var bp2 = blink_p_scene.instantiate()
		bp2.global_position = to_pos
		add_child(bp2)
	SynthAudio.play_shoot(self)

func _on_player_level_up(new_level: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -85), "✨ LEVEL UP!! ✨", Color(0.2, 0.9, 0.9))
		var lvl_up_p = load("res://scenes/level_up_particles.tscn")
		if lvl_up_p:
			var particles = lvl_up_p.instantiate()
			player.add_child(particles)
		# Play epic level up fanfare sound
		SynthAudio.play_level_up(self)

func spawn_floating_text(pos: Vector2, text: String, color: Color):
	var lbl = Label.new()
	lbl.text = text
	lbl.global_position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 11)
	add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "global_position", pos + Vector2(0, -45), 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)

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
